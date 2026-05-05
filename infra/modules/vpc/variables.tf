variable "project_id" {
  type = string
}

variable "name" {
  type        = string
  description = "VPC name (also used as a prefix for subnets, router, NAT)."
}

variable "region" {
  type = string
}

variable "subnet_cidr" {
  type        = string
  description = "Primary CIDR for the GKE node subnet."
}

variable "pods_cidr" {
  type        = string
  description = "Secondary range for GKE pods (alias IPs)."
}

variable "services_cidr" {
  type        = string
  description = "Secondary range for GKE services."
}

variable "psa_range_prefix_length" {
  type        = number
  default     = 16
  description = "Prefix length for the private services access range allocated to Google-managed services (Cloud SQL, etc.)."
}

variable "iap_source_ranges" {
  type        = list(string)
  default     = ["35.235.240.0/20"] # IAP TCP forwarders
  description = "Source ranges allowed for IAP-tunneled SSH/RDP."
}

variable "flow_logs_sampling" {
  type    = number
  default = 0.5
}
