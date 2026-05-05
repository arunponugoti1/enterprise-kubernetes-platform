# Kubernetes baseline manifests

Per-namespace bootstrap that pairs with the Phase 2 Terraform IAM:

- `Namespace` with Pod Security Standards `restricted` enforce label.
- `ServiceAccount` annotated with the matching GSA email so Workload Identity works.
- `NetworkPolicy` defaults: deny-all ingress + egress, then allow DNS to `kube-system` and allow egress to private Google APIs / Cloud SQL ranges.

These manifests are environment-agnostic — render them per-env by substituting:

| Placeholder              | Value (dev)                                         |
| ------------------------ | --------------------------------------------------- |
| `__GSA_ACCOUNT_SVC__`    | output `workload_identity_sa_emails["account-service"]`     |
| `__GSA_TXN_SVC__`        | output `workload_identity_sa_emails["transaction-service"]` |
| `__GSA_NOTIF_SVC__`      | output `workload_identity_sa_emails["notification-service"]`|

In Phase 4 these manifests move to the GitOps repo (`gitops-manifests-dev/baseline/`) and ArgoCD applies them. Until ArgoCD exists, apply manually:

```
kubectl apply -f k8s-baseline/account-service/
kubectl apply -f k8s-baseline/transaction-service/
kubectl apply -f k8s-baseline/notification-service/
```
