output "role_arn" {
  description = "ARN of the purpose‑built IAM role"
  value       = aws_iam_role.this.arn
}