# IAM role for Lambda functions
resource "aws_iam_role" "lambda_role" {
  name = "github_runner_lambda_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# Lambda basic execution policy
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Custom policy for Lambda to create/terminate EC2 instances
resource "aws_iam_role_policy" "lambda_ec2" {
  name = "lambda_ec2_policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:RunInstances",
          "ec2:TerminateInstances",
          "ec2:DescribeInstances",
          "ec2:CreateTags",
          "ec2:RequestSpotInstances",
          "ec2:DescribeSpotInstanceRequests",
          "ec2:CancelSpotInstanceRequests"
        ]
        Resource = "*"
      }
    ]
  })
}

# Policy for Lambda to access Secrets Manager
resource "aws_iam_role_policy" "lambda_secrets" {
  name = "lambda_secrets_policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          aws_secretsmanager_secret.webhook_secret.arn,
          aws_secretsmanager_secret.github_api_token.arn
        ]
      }
    ]
  })
}

# IAM role for EC2 instances (GitHub runners)
resource "aws_iam_role" "ec2_role" {
  name = "github_runner_ec2_role"

  assume_role_policy = jsonencode({
    Version= "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# EC2 instance profile
resource "aws_iam_instance_profile" "runner_profile" {
  name = "github_runner_profile"
  role = aws_iam_role.ec2_role.name
}
