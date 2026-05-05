# account-service Helm chart

Deploys account-service into an existing namespace. The namespace and the
`account-service-db` Kubernetes Secret holding DB credentials are created by
Terraform (`infra/envs/dev/app-resources.tf`); the chart depends on both.

## Required values

The ArgoCD Application sets these via `helm.parameters` so the chart stays
env-portable:

| Value                              | From                                                              |
| ---------------------------------- | ----------------------------------------------------------------- |
| `image.repository`                 | `terraform output -raw artifact_registry_urls` + `/account-service` |
| `image.tag`                        | CI bumps to the immutable git SHA tag.                            |
| `gsaEmail`                         | `workload_identity_sa_emails["account-service"]` Terraform output.|
| `cloudSql.instanceConnectionName`  | `sql_connection_name` Terraform output.                           |

## What's included

- `ServiceAccount` annotated with the GSA email (Workload Identity).
- `Deployment` with two containers: the app and the Cloud SQL Auth Proxy v2
  sidecar (private-IP, IAM-authenticated). App reads DB creds via `envFrom`
  pointing at the Terraform-created Secret.
- `Service`, `HorizontalPodAutoscaler`, `PodDisruptionBudget`.
- `NetworkPolicy`: default-deny + DNS + Google private APIs + Cloud SQL +
  ingress allow-list (api-gateway, transaction-service, asm-gateways).
- `VirtualService` binding `/accounts*` on the public ingress gateway.

The Istio mesh-wide STRICT `PeerAuthentication` and the per-call-graph
`AuthorizationPolicy` are managed centrally in `k8s-baseline/mesh/`.
