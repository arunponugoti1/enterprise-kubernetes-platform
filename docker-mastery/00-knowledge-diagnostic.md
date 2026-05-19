# 📊 Docker Knowledge Diagnostic — Starting Point

**Date taken:** 2026-05-16
**Final score:** **4.4 / 10** — *"Solid Junior — knows enough to be dangerous, not enough to be deep."*

---

## The 10 Questions + My Answers + Scoring

### 🟢 Easy

#### Q1. What is a Docker container? (Explain to your mom)
**My answer:** Docker container is like a full package bag. Every day I go to office — I don't use one bag for charger, one for laptop, one for lunch. All in one college bag with separate sections, with zip. Same way — application code, libraries, dependencies, runtime env, env variables, ports — all required to run one app. Locally it works, but shipping to another laptop is hard — if something's missing app won't come up. Container resolves this: package as one box (= image) and run anywhere (= container).

**Score: 8/10** 🌟 — Mentor-quality analogy.
**Missing for 10:** Didn't mention *isolation* aspect or VM-vs-container contrast.

---

#### Q2. Image vs Container — analogy?
**My answer:** Image is a template / rule book — what exists, what runs first, like opening lunchbox first then laptop charger. Container is the server runtime — executes instructions using image, needs CPU + memory.

**Score: 6/10** — Direction right, analogy tangled (described Dockerfile, not image).

**Cleaner mental model:**
- **Dockerfile** = recipe on paper (instructions)
- **Image** = frozen meal-prep box built from recipe (read-only, *layered*)
- **Container** = meal being eaten right now (runtime instance, thin *writable* layer on top)

---

#### Q3. What does `docker-compose up` do?
**My answer:** docker-compose is a manager that manages containers, what should connect to what. Like an automation pipeline that runs all containers at the same time.

**Score: 3/10** — Surface only.

**What actually happens (must memorize):**
1. Parses `docker-compose.yml`
2. Creates a **default bridge network** for the project
3. Pulls or builds each image
4. Creates named volumes
5. Creates containers in dependency order (`depends_on`)
6. Connects each container to the network
7. Starts them, attaches logs

---

### 🟡 Medium

#### Q4. Dockerfile has 10 lines, you change line 8 — what rebuilds?
**My answer:** Layer-based image creation. Runs layer by layer. Change line 8 → rebuild starts from that line.

**Score: 4/10** — Knew symptom, not mechanism.

**The truth:**
- Each line creates an **immutable layer** with a content hash
- Change line 8 → layer 8's hash changes → **layers 8, 9, 10 all rebuild**
- **Practical superpower:** Put rarely-changing things EARLY (`COPY package.json` + `npm install`) and frequently-changing things LATE (`COPY . .`). This is why `account-service/Dockerfile` does `COPY package*.json ./` *before* `COPY . .`.

---

#### Q5. How does account-service find postgres in compose?
**My answer:** Give postgres info to account-service via host name, username, password env vars. Compose resolves DNS via env variables.
*(My honest note: "I think I gave random understanding, if you ask me to prove I can't.")*

**Score: 3/10** — Honest gap.

**The real magic:**
- docker-compose creates a default network for the project
- Inside it, Docker runs an **embedded DNS server at 127.0.0.11**
- When account-service does `connect("postgres:5432")` → Docker DNS resolves `postgres` → postgres container's internal IP
- **The service NAME becomes the DNS hostname.**
- **K8s does the same thing** with CoreDNS — Services are reachable by name.

---

#### Q6. COPY vs ADD, Volume vs Bind mount, EXPOSE vs -p
**My answers:**
- COPY: copy files from local to image ✅
- ADD: ❌ don't know
- Volume: storage directory, like a disk bucket 🟡 roughly right
- Bind mount: ❌ described as "communication network" (wrong)
- EXPOSE 8080: 🟡 says "opens port 8080 by default" (misleading)
- -p 8080:8080: localhost:container port mapping ✅

**Score: 4/10**

