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

output "ecr_repository_url" {
  value = module.data.ecr_repository_url
}