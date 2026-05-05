# bootstrap

One-time Terraform that creates everything needed before any other root module can run:

- Enables the foundational APIs on the bootstrap project.
- Creates a CMEK-encrypted, versioned GCS bucket for Terraform remote state.
- Creates the `ci-terraform` service account.
- Creates a Workload Identity Federation pool + GitHub OIDC provider, restricted to the listed repos in your GitHub org.
- Grants the CI SA the roles it needs on the managed dev/uat/prod projects.

## Prerequisites

- The four projects (`fintech-bootstrap`, `fintech-dev`, `fintech-uat`, `fintech-prod`) already exist and are linked to a billing account. Project creation is intentionally outside Terraform — it usually requires org-level permissions and is a one-time human action.
- You are authenticated locally as a principal with Owner on `fintech-bootstrap` and at least `resourcemanager.projectIamAdmin` on the managed projects:
  ```
  gcloud auth application-default login
  ```

## Run

```
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars
terraform init
terraform apply
```

Then migrate to remote state:

1. Copy `state_bucket` from the apply output.
2. Uncomment the `backend "gcs"` block in `backend.tf` and paste the bucket name.
3. Run `terraform init -migrate-state`.
