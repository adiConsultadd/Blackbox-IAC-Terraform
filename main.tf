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
# 4. Shared SSM Parameter Store
#############################################################
module "ssm_parameters" {
  for_each = var.ssm_parameters
  source   = "./modules/base-infra/ssm"

  project_name = var.project_name
  environment  = var.environment
  param_name   = each.key
  type         = each.value.type
  value        = each.value.value
}

#############################################################
# 5. Shared EC2 Instance
#############################################################
module "ec2" {
  source = "./modules/base-infra/ec2"

  project_name      = var.project_name
  environment       = var.environment
  ami_id            = var.ec2_ami_id
  instance_type     = var.ec2_instance_type
  key_name          = var.ec2_key_name
  
  subnet_id = module.networking.private_subnet_ids[0]

  security_group_id = module.networking.ec2_security_group_id
}

#############################################################
# 6.  Sourcing Service
#############################################################
module "sourcing" {
  source = "./modules/services/sourcing"

  # Global Vars
  environment  = var.environment
  project_name = var.project_name

  # Pass in shared infrastructure details
  private_subnet_ids         = module.networking.private_subnet_ids
  lambda_security_group_id   = module.networking.lambda_security_group_id
  db_endpoint                = module.rds.db_endpoint

  # CloudFront Vars
  cloudfront_price_class = var.cloudfront_price_class
  viewer_protocol_policy = var.viewer_protocol_policy
  default_root_object    = var.default_root_object
  cloudfront_enabled     = var.cloudfront_enabled

  # EventBridge Vars
  eventbridge_schedule_expression = var.eventbridge_schedule_expression
}

#############################################################
# 7.  Drafting Service
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
# 8.  Costing Service
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
# 9. Lambda Layers
#############################################################
module "lambda_layers" {
  source = "./modules/base-infra/layers"

  project_name = var.project_name
  environment  = var.environment
  layers       = var.lambda_layers
}
