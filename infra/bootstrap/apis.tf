locals {
  bootstrap_apis = [
    "cloudresourcemanager.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "serviceusage.googleapis.com",
    "storage.googleapis.com",
    "cloudkms.googleapis.com",
    "sts.googleapis.com",
    "artifactregistry.googleapis.com",
    "secretmanager.googleapis.com",
    "cloudbilling.googleapis.com",
  ]
}

resource "google_project_service" "bootstrap" {
  for_each           = toset(local.bootstrap_apis)
  project            = var.bootstrap_project_id
  service            = each.value
  disable_on_destroy = false
}
