variable "project_id" {
  type = string
}

variable "env" {
  type = string
}

variable "region" {
  type = string
}

variable "kms_key_id" {
  type        = string
  description = "CMEK key ID for encrypting the audit log GCS bucket."
}

variable "retention_days" {
  type        = number
  default     = 2555 # 7 years — common compliance baseline
  description = "How long audit log objects are retained before deletion."
}

variable "lock_retention_policy" {
  type        = bool
  default     = false
  description = "When true, the retention policy is permanently locked (WORM). Set true only in prod after validating retention_days."
}
