locals {
  required_apis = [
    "compute.googleapis.com",
    "container.googleapis.com",
    "servicenetworking.googleapis.com",
    "sqladmin.googleapis.com",
    "sql-component.googleapis.com",
    "artifactregistry.googleapis.com",
    "secretmanager.googleapis.com",
    "cloudkms.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "cloudtrace.googleapis.com",
    "pubsub.googleapis.com",
    "meshconfig.googleapis.com",
    "mesh.googleapis.com",
    "dns.googleapis.com",
    "binaryauthorization.googleapis.com",
    "containeranalysis.googleapis.com",
    "containerscanning.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "serviceusage.googleapis.com",
  ]

  name_prefix = "fintech-${var.env}"
}

module "apis" {
  source     = "../../modules/project-apis"
  project_id = var.project_id
  apis       = local.required_apis
}

module "kms" {
  source       = "../../modules/kms"
  project_id   = var.project_id
  location     = var.region
  keyring_name = "${local.name_prefix}-platform"

  keys = {
    gke               = {}
    sql               = {}
    artifact-registry = {}
  }

  depends_on = [module.apis]
}

module "vpc" {
  source     = "../../modules/vpc"
  project_id = var.project_id
  name       = "${local.name_prefix}-vpc"
  region     = var.region

  subnet_cidr   = var.subnet_cidr
  pods_cidr     = var.pods_cidr
  services_cidr = var.services_cidr

  depends_on = [module.apis]
}

module "artifact_registry" {
  source       = "../../modules/artifact-registry"
  project_id   = var.project_id
  location     = var.region
  kms_key_name = module.kms.key_ids["artifact-registry"]

  repositories = {
    docker = {
      format      = "DOCKER"
      description = "Application container images"
    }
    helm = {
      format      = "DOCKER" # OCI Helm charts live in a DOCKER-format repo on AR
      description = "OCI-packaged Helm charts"
    }
  }

  readers = [
    "serviceAccount:${module.gke.node_service_account_email}",
  ]

  depends_on = [module.apis]
}

module "gke" {
  source     = "../../modules/gke"
  project_id = var.project_id
  name       = "${local.name_prefix}-gke"
  region     = var.region

  network             = module.vpc.network_self_link
  subnetwork          = module.vpc.subnet_self_link
  pods_range_name     = module.vpc.pods_range_name
  services_range_name = module.vpc.services_range_name

  master_ipv4_cidr_block     = var.master_ipv4_cidr_block
  master_authorized_networks = var.master_authorized_networks

  database_encryption_key = module.kms.key_ids["gke"]
  deletion_protection     = var.gke_deletion_protection

  depends_on = [module.apis, module.vpc]
}

module "cloud_sql" {
  source     = "../../modules/cloud-sql"
  project_id = var.project_id
  name       = "${local.name_prefix}-pg"
  region     = var.region

  private_network = module.vpc.network_self_link
  psa_dependency  = module.vpc.psa_connection
  kms_key_name    = module.kms.key_ids["sql"]

  databases           = ["accounts", "transactions"]
  users               = ["app_account", "app_transaction"]
  deletion_protection = var.sql_deletion_protection

  depends_on = [module.apis, module.vpc]
}

# Stash generated DB passwords in Secret Manager so app workloads can pull them via WIF.
resource "google_secret_manager_secret" "db_user" {
  for_each = toset(["app_account", "app_transaction"])

  project   = var.project_id
  secret_id = "${local.name_prefix}-pg-${each.value}-password"

  replication {
    auto {}
  }

  depends_on = [module.apis]
}

resource "google_secret_manager_secret_version" "db_user" {
  for_each = toset(["app_account", "app_transaction"])

  secret      = google_secret_manager_secret.db_user[each.value].id
  secret_data = module.cloud_sql.user_passwords[each.value]
}
