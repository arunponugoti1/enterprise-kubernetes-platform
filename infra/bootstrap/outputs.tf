output "state_bucket" {
  description = "GCS bucket holding Terraform remote state. Use this in env backend.tf files."
  value       = google_storage_bucket.tfstate.name
}

output "ci_service_account_email" {
  description = "Email of the CI Terraform service account; set as service_account in google-github-actions/auth."
  value       = google_service_account.ci_terraform.email
}

output "workload_identity_provider" {
  description = "Full resource name of the WIF provider; set as workload_identity_provider in google-github-actions/auth."
  value       = google_iam_workload_identity_pool_provider.github.name
}

output "kms_key" {
  description = "CMEK key protecting the state bucket."
  value       = google_kms_crypto_key.tfstate.id
}
