resource "aws_ssm_parameter" "this" {
  name  = "/${var.project_name}/${var.environment}/${var.param_name}"
  type  = var.type
  value = var.value

  tags = {
    Name        = "/${var.project_name}/${var.environment}/${var.param_name}"
    Environment = var.environment
    Project     = var.project_name
  }
}