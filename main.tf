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

# IAM Role for EC2 Instance
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

# IAM Policy for EC2 Role
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
          "arn:aws:s3:::${var.project_name}-${var.environment}-lambda-layers",
          "arn:aws:s3:::${var.project_name}-${var.environment}-lambda-layers/*"
        ]
      }
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

# EC2 Module Instantiation
module "ec2" {
  source = "./modules/base-infra/ec2"

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

#############################################################
# 5.  Sourcing Service
#############################################################
module "sourcing" {
  source = "./modules/services/sourcing"

  # Global Vars
  environment  = var.environment
  project_name = var.project_name

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
}

#############################################################
# 6.  Drafting Service
#############################################################
module "drafting" {
  source = "./modules/services/drafting"

  # Global Vars
  environment  = var.environment
  project_name = var.project_name

  # Pass in shared infrastructure details
  private_subnet_ids       = module.networking.private_subnet_ids
  lambda_security_group_id = module.networking.lambda_security_group_id
}

#############################################################
# 7.  Costing Service
#############################################################
module "costing" {
  source = "./modules/services/costing"

  # Global Vars
  environment  = var.environment
  project_name = var.project_name

  # Pass in shared infrastructure details
  private_subnet_ids       = module.networking.private_subnet_ids
  lambda_security_group_id = module.networking.lambda_security_group_id
}

#############################################################
# 8. Lambda Layers
#############################################################
module "lambda_layers" {
  source = "./modules/base-infra/layers"

  project_name = var.project_name
  environment  = var.environment
  layers       = var.lambda_layers
}

#############################################################
# 9. SSM Parameter Store
#############################################################
locals {
  all_ssm_parameters = {
    # Dynamic Parameters
    "/blackbox-${var.environment}/db-endpoint"    = { value = module.rds.db_endpoint, type = "String" }
    "/blackbox-${var.environment}/db-password"    = { value = module.rds.db_password, type = "SecureString" }
    "/blackbox-${var.environment}/db-port"        = { value = module.rds.db_port, type = "String" }
    "/blackbox-${var.environment}/db-user"        = { value = module.rds.db_username, type = "String" }
    "/blackbox-${var.environment}/redis-endpoint" = { value = module.elasticache.endpoint, type = "String" }
    "/blackbox-${var.environment}/cloudfront-url" = { value = module.sourcing.cloudfront_domain, type = "String" }

    # Static Parameters
    "/blackbox-${var.environment}/google_api_key"      = { value = var.google_api_key, type = "SecureString" }
    "/blackbox-${var.environment}/highergov-apibaseurl" = { value = var.highergov_apibaseurl, type = "String" }
    "/blackbox-${var.environment}/highergov-apidocurl" = { value = var.highergov_apidocurl, type = "String" }
    "/blackbox-${var.environment}/highergov-apikey"    = { value = var.highergov_apikey, type = "SecureString" }
    "/blackbox-${var.environment}/highergov-email"     = { value = var.highergov_email, type = "String" }
    "/blackbox-${var.environment}/highergov-loginurl"  = { value = var.highergov_loginurl, type = "String" }
    "/blackbox-${var.environment}/highergov-password"  = { value = var.highergov_password, type = "SecureString" }
    "/blackbox-${var.environment}/highergov-portalurl" = { value = var.highergov_portalurl, type = "String" }
    "/blackbox-${var.environment}/openai_api_key"      = { value = var.openai_api_key, type = "SecureString" }
    "/blackbox-${var.environment}/search_id"           = { value = var.search_id, type = "String"}
  }
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