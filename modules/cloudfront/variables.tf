variable "environment" { 
  type        = string
  description = "Environment name"
}

variable "project_name" {
  type        = string
  description = "Project name"
}

variable "s3_bucket_name" {
  type        = string
  description = "Bucket to serve from CloudFront"
}
