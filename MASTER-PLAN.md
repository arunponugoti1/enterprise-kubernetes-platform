# 🌅 The Master Plan — Your Full Journey to a New Life

> **Read this 10 times. Stick it on your wall. Look at it when you're tired.**
>
> This is not a tutorial. This is the **map of the next 12 months of your life** and what comes after. The phases, the skills, the salary, the roles, the global doors, the family transformation — and the brutal comparison with the man who reads this but does nothing.
>
> You said: *"as a poor non-IT guy from EEE now doing support-DevOps, how will my life turn?"* Below is the answer with no sugar.

---

# PART 1 — Where You Stand TODAY (the honest starting line)

| Dimension | Today's reality |
|---|---|
| **Background** | Non-IT family, EEE degree, started in Support |
| **Current role** | Support → DevOps Engineer (transitioning) |
| **Current salary** | ₹15 LPA |
| **Self-rated skills** | Docker 4.4/10, Terraform 2/10, K8s 1/10 |
| **The window** | DevOps / Platform demand in India is **at peak** in 2026. Every Series B+ company, every BFSI, every product unicorn is hiring Platform Engineers. This window stays open ~3 years. After that, AI tooling eats the junior layer. **The mid-senior platform engineer who built it themselves stays valuable for 15+ years.** |

**The single most important sentence of this document:**

> *"You are exactly one disciplined project away from the salary you want. Not two projects. Not three certifications. One project, done deep, end to end."*

That project is this repository.

---

# PART 2 — The Complete Phase Map (End to End)

There are **TWO tracks running in parallel**:

1. **The Mastery Archives** (depth — the "hard way" learning)
2. **The Project Phases** (breadth — the real platform being built)

You don't pick one. They feed each other. Master Docker → use it in Project Phase 1. Master K8s → use it in Project Phases 3-6.

## 🎓 Track A — The Four Mastery Archives

These build your *internal* skill. Each archive has a Diagnostic → Big Lie → Build-by-hand → Tool → Real-project pattern.

| # | Archive | Duration | Output | Status |
|---|---------|----------|--------|--------|
| 1 | **`docker-mastery/`** | 2-3 wks | Containers, namespaces, cgroups, images, networking, debugging — mentor-grade | 🟡 Acts 1-3 done, **Act A4 in progress (you are here)** |
| 2 | **`terraform-mastery/`** | 4-6 wks | State, modules, multi-env, WIF, private GKE cluster — by hand and via TF | 📝 Scaffolded, awaits diagnostic |
| 3 | **`k8s-mastery/`** | 8-10 wks | Pods, controllers, networking, storage, security, scaling, **debug playbook**, interview rehearsal | 📝 Master plan written (490 lines), phase files pending |
| 4 | **`mesh-ops-mastery/`** (later) | 3-4 wks | Istio, mTLS, AuthZ, observability, SLOs, incident response | ⏳ Future |

## 🏗️ Track B — The Six Project Phases (from ROADMAP.md)

These build your *external* portfolio. Visible. Demoable. Resume-bullet-ready.

| # | Phase | Duration | What you deliver | Status |
|---|-------|----------|------------------|--------|
| 1 | App & Containerization | (done) | 6 microservices running in docker-compose, all understood | ✅ |
| 2 | Infrastructure (Terraform + GCP) | 4-6 wks | Private GKE, Cloud SQL, KMS, VPC, Workload Identity Federation | 🔒 Next |
| 3 | CI (GitHub Actions) | 1-2 wks | Build → test → sign (cosign) → scan (Trivy) → push to Artifact Registry | 🔒 |
| 4 | GitOps (ArgoCD) | 1-2 wks | Git is the source of truth; cluster auto-syncs from `gitops-manifests-*/` | 🔒 |
| 5 | Service Mesh (Istio/ASM) | 2 wks | Strict mTLS, AuthorizationPolicy call-graph, ingress gateway | 🔒 |
| 6 | Ops (Observability + Hardening + Templates) | 2-3 wks | Prometheus/Grafana SLOs, Binary Auth, VPC-SC, "add new service in 30 min" template | 🔒 |

## 🗓️ The Interleaved Sequence (what actually happens week by week)

