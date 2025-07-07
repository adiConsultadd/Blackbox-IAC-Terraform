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