output "main_queue_arn" {
  description = "ARN of the main SQS queue."
  value       = aws_sqs_queue.main.arn
}
output "dlq_arn" {
  description = "ARN of the Dead-Letter Queue."
  value       = aws_sqs_queue.dlq.arn
}
output "main_queue_url" {
  description = "URL of the main SQS queue."
  value       = aws_sqs_queue.main.id
}
