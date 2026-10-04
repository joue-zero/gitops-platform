output "github_actions_role_arn" { value = aws_iam_role.github_actions.arn }
output "github_actions_tf_plan_role_arn" { value = aws_iam_role.github_actions_tf_plan.arn }
output "github_actions_tf_apply_role_arn" { value = aws_iam_role.github_actions_tf_apply.arn }
output "oidc_provider_arn" { value = aws_iam_openid_connect_provider.github.arn }
output "github_actions_foundation_apply_role_arn" { value = aws_iam_role.github_actions_foundation_apply.arn }
