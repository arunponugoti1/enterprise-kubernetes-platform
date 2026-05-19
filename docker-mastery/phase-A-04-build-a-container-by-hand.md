# 🎭 Phase A — Act 4: Build a Container BY HAND (No Docker)

> **The "aha!" moment of the entire Docker journey.**
>
> By the end of this file, you will have created a "container" using ONLY Linux commands. Zero Docker. After this, you will physically *feel* that Docker is just a wrapper.

---

## ✅ COMPLETED — 2026-05-18

**Status:** Hands-on done in Ubuntu WSL.

**What was witnessed live:**
- Created a PID namespace with `unshare` → saw self as PID 1
- Changed hostname inside the namespace → host machine hostname unaffected
- Built a cgroup with `memory.max = 50M`
- Ran a stress test that allocated MORE than 50MB → **kernel OOM-killed the process**
- Confirmed exit code **137** (128 + signal 9 = SIGKILL from OOM killer)

**The realization that locked it in:**
> *"I just built the exact thing Docker builds — using only `unshare`, `mount`, and a couple of files in `/sys/fs/cgroup`. Docker is a convenience wrapper, not magic."*

**Docker rating after this act: 4.4 → 6/10.** Move on to Phase B.

---

## ⚙️ Environment setup

You need a real Linux shell with `sudo`. Two options:

### Option 1: Ubuntu WSL (recommended)
From PowerShell:
```powershell
wsl -d Ubuntu
```

### Option 2: Privileged Docker container
From PowerShell:
```powershell
docker run -it --rm --privileged --name lab --pid=host ubuntu:22.04 bash
apt update && apt install -y util-linux procps stress-ng iproute2
```

⚠️ **Do NOT use the `docker-desktop` WSL distro** — it's a locked-down internal VM, no sudo, no full Linux.

### Sanity check
```bash
uname -r                              # Should show a Linux kernel version
which unshare                         # Should show /usr/bin/unshare
sudo whoami                           # Should print 'root'
stat -fc %T /sys/fs/cgroup/           # Should print 'cgroup2fs'
```

---

## 🎬 The plan

We will build a "container" in **5 steps**, each adding one layer of isolation:

| Step | What we add | What it gives us |
|------|-------------|------------------|
| 1 | Plain process | Baseline (no isolation) |
| 2 | PID namespace | Own process list (PID 1) |
| 3 | UTS namespace | Own hostname |
| 4 | NET namespace | Own network stack |
| 5 | cgroup memory limit | Resource cap (can OOM-kill it!) |

At the end you'll have a process that **acts like a Docker container** but was created with raw Linux commands.

---

## STEP 1 — Baseline: a plain Bash process

```bash
# Open a normal bash and see PIDs
echo "Host PID of this shell: $$"
ps aux | head -5
hostname
ip a | head -10        

# Note your real IP interfaces
```

📌 **Observe:** You see all host processes, real hostname, real network interfaces.
This is what "no container" looks like. Note everything for comparison.

---

## STEP 2 — Add a PID namespace

```bash
# Spin up a new bash inside a PID namespace
sudo unshare --pid --fork --mount-proc bash

# Now INSIDE the new shell:
echo "My PID is: $$"
ps aux
```

🤯 **What you should see:**
- `$$` = **1** (you are PID 1!)
- `ps aux` shows only **bash and ps** — not the host's processes
- This is exactly what a container sees

📌 **Why `--mount-proc`?** `ps` reads from `/proc`. Without remounting `/proc` for the new PID namespace, you'd still see the host's processes. The `--mount-proc` flag fixes that.

📌 **The "trick":** You're still on the same kernel, same machine. But the kernel is showing you a *filtered view* of processes. **That's a namespace.**

Type `exit` to leave when ready.

---

## STEP 3 — Add a UTS namespace (own hostname)

```bash
# Combine PID + UTS namespaces
sudo unshare --pid --uts --fork --mount-proc bash

# Inside:
hostname                # Still shows host hostname
hostname my-fake-container
hostname                # Now shows my-fake-container
exit
hostname                # Back on host — original hostname unchanged ✅
```

🤯 **What you proved:** You changed the hostname inside the "container" but the host's hostname stayed the same.
**That's UTS namespace isolation.**

