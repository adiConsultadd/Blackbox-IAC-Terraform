output "eventbridge_rule_arn" {
  description = "EventBridge Rule ARN for daily trigger"
  value       = aws_cloudwatch_event_rule.cron_daily.arn
}
