output "distribution_id" {
  description = "CloudFront distribution ID"
  value       = aws_cloudfront_distribution.mycdn.id
}

output "distribution_domain_name" {
  description = "CloudFront distribution domain name"
  value       = aws_cloudfront_distribution.mycdn.domain_name
}
