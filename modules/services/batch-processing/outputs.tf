output "rest_api_url" {
  description = "The invoke URL for the batch Processing REST API."
  value       = aws_api_gateway_stage.rest_api_stage.invoke_url
}

output "websocket_api_url" {
  description = "The invoke URL for the batch Processing WebSocket API."
  value       = aws_apigatewayv2_stage.websocket_stage.invoke_url
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket for batch processing"
  value       = module.s3.bucket_name
}

output "lambda_arns" {
  description = "Map of Lambda function ARNs for the batch processing service"
  value = merge(
    { for k, m in module.lambda : k => m.lambda_arn },
    { for k, l in aws_lambda_function.lambda_ecr : k => l.arn }
  )
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket for batch processing"
  value       = module.s3.bucket_arn
}