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
    },
    { 
      Effect = "Allow", 
      Action = ["dynamodb:Query", "dynamodb:Scan", "dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:UpdateItem", "dynamodb:DeleteItem"], 
      Resource = ["*"]
    }
  ]

  # Flexibly split lambdas based on package_type
  zip_lambdas = {
    for k, v in var.lambdas : k => v if lookup(v, "package_type", "Zip") == "Zip"
  }
    
  ecr_lambdas = {
    for k, v in var.lambdas : k => v if lookup(v, "package_type", "Zip") == "Image"
  }
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
# 2. ZIP-based Lambda functions
###############################################################################
module "lambda_zip" {
  for_each = local.zip_lambdas

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
  lambda_role_arn  = module.drafting_lambda_role.role_arn

  # VPC configuration
  vpc_subnet_ids         = var.private_subnet_ids
  vpc_security_group_ids = [var.lambda_security_group_id]
}

###############################################################################
# 3. ECR-based Lambda Functions (FLEXIBLE)
###############################################################################

# Create one ECR repository for each lambda marked as "Image"
resource "aws_ecr_repository" "ecr_repo" {
  for_each = local.ecr_lambdas

  name                 = "${var.project_name}-${var.environment}-${each.key}"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
}

# Build a placeholder image locally for each ECR repo
resource "docker_image" "placeholder" {
  for_each = local.ecr_lambdas

  name = "${aws_ecr_repository.ecr_repo[each.key].repository_url}:placeholder"
  build {
    context  = "${path.module}/placeholder-image"
    platform = "linux/amd64"
  }
}

# Push the placeholder image to its corresponding ECR repo
resource "docker_registry_image" "placeholder" {
  for_each = local.ecr_lambdas
  name     = docker_image.placeholder[each.key].name
}

# Define the Lambda function for each ECR repo
resource "aws_lambda_function" "lambda_ecr" {
  for_each = local.ecr_lambdas

  function_name = "${var.project_name}-${var.environment}-${each.key}"
  role          = module.drafting_lambda_role.role_arn
  package_type  = "Image"
  image_uri     = docker_registry_image.placeholder[each.key].name

  timeout     = each.value.timeout
  memory_size = each.value.memory_size
  environment {
    variables = merge(
      each.value.env_vars,
      { SSM_PREFIX = "blackbox-${var.environment}" }
    )
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
# 4. State Machine (Updated to reference correct module names)
###############################################################################
module "drafting_state_machine" {
  source = "../../base-infra/step-function"

  project_name       = var.project_name
  environment        = var.environment
  state_machine_name = "drafting-workflow"
  state_machine_type = "STANDARD"
  definition = templatefile("${path.module}/state-machine.tftpl", {
    rfp_cost_summary_lambda_arn = module.lambda_zip["drafting-rfp-cost-summary"].lambda_arn
    summary_lambda_arn          = module.lambda_zip["drafting-summary"].lambda_arn
    system_summary_lambda_arn   = module.lambda_zip["drafting-system-summary"].lambda_arn
    company_data_lambda_arn     = module.lambda_zip["drafting-company-data"].lambda_arn
    table_of_content_lambda_arn = module.lambda_zip["drafting-table-of-content"].lambda_arn
    user_preference_lambda_arn  = module.lambda_zip["drafting-user-preference"].lambda_arn
  })
}