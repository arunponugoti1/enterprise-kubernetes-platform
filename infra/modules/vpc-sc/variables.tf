variable "org_id" {
  type        = string
  description = "GCP Organization ID. VPC-SC perimeters are org-scoped resources."
}

variable "policy_id" {
  type        = string
  default     = ""
  description = "ID of an existing Access Context Manager access policy. If empty, a new policy is created (requires org-level resourcemanager.accessPolicies.create)."
}

variable "env" {
  type = string
}

variable "protected_project_numbers" {
  type        = list(string)
  description = "List of project numbers (not IDs) to include inside the perimeter."
}

variable "restricted_services" {
  type = list(string)
  default = [
    "storage.googleapis.com",
    "bigquery.googleapis.com",
    "container.googleapis.com",
    "sqladmin.googleapis.com",
    "secretmanager.googleapis.com",
    "cloudkms.googleapis.com",
    "pubsub.googleapis.com",
    "artifactregistry.googleapis.com",
    "containeranalysis.googleapis.com",
    "binaryauthorization.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
  ]
  description = "GCP services restricted by the perimeter (data exfiltration prevention)."
}

variable "authorized_members" {
  type        = list(string)
  default     = []
  description = "Identities (serviceAccount:, user:, group:) allowed to access the perimeter from outside via an access level."
}

variable "authorized_ip_ranges" {
  type        = list(string)
  default     = []
  description = "Corporate IP CIDR ranges that are granted an access level for the perimeter."
}

variable "perimeter_mode" {
  type        = string
  default     = "DRY_RUN"
  description = "ENFORCE or DRY_RUN. Use DRY_RUN first to audit violations before enforcing."

  validation {
    condition     = contains(["ENFORCE", "DRY_RUN"], var.perimeter_mode)
    error_message = "perimeter_mode must be ENFORCE or DRY_RUN."
  }
}
