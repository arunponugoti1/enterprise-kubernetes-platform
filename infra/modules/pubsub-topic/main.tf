variable "project_id" {
  type = string
}

variable "name" {
  type = string
}

variable "kms_key_name" {
  type        = string
  description = "Fully-qualified KMS key ID for topic CMEK."
}

variable "message_retention_duration" {
  type    = string
  default = "604800s" # 7 days
}

variable "subscriptions" {
  description = "Map of subscription name => settings."
  type = map(object({
    ack_deadline_seconds         = optional(number, 30)
    message_retention_duration   = optional(string, "604800s")
    enable_exactly_once_delivery = optional(bool, true)
    retain_acked_messages        = optional(bool, false)
    dead_letter_max_attempts     = optional(number, 5)
  }))
  default = {}
}

variable "publishers" {
  description = "Members granted roles/pubsub.publisher on the topic."
  type        = list(string)
  default     = []
}

variable "subscribers" {
  description = "Map of subscription name => list of members granted roles/pubsub.subscriber."
  type        = map(list(string))
  default     = {}
}

data "google_project" "this" {
  project_id = var.project_id
}

# Pub/Sub service agent must use the CMEK key.
resource "google_kms_crypto_key_iam_member" "pubsub" {
  crypto_key_id = var.kms_key_name
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:service-${data.google_project.this.number}@gcp-sa-pubsub.iam.gserviceaccount.com"
}

resource "google_pubsub_topic" "this" {
  project                    = var.project_id
  name                       = var.name
  kms_key_name               = var.kms_key_name
  message_retention_duration = var.message_retention_duration

  depends_on = [google_kms_crypto_key_iam_member.pubsub]
}

# Dead-letter topic shared by all subscriptions.
resource "google_pubsub_topic" "dlq" {
  project                    = var.project_id
  name                       = "${var.name}-dlq"
  kms_key_name               = var.kms_key_name
  message_retention_duration = "1209600s" # 14 days

  depends_on = [google_kms_crypto_key_iam_member.pubsub]
}

resource "google_pubsub_subscription" "this" {
  for_each = var.subscriptions

  project = var.project_id
  name    = each.key
  topic   = google_pubsub_topic.this.id

  ack_deadline_seconds         = each.value.ack_deadline_seconds
  message_retention_duration   = each.value.message_retention_duration
  enable_exactly_once_delivery = each.value.enable_exactly_once_delivery
  retain_acked_messages        = each.value.retain_acked_messages

  expiration_policy {
    ttl = "" # never expire
  }

  retry_policy {
    minimum_backoff = "10s"
    maximum_backoff = "600s"
  }

  dead_letter_policy {
    dead_letter_topic     = google_pubsub_topic.dlq.id
    max_delivery_attempts = each.value.dead_letter_max_attempts
  }
}

# Pub/Sub service agent needs publish permission on the DLQ to forward failed messages.
resource "google_pubsub_topic_iam_member" "dlq_publisher" {
  project = var.project_id
  topic   = google_pubsub_topic.dlq.name
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:service-${data.google_project.this.number}@gcp-sa-pubsub.iam.gserviceaccount.com"
}

resource "google_pubsub_topic_iam_member" "publishers" {
  for_each = toset(var.publishers)

  project = var.project_id
  topic   = google_pubsub_topic.this.name
  role    = "roles/pubsub.publisher"
  member  = each.value
}

locals {
  subscriber_bindings = merge([
    for sub_name, members in var.subscribers : {
      for m in members :
      "${sub_name}|${m}" => { sub = sub_name, member = m }
    }
  ]...)
}

resource "google_pubsub_subscription_iam_member" "subscribers" {
  for_each = local.subscriber_bindings

  project      = var.project_id
  subscription = google_pubsub_subscription.this[each.value.sub].name
  role         = "roles/pubsub.subscriber"
  member       = each.value.member
}

output "topic_id" {
  value = google_pubsub_topic.this.id
}

output "topic_name" {
  value = google_pubsub_topic.this.name
}

output "dlq_topic_id" {
  value = google_pubsub_topic.dlq.id
}

output "subscription_ids" {
  value = { for k, s in google_pubsub_subscription.this : k => s.id }
}
