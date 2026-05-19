output "key_pair_name" { value = aws_key_pair.deployer.key_name }
output "ec2_instance_profile_name" { value = aws_iam_instance_profile.ec2.name }
output "github_actions_role_arn" { value = aws_iam_role.github_actions.arn }
