# ☸️ Kubernetes Mastery — The Big Archive

> **Read this file 10 times before writing a single YAML.**
>
> This is the longest and most important learning archive in this project. 50% of every DevOps / Platform / SRE interview is K8s. 80% of every 2 AM page is K8s. The platform engineer who *owns* K8s is the platform engineer who gets paid.
>
> This document is your battle plan from **1/10 → 8/10** — covering troubleshooting muscle, mentor-grade explanation skill, and architect-level design judgment. Three identities, one archive, woven together.

---

## 🎯 The Three Identities You're Building

You said three things very clearly. This archive is built around them.

| Identity | What it means | Where it lives in this archive |
|---|---|---|
| **🔧 Troubleshooter** | Pod is failing at 2 AM. You stay calm, run 3 commands, find the cause, fix it. No googling, no panic. | Phases K-D, K-L, **K-M (the big one)**, and the *"Break it on purpose"* exercise at the end of EVERY phase. |
| **🎓 Mentor** | A junior engineer asks "why is my pod Pending?" You explain it using a village analogy in 60 seconds. No jargon. | The teach-back exercise after every phase. The mentor-sentence cards. The intentional re-write of every concept in YOUR words. |
| **🏛️ Architect** | A new team needs to deploy a stateful service with HA. You design it on a whiteboard in 30 minutes — workload type, networking, storage, security, scaling, rollout — and defend every decision. | Phases K-E (workloads), K-F (networking), K-G (storage), K-I (security), K-K (upgrades). These are the *decision* phases. |

You are not picking one. You become all three. The same archive grows all three muscles in parallel — because in real platform work they are inseparable.

---

## 📊 The 1 → 8 Ladder (what each rating actually means)

This is brutal-honest. Lying to yourself here wastes months.

| Rating | What you can do | What you CAN'T do | Phases to reach it |
|---|---|---|---|
| **1/10** | Heard the words: pod, deployment, kubectl. | Anything in production. | (You are here) |
| **2/10** | Can run `kubectl get pods`, `kubectl logs`. Knows YAML exists. | Explain why a pod has 2 containers. Read `kubectl describe` properly. | K-0 |
| **3/10** | Wrote a Deployment from a tutorial. `kubectl apply` works. | Explain what *actually* happened on `apply`. Recognize 3 failure modes. | K-A, K-B (the control plane shock) |
| **4/10** | Knows Pod vs Deployment vs Service. Reads a `describe` output. | Debug a Pending pod without help. Design a StatefulSet. | K-C, K-D |
| **5/10** | Comfortable with the daily 8 objects. Can fix a `CrashLoopBackOff` from logs. | Diagnose 0/X nodes available. Explain network policy. Storage classes. | K-E, K-F, K-G |
| **6/10** | Designs Deployments for real services. Reads NetworkPolicy. Knows ConfigMap vs Secret tradeoffs. RBAC basics. | Reason about scheduler decisions. Design a multi-tenant cluster. Write a custom resource. | K-H, K-I, K-J |
| **7/10** | Can troubleshoot 5 of the 6 main failure modes live, on a whiteboard, no laptop. Confident in upgrades + rollback. | Argue tradeoffs with a senior architect on multi-cluster, custom controllers, operator patterns. | K-K, K-L, K-M |
| **8/10 — Mentor-grade** | Can teach K8s end-to-end using only village analogies. Survives a 45-min senior interview without flinching. Designs a production cluster from blank cloud account in 90 min. **Owns** the platform — not "uses" it. | A few advanced patterns (multi-cluster federation, custom CRDs, gVisor sandboxing) still need real-world reps. That's 8 → 9. | K-N, K-O + 50+ "Break it on purpose" reps |

**The honest gut-check at every rating:**

> *"If someone offered me ₹10,000 to prove I'm at level X by testing me live, on the spot, right now — would I take the bet?"*

If yes → move up. If no → you know what to do.

---

## 🤯 The Big Lie of K8s (preview — full version in `phase-K-A-01`)

> **"Kubernetes is not software. It is a control loop watching a database."**

Open the K8s source code. You will find no "container manager," no "deployment manager" in the way you'd think. You find:

