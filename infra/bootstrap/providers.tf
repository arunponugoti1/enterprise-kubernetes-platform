provider "google" {
  project = var.bootstrap_project_id
  region  = var.region
}

provider "google-beta" {
  project = var.bootstrap_project_id
  region  = var.region
}
