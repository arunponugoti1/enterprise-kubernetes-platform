# 🐳 Docker Mastery — Personal Learning Archive

> Goal: Go from surface-level Docker knowledge → **8-9/10 mentor-grade depth**, so that when we reach Kubernetes, it feels like *"oh this is just Docker extended"* — not magic.

---

## 📖 How to use this folder

Each file is a self-contained lesson. Read them **in order**. Don't skip ahead — each one builds on the previous.

When you re-read later, focus on the **village analogies** and **summary tables** — those are your mentor weapons.

---

## 📚 Index

### Phase 0 — Where I started
- [`00-knowledge-diagnostic.md`](./00-knowledge-diagnostic.md) — The 10-question diagnostic, my answers, scoring breakdown, and gap map. **Starting score: 4.4 / 10**

### Phase A — The Foundation Unlock (Namespaces + cgroups)
> *"Docker is just a wrapper over Linux kernel features."*

- [`phase-A-01-the-big-lie.md`](./phase-A-01-the-big-lie.md) — "Containers don't exist" mindset shift + the village analogy
- [`phase-A-02-namespaces.md`](./phase-A-02-namespaces.md) — The 7 Linux namespaces, what each isolates, daily relevance
- [`phase-A-03-cgroups.md`](./phase-A-03-cgroups.md) — Resource limits (CPU, memory, exit code 137 explained)
- [`phase-A-04-build-a-container-by-hand.md`](./phase-A-04-build-a-container-by-hand.md) — 🎯 Live demo: build a container with ZERO Docker
- [`phase-A-04a-LAYMAN-step1-explained.md`](./phase-A-04a-LAYMAN-step1-explained.md) — 🍼 Layman walkthrough of Step 1 output (hospital analogy)

### Phase B — Image & Build Mastery *(in progress)*
> *"An image is not a file. It's a stack of read-only diffs."*

- [`phase-B-01-image-is-not-a-file.md`](./phase-B-01-image-is-not-a-file.md) — The mindset shift (image = manifest + frozen layer tarballs)
- [`phase-B-02-inside-an-image.md`](./phase-B-02-inside-an-image.md) — 🎯 Hands-on: `docker save` + `tar -xf` the account-service image and see every layer as a file
- [`phase-B-03-the-layer-cache.md`](./phase-B-03-the-layer-cache.md) — 🕒 Stopwatch demo: same Dockerfile, different order = 13x build time

### Phase C — Networking Deep Dive *(not started)*
### Phase D — Storage Clarity *(not started)*
### Phase E — Debugging Like a Senior *(not started)*
### Phase F — The K8s Bridge *(not started)*

---

## 🎯 The North Star

By the end of this archive, I should be able to:

1. Explain "what is a container?" to my mom using the **village analogy**
2. Build a container **by hand** using only Linux commands (no Docker)
3. Debug a "Restarting" container with a **7-step systematic workflow**
4. Reduce any Docker image size by **at least 60%** using known techniques
5. Explain `docker-compose up` step-by-step (network creation, DNS resolution, dependency order)
6. Walk into Kubernetes and say *"Pods? That's just shared NET namespace — I've seen this before."*

---

## ✅ Progress tracker

| Phase | Status | Date |
|-------|--------|------|
| Diagnostic | ✅ Done | 2026-05-16 |
| A1 — Big Lie | ✅ Done | 2026-05-16 |
| A2 — Namespaces | ✅ Done | 2026-05-16 |
| A3 — cgroups | ✅ Done | 2026-05-16 |
| A4 — Container by hand | ✅ Done (kernel OOM-killed at 50MB limit when stressed → exit 137 witnessed) | 2026-05-18 |
| **Phase A complete — Docker rating 4.4 → 6/10** | ✅ | 2026-05-18 |
| B1 — Image is not a file | ✅ Done (self-check passed: 6, 8.5, 9 /10) | 2026-05-18 |
| B2 — Inside an image (hands-on) | ✅ Done (self-check 8/10; found 122MB layer = 88% of image) | 2026-05-18 |
| B3 — The layer cache | ✅ Done (stopwatch proved 8x; user coined "plumbing before furniture") | 2026-05-19 |
