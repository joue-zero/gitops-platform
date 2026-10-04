# calls modules, wires them together variables.tf # inputs for this env outputs.tf
# what this env exposes terraform.tfvars # actual values (gitignored if secrets)

module "networking" {
  source       = "../../modules/networking"
  vpc_cidr     = var.vpc_cidr
  project_name = var.project_name
  environment  = var.environment
}

module "security_groups" {
  source       = "../../modules/security-groups"
  vpc_id       = module.networking.vpc_id
  project_name = var.project_name
  my_ip        = var.my_ip
}

module "compute_iam" {
  source         = "../../modules/compute-iam"
  project_name   = var.project_name
  ssh_public_key = var.ssh_public_key
}

module "compute" {
  source               = "../../modules/compute"
  project_name         = var.project_name
  environment          = var.environment
  vpc_id               = module.networking.vpc_id
  public_subnet_ids    = module.networking.public_subnet_ids
  private_subnet_ids   = module.networking.private_subnet_ids
  bastion_sg_id        = module.security_groups.bastion_sg_id
  app_sg_id            = module.security_groups.app_sg_id
  alb_sg_id            = module.security_groups.alb_sg_id
  key_pair_name        = module.compute_iam.key_pair_name
  ec2_instance_profile = module.compute_iam.ec2_instance_profile_name
}

module "data" {
  source          = "../../modules/data"
  project_name    = var.project_name
  data_subnet_ids = module.networking.data_subnet_ids
  db_sg_id        = module.security_groups.db_sg_id
}

data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id

  # CI roles from the foundation layer
  tf_apply_role_arn = "arn:aws:iam::${local.account_id}:role/${var.project_name}-tf-apply-role"
  tf_plan_role_arn  = "arn:aws:iam::${local.account_id}:role/${var.project_name}-tf-plan-role"

  # comma-separated, so an unset CI variable means nobody extra
  eks_extra_admins = [for p in split(",", var.eks_admin_principals) : trimspace(p) if trimspace(p) != ""]
}

# Staged: added alongside `compute`, which is removed once EKS is proven.
module "eks" {
  source       = "../../modules/eks"
  project_name = var.project_name
  vpc_id       = module.networking.vpc_id
  subnet_ids   = module.networking.private_subnet_ids

  node_instance_types = var.eks_node_instance_types

  admin_principal_arns  = concat([local.tf_apply_role_arn], local.eks_extra_admins)
  viewer_principal_arns = [local.tf_plan_role_arn]
}

module "lb_controller" {
  source            = "../../modules/lb-controller"
  project_name      = var.project_name
  cluster_name      = module.eks.cluster_name
  vpc_id            = module.networking.vpc_id
  region            = var.aws_region
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.oidc_provider_url
}

# Applied last and destroyed first, so the controller outlives the Ingresses Argo CD manages.
module "argocd" {
  source          = "../../modules/argocd"
  gitops_repo_url = var.gitops_repo_url

  depends_on = [module.eks, module.lb_controller]
}
