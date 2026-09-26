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
