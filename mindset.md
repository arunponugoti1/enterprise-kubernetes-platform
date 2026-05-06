# The DevOps & Platform Engineer Mindset

To transition from **Support** to **Platform Engineering**, use this guide to evaluate every file and resource in this project.

# How These Questions Build Real Engineering Instinct

---

## What each question actually trains in your brain

**Q1 — "Why does this file exist?"**
Trains you to see **purpose, not syntax**. In an enterprise repo with 5,000 files, you can't read everything. You learn to spot which files carry weight and which are scaffolding. When troubleshooting: you stop chasing red herrings because you instantly know what a file is *for*.

**Q2 — "Who owns it?"**
Trains you to think in **ownership boundaries**. This is the #1 thing that separates juniors from seniors. Most production incidents happen at boundaries — Terraform vs ArgoCD, app vs platform team, dev vs SRE. When troubleshooting: you stop editing the wrong file. When contributing: you submit your PR to the right repo and the right reviewers.

**Q3 — "What depends on what?"**
Trains you in **blast radius thinking**. Before you change anything, you mentally simulate the explosion. Enterprises pay senior engineers for exactly this — the ability to say "if we touch this, those 12 things move." When troubleshooting: you trace the failure upstream instead of patching symptoms.

**Q4 — "Where do secrets/config come from?"**
Trains you in **runtime reality vs static code**. Code in git is half the story; the other half is what's injected when it runs. 80% of "it works on my machine" is a config-injection mismatch. When troubleshooting: you check the actual env in the running pod, not the YAML in git.

**Q5 — "How does it fail?"**
Trains you in **observability-first design**. Enterprise systems don't fail cleanly — they fail weirdly. If you can't predict the log line, you can't grep for it at 2 AM. When troubleshooting: you go straight to the right dashboard, the right log filter, the right alert — instead of fishing for 30 minutes.

**Q6 — "Could a new engineer change this safely?"**
Trains you in **empathy and guardrails**. Enterprise code is read 100x more than written. If a file is fragile, you write the test, the comment, the validation — *before* it bites someone. When contributing: your PRs get merged faster because reviewers trust the safety nets.

**Q7 — "Explain in 30 seconds to your manager"**
Trains you in **abstraction and communication**. The hardest interview question is "what does your team do?" If you can't compress a file's purpose into a sentence, you don't own it — you're a bystander. When contributing in standups, design reviews, incident calls: you sound senior because you *speak in outcomes*, not lines of code.

---

## The 3 Psychological Checks — what they unlock

**A. "Why not the obvious thing?"**
Forces you to learn **the road not taken**. Every codebase is full of decisions that look weird until you know the alternative was worse. This is how you stop saying "this is dumb" in code reviews and start saying "I see why they did this — but here's a case they missed." That's the exact moment people start treating you as a peer, not a junior.

**B. "What would change in prod?"**
Forces you to think in **environments**, not snapshots. Dev, staging, prod aren't copies — they're the same code under different pressures. When troubleshooting prod-only bugs (the worst kind), you already know the diff in your head: "Oh, prod has CMEK locked, dev doesn't — that's the permission error."

**C. "What's the embarrassing failure?"**
Forces you to think like an **attacker, an auditor, and a customer simultaneously**. This is the meta-skill. Enterprises pay for engineers who lose sleep over silent failures: data corruption, leaked PII, audit gaps. When contributing: you add the guard, the audit log, the alert *before* compliance catches it. That's the engineer who gets promoted.

---

## How this maps to real enterprise work

| Situation | Without these questions | With these questions |
|-----------|------------------------|----------------------|
| **Onboarding** to a new repo | Lost for 3 weeks reading code | Map the system in 3 days by reading 20 files |
| **Incident at 2 AM** | Panic-grep the codebase | Open the 2 files you suspect, answer Q5, find it |
| **Code review** | Comment on style | Comment on contracts, blast radius, failure modes |
| **Design review** | Stay quiet | Ask Q3 + check A — sound like an architect |
| **Your own PR** | Hope it gets merged | Pre-answer Q6 — reviewers can't push back |
| **Promotion case** | "I closed 50 tickets" | "I owned this subsystem and these are the decisions I made" |

---

## The compounding effect

Day 1: You ask the questions and feel slow.
Week 2: You ask them silently while reading.
Month 2: You ask them *while writing* — your code answers them by default.
Month 6: You ask them *of other people's PRs* — and they start asking themselves.

That's when you stopped being a contributor and became a force multiplier.
That's the platform engineer.

---

**The shortcut:** every senior engineer you respect already does this in their head in 5 seconds. They didn't learn it from a doc — they learned it from getting burned 50 times. You're using these questions to **steal the lesson without taking the burn.**

==============

## 1. The Three Questions (Every File)
1. **The Contract:** What does this need (inputs/env) and what does it provide (outputs/ports)?
2. **The Failure Mode:** If this fails, what does the error look like in the logs? How does it self-heal?
3. **The Portability:** How much of this is "Standard" vs "Cloud Provider Specific"?

## 2. Takeaways by File Type

### 📂 Source Code (`.js`, `.py`, etc.)
- **Integration Points:** How does it talk to DBs or APIs?
- **Config Injection:** Look for `process.env`. Never hardcode secrets.
- **Health Checks:** Is there a `/healthz` (liveness) and `/readyz` (readiness) endpoint?

