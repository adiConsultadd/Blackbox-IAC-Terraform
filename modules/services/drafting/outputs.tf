output "lambda_arns" {
  description = "Map of Lambda function ARNs for the drafting service"
  value       = { for k, m in module.lambda : k => m.lambda_arn }
}

output "state_machine_arn" {
  description = "The ARN of the drafting service state machine"
  value       = module.drafting_state_machine.state_machine_arn
}
