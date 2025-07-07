variable "environment" {
  type        = string
  description = "Environment name"
}

variable "project_name" {
  type        = string
  description = "Project name"
}

variable "subnet_ids" {
  type        = list(string)
  description = "A list of subnet IDs for the ElastiCache subnet group"
}

variable "vpc_security_group_ids" {
  type        = list(string)
  description = "A list of VPC security groups to associate with the cluster"
}