**Corrections:**
| Item | Reality |
|------|---------|
| ADD | Same as COPY + auto-extracts tar files + can fetch URLs. **Rule: always use COPY** unless you need ADD's extras. |
| Volume | Docker-managed storage in `/var/lib/docker/volumes`, survives container death |
| Bind mount | Mounts a **host directory** into container (e.g., `/home/user/code:/app`). Used for dev — edit on host, live in container. NOT a network. |
| EXPOSE | **Just documentation/metadata** — does NOT open any port. Common misconception. |
| -p (or `ports:`) | The *only* thing that actually publishes a port. |

---

#### Q7. Image is 1.2 GB — how to reduce?
**My answer:** Single-stage Dockerfile = bloated. Use multi-stage: stage 1 (heavy base, install everything), stage 2 (lightweight base, copy only built artifacts + app code).

**Score: 6/10** — Got the #1 lever.

**Missing techniques for 9/10:**
- `.dockerignore` to skip `node_modules`, `.git`, logs from build context
- Combine `RUN` commands: `RUN apt-get update && apt-get install -y X && apt-get clean && rm -rf /var/lib/apt/lists/*`
- Alpine vs slim vs **distroless** base images (distroless = no shell, ~20MB)
- Pin versions to avoid bloat surprises

---

### 🔴 Hard

#### Q8. What actually isolates a container? Docker? Kernel?
**My answer:** Heard of cgroups and namespaces (Linux concepts) but don't know what they are, why, how, where.

**Score: 2/10** ⚠️ — **Biggest gap. Phase A target.**

**The truth:**
- **Docker isolates NOTHING.** Docker is a *user-friendly wrapper* over Linux kernel features.
- **Linux kernel does the isolation** via:
  - **Namespaces** = *what you can see* (7 types: PID, NET, MNT, UTS, IPC, USER, CGROUP)
  - **cgroups** = *how much you can use* (CPU, memory, disk I/O, network)
- A container = a process with its own namespaces + cgroup limits. That's it.

---

#### Q9. Container keeps restarting every 30s — debug?
**My answer:** See logs, see events, check CPU/memory.

**Score: 3/10** — Right direction, no real workflow.

**The systematic 7-step workflow (must build muscle memory):**
1. `docker ps -a` → see exit code (137=OOM, 1=app error, 139=segfault)
2. `docker logs <container> --tail 50` → last output before crash
3. `docker inspect <container>` → restart policy, entrypoint, env vars
4. `docker logs --previous` → previous run's logs
5. Check: missing env var? Wrong port? OOM killed? Healthcheck failing? Missing dep container?
6. If logs empty → entrypoint failing before app starts → `docker run -it --entrypoint sh <image>` to poke around
7. Reproduce + fix

---

#### Q10. Pod with 2 containers sharing localhost — how?
**My answer:** Pod runs like a single machine, two containers inside treat it as local, talk on localhost:port — like a Docker network.

**Score: 5/10** — Right intuition, missed the mechanism.

**The actual trick:**
- Containers in a Pod share a **NET namespace** (and sometimes more).
- Same `lo`, same `eth0`, same port space → `localhost:8080` works because they're literally on the same network from the kernel's view.
- **In plain Docker:** `docker run --network container:<other-container-name>` does this.
- **K8s implementation:** A special "pause" container holds the namespace; all app containers in the Pod join it.
- **This is the single best Docker→K8s bridge.**

---

## 📊 Gap Map (priority order)

| # | Gap | Severity | Phase |
|---|-----|----------|-------|
| 1 | **Namespaces + cgroups** | 🔴 Critical | A |
| 2 | **Docker networking & DNS** | 🔴 Critical | C |
| 3 | **Layer caching mechanism** | 🟠 High | B |
| 4 | **Bind mount vs Volume** | 🟠 High | D |
| 5 | **Debugging workflow** | 🟠 High | E |
| 6 | **Image internals (layered/read-only)** | 🟡 Medium | B |
| 7 | **EXPOSE misconception** | 🟡 Medium | B |

---

## ✅ Strengths to keep

1. **Analogy instinct** — Q1's bag explanation is mentor-grade.
2. **Multi-stage builds** — Q7 was solid.
3. **Right intuition** — Q10 felt the answer without knowing the mechanism.
4. **Honesty** — "if you ask me to prove it, I can't" is the most useful self-awareness a mentor can have.
