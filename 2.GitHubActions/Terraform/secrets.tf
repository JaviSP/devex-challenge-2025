# Secrets Manager secret for webhook
resource "aws_secretsmanager_secret" "webhook_secret" {
  name = "github/webhook/secret"
}

resource "aws_secretsmanager_secret_version" "webhook_secret" {
  secret_id     = aws_secretsmanager_secret.webhook_secret.id
  secret_string = random_password.webhook_secret.result
}

# Secrets Manager secret for GitHub API token
resource "aws_secretsmanager_secret" "github_api_token" {
  name = "github/api/token"
}

resource "aws_secretsmanager_secret_version" "github_api_token" {
  secret_id     = aws_secretsmanager_secret.github_api_token.id
  secret_string = jsonencode({
    token = var.github_token
  })
}