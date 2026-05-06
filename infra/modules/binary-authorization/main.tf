data "google_project" "this" {
  project_id = var.project_id
}

# ─── Container Analysis Note ───────────────────────────────────────────────────
# Describes the security gate that certifiers sign under.
resource "google_container_analysis_note" "qa_gate" {
  project = var.project_id
  name    = "qa-gate-${var.env}"

  attestation_authority {
    hint {
      human_readable_name = "[${var.env}] QA Gate — SAST + Trivy HIGH/CRITICAL clean"
    }
  }
}

# ─── KMS asymmetric signing key ────────────────────────────────────────────────
# Created directly (not through the shared CMEK module) because asymmetric keys
# use purpose=ASYMMETRIC_SIGN and the API rejects a rotation_period on them.
resource "google_kms_crypto_key" "attestor" {
  name     = "binauthz-qa-attestor-${var.env}"
  key_ring = var.key_ring_id
  purpose  = "ASYMMETRIC_SIGN"

  version_template {
    algorithm        = "EC_SIGN_P256_SHA256"
    protection_level = "SOFTWARE"
  }

  lifecycle {
    prevent_destroy = true
  }
}

data "google_kms_crypto_key_version" "attestor" {
  crypto_key = google_kms_crypto_key.attestor.id
}

# ─── Attestor ──────────────────────────────────────────────────────────────────
resource "google_binary_authorization_attestor" "qa_gate" {
  project = var.project_id
  name    = "qa-gate-${var.env}"

  attestation_authority_note {
    note_reference = google_container_analysis_note.qa_gate.id

    public_keys {
      id = data.google_kms_crypto_key_version.attestor.id
      pkix_public_key {
        public_key_pem      = data.google_kms_crypto_key_version.attestor.public_key[0].pem
        signature_algorithm = "ECDSA_P256_SHA256"
      }
    }
  }

  depends_on = [
    google_project_iam_member.binauthz_note_viewer,
    google_project_iam_member.binauthz_occurrences_viewer,
  ]
}

# ─── IAM — BinAuthz system SA ──────────────────────────────────────────────────
resource "google_project_iam_member" "binauthz_note_viewer" {
  project = var.project_id
  role    = "roles/containeranalysis.notes.viewer"
  member  = "serviceAccount:service-${data.google_project.this.number}@gcp-sa-binaryauthorization.iam.gserviceaccount.com"
}

resource "google_project_iam_member" "binauthz_occurrences_viewer" {
  project = var.project_id
  role    = "roles/containeranalysis.occurrences.viewer"
  member  = "serviceAccount:service-${data.google_project.this.number}@gcp-sa-binaryauthorization.iam.gserviceaccount.com"
}

# ─── IAM — CI service account ──────────────────────────────────────────────────
resource "google_kms_crypto_key_iam_member" "ci_signer" {
  crypto_key_id = google_kms_crypto_key.attestor.id
  role          = "roles/cloudkms.signerVerifier"
  member        = "serviceAccount:${var.ci_service_account_email}"
}

resource "google_project_iam_member" "ci_attestor_viewer" {
  project = var.project_id
  role    = "roles/binaryauthorization.attestorViewer"
  member  = "serviceAccount:${var.ci_service_account_email}"
}

resource "google_project_iam_member" "ci_notes_attacher" {
  project = var.project_id
  role    = "roles/containeranalysis.notes.attacher"
  member  = "serviceAccount:${var.ci_service_account_email}"
}

# ─── Binary Authorization policy ───────────────────────────────────────────────
locals {
  # Images that are never built by our CI and must be exempted.
  system_image_patterns = [
    "gcr.io/google-containers/*",
    "gcr.io/google_containers/*",
    "gke.gcr.io/*",
    "gcr.io/gke-release/*",
    "registry.k8s.io/*",
    # ASM / Istio
    "gcr.io/istio-release/*",
    "gcr.io/gke-release/asm/*",
    # ArgoCD
    "quay.io/argoproj/*",
    # kube-prometheus-stack
    "quay.io/prometheus/*",
    "quay.io/prometheus-operator/*",
    "docker.io/grafana/*",
    "docker.io/prom/*",
    # Cloud SQL Auth Proxy
    "gcr.io/cloud-sql-connectors/*",
    # cert-manager
    "quay.io/jetstack/*",
    # Redis (ArgoCD HA)
    "docker.io/redis/*",
    "docker.io/library/redis/*",
  ]
}

resource "google_binary_authorization_policy" "policy" {
  project = var.project_id

  global_policy_evaluation_mode = "ENABLE"

  default_admission_rule {
    evaluation_mode  = "REQUIRE_ATTESTATION"
    enforcement_mode = var.enforcement_mode

    require_attestations_by = [
      google_binary_authorization_attestor.qa_gate.name,
    ]
  }

  dynamic "admission_whitelist_patterns" {
    for_each = local.system_image_patterns
    content {
      name_pattern = admission_whitelist_patterns.value
    }
  }
}
