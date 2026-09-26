resource "aws_key_pair" "deployer" {
  key_name   = "${var.project_name}-key"
  public_key = file(var.ssh_public_key_path)
}

data "aws_iam_policy_document" "ec2_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ec2" {
  name               = "${var.project_name}-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json
}

resource "aws_iam_role_policy_attachment" "ecr_read" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "cloudwatch" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "ec2" {
  name = "${var.project_name}-ec2-profile"
  role = aws_iam_role.ec2.name
}

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

data "aws_iam_policy_document" "github_assume" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:joue-zero/gitops-platform:*"]
    }
  }
}

resource "aws_iam_role" "github_actions" {
  name               = "${var.project_name}-github-role"
  assume_role_policy = data.aws_iam_policy_document.github_assume.json
}

resource "aws_iam_role_policy_attachment" "ecr_push" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}

# ── Terraform CI: plan (PRs + pre-apply plan on push) ─────
# Read-only — safe to run on any PR, including from forks.
data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "github_assume_tf_plan" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:joue-zero/gitops-platform:pull_request",
        "repo:joue-zero/gitops-platform:ref:refs/heads/main",
      ]
    }
  }
}

resource "aws_iam_role" "github_actions_tf_plan" {
  name               = "${var.project_name}-tf-plan-role"
  assume_role_policy = data.aws_iam_policy_document.github_assume_tf_plan.json
}

resource "aws_iam_role_policy_attachment" "tf_plan_readonly" {
  role       = aws_iam_role.github_actions_tf_plan.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

# ReadOnlyAccess doesn't cover writing the S3 native lock file,
# which `terraform plan` still acquires and releases.
data "aws_iam_policy_document" "tf_state_lock" {
  statement {
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = ["arn:aws:s3:::${var.project_name}-tfstate-${data.aws_caller_identity.current.account_id}/*"]
  }
  statement {
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::${var.project_name}-tfstate-${data.aws_caller_identity.current.account_id}"]
  }
}

resource "aws_iam_role_policy" "tf_plan_state_lock" {
  name   = "TerraformStateLock"
  role   = aws_iam_role.github_actions_tf_plan.name
  policy = data.aws_iam_policy_document.tf_state_lock.json
}

# ── Terraform CI: apply (push to main only, gated by the
#    "dev" GitHub Environment's required reviewer) ─────────
data "aws_iam_policy_document" "github_assume_tf_apply" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:joue-zero/gitops-platform:ref:refs/heads/main"]
    }
  }
}

resource "aws_iam_role" "github_actions_tf_apply" {
  name               = "${var.project_name}-tf-apply-role"
  assume_role_policy = data.aws_iam_policy_document.github_assume_tf_apply.json
}

# Broad by necessity — this project's own IAM/OIDC resources are
# themselves managed by this Terraform config, so the apply role
# needs IAM permissions too. That's real privilege-escalation risk;
# the mitigation here is the required-reviewer gate on the "dev"
# environment, not fine-grained IAM scoping. Worth tightening if
# this ever became more than a portfolio project.
resource "aws_iam_role_policy_attachment" "tf_apply" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonVPCFullAccess",
    "arn:aws:iam::aws:policy/AmazonEC2FullAccess",
    "arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess",
    "arn:aws:iam::aws:policy/AmazonRDSFullAccess",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess",
    "arn:aws:iam::aws:policy/IAMFullAccess",
    "arn:aws:iam::aws:policy/AmazonS3FullAccess",
  ])
  role       = aws_iam_role.github_actions_tf_apply.name
  policy_arn = each.value
}
