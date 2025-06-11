terraform {
  backend "s3" {
    bucket = "blackbox-terraform-state-bucket"          
    region = "us-east-1"
    encrypt = true
    # dynamodb_table = "my-terraform-locks"     
  }
}
