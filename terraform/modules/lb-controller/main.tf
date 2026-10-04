# Installed by Terraform rather than Argo CD so it is destroyed after the Argo apps: on destroy
# the controller must still be running to delete the load balancers their Ingresses created.

locals {
  service_account = "aws-load-balancer-controller"
  oidc_host       = replace(var.oidc_provider_url, "https://", "")
}

# policy.json is the upstream iam_policy.json of the controller release matching chart_version.
resource "aws_iam_policy" "this" {
  name   = "${var.project_name}-lb-controller"
  policy = file("${path.module}/policy.json")
}

data "aws_iam_policy_document" "assume" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_host}:sub"
      values   = ["system:serviceaccount:${var.namespace}:${local.service_account}"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_host}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "this" {
  name               = "${var.project_name}-lb-controller"
  assume_role_policy = data.aws_iam_policy_document.assume.json
}

resource "aws_iam_role_policy_attachment" "this" {
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.this.arn
}

resource "helm_release" "this" {
  name       = "aws-load-balancer-controller"
  namespace  = var.namespace
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = var.chart_version

  values = [yamlencode({
    clusterName = var.cluster_name
    region      = var.region
    vpcId       = var.vpc_id

    serviceAccount = {
      create      = true
      name        = local.service_account
      annotations = { "eks.amazonaws.com/role-arn" = aws_iam_role.this.arn }
    }

    resources = {
      requests = { cpu = "25m", memory = "64Mi" }
      limits   = { memory = "128Mi" }
    }
  })]

  wait            = true
  atomic          = true
  cleanup_on_fail = true
  timeout         = 300

  depends_on = [aws_iam_role_policy_attachment.this]
}
