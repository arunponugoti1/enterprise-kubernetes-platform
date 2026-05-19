# 🏗️ Terraform + GCP Mastery — Personal Learning Archive

> Goal: Go from surface-level Terraform knowledge → **8-9/10 mentor-grade depth**, so that when we later add CI, GitOps, Mesh, and Ops on top, the *infra layer* feels like solid ground under your feet — not magic shell scripts you copy-pasted.
>
> This is the "hard way" path. Same shape as `docker-mastery/`. No shortcut from 2/10 → 8/10 exists — only consistent, deep, hands-on work.

---

## 📖 How to use this folder

Each file is a self-contained lesson. Read them **in order**. Don't skip ahead — each one builds on the previous.

When you re-read later (the Pass-2 way from `Q-PHASE.md`), focus on the **village analogies** and **summary tables** — those are your mentor weapons when you teach this to a junior engineer.

**Rule of thumb:** Don't move to the next phase until you can teach the current one to your mom (or a Class-12 student) using only the village analogy. If you can't — you don't know it yet.

---

## 📚 Index

### Phase T-0 — Honest starting point
- [`00-knowledge-diagnostic.md`](./00-knowledge-diagnostic.md) — 10-question diagnostic. Answer first, score after. This is your **before** picture.

### Phase T-A — The Foundation Unlock (State + Provider model)
> *"Terraform does not manage your infrastructure. It manages a JSON file."*

- [`phase-T-A-01-the-big-lie.md`](./phase-T-A-01-the-big-lie.md) — The mindset shift: state is the truth, the cloud is the audit. Village analogy: the mandi register vs the actual stalls.
- `phase-T-A-02-providers-and-plan.md` — *(coming after A-01 absorbed)* — How `provider`, `plan`, `apply`, `refresh` actually work under the hood.
- `phase-T-A-03-state-file-anatomy.md` — *(coming next)* — Open `terraform.tfstate`, read every key, understand why it's holy.

### Phase T-B — Build a VPC by hand (NO Terraform yet) *(not started)*
> *"You can't automate what you don't understand manually."*
- gcloud + console: create VPC, subnet, firewall rule, route
- Delete it by hand too — see what each resource is and what it costs

### Phase T-C — Hello Terraform *(not started)*
> *"The same VPC, but now from a blueprint."*
- One `main.tf`, one resource, one apply
- Open `terraform.tfstate` and read every line
- Break it intentionally → recover

### Phase T-D — State, the real secret *(not started)*
- Local state vs GCS remote state
- State locking via Cloud Storage object versioning
- `terraform import`, `terraform refresh`, `terraform state mv`, `terraform state rm`
- The "what happens if two engineers `apply` at the same time" problem

### Phase T-E — Modules and Reuse *(not started)*
- When to write a module, when NOT to
- Inputs, outputs, versioning, the `./modules/vpc` pattern
- Reading the project's existing `infra/modules/` with new eyes

### Phase T-F — Multi-environment (dev / uat / prod) *(not started)*
- Same module, three `tfvars`, three state files
- Why workspaces are a trap for serious projects
- Project-per-env vs folder-per-env vs workspace

### Phase T-G — Workload Identity Federation *(not started)*
> *"No JSON keys, ever. The watchman recognizes your face."*
- GitHub OIDC → GCP. How the trust handshake actually works.
- Why this is the single biggest security win in modern DevOps

### Phase T-H — Private GKE Cluster *(not started)*
- Private cluster, control plane in private subnet
- Node pools, autoscaling, Workload Identity (cluster-side)
- This is where account-service finally leaves your laptop

### Phase T-I — Cloud SQL + KMS *(not started)*
- Managed Postgres with private IP only, CMEK encryption
- Automated backups, point-in-time recovery
- Migrating account-service from compose-postgres → Cloud SQL

### Phase T-J — Rebuild the project's `infra/bootstrap/` from scratch *(not started)*
- Read every line of the existing scaffold
- Rebuild it without copy-pasting (Pass-3 from Q-PHASE.md)
- This is the "graduation" exercise

---

## 🎯 The North Star

By the end of this archive, I should be able to:

1. Explain "what is Terraform really doing?" to my mom using the **mandi register analogy**
2. Build a VPC + private GKE cluster from a blank GCP project in under 90 minutes, from memory
3. Recover from a corrupted state file using `terraform import` + `terraform state mv`
4. Defend my module design in a code review ("why does this module accept `name_prefix` but not `region`?")
5. Explain Workload Identity Federation end-to-end — the JWT exchange, the trust pool, the impersonation chain
6. Walk into Kubernetes (Phase 5 of the main project) and say *"Workload Identity in K8s? That's just WIF in the cluster — I've seen this before."*

---

## ✅ Progress tracker

| Phase | Status | Date |
|-------|--------|------|
| T-0 Diagnostic | 📝 File ready, awaiting answers | — |
| T-A1 The Big Lie | 📝 File ready, awaiting absorption | — |
| T-A2 Providers + Plan | 🔒 Locked — A1 first | — |
| T-A3 State file anatomy | 🔒 Locked | — |
| T-B Build VPC by hand | 🔒 Locked | — |
| T-C Hello Terraform | 🔒 Locked | — |
| T-D State, the real secret | 🔒 Locked | — |
| T-E Modules | 🔒 Locked | — |
| T-F Multi-env | 🔒 Locked | — |
| T-G Workload Identity Federation | 🔒 Locked | — |
| T-H Private GKE | 🔒 Locked | — |
| T-I Cloud SQL + KMS | 🔒 Locked | — |
| T-J Rebuild bootstrap from scratch | 🔒 Locked | — |

---

## 💰 Cost discipline (read before touching GCP)

The first time you forget to `terraform destroy` and wake up to a ₹3,000 bill, this section will feel cheap. Set these up **before** Phase T-C.

1. **Billing alerts** — `$5`, `$20`, `$50` on the bootstrap project. Non-negotiable.
2. **GCP free tier** — Bootstrap → T-G can be done at ₹0–₹200/month (VPC, IAM, GCS, Artifact Registry are mostly free).
3. **Real money starts at T-H** — GKE node-hours and Cloud SQL. `e2-small` nodes, `db-f1-micro` Cloud SQL.
4. **The destroy-at-night rule** — End of every learning session: `terraform destroy`. Morning: `terraform apply`. Idle clusters are the #1 way self-learners burn ₹10k for no reason.
5. **One Makefile target** — `make destroy` and `make up`. Build muscle memory. Don't type the full command each time — typing friction = forgetting = cost.

---

## 🧠 The Three-Pass Rule (from Q-PHASE.md, applied here)

For every phase:

- **Pass 1 — Run it.** Just make `apply` succeed. Don't try to understand.
- **Pass 2 — Understand each layer.** What is it? Why is it here? What breaks if I remove it? What are 2 alternatives? *(See Q-PHASE.md Pass 2 questions.)*
- **Pass 3 — Rebuild with modifications.** Take what you built. Make it different (different region, different machine type, add a second subnet). Force yourself to *decide*, not mimic.
- **Pass 4 — Teach it.** Write the village-analogy explanation in your own words. If you can't — you skipped Pass 2.

You only move to the next phase when you've done all 4 passes on the current one. **80% confidence on the gut-check is enough.** 100% is over-optimization.

---

## 🚦 Where to start

**Right now:** Open `00-knowledge-diagnostic.md`. Answer all 10 questions in your own words **before reading the scoring rubric**. Lying to yourself here costs months later.

Then we score together, build the gap map, and unlock Phase T-A.
