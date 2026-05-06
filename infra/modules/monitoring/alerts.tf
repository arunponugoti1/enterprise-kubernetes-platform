resource "google_monitoring_alert_policy" "pod_crash_looping" {
  project      = var.project_id
  display_name = "[${var.env}] Pod CrashLoopBackOff"
  combiner     = "OR"

  conditions {
    display_name = "Container restart count high"
    condition_threshold {
      filter          = "resource.type=\"k8s_container\" AND resource.labels.cluster_name=\"${var.cluster_name}\" AND metric.type=\"kubernetes.io/container/restart_count\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 5

      aggregations {
        alignment_period     = "300s"
        per_series_aligner   = "ALIGN_RATE"
        cross_series_reducer = "REDUCE_SUM"
        group_by_fields      = ["resource.labels.namespace_name", "resource.labels.pod_name", "resource.labels.container_name"]
      }
    }
  }

  notification_channels = local.notification_channels
  severity              = "CRITICAL"

  alert_strategy {
    auto_close = "1800s"
  }

  documentation {
    content   = "Pod is crash-looping. Check logs: kubectl logs -n $NAMESPACE $POD --previous"
    mime_type = "text/markdown"
  }
}

resource "google_monitoring_alert_policy" "high_5xx_rate" {
  project      = var.project_id
  display_name = "[${var.env}] High 5xx Error Rate (Istio)"
  combiner     = "OR"

  conditions {
    display_name = "5xx response rate > 5%"
    condition_threshold {
      filter = join(" AND ", [
        "resource.type=\"k8s_container\"",
        "resource.labels.cluster_name=\"${var.cluster_name}\"",
        "metric.type=\"istio.io/service/server/response_count\"",
        "metric.labels.response_code>=\"500\"",
      ])
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0.05

      aggregations {
        alignment_period     = "60s"
        per_series_aligner   = "ALIGN_RATE"
        cross_series_reducer = "REDUCE_FRACTION_TRUE"
        group_by_fields      = ["resource.labels.namespace_name", "destination_service_name"]
      }
    }
  }

  notification_channels = local.notification_channels
  severity              = "ERROR"

  alert_strategy {
    auto_close = "1800s"
  }

  documentation {
    content   = "Service is returning 5xx errors above 5% threshold. Check application logs and traces."
    mime_type = "text/markdown"
  }
}

resource "google_monitoring_alert_policy" "high_latency" {
  project      = var.project_id
  display_name = "[${var.env}] High p99 Latency (Istio)"
  combiner     = "OR"

  conditions {
    display_name = "p99 latency > 2000ms"
    condition_threshold {
      filter = join(" AND ", [
        "resource.type=\"k8s_container\"",
        "resource.labels.cluster_name=\"${var.cluster_name}\"",
        "metric.type=\"istio.io/service/server/response_latencies\"",
      ])
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 2000

      aggregations {
        alignment_period     = "60s"
        per_series_aligner   = "ALIGN_PERCENTILE_99"
        cross_series_reducer = "REDUCE_MEAN"
        group_by_fields      = ["resource.labels.namespace_name", "destination_service_name"]
      }
    }
  }

  notification_channels = local.notification_channels
  severity              = "WARNING"

  alert_strategy {
    auto_close = "3600s"
  }

  documentation {
    content   = "p99 response latency exceeds 2 seconds. Investigate slow queries, resource pressure, or dependency issues."
    mime_type = "text/markdown"
  }
}

resource "google_monitoring_alert_policy" "cloudsql_disk_usage" {
  project      = var.project_id
  display_name = "[${var.env}] Cloud SQL Disk Usage High"
  combiner     = "OR"

  conditions {
    display_name = "Disk utilisation > 80%"
    condition_threshold {
      filter          = "resource.type=\"cloudsql_database\" AND metric.type=\"cloudsql.googleapis.com/database/disk/utilization\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0.8

      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = local.notification_channels
  severity              = "WARNING"

  alert_strategy {
    auto_close = "86400s"
  }

  documentation {
    content   = "Cloud SQL disk utilization exceeds 80%. Consider increasing disk size or archiving old data."
    mime_type = "text/markdown"
  }
}

resource "google_monitoring_alert_policy" "pubsub_backlog" {
  project      = var.project_id
  display_name = "[${var.env}] Pub/Sub Subscription Backlog High"
  combiner     = "OR"

  conditions {
    display_name = "Undelivered messages > 1000"
    condition_threshold {
      filter          = "resource.type=\"pubsub_subscription\" AND metric.type=\"pubsub.googleapis.com/subscription/num_undelivered_messages\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 1000

      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_MEAN"
        group_by_fields    = ["resource.labels.subscription_id"]
      }
    }
  }

  notification_channels = local.notification_channels
  severity              = "WARNING"

  alert_strategy {
    auto_close = "3600s"
  }

  documentation {
    content   = "Pub/Sub subscription backlog exceeds 1000 messages. Notification service may be down or processing slowly."
    mime_type = "text/markdown"
  }
}

resource "google_monitoring_alert_policy" "cloudsql_memory" {
  project      = var.project_id
  display_name = "[${var.env}] Cloud SQL Memory Usage High"
  combiner     = "OR"

  conditions {
    display_name = "Memory utilisation > 90%"
    condition_threshold {
      filter          = "resource.type=\"cloudsql_database\" AND metric.type=\"cloudsql.googleapis.com/database/memory/utilization\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0.9

      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = local.notification_channels
  severity              = "ERROR"

  alert_strategy {
    auto_close = "3600s"
  }

  documentation {
    content   = "Cloud SQL memory utilization exceeds 90%. Risk of OOM-induced failover."
    mime_type = "text/markdown"
  }
}

resource "google_monitoring_alert_policy" "node_cpu" {
  project      = var.project_id
  display_name = "[${var.env}] GKE Node CPU Saturation"
  combiner     = "OR"

  conditions {
    display_name = "Node CPU > 85% for 10 min"
    condition_threshold {
      filter          = "resource.type=\"k8s_node\" AND resource.labels.cluster_name=\"${var.cluster_name}\" AND metric.type=\"kubernetes.io/node/cpu/allocatable_utilization\""
      duration        = "600s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0.85

      aggregations {
        alignment_period     = "120s"
        per_series_aligner   = "ALIGN_MEAN"
        cross_series_reducer = "REDUCE_MEAN"
        group_by_fields      = ["resource.labels.node_name"]
      }
    }
  }

  notification_channels = local.notification_channels
  severity              = "WARNING"

  alert_strategy {
    auto_close = "7200s"
  }

  documentation {
    content   = "GKE node CPU allocatable utilization is above 85%. Cluster autoscaler should be scaling out."
    mime_type = "text/markdown"
  }
}
