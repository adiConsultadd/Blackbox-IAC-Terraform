data "archive_file" "lambda_1" {
  type        = "zip"
  source_dir  = "${path.module}/lambda-code/lambda-1/"
  output_path = "${path.module}/lambda-code/lambda-1/index.zip"
}

resource "aws_lambda_function" "lambda_1" {
  filename         = data.archive_file.lambda_1.output_path
  function_name    = "${var.project_name}-${var.environment}-hello-world"
  role             = var.lambda_role_arn
  handler          = "index.handler"
  runtime          = "python3.9"
  timeout          = 30
  memory_size      = 128

  source_code_hash = data.archive_file.lambda_1.output_base64sha256

  environment {
    variables = {
      EXAMPLE_ENV_VAR = "HelloWorld"
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.lambda_1
  ]
}

resource "aws_cloudwatch_log_group" "lambda_1" {
  name              = "/aws/lambda/${var.project_name}-${var.environment}-hello-world"
  retention_in_days = 7
}

