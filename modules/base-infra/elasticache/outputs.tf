output "endpoint" {
  description = "The endpoint of the ElastiCache Redis cluster"
  value       = aws_elasticache_cluster.this.cache_nodes[0].address
}

output "port" {
  description = "The port of the ElastiCache Redis cluster"
  value       = aws_elasticache_cluster.this.port
}