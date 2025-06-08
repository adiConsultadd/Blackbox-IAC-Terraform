variable "environment" {
  type        = string
  description = "Environment name"
}

variable "project_name" {
  type        = string
  description = "Project name"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
  default     = ""
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "List of private subnet IDs"
  default     = []
}

variable "db_username" {
  type        = string
  default     = "postgres"
}

variable "db_password" {
  type        = string
  default     = "Password123!"
}

variable "engine" {
  type        = string
  default     = "postgres"
}

variable "instance_class" {
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  type        = number
  default     = 20
}