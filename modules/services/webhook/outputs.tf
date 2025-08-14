output "lambda_arns" {
  description = "Map of Lambda function ARNs for the webhook service"
  value       = { for k, m in module.lambda : k => m.lambda_arn }
}

output "api_gateway_invoke_url" {
  description = "The invoke URL for the Webhook API Gateway stage."
  value       = aws_api_gateway_stage.this.invoke_url
}