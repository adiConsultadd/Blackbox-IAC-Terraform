variable "function_name" {
  description = "Fully-qualified Lambda function name"
  type        = string
}

variable "s3_bucket" {
  description = "The S3 bucket name where the Lambda function's deployment package is stored."
  type        = string
}

variable "s3_key" {
  description = "The S3 key for the Lambda function's deployment package."
  type        = string
}

variable "source_code_hash" {
  description = "Used to trigger updates when the S3 object changes. This is the ETag of the S3 object."
  type        = string
  default     = null
}

variable "lambda_role_arn" {
  description = "IAM role ARN for Lambda execution"
  type        = string
}

variable "runtime" {
  type    = string
}

variable "handler" {
  type    = string
  default = "index.handler"
}

variable "timeout" {
  type    = number
  default = 30
}

variable "memory_size" {
  type    = number
  default = 128
}

variable "environment_variables" {
  type        = map(string)
  default     = {}
  description = "Key/value pairs injected into the function"
}

variable "vpc_subnet_ids" {
  description = "List of subnet IDs to attach the Lambda to"
  type        = list(string)
  default     = []
}

variable "vpc_security_group_ids" {
  description = "List of security group IDs to attach the Lambda to"
  type        = list(string)
  default     = []
}

variable "layers" {
  description = "List of Lambda Layer ARNs to attach to the function"
  type        = list(string)
  default     = []
}