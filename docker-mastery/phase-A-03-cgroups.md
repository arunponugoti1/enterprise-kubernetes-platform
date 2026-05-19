# 🎭 Phase A — Act 3: cgroups — "How MUCH can you use?"

> Namespaces controlled **what a process can SEE**.
> cgroups control **how much a process can USE**.
>
> Together = container.

---

## 🧠 The core idea

**cgroups** = "control groups" — a Linux kernel feature that groups processes together and applies **resource limits and accounting** to that group.

In one sentence:
> *cgroups are the kernel's way of saying: "this group of processes can use a maximum of X CPU, Y RAM, Z disk I/O, and W network bandwidth — and I'll keep track of how much they're actually using."*

---

## 🏘️ The Village Analogy (continued)

Recall Act A1: families live in walled compounds (namespaces).

Now the village panchayat (kernel) installs **meters** at each compound's gate:

| Meter | What it measures/limits | Real cgroup |
|-------|-------------------------|-------------|
| ⚡ Electricity meter | How much power per day | `cpu` cgroup |
| 💧 Water meter | How many buckets per day | `memory` cgroup |
| 🚪 Door open/close counter | How many entries/exits | `pids` cgroup (process count) |
| 📞 Phone call meter | How many calls allowed | `net_cls` / network cgroup |
| 📦 Storage meter | How much godown space | `blkio` cgroup (disk I/O) |

**Without meters:** One greedy family drains the whole village.
**With meters:** Panchayat enforces fairness. *"Family A has used 95% of allowed water — block further usage."*

👉 **That's exactly what cgroups do** for processes on a Linux machine.

---

## 🪪 The two jobs of cgroups

cgroups do **two things at once**:

### Job 1: **Limit** (the wall)
*"You can use AT MOST 512 MB RAM. If you try more → you get OOM-killed."*
*"You can use AT MOST 0.5 CPU cores. If you ask more → you get throttled."*

### Job 2: **Account** (the meter reading)
*"Right now this group is using 312 MB RAM and 0.3 CPU cores."*

This is why `docker stats` works — it reads cgroup accounting data.

---

## 🎛️ The major cgroup controllers (what you'll meet in real life)

| Controller | What it controls | Docker flag | K8s equivalent |
|------------|------------------|-------------|----------------|
| **cpu** | CPU shares, quotas, throttling | `--cpus="0.5"` | `resources.limits.cpu: 500m` |
| **memory** | RAM cap + swap behavior | `--memory="512m"` | `resources.limits.memory: 512Mi` |
| **pids** | Max number of processes | `--pids-limit=100` | (less commonly used) |
| **blkio** | Disk I/O bandwidth | `--device-read-bps` | (less commonly used) |
| **net_cls** | Network traffic classification | (rarely user-facing) | (network policies) |
| **devices** | Which devices the group can access | `--device=/dev/...` | (security context) |

**The two you'll touch every day: `cpu` and `memory`.**

---

## ⚡ What happens when limits are hit?

This is critical to understand for production debugging.

### Memory limit hit
- Kernel triggers **OOM killer** (Out Of Memory)
- The process gets **SIGKILL** (cannot be caught, cannot clean up)
- Container exits with **exit code 137** (= 128 + 9, where 9 = SIGKILL)
- 👉 **This is the #1 reason containers mysteriously die in production**

### CPU limit hit
- Process gets **throttled** (not killed)
- Kernel gives it less CPU time per scheduler cycle
- App keeps running, just slower
- 👉 Shows up as **latency** issues, not crashes

### PID limit hit
- New `fork()` calls fail
- App can't spawn new threads/processes
- 👉 Shows up as weird "resource temporarily unavailable" errors

---

## 🔑 Why this matters for daily DevOps

### Scenario 1: "My container keeps getting killed"
- `docker ps -a` → exit code 137
- = OOM killed
- = Memory cgroup limit reached
- 👉 Either raise the limit OR find the memory leak

### Scenario 2: "My app is slow inside the container but fast on my laptop"
- Check `docker inspect` for CPU limits
- Likely CPU cgroup is throttling the process
- 👉 Raise `--cpus` value OR optimize hot path

### Scenario 3: "How does docker stats work?"
- It reads cgroup accounting files in `/sys/fs/cgroup/...`
- Same data Kubernetes' Metrics Server reads
- 👉 Same underlying mechanism — different UI

---

## 📂 Where cgroups live (file-system level)

cgroups are exposed as a **virtual filesystem**. On modern Linux (cgroups v2):

```
/sys/fs/cgroup/
├── cpu.max          ← CPU limit
├── memory.max       ← Memory limit
├── memory.current   ← Current usage
├── pids.max         ← Process count limit
└── docker/
    └── <container-id>/
        ├── cpu.max
        ├── memory.max
        └── memory.current
```

**This is HUGE:**
- Limits are written as plain text into files
- You can `cat memory.current` to see live usage
- You can `echo "200M" > memory.max` to *change* a limit on the fly
- No Docker required — just kernel + filesystem

👉 We'll touch these files directly in Act A4.

---

## 🧮 The two halves come together

| Question | Answer |
|----------|--------|
| What can the process SEE? | **Namespaces** |
| How much can the process USE? | **cgroups** |
| What's a container? | **A process + namespaces + cgroups** |
| What does Docker do? | **Sets up the namespaces and writes the cgroup files for you** |

---

## 💎 Mentor sentences to memorize

> *"Namespaces give a process its own world. cgroups put walls around how much of the real world it can consume. Docker is the friendly tool that wires both up in one command."*

> *"Exit code 137 = the kernel killed your container because it hit the memory cgroup limit. The container didn't crash — the kernel assassinated it."*

---

## 🪞 Self-check before Act A4

Answer in your own words:

1. What are the **two jobs** of cgroups?
    1. limiting the resources
    2. accountant
2. If a container exits with code **137**, what almost certainly happened?
so we limit the resources using c-groups so when the applciation is  using the resources more then attched then the kernal will OOM killed , it will kill the process
3. Why does a CPU-limited container **not crash** but get slow?
ans: it is kind of compressable , like you wanna vote so the gate keeper says wait , others should come back from inside the room, thats why it late, wait kind of latency, if someone wanna go 2nd time for vote he won't allow , infact he say get out that is OOM killed 
4. Where do cgroup limits physically live on the Linux filesystem?
/sys/fs/c-groups
5. When you run `docker stats`, where is that data coming from?
/sys/fs/c-groups , it will get the data and give realtime info

---

## ➡️ Next file: `phase-A-04-build-a-container-by-hand.md`
**The "aha!" moment.** We'll use your Ubuntu WSL to create a container with ZERO Docker — just `unshare`, `nsenter`, and writing into cgroup files. By the end, you'll *feel* Docker as a wrapper.
