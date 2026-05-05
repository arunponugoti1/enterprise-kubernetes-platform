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
