 resource "aws_s3_bucket" "mys3bucket" {
  bucket = "${var.project_name}-${var.environment}-rfp-files"
  # acl    = "private"

  tags = {
    Name        = "${var.project_name}-${var.environment}-rfp-files"
    Environment = var.environment
    Project     = var.project_name
  }
}