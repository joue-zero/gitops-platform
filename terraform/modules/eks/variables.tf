variable "project_name" { type = string }

variable "vpc_id" { type = string }

variable "subnet_ids" {
  description = "Subnet IDs for the control plane ENIs and worker nodes (2+ AZs)"
  type        = list(string)
}

variable "kubernetes_version" {
  type    = string
  default = "1.33" # confirmed available via `aws eks describe-addon-versions`; avoid 1.31 (oldest supported, closest to deprecation)
}

variable "node_instance_types" {
  # t3.small is free-tier eligible; 2 nodes (22 pod slots) hold the ~13 pods. t3.micro (4 pods/node) is too small. x86_64 matches the image.
  type    = list(string)
  default = ["t3.small"]
}

variable "node_desired_size" {
  type    = number
  default = 2
}

variable "node_min_size" {
  type    = number
  default = 1
}

variable "node_max_size" {
  type    = number
  default = 3
}

variable "admin_principal_arns" {
  description = "IAM role/user ARNs granted cluster-admin through EKS access entries"
  type        = list(string)
  default     = []
}

variable "viewer_principal_arns" {
  description = "IAM role/user ARNs granted read-only access (including Secrets, which Helm releases are stored in)"
  type        = list(string)
  default     = []
}
