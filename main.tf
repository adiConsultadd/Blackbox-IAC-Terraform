# TODO : Put providers in separate file, move some content out of main.tf (make it more readable)
# Layers Part To Be Seen Again

################################################
# IAM
################################################
module "iam" {
  source       = "./modules/iam"
  environment  = var.environment
  project_name = var.project_name
}

################################################
# Lambda
################################################
module "lambda" {
  source          = "./modules/lambda"
  environment     = var.environment
  project_name    = var.project_name
  lambda_role_arn = module.iam.lambda_role_arn
}

################################################
# RDS
################################################
# module "rds" {
#   source              = "./modules/rds"
#   environment         = var.environment
#   project_name        = var.project_name

#   db_username         = var.db_username
#   db_password         = var.db_password
#   engine              = var.db_engine
#   instance_class      = var.db_instance_class
#   allocated_storage   = var.db_allocated_storage
#   skip_final_snapshot = var.skip_final_snapshot
# }

################################################
# S3
################################################
# module "s3" {
#   source       = "./modules/s3"
#   environment  = var.environment
#   project_name = var.project_name
# }

################################################
# CloudFront
################################################
# module "cloudfront" {
#   source                    = "./modules/cloudfront"
#   environment               = var.environment
#   project_name              = var.project_name
#   s3_bucket_name            = module.s3.bucket_name
#   price_class               = var.cloudfront_price_class
#   viewer_protocol_policy    = var.viewer_protocol_policy
#   default_root_object       = var.default_root_object
#   enabled                   = var.cloudfront_enabled
# }

################################################
# EventBridge
################################################
# module "eventbridge" {
#   source                = "./modules/eventbridge"
#   environment           = var.environment
#   project_name          = var.project_name
#   lambda_arn_to_trigger = module.lambda.lambda_1_arn

#   schedule_expression   = var.eventbridge_schedule_expression
# }