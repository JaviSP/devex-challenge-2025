# GitHub provider configuration
provider "github" {
  token = var.github_token
  owner = "ebury"
}

# GitHub Organization webhook
resource "github_organization_webhook" "workflow_job" {
  configuration {
    url          = aws_api_gateway_stage.prod.invoke_url
    content_type = "json"
    insecure_ssl = false
    secret       = random_password.webhook_secret.result
  }

  active = true

  events = ["workflow_job"]
}

# Generate random secret for webhook
resource "random_password" "webhook_secret" {
  length  = 32
  special = true
}
