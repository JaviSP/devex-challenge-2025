# API Gateway REST API
resource "aws_api_gateway_rest_api" "github_webhook" {
  name        = "github-webhook-api"
  description = "API Gateway for GitHub webhook integration"
}

# API Gateway Resource
resource "aws_api_gateway_resource" "workflow_job" {
  rest_api_id = aws_api_gateway_rest_api.github_webhook.id
  parent_id   = aws_api_gateway_rest_api.github_webhook.root_resource_id
  path_part   = "workflow_job"
}

# API Gateway Method
resource "aws_api_gateway_method" "workflow_job_post" {
  rest_api_id   = aws_api_gateway_rest_api.github_webhook.id
  resource_id   = aws_api_gateway_resource.workflow_job.id
  http_method   = "POST"
  authorization = "NONE"
}

# API Gateway Integration
resource "aws_api_gateway_integration" "workflow_job_integration" {
  rest_api_id = aws_api_gateway_rest_api.github_webhook.id
  resource_id = aws_api_gateway_resource.workflow_job.id
  http_method = aws_api_gateway_method.workflow_job_post.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.manage_runner.invoke_arn
}

# API Gateway Method Response
resource "aws_api_gateway_method_response" "workflow_job_post_200" {
  rest_api_id = aws_api_gateway_rest_api.github_webhook.id
  resource_id = aws_api_gateway_resource.workflow_job.id
  http_method = aws_api_gateway_method.workflow_job_post.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }
}

# API Gateway Integration Response
resource "aws_api_gateway_integration_response" "workflow_job_post" {
  rest_api_id = aws_api_gateway_rest_api.github_webhook.id
  resource_id = aws_api_gateway_resource.workflow_job.id
  http_method = aws_api_gateway_method.workflow_job_post.http_method
  status_code = aws_api_gateway_method_response.workflow_job_post_200.status_code

  response_templates = {
    "application/json" = ""
  }

  depends_on = [aws_api_gateway_integration.workflow_job_integration]
}

# API Gateway Deployment
resource "aws_api_gateway_deployment" "github_webhook" {
  rest_api_id = aws_api_gateway_rest_api.github_webhook.id

  depends_on = [
    aws_api_gateway_integration.workflow_job_integration,
    aws_api_gateway_integration_response.workflow_job_post
  ]

  lifecycle {
    create_before_destroy = true
  }
}

# API Gateway Stage
resource "aws_api_gateway_stage" "prod" {
  deployment_id = aws_api_gateway_deployment.github_webhook.id
  rest_api_id  = aws_api_gateway_rest_api.github_webhook.id
  stage_name   = "prod"
}

# Lambda permission for API Gateway
resource "aws_lambda_permission" "api_gateway_manage_runner" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.manage_runner.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.github_webhook.execution_arn}/*/*"
}
