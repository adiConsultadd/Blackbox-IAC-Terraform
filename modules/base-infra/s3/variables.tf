variable "environment" {
  type        = string
  description = "Environment"
}

variable "project_name" {
  type        = string
  description = "Project name"
}
 
variable "bucket_suffix" {
  type = string
  description = "Suffix to be attached to the S3-bucket"
}