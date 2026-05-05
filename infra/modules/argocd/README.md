# argocd module

Installs Argo CD via the official Helm chart with a hardened HA topology and
optional Workload Identity for the repo-server.

## What it provisions

- `argocd` namespace with the managed-ASM revision label and Pod Security
  Standards `baseline` enforce.
- Helm release of `argo-cd` (chart version pinned via `chart_version`).
- HA components: `redis-ha`, two `server` replicas + autoscaler, two
  `repo-server` replicas + autoscaler, two `applicationSet` replicas, single
  `application-controller` (sharded internally).
- Dex disabled by default (point at your IdP via `extra_values` when ready).
- `--insecure` on the server because the Istio sidecar terminates mTLS.
- (Optional) GSA `argocd-repo-server` bound to the same-named KSA via
  `iam.workloadIdentityUser`. Granted `roles/artifactregistry.reader` on
  `artifact_registry_reader_project` so the repo-server can pull OCI Helm
  charts from Artifact Registry without static creds.

## Inputs

| Name                                | Default        | Notes                                            |
| ----------------------------------- | -------------- | ------------------------------------------------ |
| `project_id`                        | _required_     |                                                  |
| `namespace`                         | `argocd`       |                                                  |
| `chart_version`                     | `7.3.11`       | Pin a known-good version per env.                |
| `asm_revision_label`                | `asm-managed`  |                                                  |
| `create_workload_identity_sa`       | `true`         |                                                  |
| `artifact_registry_reader_project`  | `""`           | Empty = skip the AR reader binding.              |
| `extra_values`                      | `""`           | Raw YAML appended to the Helm values.            |

## Outputs

- `namespace`
- `repo_server_gsa_email`

## Notes

- The Helm provider needs reachability to the cluster master endpoint. Make
  sure `master_authorized_networks` on the GKE module includes your CI runner.
- The chart's CRDs are installed by the Helm release. If you adopt the
  Application CRs into Argo's own management later, exclude them from prune.
