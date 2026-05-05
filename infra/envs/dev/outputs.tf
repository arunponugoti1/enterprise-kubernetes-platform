output "vpc_name" {
  value = module.vpc.network_name
}

output "gke_cluster_name" {
  value = module.gke.cluster_name
}

output "gke_node_sa" {
  value = module.gke.node_service_account_email
}

output "workload_identity_pool" {
  value = module.gke.workload_identity_pool
}

output "sql_connection_name" {
  value = module.cloud_sql.connection_name
}

output "sql_private_ip" {
  value = module.cloud_sql.private_ip_address
}

output "artifact_registry_urls" {
  value = module.artifact_registry.repository_urls
}
