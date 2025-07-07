###############################################################################
# 1. S3 bucket (Service-specific storage)
###############################################################################
module "s3" {
  source        = "../../base-infra/s3"
  environment   = var.environment
  project_name  = var.project_name
  bucket_suffix = "sourcing-rfp-files"
}

###############################################################################
# 2. CloudFront (Serves content from this service's S3 bucket)
###############################################################################
module "cloudfront" {
  source       = "../../base-infra/cloudfront"
  environment  = var.environment
  project_name = var.project_name

  s3_bucket_name         = module.s3.bucket_name
  price_class            = var.cloudfront_price_class
  viewer_protocol_policy = var.viewer_protocol_policy
  default_root_object    = var.default_root_object
  enabled                = var.cloudfront_enabled
}

###############################################################################
# 3. Lambda definitions (source dir, env vars, IAM policy)
###############################################################################
locals {
  bucket_arn     = "arn:aws:s3:::${module.s3.bucket_name}"
  bucket_objects = "${local.bucket_arn}/*"
  project_lambda = "arn:aws:lambda:*:*:function:${var.project_name}-${var.environment}-lambda_*"

  lambdas = {
    # -------------------------------------------------------------------------
    sourcing-lambda-1 = {
      source_dir = "${path.module}/lambda-code/lambda-1"
      env        = { EXAMPLE_ENV_VAR = "Sourcing-Lambda-1", S3_BUCKET_NAME = module.s3.bucket_name }
      policy_statements = [
        { Effect = "Allow", Action = ["s3:PutObject", "s3:GetObject", "s3:DeleteObject"], Resource = [local.bucket_objects] },
        { Effect = "Allow", Action = ["lambda:InvokeFunction"], Resource = [local.project_lambda] },
        { Effect = "Allow", Action = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"], Resource = ["arn:aws:logs:*:*:*"] }
      ]
    }
    # -------------------------------------------------------------------------
    sourcing-lambda-2 = {
      source_dir = "${path.module}/lambda-code/lambda-2"
      env        = { EXAMPLE_ENV_VAR = "Sourcing-Lambda-2", DB_ENDPOINT = var.db_endpoint }
      policy_statements = [
        { Effect = "Allow", Action = ["rds-data:*", "rds-db:connect", "rds:DescribeDBInstances"], Resource = ["*"] },
        { Effect = "Allow", Action = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"], Resource = ["arn:aws:logs:*:*:*"] }
      ]
    }
    # -------------------------------------------------------------------------
    sourcing-lambda-3 = {
      source_dir = "${path.module}/lambda-code/lambda-3"
      env = {
        EXAMPLE_ENV_VAR   = "Sourcing-Lambda-3"
        S3_BUCKET_NAME    = module.s3.bucket_name
        DB_ENDPOINT       = var.db_endpoint
        CLOUDFRONT_DISTRO = module.cloudfront.distribution_id # Get ID from internal module
      }
      policy_statements = [
        { Effect = "Allow", Action = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject", "s3:ListBucket"], Resource = [local.bucket_arn, local.bucket_objects] },
        { Effect = "Allow", Action = ["rds-data:*", "rds-db:connect", "rds:DescribeDBInstances"], Resource = ["*"] },
        { Effect = "Allow", Action = ["cloudfront:CreateInvalidation"], Resource = ["*"] },
        { Effect = "Allow", Action = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"], Resource = ["arn:aws:logs:*:*:*"] }
      ]
    }
  }
}

###############################################################################
# 4. IAM role per Lambda
###############################################################################
module "lambda_roles" {
  for_each = local.lambdas
  source   = "../../base-infra/iam-lambda"

  role_name         = "${var.project_name}-${var.environment}-${each.key}-role"
  project_name      = var.project_name
  environment       = var.environment
  policy_statements = each.value.policy_statements
}

###############################################################################
# 5. Lambda functions
###############################################################################
module "lambda" {
  for_each = local.lambdas
  source   = "../../base-infra/lambda"

  function_name          = "${var.project_name}-${var.environment}-${each.key}"
  source_dir             = each.value.source_dir
  lambda_role_arn        = module.lambda_roles[each.key].role_arn
  environment_variables  = each.value.env
  vpc_subnet_ids         = var.private_subnet_ids
  vpc_security_group_ids = [var.lambda_security_group_id]
}

###############################################################################
# 6. EventBridge (Schedules Lambda-1 of this service)
###############################################################################
module "eventbridge" {
  source       = "../../base-infra/eventbridge"
  environment  = var.environment
  project_name = var.project_name
  suffix       = "daily-trigger-sourcing-lambda-1"

  lambda_arn_to_trigger = module.lambda["sourcing-lambda-1"].lambda_arn
  schedule_expression   = var.eventbridge_schedule_expression
}