output "lambda_arns" {
  description = "Map of Lambda function ARNs for the drafting service"
  value       = { for k, m in module.lambda : k => m.lambda_arn }
}

output "deep_research_state_machine_arn" {
  description = "The ARN of the deep-research service state machine"
  value       = module.deep_research_state_machine.state_machine_arn
}