variable "environment" {
  type = string
}
variable "project_name" {
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