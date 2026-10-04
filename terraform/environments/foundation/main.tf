# Foundation: resources that must survive `terraform destroy` on the
# ephemeral dev environment — CI's OIDC provider and roles, and the
# ECR repo (so image history and the ECR_REPOSITORY_URL secret stay
# stable across dev environment teardown/recreate cycles).
#
# Applied by CI on merge (terraform-foundation.yml) once the foundation-apply role exists.
# The first apply, and any recovery from a broken role, is done by hand.

module "foundation_iam" {
  source       = "../../modules/foundation-iam"
  project_name = var.project_name
}

module "ecr" {
  source       = "../../modules/ecr"
  project_name = var.project_name
}
