provider "aws" {
  region = "eu-central-1" # Change to your preferred region
  profile = "sofa"
}

# ==========================================
# 1. Variables (CHANGE THESE)
# ==========================================
variable "github_repo" {
  description = "Your GitHub username and repo (e.g., Youssef/my-app)"
  type        = string
  default     = "joue-zero/gitops-platform" 
}

variable "ecr_repo_name" {
  description = "The name of your ECR repository"
  type        = string
  default     = "gitops-platform-app"
}

# ==========================================
# 2. Amazon ECR Repository
# ==========================================
resource "aws_ecr_repository" "app_repo" {
  name                 = var.ecr_repo_name
  image_tag_mutability = "MUTABLE"
  force_delete         = true # Allows you to destroy it later even if it has images

  image_scanning_configuration {
    scan_on_push = true
  }
}

# ==========================================
# 3. GitHub OIDC Identity Provider
# ==========================================
# Note: AWS allows you to create this once per account. If you already 
# have a GitHub OIDC provider in your AWS account, you can skip this block.
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  
  # Standard GitHub OIDC Thumbprints required by AWS
  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd"
  ]
}

# ==========================================
# 4. IAM Role & Trust Policy (The "Bouncer")
# ==========================================
data "aws_iam_policy_document" "github_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      # This ensures ONLY your specific repo can assume this role.
      # The :* at the end allows it to run from any branch (main, PRs, etc.)
      values   = ["repo:${var.github_repo}:*"] 
    }
  }
}

resource "aws_iam_role" "github_actions_role" {
  name               = "gitops-platform-github-role" # Matches your pipeline exactly
  assume_role_policy = data.aws_iam_policy_document.github_assume_role.json
}

# ==========================================
# 5. IAM Permissions (Allow ECR Push)
# ==========================================
data "aws_iam_policy_document" "ecr_push_policy" {
  # 1. Allow login (Requires an account-wide wildcard)
  statement {
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  # 2. Allow pushing only to the specific repo we created
  statement {
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:GetRepositoryPolicy",
      "ecr:DescribeRepositories",
      "ecr:ListImages",
      "ecr:DescribeImages",
      "ecr:BatchGetImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:PutImage"
    ]
    resources = [aws_ecr_repository.app_repo.arn]
  }
}

resource "aws_iam_role_policy" "github_actions_ecr_policy" {
  name   = "GitHubActionsECRPushPolicy"
  role   = aws_iam_role.github_actions_role.id
  policy = data.aws_iam_policy_document.ecr_push_policy.json
}

# ==========================================
# 6. Outputs (Copy these to GitHub!)
# ==========================================
output "AWS_ACCOUNT_ID" {
  value       = data.aws_caller_identity.current.account_id
  description = "Add this as a GitHub Variable: vars.AWS_ACCOUNT_ID"
}

output "ECR_REPOSITORY_URL" {
  value       = aws_ecr_repository.app_repo.repository_url
  description = "Add this as a GitHub Secret: secrets.ECR_REPOSITORY_URL"
}

data "aws_caller_identity" "current" {}