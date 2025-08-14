###############################################################################
# 1. IAM Role (Whole Service)
###############################################################################
locals {
  service_policy_statements = [
    # CloudWatch Logs permissions
    { Effect = "Allow", Action = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"], Resource = ["arn:aws:logs:*:*:*"] },
    # VPC permissions for Lambda to operate within a VPC
    { Effect = "Allow", Action = ["ec2:CreateNetworkInterface", "ec2:DescribeNetworkInterfaces", "ec2:DeleteNetworkInterface"], Resource = "*" },
    # ElastiCache (Redis) permissions
    { Effect = "Allow", Action = ["elasticache:Connect"], Resource = "*" },
    # RDS DB (Postgres) permissions
    { Effect = "Allow", Action = ["rds-db:connect"], Resource = "*" },
    # S3 Access
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

module "data_migration_lambda_role" {
  source = "../../base-infra/iam-lambda"

  role_name         = "${var.project_name}-${var.environment}-data-migration-role"
  project_name      = var.project_name
  environment       = var.environment
  policy_statements = local.service_policy_statements
}

###############################################################################
# 2. Lambda Function
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
  s3_bucket        = var.placeholder_s3_bucket
  s3_key           = var.placeholder_s3_key
  source_code_hash = var.placeholder_source_code_hash
  lambda_role_arn  = module.data_migration_lambda_role.role_arn

  # VPC configuration
  vpc_subnet_ids         = var.private_subnet_ids
  vpc_security_group_ids = [var.lambda_security_group_id]
}

###############################################################################
# 3. EventBridge Scheduler
###############################################################################
module "eventbridge" {
  source      = "../../base-infra/eventbridge"
  environment = var.environment
  project_name = var.project_name
  suffix      = "daily-trigger-data-migration"

  # Target the specific lambda created in this module
  lambda_arn_to_trigger = module.lambda["redis-postgres-migration"].lambda_arn
  schedule_expression   = var.eventbridge_schedule_expression
}