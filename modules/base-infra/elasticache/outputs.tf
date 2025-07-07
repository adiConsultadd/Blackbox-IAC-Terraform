output "endpoint" {
  description = "The endpoint of the ElastiCache Serverless Redis cache"
  value       = aws_elasticache_serverless_cache.this.endpoint[0].address
}

output "port" {
  description = "The port of the ElastiCache Serverless Redis cache"
  value       = aws_elasticache_serverless_cache.this.endpoint[0].port
}