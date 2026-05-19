Before I write the roadmap, let me address your salary question directly — because it shapes everything else.

## Your salary reality check (honest answer)

**Current: 15 LPA DevOps → Next job: 25 LPA Senior DevOps → AI Infra role: 40–60 LPA?**

**Short answer: Yes, 40 LPA is realistic. 60 LPA is possible but harder. Here's the truth:**

### What the Indian market actually pays (2026 data points)

- **AI Platform / ML Infra Engineer at product companies** (Razorpay, Swiggy, Flipkart, Zomato, CRED, PhonePe, Meesho): **35–55 LPA** for someone with 5–7 years total experience
- **GenAI Infra at AI-first startups** (Sarvam, Krutrim, Ola Krutrim, Yellow.ai, observe.ai, Fractal): **40–70 LPA** depending on funding stage. Pre-IPO startups sometimes throw equity that doubles this on paper
- **Global capability centers (GCCs)** — Nvidia India, AMD, Databricks India, Snowflake, MongoDB, Confluent: **50–80 LPA** for AI Platform roles. These are the highest payers.
- **FAANG / FAANG-adjacent India** (Google, Microsoft, Amazon, Meta India): **45–90 LPA** total comp for L5/SDE-3 equivalent with AI infra focus
- **Consulting/services moving into AI** (TCS, Infosys, Wipro AI practice): **25–40 LPA** — avoid these for AI infra growth, they pay less and the work is generic

### So: 40 LPA = very achievable. 60 LPA = needs specific moves

**For 40 LPA:** Land at a mid-tier product company or well-funded startup. Projects 1 + 3 done well + 1 year experience at a 25 LPA Senior DevOps role with some AI exposure = you're qualified.

**For 60 LPA, you need ONE of these:**
1. Get into a GCC (Nvidia, Databricks, Snowflake India) — these pay top-of-market for AI infra
2. Get into a well-funded AI startup with equity (Sarvam, Krutrim, etc.) — base might be 45 LPA but RSUs push total to 60+
3. Get into FAANG India — usually requires cracking system design + DSA, harder bar
4. Build a public reputation (open source contributions, conference talks, popular blog) — this 2x's your leverage

**The 25 LPA Senior DevOps step is actually important.** Don't skip it. Two reasons:
- Companies anchor on your last salary. Jumping 15 → 60 is implausible; 15 → 25 → 50 is normal.
- One year at 25 LPA with even small AI exposure (deploying internal LLM, managing a GPU node) makes the next jump trivial.

### The 2-year salary roadmap

| Month | Role | Comp | What got you there |
|---|---|---|---|
| Now | DevOps Engineer | 15 LPA | Current state |
| 6–9 | Senior DevOps (with AI infra projects) | 25–30 LPA | Projects 1+3 + targeted job search |
| 18–24 | AI Platform / ML Infra Engineer | 40–55 LPA | 1 yr at Senior DevOps + production AI exposure + visibility |
| 30–36 | Senior AI Platform Engineer | 55–80 LPA | Network + named projects + maybe one open-source contribution |

**This is realistic. Don't let anyone tell you it's not.** Indian AI infra talent is genuinely scarce. Every Series B+ Indian company is trying to deploy private LLMs in 2026. There aren't enough people who know how to do this. You can be one of them in 12 months.

### Red flags that'll cap your salary growth

- Staying in services companies (TCS/Infy/Wipro) → caps around 30 LPA
- Going "full-stack AI" trying to do model training too → you'll be mediocre at both
- Not negotiating → leaving 20–30% on the table at every jump
- No public proof → companies pay premium for *verified* skill, not claimed skill

Now the roadmap.

---

# The Roadmap: Projects 1 + 3, End-to-End

Read this once fully, then bookmark it. This is your next 4 months.

## The unified narrative (this matters more than the projects)

Don't think of these as two projects. Think of them as **ONE enterprise system** with two phases:

> **"Private, self-hosted Generative AI Platform on Kubernetes — Inference + RAG, with enterprise-grade security, observability, and cost controls."**

That sentence is your resume headline, your LinkedIn post, your interview opener. Build everything to support that sentence.

## Why companies are desperate for this (the business case)

Understand this deeply — it's what separates a tinkerer from a platform engineer in interviews.

