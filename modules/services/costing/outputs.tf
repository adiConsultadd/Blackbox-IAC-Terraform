output "lambda_arns" {
  description = "Map of Lambda function ARNs for the costing service"
  value = merge(
    { for k, m in module.lambda : k => m.lambda_arn },
    (
      length(aws_lambda_function.costing_hourly_wages_ecr) > 0 ?
      { "costing-hourly-wages" = aws_lambda_function.costing_hourly_wages_ecr[0].arn } :
      {}
    )
  )
}

output "costing_state_machine_1_arn" {
  description = "The ARN of the costing service state machine"
  value       = module.costing_state_machine_1.state_machine_arn
}

output "costing_state_machine_2_arn" {
  description = "The ARN of the costing service state machine"
  value       = module.costing_state_machine_2.state_machine_arn
}