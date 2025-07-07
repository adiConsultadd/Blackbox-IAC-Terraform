variable "project_name" {
  type        = string
  description = "Project name"
}

variable "environment" {
  type        = string
  description = "Environment name"
}

variable "param_name" {
  type        = string
  description = "The name of the parameter (e.g., 'db_password', 'api_key')"
}

variable "type" {
  type        = string
  description = "The type of the parameter (String, StringList, SecureString)"
  default     = "SecureString"
}

variable "value" {
  type        = string
  description = "The value of the parameter"
  sensitive   = true
}