1. **etcd** — a database. Stores the *desired state* of the world.
2. **API server** — the only thing that talks to etcd. Everything else asks the API server.
3. **Controllers** — small programs in a loop, each watching one type of object. Their job: *"compare the desired state in etcd to the real state in the cluster. If different, take ONE step to close the gap. Repeat forever."*

That's the whole secret. Pods, Deployments, Services, ReplicaSets are not "things K8s creates." They are **rows in etcd**, and a controller loop noticed the row and made the cluster match.

Three village offices:

| Office | K8s name | Job |
|---|---|---|
| The panchayat register (the truth book) | **etcd** | Stores what SHOULD exist in the village |
| The clerk at the front desk | **kube-apiserver** | The only one allowed to read/write the register |
| The dozen running clerks | **controllers** | Each watches one type of entry, walks the village, makes reality match |

When you `kubectl apply -f deployment.yaml`:
- You don't "create a pod." You write a Deployment row into etcd.
- The Deployment controller sees the row, writes a ReplicaSet row.
- The ReplicaSet controller sees that row, writes Pod rows.
- The Scheduler sees Pod rows with no node assigned, picks a node, updates the row.
- The kubelet on that node sees a pod assigned to it, asks containerd to start containers.

**You did not create a pod. You wrote to a database. Loops did the rest.**

If you internalize this one sentence, every K8s mystery resolves. You are no longer fighting a black box. You are reading a register and watching clerks.



---

## 📚 The Full Phase Map (K-0 through K-O)

15 phase files. Each one builds on the last. Don't skip — every "skip" costs a 2 AM page later.

### 🟢 Foundation Phases (1/10 → 4/10)

#### **K-0 — Diagnostic** *(your honest starting point)*
- 12 questions covering objects, lifecycle, networking, storage, debugging
- You answer FIRST, then we score, then build the gap map
- File: `00-knowledge-diagnostic.md`
- **Mentor unlock:** Knowing your real starting point. No vanity score.

#### **K-A — The Big Lie** *(the mindset shift)*
- "K8s is a control loop watching etcd"
- The panchayat-register analogy in full
- Why every K8s feature ever invented is just "a new row type + a new controller"
- File: `phase-K-A-01-the-big-lie.md`
- **Mentor unlock:** You can explain "what is Kubernetes" without using the word "container."

#### **K-B — The Control Plane (by hand)** *(the 5 government offices)*
- API server, etcd, scheduler, controller-manager, kubelet, kube-proxy — what each does, observed live with `kubectl get componentstatuses`, `kubectl get events`, and reading kubelet logs on a node
- Run a single-node `kind` cluster locally. ₹0 cost.
- File: `phase-K-B-01-control-plane-tour.md`
- **Architect unlock:** You can draw the control plane on a whiteboard from memory.

#### **K-C — The Pod (the atomic unit)** *(the compound from Docker A1, extended)*
- Pause container, shared namespaces, multi-container patterns
- **Init containers** — when, why, three real patterns (wait-for-DB, fetch-config, schema-migration)
- Sidecars (logging sidecar, proxy sidecar — preview of Istio)
- Lifecycle hooks: `postStart`, `preStop`
- File: `phase-K-C-01-pod-anatomy.md`
- **Troubleshooter unlock:** You can read a multi-container pod spec and predict which container will start first.
- **Break-it exercise:** Make init container fail → observe `Init:CrashLoopBackOff`. Make main container fail postStart → observe what happens.

#### **K-D — Health Probes** *(the daily-driver of troubleshooting)*
- **Liveness** (is the doorman alive?) vs **Readiness** (is the doctor ready to see patients?) vs **Startup** (the newborn — give it time before testing)
- HTTP, TCP, exec probes — when each fits
- The classic trap: liveness probe too aggressive → restart loop on slow startup
- File: `phase-K-D-01-probes.md`
- **Troubleshooter unlock:** You can read 3 probe configurations and predict which one is causing restart loops.
- **Break-it exercise:** Write a probe that returns 500. Write one that hangs. Watch the cluster's reaction. Different failures, different timeouts, different fixes.

