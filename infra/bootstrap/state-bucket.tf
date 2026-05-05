resource "google_kms_key_ring" "tfstate" {
  project  = var.bootstrap_project_id
  name     = "tfstate"
  location = var.region

  depends_on = [google_project_service.bootstrap]
}

resource "google_kms_crypto_key" "tfstate" {
  name            = "tfstate"
  key_ring        = google_kms_key_ring.tfstate.id
  rotation_period = "7776000s" # 90 days

  lifecycle {
    prevent_destroy = true
  }
}

data "google_storage_project_service_account" "gcs" {
  project = var.bootstrap_project_id

  depends_on = [google_project_service.bootstrap]
}

resource "google_kms_crypto_key_iam_member" "gcs_encrypter" {
  crypto_key_id = google_kms_crypto_key.tfstate.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${data.google_storage_project_service_account.gcs.email_address}"
}

resource "google_storage_bucket" "tfstate" {
  name                        = var.state_bucket_name
  project                     = var.bootstrap_project_id
  location                    = var.region
  force_destroy               = false
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  versioning {
    enabled = true
  }

  encryption {
    default_kms_key_name = google_kms_crypto_key.tfstate.id
  }

  lifecycle_rule {
    condition {
      num_newer_versions = 30
    }
    action {
      type = "Delete"
    }
  }

  depends_on = [google_kms_crypto_key_iam_member.gcs_encrypter]
}
