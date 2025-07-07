output "layer_arns" {
  description = "The ARNs of the created Lambda layers"
  value       = { for k, v in aws_lambda_layer_version.this : k => v.arn }
}
