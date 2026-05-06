# Disaster Recovery Runbook

---

## RTO / RPO Targets

| Scenario | Target RTO | Target RPO |
|----------|-----------|-----------|
| Single pod failure | < 30 s | 0 (stateless) |
| Node failure | < 5 min | 0 (stateless) |
| Zone failure | < 10 min | 0 (PD sync replicated) |
| Cloud SQL failover | < 2 min | < 5 s (sync HA replica) |
| Cloud SQL full restore (PITR) | < 1 hr | Configurable (PITR log lag ≤ 1 min) |
| GKE control plane outage | Managed by Google | N/A |
| Terraform state corruption | < 2 hr | Last successful `terraform apply` |

---

## 1. Cloud SQL — Point-in-Time Recovery (PITR)

Use when: data corruption, accidental `DELETE`/`DROP`, ransomware.

### 1a. Identify the recovery point

```bash
# List available backups
gcloud sql backups list \
  --instance=fintech-dev-pg-XXXX \
  --project=fintech-dev

# Binary log (PITR) retention window
gcloud sql instances describe fintech-dev-pg-XXXX \
  --project=fintech-dev \
  --format='value(settings.backupConfiguration.transactionLogRetentionDays)'
```

### 1b. Restore to a new Cloud SQL instance

**Never restore in-place to the primary** — clone to a new instance first.

```bash
TARGET_INSTANCE="fintech-dev-pg-pitr-$(date +%Y%m%d%H%M)"
RECOVERY_TIME="2025-06-01T14:30:00Z"   # ISO 8601 UTC

gcloud sql instances clone fintech-dev-pg-XXXX "${TARGET_INSTANCE}" \
  --project=fintech-dev \
  --point-in-time="${RECOVERY_TIME}"
```

### 1c. Validate data on the clone

```bash
# Connect via Cloud SQL Auth Proxy
cloud-sql-proxy --private-ip "fintech-dev:us-central1:${TARGET_INSTANCE}" &
psql "host=127.0.0.1 user=app_account dbname=accounts" \
  -c "SELECT count(*) FROM accounts;"
```

### 1d. Cut over application traffic

```bash
# Update the Kubernetes Secret with the new instance connection name
kubectl -n account-service patch secret account-service-db \
  --type=merge \
  -p "{\"stringData\":{\"INSTANCE_CONNECTION_NAME\":\"fintech-dev:us-central1:${TARGET_INSTANCE}\"}}"

# Rolling restart to pick up the new secret
kubectl -n account-service rollout restart deploy/account-service
kubectl -n account-service rollout status deploy/account-service
```

### 1e. Update Terraform state

After confirming the clone is healthy, import the new instance into Terraform
and remove the old one from state to avoid drift:

```bash
cd infra/envs/dev
terraform import module.cloud_sql.google_sql_database_instance.main \
  "fintech-dev/fintech-dev-pg-pitr-XXXXXX"
terraform apply   # reconcile state
```

---

## 2. GKE — Node Pool Recovery

Use when: node pool is stuck, nodes are NotReady, or an upgrade fails.

### 2a. Cordon and drain the affected pool

```bash
# Identify bad nodes
kubectl get nodes -o wide

# Drain gracefully (respects PDBs)
kubectl drain <node-name> \
  --ignore-daemonsets \
  --delete-emptydir-data \
  --grace-period=60
```

### 2b. Force node pool recreation via Terraform

```bash
cd infra/envs/dev
# Taint the node pool resource to force replacement
terraform taint module.gke.google_container_node_pool.main
terraform apply
```

### 2c. Verify cluster health post-recreate

```bash
kubectl get nodes
kubectl -n argocd get pods
kubectl -n account-service get pods
# ArgoCD will self-heal all workloads automatically
```

---

## 3. GKE — Full Cluster Recovery

Use when: cluster resource is deleted or catastrophically broken.

GKE regional clusters span 3 zones — a complete cluster loss requires
deliberate deletion of the Terraform-managed resource.

```bash
cd infra/envs/dev

# Recreate the cluster (will also re-create node pool)
terraform apply -target=module.gke

# Re-apply all dependent resources in dependency order
terraform apply -target=module.asm
terraform apply -target=module.argocd
terraform apply   # final full apply to reconcile everything
```

ArgoCD's root Application will re-sync all namespaces, mesh policies,
and service workloads automatically within ~5 minutes.

---

## 4. Artifact Registry — Image Unavailable

Use when: AR repository deleted or images corrupted.

```bash
# Re-create the repository via Terraform
cd infra/envs/dev
terraform apply -target=module.artifact_registry

# Re-push all images by triggering CI on each service
gh workflow run ci-account-service.yml --ref main
gh workflow run ci-transaction-service.yml --ref main
gh workflow run ci-notification-service.yml --ref main
gh workflow run ci-api-gateway.yml --ref main
gh workflow run ci-frontend.yml --ref main
```

---

## 5. Terraform State Recovery

Use when: state file is corrupted or accidentally deleted.

### 5a. State file is soft-deleted (versioning is enabled)

```bash
# List versions of the state file
gsutil ls -la gs://fintech-bootstrap-tfstate/envs/dev/

# Restore a specific version
gsutil cp \
  "gs://fintech-bootstrap-tfstate/envs/dev/#<generation>" \
  gs://fintech-bootstrap-tfstate/envs/dev/default.tfstate
```

### 5b. State must be rebuilt from scratch

```bash
cd infra/envs/dev

# Import each resource in dependency order.
# Start with the KMS keyring (most other resources depend on it).
terraform import module.kms.google_kms_key_ring.this \
  "projects/fintech-dev/locations/us-central1/keyRings/fintech-dev-platform"

# Import GKE cluster
terraform import module.gke.google_container_cluster.main \
  "projects/fintech-dev/locations/us-central1/clusters/fintech-dev-gke"

# ... continue for each resource listed in `terraform state list` from a backup
# Run `terraform plan` after each batch to verify no spurious diffs.
```

---

## 6. KMS Key Version Compromise

Use when: a CMEK key version is suspected compromised.

```bash
# Disable the compromised key version (prevents new encrypt/decrypt operations)
gcloud kms keys versions disable 1 \
  --key=gke \
  --keyring=fintech-dev-platform \
  --location=us-central1 \
  --project=fintech-dev

# Rotate to a new key version (KMS auto-rotation is already configured for 90 days)
# To force immediate rotation:
gcloud kms keys versions create \
  --key=gke \
  --keyring=fintech-dev-platform \
  --location=us-central1 \
  --project=fintech-dev

# GKE etcd, Cloud SQL, AR will all start encrypting new writes with the new version.
# Existing data remains readable because old versions are still enabled (just not default).
# Destroy the compromised version only after verifying no active readers depend on it:
gcloud kms keys versions destroy 1 \
  --key=gke \
  --keyring=fintech-dev-platform \
  --location=us-central1 \
  --project=fintech-dev
```

---

## Post-Incident Checklist

- [ ] Incident timeline documented (start, detect, mitigate, resolve)
- [ ] Root cause identified and blameless post-mortem scheduled
- [ ] Monitoring alert that would have caught the issue earlier — filed as task
- [ ] Runbook updated with any steps that were missing or incorrect
- [ ] Affected SLO windows recorded; error budget impact calculated
- [ ] DR test scheduled for the recovered scenario within 30 days
