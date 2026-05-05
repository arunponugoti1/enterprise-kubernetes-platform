variable "project_id" {
  type = string
}

variable "name" {
  type = string
}

variable "region" {
  type        = string
  description = "Region for the regional cluster (control plane is HA across zones in this region)."
}

variable "network" {
  type        = string
  description = "VPC self_link or name."
}

variable "subnetwork" {
  type        = string
  description = "Subnet self_link or name in which nodes are created."
}

variable "pods_range_name" {
  type = string
}

variable "services_range_name" {
  type = string
}

variable "master_ipv4_cidr_block" {
  type        = string
  description = "/28 CIDR for the GKE control plane (must not overlap with anything else in the VPC peer)."
}

variable "master_authorized_networks" {
  type = list(object({
    cidr_block   = string
    display_name = string
  }))
  default     = []
  description = "Networks allowed to talk to the public control-plane endpoint. Empty = no public access."
}

variable "release_channel" {
  type    = string
  default = "REGULAR"
  validation {
    condition     = contains(["RAPID", "REGULAR", "STABLE"], var.release_channel)
    error_message = "release_channel must be RAPID, REGULAR, or STABLE."
  }
}

variable "database_encryption_key" {
  type        = string
  description = "Fully-qualified KMS key ID for application-layer secrets encryption (etcd CMEK)."
}

variable "node_pool" {
  type = object({
    machine_type    = optional(string, "e2-standard-4")
    min_node_count  = optional(number, 1)
    max_node_count  = optional(number, 5)
    disk_size_gb    = optional(number, 100)
    disk_type       = optional(string, "pd-balanced")
    image_type      = optional(string, "COS_CONTAINERD")
    spot            = optional(bool, false)
    max_surge       = optional(number, 1)
    max_unavailable = optional(number, 0)
  })
  default = {}
}

variable "deletion_protection" {
  type    = bool
  default = true
}

variable "maintenance_start_time" {
  type        = string
  default     = "2024-01-01T03:00:00Z"
  description = "RFC3339 start of the daily maintenance window (UTC)."
}
