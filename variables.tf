variable "aws_region" { type = string }
variable "environment" { type = string }
variable "project_name" { type = string }

variable "lambda_layers" {
  description = "A map of Lambda layers to create. The key is the short name"
  type = map(object({
    compatible_runtimes = list(string)
  }))
  default = {}
}

variable "services_lambdas" {
  description = "A complete definition of all lambdas for all services."
  type = map(map(object({
    layers      = list(string)
    runtime     = string
    timeout     = number
    memory_size = number
    env_vars    = optional(map(string))
  })))
  default = {}
}

# ---- Networking -------------------------------------------
variable "vpc_cidr" { type = string }
variable "public_subnet_cidrs" { type = list(string) }
variable "private_subnet_cidrs" { type = list(string) }
variable "availability_zones" { type = list(string) }

# ---- RDS --------------------------------------------------
variable "db_engine" { type = string }
variable "db_instance_class" { type = string }
variable "db_allocated_storage" { type = number }
variable "db_username" { type = string }
variable "db_password" {
  type      = string
  sensitive = true
}
variable "skip_final_snapshot" { type = bool }
variable "db_multi_az" {
  description = "Specifies if the RDS instance is multi-AZ"
  type        = bool
  default     = false
}

# ---- CloudFront -------------------------------------------
variable "cloudfront_price_class" { type = string }
variable "viewer_protocol_policy" { type = string }
variable "default_root_object" { type = string }
variable "cloudfront_enabled" { type = bool }

# ---- EventBridge ------------------------------------------
variable "eventbridge_schedule_expression" { type = string }

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

# ---------- Static SSM Parameters ----------
variable "google_api_key" {
  description = "Google API Key"
  type        = string
  sensitive   = true
}

variable "openai_api_key" {
  description = "OpenAI API Key"
  type        = string
  sensitive   = true
}

# ---------- HigherGov Static SSM Parameters ----------
variable "highergov_apibaseurl" {
  description = "HigherGov API base URL"
  type        = string
}

variable "highergov_apidocurl" {
  description = "HigherGov API documentation URL"
  type        = string
}

variable "highergov_apikey" {
  description = "HigherGov API Key"
  type        = string
  sensitive   = true
}

variable "highergov_email" {
  description = "HigherGov login email"
  type        = string
}

variable "highergov_loginurl" {
  description = "HigherGov login URL"
  type        = string
}

variable "highergov_password" {
  description = "HigherGov login password"
  type        = string
  sensitive   = true
}

variable "highergov_portalurl" {
  description = "HigherGov portal URL"
  type        = string
}

variable "search_id" {
  description = "HigherGov search ID"
  type        = string
}
