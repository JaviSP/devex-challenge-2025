# Lambda function for managing GitHub runners (create and delete)
resource "aws_lambda_function" "manage_runner" {
  filename         = "lambdas/manage_runner/manage_runner.zip"
  function_name    = "github-runner-manager"
  role             = aws_iam_role.lambda_role.arn
  handler          = "manage_runner.lambda_handler"
  runtime          = "python3.12"
  timeout          = 300
  memory_size      = 256

  environment {
    variables = {
      GITHUB_ORG            = var.github_org
      INSTANCE_TYPE         = var.runner_instance_type
      RUNNER_AMI_ID         = var.runner_ami_id
      GITHUB_WEBHOOK_SECRET = aws_secretsmanager_secret_version.webhook_secret.secret_string
      GITHUB_TOKEN_SECRET   = aws_secretsmanager_secret_version.github_api_token.secret_string
    }
  }
}

# CloudWatch Log Group for Lambda function
resource "aws_cloudwatch_log_group" "manage_runner_logs" {
  name              = "/aws/lambda/${aws_lambda_function.manage_runner.function_name}"
  retention_in_days = 14
}