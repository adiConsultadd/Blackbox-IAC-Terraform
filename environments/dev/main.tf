provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "Terraform"
    }
  }
} 

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}


module "iam" {
  source       = "../../modules/iam"
  environment  = var.environment
  project_name = var.project_name
}

module "lambda" {
  source         = "../../modules/lambda"
  environment    = var.environment
  project_name   = var.project_name
  vpc_id         = var.vpc_id
  subnet_ids     = var.private_subnet_ids
  lambda_role_arn = module.iam.lambda_role_arn
}

