output "db_endpoint" {
  description = "RDS endpoint"
  value       = aws_db_instance.myrds.endpoint
}

output "db_identifier" {
  description = "RDS identifier"
  value       = aws_db_instance.myrds.id
}
