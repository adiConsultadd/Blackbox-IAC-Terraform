variable "environment" {
  type        = string
  description = "Environment name"
}

variable "project_name" {
  type        = string
  description = "Project name"
}

variable "lambda_arn_to_trigger" {
  type        = string
  description = "Which Lambda to invoke on a schedule"
}

variable "schedule_expression" {
  type        = string
  description = "Schedule expression (e.g. cron(0 8 * * ? *))"
}

variable "suffix"{
  type        = string
}