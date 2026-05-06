# ─── Access Policy (org-scoped, one per org) ───────────────────────────────────
# If policy_id is provided, use the existing policy; otherwise create one.
resource "google_access_context_manager_access_policy" "this" {
  count = var.policy_id == "" ? 1 : 0

  parent = "organizations/${var.org_id}"
  title  = "fintech-access-policy"

  lifecycle {
    prevent_destroy = true
  }
}

locals {
  policy_name = var.policy_id != "" ? "accessPolicies/${var.policy_id}" : google_access_context_manager_access_policy.this[0].name
}

# ─── Access Level — corporate identities / IPs ────────────────────────────────
resource "google_access_context_manager_access_level" "corp" {
  count = length(var.authorized_ip_ranges) > 0 || length(var.authorized_members) > 0 ? 1 : 0

  parent = local.policy_name
  name   = "${local.policy_name}/accessLevels/fintech-corp-${var.env}"
  title  = "[${var.env}] Fintech corporate access"

  basic {
    combining_function = "OR"

    dynamic "conditions" {
      for_each = length(var.authorized_ip_ranges) > 0 ? [1] : []
      content {
        ip_subnetworks = var.authorized_ip_ranges
      }
    }

    dynamic "conditions" {
      for_each = length(var.authorized_members) > 0 ? [1] : []
      content {
        members = var.authorized_members
      }
    }
  }
}

# ─── Service Perimeter ────────────────────────────────────────────────────────
resource "google_access_context_manager_service_perimeter" "fintech" {
  parent = local.policy_name
  name   = "${local.policy_name}/servicePerimeters/fintech_${var.env}"
  title  = "[${var.env}] Fintech perimeter"

  # Use spec for DRY_RUN, status for ENFORCE
  use_explicit_dry_run_spec = var.perimeter_mode == "DRY_RUN"

  dynamic "spec" {
    for_each = var.perimeter_mode == "DRY_RUN" ? [1] : []
    content {
      resources            = [for n in var.protected_project_numbers : "projects/${n}"]
      restricted_services  = var.restricted_services
      access_levels        = length(var.authorized_ip_ranges) > 0 || length(var.authorized_members) > 0 ? [google_access_context_manager_access_level.corp[0].name] : []

      vpc_accessible_services {
        enable_restriction = true
        allowed_services   = var.restricted_services
      }
    }
  }

  dynamic "status" {
    for_each = var.perimeter_mode == "ENFORCE" ? [1] : []
    content {
      resources            = [for n in var.protected_project_numbers : "projects/${n}"]
      restricted_services  = var.restricted_services
      access_levels        = length(var.authorized_ip_ranges) > 0 || length(var.authorized_members) > 0 ? [google_access_context_manager_access_level.corp[0].name] : []

      vpc_accessible_services {
        enable_restriction = true
        allowed_services   = var.restricted_services
      }
    }
  }
}