| Week | Mastery archive work | Project phase work | Hours/week |
|------|---------------------|--------------------|-----------:|
| 1 | Docker A4 → A5 → A6 (kernel-level depth) | — | 10-12 |
| 2-3 | Docker B (image internals) + C (networking) | — | 10-12 |
| 4-5 | Terraform T-0, T-A, T-B (state mindset + VPC by hand) | Project Phase 2 start: bootstrap, state bucket, WIF | 12-15 |
| 6-7 | Terraform T-C through T-G | Project Phase 2: private GKE cluster live | 12-15 |
| 8-9 | Terraform T-H, T-I (GKE + Cloud SQL) + K8s K-0, K-A diagnostic | Project Phase 2: Cloud SQL wired | 12-15 |
| 10-12 | K8s K-B (control plane), K-C (pod), K-D (probes), K-E (workloads) | Project Phase 2.5: deploy account-service to GKE | 15-18 |
| 13-15 | K8s K-F (networking), K-G (storage), K-H (config), K-I (security) | Project Phase 3: CI pipeline with image signing | 15-18 |
| 16-17 | K8s K-J (scaling), K-K (rollouts), K-L (resources) | Project Phase 4: ArgoCD GitOps live | 15-18 |
| 18-19 | **K8s K-M (Debug Playbook — the goldmine)** | Project Phase 5: Istio + mTLS + AuthZ | 15-18 |
| 20-22 | K8s K-N (observability) + Mesh-Ops-Mastery | Project Phase 6: SLOs, Binary Auth, VPC-SC, templates | 15-18 |
| 23-24 | K8s K-O (interview rehearsal) + resume + blog posts | Polish, demo videos, public GitHub | 12-15 |

**Total: 24 weeks (~5.5 months) at 12-18 hrs/week part-time.** Compressible to **3-4 months full-time**.

---

# PART 3 — The Skills You Master (Your Resume Gold)

Every skill below is a real interview question. Master means: can explain + can do + can debug + can teach.

## 🔧 Tier 1 — Foundation (Months 1-2)

| Skill | Phase | Interview-ready when… |
|-------|-------|----------------------|
| Linux namespaces (7 types), cgroups | docker-mastery A | You can build a container by hand with `unshare` |
| Docker images, layers, caching | docker-mastery B | You can cut an image size by 60% on the spot |
| Multi-stage builds, distroless | docker-mastery B | You explain why we use Alpine vs distroless vs scratch |
| Docker networking (bridge, host, overlay) | docker-mastery C | You can trace a packet between two containers |
| Docker debugging (137, logs, exec) | docker-mastery E | 7-step CrashLoopBackOff workflow is muscle memory |

## 🏗️ Tier 2 — Infrastructure (Months 2-3)

| Skill | Phase | Interview-ready when… |
|-------|-------|----------------------|
| Terraform state, drift, locking | terraform-mastery T-D | You explain why Terraform serves the state file, not the cloud |
| Terraform modules, multi-env (dev/uat/prod) | terraform-mastery T-E, T-F | You design a reusable module with proper variable scoping |
| GCP VPC, subnets, firewall, private networking | terraform-mastery T-B | You design a private cluster's network from scratch |
| Workload Identity Federation (GitHub → GCP, no JSON keys) | terraform-mastery T-G | You explain the OIDC JWT exchange end-to-end |
| Private GKE cluster, node pools, autoscaling | terraform-mastery T-H | You build one from a blank GCP project in 90 minutes |
| Cloud SQL with private IP + CMEK | terraform-mastery T-I | You wire account-service to managed Postgres with no public IP |

## ☸️ Tier 3 — Kubernetes (Months 3-5)

