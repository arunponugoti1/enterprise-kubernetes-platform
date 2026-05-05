# gitops-manifests-dev

ArgoCD-managed manifests for the **dev** environment.

The Terraform-installed ArgoCD instance reconciles the `root` Application
(planted by `infra/envs/dev/argocd.tf`), which points at `apps/`. Each file in
`apps/` is an Argo `Application` that ArgoCD then reconciles in turn — this is
the standard "app-of-apps" pattern.

## Layout

```
apps/                    Argo Applications (each describes one logical bundle).
  baseline.yaml          Namespaces, KSAs, NetworkPolicies for app services.
  mesh.yaml              Mesh-wide mTLS, ingress gateway, AuthorizationPolicies.
  services/              One Application per microservice (added in Phases 5–6).
```

In production this directory lives in its own repository (`gitops-manifests-dev`).
For now it ships alongside the Terraform in this monorepo and ArgoCD points
at the same Git URL with a different `path`.

## Adding a new microservice

1. Create the Helm chart under `microservices-app-repo/<service>/chart/`.
2. Push a new `Application` YAML into `apps/services/<service>.yaml` here.
3. Commit. ArgoCD picks it up within `timeout.reconciliation` (180s).
