variable "project_id" {
  type = string
}

variable "cluster_id" {
  type        = string
  description = "Fully-qualified GKE cluster resource id (e.g. //container.googleapis.com/projects/.../clusters/...)."
}

variable "cluster_location" {
  type        = string
  description = "Region of the GKE cluster (used for the Hub membership location)."
}

variable "membership_id" {
  type        = string
  description = "Stable Hub membership ID (typically the cluster name)."
}

variable "channel" {
  type    = string
  default = "regular"
  validation {
    condition     = contains(["rapid", "regular", "stable"], var.channel)
    error_message = "channel must be rapid, regular, or stable."
  }
}

# Enable the Fleet (GKE Hub) servicemesh feature once per project.
resource "google_gke_hub_feature" "servicemesh" {
  provider = google-beta
  project  = var.project_id
  name     = "servicemesh"
  location = "global"
}

# Register the cluster with the Fleet.
resource "google_gke_hub_membership" "cluster" {
  provider      = google-beta
  project       = var.project_id
  membership_id = var.membership_id
  location      = var.cluster_location

  endpoint {
    gke_cluster {
      resource_link = var.cluster_id
    }
  }
}

# Opt the membership into the managed ASM control plane + data plane.
resource "google_gke_hub_feature_membership" "asm" {
  provider   = google-beta
  project    = var.project_id
  location   = "global"
  feature    = google_gke_hub_feature.servicemesh.name
  membership = google_gke_hub_membership.cluster.membership_id

  mesh {
    management = "MANAGEMENT_AUTOMATIC"
    control_plane = "AUTOMATIC"
  }
}

output "membership_id" {
  value = google_gke_hub_membership.cluster.membership_id
}

output "control_plane_revision_label" {
  description = "Sidecar injection label value for the managed ASM channel. Apply as istio.io/rev=<value> on namespaces/pods. Channel mapping: regular=asm-managed, rapid=asm-managed-rapid, stable=asm-managed-stable."
  value = lookup(
    {
      "regular" = "asm-managed",
      "rapid"   = "asm-managed-rapid",
      "stable"  = "asm-managed-stable",
    },
    var.channel,
    "asm-managed",
  )
}
