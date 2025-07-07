variable "environment" {
  type        = string
  description = "Environment name"
}

variable "project_name" {
  type        = string
  description = "Project name"
}

variable "node_type" {
  type        = string
  description = "The instance class for the ElastiCache node(s)"
}

variable "num_cache_nodes" {
  type        = number
  description = "The number of cache nodes in the cluster"
}

variable "engine_version" {
  type        = string
  description = "The Redis engine version"
}

variable "subnet_ids" {
  type        = list(string)
  description = "A list of subnet IDs for the ElastiCache subnet group"
}

variable "vpc_security_group_ids" {
  type        = list(string)
  description = "A list of VPC security groups to associate with the cluster"
}