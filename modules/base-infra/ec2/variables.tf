variable "project_name" {
  type        = string
  description = "Name of the project"
}

variable "environment" {
  type        = string
  description = "Deployment environment name (e.g., dev, prod)"
}

variable "ami_id" {
  type        = string
  description = "The AMI ID for the EC2 instance"
}

variable "instance_type" {
  type        = string
  description = "The instance type for the EC2 instance (e.g., t3.micro)"
}

variable "key_name" {
  type        = string
  description = "The name of the EC2 key pair for SSH access"
}

variable "subnet_id" {
  type        = string
  description = "The ID of the subnet to launch the instance into"
}

variable "security_group_id" {
  type        = string
  description = "The ID of the security group to associate with the instance"
}

variable "iam_instance_profile" {
  type        = string
  description = "The IAM instance profile to associate with the EC2 instance"
  default     = null
}

variable "associate_public_ip_address" {
  type        = bool
  description = "Whether to associate a public IP address with the instance"
  default     = false
}

variable "name" {
  type        = string
  description = "The specific name for the EC2 instance tag."
}

variable "root_volume_size" {
  description = "The size of the root EBS volume in GB."
  type        = number
  default     = 8 # Default size if not specified
}
