resource "aws_db_instance" "myrds" {
  identifier             = "${var.project_name}-${var.environment}-db"
  engine                 = var.engine        
  instance_class         = var.instance_class
  allocated_storage      = var.allocated_storage
  username               = var.db_username
  password               = var.db_password
  skip_final_snapshot    = true                

  tags = {
    Name        = "${var.project_name}-${var.environment}-db"
    Environment = var.environment
    Project     = var.project_name
  }
}
