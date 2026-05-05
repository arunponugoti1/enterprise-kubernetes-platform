output "cluster_name" {
  value = google_container_cluster.this.name
}

output "cluster_id" {
  value = google_container_cluster.this.id
}

output "endpoint" {
  value     = google_container_cluster.this.endpoint
  sensitive = true
}

output "ca_certificate" {
  value     = google_container_cluster.this.master_auth[0].cluster_ca_certificate
  sensitive = true
}

output "node_service_account_email" {
  value = google_service_account.nodes.email
}

output "workload_identity_pool" {
  value = "${var.project_id}.svc.id.goog"
}
