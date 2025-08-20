###############################################################################
# 1. IAM Role (Whole Service)
###############################################################################
locals {
  service_policy_statements = [
    # CloudWatch Logs permissions
    { Effect = "Allow", Action = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"], Resource = ["arn:aws:logs:*:*:*"] },
    # VPC permissions for Lambda to operate within a VPC
    { Effect = "Allow", Action = ["ec2:CreateNetworkInterface", "ec2:DescribeNetworkInterfaces", "ec2:DeleteNetworkInterface"], Resource = "*" },
    # ElastiCache Serverless permissions
    { Effect = "Allow", Action = ["elasticache:Connect"], Resource = "*" },
    # RDS DB permissions
    { Effect = "Allow", Action = ["rds-db:connect"], Resource = "*" },
    # S3 Full Access
    { Effect = "Allow", Action = ["s3:*"], Resource = ["*"] },
    # Lambda Invoke Permissions
    { Effect = "Allow", Action = ["lambda:InvokeFunction"], Resource = ["*"] },
    # Step Function Invoke Permissions
    { Effect = "Allow", Action = ["states:StartExecution"], Resource = ["*"] },
    {
      Effect   = "Allow",
      Action   = ["states:DescribeExecution", "states:GetExecutionHistory", "states:StopExecution"],
      Resource = ["*"]
    },
    # SSM Parameter Store & KMS Decrypt Permissions
    { Effect = "Allow", Action = ["ssm:GetParameter", "ssm:GetParameters", "ssm:GetParametersByPath"], Resource = "*" },
    { Effect   = "Allow", Action   = "kms:Decrypt", Resource = "*" }
  ]
}

module "validation_lambda_role" {
  source = "../../base-infra/iam-lambda"

  role_name         = "${var.project_name}-${var.environment}-validation-service-role"
  project_name      = var.project_name
  environment       = var.environment
  policy_statements = local.service_policy_statements
}

###############################################################################
# 2. Standard Lambda functions
###############################################################################
module "lambda" {
  for_each = {
    for k, v in var.lambdas : k => v
    if k != "validation-state-machine-executor" 
  }

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

  # Standard parameters from root placeholder
  s3_bucket        = var.placeholder_s3_bucket
  s3_key           = var.placeholder_s3_key
  source_code_hash = var.placeholder_source_code_hash
  lambda_role_arn  = module.validation_lambda_role.role_arn

  # VPC configuration
  vpc_subnet_ids         = var.private_subnet_ids
  vpc_security_group_ids = [var.lambda_security_group_id]
}

###############################################################################
# 3. State Machine
###############################################################################
module "validation_state_machine" {
  source = "../../base-infra/step-function"

  project_name       = var.project_name
  environment        = var.environment
  state_machine_name = "validation-workflow"
  state_machine_type = "STANDARD"
  definition = templatefile("${path.module}/state-machine.tftpl", {
    legal_req_lambda_arn = module.lambda["validation-legal-requirements"].lambda_arn
    tech_req_lambda_arn  = module.lambda["validation-technical-requirements"].lambda_arn
  })
}

###############################################################################
# 4. State Machine Executor Lambda
###############################################################################
module "state_machine_executor_lambda" {
  source        = "../../base-infra/lambda"
  function_name = "${var.project_name}-${var.environment}-validation-state-machine-executor"

  # Configuration from the .tfvars file
  runtime       = var.lambdas["validation-state-machine-executor"].runtime
  timeout       = var.lambdas["validation-state-machine-executor"].timeout
  memory_size   = var.lambdas["validation-state-machine-executor"].memory_size
  layers        = [for layer_key in var.lambdas["validation-state-machine-executor"].layers : var.available_layer_arns[layer_key]]

  # Inject the Step Function ARN into this specific Lambda
  environment_variables = {
    BLACKBOX_VALIDATION_STEP_FUNCTION_ARN = module.validation_state_machine.state_machine_arn
    SSM_PREFIX                   = "blackbox-${var.environment}"
  }

  # Standard parameters from root placeholder
  s3_bucket        = var.placeholder_s3_bucket
  s3_key           = var.placeholder_s3_key
  source_code_hash = var.placeholder_source_code_hash
  lambda_role_arn  = module.validation_lambda_role.role_arn

  # VPC configuration
  vpc_subnet_ids         = var.private_subnet_ids
  vpc_security_group_ids = [var.lambda_security_group_id]
}