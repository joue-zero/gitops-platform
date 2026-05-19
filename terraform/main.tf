module "networking" {
  source       = "./modules/networking"
  vpc_cidr     = var.vpc_cidr
  project_name = var.project_name
  environment  = var.environment
}

module "security_groups" {
  source       = "./modules/security-groups"
  vpc_id       = module.networking.vpc_id
  project_name = var.project_name
  my_ip        = var.my_ip
}

module "iam" {
  source              = "./modules/iam"
  project_name        = var.project_name
  ssh_public_key_path = var.ssh_public_key_path
}

module "compute" {
  source               = "./modules/compute"
  project_name         = var.project_name
  environment          = var.environment
  vpc_id               = module.networking.vpc_id
  public_subnet_ids    = module.networking.public_subnet_ids
  private_subnet_ids   = module.networking.private_subnet_ids
  bastion_sg_id        = module.security_groups.bastion_sg_id
  app_sg_id            = module.security_groups.app_sg_id
  alb_sg_id            = module.security_groups.alb_sg_id
  key_pair_name        = module.iam.key_pair_name
  ec2_instance_profile = module.iam.ec2_instance_profile_name
}
