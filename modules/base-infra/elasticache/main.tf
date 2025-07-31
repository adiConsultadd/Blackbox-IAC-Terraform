resource "aws_elasticache_subnet_group" "this" {
  name       = "${var.project_name}-redis-sng-${var.environment}"
  subnet_ids = var.subnet_ids

  tags = {
    Name        = "${var.project_name}-redis-sng-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_elasticache_serverless_cache" "this" {
  name               = "${var.project_name}-redis-serverless-${var.environment}"
  engine             = "redis"
  subnet_ids         = var.subnet_ids
  security_group_ids = var.vpc_security_group_ids

  tags = {
    Name        = "${var.project_name}-redis-serverless-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
  }
}