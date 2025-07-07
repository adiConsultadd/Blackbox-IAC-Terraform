output "lambda_arns" {
  description = "Map of Lambda function ARNs for the costing service"
  value       = { for k, m in module.lambda : k => m.lambda_arn }
}

output "state_machine_arn" {
  description = "The ARN of the costing service state machine"
  value       = module.costing_state_machine.state_machine_arn
}
