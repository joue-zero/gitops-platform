# ── Cluster IAM role ───────────────────────────────────────
data "aws_iam_policy_document" "eks_cluster_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "cluster" {
  name               = "${var.project_name}-eks-cluster-role"
  assume_role_policy = data.aws_iam_policy_document.eks_cluster_assume.json
}

resource "aws_iam_role_policy_attachment" "cluster_policy" {
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# ── Cluster ────────────────────────────────────────────────
resource "aws_eks_cluster" "main" {
  name     = "${var.project_name}-eks"
  role_arn = aws_iam_role.cluster.arn
  version  = var.kubernetes_version

  vpc_config {
    subnet_ids = var.subnet_ids
  }

  # API-only auth; the cluster creator is not an implicit admin.
  access_config {
    authentication_mode                         = "API"
    bootstrap_cluster_creator_admin_permissions = false
  }

  depends_on = [aws_iam_role_policy_attachment.cluster_policy]

  tags = { Name = "${var.project_name}-eks" }
}

# ── Cluster access ─────────────────────────────────────────
# Later maps win in merge(), so a principal listed as both admin and viewer is an admin.
locals {
  access_policy_prefix = "arn:aws:eks::aws:cluster-access-policy"
  access_entries = merge(
    { for arn in var.viewer_principal_arns : arn => "AmazonEKSAdminViewPolicy" },
    { for arn in var.admin_principal_arns : arn => "AmazonEKSClusterAdminPolicy" },
  )
}

resource "aws_eks_access_entry" "this" {
  for_each      = local.access_entries
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = each.key
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "this" {
  for_each      = local.access_entries
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = each.key
  policy_arn    = "${local.access_policy_prefix}/${each.value}"

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.this]
}

# OIDC provider for IRSA. No thumbprint: IAM validates EKS's issuer against its own root CAs.
resource "aws_iam_openid_connect_provider" "eks" {
  url            = aws_eks_cluster.main.identity[0].oidc[0].issuer
  client_id_list = ["sts.amazonaws.com"]
}

# The default CNI ignores NetworkPolicy objects; managing the add-on lets enforcement be switched on.
resource "aws_eks_addon" "vpc_cni" {
  cluster_name         = aws_eks_cluster.main.name
  addon_name           = "vpc-cni"
  configuration_values = jsonencode({ enableNetworkPolicy = "true" })

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
}

# ── Node group IAM role ────────────────────────────────────
data "aws_iam_policy_document" "eks_node_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "node" {
  name               = "${var.project_name}-eks-node-role"
  assume_role_policy = data.aws_iam_policy_document.eks_node_assume.json
}

resource "aws_iam_role_policy_attachment" "node_policies" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
  ])
  role       = aws_iam_role.node.name
  policy_arn = each.value
}

# ── Managed node group ─────────────────────────────────────
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.project_name}-node-group"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = var.subnet_ids

  instance_types = var.node_instance_types

  scaling_config {
    desired_size = var.node_desired_size
    min_size     = var.node_min_size
    max_size     = var.node_max_size
  }

  depends_on = [
    aws_iam_role_policy_attachment.node_policies,
    aws_eks_addon.vpc_cni,
  ]

  tags = { Name = "${var.project_name}-eks-node" }
}
