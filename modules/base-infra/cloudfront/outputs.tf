output "distribution_id" {
  description = "CloudFront distribution ID"
  value       = aws_cloudfront_distribution.this.id
}

output "distribution_domain_name" {
  description = "CloudFront distribution domain name"
  value       = aws_cloudfront_distribution.this.domain_name
}

output "distribution_arn" {
  description = "The ARN of the CloudFront distribution"
  value       = aws_cloudfront_distribution.this.arn
}