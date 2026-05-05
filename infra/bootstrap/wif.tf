resource "google_service_account" "ci_terraform" {
  project      = var.bootstrap_project_id
  account_id   = "ci-terraform"
  display_name = "CI Terraform runner (impersonated via WIF from GitHub Actions)"

  depends_on = [google_project_service.bootstrap]
}

resource "google_iam_workload_identity_pool" "github" {
  project                   = var.bootstrap_project_id
  workload_identity_pool_id = "github-pool"
  display_name              = "GitHub Actions"
  description               = "WIF pool for GitHub Actions OIDC"

  depends_on = [google_project_service.bootstrap]
}

resource "google_iam_workload_identity_pool_provider" "github" {
  project                            = var.bootstrap_project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-provider"
  display_name                       = "GitHub OIDC"

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.repository" = "assertion.repository"
    "attribute.ref"        = "assertion.ref"
    "attribute.actor"      = "assertion.actor"
  }

  # Only allow tokens from the configured GitHub org's listed repos.
  attribute_condition = "assertion.repository_owner == \"${var.github_org}\""

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

resource "google_service_account_iam_member" "ci_wif_impersonation" {
  for_each = toset(var.github_repos)

  service_account_id = google_service_account.ci_terraform.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.repository/${var.github_org}/${each.value}"
}

# Grant the CI SA the roles it needs on each managed project. Scope is intentionally
# broad here for bootstrap; tighten per-project once env-specific roles stabilize.
locals {
  ci_project_roles = [
    "roles/owner",
    "roles/serviceusage.serviceUsageAdmin",
  ]

  ci_project_role_bindings = {
    for pair in setproduct(var.managed_project_ids, local.ci_project_roles) :
    "${pair[0]}|${pair[1]}" => { project = pair[0], role = pair[1] }
  }
}

resource "google_project_iam_member" "ci_managed_projects" {
  for_each = local.ci_project_role_bindings

  project = each.value.project
  role    = each.value.role
  member  = "serviceAccount:${google_service_account.ci_terraform.email}"
}

# CI SA also needs to read/write Terraform state.
resource "google_storage_bucket_iam_member" "ci_state_admin" {
  bucket = google_storage_bucket.tfstate.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.ci_terraform.email}"
}
