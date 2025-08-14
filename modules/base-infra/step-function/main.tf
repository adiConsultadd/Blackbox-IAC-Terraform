data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

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

# Create a CloudWatch Log Group, but only for EXPRESS workflows which need it
resource "aws_cloudwatch_log_group" "sfn_log_group" {
  count = var.state_machine_type == "EXPRESS" ? 1 : 0

  name              = "/aws/vendedlogs/states/${var.project_name}-${var.environment}-${var.state_machine_name}"
  retention_in_days = 7

  tags = {
    Project     = var.project_name,
    Environment = var.environment
  }
}

locals {
  base_statements = [
    {
      Effect   = "Allow",
      Action   = "lambda:InvokeFunction",
      Resource = ["*"]
    }
  ]

  express_logging_statements = var.state_machine_type == "EXPRESS" ? [
    {
      Effect   = "Allow",
      Action   = [
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogStreams"
      ],
      Resource = [aws_cloudwatch_log_group.sfn_log_group[0].arn]
    },
    {
      Effect   = "Allow",
      Action   = [
        "logs:CreateLogDelivery",
        "logs:GetLogDelivery",
        "logs:UpdateLogDelivery",
        "logs:DeleteLogDelivery",
        "logs:ListLogDeliveries",
        "logs:PutResourcePolicy",
        "logs:DescribeResourcePolicies",
        "logs:DescribeLogGroups"
      ],
      Resource = ["*"] 
    }
  ] : []

  # Combine the policy statements
  all_statements = concat(local.base_statements, local.express_logging_statements)
}

resource "aws_iam_role_policy" "step_function_policy" {
  name = "${var.project_name}-${var.environment}-${var.state_machine_name}-policy"
  role = aws_iam_role.step_function_role.id

  policy = jsonencode({
    Version   = "2012-10-17",
    Statement = local.all_statements
  })
}

resource "aws_sfn_state_machine" "this" {
  name       = "${var.project_name}-${var.environment}-${var.state_machine_name}"
  role_arn   = aws_iam_role.step_function_role.arn
  definition = var.definition
  type       = var.state_machine_type # Use the new variable

  # Dynamically add logging configuration only for EXPRESS workflows
  dynamic "logging_configuration" {
    for_each = var.state_machine_type == "EXPRESS" ? [1] : []
    content {
      log_destination        = "${aws_cloudwatch_log_group.sfn_log_group[0].arn}:*"
      include_execution_data = true
      level                  = "ALL"
    }
  }

  tags = {
    Project     = var.project_name,
    Environment = var.environment
  }

  depends_on = [
    aws_iam_role.step_function_role,
    aws_iam_role_policy.step_function_policy
  ]
}