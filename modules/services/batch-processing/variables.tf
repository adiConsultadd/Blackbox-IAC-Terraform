variable "environment" {
  description = "The deployment environment (e.g., dev, prod)"
  type        = string
}
variable "project_name" {
  description = "The name of the project"
  type        = string
}
variable "private_subnet_ids" {
  description = "List of private subnet IDs from the shared VPC"
  type        = list(string)
}
variable "lambda_security_group_id" {
  description = "The ID of the shared Lambda security group"
  type        = string
}
variable "available_layer_arns" {
  description = "A map of all available Lambda Layer ARNs, keyed by their short name."
  type        = map(string)
  default     = {}
}
variable "lambdas" {
  description = "A map of lambda function definitions for this service."
  type = map(object({
    layers      = list(string)
    runtime     = string
    timeout     = number
    memory_size = number
    env_vars    = optional(map(string))
    package_type = optional(string, "Zip") 
  }))
  default = {}
}
variable "placeholder_s3_bucket" {
  description = "S3 bucket for the placeholder Lambda code."
  type        = string
}
variable "placeholder_s3_key" {
  description = "S3 key for the placeholder Lambda zip."
  type        = string
}
variable "placeholder_source_code_hash" {
  description = "Hash of the placeholder zip to trigger updates."
  type        = string
}
variable "validation_state_machine_arn" {
  description = "The ARN of the validation workflow state machine from the validation service"
  type        = string
}
variable "drafting_lambda_arns" {
  description = "A map of Lambda function ARNs from the drafting service."
  type        = map(string)
  default     = {}
}

variable "deep_research_lambda_arns" {
  description = "A map of Lambda function ARNs from the deep-research service."
  type        = map(string)
  default     = {}
}