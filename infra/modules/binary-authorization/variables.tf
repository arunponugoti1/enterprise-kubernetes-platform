variable "project_id" {
  type = string
}

variable "env" {
  type = string
}

variable "key_ring_id" {
  type        = string
  description = "Fully-qualified ID of the existing KMS keyring (from module.kms.keyring_id). The asymmetric attestor signing key is created here."
}

variable "ci_service_account_email" {
  type        = string
  description = "Email of the CI service account that will sign and create attestations after a successful Trivy scan."
}

variable "enforcement_mode" {
  type        = string
  default     = "DRYRUN_AUDIT_LOG_ONLY"
  description = "DRYRUN_AUDIT_LOG_ONLY for dev (audit without blocking); ENFORCED_BLOCK_AND_AUDIT_LOG for prod."

  validation {
    condition     = contains(["DRYRUN_AUDIT_LOG_ONLY", "ENFORCED_BLOCK_AND_AUDIT_LOG"], var.enforcement_mode)
    error_message = "enforcement_mode must be DRYRUN_AUDIT_LOG_ONLY or ENFORCED_BLOCK_AND_AUDIT_LOG."
  }
}
