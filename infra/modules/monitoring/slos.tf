locals {
  slo_services = {
    account-service     = { namespace = "account-service",     port = 8080 }
    transaction-service = { namespace = "transaction-service", port = 8080 }
    notification-service = { namespace = "notification-service", port = 8080 }
    api-gateway         = { namespace = "api-gateway",         port = 3000 }
  }
}

# Custom services backed by Istio request metrics
resource "google_monitoring_custom_service" "services" {
  for_each = local.slo_services

  project      = var.project_id
  service_id   = "${var.env}-${each.key}"
  display_name = "[${var.env}] ${each.key}"

  telemetry {
    resource_name = "//container.googleapis.com/projects/${var.project_id}/locations/${var.region}/clusters/${var.cluster_name}/k8s/namespaces/${each.value.namespace}"
  }
}

# Availability SLO — 99.9% good requests (non-5xx / total)
resource "google_monitoring_slo" "availability" {
  for_each = local.slo_services

  project      = var.project_id
  service      = google_monitoring_custom_service.services[each.key].service_id
  slo_id       = "${var.env}-${each.key}-availability"
  display_name = "[${var.env}] ${each.key} Availability"
  goal                = var.availability_slo_goal
  rolling_period_days = 28

  request_based_sli {
    good_total_ratio {
      good_service_filter = join(" AND ", [
        "resource.type=\"k8s_container\"",
        "resource.labels.cluster_name=\"${var.cluster_name}\"",
        "metric.type=\"istio.io/service/server/response_count\"",
        "resource.labels.namespace_name=\"${each.value.namespace}\"",
        "metric.labels.response_code<\"500\"",
      ])
      total_service_filter = join(" AND ", [
        "resource.type=\"k8s_container\"",
        "resource.labels.cluster_name=\"${var.cluster_name}\"",
        "metric.type=\"istio.io/service/server/response_count\"",
        "resource.labels.namespace_name=\"${each.value.namespace}\"",
      ])
    }
  }
}

# Latency SLO — 95% of requests served under 500ms
resource "google_monitoring_slo" "latency" {
  for_each = local.slo_services

  project      = var.project_id
  service      = google_monitoring_custom_service.services[each.key].service_id
  slo_id       = "${var.env}-${each.key}-latency"
  display_name = "[${var.env}] ${each.key} Latency p95 < 500ms"
  goal                = var.latency_slo_goal
  rolling_period_days = 28

  request_based_sli {
    distribution_cut {
      distribution_filter = join(" AND ", [
        "resource.type=\"k8s_container\"",
        "resource.labels.cluster_name=\"${var.cluster_name}\"",
        "metric.type=\"istio.io/service/server/response_latencies\"",
        "resource.labels.namespace_name=\"${each.value.namespace}\"",
      ])
      range {
        max = 500
      }
    }
  }
}

# Burn rate alerts for availability SLOs (fast burn 2% budget in 1hr, slow burn 5% in 6hr)
resource "google_monitoring_alert_policy" "slo_burn_rate_fast" {
  for_each = local.slo_services

  project      = var.project_id
  display_name = "[${var.env}] ${each.key} SLO Fast Burn"
  combiner     = "OR"

  conditions {
    display_name = "Fast burn: 2% budget consumed in 1h"
    condition_threshold {
      filter = join(" AND ", [
        "select_slo_burn_rate(\"projects/${var.project_id}/services/${google_monitoring_custom_service.services[each.key].service_id}/serviceLevelObjectives/${google_monitoring_slo.availability[each.key].slo_id}\", 60m)",
      ])
      duration        = "0s"
      comparison      = "COMPARISON_GT"
      threshold_value = 14.4

      trigger {
        count = 1
      }
    }
  }

  notification_channels = local.notification_channels
  severity              = "CRITICAL"

  alert_strategy {
    auto_close = "1800s"
  }

  documentation {
    content   = "${each.key} is burning through its error budget 14x faster than normal. Immediate action required."
    mime_type = "text/markdown"
  }
}

resource "google_monitoring_alert_policy" "slo_burn_rate_slow" {
  for_each = local.slo_services

  project      = var.project_id
  display_name = "[${var.env}] ${each.key} SLO Slow Burn"
  combiner     = "OR"

  conditions {
    display_name = "Slow burn: 5% budget consumed in 6h"
    condition_threshold {
      filter = join(" AND ", [
        "select_slo_burn_rate(\"projects/${var.project_id}/services/${google_monitoring_custom_service.services[each.key].service_id}/serviceLevelObjectives/${google_monitoring_slo.availability[each.key].slo_id}\", 360m)",
      ])
      duration        = "0s"
      comparison      = "COMPARISON_GT"
      threshold_value = 6

      trigger {
        count = 1
      }
    }
  }

  notification_channels = local.notification_channels
  severity              = "WARNING"

  alert_strategy {
    auto_close = "7200s"
  }

  documentation {
    content   = "${each.key} is steadily burning its error budget at 6x normal rate over 6 hours."
    mime_type = "text/markdown"
  }
}
