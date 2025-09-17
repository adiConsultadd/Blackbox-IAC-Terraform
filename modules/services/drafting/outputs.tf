output "lambda_arns" {
  description = "Map of all Lambda function ARNs for the drafting service (ZIP and ECR)"
  value = merge(
    { for k, m in module.lambda_zip : k => m.lambda_arn },
    { for k, l in aws_lambda_function.lambda_ecr : k => l.arn }
  )
}


output "drafting_state_machine_arn" {
  description = "The ARN of the drafting service state machine"
  value       = module.drafting_state_machine.state_machine_arn
}