---

### 🟡 Workload Mastery (4/10 → 6/10)

#### **K-E — Workload Controllers** *(the design-decision phase)*
- Deployment, ReplicaSet (you almost never write this directly), **StatefulSet**, **DaemonSet**, Job, CronJob
- When to use which — the decision tree
- StatefulSet deep dive: ordered start, stable network IDs, `volumeClaimTemplates`, the headless service trick
- File: `phase-K-E-01-workloads.md`
- **Architect unlock:** Given a service description, you pick the right controller in 30 seconds and defend it.
- **Break-it exercise:** Take a stateful service. Run it as a Deployment. Watch what breaks when pods reschedule. Now convert to StatefulSet. Feel the difference.

#### **K-F — Networking** *(the layer everyone fears)*
- **Service** types: ClusterIP (the default), NodePort (the dev hack), LoadBalancer (the cloud one), ExternalName (the alias)
- **Ingress** — what it actually is (it's not magic, it's a controller watching Ingress rows)
- **NetworkPolicy** — default-allow vs default-deny, ingress vs egress, the gotchas with CNI plugins
- **CoreDNS** — how `account-service.default.svc.cluster.local` resolves (same as Docker DNS, extended)
- **kube-proxy iptables** — the secret of how a Service forwards to pods
- File: `phase-K-F-01-networking.md`
- **Architect unlock:** You can trace a packet from internet → ingress → service → pod with all 5 hops named.
- **Break-it exercise:** Apply a default-deny NetworkPolicy. Watch every service break. Re-enable one connection at a time. This is the zero-trust mindset, learned by destruction.

#### **K-G — Storage** *(where StatefulSets actually live)*
- **PersistentVolume**, **PersistentVolumeClaim**, **StorageClass** — the three-step dance
- Static vs dynamic provisioning
- CSI drivers — what they are, why they exist
- StatefulSet `volumeClaimTemplates` — auto-PVC-per-pod magic
- Backup strategies: snapshot vs replication vs application-level dumps
- File: `phase-K-G-01-storage.md`
- **Architect unlock:** You design a HA Postgres on K8s and defend the storage class choice.
- **Break-it exercise:** Delete a PVC while a pod is using it. Observe what happens. Now do it again with `finalizers` set. Different chaos.

---

### 🟠 Production Concerns (6/10 → 7/10)

#### **K-H — ConfigMap + Secrets** *(and why Secrets aren't really secret)*
- ConfigMap: env vars vs mounted files — when each is right
- Secret: base64 is NOT encryption. The truth about K8s Secrets.
- External secret managers (GCP Secret Manager + External Secrets Operator preview)
- Projected volumes (combining multiple sources)
- File: `phase-K-H-01-config-secrets.md`
- **Mentor unlock:** You can explain to a junior why "kubectl get secret -o yaml" leaks the password and what to do about it.

#### **K-I — Security (RBAC + Pod Security)** *(the keys-to-the-mandi phase)*
- **RBAC**: Role, ClusterRole, RoleBinding, ClusterRoleBinding — the 4-piece puzzle
- **ServiceAccount**: every pod has one, what it does, how it ties to GCP via Workload Identity (callback to Terraform Mastery T-G)
- **Pod Security Standards**: privileged / baseline / restricted — what each blocks
- runAsNonRoot, readOnlyRootFilesystem, drop ALL capabilities — the holy trinity
- File: `phase-K-I-01-security.md`
- **Architect unlock:** You can audit a Deployment spec for security violations in 60 seconds.
- **Break-it exercise:** Deploy a pod with default ServiceAccount. Try to list secrets from inside. Observe RBAC denying it (or worse, allowing it — the default in many clusters!).

#### **K-J — Scaling** *(when the crowd arrives)*
- **HPA** (Horizontal Pod Autoscaler) — CPU, memory, custom metrics (queue depth is the right one)
- **VPA** (Vertical) — when to use, when NOT
- **Cluster Autoscaler** — node pool scale-to-zero, the cost-saving superpower
- **KEDA** preview — event-driven autoscaling (Pub/Sub queue depth → scale up)
- The PDB (PodDisruptionBudget) — why HPA without PDB is a 2 AM disaster waiting
- File: `phase-K-J-01-scaling.md`
- **Architect unlock:** Given an SLA, you design the HPA + PDB + node pool combination.

