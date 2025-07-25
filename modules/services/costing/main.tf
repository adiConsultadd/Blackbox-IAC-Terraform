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
    { Effect = "Allow", Action = ["rds-db:connect"], Resource = "*" },
    # RDS DB permissions - Allows connection to ANY database
    { Effect = "Allow", Action = ["rds-db:connect"], Resource = "*" },
    # Full SSM Permissions
    { Effect = "Allow", Action = ["ssm:*"], Resource = "*" },
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
    }
  ]
}
module "costing_lambda_role" {
  source = "../../base-infra/iam-lambda"

  role_name         = "${var.project_name}-${var.environment}-costing-service-role"
  project_name      = var.project_name
  environment       = var.environment
  policy_statements = local.service_policy_statements
}

###############################################################################
# 2. Lambda functions (referencing the single service role)
###############################################################################
module "lambda" {
  for_each = {
    for k, v in var.lambdas : k => v
    if k != "costing-cost-step-machine" && k != "costing-hourly-wages"
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
  # Standard parameters
  s3_bucket        = var.placeholder_s3_bucket
  s3_key           = var.placeholder_s3_key
  source_code_hash = var.placeholder_source_code_hash
  lambda_role_arn  = module.costing_lambda_role.role_arn

  # VPC configuration
  vpc_subnet_ids         = var.private_subnet_ids
  vpc_security_group_ids = [var.lambda_security_group_id]
}

###############################################################################
# 3. ECR-Based Lambda (Costing-Hourly-Wages)
###############################################################################
resource "aws_ecr_repository" "hourly_wages_repo" {
  name                 = "${var.project_name}-${var.environment}-costing-hourly-wages"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

# Step A: Build the placeholder image locally using the Docker provider
resource "docker_image" "hourly_wages_placeholder" {
  name = "${aws_ecr_repository.hourly_wages_repo.repository_url}:placeholder"
  build {
    context = "${path.module}/placeholder-image"
    platform = "linux/amd64" # Specify architecture for compatibility
  }
}

# Step B: Push the placeholder image to your ECR repository
resource "docker_registry_image" "hourly_wages_placeholder" {
  name = docker_image.hourly_wages_placeholder.name
}

# Step C: Define the Lambda function, now pointing to the placeholder image that exists in your ECR
resource "aws_lambda_function" "costing_hourly_wages_ecr" {
  count         = lookup(var.lambdas, "costing-hourly-wages", null) != null ? 1 : 0
  function_name = "${var.project_name}-${var.environment}-costing-hourly-wages"
  role          = module.costing_lambda_role.role_arn
  package_type  = "Image"
  image_uri     = docker_registry_image.hourly_wages_placeholder.name

  timeout     = var.lambdas["costing-hourly-wages"].timeout
  memory_size = var.lambdas["costing-hourly-wages"].memory_size
  environment {
    variables = {
      SSM_PREFIX = "blackbox-${var.environment}"
    }
  }
  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [var.lambda_security_group_id]
  }

  lifecycle {
    ignore_changes = [image_uri]
  }
}


###############################################################################
# 4. State Machines
###############################################################################
module "costing_state_machine_1" {
  source = "../../base-infra/step-function"

  project_name       = var.project_name
  environment        = var.environment
  state_machine_name = "costing-workflow-1"
  definition = templatefile("${path.module}/state-machine-1.tftpl", {
    rfp_infrastructure_lambda_arn  = module.lambda["costing-rfp-infrastructure"].lambda_arn
    rfp_license_lambda_arn         = module.lambda["costing-rfp-license"].lambda_arn
    hourly_wages_lambda_arn        = length(aws_lambda_function.costing_hourly_wages_ecr) > 0 ? aws_lambda_function.costing_hourly_wages_ecr[0].arn : ""
    hourly_wages_result_lambda_arn = module.lambda["costing-hourly-wages-result"].lambda_arn
  })
}

module "costing_state_machine_2" {
  source = "../../base-infra/step-function"

  project_name       = var.project_name
  environment        = var.environment
  state_machine_name = "costing-workflow-2"
  definition = templatefile("${path.module}/state-machine-2.tftpl", {
    rfp_cost_image_extractor_lambda_arn   = module.lambda["costing-rfp-cost-image-extractor"].lambda_arn
    rfp_cost_image_calculation_lambda_arn = module.lambda["costing-rfp-cost-image-calculation"].lambda_arn
  })
}

module "costing_cost_step_machine_lambda" {
  source        = "../../base-infra/lambda"
  function_name = "${var.project_name}-${var.environment}-costing-cost-step-machine"
  
  # Configuration is pulled directly from the variable for this specific lambda
  runtime     = var.lambdas["costing-cost-step-machine"].runtime
  timeout     = var.lambdas["costing-cost-step-machine"].timeout
  memory_size = var.lambdas["costing-cost-step-machine"].memory_size
  layers      = [for layer_key in var.lambdas["costing-cost-step-machine"].layers : var.available_layer_arns[layer_key]]
  
  environment_variables = {
    STEP_FUNCTION_ARN = module.costing_state_machine_1.state_machine_arn
    SSM_PREFIX        = "blackbox-${var.environment}"
  }

  lambda_role_arn  = module.costing_lambda_role.role_arn
  s3_bucket        = var.placeholder_s3_bucket
  s3_key           = var.placeholder_s3_key
  source_code_hash = var.placeholder_source_code_hash

  vpc_subnet_ids         = var.private_subnet_ids
  vpc_security_group_ids = [var.lambda_security_group_id]
}