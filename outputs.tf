output "lambda_role_arn" {
  description = "Lambda execution role ARN"
  value       = module.iam.lambda_role_arn
}

output "lambda_1_arn" {
  description = "Lambda 1 ARN"
  value       = module.lambda.lambda_1_arn
}

output "lambda_1_name" {
  description = "Lambda 1 name"
  value       = module.lambda.lambda_1_name
}

output "lambda_2_arn" {
  description = "Lambda 1 ARN"
  value       = module.lambda.lambda_2_arn
}

output "lambda_2_name" {
  description = "Lambda 1 name"
  value       = module.lambda.lambda_2_name
}

output "lambda_3_arn" {
  description = "Lambda 1 ARN"
  value       = module.lambda.lambda_3_arn
}

output "lambda_3_name" {
  description = "Lambda 1 name"
  value       = module.lambda.lambda_3_name
}

# output "db_endpoint" {
#   description = "RDS endpoint"
#   value       = module.rds.db_endpoint
# }

# output "db_identifier" {
#   description = "RDS identifier"
#   value       = module.rds.db_identifier
# }

#  output "s3_bucket_name" {
#   description = "Name of the RFP S3 bucket"
#   value       = module.s3.bucket_name
# }
