###############################################################################
# 1. Lambda definitions (source dir, env vars, IAM policy)
###############################################################################
locals {
  project_lambda = "arn:aws:lambda:*:*:function:${var.project_name}-${var.environment}-lambda_*"
  lambdas = {
    costing-hourly-wages = {
      source_dir = "${path.module}/lambda-code/blackbox_hourly_wages_lambda"
      env        = { EXAMPLE_ENV_VAR = "HourlyWagesLambda" }
      policy_statements = [
        { Effect = "Allow", Action = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"], Resource = ["arn:aws:logs:*:*:*"] }
      ]
    }
    costing-hourly-wages-result = {
      source_dir = "${path.module}/lambda-code/blackbox_hourly_wages_result_lambda"
      env        = { EXAMPLE_ENV_VAR = "HourlyWagesResultLambda" }
      policy_statements = [
        { Effect = "Allow", Action = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"], Resource = ["arn:aws:logs:*:*:*"] }
      ]
    }
    costing-rfp-cost-formating = {
      source_dir = "${path.module}/lambda-code/blackbox_rfp_cost_formating_lambda"
      env        = { EXAMPLE_ENV_VAR = "RfpCostFormatingLambda" }
      policy_statements = [
        { Effect = "Allow", Action = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"], Resource = ["arn:aws:logs:*:*:*"] }
      ]
    }
    costing-rfp-cost-image-calculation = {
      source_dir = "${path.module}/lambda-code/blackbox_rfp_cost_image_calculation_lambda"
      env        = { EXAMPLE_ENV_VAR = "RfpCostImageCalculationLambda" }
      policy_statements = [
        { Effect = "Allow", Action = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"], Resource = ["arn:aws:logs:*:*:*"] }
      ]
    }
    costing-rfp-cost-image-extractor = {
      source_dir = "${path.module}/lambda-code/blackbox_rfp_cost_image_extractor_lambda"
      env        = { EXAMPLE_ENV_VAR = "RfpCostImageExtractorLambda" }
      policy_statements = [
        { Effect = "Allow", Action = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"], Resource = ["arn:aws:logs:*:*:*"] }
      ]
    }
    costing-rfp-cost-regenerating = {
      source_dir = "${path.module}/lambda-code/blackbox_rfp_cost_regenerating_lambda"
      env        = { EXAMPLE_ENV_VAR = "RfpCostRegeneratingLambda" }
      policy_statements = [
        { Effect = "Allow", Action = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"], Resource = ["arn:aws:logs:*:*:*"] }
      ]
    }
    costing-rfp-cost-summary = {
      source_dir = "${path.module}/lambda-code/blackbox_rfp_cost_summary_lambda"
      env        = { EXAMPLE_ENV_VAR = "RfpCostSummaryLambda" }
      policy_statements = [
        { Effect = "Allow", Action = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"], Resource = ["arn:aws:logs:*:*:*"] }
      ]
    }
    costing-rfp-infrastructure = {
      source_dir = "${path.module}/lambda-code/blackbox_rfp_infrastructure_lambda"
      env        = { EXAMPLE_ENV_VAR = "RfpInfrastructureLambda" }
      policy_statements = [
        { Effect = "Allow", Action = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"], Resource = ["arn:aws:logs:*:*:*"] }
      ]
    }
    costing-rfp-license = {
      source_dir = "${path.module}/lambda-code/blackbox_rfp_license_lambda"
      env        = { EXAMPLE_ENV_VAR = "RfpLicenseLambda" }
      policy_statements = [
        { Effect = "Allow", Action = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"], Resource = ["arn:aws:logs:*:*:*"] }
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