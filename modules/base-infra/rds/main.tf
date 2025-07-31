resource "aws_db_subnet_group" "this" {
  name       = "${var.project_name}-sng-${var.environment}"
  subnet_ids = var.subnet_ids

  tags = {
    Name        = "${var.project_name}-sng-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_db_instance" "myrds" {
  identifier             = "${var.project_name}-db-${var.environment}"
  engine                 = var.engine
  instance_class         = var.instance_class
  allocated_storage      = var.allocated_storage
  username               = var.db_username
  password               = var.db_password
  skip_final_snapshot    = var.skip_final_snapshot
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = var.vpc_security_group_ids
  multi_az               = var.multi_az

  tags = {
    Name        = "${var.project_name}-db-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
  }
}