terraform {
  backend "s3" {
    bucket         = "blackbox-terraform-state-bucket"
    workspace_key_prefix = "blackbox"
    key            = "terraform.tfstate" 
    region         = "us-east-1"
    encrypt        = true
    # dynamodb_table = "blackbox-terraform-locks"        
  }
}