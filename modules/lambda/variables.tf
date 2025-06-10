variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "lambda_role_arn" {
  description = "Lambda execution role ARN"
  type        = string
}

variable "eventbridge_rule_arn" {
  description = "EventBridge rule ARN (placeholder for now)"
  type        = string
  default     = ""
}
