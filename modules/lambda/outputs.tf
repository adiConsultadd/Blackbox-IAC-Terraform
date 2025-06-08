output "lambda_1_arn" {
  description = "Lambda 1 ARN"
  value       = aws_lambda_function.lambda_1.arn
}

output "lambda_1_name" {
  description = "Lambda 1 name"
  value       = aws_lambda_function.lambda_1.function_name
}
