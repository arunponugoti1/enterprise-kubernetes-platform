data "google_project" "this" {
  project_id = var.project_id
}

# Allow the GKE service agent to use the CMEK key for etcd application-layer encryption.
resource "google_kms_crypto_key_iam_member" "gke_etcd" {
  crypto_key_id = var.database_encryption_key
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:service-${data.google_project.this.number}@container-engine-robot.iam.gserviceaccount.com"
}

# Dedicated, least-privilege node service account.
resource "google_service_account" "nodes" {
  project      = var.project_id
  account_id   = "${var.name}-nodes"
  display_name = "GKE node SA for ${var.name}"
}

locals {
  node_sa_roles = [
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
    "roles/stackdriver.resourceMetadata.writer",
    "roles/artifactregistry.reader",
  ]
}

resource "google_project_iam_member" "nodes" {
  for_each = toset(local.node_sa_roles)
  project  = var.project_id
  role     = each.value
  member   = "serviceAccount:${google_service_account.nodes.email}"
}

resource "google_container_cluster" "this" {
  provider = google-beta

  project                  = var.project_id
  name                     = var.name
  location                 = var.region
  network                  = var.network
  subnetwork               = var.subnetwork
  remove_default_node_pool = true
  initial_node_count       = 1
  deletion_protection      = var.deletion_protection
  datapath_provider        = "ADVANCED_DATAPATH" # Cilium / Dataplane V2 — built-in NetworkPolicy.
  networking_mode          = "VPC_NATIVE"
  enable_shielded_nodes    = true

  release_channel {
    channel = var.release_channel
  }

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  ip_allocation_policy {
    cluster_secondary_range_name  = var.pods_range_name
    services_secondary_range_name = var.services_range_name
  }

  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = var.master_ipv4_cidr_block

    master_global_access_config {
      enabled = true
    }
  }

  master_authorized_networks_config {
    gcp_public_cidrs_access_enabled = false
    dynamic "cidr_blocks" {
      for_each = var.master_authorized_networks
      content {
        cidr_block   = cidr_blocks.value.cidr_block
        display_name = cidr_blocks.value.display_name
      }
    }
  }

  database_encryption {
    state    = "ENCRYPTED"
    key_name = var.database_encryption_key
  }

  binary_authorization {
    evaluation_mode = "PROJECT_SINGLETON_POLICY_ENFORCE"
  }

  logging_config {
    enable_components = [
      "SYSTEM_COMPONENTS",
      "WORKLOADS",
      "API_SERVER",
      "CONTROLLER_MANAGER",
      "SCHEDULER",
    ]
  }

  monitoring_config {
    enable_components = [
      "SYSTEM_COMPONENTS",
      "API_SERVER",
      "CONTROLLER_MANAGER",
      "SCHEDULER",
      "STORAGE",
      "HPA",
      "POD",
      "DAEMONSET",
      "DEPLOYMENT",
      "STATEFULSET",
    ]
    managed_prometheus {
      enabled = true
    }
  }

  addons_config {
    http_load_balancing {
      disabled = false
    }
    horizontal_pod_autoscaling {
      disabled = false
    }
    network_policy_config {
      # Disabled because Dataplane V2 supplies NetworkPolicy natively.
      disabled = true
    }
    gcp_filestore_csi_driver_config {
      enabled = true
    }
    gce_persistent_disk_csi_driver_config {
      enabled = true
    }
    gcs_fuse_csi_driver_config {
      enabled = true
    }
    dns_cache_config {
      enabled = true
    }
  }

  # ASM (managed) — enabled here so Phase 3 can configure it without a cluster recreation.
  mesh_certificates {
    enable_certificates = true
  }

  cost_management_config {
    enabled = true
  }

  maintenance_policy {
    recurring_window {
      start_time = var.maintenance_start_time
      end_time   = timeadd(var.maintenance_start_time, "4h")
      recurrence = "FREQ=WEEKLY;BYDAY=SA,SU"
    }
  }

  # Force resource consumers to wait until KMS binding exists.
  depends_on = [google_kms_crypto_key_iam_member.gke_etcd]

  lifecycle {
    ignore_changes = [
      # Node count drift from autoscaling on the (removed) default pool.
      initial_node_count,
    ]
  }
}

resource "google_container_node_pool" "primary" {
  provider = google-beta

  project    = var.project_id
  name       = "${var.name}-primary"
  cluster    = google_container_cluster.this.name
  location   = var.region
  node_count = null

  autoscaling {
    min_node_count = var.node_pool.min_node_count
    max_node_count = var.node_pool.max_node_count
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  upgrade_settings {
    strategy        = "SURGE"
    max_surge       = var.node_pool.max_surge
    max_unavailable = var.node_pool.max_unavailable
  }

  node_config {
    machine_type    = var.node_pool.machine_type
    disk_size_gb    = var.node_pool.disk_size_gb
    disk_type       = var.node_pool.disk_type
    image_type      = var.node_pool.image_type
    spot            = var.node_pool.spot
    service_account = google_service_account.nodes.email
    oauth_scopes    = ["https://www.googleapis.com/auth/cloud-platform"]

    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }

    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    metadata = {
      disable-legacy-endpoints = "true"
    }

    labels = {
      env = var.name
    }
  }

  lifecycle {
    ignore_changes = [node_config[0].labels]
  }
}
