variable "environment"  { type = string }
variable "project_name" { type = string }

# ---- CloudFront -------------------------------------------------------------
variable "cloudfront_price_class"   { type = string }
variable "viewer_protocol_policy"   { type = string }
variable "default_root_object"      { type = string }
variable "cloudfront_enabled"       { type = bool }

# ---- EventBridge ------------------------------------------------------------
variable "eventbridge_schedule_expression" { type = string }
