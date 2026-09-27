variable "project_name" { type = string }

variable "ssh_public_key" {
  description = "SSH public key contents (not a path) — e.g. $(cat ~/.ssh/gitops-platform.pub)"
  type        = string
}
