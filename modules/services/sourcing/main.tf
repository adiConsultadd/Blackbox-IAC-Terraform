###############################################################################
# 1. S3 bucket (Service-specific storage)
###############################################################################
module "s3" {
  source        = "../../base-infra/s3"
  environment   = var.environment
  project_name  = var.project_name
  bucket_suffix = "sourcing-rfp-files"
}

###############################################################################
# 2. CloudFront (Serves content from this service's S3 bucket)
###############################################################################
module "cloudfront" {
  source                         = "../../base-infra/cloudfront"
  environment                    = var.environment
  project_name                   = var.project_name
  s3_bucket_name                 = module.s3.bucket_name
  s3_bucket_regional_domain_name = module.s3.bucket_regional_domain_name
  price_class                    = var.cloudfront_price_class
  viewer_protocol_policy         = var.viewer_protocol_policy
  default_root_object            = var.default_root_object
  enabled                        = var.cloudfront_enabled
}

data "aws_iam_policy_document" "s3_policy" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${module.s3.bucket_arn}/*"]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [module.cloudfront.distribution_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "this" {
  bucket = module.s3.bucket_name
  policy = data.aws_iam_policy_document.s3_policy.json
}

###############################################################################
# 3. IAM Role (Whole Service)
###############################################################################
locals {
  # Define the combined policy statements once
  service_policy_statements = [
    # General Permissions
    { Effect = "Allow", Action = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"], Resource = ["arn:aws:logs:*:*:*"] },
    # VPC Permissions (Required for Lambdas in a VPC)
    { Effect = "Allow", Action = ["ec2:CreateNetworkInterface", "ec2:DescribeNetworkInterfaces", "ec2:DeleteNetworkInterface"], Resource = "*" },
    # S3 Full Access
    { Effect = "Allow", Action = ["s3:*"], Resource = ["*"] },
    # RDS Permissions
    { Effect = "Allow", Action = ["rds-data:*", "rds-db:connect", "rds:DescribeDBInstances"], Resource = ["*"] },
    # CloudFront Invalidation Permissions
    { Effect = "Allow", Action = ["cloudfront:CreateInvalidation"], Resource = ["*"] },
    # Full SSM Permissions
    {
      Effect = "Allow",
      Action = [
        "ssm:GetParameter",
        "ssm:GetParameters",
        "ssm:GetParametersByPath"
      ],
      Resource = "*"
    },
    {
      Effect   = "Allow",
      Action   = "kms:Decrypt",
      Resource = "*"
    },
    # Lambda Invoke Permissions
    { Effect = "Allow", Action = ["lambda:InvokeFunction"], Resource = ["*"] },
  ]
}
module "sourcing_lambda_role" {
  source = "../../base-infra/iam-lambda"

  role_name         = "${var.project_name}-sourcing-service-role-${var.environment}"
  project_name      = var.project_name
  environment       = var.environment
  policy_statements = local.service_policy_statements
}

###############################################################################
# 4. Lambda function definitions
###############################################################################
locals {
  lambdas = {
    "sourcing-rfp-sourcing-web"                 = {
      layers = [],
      env    = { S3_BUCKET_NAME = module.s3.bucket_name }
    }
    "sourcing-rfp-details-db-ingestion"         = {
      layers = [],
      env    = { DB_ENDPOINT = var.db_endpoint }
    }
    "sourcing-rfp-documents-s3-url-db-ingestion" = {
      layers = [],
      env = {
        S3_BUCKET_NAME    = module.s3.bucket_name
        DB_ENDPOINT       = var.db_endpoint
        CLOUDFRONT_DISTRO = module.cloudfront.distribution_id
      }
    }
  }
}


###############################################################################
# 5. Lambda functions
###############################################################################
module "lambda" {
  for_each = var.lambdas

  source        = "../../base-infra/lambda"
  function_name = "${var.project_name}-${each.key}-${var.environment}"

  # Configuration from the .tfvars file
  runtime       = each.value.runtime
  timeout       = each.value.timeout
  memory_size   = each.value.memory_size
  layers        = [for layer_key in each.value.layers : var.available_layer_arns[layer_key]]
  environment_variables = merge(
    each.value.env_vars,
    {SSM_PREFIX = "blackbox-${var.environment}"}
  )
  # Standard parameters
  s3_bucket              = var.placeholder_s3_bucket
  s3_key                 = var.placeholder_s3_key
  source_code_hash       = var.placeholder_source_code_hash
  lambda_role_arn        = module.sourcing_lambda_role.role_arn

  # VPC configuration
  vpc_subnet_ids         = var.private_subnet_ids
  vpc_security_group_ids = [var.lambda_security_group_id]
}

###############################################################################
# 6. EventBridge (Schedules Lambda-1 of this service)
###############################################################################
module "eventbridge" {
  source       = "../../base-infra/eventbridge"
  environment  = var.environment
  project_name = var.project_name
  suffix       = "daily-trigger-sourcing-lambda-1"

  lambda_arn_to_trigger = module.lambda["sourcing-rfp-sourcing-web"].lambda_arn
  schedule_expression   = var.eventbridge_schedule_expression
}