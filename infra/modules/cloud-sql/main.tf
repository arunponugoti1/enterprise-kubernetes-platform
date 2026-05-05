data "google_project" "this" {
  project_id = var.project_id
}

# Cloud SQL service agent must be able to use the CMEK key.
resource "google_project_service_identity" "sql" {
  provider = google-beta
  project  = var.project_id
  service  = "sqladmin.googleapis.com"
}

resource "google_kms_crypto_key_iam_member" "sql" {
  crypto_key_id = var.kms_key_name
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${google_project_service_identity.sql.email}"
}

resource "random_id" "suffix" {
  byte_length = 2
}

locals {
  default_flags = {
    "cloudsql.enable_pgaudit" = "on"
    "log_connections"         = "on"
    "log_disconnections"      = "on"
    "log_lock_waits"          = "on"
    "log_checkpoints"         = "on"
    "log_min_duration_statement" = "1000"
  }
  flags = merge(local.default_flags, var.extra_database_flags)
}

resource "google_sql_database_instance" "this" {
  provider = google-beta

  project             = var.project_id
  # Suffix forces a fresh name on recreation, since instance names are reserved for ~7 days.
  name                = "${var.name}-${random_id.suffix.hex}"
  region              = var.region
  database_version    = var.database_version
  deletion_protection = var.deletion_protection
  encryption_key_name = var.kms_key_name

  settings {
    tier              = var.tier
    availability_type = var.availability_type
    disk_size         = var.disk_size_gb
    disk_type         = var.disk_type
    disk_autoresize   = true
    edition           = "ENTERPRISE"

    backup_configuration {
      enabled                        = true
      point_in_time_recovery_enabled = true
      transaction_log_retention_days = var.transaction_log_retention_days
      start_time                     = "02:00"
      backup_retention_settings {
        retained_backups = var.backup_retention_days
        retention_unit   = "COUNT"
      }
    }

    ip_configuration {
      ipv4_enabled                                  = false
      private_network                               = var.private_network
      enable_private_path_for_google_cloud_services = true
      ssl_mode                                      = "ENCRYPTED_ONLY"
    }

    maintenance_window {
      day          = var.maintenance_window.day
      hour         = var.maintenance_window.hour
      update_track = var.maintenance_window.update_track
    }

    insights_config {
      query_insights_enabled  = true
      record_application_tags = true
      record_client_address   = false
      query_string_length     = 1024
    }

    deletion_protection_enabled = var.deletion_protection

    dynamic "database_flags" {
      for_each = local.flags
      content {
        name  = database_flags.key
        value = database_flags.value
      }
    }
  }

  depends_on = [
    google_kms_crypto_key_iam_member.sql,
    var.psa_dependency,
  ]
}

resource "google_sql_database" "this" {
  for_each = toset(var.databases)
  project  = var.project_id
  name     = each.value
  instance = google_sql_database_instance.this.name
}

resource "random_password" "users" {
  for_each = toset(var.users)
  length   = 32
  special  = true
  override_special = "!@#$%^&*()-_=+[]{}"
}

resource "google_sql_user" "users" {
  for_each = toset(var.users)
  project  = var.project_id
  instance = google_sql_database_instance.this.name
  name     = each.value
  password = random_password.users[each.value].result
}
