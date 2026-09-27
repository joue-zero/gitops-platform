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