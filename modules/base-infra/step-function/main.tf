resource "aws_iam_role" "step_function_role" {
  name = "${var.project_name}-${var.environment}-${var.state_machine_name}-role"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = {
          Service = "states.amazonaws.com"
        },
        Action    = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Project     = var.project_name,
    Environment = var.environment
  }
}

resource "aws_iam_role_policy" "step_function_policy" {
  name = "${var.project_name}-${var.environment}-${var.state_machine_name}-policy"
  role = aws_iam_role.step_function_role.id

  policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = "lambda:InvokeFunction",
        Resource = ["arn:aws:lambda:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:function:${var.project_name}-${var.environment}-*"]
      }
    ]
  })
}

resource "aws_sfn_state_machine" "this" {
  name       = "${var.project_name}-${var.environment}-${var.state_machine_name}"
  role_arn   = aws_iam_role.step_function_role.arn
  definition = var.definition
  type = "STANDARD"
  tags = {
    Project     = var.project_name,
    Environment = var.environment
  }

  depends_on = [
    aws_iam_role.step_function_role,
    aws_iam_role_policy.step_function_policy
  ]
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
