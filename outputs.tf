output "sourcing_s3_bucket" {
  description = "Name of the S3 bucket used by the sourcing feature"
  value       = module.sourcing.s3_bucket_name
}

output "cdn_domain_name" {
  description = "CloudFront distribution domain name"
  value       = module.sourcing.cloudfront_domain
}

output "eventbridge_rule_arn" {
  description = "ARN of the EventBridge scheduled rule"
  value       = module.sourcing.eventbridge_rule_arn
}
