# Terraform Skills Diagnostic — Results & Review

> **Date:** 2026-05-19
> **Format:** Self-answered 10-question diagnostic, reviewed by Claude
> **Purpose:** Identify gaps before moving deeper into Terraform/GKE work

---

## 📋 The Questions & Your Answers (with grading)

### 🟢 Easy (Foundation)

---

### Q1. What does `terraform apply` actually DO?

**Your answer:**
> terraform apply --auto-approve then it will check the existing statefile if these resources already exist or not, not check console, then if the resource already exist it will not do recreate it, if it has any changes or for the first time then it will create or recreate the infra, update in the state file and update in the console and it will lock while applying so any other guy should not use it.

**Rating: 8/10** ✅

**What you got right:**
- ✓ Checks **state file** (not console) — this is THE most important mental model and you got it
- ✓ Won't recreate if already exists
- ✓ Updates state file + console
- ✓ Locks during apply

**What's missing:**
- There's a **refresh phase BEFORE diff** — Terraform DOES call GCP API to check current real state (to detect drift), but compares the result against state file
- Full internal flow: `Read config → Read state → Refresh (API call) → Diff → Plan → Apply → Update state → Release lock`

**Verdict:** Strong foundation. Right mental model.

---

### Q2. `terraform plan` vs `terraform apply` — why does plan exist?

**Your answer:**
> the plan is just a blue print and shows any format, syntax issues and if all the things good shows what resources are going to create or recreate or destroy, apply means real changes it will change in the statefile and in console.

**Rating: 6/10** ⚠️

**What you got right:**
- ✓ Plan = blueprint, shows syntax issues
- ✓ Plan shows create/recreate/destroy
- ✓ Apply = real changes

**What you missed — the "WHY plan exists" part:**
1. **Safety net** — review before destruction (especially `-/+ replace` operations)
2. **CI/CD gating** — `terraform plan -out=tfplan` → human approves → `terraform apply tfplan` (no surprises)
3. **Cost estimation** — tools like Infracost run on the plan
4. **Team review** — post plan output in PR for review

**Verdict:** You explained the *what* but not the *why*. In interviews, "why does X exist" questions test if you understand engineering tradeoffs.

---

### Q3. What is a provider? Give an example.

**Your answer:**
> provider is a gateway api like in what cloud you want to provision the infra using terraform there we have provide the cloud details so it, terraform will check which cloud, version permissions then it will enter onto the cloud.

**Rating: 6/10** ⚠️

**What you got right:**
- ✓ Gateway/API concept
- ✓ Tells Terraform which cloud
- ✓ Needs credentials/permissions

**What you missed:**
- **No concrete example given** — like `google`, `aws`, `azurerm`, `kubernetes`, `helm`
- Providers are **plugins** — downloaded during `terraform init` into `.terraform/` folder
- They **translate HCL → cloud API calls**
- One Terraform config can use MANY providers (e.g., `google` + `kubernetes` + `helm` for a GKE deployment)

**Verdict:** Right idea, but vague. Always give a concrete example when asked.

---

### 🟡 Medium (Mental Model)

---

### Q4. What is `terraform.tfstate`? What if you delete it?

**Your answer:**
> state file is a single source of truth, terraform only validate statefile not console, it doesn't care console, if you delete the statefile then reapply the same resources it will again create because it feels there is nothing inside the state file related to the resources we deleted.

**Rating: 8/10** ✅

**What you got right:**
- ✓ Single source of truth
- ✓ Terraform validates against state, not console
- ✓ If deleted → Terraform re-creates because state thinks nothing exists

**What's missing:**
- **Real disaster:** Terraform tries to create resources that ALREADY EXIST in GCP → API errors like "VPC name already taken" → blocked apply
- `terraform.tfstate.backup` keeps last good state
- **Remote state** (GCS/S3) prevents this — local state is fragile
- Recovery option: `terraform import` to rebuild state piece by piece (painful but possible)

**Verdict:** Excellent. Add the "duplicate resource error" detail and you're at 10/10.

---

### Q5. Two engineers run `terraform apply` simultaneously?

**Your answer:**
> this is most imp and great feature in terraform the person who apply the first it will lock for him, it will change 2nd person apply until it finishes 1st person apply. after finish it will release for the 2nd person.

**Rating: 9/10** 🌟

**What you got right:**
- ✓ First person locks
- ✓ Second person waits
- ✓ Released after first finishes

**What's missing:**
- HOW the lock works: GCS uses object locks, S3 uses DynamoDB, Azure uses blob lease
- Local state = NO real locking (just a `.terraform.tfstate.lock.info` file, easily bypassed)
- Dangerous flag: `-lock=false` (never use in team setting)
- `terraform force-unlock <LOCK_ID>` for stuck locks

