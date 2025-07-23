output "bucket_name" {
  description = "Name of the RFP S3 bucket"
  value       = aws_s3_bucket.mys3bucket.bucket
}

output "bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.mys3bucket.arn
}

output "bucket_regional_domain_name" {
  description = "The regional domain name of the S3 bucket"
  value       = aws_s3_bucket.mys3bucket.bucket_regional_domain_name
}