resource "aws_sqs_queue" "dlq" {
  name = "${var.project_name}-${var.environment}-${var.queue_name}-dlq"
}

resource "aws_sqs_queue" "main" {
  name                       = "${var.project_name}-${var.environment}-${var.queue_name}-queue"
  visibility_timeout_seconds = var.visibility_timeout_seconds
  max_message_size           = var.max_message_size

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = var.max_receive_count
  })
}

resource "aws_lambda_event_source_mapping" "this" {
  event_source_arn = aws_sqs_queue.main.arn
  function_name    = var.lambda_trigger_arn
}

data "aws_iam_policy_document" "queue_owner_policy" {
  policy_id = "__default_policy_ID"
  statement {
    sid    = "__owner_statement"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.aws_account_id}:root"]
    }
    actions   = ["SQS:*"]
    resources = [aws_sqs_queue.main.arn]
  }
}

resource "aws_sqs_queue_policy" "this" {
  queue_url = aws_sqs_queue.main.id
  policy    = data.aws_iam_policy_document.queue_owner_policy.json
}