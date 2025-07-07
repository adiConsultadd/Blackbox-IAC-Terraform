output "name" {
  description = "The full name of the SSM parameter"
  value       = aws_ssm_parameter.this.name
}

output "arn" {
  description = "The ARN of the SSM parameter"
  value       = aws_ssm_parameter.this.arn
}