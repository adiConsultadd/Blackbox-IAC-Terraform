# modules/services/webhook/main.tf

###############################################################################
# 1. IAM Role (Whole Service)
###############################################################################
locals {
  service_policy_statements = [
    # CloudWatch Logs permissions
    { Effect = "Allow", Action = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"], Resource = ["arn:aws:logs:*:*:*"] },
    # VPC permissions for Lambda to operate within a VPC
    { Effect = "Allow", Action = ["ec2:CreateNetworkInterface", "ec2:DescribeNetworkInterfaces", "ec2:DeleteNetworkInterface"], Resource = "*" },
    # S3 Access (if needed)
    { Effect = "Allow", Action = ["s3:*"], Resource = ["*"] },
    # SSM Parameter Store Access
    {
      Effect = "Allow",
      Action = [
        "ssm:GetParameter",
        "ssm:GetParameters",
        "ssm:GetParametersByPath"
      ],
      Resource = "*"
    },
    # KMS Decrypt for SecureString SSM parameters
    {
      Effect   = "Allow",
      Action   = "kms:Decrypt",
      Resource = "*"
    }
  ]
}

module "webhook_lambda_role" {
  source = "../../base-infra/iam-lambda"

  role_name         = "${var.project_name}-${var.environment}-webhook-service-role"
  project_name      = var.project_name
  environment       = var.environment
  policy_statements = local.service_policy_statements
}

###############################################################################
# 2. Lambda function
###############################################################################
module "lambda" {
  for_each = var.lambdas

  source        = "../../base-infra/lambda"
  function_name = "${var.project_name}-${var.environment}-${each.key}"

  # Configuration from the .tfvars file
  runtime       = each.value.runtime
  timeout       = each.value.timeout
  memory_size   = each.value.memory_size
  layers        = [for layer_key in each.value.layers : var.available_layer_arns[layer_key]]
  environment_variables = merge(
    each.value.env_vars,
    { SSM_PREFIX = "blackbox-${var.environment}" }
  )

  # Standard parameters using the global placeholder
  s3_bucket          = var.placeholder_s3_bucket
  s3_key             = var.placeholder_s3_key
  source_code_hash   = var.placeholder_source_code_hash
  lambda_role_arn    = module.webhook_lambda_role.role_arn

  # VPC configuration
  vpc_subnet_ids         = var.private_subnet_ids
  vpc_security_group_ids = [var.lambda_security_group_id]
}

###############################################################################
# 3. API Gateway
###############################################################################

# REST API
resource "aws_api_gateway_rest_api" "this" {
  name        = "${var.project_name}-${var.environment}-webhook-api"
  description = "API Gateway for the Webhook service"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# Resource: /webhook
resource "aws_api_gateway_resource" "webhook" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_rest_api.this.root_resource_id
  path_part   = "webhook"
}

# Method: GET /
resource "aws_api_gateway_method" "get_root" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_rest_api.this.root_resource_id
  http_method   = "GET"
  authorization = "NONE"
}

# Method: POST /webhook
resource "aws_api_gateway_method" "post_webhook" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_resource.webhook.id
  http_method   = "POST"
  authorization = "NONE"
}

# Integration: GET / -> Lambda
resource "aws_api_gateway_integration" "get_root" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_rest_api.this.root_resource_id
  http_method = aws_api_gateway_method.get_root.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = module.lambda["webhook"].invoke_arn
}

# Integration: POST /webhook -> Lambda
resource "aws_api_gateway_integration" "post_webhook" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.webhook.id
  http_method = aws_api_gateway_method.post_webhook.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = module.lambda["webhook"].invoke_arn
}

# Deployment - triggered by changes to the API structure
resource "aws_api_gateway_deployment" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.webhook.id,
      aws_api_gateway_method.get_root.id,
      aws_api_gateway_method.post_webhook.id,
      aws_api_gateway_integration.get_root.id,
      aws_api_gateway_integration.post_webhook.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Stage
resource "aws_api_gateway_stage" "this" {
  deployment_id = aws_api_gateway_deployment.this.id
  rest_api_id   = aws_api_gateway_rest_api.this.id
  stage_name    = var.environment
}

# Lambda Permission
resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda["webhook"].lambda_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.this.execution_arn}/*/*"
}
