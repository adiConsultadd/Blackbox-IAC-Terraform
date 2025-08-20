output "lambda_arns" {
  description = "Map of Lambda function ARNs for the validation service"
  value = merge(
    { for k, m in module.lambda : k => m.lambda_arn },
    { "validation-state-machine-executor" = module.state_machine_executor_lambda.lambda_arn }
  )
}

output "validation_state_machine_arn" {
  description = "The ARN of the validation service state machine"
  value       = module.validation_state_machine.state_machine_arn
}