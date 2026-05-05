variable "project_id" {
  type = string
}

variable "name" {
  type        = string
  description = "GSA account_id (max 30 chars). Also drives display_name."
}

variable "display_name" {
  type    = string
  default = ""
}

variable "kubernetes_namespace" {
  type        = string
  description = "Kubernetes namespace where the bound KSA lives."
}

variable "kubernetes_service_account" {
  type        = string
  description = "Kubernetes service account name that may impersonate this GSA."
}

variable "project_roles" {
  type        = list(string)
  default     = []
  description = "Project-level IAM roles to grant the GSA (e.g. roles/cloudsql.client)."
}

variable "secret_accessor_secrets" {
  type        = list(string)
  default     = []
  description = "Secret Manager secret IDs (short names) the GSA gets roles/secretmanager.secretAccessor on. Secrets must live in project_id."
}

resource "google_service_account" "this" {
  project      = var.project_id
  account_id   = var.name
  display_name = var.display_name != "" ? var.display_name : "Workload Identity GSA for ${var.kubernetes_namespace}/${var.kubernetes_service_account}"
}

resource "google_service_account_iam_member" "wi" {
  service_account_id = google_service_account.this.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[${var.kubernetes_namespace}/${var.kubernetes_service_account}]"
}

resource "google_project_iam_member" "roles" {
  for_each = toset(var.project_roles)

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.this.email}"
}

resource "google_secret_manager_secret_iam_member" "secrets" {
  for_each = toset(var.secret_accessor_secrets)

  project   = var.project_id
  secret_id = each.value
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.this.email}"
}

output "email" {
  value = google_service_account.this.email
}

output "name" {
  value = google_service_account.this.name
}

output "ksa_annotation" {
  description = "Annotation to put on the Kubernetes ServiceAccount: iam.gke.io/gcp-service-account"
  value       = google_service_account.this.email
}
