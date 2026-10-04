variable "namespace" {
  description = "Namespace Argo CD is installed into"
  type        = string
  default     = "argocd"
}

variable "argocd_chart_version" {
  description = "Version of the argo/argo-cd Helm chart (chart 10.9.6 ships Argo CD v3.5.3)"
  type        = string
  default     = "10.9.6"
}

variable "argocd_apps_chart_version" {
  description = "Version of the argo/argocd-apps Helm chart, used to create the root Application"
  type        = string
  default     = "2.0.6"
}

variable "gitops_repo_url" {
  description = "Git repository Argo CD watches. It holds the Application manifests and the per-environment values."
  type        = string
}

variable "gitops_repo_revision" {
  description = "Branch, tag or commit of the GitOps repository to track"
  type        = string
  default     = "main"
}

variable "gitops_apps_path" {
  description = "Directory in the GitOps repository that holds the child Application manifests"
  type        = string
  default     = "apps"
}
