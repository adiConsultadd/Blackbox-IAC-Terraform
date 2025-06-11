# output "lambda_arns" {
#   description = "Map of Lambda function ARNs (lambda_1…lambda_3)"
#   value       = { for k, m in module.lambda : k => m.lambda_arn }
# }

output "s3_bucket_name" {
  description = "Primary S3 bucket for the sourcing feature"
  value       = module.s3.bucket_name
}

# output "cloudfront_domain" {
#   description = "CloudFront distribution domain name"
#   value       = module.cloudfront.distribution_domain_name
# }

# output "eventbridge_rule_arn" {
#   description = "ARN of the scheduled EventBridge rule"
#   value       = module.eventbridge.eventbridge_rule_arn
# }

# output "db_endpoint" {
#   description = "RDS endpoint for sourcing feature"
#   value       = module.rds.db_endpoint
# }
