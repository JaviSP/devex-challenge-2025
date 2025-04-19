# API gateway URL
output "webhook_url" {
  description = "URL for the GitHub webhook"
  value       = aws_api_gateway_stage.prod.invoke_url
}

output "manage_runner_lambda_arn" {
  description = "ARN of the Lambda function that manages runners"
  value       = aws_lambda_function.manage_runner.arn
}

output "cloudwatch_log_group" {
  description = "Name of the CloudWatch Log Group for the Lambda function"
  value       = aws_cloudwatch_log_group.manage_runner_logs.name
}