### 🐳 Dockerfiles
- **Security:** Does it run as a non-root user?
- **Efficiency:** Is it a multi-stage build? Is the final image small?
- **Immutability:** Does the image contain everything it needs to run without external downloads?

### 🏗️ Terraform (`.tf`)
- **Least Privilege:** Does the IAM role have only the bare minimum permissions?
- **State:** How is the "truth" of the infrastructure stored?
- **Reusability:** How do we use the same code for Dev, UAT, and Prod?

### ☸️ Kubernetes & Helm (`.yaml`)
- **Resource Limits:** Are CPU and Memory limits defined to prevent cluster crashes?
- **Networking:** How does traffic flow from the User -> Gateway -> Service -> Pod?
- **Scaling:** What triggers a Horizontal Pod Autoscaler (HPA)?

## 3. Core Concepts
- **Statelessness:** If I delete a Pod, no data should be lost (data lives in the DB).
- **Observability:** Can I diagnose a problem using only Logs and Metrics?
- **Idempotency:** If I run this command twice, does it stay in the correct state without breaking?
- **GitOps:** Git is the single source of truth. If it's not in Git, it's a "ghost" resource.

---
*Support sees the symptoms. DevOps builds the immune system.*


=========
# Platform Engineer Mindset — Daily Driver

> Support sees symptoms. Platform builds the immune system.
> Read this every morning. Pick one section, apply it to one file you touched today.

---

## The 3 Questions — ask them about every file

1. **Contract** — what inputs does it need, what does it expose?
2. **Failure mode** — when it breaks, what's the log line, and how does it self-heal?
3. **Portability** — what's standard vs. cloud-locked? Could I move it in a week?

---

## Per-file checklist

### 📂 Source code
- [ ] Config from env vars, never hardcoded
- [ ] Secrets injected at runtime, never in image
- [ ] `/health` (liveness) + `/ready` (readiness) exist and mean different things
- [ ] Stateless — kill the pod, lose nothing

### 🐳 Dockerfile
- [ ] Multi-stage build, final image < 200 MB
- [ ] Runs as non-root (`USER 1000`)
- [ ] Pinned base image digest, no `:latest`
- [ ] No `apt-get` at runtime — image is fully self-contained

### 🏗️ Terraform
- [ ] IAM is least privilege — every role defended in review
- [ ] State is remote, encrypted (CMEK), versioned
- [ ] Same module runs dev/uat/prod — only `tfvars` differ
- [ ] `prevent_destroy` on anything that holds data

### ☸️ Kubernetes / Helm
- [ ] CPU + memory `requests` and `limits` set
- [ ] HPA + PDB + topology spread defined
- [ ] NetworkPolicy default-deny in the namespace
- [ ] `readOnlyRootFilesystem: true`, `runAsNonRoot: true`, drop ALL caps

---

## 4 core principles (memorize)

| Principle | One-line test |
|-----------|--------------|
| **Statelessness** | Can I `kubectl delete pod` without losing data? |
| **Observability** | Can I diagnose using only logs + metrics + traces? |
| **Idempotency** | Does running it twice end in the same state? |
| **GitOps** | If it's not in git, it doesn't exist. |

---

## Self-test (no peeking — answer aloud)

### Beginner — you should know these in week 1
1. What's the difference between liveness and readiness probes? Give a scenario where one passes and the other fails.
2. Why does a container run as a non-root user? What happens if it doesn't?
3. What does `terraform plan` do that `terraform apply` doesn't?
4. Why is `:latest` an anti-pattern in Kubernetes manifests?
5. A pod is `CrashLoopBackOff`. Name three commands you'd run, in order.

### Intermediate — you should know these in month 1
6. What is Workload Identity and why is it better than mounting a service account JSON key?
7. Explain the GitOps reconciliation loop. What happens if I `kubectl edit` a resource ArgoCD manages?
8. Why do we put a `PodDisruptionBudget` on a service that has an HPA?
9. What's the blast radius of a leaked CI service account key in our setup? What limits it?
10. CMEK vs Google-managed encryption — when does the difference actually matter?

### Advanced — you should be able to defend these in design review
11. Walk through how a request from the internet reaches `account-service`. Name every hop and what enforces security at each one.
12. Cloud SQL primary fails at 03:00. What happens, in what order, and what's the customer-visible impact?
13. Someone pushes an image with a HIGH CVE. Name every gate that should stop it before it runs in dev.
14. How would you onboard a new microservice in under a day? List the artifacts that must exist before traffic flows.
15. Our SLO is 99.9% availability. We've burned 80% of the monthly error budget on day 10. What do you do?

### Trap questions — these expose weak mental models
16. Why is `kubectl apply` not idempotent in all cases? (Hint: think about field ownership.)
17. If both Terraform and ArgoCD manage Kubernetes resources, who owns what — and how do you decide?
18. We enabled Binary Authorization in `DRYRUN` mode. What does that actually prevent? What does it not?
19. A Slack alert fires for high p99 latency, but Grafana shows latency is fine. Name three reasons this can happen.
20. We have backups. Are we sure we can restore? How do we know?

---

## Daily ritual

**Morning (5 min):** read this file. Pick one checklist item.
**During work:** apply it to one PR or file you touch.
**End of day (2 min):** answer one question above. If you stumbled, mark it and revisit tomorrow.

After 30 days, you don't read this — you live it.
