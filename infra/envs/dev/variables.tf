variable "project_id" {
  description = "GCP project for this environment."
  type        = string
}

variable "region" {
  description = "Default region for regional resources."
  type        = string
  default     = "us-central1"
}

variable "env" {
  description = "Environment name (dev/uat/prod)."
  type        = string
}

variable "subnet_cidr" {
  type    = string
  default = "10.10.0.0/20"
}

variable "pods_cidr" {
  type    = string
  default = "10.20.0.0/14"
}

variable "services_cidr" {
  type    = string
  default = "10.24.0.0/20"
}

variable "master_ipv4_cidr_block" {
  type    = string
  default = "172.16.0.0/28"
}

variable "master_authorized_networks" {
  type = list(object({
    cidr_block   = string
    display_name = string
  }))
  default = []
}

variable "gke_deletion_protection" {
  type    = bool
  default = false # dev: easier teardown; UAT/prod default true.
}

variable "sql_deletion_protection" {
  type    = bool
  default = false
}

variable "alert_email" {
  type        = string
  description = "Email for Cloud Monitoring alert notifications."
}

variable "slack_channel_name" {
  type        = string
  default     = ""
  description = "Slack channel for alerts (e.g. #fintech-alerts). Leave empty to disable."
}

variable "slack_auth_token" {
  type        = string
  sensitive   = true
  default     = ""
  description = "Slack bot OAuth token. Required when slack_channel_name is set."
}

variable "gitops_repo_url" {
  type        = string
  description = "HTTPS or SSH URL of the GitOps manifests repository ArgoCD reconciles from."
}

variable "gitops_target_revision" {
  type        = string
  default     = "main"
  description = "Branch, tag, or commit ArgoCD tracks for the root Application."
}
