resource "google_monitoring_notification_channel" "email" {
  project      = var.project_id
  display_name = "[${var.env}] Email alerts"
  type         = "email"

  labels = {
    email_address = var.alert_email
  }
}

resource "google_monitoring_notification_channel" "slack" {
  count = var.slack_channel_name != "" ? 1 : 0

  project      = var.project_id
  display_name = "[${var.env}] Slack alerts"
  type         = "slack"

  labels = {
    channel_name = var.slack_channel_name
  }

  sensitive_labels {
    auth_token = var.slack_auth_token
  }
}

locals {
  notification_channels = compact([
    google_monitoring_notification_channel.email.id,
    length(google_monitoring_notification_channel.slack) > 0 ? google_monitoring_notification_channel.slack[0].id : "",
  ])
}

output "notification_channel_ids" {
  value = local.notification_channels
}
