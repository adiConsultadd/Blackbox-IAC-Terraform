output "lambda_1_arn" {
  description = "Lambda 1 ARN"
  value       = aws_lambda_function.lambda_1.arn
}

output "lambda_1_name" {
  description = "Lambda 1 name"
  value       = aws_lambda_function.lambda_1.function_name
}

output "lambda_2_arn" {
  description = "Lambda 2 ARN"
  value       = aws_lambda_function.lambda_2.arn
}

output "lambda_2_name" {
  description = "Lambda 2 name"
  value       = aws_lambda_function.lambda_2.function_name
}

output "lambda_3_arn" {
  description = "Lambda 3 ARN"
  value       = aws_lambda_function.lambda_3.arn
}

output "lambda_3_name" {
  description = "Lambda 3 name"
  value       = aws_lambda_function.lambda_3.function_name
}
