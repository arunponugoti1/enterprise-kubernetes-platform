# CMEK: grant the GCS service agent access to the encryption key
resource "google_kms_crypto_key_iam_member" "gcs_encrypter" {
  crypto_key_id = var.kms_key_id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:service-${data.google_project.this.number}@gs-project-accounts.iam.gserviceaccount.com"
}

data "google_project" "this" {
  project_id = var.project_id
}

# ─── Tamper-evident audit log bucket ──────────────────────────────────────────
resource "google_storage_bucket" "audit_logs" {
  project  = var.project_id
  name     = "${var.project_id}-audit-logs-${var.env}"
  location = var.region

  storage_class = "STANDARD"
  force_destroy = false

  # Retention policy provides WORM immutability.
  # lock_retention_policy=true makes this permanent and irreversible — only
  # enable in prod after validating retention_days matches compliance requirements.
  retention_policy {
    retention_period = var.retention_days * 86400
    is_locked        = var.lock_retention_policy
  }

  versioning {
    enabled = true
  }

  encryption {
    default_kms_key_name = var.kms_key_id
  }

  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  lifecycle_rule {
    condition { age = 90 }
    action {
      type          = "SetStorageClass"
      storage_class = "COLDLINE"
    }
  }

  lifecycle_rule {
    condition { age = var.retention_days }
    action { type = "Delete" }
  }

  labels = {
    env     = var.env
    purpose = "audit-logs"
  }

  depends_on = [google_kms_crypto_key_iam_member.gcs_encrypter]
}

# ─── Log sink ─────────────────────────────────────────────────────────────────
resource "google_logging_project_sink" "audit_logs" {
  project     = var.project_id
  name        = "audit-logs-gcs-${var.env}"
  destination = "storage.googleapis.com/${google_storage_bucket.audit_logs.name}"

  filter = <<-EOT
    log_id("cloudaudit.googleapis.com/activity") OR
    log_id("cloudaudit.googleapis.com/data_access") OR
    log_id("cloudaudit.googleapis.com/system_event") OR
    log_id("cloudaudit.googleapis.com/policy")
  EOT

  unique_writer_identity = true
}

# Grant the sink's writer SA write access to the bucket
resource "google_storage_bucket_iam_member" "sink_writer" {
  bucket = google_storage_bucket.audit_logs.name
  role   = "roles/storage.objectCreator"
  member = google_logging_project_sink.audit_logs.writer_identity
}

# Grant the sink's writer SA access to encrypt with CMEK
resource "google_kms_crypto_key_iam_member" "sink_encrypter" {
  crypto_key_id = var.kms_key_id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = google_logging_project_sink.audit_logs.writer_identity
}

# ─── Admin Activity audit logs on by default; enable Data Access ──────────────
resource "google_project_iam_audit_config" "all_services" {
  project = var.project_id
  service = "allServices"

  audit_log_config {
    log_type = "ADMIN_READ"
  }
  audit_log_config {
    log_type = "DATA_READ"
  }
  audit_log_config {
    log_type = "DATA_WRITE"
  }
}
