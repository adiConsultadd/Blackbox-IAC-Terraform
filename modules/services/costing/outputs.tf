output "lambda_arns" {
  description = "Map of Lambda function ARNs for the costing service"
  value       = { for k, m in module.lambda : k => m.lambda_arn }
}