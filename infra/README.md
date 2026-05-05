# Infrastructure (Terraform)

Multi-project, multi-environment GCP infrastructure managed entirely in Terraform.
All required Google APIs are enabled by Terraform — nothing is clicked in the console.

## Layout

```
infra/
  bootstrap/         One-time bootstrap: state bucket, CMEK, CI service account, WIF.
                     Runs with LOCAL state, then state is migrated to the GCS bucket it creates.
  modules/
    project-apis/    Reusable module that enables a curated list of Google APIs on a project.
  envs/
    dev/             Per-environment root module. Uses remote state in the bootstrap bucket.
    uat/
    prod/
```

## Order of operations

1. **Bootstrap** (run once, by a human with Owner on the bootstrap project):
   ```
   cd infra/bootstrap
   terraform init
   terraform apply -var-file=terraform.tfvars
   # then migrate to remote state:
   terraform init -migrate-state
   ```
2. **Per-environment** (run by CI via Workload Identity Federation):
   ```
   cd infra/envs/dev
   terraform init
   terraform apply -var-file=terraform.tfvars
   ```

## Conventions

- Project IDs: `fintech-<env>` (`fintech-dev`, `fintech-uat`, `fintech-prod`).
- Region defaults: `us-central1` (override per env if needed).
- No service account keys. CI authenticates via Workload Identity Federation only.
- State bucket is encrypted with CMEK and versioned.
