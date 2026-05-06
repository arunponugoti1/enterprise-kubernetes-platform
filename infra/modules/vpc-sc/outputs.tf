output "policy_name" {
  description = "Resource name of the Access Context Manager access policy."
  value       = local.policy_name
}

output "perimeter_name" {
  description = "Resource name of the service perimeter."
  value       = google_access_context_manager_service_perimeter.fintech.name
}
