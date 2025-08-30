#############################################################
# 1. Shared Networking Infrastructure
#############################################################
module "networking" {
  source = "./modules/base-infra/networking"

  project_name         = var.project_name
  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
  ssh_access_cidr      = var.ssh_access_cidr
}

#############################################################
# 2. Shared RDS Database
#############################################################
module "rds" {
  source = "./modules/base-infra/rds"

  project_name           = var.project_name
  environment            = var.environment
  engine                 = var.db_engine
  instance_class         = var.db_instance_class
  allocated_storage      = var.db_allocated_storage
  db_username            = var.db_username
  db_password            = var.db_password
  skip_final_snapshot    = var.skip_final_snapshot
  subnet_ids             = module.networking.private_subnet_ids
  vpc_security_group_ids = [module.networking.rds_security_group_id]
  multi_az               = var.db_multi_az
}

#############################################################
# 3. Shared ElastiCache Redis Cluster
#############################################################
module "elasticache" {
  source = "./modules/base-infra/elasticache"

  project_name           = var.project_name
  environment            = var.environment
  subnet_ids             = module.networking.private_subnet_ids
  vpc_security_group_ids = [module.networking.elasticache_security_group_id]
}


#############################################################
# 4. Shared EC2 Instance & IAM Role
#############################################################
resource "aws_iam_role" "ec2_role" {
  name = "${var.project_name}-${var.environment}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_iam_policy" "ec2_policy" {
  name        = "${var.project_name}-${var.environment}-ec2-policy"
  description = "Policy for EC2 to invoke Lambda and access project S3 buckets."

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "lambda:InvokeFunction"
        Effect   = "Allow"
        Resource = "arn:aws:lambda:${var.aws_region}:${data.aws_caller_identity.current.account_id}:function:${var.project_name}-${var.environment}-*"
      },
      {
        Action = [
          "s3:GetObject",
          "s3:ListBucket",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Effect   = "Allow"
        Resource = [
          "arn:aws:s3:::${var.project_name}-${var.environment}-sourcing-rfp-files",
          "arn:aws:s3:::${var.project_name}-${var.environment}-sourcing-rfp-files/*",
          # Add access to the new lambda artifacts bucket
          aws_s3_bucket.lambda_artifacts.arn,
          "${aws_s3_bucket.lambda_artifacts.arn}/*",
          "arn:aws:s3:::cost-image-upload-temp/*",
          "arn:aws:s3:::${var.project_name}-${var.environment}-sourcing-costing-document/*"
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ],
        Resource = "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/*"
      },
      # Step Function Invoke Permissions
      { Effect = "Allow", Action = ["states:StartExecution", "states:StartSyncExecution"], Resource = ["*"] },
      {
        Effect   = "Allow",
        Action   = ["states:DescribeExecution", "states:GetExecutionHistory", "states:StopExecution"],
        Resource = ["*"]
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_policy_attach" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.ec2_policy.arn
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project_name}-${var.environment}-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

module "ec2" {
  source = "./modules/base-infra/ec2"

  name          = "ec2-instance"
  project_name  = var.project_name
  environment   = var.environment
  ami_id        = var.ec2_ami_id
  instance_type = var.ec2_instance_type
  key_name      = var.ec2_key_name

  subnet_id                   = module.networking.public_subnet_ids[0]
  associate_public_ip_address = true
  security_group_id           = module.networking.ec2_security_group_id
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name

  depends_on = [aws_iam_instance_profile.ec2_profile]
}

module "deep_research_ec2" {
  source = "./modules/base-infra/ec2"

  name             = "playground" 
  root_volume_size = var.deep_research_ec2_volume_size 
  project_name     = var.project_name
  environment      = var.environment
  ami_id           = var.ec2_ami_id
  instance_type    = var.deep_research_ec2_instance_type
  key_name         = var.ec2_key_name

  subnet_id                   = module.networking.public_subnet_ids[1] 
  associate_public_ip_address = true
  security_group_id           = module.networking.ec2_security_group_id 
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name 

  depends_on = [aws_iam_instance_profile.ec2_profile]
}

#############################################################
# 5. Lambda Artifacts Bucket and Placeholder Code
#############################################################
resource "aws_s3_bucket" "lambda_artifacts" {
  bucket = "${var.project_name}-${var.environment}-lambda-artifacts"
}

resource "aws_s3_bucket_versioning" "lambda_artifacts_versioning" {
  bucket = aws_s3_bucket.lambda_artifacts.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "lambda_artifacts_public_access" {
  bucket = aws_s3_bucket.lambda_artifacts.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "archive_file" "placeholder" {
  type        = "zip"
  source_dir  = "${path.root}/placeholder-code"
  output_path = "${path.root}/placeholder.zip"
}

resource "aws_s3_object" "placeholder" {
  bucket = aws_s3_bucket.lambda_artifacts.id
  key    = "placeholder.zip"
  source = data.archive_file.placeholder.output_path
  etag   = filemd5(data.archive_file.placeholder.output_path)
}

#############################################################
# 6.  Layers
#############################################################
module "layers" {
  source = "./modules/base-infra/layers"

  project_name = var.project_name
  environment  = var.environment
  layers       = var.lambda_layers
}

#############################################################
# 6.  Sourcing Service
#############################################################
module "sourcing" {
  source = "./modules/services/sourcing"

  # Global Vars
  environment  = var.environment
  project_name = var.project_name
  lambdas        = lookup(var.services_lambdas, "sourcing", {})

  # Pass in shared infrastructure details
  private_subnet_ids       = module.networking.private_subnet_ids
  lambda_security_group_id = module.networking.lambda_security_group_id
  db_endpoint              = module.rds.db_endpoint

  # CloudFront Vars
  cloudfront_price_class = var.cloudfront_price_class
  viewer_protocol_policy = var.viewer_protocol_policy
  default_root_object    = var.default_root_object
  cloudfront_enabled     = var.cloudfront_enabled

  # EventBridge Vars
  eventbridge_schedule_expression = var.eventbridge_schedule_expression

  # Placeholder Lambda Artifacts
  placeholder_s3_bucket        = aws_s3_bucket.lambda_artifacts.id
  placeholder_s3_key           = aws_s3_object.placeholder.key
  placeholder_source_code_hash = aws_s3_object.placeholder.etag

  # Lambda Layers
  available_layer_arns = module.layers.layer_arns

}

#############################################################
# 7.  Drafting Service
#############################################################
module "drafting" {
  source = "./modules/services/drafting"

  # Global Vars
  environment  = var.environment
  project_name = var.project_name
  lambdas        = lookup(var.services_lambdas, "drafting", {})

  # Pass in shared infrastructure details
  private_subnet_ids       = module.networking.private_subnet_ids
  lambda_security_group_id = module.networking.lambda_security_group_id

  # Placeholder Lambda Artifacts
  placeholder_s3_bucket        = aws_s3_bucket.lambda_artifacts.id
  placeholder_s3_key           = aws_s3_object.placeholder.key
  placeholder_source_code_hash = aws_s3_object.placeholder.etag

  # Lambda Layers
  available_layer_arns = module.layers.layer_arns
}

#############################################################
# 8.  Costing Service
#############################################################
module "costing" {
  source = "./modules/services/costing"

  # Global Vars
  environment  = var.environment
  project_name = var.project_name
  lambdas        = lookup(var.services_lambdas, "costing", {})

  # Pass in shared infrastructure details
  private_subnet_ids       = module.networking.private_subnet_ids
  lambda_security_group_id = module.networking.lambda_security_group_id

  # Placeholder Lambda Artifacts
  placeholder_s3_bucket        = aws_s3_bucket.lambda_artifacts.id
  placeholder_s3_key           = aws_s3_object.placeholder.key
  placeholder_source_code_hash = aws_s3_object.placeholder.etag

  # Lambda Layers
  available_layer_arns = module.layers.layer_arns
}

#############################################################
# 9. Deep Research Service
#############################################################
module "deep_research" {
  source = "./modules/services/deep-research"

  # Global Vars
  environment  = var.environment
  project_name = var.project_name
  lambdas      = lookup(var.services_lambdas, "deep-research", {})

  # Pass in shared infrastructure details
  private_subnet_ids       = module.networking.private_subnet_ids
  lambda_security_group_id = module.networking.lambda_security_group_id

  # Placeholder Lambda Artifacts from root
  placeholder_s3_bucket        = aws_s3_bucket.lambda_artifacts.id
  placeholder_s3_key           = aws_s3_object.placeholder.key
  placeholder_source_code_hash = aws_s3_object.placeholder.etag

  # Lambda Layers
  available_layer_arns = module.layers.layer_arns
}

#############################################################
# 10. Webhook Service
#############################################################
module "webhook" {
  source = "./modules/services/webhook"

  # Global Vars
  environment  = var.environment
  project_name = var.project_name
  lambdas      = lookup(var.services_lambdas, "webhook", {})

  # Pass in shared infrastructure details
  private_subnet_ids       = module.networking.private_subnet_ids
  lambda_security_group_id = module.networking.lambda_security_group_id

  # Placeholder Lambda Artifacts
  placeholder_s3_bucket        = aws_s3_bucket.lambda_artifacts.id
  placeholder_s3_key           = aws_s3_object.placeholder.key
  placeholder_source_code_hash = aws_s3_object.placeholder.etag

  # Lambda Layers
  available_layer_arns = module.layers.layer_arns
}

#############################################################
# 11. Data Migration Service
#############################################################
module "data_migration" {
  source = "./modules/services/data-migration"

  # Global Vars
  environment  = var.environment
  project_name = var.project_name
  lambdas      = lookup(var.services_lambdas, "data-migration", {})

  # Pass in shared infrastructure details
  private_subnet_ids       = module.networking.private_subnet_ids
  lambda_security_group_id = module.networking.lambda_security_group_id

  # Placeholder Lambda Artifacts
  placeholder_s3_bucket        = aws_s3_bucket.lambda_artifacts.id
  placeholder_s3_key           = aws_s3_object.placeholder.key
  placeholder_source_code_hash = aws_s3_object.placeholder.etag

  # Lambda Layers
  available_layer_arns = module.layers.layer_arns

  # EventBridge Schedule
  eventbridge_schedule_expression = var.data_migration_schedule_expression
}

#############################################################
# 12. Validation Service
#############################################################
module "validation" {
  source = "./modules/services/validation"

  # Global Vars
  environment  = var.environment
  project_name = var.project_name
  lambdas      = lookup(var.services_lambdas, "validation", {})

  # Pass in shared infrastructure details
  private_subnet_ids       = module.networking.private_subnet_ids
  lambda_security_group_id = module.networking.lambda_security_group_id

  # Placeholder Lambda Artifacts
  placeholder_s3_bucket        = aws_s3_bucket.lambda_artifacts.id
  placeholder_s3_key           = aws_s3_object.placeholder.key
  placeholder_source_code_hash = aws_s3_object.placeholder.etag

  # Lambda Layers
  available_layer_arns = module.layers.layer_arns
}

#############################################################
# 13. SSM Parameter Store
#############################################################
locals {
  static_parameters = {
    "/blackbox-${var.environment}/google-api-key"          = { value = var.google_api_key, type = "SecureString" },
    "/blackbox-${var.environment}/openai-api-key"          = { value = var.openai_api_key, type = "SecureString" },
    "/blackbox-${var.environment}/highergov-api-base-url"  = { value = var.highergov_apibaseurl, type = "String" },
    "/blackbox-${var.environment}/highergov-api-doc-url"   = { value = var.highergov_apidocurl, type = "String" },
    "/blackbox-${var.environment}/highergov-api-key"       = { value = var.highergov_apikey, type = "SecureString" },
    "/blackbox-${var.environment}/highergov-email"         = { value = var.highergov_email, type = "String" },
    "/blackbox-${var.environment}/highergov-login-url"     = { value = var.highergov_loginurl, type = "String" },
    "/blackbox-${var.environment}/highergov-password"      = { value = var.highergov_password, type = "SecureString" },
    "/blackbox-${var.environment}/highergov-portal-url"    = { value = var.highergov_portalurl, type = "String" },
    "/blackbox-${var.environment}/highergov-search-id"     = { value = var.search_id, type = "String" },
    "/blackbox-${var.environment}/openai-webhook-secret"     = { value = var.openai-webhook-secret, type = "String" },
    "/blackbox-${var.environment}/APM_SERVER_URL"     = { value = var.apm_server_url, type = "String" },
    "/blackbox-${var.environment}/APM_SECRET_TOKEN"     = { value = var.apm_secret_token, type = "String" },
    "/blackbox-${var.environment}/ELASTIC_APM_API_KEY"     = { value = var.elastic_apm_api_key, type = "String" },
    }

  infra_parameters = {
    "/blackbox-${var.environment}/db-endpoint"    = { value = module.rds.db_endpoint, type = "String" },
    "/blackbox-${var.environment}/db-password"    = { value = module.rds.db_password, type = "SecureString" },
    "/blackbox-${var.environment}/db-port"        = { value = module.rds.db_port, type = "String" },
    "/blackbox-${var.environment}/db-user"        = { value = module.rds.db_username, type = "String" },
    "/blackbox-${var.environment}/redis-endpoint" = { value = "${module.elasticache.endpoint}:${module.elasticache.port}", type = "String" },
    "/blackbox-${var.environment}/cloudfront-url" = { value = module.sourcing.cloudfront_domain, type = "String" }
  }

  all_ssm_parameters = merge(local.static_parameters, local.infra_parameters)
}

resource "aws_ssm_parameter" "app_config" {
  for_each = local.all_ssm_parameters

  name      = each.key
  type      = each.value.type
  value     = each.value.value
  overwrite = true

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

