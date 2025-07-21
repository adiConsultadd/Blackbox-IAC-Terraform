resource "aws_s3_bucket" "mys3bucket" {
  bucket = "${var.project_name}-${var.environment}-${var.bucket_suffix}"
  # acl    = "private"
  force_destroy = true
  tags = {
    Name        = "${var.project_name}-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
  }
}