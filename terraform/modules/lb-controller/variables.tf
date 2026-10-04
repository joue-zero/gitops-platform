variable "project_name" { type = string }
variable "cluster_name" { type = string }
variable "vpc_id" { type = string }
variable "region" { type = string }

variable "oidc_provider_arn" {
  description = "ARN of the cluster's IAM OIDC provider, used for the controller's IRSA role"
  type        = string
}

variable "oidc_provider_url" {
  description = "Issuer URL of the cluster's OIDC provider"
  type        = string
}

variable "namespace" {
  type    = string
  default = "kube-system"
}

variable "chart_version" {
  description = "Version of the eks/aws-load-balancer-controller chart. policy.json must come from the same release."
  type        = string
  default     = "3.5.0"
}
