# Account-wide singleton — AWS allows only one OIDC provider per URL
# per account. This, and every role below, is foundation: it must
# survive `terraform destroy` on the ephemeral dev environment, since
# the CI roles are what bring the environment back up.
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

data "aws_caller_identity" "current" {}

# ── CI: push app images to ECR ────────────────────────────
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

# The deploy job's Ansible dynamic inventory (amazon.aws.aws_ec2) calls
# ec2:DescribeInstances to find the app servers/bastion — this role was
# only ever given ECR permissions, so that call was denied.
data "aws_iam_policy_document" "ec2_describe" {
  statement {
    actions   = ["ec2:DescribeInstances"]
    resources = ["*"] # DescribeInstances doesn't support resource-level scoping
  }
}

resource "aws_iam_role_policy" "ec2_describe" {
  name   = "Ec2DescribeForInventory"
  role   = aws_iam_role.github_actions.name
  policy = data.aws_iam_policy_document.ec2_describe.json
}

# ── CI: terraform plan (PRs + pre-apply plan on push) ─────
# Read-only — safe to run on any PR, including from forks.
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

# ── CI: terraform apply (push to main only, gated by the
#    "dev" GitHub Environment's required reviewer) ─────────
# Only ever applies the dev environment's state (networking, compute,
# RDS) — it never touches this foundation state, so it doesn't need
# permission to modify its own OIDC provider or roles.
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
      # A job with `environment: dev` (the gated apply/manual-dispatch
      # jobs) gets an environment-scoped sub claim, not a ref-scoped
      # one — GitHub swaps it the moment a job targets a protected
      # Environment. The nightly-destroy job deliberately has no
      # `environment:` (it must run unattended), so it still presents
      # the plain ref-based sub. Both need to be accepted here.
      values = [
        "repo:joue-zero/gitops-platform:ref:refs/heads/main",
        "repo:joue-zero/gitops-platform:environment:dev",
      ]
    }
  }
}

resource "aws_iam_role" "github_actions_tf_apply" {
  name               = "${var.project_name}-tf-apply-role"
  assume_role_policy = data.aws_iam_policy_document.github_assume_tf_apply.json
}

# Still needs IAM permissions: the dev environment creates its own
# ec2 instance role/profile (see the compute-iam module). Scoped to
# the services the dev environment actually uses, not account admin.
resource "aws_iam_role_policy_attachment" "tf_apply" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonVPCFullAccess",
    "arn:aws:iam::aws:policy/AmazonEC2FullAccess",
    "arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess",
    "arn:aws:iam::aws:policy/AmazonRDSFullAccess",
    "arn:aws:iam::aws:policy/IAMFullAccess",
    "arn:aws:iam::aws:policy/AmazonS3FullAccess",
  ])
  role       = aws_iam_role.github_actions_tf_apply.name
  policy_arn = each.value
}

# No managed full-access policy exists for EKS. eks:* on * is deliberate: the role already has IAMFullAccess.
data "aws_iam_policy_document" "tf_apply_eks" {
  statement {
    actions   = ["eks:*"]
    resources = ["*"]
  }
}

# RDS creates and encrypts the managed master-user secret on the caller's behalf, so the caller
# needs these. Scoped to the AWS-managed Secrets Manager key and to RDS-owned ("rds!") secrets.
data "aws_region" "current" {}

data "aws_kms_key" "secretsmanager" {
  key_id = "alias/aws/secretsmanager"
}

data "aws_iam_policy_document" "tf_apply_rds_secret" {
  statement {
    actions   = ["kms:DescribeKey", "kms:CreateGrant", "kms:GenerateDataKey", "kms:Decrypt"]
    resources = [data.aws_kms_key.secretsmanager.arn]
  }

  statement {
    actions = [
      "secretsmanager:CreateSecret",
      "secretsmanager:TagResource",
      "secretsmanager:DescribeSecret",
      "secretsmanager:DeleteSecret",
    ]
    resources = ["arn:aws:secretsmanager:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:secret:rds!*"]
  }
}

resource "aws_iam_role_policy" "tf_apply_rds_secret" {
  name   = "RdsManagedSecret"
  role   = aws_iam_role.github_actions_tf_apply.name
  policy = data.aws_iam_policy_document.tf_apply_rds_secret.json
}

resource "aws_iam_role_policy" "tf_apply_eks" {
  name   = "ManageEks"
  role   = aws_iam_role.github_actions_tf_apply.name
  policy = data.aws_iam_policy_document.tf_apply_eks.json
}

# ── CI: terraform apply for foundation (push to main, no approval gate) ─────
data "aws_iam_policy_document" "github_assume_foundation_apply" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:joue-zero/gitops-platform:ref:refs/heads/main"] # never PRs
    }
  }
}

resource "aws_iam_role" "github_actions_foundation_apply" {
  name               = "${var.project_name}-foundation-apply-role"
  assume_role_policy = data.aws_iam_policy_document.github_assume_foundation_apply.json
}

# Foundation holds only IAM, the OIDC provider and ECR.
resource "aws_iam_role_policy_attachment" "foundation_apply" {
  for_each = toset([
    "arn:aws:iam::aws:policy/IAMFullAccess",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess",
  ])
  role       = aws_iam_role.github_actions_foundation_apply.name
  policy_arn = each.value
}

resource "aws_iam_role_policy" "foundation_apply_state" {
  name   = "TerraformState"
  role   = aws_iam_role.github_actions_foundation_apply.name
  policy = data.aws_iam_policy_document.tf_state_lock.json
}
