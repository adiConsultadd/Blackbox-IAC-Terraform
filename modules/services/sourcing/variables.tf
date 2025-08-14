variable "environment" { type = string }
variable "project_name" { type = string }

variable "lambdas" {
  description = "A map of lambda function definitions for this service."
  type = map(object({
    layers      = list(string)
    runtime     = string
    timeout     = number
    memory_size = number
    env_vars    = optional(map(string))
  }))
  default = {}
}

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

variable "available_layer_arns" {
  description = "A map of all available Lambda Layer ARNs, keyed by their short name."
  type        = map(string)
  default     = {}
}


# ---- CloudFront -------------------------------------------------------------
variable "cloudfront_price_class" { type = string }
variable "viewer_protocol_policy" { type = string }
variable "default_root_object" { type = string }
variable "cloudfront_enabled" { type = bool }

# ---- EventBridge ------------------------------------------------------------
variable "eventbridge_schedule_expression" { type = string }

# ---- Placeholder Lambda Artifacts -------------------------------------------
variable "placeholder_s3_bucket" {
  type        = string
  description = "S3 bucket for the placeholder Lambda code."
}
variable "placeholder_s3_key" {
  type        = string
  description = "S3 key for the placeholder Lambda zip."
}
variable "placeholder_source_code_hash" {
  type        = string
  description = "Hash of the placeholder zip to trigger updates."
}