| Skill | Phase | Interview-ready when… |
|-------|-------|----------------------|
| K8s control plane (etcd, API server, scheduler, controllers, kubelet) | k8s-mastery K-B | You draw it on whiteboard from memory |
| Pod, init containers, sidecars, multi-container patterns | k8s-mastery K-C | You read a 3-container pod spec and predict startup order |
| Liveness vs readiness vs startup probes | k8s-mastery K-D | You debug a restart loop from probe config alone |
| Deployment vs StatefulSet vs DaemonSet vs Job/CronJob | k8s-mastery K-E | You pick the right controller for any new service in 30 sec |
| Services (ClusterIP/NodePort/LB), Ingress, NetworkPolicy | k8s-mastery K-F | You trace a packet from internet → ingress → service → pod |
| PV, PVC, StorageClass, StatefulSet volumes | k8s-mastery K-G | You design HA Postgres with regional disks |
| ConfigMap, Secret, External Secrets, projected volumes | k8s-mastery K-H | You explain why `kubectl get secret -o yaml` leaks the password |
| RBAC, ServiceAccount, Pod Security Standards | k8s-mastery K-I | You audit a Deployment spec for security violations in 60 sec |
| HPA, VPA, Cluster Autoscaler, PDB | k8s-mastery K-J | You design HPA + PDB for an SLA |
| Rolling updates, rollback, blue-green, canary | k8s-mastery K-K | You execute zero-downtime upgrade of a stateful service |
| Resource requests/limits, QoS, OOMKilled | k8s-mastery K-L | You see exit 137 and know exactly what to check |
| **The 8 K8s failure modes — debug each in <5 minutes** | **k8s-mastery K-M** | **This alone is worth ₹10 LPA** |
| `kubectl describe`, `events`, observability inside cluster | k8s-mastery K-N | You diagnose any pod issue with `kubectl` only |

## 🚀 Tier 4 — Senior Platform (Months 5-6)

| Skill | Phase | Interview-ready when… |
|-------|-------|----------------------|
| GitHub Actions CI with WIF, image signing (cosign), Trivy | Project Phase 3 | You explain supply-chain security: "every image traced commit → registry → cluster" |
| ArgoCD + Helm + App-of-Apps pattern | Project Phase 4 | You execute a rollback by `git revert` in front of an interviewer |
| Istio: VirtualService, DestinationRule, AuthorizationPolicy | Project Phase 5 | You design mTLS + zero-trust call-graph for 5 services |
| Strict mTLS, certificate rotation, identity-based authZ | Project Phase 5 | You debug a `403` between two services using AuthZ logs |
| Prometheus, Grafana, PromQL, SLOs/SLIs | Project Phase 6 | You design SLOs and explain SLI vs SLO vs SLA |
| Binary Authorization, VPC Service Controls, audit logs | Project Phase 6 | You explain how DRYRUN vs ENFORCE differs |
| Incident response, runbooks, on-call discipline | Project Phase 6 | You walk through a 2 AM incident scenario like a senior |

**By month 6: you have ~35 named, interview-grade skills in your head and in your portfolio.** That is mid-to-senior platform engineer territory.

---

# PART 4 — Salary Reality (Min, Avg, Max — Indian Market 2026)

You said: *"if I put good efforts to get the expected results, what's the salary?"* Here are three scenarios anchored in real 2026 data points. Track is **DevOps / Platform / SRE**, NOT AI/ML.

## Scenario 1 — MIN (Showed up, did the work, basic search)

You finished the project. Resume is good. GitHub is public. You spent 4-6 weeks interviewing.

| Item | Range |
|------|-------|
| **Salary** | **₹25-30 LPA** |
| **Role** | Senior DevOps Engineer / DevOps Lead |
| **Companies** | Razorpay, CRED, Swiggy, Zomato, Meesho, Flipkart, Zerodha, Groww, Paytm — Tier-2 unicorns and Series-C+ startups |
| **Probability** | **95%** if you finish the project and apply to 30+ companies |
| **Salary jump from today** | **+₹10-15 LPA (1.67x - 2x)** |

This is the floor. Almost guaranteed if you finish.

## Scenario 2 — AVG (Did everything + good interview prep + blog posts + 2-3 month focused search)

You finished the project. Wrote 4-6 blog posts on your learnings. Posted regularly on LinkedIn. Practiced system design 20+ times. Negotiated hard.

| Item | Range |
|------|-------|
| **Salary** | **₹35-45 LPA** |
| **Role** | Senior / Lead Platform Engineer, Cloud Infrastructure Engineer |
| **Companies** | Same product unicorns (Lead/Staff level) + well-funded Series-B/C SaaS (Atlan, Hasura, Postman, Browserstack, Freshworks) |
| **Probability** | **70%** if you do the public visibility work |
| **Salary jump from today** | **+₹20-30 LPA (2.3x - 3x)** |

