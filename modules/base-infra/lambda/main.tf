locals {
  zip_path = "${path.module}/build/${replace(var.function_name, "/", "-")}.zip"
}

# Package source into a ZIP
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = var.source_dir
  output_path = local.zip_path
}

# Dedicated CloudWatch Log Group
resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = 7
}

# Lambda Function
resource "aws_lambda_function" "this" {
  function_name    = var.function_name
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  role        = var.lambda_role_arn
  handler     = var.handler
  runtime     = var.runtime
  timeout     = var.timeout
  memory_size = var.memory_size

  environment { variables = var.environment_variables }

  depends_on = [aws_cloudwatch_log_group.this]
}
