output "gsa_email" {
  description = "Email of the GCP service account. Set as gsaEmail in the ArgoCD Application helm.parameters."
  value       = google_service_account.this.email
}

output "gsa_name" {
  description = "Fully-qualified resource name of the GCP service account."
  value       = google_service_account.this.name
}

output "namespace" {
  description = "Name of the Kubernetes namespace owned by this module."
  value       = kubernetes_namespace_v1.this.metadata[0].name
}

output "ksa_name" {
  description = "Name of the Kubernetes ServiceAccount annotated for Workload Identity."
  value       = kubernetes_service_account_v1.this.metadata[0].name
}