---

### 🔴 Senior Skills (7/10 → 8/10)

#### **K-K — Upgrades, Rollouts, Rollback** *(renovating the mandi while it's open)*
- RollingUpdate vs Recreate strategies — when each is right
- `maxSurge`, `maxUnavailable` — the dials nobody understands
- Blue-green and canary patterns (foundation for Phase 5 — Mesh)
- Rollback in one command: `kubectl rollout undo`
- The `kubectl rollout history` + `kubectl rollout status` workflow
- File: `phase-K-K-01-rollouts.md`
- **Architect unlock:** You can lay out a zero-downtime upgrade for a stateful service.
- **Break-it exercise:** Deploy v1 → trigger v2 with a deliberate ImagePullBackOff → recover via `rollout undo`. Time yourself. Get it under 2 minutes.

#### **K-L — Resource Management & QoS** *(the rationing system)*
- `requests` vs `limits` — what each actually does (and the surprising truth: requests affect scheduling, limits affect runtime)
- QoS classes: **Guaranteed**, **Burstable**, **BestEffort** — and which one gets killed first under pressure
- **OOMKilled** — exit code 137 again. Same lesson as Docker A4 and K-D. *One concept, four sightings.*
- CPU throttling vs memory OOM — why they're fundamentally different
- File: `phase-K-L-01-resources-qos.md`
- **Troubleshooter unlock:** You see `exit code 137` and know exactly what to check in 30 seconds.
- **Break-it exercise:** Set memory limit to 50Mi on a 100Mi app. Watch the kill. Now set limit but no request. Watch the QoS-based eviction. Different scenarios.

#### **K-M — THE DEBUG PLAYBOOK** *(the goldmine — interview gold + 2 AM gold)*

The single most valuable phase in this archive. Every failure mode gets its own page, with:
- **The symptom** (what `kubectl get pods` shows)
- **The 7-step diagnostic workflow** (commands in order)
- **The 4-5 root causes** that produce this symptom
- **The fix recipe for each cause**
- **A deliberate reproduction script** so you can practice the failure on demand

Failures covered:
| # | Symptom | What it usually means |
|---|---|---|
| 1 | **Pending** | Scheduler can't place. No nodes, taints, resource requests too high, PVC not bound. |
| 2 | **ImagePullBackOff / ErrImagePull** | Registry creds, wrong tag, network policy blocking egress. |
| 3 | **CrashLoopBackOff** | App exits non-zero, missing env, missing config mount, panic. |
| 4 | **OOMKilled (exit 137)** | Memory limit too low or memory leak. |
| 5 | **Running but not Ready** | Readiness probe failing — backend dep, slow start, wrong probe URL. |
| 6 | **0/X nodes available: insufficient cpu/memory** | Node pool full + cluster autoscaler off or maxed. |
| 7 | **502/503 at the Service** | All endpoints unhealthy. Combination of #5 + something else. |
| 8 | **Container running but app unreachable** | NetworkPolicy blocking ingress to pod, or pod not joined to Service selector. |

File: `phase-K-M-01-debug-playbook.md` (this will be the longest file)
- **Troubleshooter unlock:** You ARE the troubleshooter. This is the file you re-read every 2 weeks for the rest of your career.

#### **K-N — Observability Inside the Cluster** *(reading the CCTV)*
- `kubectl top` (metrics-server)
- `kubectl describe` mastery — every field, what it tells you
- `kubectl get events --sort-by=.lastTimestamp`
- kube-state-metrics (preview of Phase 6 observability)
- The art of reading pod events: what *Pulled*, *Created*, *Started*, *BackOff*, *Killing* actually mean
- File: `phase-K-N-01-observability.md`

