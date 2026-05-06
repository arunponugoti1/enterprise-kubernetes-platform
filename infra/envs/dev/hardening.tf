# ─── Phase 9: Hardening ────────────────────────────────────────────────────────

# ── Binary Authorization ──────────────────────────────────────────────────────
# Requires attestation from the qa-gate attestor (SAST + Trivy clean) on all
# non-system container images at GKE admission time.
# enforcement_mode=DRYRUN_AUDIT_LOG_ONLY in dev so new images are never
# blocked during iteration; flip to ENFORCED_BLOCK_AND_AUDIT_LOG for prod.
module "binary_authorization" {
  source = "../../modules/binary-authorization"

  project_id               = var.project_id
  env                      = var.env
  key_ring_id              = module.kms.keyring_id
  ci_service_account_email = var.ci_service_account_email
  enforcement_mode         = var.binauthz_enforcement_mode

  depends_on = [module.apis, module.kms]
}

# ── Tamper-evident Cloud Audit Logs bucket ────────────────────────────────────
# All Admin Activity + Data Access audit logs flow via a log sink into a
# CMEK-encrypted GCS bucket with an object-level retention policy.
# lock_retention_policy=false in dev; set true in prod after validating
# retention_days matches compliance requirements (irreversible once locked).
module "audit_logs" {
  source = "../../modules/audit-logs"

  project_id            = var.project_id
  env                   = var.env
  region                = var.region
  kms_key_id            = module.kms.key_ids["gcs"]
  retention_days        = 365 # 1 year for dev; 7 years (2555) for prod
  lock_retention_policy = false

  depends_on = [module.apis, module.kms]
}

# ── VPC Service Controls ──────────────────────────────────────────────────────
# Uncomment and populate org_id + protected_project_number to enable a
# DRY_RUN perimeter around this project. Promote to ENFORCE in prod after
# verifying no legitimate traffic is flagged as a violation in Cloud Logging.
#
# module "vpc_sc" {
#   source = "../../modules/vpc-sc"
#
#   org_id                    = var.org_id
#   env                       = var.env
#   protected_project_numbers = [var.project_number]
#   authorized_ip_ranges      = var.corp_ip_ranges
#   perimeter_mode            = "DRY_RUN"
#
#   depends_on = [module.apis]
# }