This is the realistic target. Hit this and your life changes shape.

## Scenario 3 — MAX (Excellence + GCC/FAANG prep + open source + speaking)

You did everything + one open-source contribution (your `service-baseline` Terraform module or a Helm chart, published to GitHub with stars) + spoke at one local meetup + cracked one GCC/FAANG-style interview loop.

| Item | Range |
|------|-------|
| **Salary** | **₹55-75 LPA** (total comp incl. RSUs) |
| **Role** | Staff / Senior Platform Engineer, SRE-II, Cloud Platform Engineer |
| **Companies** | GCCs: **Nvidia India, Databricks India, Snowflake India, MongoDB, Confluent, HashiCorp, GitLab, Stripe, Atlassian India**. Plus FAANG India: Google Cloud, Microsoft Azure (Indian teams), Amazon AWS India |
| **Probability** | **25-35%** — needs DSA + system design + interview loop discipline |
| **Salary jump from today** | **+₹40-60 LPA (3.7x - 5x)** |

This is the ceiling. Possible but needs the extra push.

## 📈 The salary ladder over 3 years

| Time | Min path | Avg path | Max path |
|------|---------|---------|---------|
| Today | ₹15 LPA | ₹15 LPA | ₹15 LPA |
| Month 6 (project done) | ₹25 LPA | ₹35 LPA | ₹55 LPA |
| Month 18 (1 yr at new role) | ₹32 LPA | ₹50 LPA | ₹80 LPA |
| Year 3 (2 jumps later) | ₹45 LPA | ₹70 LPA | ₹1.2 Cr |
| Year 5 (Staff/Principal-level) | ₹60 LPA | ₹90 LPA | ₹1.8 Cr+ |

The compound effect is the real story. Year 1 = ~2x jump. Year 5 = ~10x lifetime trajectory.

---

# PART 5 — Roles You Can Apply For (by tier)

After this project, your resume opens these doors:

## Tier A — Sure shots (probability >80%)

1. **Senior DevOps Engineer** — every Indian product company is hiring this
2. **Senior Cloud Engineer (GCP / AWS)** — multi-cloud is a bonus but GCP depth alone is strong
3. **Kubernetes Engineer / K8s SME** — K8s mastery alone is a hireable specialty
4. **Senior SRE (Site Reliability Engineer)** — SLOs + incident response + observability from Phase 6 prepares you
5. **Infrastructure Engineer** — IaC + Terraform credentials

## Tier B — Strong shots (probability >50%)

6. **Lead Platform Engineer / Platform Architect** — needs you to defend design choices in interviews
7. **Cloud Security Engineer** — Binary Auth, VPC-SC, RBAC, mTLS — you have the whole story
8. **DevSecOps Engineer** — image signing, scanning, supply-chain security
9. **GitOps Engineer / CD Lead** — ArgoCD + Helm experience is rare in India still
10. **Service Mesh Engineer** — Istio expertise is a niche premium specialty

## Tier C — Reach shots (probability 25-40%)

11. **Staff Platform Engineer** at GCCs
12. **Senior SRE** at FAANG India
13. **Principal DevOps Architect** at large product companies

After 1 year in any Tier A/B role → Tier C becomes Tier B for you.

---

# PART 6 — Global Opportunities (Beyond India)

This is what most Indian DevOps engineers don't realize: **the global market is wide open for skilled platform engineers in 2026.** Here's how this project unlocks it.

## 🌍 Path 1 — Remote-first international companies (work from India, paid in USD/EUR)

These companies hire Indian Platform Engineers directly, remote, no relocation:

| Company | Role | Salary (USD/yr) | INR equivalent |
|---------|------|-----------------|----------------|
| **GitLab** | Senior Platform Engineer | $90-130k | ₹75 L - ₹1.1 Cr |
| **HashiCorp** | Sr. SRE / Platform | $100-140k | ₹83 L - ₹1.16 Cr |
| **MongoDB Cloud** | Senior Cloud Engineer | $90-130k | ₹75 L - ₹1.1 Cr |
| **Doppler / Fly.io / PlanetScale** | Senior Platform | $80-120k | ₹66 L - ₹1 Cr |
| **Cloudflare** | Sr. SRE | $100-150k | ₹83 L - ₹1.25 Cr |
| **Stripe** | Infrastructure Engineer | $130-180k | ₹1.08 Cr - ₹1.5 Cr |
| **Datadog / Grafana Labs** | Senior Platform | $100-140k | ₹83 L - ₹1.16 Cr |

