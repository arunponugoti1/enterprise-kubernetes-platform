# Mesh baseline

Manifests applied after Managed ASM is enabled by Terraform. Apply order matters; the filename prefixes (00, 10, 11, 12, 20, 21) reflect it.

| File                                  | Purpose                                                     |
| ------------------------------------- | ----------------------------------------------------------- |
| `00-strict-mtls.yaml`                 | Mesh-wide STRICT `PeerAuthentication` in `istio-system`.    |
| `10-ingress-gateway-namespace.yaml`   | `asm-gateways` namespace + ingress-gateway KSA.             |
| `11-ingress-gateway-deployment.yaml`  | Injected gateway Deployment + Service (LB) + HPA + PDB.     |
| `12-gateway.yaml`                     | Istio `Gateway` terminating TLS on 443 (HTTP→HTTPS redir).  |
| `20-authz-deny-all.yaml`              | Default-deny `AuthorizationPolicy` in each app namespace.   |
| `21-authz-call-graph.yaml`            | Allow-list per service + health-probe exceptions.           |

## Prerequisites

- Phase 3 Terraform applied (Hub membership + `servicemesh` feature + managed control plane). Confirm with:
  ```
  gcloud container fleet mesh describe --project <project>
  ```
- App namespaces (`account-service`, `transaction-service`, `notification-service`) labeled `istio.io/rev: asm-managed` — already done in `k8s-baseline/<service>/namespace.yaml`.

## TLS for the ingress gateway

`12-gateway.yaml` references a TLS secret named `ingress-cert` in `asm-gateways`. Provide it via cert-manager + Let's Encrypt (recommended) or a Google-managed certificate. Until that secret exists, the HTTPS server stays inactive — HTTP-only listener still works for testing.

## Verifying

After apply:

```
# mesh-wide mTLS in effect
istioctl x authz check <pod> -n account-service

# An external curl to the LB without TLS should be redirected, with TLS should
# return whatever the configured VirtualService routes to (none yet — Phase 5).
kubectl -n asm-gateways get svc asm-ingressgateway -o wide
```

These manifests will move to `gitops-manifests-dev/baseline/mesh/` in Phase 4 and be applied by ArgoCD.
