# Project Roadmap — End-to-End Journey

> Where you are now → Where this project ends.
> Created 2026-05-09 after deep mastery of `account-service`.
> The full picture from local Docker to a production-grade GCP platform.

---

## TL;DR — Where This Project Ends

You will have built a **production-grade enterprise platform** where:

1. A developer can clone the repo, run `docker compose up`, and develop locally
2. A platform engineer can run `terraform apply` and get **dev/uat/prod** environments on GCP
3. Code pushed to `main` triggers CI → builds, signs, scans, deploys automatically
4. All services run with **mTLS**, NetworkPolicies, AuthZ, resource limits, and SLOs
5. Failures trigger alerts; on-call gets paged; rollback is one Git revert
6. Adding a brand-new microservice takes **30 minutes**, not 3 days

This is the kind of platform a real Platform Engineering team at Razorpay or PhonePe builds.

---

## The 6-Phase Journey (Mapped to the Project Folders)

Here is the FULL picture, end to end, with what you'll learn at each phase.

```
Phase 1 → Phase 2 → Phase 3 → Phase 4 → Phase 5 → Phase 6
  App     Infra      CI      GitOps     Mesh       Ops
 (DONE)
```

---

## Phase 1: App & Containerization ✅ (CURRENT)

**Status:** account-service deeply mastered. Speed-survey other 4 services next.

**What you'll have at end:**
- 5 microservices running locally via docker-compose
- Multi-stage Dockerfiles for each
- A clear contract sheet of what each service does

**Folders involved:**
```
account-service/        ← Done
transaction-service/    ← 15-min read
notification-service/   ← 15-min read
api-gateway/            ← 15-min read
frontend/               ← 15-min read
docker-compose.yml      ← run this
```

