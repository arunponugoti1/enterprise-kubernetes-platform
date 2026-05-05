variable "project_id" {
  description = "Project on which to enable the APIs."
  type        = string
}

variable "apis" {
  description = "List of Google API service names to enable (e.g. compute.googleapis.com)."
  type        = list(string)
}

variable "disable_on_destroy" {
  description = "Whether destroying this resource disables the API on the project. Leave false to avoid breaking other consumers."
  type        = bool
  default     = false
}

resource "google_project_service" "this" {
  for_each = toset(var.apis)

  project            = var.project_id
  service            = each.value
  disable_on_destroy = var.disable_on_destroy
}

output "enabled_apis" {
  value = [for s in google_project_service.this : s.service]
}
