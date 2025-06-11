#############################################################
# 1. Shared IAM 
#############################################################
module "iam" {
  source       = "./modules/base-infra/iam"
  environment  = var.environment
  project_name = var.project_name
}

#############################################################
# 2. Sourcing Feature
#############################################################
module "feature_sourcing" {
  source       = "./modules/features/sourcing"

  environment      = var.environment
  project_name     = var.project_name
  lambda_role_arn  = module.iam.lambda_role_arn

  # RDS
  db_username         = var.db_username
  db_password         = var.db_password
  db_engine           = var.db_engine
  db_instance_class   = var.db_instance_class
  db_allocated_storage= var.db_allocated_storage
  skip_final_snapshot = var.skip_final_snapshot

  # CloudFront
  cloudfront_price_class = var.cloudfront_price_class
  viewer_protocol_policy = var.viewer_protocol_policy
  default_root_object    = var.default_root_object
  cloudfront_enabled     = var.cloudfront_enabled

  # EventBridge
  eventbridge_schedule_expression = var.eventbridge_schedule_expression
}
