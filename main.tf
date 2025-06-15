#############################################################
# 1.  Sourcing Feature 
#############################################################
module "feature_sourcing" {
  source       = "./modules/services/sourcing"

  environment  = var.environment
  project_name = var.project_name

  # -------------- CloudFront -----------
  cloudfront_price_class = var.cloudfront_price_class
  viewer_protocol_policy = var.viewer_protocol_policy
  default_root_object    = var.default_root_object
  cloudfront_enabled     = var.cloudfront_enabled

  # ------------- EventBridge -----------
  eventbridge_schedule_expression = var.eventbridge_schedule_expression
}
