output "attestor_name" {
  description = "Full resource name of the Binary Authorization attestor."
  value       = google_binary_authorization_attestor.qa_gate.name
}

output "attestor_kms_key_version_id" {
  description = "Fully-qualified KMS key version ID used to sign attestations. Pass as BINAUTHZ_KEY_VERSION_ID in CI."
  value       = data.google_kms_crypto_key_version.attestor.id
}

output "note_id" {
  description = "Container Analysis note ID backing the attestor."
  value       = google_container_analysis_note.qa_gate.id
}
