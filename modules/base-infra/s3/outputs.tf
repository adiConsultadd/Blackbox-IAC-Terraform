 output "bucket_name" {
  description = "Name of the RFP S3 bucket"
  value       = aws_s3_bucket.mys3bucket.bucket
}
