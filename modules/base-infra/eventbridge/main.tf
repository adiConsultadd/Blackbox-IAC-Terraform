resource "aws_cloudwatch_event_rule" "cron_daily" {
  name                = "${var.project_name}-${var.suffix}-${var.environment}"
  schedule_expression = var.schedule_expression

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_cloudwatch_event_target" "cron_daily_target" {
  rule      = aws_cloudwatch_event_rule.cron_daily.name
  arn       = var.lambda_arn_to_trigger
  target_id = "lambda-1-daily"
}

resource "aws_lambda_permission" "allow_eventbridge_to_invoke" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_arn_to_trigger
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.cron_daily.arn
}