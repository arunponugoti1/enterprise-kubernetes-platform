variable "project_id" {
  type = string
}

variable "location" {
  type = string
}

variable "kms_key_name" {
  type        = string
  description = "Fully-qualified KMS crypto key ID for CMEK."
}

variable "repositories" {
  description = "Map of repo_id => settings."
  type = map(object({
    format      = string                # DOCKER, MAVEN, NPM, PYTHON, HELM, etc.
    description = optional(string, "")
    immutable_tags = optional(bool, true)
    keep_count    = optional(number, 20)
    older_than    = optional(string, "2592000s") # 30 days for untagged
  }))
}

variable "readers" {
  description = "Members granted artifactregistry.reader on every repo (e.g. node SA)."
  type        = list(string)
  default     = []
}

variable "writers" {
  description = "Members granted artifactregistry.writer on every repo (e.g. CI SA)."
  type        = list(string)
  default     = []
}

data "google_project" "this" {
  project_id = var.project_id
}

resource "google_kms_crypto_key_iam_member" "ar" {
  crypto_key_id = var.kms_key_name
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:service-${data.google_project.this.number}@gcp-sa-artifactregistry.iam.gserviceaccount.com"
}

resource "google_artifact_registry_repository" "this" {
  for_each = var.repositories

  project       = var.project_id
  location      = var.location
  repository_id = each.key
  description   = each.value.description
  format        = each.value.format
  kms_key_name  = var.kms_key_name

  docker_config {
    immutable_tags = each.value.format == "DOCKER" ? each.value.immutable_tags : false
  }

  cleanup_policies {
    id     = "keep-recent"
    action = "KEEP"
    most_recent_versions {
      keep_count = each.value.keep_count
    }
  }

  cleanup_policies {
    id     = "delete-old-untagged"
    action = "DELETE"
    condition {
      tag_state  = "UNTAGGED"
      older_than = each.value.older_than
    }
  }

  depends_on = [google_kms_crypto_key_iam_member.ar]
}

locals {
  reader_bindings = {
    for pair in setproduct(keys(var.repositories), var.readers) :
    "${pair[0]}|${pair[1]}" => { repo = pair[0], member = pair[1] }
  }
  writer_bindings = {
    for pair in setproduct(keys(var.repositories), var.writers) :
    "${pair[0]}|${pair[1]}" => { repo = pair[0], member = pair[1] }
  }
}

resource "google_artifact_registry_repository_iam_member" "readers" {
  for_each   = local.reader_bindings
  project    = var.project_id
  location   = var.location
  repository = google_artifact_registry_repository.this[each.value.repo].name
  role       = "roles/artifactregistry.reader"
  member     = each.value.member
}

resource "google_artifact_registry_repository_iam_member" "writers" {
  for_each   = local.writer_bindings
  project    = var.project_id
  location   = var.location
  repository = google_artifact_registry_repository.this[each.value.repo].name
  role       = "roles/artifactregistry.writer"
  member     = each.value.member
}

output "repository_ids" {
  value = { for k, r in google_artifact_registry_repository.this : k => r.id }
}

output "repository_urls" {
  description = "Map of repo_id => host/path you can docker push to."
  value = {
    for k, r in google_artifact_registry_repository.this :
    k => "${var.location}-docker.pkg.dev/${var.project_id}/${r.repository_id}"
  }
}