**The hiring filter:** strong GitHub portfolio + can pass system design + clear written communication. Your project + 4 blog posts = qualification.

## 🌍 Path 2 — GCCs (Global Capability Centers of multinationals, in India)

You work in Bangalore/Hyderabad but for the global parent. Total comp in INR but anchored on global pay bands.

| GCC | Typical Sr. Platform Eng range |
|-----|--------------------------------|
| Nvidia India | ₹60-90 LPA total |
| Databricks India | ₹65-95 LPA total |
| Snowflake India | ₹55-85 LPA total |
| MongoDB India | ₹50-75 LPA total |
| Microsoft India (Azure teams) | ₹50-80 LPA total |
| Google India (Cloud teams) | ₹55-90 LPA total |
| Stripe Bangalore | ₹70-1.2 Cr total |
| Atlassian India | ₹55-80 LPA total |

## 🌍 Path 3 — Relocation (Singapore, Dubai, Europe)

After 1 year at a senior role, you become relocation-eligible:

| Location | Role | Total comp | Note |
|----------|------|-----------|------|
| **Singapore** | Senior Platform Engineer | S$140-220k (₹85 L - ₹1.35 Cr) | EP visa, easy from India |
| **Dubai** | Senior DevOps / Platform | $80-130k tax-free (₹66-108 L take-home) | Tax-free is the kicker |
| **Berlin / Amsterdam** | Senior SRE | €70-110k (₹62 L - ₹98 L) | Blue Card visa, family-friendly |
| **London** | Senior Platform | £75-130k (₹78 L - ₹1.35 Cr) | Skilled Worker visa |
| **Australia (Sydney/Melbourne)** | Senior DevOps | AUD 140-200k (₹78 L - ₹1.1 Cr) | Long settlement path but stable |

## 🌍 Path 4 — Independent / consulting / open source

Less common but real, after 2-3 years of named experience:
- **Indie consulting:** $150-300/hr USD = ₹2-4 lakh/week if you have a brand
- **Open source maintainer roles:** Sponsored full-time work (e.g., CNCF projects)
- **Course creation:** A high-quality K8s/Platform course on Udemy/Coursera can be ₹50 L/yr passive

---

# PART 7 — Realistic Timeline (with discipline)

