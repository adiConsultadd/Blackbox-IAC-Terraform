output "sourcing_s3_bucket" {
  description = "Name of the S3 bucket used by the sourcing feature"
  value       = module.sourcing.s3_bucket_name
}

output "lambda_names" {
  description = "Map of Lambda function names"
  value = {
    for k, inst in module.sourcing.lambda :
    k => inst.lambda_name
  }
}

output "lambda_arns" {
  description = "Map of Lambda function ARNs"
  value = {
    for k, inst in module.sourcing.lambda :
    k => inst.lambda_arn
  }
}

output "cdn_distribution_id" {
  description = "CloudFront distribution ID"
  value       = module.sourcing.cloudfront.distribution_id
}

output "cdn_domain_name" {
  description = "CloudFront distribution domain name"
  value       = module.sourcing.cloudfront.distribution_domain_name
}

output "eventbridge_rule_arn" {
  description = "ARN of the EventBridge scheduled rule"
  value       = module.sourcing.eventbridge.eventbridge_rule_arn
}
