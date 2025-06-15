###############################################################################
# 1.  S3 bucket
###############################################################################
module "s3" {
  source       = "../../base-infra/s3"
  environment  = var.environment
  project_name = var.project_name  
  bucket_suffix = "sourcing-rfp-files"
}

###############################################################################
# 2.  Lambda definitions (source dir, env vars, IAM policy)
###############################################################################
locals {
  bucket_arn     = "arn:aws:s3:::${module.s3.bucket_name}"
  bucket_objects = "${local.bucket_arn}/*"
  project_lambda = "arn:aws:lambda:*:*:function:${var.project_name}-${var.environment}-lambda_*"

  lambdas = {
    # -------------------------------------------------------------------------
    sourcing-lambda-1 = {
      source_dir = "${path.module}/lambda-code/lambda-1"
      env        = { EXAMPLE_ENV_VAR = "Sourcing-Lambda-1" }

      policy_statements = [
        # S3 – write RFP files
        {
          Effect   = "Allow"
          Action   = ["s3:PutObject", "s3:GetObject", "s3:DeleteObject"]
          Resource = [local.bucket_objects]            
        },
        # Invoke lambda‑2 & lambda‑3
        {
          Effect   = "Allow"
          Action   = ["lambda:InvokeFunction"]
          Resource = [local.project_lambda]            
        },
        # Logs
        {
          Effect   = "Allow"
          Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
          Resource = ["arn:aws:logs:*:*:*"]           
        }
      ]
    }

    # -------------------------------------------------------------------------
    sourcing-lambda-2 = {
      source_dir = "${path.module}/lambda-code/lambda-2"
      env        = { EXAMPLE_ENV_VAR = "Sourcing-Lambda-2" }

      policy_statements = [
        # RDS – read / write
        {
          Effect   = "Allow"
          Action   = ["rds-data:*", "rds-db:connect", "rds:DescribeDBInstances"]
          Resource = ["*"]                             
        },
        # Logs
        {
          Effect   = "Allow"
          Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
          Resource = ["arn:aws:logs:*:*:*"]
        }
      ]
    }

    # -------------------------------------------------------------------------
    sourcing-lambda-3 = {
      source_dir = "${path.module}/lambda-code/lambda-3"
      env        = { EXAMPLE_ENV_VAR = "Sourcing-Lambda-3" }

      policy_statements = [
        # S3 – full read / write
        {
          Effect   = "Allow"
          Action   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject", "s3:ListBucket"]
          Resource = [local.bucket_arn, local.bucket_objects]
        },
        # RDS – read / write
        {
          Effect   = "Allow"
          Action   = ["rds-data:*", "rds-db:connect", "rds:DescribeDBInstances"]
          Resource = ["*"]
        },
        # CloudFront invalidations
        {
          Effect   = "Allow"
          Action   = ["cloudfront:CreateInvalidation"]
          Resource = ["*"]
        },
        # Logs
        {
          Effect   = "Allow"
          Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
          Resource = ["arn:aws:logs:*:*:*"]
        }
      ]
    }
  }
}

###############################################################################
# 3.  IAM role per Lambda
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
# 4.  Lambda functions
###############################################################################
module "lambda" {
  for_each = local.lambdas
  source   = "../../base-infra/lambda"

  function_name         = "${var.project_name}-${var.environment}-${each.key}"
  source_dir            = each.value.source_dir
  lambda_role_arn       = module.lambda_roles[each.key].role_arn
  environment_variables = each.value.env
}

###############################################################################
# 5. EventBridge
###############################################################################
module "eventbridge" {
  source       = "../../base-infra/eventbridge"
  environment  = var.environment
  project_name = var.project_name
  suffix = "daily-trigger-sourcing-lambda-1"

  lambda_arn_to_trigger = module.lambda["sourcing-lambda-1"].lambda_arn
  schedule_expression   = var.eventbridge_schedule_expression
}

###############################################################################
# 6. CloudFront 
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