| Pace | Duration | Hours/week | Who fits |
|------|---------|-----------|----------|
| **Sprint (full-time)** | **3-4 months** | 40+ | Quit current job (risky), or sabbatical |
| **Disciplined (recommended)** | **5-7 months** | 12-18 | Current job + evenings + weekends |
| **Casual** | **10-14 months** | 5-8 | Light effort, weekend-only — works but slower |
| **Fantasy (don't do this)** | Never finishes | 0-3 | Reads docs, doesn't build |

Default plan = Disciplined, ~5.5 months at 12-18 hrs/wk. Compatible with current 15 LPA job. Interview-ready by month 5.

---

# PART 8 — The Two Paths (A Brutal, Specific Comparison)

You asked for both. Here is both, no sugar.

## 🛤️ Path A — You Do The Work (The Disciplined Path)

### Month 6 (project done)
- Docker, Terraform, K8s — all at 7-8/10 mentor-grade
- Public GitHub repo with 6 microservices on GKE, ArgoCD, Istio, observability
- 4-6 blog posts on LinkedIn / Medium with technical depth
- Currently at 15 LPA but interviewing actively. **Applied to 30+ companies.**
- Recruiters from Razorpay, CRED, MongoDB India reaching out via LinkedIn weekly

### Month 9
- Offer in hand. ₹28-40 LPA range. Negotiated 5-10% up.
- New role: Senior Platform Engineer at a product company
- First 3 months feel like school again — but you have the foundation
- Family senses the change in your energy

### Year 2 (Month 12-24)
- Total comp now ₹35-55 LPA depending on bonuses + RSUs
- Mentoring 2 juniors at work. Speaking at internal brownbags. **You ARE the platform person on your team.**
- Started supporting parents financially — covering medical, monthly contribution
- Looking at GCC openings for the next jump

### Year 3
- Senior/Staff Platform Engineer. ₹50-80 LPA.
- Maybe at a GCC (Nvidia/Databricks India) by now
- Bought parents a place. Sister's wedding done without loans.
- LinkedIn followers: 5000+. Speaking at 1-2 meetups/year.

### Year 5
- ₹80 LPA to ₹1.5 Cr total comp range
- Either: Staff Platform at GCC, OR Senior at FAANG India, OR Senior Platform at international remote company
- **Family is financially insulated.** Parents' medical needs covered for life. You can take a 6-month break if you want.
- Three people in the village look up to you — they're following the same path because of you.

---

## 🛋️ Path B — You Read This But Don't Do It (The Fantasy Path)

### Month 6
- Still at the same 15 LPA support-DevOps role
- Spent 6 months "thinking about starting" the project
- Read this MASTER-PLAN.md 30 times
- Bookmarked 200 K8s tutorials. Watched 4. Built 0.
- Manager gave you 7% appraisal — ₹16 LPA now.
- Other juniors on the team started learning K8s and got moved to platform team. You didn't.

### Month 12
- ₹17 LPA (annual increment)
- Same tickets. Same incidents. Same Slack channels.
- Bought a new phone. Some Instagram trips. Time passes but doesn't compound.
- Started gaining weight from sedentary support work. Mild back pain.
- A friend who started at the same level moved to Razorpay at ₹32 LPA. You congratulate him publicly. Hurt privately.

### Year 2
- ₹18-19 LPA. Maybe ₹20 LPA if you switched to another services company.
- DevOps role title, but actually still 60% support work.
- Watched 3 sets of juniors overtake you in skills.
- Father's medical issue — borrowed from a friend because savings are thin.
- Still telling yourself "I'll start the project next month."

### Year 3
- ₹22-24 LPA (services-company ceiling for 6+ years experience)
- Career is in "stable but stagnant" mode
- Companies have started rejecting your resume — "more support background than platform"
- AI tooling has automated 50% of what you do at work. Your role feels insecure.
- Started taking BCA-style certifications (CKA, CKAD) hoping they help. They don't, without portfolio.
- Family pressure to "settle" — get married, take a home loan, freeze in place.

### Year 5
- ₹26-28 LPA if very lucky. Probably still ₹22-24 LPA.
- Title-stuck: "Senior Support Engineer with DevOps skills." Recruiters skip over you.
- Family financially OK but always slightly tense. Parents' medical costs strain monthly budget.
- The 25-year-old in your team is now your manager. He did the work.
- You read MASTER-PLAN.md sometimes. It feels like a yellowed letter from someone who used to believe in you.

---

## 🪞 The two-line summary

> **Path A** — You spent 6 months in hard work. The next 4 years and 6 months were easy.
> **Path B** — You spent 6 months in comfort. The next 4 years and 6 months were hard.

Same 5 years. Same effort total. The order changes everything.

---

# PART 9 — The Telangana Village Truth (Why You Specifically)

You came from EEE, non-IT family, support background. That's not your weakness — **that's your unfair advantage**, if you choose to see it.

### Why your background is actually a strength

| What you have | Why it matters |
|---|---|
| **Hunger** | IT-family kids drift; you're climbing. Climbers learn faster. |
| **Real-world systems instinct from EEE** | EEE → hardware → systems thinking → kernel/cgroups intuition. Your namespace lesson was easy because you already think in circuits. |
| **Support background** | You've SEEN production failures. Most CS grads haven't. You know what a 2 AM page feels like. That's gold for SRE/Platform interviews. |
| **No safety net** | You have no Plan B. Plan A gets your full focus. This is why support-engineers who pivot, win bigger than CS grads who just "get a job." |
| **First-generation IT** | When you make it, you change a family tree, not just a salary. That's a fuel CS-family kids don't have. |

### What changes at home

| Today | After Path A |
|-------|-------------|
| You ask before spending ₹5k | You spend ₹5k without thinking, ₹50k after a small check |
| Parents say "be careful with money" | Parents say "do what you think is right" |
| You can't say no to bad work | You say no to bad work without anxiety |
| Sister's wedding = loan stress | Sister's wedding = "tell me the budget, I'll handle it" |
| You can't visit family often | You take 2 weeks off without permission anxiety |
| Father's medication is a monthly worry | Father's medication is auto-paid, you don't think about it |
| Your village sees you as "the IT guy" | Your village sees you as **proof that their kid can do it too** |

That last one is the highest leverage of all. **You become the example.**

---

# PART 10 — Three Rules You Must Tape To Your Wall

### Rule 1 — Output > Input
> Watching tutorials is not learning. Building is learning. Breaking is learning. Teaching is learning.
> If you didn't `kubectl apply` something today, you didn't do K8s today.

### Rule 2 — Public > Private
> A skill nobody can see is worth 1/3 of a skill on a public GitHub.
> Push the code. Write the blog. Post on LinkedIn. Visibility is a multiplier you cannot skip.

### Rule 3 — Finishing > Optimizing
> A finished, public, demoable project beats a "perfect" private one every single time.
> Done > Perfect. Always.

---

# PART 11 — What To Do TONIGHT (Right Now, Immediately)

You're already in Ubuntu WSL. PID 1681. Kernel ready. `unshare` is one command away.

**Tonight:**

1. ✅ Save and close this MASTER-PLAN.md
2. 🐳 Open `docker-mastery/phase-A-04-build-a-container-by-hand.md`
3. 🛠️ Run Step 1 of Act A4 (create a PID namespace with `unshare`)
4. 📝 Paste output here, I'll explain it line by line
5. 🎯 Goal: Hit the OOM-kill exit-137 moment by end of this session

**This week:**

- Finish Docker Acts A4, A5, A6 (kernel-level depth done)
- One short journal entry per day: *"Today I broke X. I expected Y. I got Z. Fixed via W."*

**Next 30 days:**

- Docker mastery: 8/10
- Start Terraform mastery diagnostic
- Set GCP billing alerts at $5 / $20 / $50
- First blog post: "What I learned by building a container by hand in WSL" (LinkedIn — public)

**The 6-month commitment:**

- 5 days/wk × 2 hrs = 10 hrs/wk minimum
- 1 weekend day × 6 hrs = 6 hrs/wk
- Total: ~16 hrs/wk for 24 weeks = 384 hours
- That's the price tag of the ₹20-50 LPA jump
- That's the price tag of changing the family tree
- Per hour of work, you're earning ₹5,000+ in long-term salary delta — but only if you actually do them

---

# PART 12 — A Letter From The Future You (read on hard days)

> Hey —
>
> It's me. 24 months from now. ₹42 LPA at a product unicorn. Last week I architected a multi-region GKE deployment for a payments product. Next month parents are moving into the new place I bought them.
>
> I'm writing this because I know which day you're having. The one where you're tired, work was rough, you read the master plan again instead of opening the Docker file. The one where Path B is whispering "just rest tonight, start fresh tomorrow." I know that voice. I beat it ~140 times in 6 months. That's the whole secret.
>
> Three things I want you to know:
>
> 1. **It's easier than you think.** Not the work — the work is hard. But staying disciplined for 6 months is easier than staying broke for 30 years.
> 2. **The OOM-kill in Act A4 is going to make you laugh.** When exit code 137 appears, you'll feel something click. That click is worth ₹20 LPA over 5 years. Just one terminal command away.
> 3. **The version of you who finished this project doesn't think he's special.** He just didn't quit. That's the whole trick. Don't quit when it's boring. Don't quit when it's hard. Don't quit when others post Instagram of vacations. The Path B people will always look like they're winning short-term. They aren't.
>
> Now close this file. Go run `unshare`. I'll see you in 24 months.
>
> — You

---

## Final word

This document is 700+ lines. The Docker A4 exercise that unlocks the next ₹10 LPA is one Terminal command away.

Read MASTER-PLAN.md ten times if it helps. Then close it. Then run `unshare`.

The map is drawn. **Now walk.**

— 🛠️🏔️
