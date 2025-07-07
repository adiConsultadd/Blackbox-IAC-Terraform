output "lambda_arns" {
  description = "Map of Lambda function ARNs for the costing service"
  value       = { for k, m in module.lambda : k => m.lambda_arn }
}

output "costing_state_machine_1_arn" {
  description = "The ARN of the costing service state machine"
  value       = module.costing_state_machine_1.state_machine_arn
}

output "costing_state_machine_2_arn" {
  description = "The ARN of the costing service state machine"
  value       = module.costing_state_machine_2.state_machine_arn
}