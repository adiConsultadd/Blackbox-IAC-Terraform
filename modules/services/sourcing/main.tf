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
  source                 = "../../base-infra/cloudfront"
  environment            = var.environment
  project_name           = var.project_name
  s3_bucket_name         = module.s3.bucket_name
  price_class            = var.cloudfront_price_class
  viewer_protocol_policy = var.viewer_protocol_policy
  default_root_object    = var.default_root_object
  enabled                = var.cloudfront_enabled
}

###############################################################################
# 3. IAM Role (Whole Service)
###############################################################################
locals {
  bucket_arn   = "arn:aws:s3:::${module.s3.bucket_name}"
  bucket_objects = "${local.bucket_arn}/*"
  project_lambda = "arn:aws:lambda:*:*:function:${var.project_name}-${var.environment}-lambda_*"

  # Define the combined policy statements once
  service_policy_statements = [
    # General Permissions
    { Effect = "Allow", Action = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"], Resource = ["arn:aws:logs:*:*:*"] },
    # VPC Permissions (Required for Lambdas in a VPC)
    { Effect = "Allow", Action = ["ec2:CreateNetworkInterface", "ec2:DescribeNetworkInterfaces", "ec2:DeleteNetworkInterface"], Resource = "*" },
    # S3 Permissions (from lambda-1 and lambda-3)
    { Effect = "Allow", Action = ["s3:PutObject", "s3:GetObject", "s3:DeleteObject", "s3:ListBucket"], Resource = [local.bucket_arn, local.bucket_objects] },
    # Lambda Invoke Permissions (from lambda-1)
    { Effect = "Allow", Action = ["lambda:InvokeFunction"], Resource = [local.project_lambda] },
    # RDS Permissions (from lambda-2 and lambda-3)
    { Effect = "Allow", Action = ["rds-data:*", "rds-db:connect", "rds:DescribeDBInstances"], Resource = ["*"] },
    # CloudFront Invalidation Permissions (from lambda-3)
    { Effect = "Allow", Action = ["cloudfront:CreateInvalidation"], Resource = ["*"] }
  ]
}
module "sourcing_lambda_role" {
  source = "../../base-infra/iam-lambda"

  role_name         = "${var.project_name}-${var.environment}-sourcing-service-role"
  project_name      = var.project_name
  environment       = var.environment
  policy_statements = local.service_policy_statements
}

###############################################################################
# 4. Lambda function definitions
###############################################################################
locals {
  lambdas = {
    "sourcing-rfp-sourcing-web"                 = {
        layers = [], 
        env = { S3_BUCKET_NAME = module.s3.bucket_name }
    }
    "sourcing-rfp-details-db-ingestion"         = {
        layers = [], 
        env = { DB_ENDPOINT = var.db_endpoint }
    }
    "sourcing-rfp-documents-s3-url-db-ingestion" = {
        layers = [], 
        env = {
          S3_BUCKET_NAME    = module.s3.bucket_name
          DB_ENDPOINT       = var.db_endpoint
          CLOUDFRONT_DISTRO = module.cloudfront.distribution_id
        }
    }
  }
}


###############################################################################
# 5. Lambda functions
###############################################################################
module "lambda" {
  for_each = local.lambdas
  source   = "../../base-infra/lambda"
  runtime       = var.lambda_configs[each.key].runtime
  timeout       = var.lambda_configs[each.key].timeout
  memory_size   = var.lambda_configs[each.key].memory_size
  
  function_name = "${var.project_name}-${var.environment}-${each.key}"

  # Deploy from the placeholder artifact in S3
  s3_bucket        = var.placeholder_s3_bucket
  s3_key           = var.placeholder_s3_key
  source_code_hash = var.placeholder_source_code_hash

  # All functions now use the SAME role ARN
  lambda_role_arn = module.sourcing_lambda_role.role_arn

  # Set function-specific environment variables
  environment_variables = each.value.env

  # VPC config remains the same
  vpc_subnet_ids         = var.private_subnet_ids
  vpc_security_group_ids = [var.lambda_security_group_id]

  # Attaching required layers
  layers = [for layer_key in each.value.layers : var.available_layer_arns[layer_key]]
}

###############################################################################
# 6. EventBridge (Schedules Lambda-1 of this service)
###############################################################################
module "eventbridge" {
  source    = "../../base-infra/eventbridge"
  environment = var.environment
  project_name = var.project_name
  suffix    = "daily-trigger-sourcing-lambda-1"

  lambda_arn_to_trigger = module.lambda["sourcing-rfp-sourcing-web"].lambda_arn
  schedule_expression   = var.eventbridge_schedule_expression
}