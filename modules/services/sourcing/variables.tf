variable "environment"  { type = string }
variable "project_name" { type = string }

# ---- Shared Infrastructure Inputs -------------------------------------------
variable "private_subnet_ids" {
  type        = list(string)
  description = "List of private subnet IDs from the shared VPC"
}
variable "lambda_security_group_id" {
  type        = string
  description = "The ID of the shared Lambda security group"
}
variable "db_endpoint" {
  type        = string
  description = "The endpoint of the shared RDS database"
  sensitive   = true
}

# ---- CloudFront -------------------------------------------------------------
variable "cloudfront_price_class" { type = string }
variable "viewer_protocol_policy" { type = string }
variable "default_root_object"    { type = string }
variable "cloudfront_enabled"     { type = bool }

# ---- EventBridge ------------------------------------------------------------
variable "eventbridge_schedule_expression" { type = string }