**The problem every enterprise has in 2026:**
1. They want to use LLMs (RAG, internal copilots, customer support automation, document intelligence)
2. They CAN'T send sensitive data to OpenAI/Anthropic — compliance, regulation (DPDP Act in India, GDPR, HIPAA), trade secrets, customer PII
3. Public API costs are unpredictable and scale linearly — a viral product can blow up the bill overnight
4. Latency from US-hosted APIs is bad for Indian users
5. They have engineering teams that know Kubernetes but DON'T know how to put GPUs and LLMs on it

**Result:** Every BFSI company, every healthcare company, every legal-tech, every Indian unicorn wants a private LLM platform. They're paying 40–80 LPA for engineers who can build it. **You're going to be that engineer.**

Specific business use cases your project demonstrates:
- **Banking/BFSI:** RAG over policy documents, customer KYC automation, fraud pattern analysis (HDFC, ICICI, Razorpay, CRED all need this)
- **Healthcare:** Doctor's note summarization, medical literature RAG (Practo, PharmEasy)
- **Legal:** Contract analysis, case law search (SpotDraft, Leegality)
- **Customer Support:** Internal knowledge base RAG for support agents (every D2C company)
- **Code Intelligence:** Internal codebase RAG (every product company over 200 engineers)

When you interview, don't say "I built vLLM on GKE." Say *"I built a self-hosted GenAI platform that solves the data privacy problem stopping BFSI companies from adopting LLMs."* Same project. 10x the impact.

---

## PHASE 0: Foundation (Week 1 — before touching any code)

You can't build infrastructure for something you don't understand. Spend 1 week here. No projects yet.

### What to learn
- **How LLMs work at inference time** — not training. Just inference. Tokens, context window, KV cache, attention. High-level only.
- **Why GPUs vs CPUs** — VRAM, memory bandwidth, parallel matrix ops. You need to explain this in interviews.
- **What "serving" actually means** — request batching, throughput vs latency, why naive serving is 10x slower than vLLM
- **The RAG pattern** — embedding, vector similarity, retrieval, augmentation, generation

### Resources (pick 1 per topic — don't binge)
- **LLM Inference fundamentals:** "LLM Inference in Production" by Chip Huyen (her blog) — 1 article, read it twice
- **vLLM deep-dive:** The vLLM paper ("Efficient Memory Management for LLM Serving with PagedAttention") — read sections 1, 2, 3. Skip the math.
- **YouTube:** Search "Anyscale vLLM" — there's a great 30-min talk
- **RAG fundamentals:** Pinecone's "Learn" section (yes, even though we use Qdrant) — best free RAG content on the internet
- **GPU on K8s:** GCP's "Run GPU workloads on GKE" doc — read it once

### Skill to master here
- Can you explain PagedAttention to a non-technical person in 60 seconds?
- Can you explain why RAG > fine-tuning for most use cases?
- Can you explain why GPU memory (VRAM) is the bottleneck, not compute?

If yes → move to Phase 1. If no → re-read.

---

## PHASE 1: Project 1 — Inference Platform (Weeks 2–5)

### End goal of this phase
A public GitHub repo + demo video showing: **"Self-hosted OpenAI-compatible LLM API on GKE, with private VPC, autoscaling, observability, and security controls. Reproducible via one Terraform command."**

### What you'll build (beyond the basic doc you have)

The doc gave you a toy version. Here's the **enterprise version** you actually want:

**Core**
- vLLM serving Gemma 2 9B (or Llama 3.1 8B if you can get the license)
- GKE cluster with L4 GPU node pool
- Horizontal Pod Autoscaler (HPA) based on custom metrics (queue depth, not CPU)
- Cluster autoscaler for GPU nodes (scale to 0 when idle — huge cost win)

