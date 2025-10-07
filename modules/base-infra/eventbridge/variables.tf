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
  default     = null
}

variable "event_pattern" {
  type        = string
  description = "Event pattern for event-driven triggers. Must be a JSON string."
  default     = null 
}
variable "suffix"{
  type        = string
}