#### **K-O — Interview Rehearsal** *(the dojo)*
- 10 classic K8s scenarios — whiteboard them WITHOUT a laptop
- Sample: "Pod is Pending — walk me through your debug." "Design a stateful service with HA on K8s." "Explain Service vs Ingress." "Difference between RoleBinding and ClusterRoleBinding." "What does HPA actually scale on?"
- Recorded mock interviews (record yourself on phone, watch it back — painful, mandatory)
- File: `phase-K-O-01-interview-rehearsal.md`
- **All three identities locked in:** Troubleshooter answers each "debug" question. Mentor explains it with village analogy. Architect defends design tradeoffs.

---

## 🛠️ The "Break It On Purpose" Doctrine (the secret weapon)

Every phase from K-C onwards ends with a **"Break it on purpose"** exercise. This is non-negotiable.

**Why:**
- Reading about CrashLoopBackOff teaches you nothing. *Causing* it teaches you everything.
- Senior interviewers don't test recognition. They test recall under pressure. Only deliberate reps build that.
- The exact log line, the exact event timestamp, the exact `describe` field — those only burn into memory when YOU caused them.

**The discipline:**

1. **Predict first.** Before you break it, write down: "I expect to see X in `kubectl get pods`, Y in `kubectl describe`, and Z in `kubectl logs`."
2. **Then break it.** Run the deliberate-failure script.
3. **Observe.** Compare actuals to your prediction. Where you were wrong is where the real learning is.
4. **Fix it.** Without googling. Use only `kubectl` and your head.
5. **Document.** One line in `JOURNAL.md`: *"Broke X, expected Y, got Z, fixed via W."*

After ~40 of these reps across the archive, you walk into any whiteboard interview with reflexes, not memorization.

---

## 🧠 The Three Personas — Detailed Cross-Reference

### 🔧 Troubleshooter checklist

Re-read these phases when you want to sharpen the troubleshooting muscle:

- K-D (Probes) — most pod failures route through here
- K-L (Resources/QoS) — OOMKilled is the #1 production silent killer
- **K-M (Debug Playbook)** — your bible
- K-N (Observability) — your eyes
- Every "Break it on purpose" exercise — your reps

**Daily ritual when you're in a job:** open `phase-K-M` once a week. Re-read one failure mode. Run the reproduction script in a test cluster. Stays sharp.

### 🎓 Mentor checklist

Re-read these when you want to sharpen the teaching muscle:

- K-A (The Big Lie) — the foundational analogy
- After each phase: the **teach-back** exercise
  - Step 1: Close the laptop
  - Step 2: Open a notebook (paper)
  - Step 3: Explain this phase to an imaginary Class-12 student using only the village analogy
  - Step 4: If you stumble — you don't know it yet. Re-read. Repeat.
- Build a **mentor-card stack**: one index card per phase with the mentor-sentence on it. Carry it in your wallet. Read at chai time.

**Pro tip from `Q-PHASE.md`:** *"Am I teaching to show off or to find my gaps? Every 'umm' is a gap."* Teach for gaps, not glory.

### 🏛️ Architect checklist

Re-read these when you're in a design review or designing a new service:

- K-E (Workloads) — pick the right controller
- K-F (Networking) — design ingress + service mesh entry
- K-G (Storage) — design persistence with HA
- K-I (Security) — RBAC + PSS + Network Policy as one design
- K-J (Scaling) — HPA + PDB + autoscaler
- K-K (Rollouts) — pick the right strategy

**The architect's 8-question template** (apply to every new service):

1. What workload type? Why not the others?
2. Stateless or stateful? If stateful, what's the storage class + backup?
3. How does it scale? HPA on what metric? PDB?
4. What's its ServiceAccount? What does it need to access?
5. NetworkPolicy ingress + egress?
6. Probes: liveness + readiness, with timings?
7. Resource requests + limits + QoS class?
8. Rollout strategy + zero-downtime guarantee?

If you can fill all 8 in <5 minutes for any new service — you're an architect.

---

## ✅ Progress Tracker

