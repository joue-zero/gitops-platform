output "vpc_id" {
  value = module.networking.vpc_id
}

output "bastion_public_ip" {
  value = module.compute.bastion_public_ip
}

output "app_private_ips" {
  value = module.compute.app_private_ips
}

output "alb_dns_name" {
  value = module.compute.alb_dns_name
}

output "db_endpoint" {
  value = module.data.db_endpoint
}

output "db_credentials_secret_arn" {
  value = module.data.db_credentials_secret_arn
}

output "eks_cluster_name" {
  value = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "eks_oidc_provider_arn" {
  value = module.eks.oidc_provider_arn
}

output "argocd_namespace" {
  value = module.argocd.namespace
}
