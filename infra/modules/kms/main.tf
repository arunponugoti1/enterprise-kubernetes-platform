variable "project_id" {
  type = string
}

variable "location" {
  type        = string
  description = "Region for the keyring (must match the regions of consuming resources)."
}

variable "keyring_name" {
  type    = string
  default = "platform"
}

variable "keys" {
  description = "Map of logical key name => settings. Used for one CMEK per purpose (gke, sql, artifact-registry, gcs, etc.)."
  type = map(object({
    rotation_period = optional(string, "7776000s") # 90 days
    purpose         = optional(string, "ENCRYPT_DECRYPT")
  }))
}

resource "google_kms_key_ring" "this" {
  project  = var.project_id
  name     = var.keyring_name
  location = var.location
}

resource "google_kms_crypto_key" "this" {
  for_each = var.keys

  name            = each.key
  key_ring        = google_kms_key_ring.this.id
  rotation_period = each.value.rotation_period
  purpose         = each.value.purpose

  lifecycle {
    prevent_destroy = true
  }
}

output "key_ids" {
  description = "Map of logical key name => fully-qualified crypto key ID."
  value       = { for k, v in google_kms_crypto_key.this : k => v.id }
}

output "keyring_id" {
  value = google_kms_key_ring.this.id
}
