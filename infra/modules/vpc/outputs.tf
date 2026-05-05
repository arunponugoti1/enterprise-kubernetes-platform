output "network_id" {
  value = google_compute_network.this.id
}

output "network_name" {
  value = google_compute_network.this.name
}

output "network_self_link" {
  value = google_compute_network.this.self_link
}

output "subnet_id" {
  value = google_compute_subnetwork.nodes.id
}

output "subnet_name" {
  value = google_compute_subnetwork.nodes.name
}

output "subnet_self_link" {
  value = google_compute_subnetwork.nodes.self_link
}

output "pods_range_name" {
  value = "pods"
}

output "services_range_name" {
  value = "services"
}

output "psa_connection" {
  description = "The service networking connection — depend on this from Cloud SQL."
  value       = google_service_networking_connection.psa.id
}
