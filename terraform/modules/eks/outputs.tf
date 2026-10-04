output "cluster_name" {
  value = aws_eks_cluster.main.name
  # Consumers that talk to the cluster wait for nodes, access entries and the CNI.
  depends_on = [aws_eks_node_group.main, aws_eks_access_policy_association.this, aws_eks_addon.vpc_cni]
}

output "cluster_endpoint" {
  value = aws_eks_cluster.main.endpoint
}

output "cluster_certificate_authority_data" {
  value = aws_eks_cluster.main.certificate_authority[0].data
}

output "cluster_security_group_id" {
  value = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
}

output "oidc_provider_arn" {
  value = aws_iam_openid_connect_provider.eks.arn
}

output "oidc_provider_url" {
  value = aws_iam_openid_connect_provider.eks.url
}

output "node_role_arn" {
  value = aws_iam_role.node.arn
}
