variable "project_name" {
  description = "Prefix for all resource names and tags"
  type        = string
  default     = "gitops-platform"
}

variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "eu-central-1"
}

variable "environment" {
  description = "Environment name (dev / prod)"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "ssh_public_key" {
  description = "SSH public key contents to register with AWS (not a path — a local path doesn't exist when this runs in CI)"
  type        = string
}

variable "my_ip" {
  description = "Your public IP for bastion SSH access"
  type        = string
  sensitive   = true
  # No default — must be set in tfvars. Never 0.0.0.0/0
}

variable "eks_admin_principals" {
  description = "Comma-separated IAM user/role ARNs granted cluster-admin on the EKS cluster, in addition to the CI apply role. Empty means only the CI role."
  type        = string
  default     = ""
}

variable "gitops_repo_url" {
  description = "Git repository Argo CD watches for Application manifests and per-environment values"
  type        = string
  default     = "https://github.com/joue-zero/gitops-platform-config.git"
}

variable "eks_node_instance_types" {
  description = "Instance types for the EKS worker nodes. Must be x86_64 (the image is built for amd64). t3.small is free-tier eligible and fits the current workload."
  type        = list(string)
  default     = ["t3.small"]
}
