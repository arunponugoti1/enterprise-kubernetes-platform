# 📊 Terraform + GCP Knowledge Diagnostic — Starting Point

> **Date taken:** _(fill in when you take it)_
> **Self-rating going in:** 2 / 10
> **Final score:** _(filled in after we score together)_

---

## 📋 Rules of engagement (READ THIS BEFORE ANSWERING)

1. **Answer in your OWN words.** No Google, no Claude, no rereading the project docs while answering. You're testing what's actually in your head, not what's in a tab.
2. **It is OKAY to write "I don't know."** Honest "don't know" scores higher than confident wrong. From `Q-PHASE.md`: *"Vague understanding = no understanding. Specific or nothing."*
3. **Write the answer out** — don't just *think* it. The act of writing exposes the gap. If you'd be embarrassed to read it to a senior engineer, that's the signal.
4. **Use village analogies if they help.** Same as `mindset.md` says — English only, simple, real.
5. **Don't read the scoring rubric below until you've answered all 10.**

---

## ❓ The 10 Questions

### 🟢 Easy (foundation)

#### Q1. What does Terraform actually DO when you run `terraform apply`? Walk through it as if explaining to a new joinee.
*Your answer: terraform apply --auto-approve then it will check the existing statefile if these resources already exist or not , not check console , then if the resource already exsit it will not do recreate it , if it has any changes or for the first time then it will create or recreate the infra, update in the state file and update in the console and it will lock while applying so any other guy should not use it 

#### Q2. What is the difference between `terraform plan` and `terraform apply`? Why does `plan` exist at all — why not just `apply`?
*Your answer: the plan is jus a blue print and shows any format, syntax issues and if all the things good shows what resources are going to create or recreate or destroy , apply means real changes it wil change in the statefile and in console 

#### Q3. What is a **provider** in Terraform? Give one example and explain what it does.
*Your answer: provider is a gateway api like in what cloud you want to provision the infra using terraform there we have proide the cloud detailes so it , terraform will che which cloud, version permisions then it will enter onto the cloud 
### 🟡 Medium (mental model)

#### Q4. Terraform has a file called `terraform.tfstate`. What is it? What happens if you accidentally delete it after a successful `apply`?
*Your answer: state file is a single source of truth, terraform only validate stefile not console , it dones care console , if you delete the statefile then reapply the same resources it will again create becasue it feels there is nothing inside the state file related to the resources we deleted

#### Q5. Two engineers run `terraform apply` on the same code at the same time. What happens? How does Terraform prevent disaster?
*Your answer: this is most imp and great feature in terraform  the person who apply the fisrt it will lock for him , it will change 2nd person apply untill it finishes 1st person apply. after finish it will release for the 2nd person

#### Q6. In GCP, what is a **VPC**? What is a **subnet**? What is a **firewall rule**? Can a subnet exist without a VPC?
*Your answer: VPC is just like a pysical place where where we build the building right , so the vpc is foundation without vpc we can;t create the subnets , subnets are like a floors inthe building which separets the specific purposees , like if you have created subnets for gke you can seperate for service few , for pods few , for node few like this we will segerigate , subnets is notthing but IP addresses, firwall rule is like connection , communication rules whom to conect, where to connect , whom not to connect , it manages the communication , connection

#### Q7. In Terraform, what is a **module**? When should you write one? When should you NOT?
*Your answer: module is like a reuseable template , if you wanna replicate same things multiple times then create the module and use it with min configuration , like if you wanna build for dev, uat and prod then create and use module , if your requirement is only for one time no need of module building 
### 🔴 Hard (the real engineer questions)

#### Q8. What is **state drift**? Give a concrete example of how it happens. Whose fault is it — Terraform's or the human's?
*Your answer: it is humamn fault , mismatch of statefile and actual resorce in the console , if you modify anything in console or statefile manually then there will be a drift , we have to fix it by terraform apply

#### Q9. What is **Workload Identity Federation** in GCP? Why is it better than a JSON service-account key sitting in GitHub Secrets?
*Your answer: i know it is more secure  then regular classic SA , it won;t ask  json file to uplaod , like in github action want to connect with gcp , gcp asks github actions proove me you are authorized and aithenticated so it shows json file which created by SA .
but in otherhands worload identity we are providing , not much idea about it 
#### Q10. You change ONE line in a `.tf` file (say, change `machine_type = "e2-small"` to `"e2-medium"`). You run `terraform apply`. What does Terraform do internally — step by step — before changing anything on GCP?
*Your answer: first it will check existing infra in the statefile , if it is shows e2-medium then it won;t change if it has small then change to medium, and update in the statefile and then update in the console 

```
(write here)
```

---

# 🛑 STOP — Do NOT scroll below until all 10 are answered.

When all 10 have a written answer (even "I don't know"), come back to this file. We'll fill in the scoring section together.

---

## 📊 Scoring rubric (we fill this in TOGETHER, after you answer)

For each question, the score lives on this scale:

| Score | Means |
|-------|-------|
| 0-2 | Don't know / wildly wrong |
| 3-4 | Right direction, mechanism wrong |
| 5-6 | Surface correct, can't go deeper |
| 7-8 | Solid working knowledge, small gaps |
| 9-10 | Mentor-quality — clear, deep, with analogy |

| Q | Topic | Score | Notes (filled in after) |
|---|-------|-------|------------------------|
| Q1 | What `apply` does | _ / 10 | |
| Q2 | `plan` vs `apply` | _ / 10 | |
| Q3 | Providers | _ / 10 | |
| Q4 | State file | _ / 10 | |
| Q5 | Locking / concurrency | _ / 10 | |
| Q6 | VPC / Subnet / Firewall | _ / 10 | |
| Q7 | Modules | _ / 10 | |
| Q8 | State drift | _ / 10 | |
| Q9 | Workload Identity Federation | _ / 10 | |
| Q10 | The internal `apply` sequence | _ / 10 | |
| **Total** | | **_ / 100** = **_ / 10** | |

---

## 🧠 What the score means (gut-honest categories)

| Range | What it means | Where to start |
|-------|---------------|----------------|
| 0 - 3 / 10 | "Heard the words, never wrote a `.tf` file in anger" | Start at T-A1, slow and steady |
| 3 - 5 / 10 | "Solid Junior — knows enough to be dangerous, not enough to be deep" | T-A1, but you'll move fast through T-B |
| 5 - 7 / 10 | "Confident Intermediate — has shipped, hasn't been burned" | T-D and T-G are your real gaps |
| 7 - 8 / 10 | "Ready to mentor on basics, learning advanced patterns" | Skip to T-H/T-I |
| 8 - 10 / 10 | "Could teach this course" | Why are you here? |

---

## 🗺️ Gap map (we build this together AFTER scoring)

Once we have scores, we list the 3-5 biggest gaps in priority order:

| # | Gap | Severity | Phase that fixes it |
|---|-----|----------|---------------------|
| 1 | _ | _ | _ |
| 2 | _ | _ | _ |
| 3 | _ | _ | _ |

The gap map is what you re-read at the start of every learning session. It is your battle plan.

---

## ✅ When you're done with this file

- All 10 answered (even "I don't know")
- We've scored together and filled the table
- The gap map exists at the bottom

Then you unlock `phase-T-A-01-the-big-lie.md` and the journey begins.

---

> *"The shortcut: every senior engineer you respect already does this in their head in 5 seconds. They didn't learn it from a doc — they learned it from getting burned 50 times. You're using these questions to steal the lesson without taking the burn."*
> — `mindset.md`
