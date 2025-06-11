###############################################################################
# 1. s3 Bucket
###############################################################################
module "s3" {
  source       = "../../base-infra/s3"
  environment  = var.environment
  project_name = var.project_name
}

###############################################################################
# 2. Lambdas (three functions)
###############################################################################
locals {
  lambdas = {
    lambda_1 = {
      source_dir = "${path.module}/lambda-code/lambda-1"
      env        = { EXAMPLE_ENV_VAR = "HelloWorld-lambda1" }
    }
    lambda_2 = {
      source_dir = "${path.module}/lambda-code/lambda-2"
      env        = { EXAMPLE_ENV_VAR = "HelloWorld-lambda2" }
    }
    lambda_3 = {
      source_dir = "${path.module}/lambda-code/lambda-3"
      env        = { EXAMPLE_ENV_VAR = "HelloWorld-lambda3" }
    }
  }
}

module "lambda" {
  source = "../../base-infra/lambda"
  for_each = local.lambdas

  function_name         = "${var.project_name}-${var.environment}-${each.key}"
  source_dir            = each.value.source_dir
  lambda_role_arn       = var.lambda_role_arn
  environment_variables = each.value.env
}

###############################################################################
# 3. EventBridge – triggers lambda‑1 every day (example)
###############################################################################
# module "eventbridge" {
#   source       = "../../base-infra/eventbridge"
#   environment  = var.environment
#   project_name = var.project_name

#   lambda_arn_to_trigger = module.lambda["lambda_1"].lambda_arn
#   schedule_expression   = var.eventbridge_schedule_expression
# }

###############################################################################
# 4. CloudFront 
###############################################################################
# module "cloudfront" {
#   source       = "../../base-infra/cloudfront"
#   environment  = var.environment
#   project_name = var.project_name

#   s3_bucket_name         = module.s3.bucket_name
#   price_class            = var.cloudfront_price_class
#   viewer_protocol_policy = var.viewer_protocol_policy
#   default_root_object    = var.default_root_object
#   enabled                = var.cloudfront_enabled
# }

###############################################################################
# 5. RDS 
###############################################################################
# module "rds" {
#   source              = "../../base-infra/rds"
#   environment         = var.environment
#   project_name        = var.project_name

#   db_username         = var.db_username
#   db_password         = var.db_password
#   engine              = var.db_engine
#   instance_class      = var.db_instance_class
#   allocated_storage   = var.db_allocated_storage
#   skip_final_snapshot = var.skip_final_snapshot
# }