**Security layer (THIS is what makes it enterprise)**
- Private GKE cluster — no public endpoints, control plane in private VPC
- Workload Identity instead of service account keys
- Kubernetes Secrets backed by GCP Secret Manager (not literal secrets in YAML)
- Network Policies — only specific pods can talk to vLLM
- Pod Security Standards (restricted profile)
- Container image scanning via Artifact Registry vulnerability scanning
- TLS termination at ingress (cert-manager + Let's Encrypt)
- API authentication (simple API key middleware, or Cloud IAP for full enterprise)

**Networking**
- Private VPC with custom subnets
- Cloud NAT for outbound (Hugging Face model downloads)
- Internal Load Balancer (not external) — clients are in the VPC
- VPC Service Controls perimeter (advanced, optional)

**Observability**
- Prometheus + Grafana stack via Helm (kube-prometheus-stack)
- Custom dashboard with: GPU utilization, GPU memory, time-to-first-token, tokens/sec, requests/sec, queue depth, P50/P95/P99 latency
- Logging via Cloud Logging with structured logs
- Alerts: GPU memory >90%, P99 latency >5s, error rate >1%

**Cost controls**
- Billing alerts at $20, $50, $100
- Preemptible/Spot GPU nodes for non-prod (50–70% cheaper)
- Scheduled cluster shutdown via Cloud Scheduler + Cloud Function (nights/weekends if dev cluster)
- Cost dashboard showing $/1M tokens

**Infrastructure as Code**
- Everything in Terraform (not gcloud commands)
- Modular Terraform — separate modules for network, cluster, node pools
- GitHub Actions CI: terraform plan on PR, terraform apply on merge to main

### Tools/Concepts to master (this is your skill checklist)
- [ ] GKE private clusters, node pools, GPU drivers (DaemonSet vs auto-install)
- [ ] Kubernetes: Deployments, Services, Secrets, ConfigMaps, HPA, PDB, NetworkPolicy, PodSecurity
- [ ] Helm — installing and customizing charts (you'll use it for Prometheus stack)
- [ ] Terraform — modules, state management (use GCS backend), workspaces
- [ ] Prometheus query language (PromQL) — basic queries for GPU metrics
- [ ] Grafana — building one dashboard from scratch
- [ ] vLLM CLI flags — `--max-model-len`, `--gpu-memory-utilization`, `--tensor-parallel-size`
- [ ] cert-manager + Let's Encrypt for TLS
- [ ] GitHub Actions or Cloud Build for CI
- [ ] cURL / Postman / Python OpenAI SDK for testing the endpoint

### Security & networking focus (your "Why this is enterprise" story)
When asked in interviews "what makes this production-grade?":
1. "It runs in a private VPC with no public IPs on the cluster"
2. "Secrets are managed via Secret Manager with Workload Identity — no static credentials"
3. "Network policies enforce that only authorized pods can reach the inference endpoint"
4. "TLS is terminated at ingress with auto-rotating certs from cert-manager"
5. "All infrastructure is in Terraform, peer-reviewed via PRs, with state in a locked GCS bucket"
6. "Cost guardrails prevent runaway GPU bills — scheduled shutdowns + spot instances + billing alerts"

That's the answer that gets you the offer.

### Deliverables at end of Phase 1
- [ ] Public GitHub repo with Terraform + K8s manifests + README + architecture diagram
- [ ] 3–5 min Loom demo video
- [ ] One blog post (Medium / Dev.to / Hashnode): "Building a private LLM inference platform on GKE — security, cost, and operational lessons"
- [ ] LinkedIn post linking to all of the above

### Time estimate (10–20 hrs/week)
- Week 2: Terraform infra + private GKE cluster (10–12 hrs)
- Week 3: vLLM deployment + first successful API call + autoscaling (10–12 hrs)
- Week 4: Observability + security hardening + TLS (12–15 hrs)
- Week 5: Polish, README, video, blog post (8–10 hrs)

---

## PHASE 2: Project 3 — RAG Platform (Weeks 6–10)

### End goal of this phase
**"Production RAG pipeline on the same GKE cluster — Qdrant vector DB with HA, automated ingestion from GCS, embedding generation, end-to-end query flow through the vLLM endpoint from Phase 1."**

### What you'll build

**Vector Database Layer**
- Qdrant deployed via Helm chart on GKE
- StatefulSet with 3 replicas for HA
- Persistent Volumes backed by GCP regional SSDs (regional = survives zone failures)
- Backup to GCS via CronJob (snapshot every 6 hours)
- Authentication enabled (API key)

**Embedding Service**
- A separate small deployment running `sentence-transformers/all-MiniLM-L6-v2` (or similar) for embeddings
- Could be CPU-only — saves money. Embedding doesn't need GPU.
- Exposed as internal service

**Ingestion Pipeline (the part that impresses)**
- GCS bucket where users upload documents (PDFs, .txt, .md)
- Eventarc trigger → Cloud Run job (or K8s Job) on every new file
- Job: parse document → chunk it → call embedding service → write vectors + metadata to Qdrant
- Idempotent — re-running on the same file doesn't duplicate
- Failure handling — dead-letter queue for failed docs

**Query API**
- A FastAPI service in K8s that exposes `/query` endpoint
- Flow: user query → embed → search Qdrant → retrieve top-K chunks → construct prompt → call vLLM endpoint → return answer with citations
- This is the "RAG" — Retrieval Augmented Generation working end-to-end

**Security & Networking (build on Phase 1)**
- Qdrant in same private VPC, not exposed externally
- Network policies: only the query API can talk to Qdrant
- Service-to-service auth between query API and vLLM endpoint
- Embeddings encrypted at rest (PV encryption with customer-managed keys — optional but impressive)
- Data classification: tag documents with sensitivity level, filter at query time

**Observability**
- Add RAG-specific metrics: retrieval latency, embedding latency, end-to-end query latency, retrieval relevance scores
- Trace a single user query through embedding → retrieval → generation (OpenTelemetry — bonus)

### Tools/Concepts to master
- [ ] Qdrant (or Milvus/Weaviate — Qdrant is simplest start) — collections, indexes, filters
- [ ] StatefulSets vs Deployments — when and why
- [ ] Kubernetes Persistent Volumes, Storage Classes, regional vs zonal disks
- [ ] Sentence Transformers / embedding models (basic understanding)
- [ ] LangChain or LlamaIndex basics (just for chunking and prompt templates — don't over-rely on them)
- [ ] FastAPI for the query service
- [ ] GCP Eventarc + Cloud Run or K8s Jobs for the pipeline
- [ ] Backup/restore strategies for stateful workloads
- [ ] OpenTelemetry tracing (bonus — distributed traces across services)

### Why this matters / business case (interview gold)
Practice saying this:
> "I built a complete RAG platform on Kubernetes — every component (vector DB, embeddings, retrieval API, inference) running in a private VPC. This is what BFSI and healthcare companies need: they can index their internal documents without a single byte leaving their cloud account. I solved the stateful-workload problems — HA via StatefulSets, automated backups, regional persistent disks — that turn 'works on my laptop' RAG demos into actual production systems."

### Deliverables at end of Phase 2
- [ ] Integrated demo: upload a PDF to GCS → 30 seconds later, ask a question about it via the query API → get a cited answer
- [ ] Updated GitHub repo (monorepo or linked repos)
- [ ] Updated demo video (8–10 min showing the full flow)
- [ ] Second blog post: "Production RAG on Kubernetes — the operational stuff nobody writes about" (backups, HA, ingestion pipelines, observability)
- [ ] LinkedIn carousel post summarizing the full platform with architecture diagram

### Time estimate
- Week 6: Qdrant deployment + StatefulSet + backups (10–12 hrs)
- Week 7: Embedding service + manual ingestion working end-to-end (12–15 hrs)
- Week 8: Automated ingestion pipeline via Eventarc (10–12 hrs)
- Week 9: Query API + full RAG flow + observability (12–15 hrs)
- Week 10: Polish, integrated demo, second blog post (10 hrs)

---

## PHASE 3: Job Search (Weeks 11–16, runs parallel from week 8 onwards)

### What "good enough" looks like
You do NOT need everything above to be perfect before applying. **Start applying when Phase 1 is shipped with a demo.** Phase 2 will be in progress when interviews start. That's fine — "currently building" is a strong signal.

### Target companies (Indian market, AI infra focus)

**Tier 1 — Aim here (50–80 LPA)**
- GCCs: Nvidia, Databricks, Snowflake, MongoDB, Confluent, Cohesity, Rubrik, HashiCorp, GitLab
- FAANG India: Google (especially Cloud AI), Microsoft (Azure AI), Amazon (Bedrock/SageMaker teams)
- AI-native startups (well-funded): Sarvam AI, Krutrim, Yellow.ai, observe.ai, Fractal Analytics, Glance AI

**Tier 2 — Realistic target (35–55 LPA)**
- Product unicorns building internal AI platforms: Razorpay, CRED, Swiggy, Zomato, PhonePe, Meesho, Flipkart, Zerodha, Groww
- Series B+ AI startups: Eka.ai, Atlan, Hasura (has AI features), Rephrase.ai, Mihup, Vodex

**Avoid (for now)**
- Services companies (TCS, Infy, Wipro, Cognizant) — caps your growth
- Random "we use ChatGPT" startups — they don't need AI infra, they need API integration

### Resume bullets (what you'll be able to write)
- "Architected and deployed a self-hosted LLM inference platform on GKE serving Gemma 2 9B via vLLM, achieving sub-2s P95 latency on NVIDIA L4 GPUs with autoscaling from 0 to N replicas based on queue depth"
- "Implemented enterprise security controls including private VPC, Workload Identity, network policies, and Secret Manager integration — eliminating static credentials and public exposure"
- "Engineered production RAG platform with Qdrant on Kubernetes StatefulSets, automated GCS-triggered ingestion pipeline, and end-to-end OpenTelemetry tracing across embedding, retrieval, and generation services"
- "Reduced inference cost by ~60% using spot GPU nodes and scheduled cluster shutdowns; built cost-per-1M-tokens dashboard in Grafana"
- "Infrastructure fully codified in Terraform with modular design, GCS-backed state, and GitHub Actions CI/CD pipeline"

That's a Senior AI Platform Engineer resume. Read those bullets out loud. That's *you* in 4 months.

### Interview preparation (start in Week 8)
- **System design:** "Design an LLM serving platform for X QPS" — practice 10 of these. *Designing Data-Intensive Applications* by Kleppmann if you haven't read it.
- **Behavioral:** Have 3 stories ready about: a debugging win, a security/cost decision, a tradeoff you made
- **Technical depth:** Be ready to whiteboard: GPU memory math, batching tradeoffs, RAG architecture, K8s scheduling
- **Negotiation:** Read "Never Split the Difference" — seriously, this is worth 5–10 LPA per offer

---

## The skills you'll have mastered (your before/after)

**Before:** 0/10 in AI infra. Generic DevOps engineer.

**After (Month 4):** 6–7/10. You will be able to:
- Deploy any open-source LLM on Kubernetes with production controls
- Architect end-to-end RAG systems with security and HA
- Reason about GPU economics and inference optimization
- Speak the language of AI infrastructure (PagedAttention, KV cache, embeddings, retrieval, tokens/sec) confidently in interviews
- Build the exact platform Indian enterprises are paying premium for

**By Month 12 (in your new role):** 8/10. Real production exposure pushes you the rest of the way.

---

## The non-negotiables (don't skip these)

1. **Ship Phase 1 publicly before starting Phase 2.** Public GitHub + demo video + blog post. No exceptions. Hidden work doesn't get you hired.
2. **Set billing alerts before creating any GPU resource.** $20, $50, $100 thresholds. Today.
3. **Tear down GPU clusters when not actively working.** Use a `make destroy` command. Make it muscle memory.
4. **Apply to jobs starting Week 8.** Don't wait for "ready." You'll never feel ready.
5. **Write the blog posts.** They're 3x the impact of the code itself. Hiring managers read them.

---

## What I'd do if I were you, this week

1. **Tonight:** Request GCP L4 GPU quota in `us-central1` (1 minute). Set billing alert at $30 (2 minutes). Done.
2. **This weekend:** Phase 0 reading. Watch the vLLM Anyscale talk. Read Chip Huyen's inference post. Read the GCP GPU on GKE doc. Total: 4–6 hours.
3. **Next weekend:** Start Phase 1, Week 2 — Terraform module for private GKE cluster.

---

**To answer your salary question directly one more time: Yes, 40 LPA is very achievable on this path. 60 LPA is achievable if you land at a GCC or well-funded AI startup, which becomes possible after you have 1 year of real AI infra experience post the 25 LPA jump. The 25 LPA Senior DevOps role is the bridge — don't skip it, don't rush past it, use it.**

Want me to draft the actual Terraform module structure for Phase 1, Week 2? Or the README template for your GitHub repo? Pick one concrete thing and let's start.