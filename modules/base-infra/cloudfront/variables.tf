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

variable "price_class" {
  type        = string
  description = "CloudFront price class"
}

variable "viewer_protocol_policy" {
  type        = string
  description = "Viewer protocol policy"
}

variable "default_root_object" {
  type        = string
  description = "Default root object"
}

variable "enabled" {
  type        = bool
  description = "Whether CloudFront distribution is enabled"
}