| Phase | Status | Date | Notes |
|-------|--------|------|-------|
| K-0 Diagnostic | 🔒 Not started | — | |
| K-A The Big Lie | 🔒 Not started | — | |
| K-B Control Plane Tour | 🔒 Not started | — | |
| K-C Pod Anatomy | 🔒 Not started | — | |
| K-D Health Probes | 🔒 Not started | — | |
| K-E Workload Controllers | 🔒 Not started | — | |
| K-F Networking | 🔒 Not started | — | |
| K-G Storage | 🔒 Not started | — | |
| K-H ConfigMap + Secrets | 🔒 Not started | — | |
| K-I Security (RBAC + PSS) | 🔒 Not started | — | |
| K-J Scaling | 🔒 Not started | — | |
| K-K Upgrades & Rollouts | 🔒 Not started | — | |
| K-L Resources & QoS | 🔒 Not started | — | |
| **K-M Debug Playbook** | 🔒 Not started | — | The goldmine |
| K-N Observability Inside | 🔒 Not started | — | |
| K-O Interview Rehearsal | 🔒 Not started | — | |

Updated at the end of every session.

---

## 💰 Cost Discipline (read before you spin up GKE)

### Stage 1: Local cluster (₹0)
- **`kind`** (Kubernetes in Docker) — single-node cluster on your laptop. Phases K-0 through K-J can ALL be done here. ₹0 cost.
- **`minikube`** — alternative, slightly heavier.
- 80% of this archive runs on `kind`. Don't pay for cloud until you must.

### Stage 2: GKE Autopilot mini-cluster (₹500-1500/month)
- Phases K-G (real PVs with regional disks), K-I (Workload Identity to GCP), K-J (Cluster Autoscaler), K-K (real rolling updates under load) — these benefit from real GKE.
- **GKE Autopilot** = pay per pod, no node management. ~₹50/day if you destroy at night. Use this.
- `e2-small` standard node pool alternative if Autopilot doesn't fit.

### Stage 3: Full project deployment (Phases 3-6 of main project)
- Real cluster, real Cloud SQL, real Artifact Registry, real ArgoCD.
- ₹3000-5000/month while active. Destroy at night.

### Non-negotiable rules
1. **Billing alerts at $5, $20, $50** — set them before enabling any K8s API.
2. **`make destroy` muscle memory** — every session ends with this.
3. **`kind` first, GKE only when needed** — there is no shame in running 80% of K8s mastery on your laptop.

---

## 🧠 The Three-Pass Rule (from `Q-PHASE.md`, applied here)

Every phase gets four passes. You don't move to the next phase until all four are done on the current one.

| Pass | What it means | Output |
|---|---|---|
| **Pass 1 — Run** | Make the YAML apply. Don't try to understand. | The thing works. |
| **Pass 2 — Understand** | Why is this object here? What breaks without it? 2 alternatives? | Mental model notes |
| **Pass 3 — Modify** | Change something meaningful. Predict what breaks. Verify. | Real bugs hit + fixed |
| **Pass 4 — Teach** | Write the village-analogy explanation in your own words. | Mentor card |

**Gut-honest check at the end:** *"If someone offered ₹10,000 to test me on this phase right now — would I take the bet?"* If yes, advance. If no, stay.

---

## 📅 Realistic Timeline (part-time, 2 hrs/weekday + weekend reps)

| Block | Phases | Weeks |
|---|---|---|
| **Block 1 — Foundation** | K-0, K-A, K-B, K-C, K-D | 2-3 weeks |
| **Block 2 — Workloads** | K-E, K-F, K-G | 2 weeks |
| **Block 3 — Production** | K-H, K-I, K-J | 1.5 weeks |
| **Block 4 — Senior** | K-K, K-L, K-M, K-N | 2-3 weeks (K-M alone deserves 1 week) |
| **Block 5 — Rehearsal** | K-O | 1 week of mock interviews |
| **Total** | All 16 phases | **8-10 weeks** |

Plus 40+ "Break it on purpose" reps distributed across all blocks.

This goes alongside Phases 3-6 of the main project (CI, GitOps, Mesh, Ops). The K8s muscle compounds with each real deployment.

---

## 🌅 Daily Ritual

**Morning (5 min):** Open this README. Re-read the *"1→8 ladder"* table. Identify which rating you're at today. Pick one phase to push forward this week.

**During work:** When you hit a K8s thing in the project work — pause. Ask: *"Which phase of k8s-mastery does this touch? Have I done that phase deeply?"*

