# ─── GCP Service Account ───────────────────────────────────────────────────────
resource "google_service_account" "this" {
  project      = var.project_id
  account_id   = "svc-${var.service_name}-${var.env}"
  display_name = "[${var.env}] ${var.service_name} workload identity GSA"
}

# Workload Identity binding: KSA in the service namespace may impersonate this GSA
resource "google_service_account_iam_member" "wi" {
  service_account_id = google_service_account.this.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[${var.service_name}/${var.service_name}]"
}

# Project-level roles (e.g. roles/cloudsql.client, roles/pubsub.publisher)
resource "google_project_iam_member" "roles" {
  for_each = toset(var.project_roles)

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.this.email}"
}

# Secret Manager accessor grants
resource "google_secret_manager_secret_iam_member" "secrets" {
  for_each = toset(var.secret_accessor_secret_ids)

  project   = var.project_id
  secret_id = each.value
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.this.email}"
}

# Pub/Sub publisher grants
resource "google_pubsub_topic_iam_member" "publisher" {
  for_each = toset(var.pubsub_publisher_topic_ids)

  project = var.project_id
  topic   = each.value
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${google_service_account.this.email}"
}

# Pub/Sub subscriber grants
resource "google_pubsub_subscription_iam_member" "subscriber" {
  for_each = toset(var.pubsub_subscriber_subscription_ids)

  project      = var.project_id
  subscription = each.value
  role         = "roles/pubsub.subscriber"
  member       = "serviceAccount:${google_service_account.this.email}"
}

# ─── Kubernetes Namespace ─────────────────────────────────────────────────────
resource "kubernetes_namespace_v1" "this" {
  metadata {
    name = var.service_name
    labels = merge(
      {
        "istio.io/rev"                       = var.asm_revision_label
        "pod-security.kubernetes.io/enforce" = "restricted"
        "pod-security.kubernetes.io/audit"   = "restricted"
        "pod-security.kubernetes.io/warn"    = "restricted"
      },
      var.extra_namespace_labels
    )
  }
}

# ─── Kubernetes ServiceAccount (annotated for Workload Identity) ──────────────
resource "kubernetes_service_account_v1" "this" {
  metadata {
    name      = var.service_name
    namespace = kubernetes_namespace_v1.this.metadata[0].name
    annotations = {
      "iam.gke.io/gcp-service-account" = google_service_account.this.email
    }
  }
}
