variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "eu-west-1"
}

variable "runner_instance_type" {
  description = "EC2 instance type for GitHub runners"
  type        = string
  default     = "c5.large"
}

variable "runner_ami_id" {
  description = "AMI ID for GitHub runner instances"
  type        = string
}

variable "github_token" {
  description = "GitHub token for managing organization resources"
  type        = string
  sensitive   = true
}

variable "github_org" {
  description = "GitHub organization name"
  type        = string
  default     = "ebury"
}