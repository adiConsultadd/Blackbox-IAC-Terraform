# Dedicated CloudWatch Log Group
resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = 7
}

# Lambda Function
resource "aws_lambda_function" "this" {
  function_name = var.function_name
  layers        = var.layers

  # Deploy from S3 instead of local zip file
  s3_bucket        = var.s3_bucket
  s3_key           = var.s3_key
  source_code_hash = var.source_code_hash

  role        = var.lambda_role_arn
  handler     = var.handler
  runtime     = var.runtime
  timeout     = var.timeout
  memory_size = var.memory_size

  environment { variables = var.environment_variables }

  vpc_config {
    subnet_ids         = var.vpc_subnet_ids
    security_group_ids = var.vpc_security_group_ids
  }

  depends_on = [aws_cloudwatch_log_group.this]
}