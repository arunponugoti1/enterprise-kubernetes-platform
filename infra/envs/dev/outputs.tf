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

output "workload_identity_sa_emails" {
  description = "GSA emails per service. Annotate the matching KSA with iam.gke.io/gcp-service-account=<email>."
  value = {
    "account-service"      = module.wi_account_service.email
    "transaction-service"  = module.wi_transaction_service.email
    "notification-service" = module.wi_notification_service.email
  }
}

output "pubsub_transactions_topic" {
  value = module.pubsub_transactions.topic_id
}

output "pubsub_transactions_subscription" {
  value = module.pubsub_transactions.subscription_ids
}
