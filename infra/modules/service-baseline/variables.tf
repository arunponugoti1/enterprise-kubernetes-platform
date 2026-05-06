variable "project_id" {
  type = string
}

variable "env" {
  type = string
}

variable "service_name" {
  type        = string
  description = "Kebab-case service name (e.g. order-service). Drives GSA id, namespace, and KSA name."
}

variable "asm_revision_label" {
  type        = string
  description = "Istio revision label for namespace injection (from module.asm.control_plane_revision_label)."
}

variable "project_roles" {
  type        = list(string)
  default     = []
  description = "GCP project-level IAM roles granted to the service's GSA (e.g. roles/cloudsql.client)."
}

variable "secret_accessor_secret_ids" {
  type        = list(string)
  default     = []
  description = "Short Secret Manager secret IDs the GSA gets roles/secretmanager.secretAccessor on."
}

variable "pubsub_publisher_topic_ids" {
  type        = list(string)
  default     = []
  description = "Pub/Sub topic IDs the GSA is granted roles/pubsub.publisher on."
}

variable "pubsub_subscriber_subscription_ids" {
  type        = list(string)
  default     = []
  description = "Pub/Sub subscription IDs the GSA is granted roles/pubsub.subscriber on."
}

variable "extra_namespace_labels" {
  type        = map(string)
  default     = {}
  description = "Additional labels to merge onto the Kubernetes namespace."
}
