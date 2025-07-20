variable "environment" {
  type = string
}
variable "project_name" {
  type = string
}
variable "lambda_runtime" {
  type = string
}
variable "private_subnet_ids" {
  type        = list(string)
  description = "List of private subnet IDs from the shared VPC"
}
variable "lambda_security_group_id" {
  type        = string
  description = "The ID of the shared Lambda security group"
}

variable "required_layer_arns" {
  description = "A list of Lambda Layer ARNs to attach to the functions in this service."
  type        = list(string)
  default     = []
}

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