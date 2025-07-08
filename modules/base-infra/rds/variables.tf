variable "environment" {
  type        = string
  description = "Environment name"
}

variable "project_name" {
  type        = string
  description = "Project name"
}

variable "db_username" {
  type        = string
  description = "RDS DB username"
}

variable "db_password" {
  type        = string
  description = "RDS DB password"
  sensitive   = true
}

variable "engine" {
  type        = string
  description = "RDS engine (e.g. postgres, mysql, etc.)"
}

variable "instance_class" {
  type        = string
  description = "RDS instance class (e.g. db.t3.micro)"
}

variable "allocated_storage" {
  type        = number
  description = "Allocated storage in GB"
}

variable "skip_final_snapshot" {
  type        = bool
  description = "Whether to skip the final DB snapshot"
}

variable "subnet_ids" {
  type        = list(string)
  description = "A list of subnet IDs for the DB subnet group"
}

variable "vpc_security_group_ids" {
  type        = list(string)
  description = "A list of VPC security groups to associate"
}

variable "multi_az" {
  type        = bool
  description = "Specifies if the RDS instance is multi-AZ"
}