variable "aws_region"   { type = string }
variable "environment"  { type = string }
variable "project_name" { type = string }

# ---- Networking -------------------------------------------
variable "vpc_cidr"             { type = string }
variable "public_subnet_cidrs"  { type = list(string) }
variable "private_subnet_cidrs" { type = list(string) }
variable "availability_zones"   { type = list(string) }

# ---- RDS --------------------------------------------------
variable "db_engine"            { type = string }
variable "db_instance_class"    { type = string }
variable "db_allocated_storage" { type = number }
variable "db_username"          { type = string }
variable "db_password"          { type = string }
variable "skip_final_snapshot"  { type = bool }

# ---- ElastiCache ------------------------------------------
variable "elasticache_node_type"      { type = string }
variable "elasticache_num_nodes"    { type = number }
variable "elasticache_engine_version" { type = string }

# ---- CloudFront -------------------------------------------
variable "cloudfront_price_class" { type = string }
variable "viewer_protocol_policy" { type = string }
variable "default_root_object"    { type = string }
variable "cloudfront_enabled"     { type = bool }

# ---- EventBridge ------------------------------------------
variable "eventbridge_schedule_expression" { type = string }

# ---- SSM Parameter Store ----------------------------------
variable "ssm_parameters" {
  description = "A map of SSM parameters to create"
  type = map(object({
    type  = string
    value = string
  }))
  default   = {}
  # sensitive = true
}

# ---- Lambda Layers ----------------------------------
variable "lambda_layers" {
  description = "Configuration for Lambda layers"
  type = map(object({
    source_path         = string
    compatible_runtimes = list(string)
  }))
  default = {}
}

# ---- EC2 --------------------------------------------------
variable "ec2_instance_type" { 
  type = string 
}
variable "ec2_ami_id" { 
  type = string 
}
variable "ec2_key_name" {
  type        = string
  description = "Key pair name for EC2 instance access"
}
variable "ssh_access_cidr" {
  type        = string
  description = "CIDR block for SSH access to the EC2 instance"
}