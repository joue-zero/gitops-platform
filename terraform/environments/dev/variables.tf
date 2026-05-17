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
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "ssh_public_key_path" {
  description = "Path to SSH public key to register with AWS"
  type        = string
  default     = "~/.ssh/gitops-platform.pub"
}

variable "my_ip" {
  description = "Your public IP for bastion SSH access"
  type        = string
  # No default — must be set in tfvars. Never 0.0.0.0/0
}