---

## STEP 4 — Add a NET namespace (own network)

```bash
sudo unshare --pid --uts --net --fork --mount-proc bash

# Inside:
ip a                    # 😱 Only 'lo' (loopback) — no eth0!
ip link set lo up       # Bring loopback up
ping -c 2 127.0.0.1     # Works (own loopback)
ping -c 2 8.8.8.8       # ❌ FAILS — no network connection
exit
```

🤯 **What you proved:**
- Inside the namespace: **completely separate network stack**, no internet access
- The kernel literally hid all the network interfaces
- This is exactly what a container sees before Docker wires up `eth0` via `veth` pairs

🔑 **K8s bridge moment:** Two containers in a Pod sharing this single `lo` interface = they can talk via `localhost`. **That's the entire mechanism.**

---

## STEP 5 — Add a cgroup memory limit

Now the **other half** — resource limits via cgroups v2.

```bash
# Create a cgroup directory (just `mkdir` — it's a virtual filesystem!)
sudo mkdir /sys/fs/cgroup/my-container

# Set memory limit to 50 MB
echo "50M" | sudo tee /sys/fs/cgroup/my-container/memory.max

# Check the limit
cat /sys/fs/cgroup/my-container/memory.max

# Add the current shell to this cgroup (its PID)
echo $$ | sudo tee /sys/fs/cgroup/my-container/cgroup.procs

# Verify which cgroup we're in
cat /proc/self/cgroup
```

🤯 **Look what just happened:** You created a cgroup by **making a folder**. You set a limit by **writing to a file**. The Linux kernel exposes the entire control system as a filesystem.

### Now stress-test it

Install stress tool if needed (`sudo apt install stress-ng`):

```bash
# Try to allocate 200 MB — but limit is 50 MB
stress-ng --vm 1 --vm-bytes 200M --vm-keep
```

💥 **Boom.** Within seconds you'll see:
```
stress-ng: error: ... killed
```
The kernel **OOM-killed** the process because it hit the cgroup's memory limit.

**Check the exit code:**
```bash
echo $?       # Should be 137 — the signature of OOM kill!
```

🎯 **You just proved exit code 137 with your own hands.**

---

## STEP 6 — Cleanup

```bash
# Remove the cgroup (it must be empty first — processes moved out)
sudo rmdir /sys/fs/cgroup/my-container
```

---

## 🧠 The moment of realization

Pause and reflect. What just happened?

✅ You created a **process with its own PID list** (PID namespace) → like a Docker container
✅ You gave it **its own hostname** (UTS namespace) → like a Docker container
✅ You gave it **its own network** (NET namespace) → like a Docker container
✅ You **limited its memory** (cgroup) → like `docker run --memory=50m`
✅ You watched the kernel **OOM-kill it** with exit code 137 → like a real prod container crash

**You did this with `unshare`, `mkdir`, `echo`, `cat`.**
**No Docker daemon. No image. No registry. No Dockerfile.**

> **Docker is `unshare` + `mkdir` + `echo` + a friendly UI.**

---

## 🪞 Self-check after Act A4

1. What does `unshare --pid --fork --mount-proc bash` actually do?
2. Why does `ps aux` inside the namespace only show 2-3 processes?
3. Why is creating a cgroup just `mkdir`?
4. Walk through how `docker run --memory=50m alpine` translates to what you did manually.
5. **Bonus:** If you ran `unshare` WITHOUT `--net`, would two such "containers" be able to talk to each other on `localhost`?

---

## 💎 Mentor lines from this act

> *"Docker is `unshare` + cgroup files + a friendly UI."*

> *"A namespace is a folder in disguise. A cgroup is a folder in disguise. The whole 'container revolution' is the Linux kernel exposing its features as filesystems we can write to."*

> *"When `docker run` happens, the kernel doesn't create a 'container.' It creates a process, gives it filtered views via namespaces, and writes some limit numbers into cgroup files. That's it."*

---

## ➡️ End of Phase A

After completing Act A4 successfully, you have **earned a Docker rating of 6/10**.

Up next: **Phase B — Image & Build Mastery.**
We'll dissect what an image actually IS (spoiler: stacked tarballs), why layer ordering matters, and rebuild your `account-service` image to be 10x smaller.
