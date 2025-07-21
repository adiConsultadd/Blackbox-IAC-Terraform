###############################################################################
# 1. IAM Role (Whole Service)
###############################################################################
locals {
  service_policy_statements = [
    # CloudWatch Logs permissions
    { Effect = "Allow", Action = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"], Resource = ["arn:aws:logs:*:*:*"] },
    # VPC permissions for Lambda to operate within a VPC
    { Effect = "Allow", Action = ["ec2:CreateNetworkInterface", "ec2:DescribeNetworkInterfaces", "ec2:DeleteNetworkInterface"], Resource = "*" },
    # ElastiCache Serverless permissions - Allows connection to ANY cache
    { Effect = "Allow", Action = ["elasticache:Connect"], Resource = "*" },
    # RDS DB permissions - Allows connection to ANY database
    { Effect = "Allow", Action = ["rds-db:connect"], Resource = "*" }
  ]
}

# Create the IAM role once for the service
module "drafting_lambda_role" {
  source = "../../base-infra/iam-lambda"

  role_name         = "${var.project_name}-${var.environment}-drafting-service-role"
  project_name      = var.project_name
  environment       = var.environment
  policy_statements = local.service_policy_statements
}


###############################################################################
# 2. Lambda functions
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
  environment_variables = each.value.env_vars

  # Standard parameters
  s3_bucket        = var.placeholder_s3_bucket
  s3_key           = var.placeholder_s3_key
  source_code_hash = var.placeholder_source_code_hash
  lambda_role_arn  = module.drafting_lambda_role.role_arn

  # VPC configuration
  vpc_subnet_ids         = var.private_subnet_ids
  vpc_security_group_ids = [var.lambda_security_group_id]
}

###############################################################################
# 3. State Machine 
###############################################################################
module "drafting_state_machine" {
  source = "../../base-infra/step-function"

  project_name       = var.project_name
  environment        = var.environment
  state_machine_name = "drafting-workflow"
  definition = templatefile("${path.module}/state-machine.tftpl", {
    rfp_cost_summary_lambda_arn = module.lambda["drafting-rfp-cost-summary"].lambda_arn
    summary_lambda_arn          = module.lambda["drafting-summary"].lambda_arn
    system_summary_lambda_arn   = module.lambda["drafting-system-summary"].lambda_arn
    company_data_lambda_arn     = module.lambda["drafting-company-data"].lambda_arn
    table_of_content_lambda_arn = module.lambda["drafting-table-of-content"].lambda_arn
    user_preference_lambda_arn  = module.lambda["drafting-user-preference"].lambda_arn
  })
}