# The DevOps & Platform Engineer Mindset

To transition from **Support** to **Platform Engineering**, use this guide to evaluate every file and resource in this project.

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
