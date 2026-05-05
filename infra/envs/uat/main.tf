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
}

module "apis" {
  source     = "../../modules/project-apis"
  project_id = var.project_id
  apis       = local.required_apis
}

# Subsequent phases will add: vpc, gke, cloud_sql, artifact_registry, etc.
# Each will declare `depends_on = [module.apis]`.
