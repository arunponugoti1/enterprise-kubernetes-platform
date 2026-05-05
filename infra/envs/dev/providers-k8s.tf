# Configure the Kubernetes + Helm providers against the GKE cluster created
# in this same root module. Reaching the cluster requires that the runner can
# hit the master endpoint — set master_authorized_networks on the GKE module
# so CI / your bastion is on the allow-list.

data "google_client_config" "default" {}

# Use the data source so we don't depend on the cluster module's outputs being
# computed at provider-config time, which would create a chicken-and-egg cycle.
data "google_container_cluster" "this" {
  project  = var.project_id
  name     = module.gke.cluster_name
  location = var.region

  depends_on = [module.gke]
}

provider "kubernetes" {
  host  = "https://${data.google_container_cluster.this.endpoint}"
  token = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(
    data.google_container_cluster.this.master_auth[0].cluster_ca_certificate
  )
}

provider "helm" {
  kubernetes {
    host  = "https://${data.google_container_cluster.this.endpoint}"
    token = data.google_client_config.default.access_token
    cluster_ca_certificate = base64decode(
      data.google_container_cluster.this.master_auth[0].cluster_ca_certificate
    )
  }
}
