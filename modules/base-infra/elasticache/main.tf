resource "aws_elasticache_subnet_group" "this" {
  name      = "${var.project_name}-${var.environment}-redis-sng"
  subnet_ids = var.subnet_ids

  tags = {
    Name        = "${var.project_name}-${var.environment}-redis-sng"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_elasticache_serverless_cache" "this" {
  name              = "${var.project_name}-${var.environment}-redis-serverless"
  engine            = "redis"
  subnet_ids        = var.subnet_ids
  security_group_ids = var.vpc_security_group_ids

  tags = {
    Name        = "${var.project_name}-${var.environment}-redis-serverless"
    Environment = var.environment
    Project     = var.project_name
  }
}