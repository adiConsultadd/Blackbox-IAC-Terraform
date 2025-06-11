output "sourcing_s3_bucket" {
  description = "Primary S3 bucket for sourcing feature"
  value       = module.feature_sourcing.s3_bucket_name
}
