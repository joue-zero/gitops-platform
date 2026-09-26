# Foundation: resources that must survive `terraform destroy` on the
# ephemeral dev environment — CI's OIDC provider and roles, and the
# ECR repo (so image history and the ECR_REPOSITORY_URL secret stay
# stable across dev environment teardown/recreate cycles).
#
# Applied manually, not via CI — CI's own permission to run terraform
# comes from the roles this config creates, so this layer can't
# bootstrap itself.

module "foundation_iam" {
  source       = "../../modules/foundation-iam"
  project_name = var.project_name
}

module "ecr" {
  source       = "../../modules/ecr"
  project_name = var.project_name
}
