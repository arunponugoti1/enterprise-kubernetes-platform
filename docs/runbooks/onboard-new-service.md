# Onboard a New Microservice

Target time: **< 4 hours** for a new engineer following this runbook.

---

## Prerequisites

- Repo cloned, `scripts/new-service.sh` executable
- `gcloud` CLI authenticated with `roles/owner` on `fintech-dev`
- Terraform state access (bootstrap SA credentials or WIF)
- Helm and kubectl pointing at the dev cluster

---

## Step 1 — Run the scaffold script (5 min)

```bash
./scripts/new-service.sh payment-service \
  --port 8080 \
  --wave 25 \
  --cloud-sql \
  --virtual-service \
  --lang node
```

This generates:
| Path | Description |
|------|-------------|
| `payment-service/chart/` | Helm chart (PSS-restricted, Cloud SQL Proxy, HPA, PDB, NetworkPolicy) |
| `.github/workflows/ci-payment-service.yml` | CI: test → CodeQL → build → Trivy → push → BinAuthz attest → bump tag |
| `gitops-manifests-dev/apps/services/payment-service.yaml` | ArgoCD Application (wave 25, Helm) |

---

## Step 2 — Write the service code (variable)

Create `payment-service/` with at minimum:
- `Dockerfile` — multi-stage, non-root user, no unnecessary packages
- `package.json` (or equivalent) with a `test` script
- `src/index.js` (or equivalent) — HTTP server on the configured port
- `/health` endpoint returning `200 OK`

---

## Step 3 — Add Terraform resources (15 min)

Add to `infra/envs/dev/` (new file `payment-service.tf` or append `main.tf`):

```hcl
module "svc_payment_service" {
  source = "../../modules/service-baseline"

  project_id         = var.project_id
  env                = var.env
  service_name       = "payment-service"
  asm_revision_label = module.asm.control_plane_revision_label

  project_roles = [
    "roles/cloudsql.client",
    # add more as needed
  ]

  depends_on = [module.asm]
}
```

If the service needs its own Cloud SQL user, add a `kubernetes_secret_v1` in `app-resources.tf`:

```hcl
resource "kubernetes_secret_v1" "payment_service_db" {
  metadata {
    name      = "payment-service-db"
    namespace = module.svc_payment_service.namespace
  }
  type = "Opaque"
  data = {
    DB_USER                  = "app_payment"
    DB_NAME                  = "payments"
    DB_PASSWORD              = module.cloud_sql.user_passwords["app_payment"]
    INSTANCE_CONNECTION_NAME = module.cloud_sql.connection_name
  }
}
```

Also add `"app_payment"` to the `additional_users` map in the `cloud-sql` module call.

Apply:
```bash
cd infra/envs/dev
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

---

## Step 4 — Populate the ArgoCD Application (10 min)

After `terraform apply`, get the GSA email:
```bash
terraform output -json | jq -r '.workload_identity_sa_emails.value["payment-service"]'
# or
terraform output module.svc_payment_service.gsa_email
```

Update `gitops-manifests-dev/apps/services/payment-service.yaml`:
```yaml
parameters:
  - name: image.repository
    value: us-central1-docker.pkg.dev/fintech-dev/docker/payment-service   # real AR URL
  - name: gsaEmail
    value: svc-payment-service-dev@fintech-dev.iam.gserviceaccount.com    # from TF output
  - name: cloudSql.instanceConnectionName
    value: fintech-dev:us-central1:fintech-dev-pg-xxxx                    # from TF output
```

---

## Step 5 — Add mesh authorization policies (10 min)

Add an AuthorizationPolicy to `k8s-baseline/mesh/21-authz-call-graph.yaml` that allows only the expected callers:

```yaml
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: allow-api-gateway
  namespace: payment-service
spec:
  action: ALLOW
  rules:
    - from:
        - source:
            principals:
              - "cluster.local/ns/api-gateway/sa/api-gateway"
```

Commit the mesh policy alongside the service code.

---

## Step 6 — Commit and push (2 min)

```bash
git add payment-service/ \
        .github/workflows/ci-payment-service.yml \
        gitops-manifests-dev/apps/services/payment-service.yaml \
        k8s-baseline/mesh/21-authz-call-graph.yaml \
        infra/envs/dev/

git commit -m "feat(payment-service): initial scaffold + infra wiring"
git push origin HEAD:main
```

---

## Step 7 — Verify (20 min)

### CI passes
Watch `.github/workflows/ci-payment-service.yml` on the Actions tab.
All jobs should be green: test → sast → build-and-push (incl. Trivy + BinAuthz) → deploy-to-dev.

### ArgoCD syncs
```bash
kubectl -n argocd get app payment-service
# STATUS: Synced, HEALTH: Healthy
```

### Pod is running
```bash
kubectl -n payment-service get pods
kubectl -n payment-service logs deploy/payment-service
```

### mTLS verified
```bash
# Check that sidecar is injected and mTLS is enforced
kubectl -n payment-service exec deploy/payment-service -c istio-proxy -- \
  pilot-agent request GET stats | grep ssl
```

### Health endpoint
```bash
kubectl -n payment-service port-forward svc/payment-service 8080:80 &
curl -s http://localhost:8080/health
```

---

## GitHub Actions repo variables to set

After Terraform apply, set these under **Settings → Secrets and variables → Actions → Variables**:

| Variable | Value | Source |
|----------|-------|--------|
| `AR_HOST` | `us-central1-docker.pkg.dev` | Artifact Registry region |
| `AR_PROJECT` | `fintech-dev` | GCP project |
| `WIF_PROVIDER` | `projects/…/providers/github-provider` | `terraform output workload_identity_provider` |
| `CI_SERVICE_ACCOUNT` | `ci-terraform@fintech-bootstrap…` | `terraform output ci_service_account_email` |
| `BINAUTHZ_ATTESTOR` | `qa-gate-dev` | `module.binary_authorization.attestor_name` |
| `BINAUTHZ_KEY_VERSION_ID` | `projects/…/cryptoKeyVersions/1` | `module.binary_authorization.attestor_kms_key_version_id` |
