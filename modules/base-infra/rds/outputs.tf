output "db_endpoint" {
  description = "RDS endpoint"
  value       = aws_db_instance.myrds.endpoint
}

output "db_identifier" {
  description = "RDS identifier"
  value       = aws_db_instance.myrds.id
}

output "db_port" {
  description = "The database port"
  value       = aws_db_instance.myrds.port
}

output "db_username" {
  description = "The database username"
  value       = aws_db_instance.myrds.username
  sensitive   = true
}

output "db_password" {
  description = "The database password"
  value       = aws_db_instance.myrds.password
  sensitive   = true
}