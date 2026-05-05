variable "project_id" {
  type = string
}

variable "namespace" {
  type    = string
  default = "argocd"
}

variable "chart_version" {
  type        = string
  description = "argo-cd Helm chart version (https://artifacthub.io/packages/helm/argo/argo-cd)."
  default     = "7.3.11"
}

variable "asm_revision_label" {
  type        = string
  description = "Managed ASM revision label so the namespace participates in the mesh."
  default     = "asm-managed"
}

variable "create_workload_identity_sa" {
  type        = bool
  default     = true
  description = "Create a GSA bound to the argocd-repo-server KSA, for pulling OCI Helm charts from Artifact Registry."
}

variable "artifact_registry_reader_project" {
  type        = string
  default     = ""
  description = "If set, grants the GSA roles/artifactregistry.reader on this project."
}

variable "extra_values" {
  type        = string
  default     = ""
  description = "Extra YAML appended to the Helm values for environment-specific tweaks."
}

resource "kubernetes_namespace_v1" "argocd" {
  metadata {
    name = var.namespace
    labels = {
      "istio.io/rev"                         = var.asm_revision_label
      "pod-security.kubernetes.io/enforce"   = "baseline"
      "pod-security.kubernetes.io/audit"     = "restricted"
      "pod-security.kubernetes.io/warn"      = "restricted"
    }
  }
}

# GSA for the repo-server so it can fetch private OCI Helm charts from
# Artifact Registry without static creds.
resource "google_service_account" "repo_server" {
  count = var.create_workload_identity_sa ? 1 : 0

  project      = var.project_id
  account_id   = "argocd-repo-server"
  display_name = "ArgoCD repo-server (WIF)"
}

resource "google_service_account_iam_member" "repo_server_wi" {
  count = var.create_workload_identity_sa ? 1 : 0

  service_account_id = google_service_account.repo_server[0].name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[${var.namespace}/argocd-repo-server]"
}

resource "google_project_iam_member" "repo_server_ar_reader" {
  count = var.create_workload_identity_sa && var.artifact_registry_reader_project != "" ? 1 : 0

  project = var.artifact_registry_reader_project
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.repo_server[0].email}"
}

locals {
  ksa_annotation = var.create_workload_identity_sa ? {
    "iam.gke.io/gcp-service-account" = google_service_account.repo_server[0].email
  } : {}

  base_values = yamlencode({
    global = {
      domain = ""
    }

    # HA topology — active/active on every component that supports it.
    redis-ha = {
      enabled = true
    }

    controller = {
      replicas = 1 # the application-controller is a singleton (sharded internally)
      resources = {
        requests = { cpu = "250m", memory = "512Mi" }
        limits   = { memory = "2Gi" }
      }
    }

    server = {
      replicas = 2
      autoscaling = {
        enabled     = true
        minReplicas = 2
        maxReplicas = 5
      }
      service = {
        type = "ClusterIP"
      }
      # The Istio ingress gateway (asm-gateways) terminates TLS; the server
      # speaks plain HTTP behind the mesh sidecar with mTLS.
      extraArgs = ["--insecure"]
      resources = {
        requests = { cpu = "100m", memory = "128Mi" }
        limits   = { memory = "512Mi" }
      }
    }

    repoServer = {
      replicas = 2
      autoscaling = {
        enabled     = true
        minReplicas = 2
        maxReplicas = 6
      }
      serviceAccount = {
        create      = true
        name        = "argocd-repo-server"
        annotations = local.ksa_annotation
      }
      resources = {
        requests = { cpu = "100m", memory = "256Mi" }
        limits   = { memory = "1Gi" }
      }
    }

    applicationSet = {
      replicas = 2
    }

    notifications = {
      enabled = true
    }

    dex = {
      enabled = false
    }

    configs = {
      params = {
        "server.insecure" = true
      }
      cm = {
        "application.resourceTrackingMethod" = "annotation"
        "timeout.reconciliation"             = "180s"
        "exec.enabled"                       = "false"
      }
      rbac = {
        "policy.default" = "role:readonly"
      }
    }
  })
}

resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.chart_version
  namespace  = kubernetes_namespace_v1.argocd.metadata[0].name

  atomic            = true
  cleanup_on_fail   = true
  dependency_update = true
  timeout           = 900

  values = compact([
    local.base_values,
    var.extra_values,
  ])

  depends_on = [
    kubernetes_namespace_v1.argocd,
    google_service_account_iam_member.repo_server_wi,
  ]
}

output "namespace" {
  value = kubernetes_namespace_v1.argocd.metadata[0].name
}

output "repo_server_gsa_email" {
  value = var.create_workload_identity_sa ? google_service_account.repo_server[0].email : null
}