| Metric | Value |
|---|---|
| Time | 1-2 weeks (you've done most of it) |
| Cost | ₹0 (local Docker) |
| Skills gained | Microservices, Docker, transactional logic, REST APIs |

---

## Phase 2: Infrastructure (Terraform on GCP)

**The big one. This is where 50% of your career value comes from.**

You will write zero application code in this phase. Pure Platform Engineering.

### What you'll build

```
infra/
├── bootstrap/                    ← Step 1: Project setup, state bucket, WIF
└── envs/
    ├── dev/                      ← Step 2: First environment
    ├── uat/                      ← Later
    └── prod/                     ← Later
└── modules/                      ← Reusable pieces
    ├── vpc/                      ← Private network
    ├── gke/                      ← Kubernetes cluster
    ├── cloud-sql/                ← Managed Postgres
    ├── artifact-registry/        ← Private Docker registry
    ├── kms/                      ← Encryption keys
    ├── workload-identity-sa/     ← Service accounts (no JSON keys)
    ├── pubsub-topic/             ← Async messaging
    └── project-apis/             ← Enable required GCP APIs
```

### Step-by-Step Order

1. **Bootstrap** — creates the GCS bucket where Terraform state lives + sets up Workload Identity Federation for GitHub Actions
2. **Network (VPC)** — private network with subnets, firewall rules, no public IPs
3. **GKE Cluster** — private cluster, Workload Identity enabled, regional
4. **Cloud SQL** — Postgres with private IP only, automated backups
5. **Artifact Registry** — where your Docker images go
6. **KMS** — customer-managed encryption keys for everything

### What you'll learn (resume gold)

- **Terraform fundamentals** — providers, state, modules, plans, applies
- **Remote state** — GCS backend with locking
- **Multi-environment patterns** — dev/uat/prod isolation
- **GCP networking** — VPCs, private IPs, subnets, firewall rules
- **Kubernetes cluster design** — node pools, autoscaling, security
- **Workload Identity Federation** — the "no JSON key files" pattern

| Metric | Value |
|---|---|
| Time | 3-4 weeks |
| Cost | ₹3-5k/month while learning |
| Cost-saving tip | `terraform destroy` at night, `terraform apply` in morning |
| Skills gained | The 30 LPA skills |

---

## Phase 3: CI (GitHub Actions + Image Pipeline)

**This is where code goes from your laptop to a registry — automatically and securely.**

### What you'll build

```
.github/workflows/
├── ci-account-service.yml        ← Already scaffolded
├── ci-transaction-service.yml
├── ci-notification-service.yml
├── ci-api-gateway.yml
├── ci-frontend.yml
├── terraform.yml                 ← Terraform plan/apply on PR
└── dast.yml                      ← Security scanning
```

### What each pipeline does

When you push code to a service folder:

1. **Build** — Docker image with multi-stage build
2. **Test** — Unit + integration tests inside the container
3. **Sign** — Image signed using Sigstore/cosign
4. **Scan** — Vulnerability scan (Trivy / Snyk)
5. **Push** — Image goes to Artifact Registry with the **immutable git SHA** as the tag
6. **Update GitOps repo** — Bump the image tag in `gitops-manifests-dev/`

### What you'll learn

- **GitHub Actions** workflows (matrix builds, secrets, caching)
- **Workload Identity Federation** — GitHub authenticates to GCP **without any stored keys**
- **Image signing** — proves the image came from your CI, not a hacker
- **Immutable artifacts** — never `:latest` tags, always `:abc1234`
- **Path-based triggers** — only build account-service when account-service changes

| Metric | Value |
|---|---|
| Time | 1 week |
| Cost | ₹0 (GH Actions free tier covers this easily) |
| Skills gained | Modern CI patterns, supply-chain security |

---

## Phase 4: GitOps (ArgoCD — Declarative Continuous Delivery)

**This is where you stop running `kubectl apply` manually. Git becomes the source of truth.**

### What you'll build

```
infra/modules/argocd/             ← ArgoCD installed via Terraform
gitops-manifests-dev/             ← The "what should be running" repo
account-service/chart/            ← Helm chart (already exists)
transaction-service/chart/
notification-service/chart/
api-gateway/chart/
frontend/chart/
```

### How it works

1. CI pushes new image tag → updates `gitops-manifests-dev/account-service.yaml`
2. ArgoCD watches the Git repo every 3 minutes
3. ArgoCD sees the change → automatically syncs to the cluster
4. New pod rolls out with zero-downtime
5. ArgoCD UI shows everything green

### Pattern: App-of-Apps

One root Application creates child Applications for every service. Add a new service → it shows up automatically.

### What you'll learn

- **GitOps philosophy** — "if it's not in Git, it doesn't exist"
- **ArgoCD** — sync waves, drift detection, rollback (one Git revert = full rollback)
- **Helm** — templating, values per environment, chart structure
- **Self-service deploys** — devs don't need cluster access

| Metric | Value |
|---|---|
| Time | 1 week |
| Cost | Minimal |
| Skills gained | GitOps, Helm, the modern delivery pattern |

---

## Phase 5: Service Mesh (Anthos Service Mesh / Istio)

**This is where security becomes uniform across all services. The crown jewel of Platform Engineering.**

### What you'll build

```
infra/modules/asm/                ← Anthos Service Mesh enabled
k8s-baseline/mesh/
├── 00-strict-mtls.yaml           ← All service-to-service traffic encrypted
├── 10-ingress-gateway-namespace.yaml
├── 11-ingress-gateway-deployment.yaml
├── 12-gateway.yaml               ← Public ingress (only entry point)
├── 20-authz-deny-all.yaml        ← Default deny — explicit allow only
└── 21-authz-call-graph.yaml      ← Who can call whom
```

### What this unlocks

| Without mesh | With mesh |
|---|---|
| Each service implements TLS itself | Every service automatically gets mTLS |
| Each service implements auth | Mesh enforces "transaction-service can call account-service" |
| Manual retry logic in code | Mesh handles retries, timeouts, circuit breakers |
| No traffic visibility | See every request between services |

### What you'll learn

- **mTLS** — mutual TLS, automatic certificate rotation
- **Istio resources** — VirtualService, DestinationRule, AuthorizationPolicy, PeerAuthentication
- **Zero-trust networking** — never trust, always verify
- **Traffic management** — canary deploys, A/B testing, fault injection
- **Service mesh debugging** — Kiali, envoy logs, mesh dashboards

| Metric | Value |
|---|---|
| Time | 2 weeks |
| Cost | Minimal |
| Skills gained | This is what differentiates senior platform engineers |

---

## Phase 6: Operations (Observability + Hardening + Templatization)

**The final phase. This is what separates a "demo project" from a "production platform."**

### Sub-phase 6A: Observability

```
infra/modules/monitoring/         ← Cloud Monitoring alerts
├── alerts.tf                     ← Alert policies
├── slos.tf                       ← Service Level Objectives
└── notifications.tf              ← Slack / email routing

k8s-baseline/observability/
├── 01-kube-prometheus-stack.yaml ← Prometheus + Grafana
├── 10-grafana-golden-signals.yaml ← Dashboards
└── 20-argocd-notifications.yaml  ← Deploy success/fail alerts
```

**What you'll learn:**
- **The 4 Golden Signals** — Latency, Traffic, Errors, Saturation
- **SLOs / SLIs** — measurable reliability targets ("99.9% of requests < 300ms")
- **Alert design** — alert on symptoms (user impact), not causes
- **Grafana dashboard design** — RED method (Rate, Errors, Duration)

### Sub-phase 6B: Security Hardening

```
infra/modules/binary-authorization/   ← Only signed images can deploy
infra/modules/audit-logs/             ← Every GCP API call logged
infra/modules/vpc-sc/                 ← Data exfiltration prevention
.github/workflows/dast.yml            ← Dynamic Application Security Testing
.zap/                                 ← OWASP ZAP scan rules
```

**What you'll learn:**
- **Binary Authorization** — cluster rejects unsigned images at admission
- **Audit logs** — forensic-grade record of every change
- **VPC Service Controls** — perimeter around your data
- **DAST** — automated security scanning of running services

### Sub-phase 6C: Templatization (The Platform Maturity Test)

```
infra/modules/service-baseline/   ← One module creates all infra for a service
scaffold/                         ← Helm chart scaffold script
scripts/                          ← "Add a new service in 30 min" script
docs/runbooks/                    ← On-call playbooks
```

**The test:** A new developer joins the team. They want to add a `payment-service`.

**With a mature platform:**
1. Run `./scripts/new-service.sh payment-service`
2. Push to Git
3. Service is deployed to dev within 10 minutes — with mTLS, NetworkPolicies, monitoring, alerts, all of it

**Without a mature platform:**
1. Copy-paste 200 lines of Terraform
2. Forget to add NetworkPolicy
3. Production incident in 3 weeks

**This is what Platform Engineering means.**

| Metric | Value |
|---|---|
| Time | 2-3 weeks |
| Cost | Minimal |
| Skills gained | Senior Platform Engineer skills |

---

## The Full Timeline

| Phase | What | Time | Running Total |
|---|---|---|---|
| Phase 1 | App + Containerization | 1-2 weeks | 2 weeks |
| Phase 2 | Infrastructure (Terraform + GCP) | 3-4 weeks | 6 weeks |
| Phase 3 | CI (GitHub Actions) | 1 week | 7 weeks |
| Phase 4 | GitOps (ArgoCD) | 1 week | 8 weeks |
| Phase 5 | Service Mesh (Istio) | 2 weeks | 10 weeks |
| Phase 6 | Ops (Observability + Hardening + Templatization) | 2-3 weeks | **12-13 weeks** |

**Total: ~3 months part-time** (2 hours/day on weekdays + weekends).

---

## The Cost Picture

| Phase | Monthly Cost | Why |
|---|---|---|
| Phase 1 | ₹0 | Local Docker only |
| Phase 2-6 | ₹3-5k/month | Small dev cluster on GCP |
| **Total over 3 months** | **₹10-15k** | |

**Cost-saving rules:**
1. ALWAYS run `terraform destroy` at end of session
2. Use `e2-small` or `e2-micro` machine types (NOT `n1-standard-4`)
3. Set GCP budget alerts at $50, $100, $200
4. Use Cloud SQL `db-f1-micro` tier
5. Don't keep clusters running 24/7

**Payback math:** ₹15k investment → ₹10 LPA salary jump = ₹83k/month extra. **Payback period: 5 days.**

---

## What You'll Have at the End — The Resume Bullet

> "Designed and built an enterprise-grade fintech platform on GCP from scratch — 5 microservices, multi-environment Terraform infrastructure (dev/uat/prod) with private GKE clusters, Cloud SQL, and KMS-encrypted artifact registry. Implemented full CI/CD using GitHub Actions with Workload Identity Federation (zero static credentials), GitOps delivery via ArgoCD, and zero-trust security via Anthos Service Mesh (strict mTLS, AuthZ call-graph enforcement). Operational maturity included Cloud Monitoring SLOs, Binary Authorization, VPC Service Controls, audit logs, DAST scanning, and a templatization layer that allows new microservices to be added in 30 minutes."

**That bullet alone is worth 10 LPA in salary negotiation.**

---

## What You'll Be Able to Do Confidently

After finishing this project, you can walk into any DevOps / Platform / SRE interview and:

✅ Explain how a private GKE cluster routes traffic from internet → Istio gateway → app
✅ Debug a `403` between two services using AuthorizationPolicy logs
✅ Write a Terraform module from scratch for any new service
✅ Set up CI from zero on a new repo with image signing in 30 minutes
✅ Design SLOs and explain the difference between SLO/SLI/SLA
✅ Explain the trade-offs of GitOps vs imperative `kubectl apply`
✅ Discuss Workload Identity Federation vs JSON key files (security depth)
✅ Walk through an incident: "the 5xx rate spiked at 2am, here's how I'd debug"

---

## The Telangana Village Truth

> When you started, you were a person who could repair a tractor.
>
> By the end of this project, you will be the engineer who designed the tractor factory —
> picked the location, drew the assembly line, set up the supply chain,
> and trained the QA team.
>
> One repairs. The other architects.
> The factory architect always earns more than the mechanic.

---

## Where This Project Ends — The Final State

```
                          ┌─────────────────┐
                          │     User        │
                          └────────┬────────┘
                                   │
                          ┌────────▼────────┐
                          │ Public DNS / LB │
                          └────────┬────────┘
                                   │
                          ┌────────▼────────────┐
                          │ Istio Ingress       │
                          │ Gateway (mTLS edge) │
                          └────────┬────────────┘
                                   │
                          ┌────────▼────────┐
                          │  api-gateway    │ ← JWT validation
                          └────────┬────────┘
                                   │ mTLS
                ┌──────────────────┼──────────────────┐
                │                  │                  │
        ┌───────▼──────┐  ┌───────▼─────────┐  ┌────▼──────────┐
        │  account-    │  │ transaction-    │  │ notification- │
        │  service     │  │ service         │  │ service       │
        └───────┬──────┘  └─────────────────┘  └───────────────┘
                │
        ┌───────▼──────────┐
        │ Cloud SQL Proxy  │
        │ (Workload ID)    │
        └───────┬──────────┘
                │ private IP
        ┌───────▼──────────┐
        │ Cloud SQL        │
        │ (Postgres)       │
        └──────────────────┘

  Surrounding everything:
  - Private VPC (no public IPs)
  - VPC Service Controls perimeter
  - Audit logs to BigQuery
  - Prometheus → Grafana → Slack alerts
  - ArgoCD reconciling from Git every 3 minutes
  - GitHub Actions building, signing, deploying on every push
```

This is where the project ends. **A real, working, production-grade platform.**

---

## What to Do Next (Right Now)

1. Finish Phase 1 — speed survey of remaining 4 services (1-2 days)
2. Open `infra/bootstrap/` and start reading the Terraform code
3. Create a GCP account, enable billing with budget alerts at $50/$100/$200
4. Begin Phase 2

You are 1/6th of the way there. The hardest part (the mindset shift) is already done.

The rest is just walking the path, one phase at a time.
