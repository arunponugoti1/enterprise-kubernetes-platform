# ---------------------------------------------------------------------------
# Phase 4: ArgoCD (GitOps control plane) + app-of-apps root Application
# ---------------------------------------------------------------------------

module "argocd" {
  source = "../../modules/argocd"

  project_id                       = var.project_id
  asm_revision_label               = module.asm.control_plane_revision_label
  artifact_registry_reader_project = var.project_id

  depends_on = [module.asm, module.gke]
}

# App-of-apps root: a single Argo Application that points at the GitOps repo
# directory containing all child Applications. ArgoCD then takes over and
# reconciles everything else (baseline namespaces, mesh policies, services).
resource "kubernetes_manifest" "root_application" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "root"
      namespace = module.argocd.namespace
      finalizers = [
        "resources-finalizer.argocd.argoproj.io",
      ]
    }
    spec = {
      project = "default"
      source = {
        repoURL        = var.gitops_repo_url
        targetRevision = var.gitops_target_revision
        path           = "gitops-manifests-${var.env}/apps"
        directory = {
          recurse = true
        }
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = module.argocd.namespace
      }
      syncPolicy = {
        automated = {
          prune    = true
          selfHeal = true
        }
        syncOptions = [
          "CreateNamespace=false",
          "ServerSideApply=true",
          "ApplyOutOfSyncOnly=true",
        ]
        retry = {
          limit = 5
          backoff = {
            duration    = "10s"
            factor      = 2
            maxDuration = "5m"
          }
        }
      }
    }
  }

  depends_on = [module.argocd]
}
