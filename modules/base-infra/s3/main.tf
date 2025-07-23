resource "aws_s3_bucket" "mys3bucket" {
 bucket = "${var.project_name}-${var.environment}-${var.bucket_suffix}"
 force_destroy = true
 tags = {
  Name    = "${var.project_name}-${var.environment}"
  Environment = var.environment
  Project  = var.project_name
 }
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.mys3bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "this" {
  bucket = aws_s3_bucket.mys3bucket.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_versioning" "this" {
 bucket = aws_s3_bucket.mys3bucket.id
 versioning_configuration {
  status = "Enabled"
 }
}