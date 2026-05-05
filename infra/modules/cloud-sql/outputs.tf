output "instance_name" {
  value = google_sql_database_instance.this.name
}

output "connection_name" {
  description = "Use as the -instances arg for the Cloud SQL Auth Proxy sidecar."
  value       = google_sql_database_instance.this.connection_name
}

output "private_ip_address" {
  value = google_sql_database_instance.this.private_ip_address
}

output "user_passwords" {
  description = "Map of username => generated password. Pipe these into Secret Manager from the caller."
  value       = { for u, r in random_password.users : u => r.result }
  sensitive   = true
}
