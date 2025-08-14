output "lambda_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.this.arn
}

output "lambda_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.this.function_name
}

output "invoke_arn" {
  description = "The ARN to be used for invoking the function from other services, like API Gateway."
  value       = aws_lambda_function.this.invoke_arn
}