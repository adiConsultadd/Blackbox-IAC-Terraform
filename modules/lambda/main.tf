###############################################################################
# Lambda 1
###############################################################################
data "archive_file" "lambda_1" {
  type        = "zip"
  source_dir  = "${path.module}/lambda-code/lambda-1/"
  output_path = "${path.module}/lambda-code/lambda-1/index.zip"
}

resource "aws_cloudwatch_log_group" "lambda_1" {
  name              = "/aws/lambda/${var.project_name}-${var.environment}-lambda-1"
  retention_in_days = 7
}

resource "aws_lambda_function" "lambda_1" {
  filename         = data.archive_file.lambda_1.output_path
  function_name    = "${var.project_name}-${var.environment}-lambda-1"
  role             = var.lambda_role_arn
  handler          = "index.handler"
  runtime          = "python3.9"
  timeout          = 30
  memory_size      = 128

  source_code_hash = data.archive_file.lambda_1.output_base64sha256

  environment {
    variables = {
      EXAMPLE_ENV_VAR = "HelloWorld-lambda1"
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.lambda_1
  ]
}

###############################################################################
# Lambda 2
###############################################################################
data "archive_file" "lambda_2" {
  type        = "zip"
  source_dir  = "${path.module}/lambda-code/lambda-2/"
  output_path = "${path.module}/lambda-code/lambda-2/index.zip"
}

resource "aws_cloudwatch_log_group" "lambda_2" {
  name              = "/aws/lambda/${var.project_name}-${var.environment}-lambda-2"
  retention_in_days = 7
}

resource "aws_lambda_function" "lambda_2" {
  filename         = data.archive_file.lambda_2.output_path
  function_name    = "${var.project_name}-${var.environment}-lambda-2"
  role             = var.lambda_role_arn
  handler          = "index.handler"
  runtime          = "python3.9"
  timeout          = 30
  memory_size      = 128
  source_code_hash = data.archive_file.lambda_2.output_base64sha256

  environment {
    variables = {
      EXAMPLE_ENV_VAR = "HelloWorld-lambda2"
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.lambda_2
  ]
}

###############################################################################
# Lambda 3
###############################################################################
data "archive_file" "lambda_3" {
  type        = "zip"
  source_dir  = "${path.module}/lambda-code/lambda-3/"
  output_path = "${path.module}/lambda-code/lambda-3/index.zip"
}

resource "aws_cloudwatch_log_group" "lambda_3" {
  name              = "/aws/lambda/${var.project_name}-${var.environment}-lambda-3"
  retention_in_days = 7
}

resource "aws_lambda_function" "lambda_3" {
  filename         = data.archive_file.lambda_3.output_path
  function_name    = "${var.project_name}-${var.environment}-lambda-3"
  role             = var.lambda_role_arn
  handler          = "index.handler"
  runtime          = "python3.9"
  timeout          = 30
  memory_size      = 128
  source_code_hash = data.archive_file.lambda_3.output_base64sha256

  environment {
    variables = {
      EXAMPLE_ENV_VAR = "HelloWorld-lambda3"
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.lambda_3
  ]
}
