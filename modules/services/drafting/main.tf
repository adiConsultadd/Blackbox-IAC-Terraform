###############################################################################
# 1. Lambda definitions (source dir, env vars, IAM policy)
###############################################################################
locals {
  project_lambda = "arn:aws:lambda:*:*:function:${var.project_name}-${var.environment}-lambda_*"
  lambdas = {
    drafting-rfp-cost-summary = {
      source_dir = "${path.module}/lambda-code/blackbox_rfp_cost_summary_lambda"
      env        = { EXAMPLE_ENV_VAR = "RfpCostSummaryLambda" }
      policy_statements = [
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
    drafting-company-data = {
      source_dir = "${path.module}/lambda-code/blackbox_company_data_lambda"
      env        = { EXAMPLE_ENV_VAR = "CompanyDataLambda" }
      policy_statements = [
        { Effect = "Allow", Action = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"], Resource = ["arn:aws:logs:*:*:*"] },
        { Effect = "Allow", Action = ["ec2:CreateNetworkInterface", "ec2:DescribeNetworkInterfaces", "ec2:DeleteNetworkInterface"], Resource = "*" },
        { Effect = "Allow", Action = ["elasticache:Connect"], Resource = "*" },
        { Effect = "Allow", Action = ["rds-db:connect"], Resource = "*" }
      ]
    }
    drafting-content-regeneration = {
      source_dir = "${path.module}/lambda-code/blackbox_content_regeneration_lambda"
      env        = { EXAMPLE_ENV_VAR = "ContentRegenerationLambda" }
      policy_statements = [
        { Effect = "Allow", Action = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"], Resource = ["arn:aws:logs:*:*:*"] },
        { Effect = "Allow", Action = ["ec2:CreateNetworkInterface", "ec2:DescribeNetworkInterfaces", "ec2:DeleteNetworkInterface"], Resource = "*" },
        { Effect = "Allow", Action = ["elasticache:Connect"], Resource = "*" },
        { Effect = "Allow", Action = ["rds-db:connect"], Resource = "*" }
      ]
    }
    drafting-extract-text = {
      source_dir = "${path.module}/lambda-code/blackbox_extract_text_from_file"
      env        = { EXAMPLE_ENV_VAR = "ExtractTextLambda" }
      policy_statements = [
        { Effect = "Allow", Action = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"], Resource = ["arn:aws:logs:*:*:*"] },
        { Effect = "Allow", Action = ["ec2:CreateNetworkInterface", "ec2:DescribeNetworkInterfaces", "ec2:DeleteNetworkInterface"], Resource = "*" },
        { Effect = "Allow", Action = ["elasticache:Connect"], Resource = "*" },
        { Effect = "Allow", Action = ["rds-db:connect"], Resource = "*" }
      ]
    }
    drafting-section-content = {
      source_dir = "${path.module}/lambda-code/blackbox_section_content_lambda"
      env        = { EXAMPLE_ENV_VAR = "SectionContentLambda" }
      policy_statements = [
        { Effect = "Allow", Action = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"], Resource = ["arn:aws:logs:*:*:*"] },
        { Effect = "Allow", Action = ["ec2:CreateNetworkInterface", "ec2:DescribeNetworkInterfaces", "ec2:DeleteNetworkInterface"], Resource = "*" },
        { Effect = "Allow", Action = ["elasticache:Connect"], Resource = "*" },
        { Effect = "Allow", Action = ["rds-db:connect"], Resource = "*" }
      ]
    }
    drafting-summary = {
      source_dir = "${path.module}/lambda-code/blackbox_summary_lambda"
      env        = { EXAMPLE_ENV_VAR = "SummaryLambda" }
      policy_statements = [
        { Effect = "Allow", Action = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"], Resource = ["arn:aws:logs:*:*:*"] },
        { Effect = "Allow", Action = ["ec2:CreateNetworkInterface", "ec2:DescribeNetworkInterfaces", "ec2:DeleteNetworkInterface"], Resource = "*" },
        { Effect = "Allow", Action = ["elasticache:Connect"], Resource = "*" },
        { Effect = "Allow", Action = ["rds-db:connect"], Resource = "*" }
      ]
    }
    drafting-system-summary = {
      source_dir = "${path.module}/lambda-code/blackbox_system_summary_lambda"
      env        = { EXAMPLE_ENV_VAR = "SystemSummaryLambda" }
      policy_statements = [
        { Effect = "Allow", Action = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"], Resource = ["arn:aws:logs:*:*:*"] },
        { Effect = "Allow", Action = ["ec2:CreateNetworkInterface", "ec2:DescribeNetworkInterfaces", "ec2:DeleteNetworkInterface"], Resource = "*" },
        { Effect = "Allow", Action = ["elasticache:Connect"], Resource = "*" },
        { Effect = "Allow", Action = ["rds-db:connect"], Resource = "*" }
      ]
    }
    drafting-table-of-content = {
      source_dir = "${path.module}/lambda-code/blackbox_table_of_content_lambda"
      env        = { EXAMPLE_ENV_VAR = "TableOfContentLambda" }
      policy_statements = [
        { Effect = "Allow", Action = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"], Resource = ["arn:aws:logs:*:*:*"] },
        { Effect = "Allow", Action = ["ec2:CreateNetworkInterface", "ec2:DescribeNetworkInterfaces", "ec2:DeleteNetworkInterface"], Resource = "*" },
        { Effect = "Allow", Action = ["elasticache:Connect"], Resource = "*" },
        { Effect = "Allow", Action = ["rds-db:connect"], Resource = "*" }
      ]
    }
    drafting-toc-enrichment = {
      source_dir = "${path.module}/lambda-code/blackbox_toc_enrichment_lambda"
      env        = { EXAMPLE_ENV_VAR = "TocEnrichmentLambda" }
      policy_statements = [
        { Effect = "Allow", Action = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"], Resource = ["arn:aws:logs:*:*:*"] },
        { Effect = "Allow", Action = ["ec2:CreateNetworkInterface", "ec2:DescribeNetworkInterfaces", "ec2:DeleteNetworkInterface"], Resource = "*" },
        { Effect = "Allow", Action = ["elasticache:Connect"], Resource = "*" },
        { Effect = "Allow", Action = ["rds-db:connect"], Resource = "*" }
      ]
    }
    drafting-user-preference = {
      source_dir = "${path.module}/lambda-code/blackbox_user_preference_lambda"
      env        = { EXAMPLE_ENV_VAR = "UserPreferenceLambda" }
      policy_statements = [
        { Effect = "Allow", Action = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"], Resource = ["arn:aws:logs:*:*:*"] },
        { Effect = "Allow", Action = ["ec2:CreateNetworkInterface", "ec2:DescribeNetworkInterfaces", "ec2:DeleteNetworkInterface"], Resource = "*" },
        { Effect = "Allow", Action = ["elasticache:Connect"], Resource = "*" },
        { Effect = "Allow", Action = ["rds-db:connect"], Resource = "*" }
      ]
    }
    drafting-toc-regenerate = {
      source_dir = "${path.module}/lambda-code/blackbox_toc_regenerate_lambda"
      env        = { EXAMPLE_ENV_VAR = "TocRegenerateLambda" }
      policy_statements = [
        { Effect = "Allow", Action = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"], Resource = ["arn:aws:logs:*:*:*"] },
        { Effect = "Allow", Action = ["ec2:CreateNetworkInterface", "ec2:DescribeNetworkInterfaces", "ec2:DeleteNetworkInterface"], Resource = "*" },
        { Effect = "Allow", Action = ["elasticache:Connect"], Resource = "*" },
        { Effect = "Allow", Action = ["rds-db:connect"], Resource = "*" }
      ]
    }
  }
}

###############################################################################
# 2. IAM role per Lambda
###############################################################################
module "lambda_roles" {
  for_each = local.lambdas
  source   = "../../base-infra/iam-lambda"

  role_name         = "${var.project_name}-${var.environment}-${each.key}-role"
  project_name      = var.project_name
  environment       = var.environment
  policy_statements = each.value.policy_statements
}

###############################################################################
# 3. Lambda functions
###############################################################################
module "lambda" {
  for_each = local.lambdas
  source   = "../../base-infra/lambda"

  function_name          = "${var.project_name}-${var.environment}-${each.key}"
  source_dir             = each.value.source_dir
  lambda_role_arn        = module.lambda_roles[each.key].role_arn
  environment_variables  = each.value.env
  vpc_subnet_ids         = var.private_subnet_ids
  vpc_security_group_ids = [var.lambda_security_group_id]
}


# ###############################################################################
# # 4. State Machine
# ###############################################################################
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