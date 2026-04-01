terraform {
  required_version = ">= 1.7"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.50"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "github_repo" {
  description = "owner/repo format, e.g. nguyengoctu/judge-engine"
  type        = string
  default     = "nguyengoctu/judge-engine"
}

variable "role_name" {
  type    = string
  default = "judge-engine-github-actions"
}

data "aws_caller_identity" "current" {}

# ── GitHub OIDC Provider ──────────────────────────────────────────────────────

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

resource "aws_iam_role" "github_actions" {
  name = var.role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.github.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringLike = {
          "token.actions.githubusercontent.com:sub" = "repo:${var.github_repo}:*"
        }
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "admin" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

output "github_actions_role_arn" {
  value = aws_iam_role.github_actions.arn
}

output "next_step" {
  value = <<-EOT
    Bootstrap complete.

    1. Copy the ARN above.
    2. Go to GitHub repo → Settings → Secrets and variables → Actions.
    3. Create secret: AWS_ROLE_ARN = ${aws_iam_role.github_actions.arn}
    4. Push any change under terraform/ → infra.yml runs the full pipeline automatically.
  EOT
}
