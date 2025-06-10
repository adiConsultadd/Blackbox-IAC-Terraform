# variables.tf

variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g. dev, prod)"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
}

# ------------------------------------------------------------------------------
# RDS variables
# ------------------------------------------------------------------------------
variable "db_username" {
  description = "RDS DB Username"
  type        = string
}

variable "db_password" {
  description = "RDS DB Password"
  type        = string
}

variable "db_engine" {
  description = "RDS Engine type"
  type        = string
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
}

variable "db_allocated_storage" {
  description = "RDS allocated storage in GB"
  type        = number
}

variable "skip_final_snapshot" {
  description = "Whether to skip the final snapshot on RDS deletion"
  type        = bool
}

# ------------------------------------------------------------------------------
# CloudFront variables
# ------------------------------------------------------------------------------
variable "cloudfront_price_class" {
  description = "CloudFront price class (e.g. PriceClass_100, PriceClass_All)"
  type        = string
}

variable "viewer_protocol_policy" {
  description = "CloudFront viewer protocol policy"
  type        = string
}

variable "default_root_object" {
  description = "Default root object for CloudFront"
  type        = string
}

variable "cloudfront_enabled" {
  description = "Whether to enable the CloudFront distribution"
  type        = bool
}

# ------------------------------------------------------------------------------
# EventBridge variables
# ------------------------------------------------------------------------------
variable "eventbridge_schedule_expression" {
  description = "Schedule expression for EventBridge rule (e.g. cron(0 8 * * ? *))"
  type        = string
}
