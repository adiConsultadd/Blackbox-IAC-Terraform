variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
  default     = ""
}

variable "subnet_ids" {
  description = "Subnet IDs"
  type        = list(string)
  default     = []
}

variable "rds_endpoint" {
  description = "RDS endpoint (placeholder for now)"
  type        = string
  default     = ""
}

variable "s3_bucket_name" {
  description = "S3 bucket name (placeholder for now)"
  type        = string
  default     = ""
}

variable "lambda_role_arn" {
  description = "Lambda execution role ARN"
  type        = string
}

# If you don't need EventBridge right now, comment out or set a default:
variable "eventbridge_rule_arn" {
  description = "EventBridge rule ARN (placeholder for now)"
  type        = string
  default     = ""
}
