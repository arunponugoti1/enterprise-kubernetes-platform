# 🔒 MY TERRAFORM ROADMAP — LOCKED BLUEPRINT

> **Status:** 🔒 LOCKED — Do not deviate without re-running diagnostic
> **Created:** 2026-05-19
> **Based on:** Diagnostic score 69/100 (Confident Intermediate)
> **Supersedes:** Default README.md phase order (which is for 0-3/10 beginners)

---

## ⚠️ Read This First

This blueprint **overrides** the linear T-A → T-J path in `README.md`.

**Why?** The README's own gap-map table says:

| Score | What to do |
|-------|------------|
| 0-3/10 | Start T-A1, slow and steady |
| 3-5/10 | T-A1, move fast through T-B |
| **5-7/10** | **"T-D and T-G are your real gaps"** ← I scored 6.9 here |
| 7-8/10 | Skip to T-H/T-I |

I am a **Confident Intermediate**. I've already shipped Terraform in `infra/bootstrap/`. Doing "manual VPC in console" (T-B) and "Hello Terraform" (T-C) is beneath my level. The README tells me to skip them.

---

## 📊 Diagnostic Recap

| Section | Score | Gap |
|---------|-------|-----|
| Easy (Q1-3) | 20/30 (67%) | Provider examples, "why plan exists" depth |
| Medium (Q4-7) | 33/40 (83%) | GCP specifics on VPC, module inputs/outputs |
| Hard (Q8-10) | 16/30 (53%) | **State toolbox (Q8), WIF (Q9), apply internals (Q10)** |
| **Total** | **69/100** | — |

**My 3 real gaps (in order):**
1. **WIF** (Q9: 4/10) — I don't know how OIDC trust handshake works
2. **State toolbox** (Q8: 7/10 concept, 0/10 commands) — Don't know `refresh`, `import`, `state mv/rm`
3. **Apply internals + update strategies** (Q10: 5/10) — Don't know in-place vs destroy+recreate

---

## ✂️ What I'm Skipping (and Why)

| Phase | Skip? | Reason |
|-------|-------|--------|
| T-A1 (Big Lie) | ❌ Read it | 30-min cheap win — file already exists |
| T-A2 (Providers + Plan) | ⏭️ Skip standalone | Fold into T-D when I need it |
| T-A3 (State anatomy) | ⏭️ Skip standalone | I'll open `tfstate` during T-D |
| **T-B (Manual VPC)** | ⏭️ **SKIP** | I've already shipped Terraform — beneath my level |
| **T-C (Hello Terraform)** | ⏭️ **SKIP** | Same reason — kindergarten phase |
| T-D (State mastery) | ✅ DO | My real gap #2 |
| T-E (Modules) | 🔄 Learn in context | Will emerge naturally during T-H |
| T-F (Multi-env) | 🔄 Learn in context | Will emerge naturally during T-H |
| T-G (WIF) | ✅ DO | My real gap #1 |
| T-H (Private GKE) | ✅ DO | The real goal |
| T-I (Cloud SQL + KMS) | ✅ DO | account-service migration needs this |
| T-J (Rebuild bootstrap) | ✅ DO | Graduation exercise |

---

## 🚀 The Compressed Path — 4 Stages, ~6-7 Sessions

### **Stage 1: Mindset Lock (1 session, ~30 min)**
- Read `phase-T-A-01-the-big-lie.md`
- Recite the mandi register analogy out loud
- Answer the 4 self-check questions in own words
- **Done when:** I can explain "Terraform serves state, not cloud" in one sentence

### **Stage 2: State Mastery (T-D) — Hands-on (1-2 sessions)**
- Move local state → GCS backend (remote state)
- Practice commands by breaking things:
  - `terraform refresh` / `plan -refresh-only`
  - `terraform import` (rescue orphaned resources)
  - `terraform state list / show / rm / mv`
- Cause drift deliberately → detect → fix
- Simulate two-engineer lock conflict
- **Done when:** I can recover a deleted state file using `import`

### **Stage 3: WIF Hands-on (T-G) — (1 session)**
- Set up GitHub OIDC → GCP STS trust pool
- Configure SA impersonation
- Build a GitHub Actions workflow that deploys via WIF
- **Delete all JSON SA keys forever**
- **Done when:** I can explain the JWT exchange end-to-end + my CI pipeline uses zero JSON keys

### **Stage 4: Real Infra Build (T-H + T-I + T-J) — (3-4 sessions)**
- **T-H:** Private GKE cluster + node pools + cluster-side Workload Identity
  - Modules emerge here naturally (VPC module, GKE module)
  - Multi-env emerges here naturally (dev/prod tfvars)
- **T-I:** Cloud SQL (private IP only) + KMS encryption + automated backups
  - Migrate account-service from compose-postgres → Cloud SQL
- **T-J:** Rebuild `infra/bootstrap/` from scratch from memory (graduation)
- **Done when:** I can build VPC + private GKE + Cloud SQL from blank GCP project in 90 min from memory

---

## 🏁 End Goal (Self-rating: 6.9/10 → 8/10)

After Stage 4, I can:

1. ✅ Explain Terraform to my mom using mandi register analogy
2. ✅ Build VPC + private GKE cluster from blank GCP project in **90 minutes from memory**
3. ✅ Recover from corrupted state using `terraform import` + `terraform state mv`
4. ✅ Defend my module design in a code review
5. ✅ Explain WIF end-to-end — JWT exchange, trust pool, impersonation chain
6. ✅ Walk into Kubernetes mastery saying *"Workload Identity in K8s? That's just WIF in the cluster — I've seen this before."*

---

## 🚫 Rules of This Blueprint

1. **Do NOT add T-B or T-C back.** I've shipped Terraform. Manual VPC + Hello TF is beneath my level. Going back is ego, not learning.
2. **Do NOT do T-E or T-F as standalone phases.** Modules and multi-env are learned best in context (during T-H).
3. **DO read T-A1 even though I scored 8/10 on Q1.** The mandi analogy is mentor-weapon vocabulary I need when I teach this later.
4. **DO `terraform destroy` at end of every learning session.** Idle GCP resources = wasted ₹. Build the muscle memory.
5. **DO write a village/building analogy after each stage.** If I can't explain it analogically, I don't know it.
6. **If I score below 5/10 on a future self-test → re-evaluate this blueprint.** Don't push through if foundation cracks.

---

## 📍 Where I Am RIGHT NOW

- ✅ T-0 Diagnostic complete (69/100)
- ✅ Blueprint locked (this file)
- ⏭️ **Next:** Stage 1 — Read `phase-T-A-01-the-big-lie.md` (30 min)

---

## 🔗 Companion Files

- `00-knowledge-diagnostic.md` — The 10 questions + my answers
- `00-diagnostic-results.md` — Full grading + per-question feedback
- `phase-T-A-01-the-big-lie.md` — Stage 1 reading material
- `README.md` — Original 12-phase plan (now overridden by this blueprint)

---

## 💎 Mentor Sentence I Will Memorize

> *"I am Confident Intermediate. My gaps are state toolbox, WIF, and apply internals. I do not need to redo VPC-by-hand or Hello-Terraform. I follow the compressed path: T-A1 read → T-D hands-on → T-G hands-on → T-H/T-I/T-J build."*

🔒 **BLUEPRINT LOCKED — Do not deviate.**
