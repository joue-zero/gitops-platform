output "github_actions_role_arn" {
  value = module.foundation_iam.github_actions_role_arn
}

output "github_actions_tf_plan_role_arn" {
  value = module.foundation_iam.github_actions_tf_plan_role_arn
}

output "github_actions_tf_apply_role_arn" {
  value = module.foundation_iam.github_actions_tf_apply_role_arn
}

output "ecr_repository_url" {
  value = module.ecr.ecr_repository_url
}