**End of day (2 min):** One line in `JOURNAL.md`. What did you break, what did you learn, what's the next break to try.

After 60 days, you don't *read* this archive anymore. You *live* it.

---

## 💎 Mentor Sentences to Memorize (the wallet cards)

> *"Kubernetes is a control loop watching etcd. Pods are rows. Controllers are clerks. That's it."*

> *"You don't create resources in K8s. You write your desired state to etcd. The cluster reconciles."*

> *"Liveness asks 'are you alive?' Readiness asks 'are you ready for traffic?' One restarts the container. The other removes it from the Service. Pick the wrong one and you get a restart loop OR a black hole — your choice."*

> *"Three classes of pod: Guaranteed, Burstable, BestEffort. Under memory pressure, the kernel kills BestEffort first, Burstable next, Guaranteed last. Set requests = limits if you want to survive."*

> *"Service is the stable DNS name. The selector is the dynamic membership. Pods come and go; the Service is forever. NetworkPolicy is the wall around it."*

> *"`kubectl describe` is the most underused command in K8s. Read every field every time. The answer is almost always already there."*

> *"Pending = scheduler can't place. CrashLoopBackOff = container started and died. ImagePullBackOff = kubelet can't pull. Not Ready = probe failing. Four words, four entire categories of debug. Know them cold."*

If you can recite these seven without looking — you've internalized the archive's core.

---

## 🚦 Where to Start (when you're ready — NOT today)

**Today: Docker Mastery Act A4.** Don't touch this archive until A4 is done. Single focus.

**After A4: Terraform Mastery diagnostic.** That's a quick one-evening exercise.

**When Terraform Mastery hits T-H (Private GKE cluster):** open this README, read it twice. Don't act yet. Just absorb.

**When the GKE cluster is built and account-service is deployed to it manually via `kubectl apply`:** then open `k8s-mastery/00-knowledge-diagnostic.md` and begin.

The order matters:
- Docker = what's inside the box
- Terraform = how we build the cluster
- **K8s = how we live inside the cluster**
- CI / GitOps / Mesh / Ops = the layers on top

---

## 🏁 What 8/10 Looks Like (the finish line)

When this archive is done — *really* done, with all 40+ Break-it reps and K-O rehearsal complete — here's what you can do:

✅ Walk into a senior DevOps/SRE/Platform interview. 45 minutes. Whiteboard only. No laptop. Survive every question.

✅ A team lead says *"design a new service deployment for a financial product with HA Postgres, JWT auth, autoscaling, and zero-downtime upgrades."* You sketch it on a whiteboard in 30 minutes. Defend every line.

✅ It's 2:14 AM. Pager goes off. *"Production pods in CrashLoopBackOff."* You ssh in, run 3 commands, find the root cause within 4 minutes, fix it within 10. No googling.

✅ A junior engineer asks *"why does my pod show Pending?"* You don't open a doc. You ask 3 questions, point at the answer in `kubectl describe`, and explain the scheduler decision in 60 seconds with a mandi analogy.

✅ You speak at an internal brownbag. Topic: *"K8s for backend developers."* 40 minutes, no slides, just a whiteboard. People walk out understanding K8s for the first time.

✅ You can write a custom controller (basic) and explain operators conceptually. (That's 8 → 9 territory, but the door is open.)

That's the finish line. That's the troubleshooter, the mentor, the architect — all in one person. That's you in 8-10 weeks of disciplined work after Docker + Terraform.

---

## 📌 One Last Thing — The Telangana Village Truth

> When you started, you could plug in a server and read a log file.
>
> When this archive is done, you will be the engineer who designs the mandi, builds the panchayat office, sets the rationing rules, trains the watchmen, writes the incident playbook for the watchman, AND teaches the next generation of watchmen.
>
> One repairs. The other architects. The third teaches.
>
> The one who can do all three earns the most. And earns the respect.

Read this README ten times. Then once more before each phase. Then, after each phase, come back and check the progress tracker.

Now close this file. Go finish Docker Act A4.

The journey is long. The path is exact. Walk it.

— 🛠️