**Verdict:** Best answer in the easy/medium section. You really get this one.

---

### Q6. VPC, Subnet, Firewall Rule in GCP?

**Your answer:**
> VPC is just like a physical place where we build the building right, so the vpc is foundation without vpc we can't create the subnets, subnets are like floors in the building which separates the specific purposes, like if you have created subnets for gke you can separate for service few, for pods few, for node few like this we will segregate, subnets is nothing but IP addresses, firewall rule is like connection, communication rules whom to connect, where to connect, whom not to connect, it manages the communication, connection.

**Rating: 8/10** ✅

**Your building analogy is excellent! 🏢** (Exactly the kind of thinking that works for you.)

**What you got right:**
- ✓ VPC = foundation
- ✓ Subnets = floors with specific purpose
- ✓ Subnets = IP ranges
- ✓ Firewall = communication rules
- ✓ Subnet CANNOT exist without VPC

**What you missed — GCP-specific gotchas:**
- In GCP, **VPC is GLOBAL** (unlike AWS where VPC is regional) — unique GCP feature
- **Subnets are REGIONAL** in GCP
- **Firewall rules in GCP are at VPC level** (unlike AWS security groups which attach to instances)
- Subnet = CIDR block (e.g., `10.0.1.0/24`)
- GKE needs **secondary IP ranges** in subnet for Pods and Services (this'll matter for Phase 2)

**Verdict:** Solid. Now memorize the GCP specifics because GKE will trip you on them.

---

### Q7. What is a module? When to write/not write one?

**Your answer:**
> module is like a reusable template, if you wanna replicate same things multiple times then create the module and use it with min configuration, like if you wanna build for dev, uat and prod then create and use module, if your requirement is only for one time no need of module building.

**Rating: 8/10** ✅

**What you got right:**
- ✓ Reusable template
- ✓ Dev/UAT/Prod example
- ✓ Don't use for one-time

**What's missing:**
- **Inputs (variables) and outputs** — modules have a contract
- Source types: local (`./modules/vpc`), registry (`terraform-google-modules/...`), git (`git::https://...`)
- **Version pinning** for registry modules (critical for prod)
- **Anti-pattern:** Over-modularizing — wrapping every single resource in a module = useless abstraction
- Rule of thumb: Make a module when you'd copy-paste the same block 2-3 times

**Verdict:** Practical grasp. Add the inputs/outputs detail.

---

### 🔴 Hard (Real Engineer Questions)

---

### Q8. What is state drift? Whose fault is it?

**Your answer:**
> it is human fault, mismatch of statefile and actual resource in the console, if you modify anything in console or statefile manually then there will be a drift, we have to fix it by terraform apply.

**Rating: 7/10** ✅

**What you got right:**
- ✓ Human fault (mostly)
- ✓ Mismatch between state and reality
- ✓ Caused by manual console/state edits
- ✓ Fix mention

**What's missing — and this is where seniors test juniors:**
- **Not always human fault!** Examples:
  - Auto-scaling group changes node count → drift, but legitimate
  - GCP auto-applies security patches to OS images → drift
- **Detection workflow:**
  1. `terraform plan -refresh-only` → shows drift without changing anything
  2. `terraform apply -refresh-only` → updates state to match reality
  3. Then `terraform plan` → shows what code wants to change
- **Resource exists in console but NOT in state** → `terraform import google_compute_instance.my_vm projects/.../instances/...`
- **State has resource but it's gone in console** → `terraform state rm <resource>`

**Verdict:** You understand the concept. The toolbox (`refresh`, `import`, `state rm`, `state mv`) is what you need to learn.

---

### Q9. Workload Identity Federation — why better than JSON SA key?

**Your answer:**
> i know it is more secure then regular classic SA, it won't ask json file to upload, like in github action want to connect with gcp, gcp asks github actions prove me you are authorized and authenticated so it shows json file which created by SA. but in other hands workload identity we are providing, not much idea about it.

**Rating: 4/10** ⚠️

**Honesty appreciated** — you said you don't fully know. Better than bluffing.

**Building analogy explanation:**

**Old way (SA JSON key) — like giving someone a master key:**
- You create an SA in GCP
- You download the JSON file (a master key 🔑)
- You paste it into GitHub Secrets
- Anyone with GitHub admin can steal it
- Key works **forever** unless you rotate it manually
- If leaked → attacker has GCP access until you notice

**WIF way — like a one-time visitor pass at building reception:**
1. GitHub Actions runs your job
2. GitHub issues a short-lived **OIDC token** (an ID card saying "I am repo arunponugoti1/foo, branch main, workflow deploy.yml")
3. Your job presents this token to GCP's STS (Security Token Service)
4. GCP checks: "Do I trust GitHub as an identity provider? Is this repo allowed? Yes."
5. GCP gives back a **short-lived access token** (15 minutes)
6. Job uses that token to talk to GCP
7. Token expires automatically — no cleanup needed

**Why it's better:**
- ✓ **No long-lived secret** to leak
- ✓ **Scoped to repo/branch/workflow** — leaked token from one workflow can't be reused elsewhere
- ✓ **Auto-expires** in minutes
- ✓ **Audit-friendly** — GCP logs show "GitHub Actions workflow X assumed SA Y"

**Verdict:** This will come up in EVERY DevOps interview. Must know cold. Hands-on WIF setup needed.

---

### Q10. Change `machine_type` from `e2-small` → `e2-medium`. Step-by-step?

**Your answer:**
> first it will check existing infra in the statefile, if it shows e2-medium then it won't change if it has small then change to medium, and update in the statefile and then update in the console.

**Rating: 5/10** ⚠️

**What you got right:**
- ✓ Check state file
- ✓ Update if different
- ✓ Update state + console

**What you missed — the BIG one for senior interviews:**

Real step-by-step internal flow:

1. **Parse** all `.tf` files → build desired config
2. **Initialize providers** (already done if `init` ran)
3. **Acquire state lock**
4. **Refresh** — call GCP API for ACTUAL current state of the VM (not just state file)
5. **Build dependency graph** (which resource depends on what)
6. **Diff:**
   - State says `e2-small`
   - Code says `e2-medium`
   - GCP says (from refresh) `e2-small`
   - Diff = needs change
7. **Determine update strategy** — THIS IS THE KEY POINT:
   - For `machine_type` on a GCE VM → Terraform must **STOP the VM, change machine_type, START it** (downtime!)
   - For some attributes → **destroy + recreate** (replacement marked as `-/+` in plan) → data loss possible
   - For others → **in-place update** (no downtime)
8. **Show plan** to user
9. **Execute** — API calls in dependency order
10. **Update state file** with new attributes
11. **Release lock**

**The senior insight:** Not all changes are equal. Some are zero-downtime, some need stop/start, some need full replace. ALWAYS read the plan output for `-/+` markers (means destroy+recreate).

**Verdict:** You answered the easy version. The hard version asks about update strategies — where production engineers get burned.

---

## 📊 Overall Score

| Section | Score | % |
|---------|-------|---|
| Easy (Q1-3) | 20/30 | 67% |
| Medium (Q4-7) | 33/40 | 83% |
| Hard (Q8-10) | 16/30 | 53% |
| **TOTAL** | **69/100** | **69%** |

**Honest assessment for a Support→DevOps transition:**
- 🎯 You're at a **strong junior** level
- 💪 **Strengths:** State file mental model, locking, modules, infrastructure intuition (VPC building analogy)
- 🔧 **Weaknesses:** Internal Terraform workflow depth, WIF mechanics, update strategies (replace vs in-place)

---

## 🎯 What's Next — Priority Order

### **Priority 1: Hands-on WIF setup** 🔴
Cannot call yourself DevOps without this.
1. Set up WIF for GitHub → GCP connection
2. Remove any SA JSON keys currently in use
3. Build a workflow that deploys using WIF
- **Time:** 2-3 hours, one focused session

### **Priority 2: Master the state toolbox** 🟡
Learn these commands by **breaking and fixing** state:
- `terraform refresh` / `plan -refresh-only`
- `terraform import`
- `terraform state list / show / rm / mv`
- Deliberately cause drift in a sandbox project and fix it

### **Priority 3: Update strategies deep dive** 🟡
- Read plan outputs and identify: `~` (in-place) vs `-/+` (destroy+recreate)
- Learn `lifecycle` block: `prevent_destroy`, `create_before_destroy`, `ignore_changes`
- Prevents accidental data loss in prod

### **Priority 4: Build a real GKE Terraform module** 🟢
This is Phase 2:
- VPC + subnets with secondary ranges for Pods/Services
- GKE cluster with WIF for workloads
- Node pool with proper labels/taints
- Output kubeconfig

---

## 💡 Recommendation

**Don't jump to next Terraform topic yet.** Instead:
1. Re-answer Q9 and Q10 after the explanations above → see if it sticks
2. Do a **hands-on WIF setup** session (closes biggest gap)
3. Then move to the GKE Terraform module for Phase 2
