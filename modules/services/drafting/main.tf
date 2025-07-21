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
# 2. Lambda function definitions
###############################################################################
locals {
  lambdas = {
    "drafting-rfp-cost-summary"   = { layers = ["common", "openai"] }
    "drafting-company-data"       = { layers = ["common"] }
    "drafting-content-regeneration" = { layers = ["common", "google"] }
    "drafting-executive-summary"  = { layers = ["common", "openai"] }
    "drafting-extract-text"       = { layers = ["common"] }
    "drafting-section-content"    = { layers = ["common", "google"] }
    "drafting-summary"            = { layers = ["common", "openai"] }
    "drafting-system-summary"     = { layers = ["common", "openai"] }
    "drafting-table-of-content"   = { layers = ["common", "google"] }
    "drafting-toc-enrichment"     = { layers = ["common", "google"] }
    "drafting-user-preference"    = { layers = ["common"] }
    "drafting-toc-regenerate"     = { layers = ["common", "google"] }
  }
}

###############################################################################
# 3. Lambda functions
###############################################################################
module "lambda" {
  for_each = local.lambdas
  source   = "../../base-infra/lambda"
  runtime       = var.lambda_configs[each.key].runtime
  timeout       = var.lambda_configs[each.key].timeout
  memory_size   = var.lambda_configs[each.key].memory_size
  
  function_name = "${var.project_name}-${var.environment}-${each.key}"

  # Deploy from the placeholder artifact in S3
  s3_bucket        = var.placeholder_s3_bucket
  s3_key           = var.placeholder_s3_key
  source_code_hash = var.placeholder_source_code_hash

  # All functions now use the SAME role ARN
  lambda_role_arn = module.drafting_lambda_role.role_arn

  # VPC config remains the same
  vpc_subnet_ids         = var.private_subnet_ids
  vpc_security_group_ids = [var.lambda_security_group_id]

  # Attaching the lambda layers
  layers = [for layer_key in each.value.layers : var.available_layer_arns[layer_key]]
}

###############################################################################
# 4. State Machine 
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