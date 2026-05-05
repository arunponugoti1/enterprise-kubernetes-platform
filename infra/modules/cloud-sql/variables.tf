variable "project_id" {
  type = string
}

variable "name" {
  type = string
}

variable "region" {
  type = string
}

variable "database_version" {
  type    = string
  default = "POSTGRES_15"
}

variable "tier" {
  type    = string
  default = "db-custom-2-7680"
}

variable "availability_type" {
  type    = string
  default = "REGIONAL" # HA
  validation {
    condition     = contains(["REGIONAL", "ZONAL"], var.availability_type)
    error_message = "availability_type must be REGIONAL or ZONAL."
  }
}

variable "disk_size_gb" {
  type    = number
  default = 100
}

variable "disk_type" {
  type    = string
  default = "PD_SSD"
}

variable "private_network" {
  type        = string
  description = "VPC self_link for private IP."
}

variable "psa_dependency" {
  type        = any
  description = "Pass the VPC module's psa_connection output to enforce ordering."
  default     = null
}

variable "kms_key_name" {
  type        = string
  description = "Fully-qualified KMS crypto key ID for CMEK."
}

variable "deletion_protection" {
  type    = bool
  default = true
}

variable "backup_retention_days" {
  type    = number
  default = 30
}

variable "transaction_log_retention_days" {
  type    = number
  default = 7
}

variable "maintenance_window" {
  type = object({
    day          = optional(number, 7) # 1=Mon..7=Sun
    hour         = optional(number, 4) # UTC
    update_track = optional(string, "stable")
  })
  default = {}
}

variable "databases" {
  type    = list(string)
  default = []
}

variable "users" {
  type        = list(string)
  default     = []
  description = "App users to create with random passwords (passwords stored in Secret Manager by the caller)."
}

variable "extra_database_flags" {
  type    = map(string)
  default = {}
}
