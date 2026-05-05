variable "bootstrap_project_id" {
  description = "Existing GCP project that hosts Terraform state, CI service accounts, and the WIF pool."
  type        = string
}

variable "region" {
  description = "Default region for regional resources (state bucket, KMS keyring)."
  type        = string
  default     = "us-central1"
}

variable "state_bucket_name" {
  description = "Globally unique name for the GCS bucket that stores Terraform state."
  type        = string
}

variable "github_org" {
  description = "GitHub organization that owns the repos allowed to impersonate the CI service account."
  type        = string
}

variable "github_repos" {
  description = "List of GitHub repositories (without org prefix) allowed to impersonate the CI service account via WIF."
  type        = list(string)
  default     = ["infra-gcp-terraform"]
}

variable "managed_project_ids" {
  description = "Project IDs the CI service account is allowed to manage (dev/uat/prod)."
  type        = list(string)
}
