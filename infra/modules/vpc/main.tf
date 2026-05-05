resource "google_compute_network" "this" {
  project                         = var.project_id
  name                            = var.name
  auto_create_subnetworks         = false
  routing_mode                    = "REGIONAL"
  delete_default_routes_on_create = false
}

resource "google_compute_subnetwork" "nodes" {
  project                  = var.project_id
  name                     = "${var.name}-nodes-${var.region}"
  region                   = var.region
  network                  = google_compute_network.this.id
  ip_cidr_range            = var.subnet_cidr
  private_ip_google_access = true

  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = var.pods_cidr
  }

  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = var.services_cidr
  }

  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = var.flow_logs_sampling
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

# Cloud NAT so private nodes can pull images / reach external APIs without public IPs.
resource "google_compute_router" "nat" {
  project = var.project_id
  name    = "${var.name}-rtr"
  region  = var.region
  network = google_compute_network.this.id
}

resource "google_compute_router_nat" "nat" {
  project                            = var.project_id
  name                               = "${var.name}-nat"
  router                             = google_compute_router.nat.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# Private services access for Google-managed services (Cloud SQL private IP, etc.)
resource "google_compute_global_address" "psa" {
  project       = var.project_id
  name          = "${var.name}-psa"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = var.psa_range_prefix_length
  network       = google_compute_network.this.id
}

resource "google_service_networking_connection" "psa" {
  network                 = google_compute_network.this.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.psa.name]
}

# Firewall: allow IAP-tunneled SSH only (no public 0.0.0.0/0 ingress).
resource "google_compute_firewall" "iap_ssh" {
  project   = var.project_id
  name      = "${var.name}-allow-iap-ssh"
  network   = google_compute_network.this.name
  direction = "INGRESS"
  priority  = 1000

  source_ranges = var.iap_source_ranges

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}

# Allow internal traffic within the subnet + secondary ranges (pods/services).
resource "google_compute_firewall" "internal" {
  project   = var.project_id
  name      = "${var.name}-allow-internal"
  network   = google_compute_network.this.name
  direction = "INGRESS"
  priority  = 1100

  source_ranges = [
    var.subnet_cidr,
    var.pods_cidr,
    var.services_cidr,
  ]

  allow { protocol = "tcp" }
  allow { protocol = "udp" }
  allow { protocol = "icmp" }
}

# Explicitly deny SSH from the internet (defense in depth — implicit deny exists,
# but an explicit rule is auditable and survives policy drift).
resource "google_compute_firewall" "deny_public_ssh" {
  project   = var.project_id
  name      = "${var.name}-deny-public-ssh"
  network   = google_compute_network.this.name
  direction = "INGRESS"
  priority  = 65000

  source_ranges = ["0.0.0.0/0"]

  deny {
    protocol = "tcp"
    ports    = ["22", "3389"]
  }
}
