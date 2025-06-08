resource "aws_cloudfront_distribution" "mycdn" {
  origin {
    domain_name = "${var.s3_bucket_name}.s3.amazonaws.com"
    origin_id   = "S3-${var.s3_bucket_name}"
  }

  enabled             = true
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${var.s3_bucket_name}"

    viewer_protocol_policy = "allow-all"
  }

  # For dev usage, we’ll allow HTTP. 
  # In real usage, you might want to force HTTPS only.

  # Price class
  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}
