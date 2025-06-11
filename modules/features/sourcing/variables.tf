variable "environment"     { type = string }
variable "project_name"    { type = string }
variable "lambda_role_arn" { type = string }

# RDS
variable "db_username"         { type = string }
variable "db_password"         { type = string }
variable "db_engine"           { type = string }
variable "db_instance_class"   { type = string }
variable "db_allocated_storage"{ type = number }
variable "skip_final_snapshot" { type = bool }

# CloudFront
variable "cloudfront_price_class" { type = string }
variable "viewer_protocol_policy" { type = string }
variable "default_root_object"    { type = string }
variable "cloudfront_enabled"     { type = bool }

# EventBridge
variable "eventbridge_schedule_expression" { type = string }
