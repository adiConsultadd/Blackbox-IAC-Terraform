resource "aws_cloudwatch_event_rule" "this" {
  name = "${var.project_name}-${var.environment}-${var.suffix}"

  schedule_expression = var.schedule_expression
  event_pattern       = var.event_pattern

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_cloudwatch_event_target" "target" {
  rule      = aws_cloudwatch_event_rule.this.name
  arn       = var.lambda_arn_to_trigger
  target_id = "lambda-target-${var.suffix}"
}

resource "aws_lambda_permission" "allow_eventbridge_to_invoke" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_arn_to_trigger
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.this.arn
}