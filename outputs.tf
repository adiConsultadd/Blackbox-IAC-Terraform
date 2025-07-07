output "sourcing_s3_bucket" {
  description = "Name of the S3 bucket used by the sourcing feature"
  value       = module.sourcing.s3_bucket_name
}

output "cdn_domain_name" {
  description = "CloudFront distribution domain name for the sourcing service"
  value       = module.sourcing.cloudfront_domain
}

output "eventbridge_rule_arn" {
  description = "ARN of the EventBridge scheduled rule for the sourcing service"
  value       = module.sourcing.eventbridge_rule_arn
}

output "rds_database_endpoint" {
  description = "Endpoint of the shared RDS database"
  value       = module.rds.db_endpoint
}

output "elasticache_cluster_endpoint" {
  description = "Endpoint of the shared ElastiCache Redis cluster"
  value       = module.elasticache.endpoint
}

output "vpc_id" {
  description = "ID of the shared VPC"
  value       = module.networking.vpc_id
}