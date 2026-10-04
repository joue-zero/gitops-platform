# Installed by Terraform so a recreated cluster gets Argo CD back and re-syncs from Git.

resource "helm_release" "argocd" {
  name             = "argocd"
  namespace        = var.namespace
  create_namespace = true

  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.argocd_chart_version

  values = [file("${path.module}/values/argocd.yaml")]

  # roll back instead of leaving a half-installed controller
  wait            = true
  atomic          = true
  cleanup_on_fail = true
  timeout         = 600
}

# App-of-apps root. Created with the argocd-apps chart because a manifest resource needs the Application CRD at plan time.
resource "helm_release" "root_app" {
  name      = "argocd-root"
  namespace = var.namespace

  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argocd-apps"
  version    = var.argocd_apps_chart_version

  values = [yamlencode({
    applications = {
      root = {
        namespace = var.namespace
        project   = "default"

        # destroying the root cascades to the child apps and what they manage
        finalizers = ["resources-finalizer.argocd.argoproj.io"]

        source = {
          repoURL        = var.gitops_repo_url
          targetRevision = var.gitops_repo_revision
          path           = var.gitops_apps_path
        }

        destination = {
          server    = "https://kubernetes.default.svc"
          namespace = var.namespace
        }

        syncPolicy = {
          # prune removes what leaves Git; selfHeal reverts manual drift
          automated   = { prune = true, selfHeal = true }
          syncOptions = ["ServerSideApply=true"]
        }
      }
    }
  })]

  wait            = true
  atomic          = true
  cleanup_on_fail = true
  timeout         = 300

  depends_on = [helm_release.argocd]
}
