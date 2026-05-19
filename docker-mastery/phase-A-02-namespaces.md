# 🎭 Phase A — Act 2: Namespaces — "What can you SEE?"

> Namespaces = the **isolation** part of containers.
> They control **what a process can see** of the rest of the system.

There are **7 namespace types** in Linux. Each isolates *one specific thing*.

Keep the village analogy in your head while reading each one.

---

## 1️⃣ PID Namespace — "Your own villager list"

**What it isolates:** Process IDs.

**Without it:** Run `ps aux` inside a container, you'd see every process running on the host.

**With it:** Inside the container, your app is **PID 1**. It can only see processes inside its own compound.

**Why it matters:**
- 🔒 Security — can't kill host processes
- 🎭 Illusion of being alone (which is why your app's `init` becomes PID 1 inside containers — a subtle but important behavior)

**Relevance:** ⭐⭐⭐

---

## 2️⃣ NET Namespace — "Your own phone line" 🔑

> **This is the MOST IMPORTANT namespace for daily DevOps work.**

**What it isolates:** Network interfaces, IP addresses, routing tables, iptables rules, port numbers.

**With it:** The container has its OWN:
- `eth0` interface
- `lo` (localhost)
- Port 8080 — completely separate from the host's port 8080
- Routing table
- Firewall rules

**Why it matters:**
- Q5 (how postgres finds account-service) = solved by NET namespace + Docker DNS
- Q10 (pod containers sharing localhost) = literally one shared NET namespace
- Every networking question in Docker/K8s comes back to this

**🔑 K8s bridge:** When Pod containers share `localhost:port`, they share **one NET namespace**. We'll prove it live in Act A4.

**Relevance:** ⭐⭐⭐⭐⭐

---

## 3️⃣ MNT Namespace — "Your own well / filesystem view"

**What it isolates:** Filesystems and mount points the process can see.

**With it:** Container sees its own `/`, `/usr`, `/etc`, `/var`. Physically these files live somewhere in `/var/lib/docker/overlay2/...` on the host, but the container thinks it's looking at a fresh root filesystem.

**Why it matters:**
- This is how a container can have **Ubuntu** inside while the host runs **Alpine** — different filesystems, **same kernel**.
- Every "file not found inside container but exists on host" question = MNT namespace.

**Relevance:** ⭐⭐⭐⭐

---

## 4️⃣ UTS Namespace — "Your own welcome board (hostname)"

**What it isolates:** Hostname and domain name.

**With it:** `hostname` inside the container returns something like `a3f9b2c8d1` (the container ID), not your laptop's hostname.

**Why it matters:**
- Apps that identify themselves by hostname (databases, clustering software like Kafka/RabbitMQ) can run independently without name collisions.

**Fun fact:** UTS = "Unix Timesharing System" — historical name. Just remember **"hostname namespace."**

**Relevance:** ⭐⭐

---

## 5️⃣ IPC Namespace — "Your own notice board"

**What it isolates:** Inter-process communication primitives — shared memory segments, semaphores, message queues.

**With it:** A container can't read another container's shared memory.

**Why it matters:** Mostly security. You'll rarely interact with this directly.

**Relevance:** ⭐

---

## 6️⃣ USER Namespace — "Your own family head ID system"

**What it isolates:** User IDs (UIDs) and Group IDs (GIDs).

**With it (advanced):** Root inside the container (UID 0) can be **mapped to a non-root user** (UID 1000) on the host. So even if the app inside the container is "root," it's not actually root on your laptop.

**Why it matters:**
- 🔒 **Security gold.**
- "Rootless containers" — a growing best practice — rely entirely on USER namespaces.
- If a container escape happens, attacker is just user 1000 on the host, not root.

**Relevance:** ⭐⭐⭐ (security-focused)

---

## 7️⃣ CGROUP Namespace — "Your own usage report card view"

**What it isolates:** The *view* of cgroup hierarchies (NOT the limits themselves — just the view from inside).

**Why it matters:** Mostly cosmetic / security. Don't stress about this one.

**Relevance:** ⭐

---

## 📌 The Summary Table — MEMORIZE THIS

| Namespace | Isolates | Village analogy | Daily relevance |
|-----------|----------|-----------------|-----------------|
| **PID** | Process IDs | Villager list | ⭐⭐⭐ |
| **NET** | Network stack | Phone line | ⭐⭐⭐⭐⭐ |
| **MNT** | Filesystem mounts | Well / water | ⭐⭐⭐⭐ |
| **UTS** | Hostname | Welcome board | ⭐⭐ |
| **IPC** | Shared memory | Notice board | ⭐ |
| **USER** | User IDs | Family head ID | ⭐⭐⭐ (security) |
| **CGROUP** | cgroup view | Report card view | ⭐ |

**The two you must master: NET and MNT.**
**The rest: know they exist + what they isolate.**

---

## 🧪 The mind-blowing recap

When `docker run nginx` happens:

```
Docker → Kernel: "create a new process with its own:
                  PID, NET, MNT, UTS, IPC, USER namespaces"
Kernel → Docker: "done. Process exists. PID 1 from its view, 24871 from mine."
Docker → that process: "now execute /usr/sbin/nginx"
Docker → cgroups: "limit this process to 512MB RAM, 0.5 CPU"
```

**That's it. That's all Docker is doing at runtime.**

---

## 🪞 Self-check before moving on

Answer in your own words (no Googling):

1. Why does the sentence *"containers don't exist in Linux"* make sense now?
Ans: yes now understood docker created this word but fundamentally it is utilizing the namespace and c-groups it is the heart of the container isolating the application and managing the resouces using resources that's it 
2. In the village analogy, what does the **kernel** play the role of?
is like a land owner who hire the pople and give the hardware to work, i have another analogy also, like a builder who owns the land where he build the floors and give to the customers to sell then users buy it and use thier own toilet, bed room, elecricity etc
3. If a Pod has 2 containers sharing `localhost`, which **namespace** are they sharing?
NET-Namespace:here we have routes, address etc
4. What's the difference between *"what you can see"* and *"how much you can use"* in container terms?
 1.namespaces, 2. c-groups 

If you can answer these 4 → you've absorbed Acts A1 + A2.
If you stumble → re-read the relevant section, or ask for a different analogy.

---

## ➡️ Next file: `phase-A-03-cgroups.md`
We cover the OTHER half — resource limits.
