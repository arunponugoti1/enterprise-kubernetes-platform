# Transaction-Service — Telangana Village Layman's Guide

---

## The Village Setup — Who is Who

Before understanding this service, remember who exists in our village bank system:

| System Piece | Village Analogy |
|---|---|
| `account-service` | The **Accountant** sitting inside the bank. He owns the register (database). Only he can touch the khata. |
| `transaction-service` | The **Hawala Agent** (middleman). He does NOT keep money. He just says "Venkatesh nundi teesuko, Laxmi ki ivvu" (take from Venkatesh, give to Laxmi). |
| `notification-service` | The **Announcer / Peon** who sends SMS alerts after every transaction. |
| `api-gateway` | The **Security Guard** at the main gate. Nobody enters without his permission. He calls the Hawala Agent when a transfer is needed. |
| `postgres` | The **Almiraah** (iron safe). Only the Accountant has the key. |

---

## Why Does This Service Exist? What Happens Without It?

**The problem:** The Accountant (`account-service`) is very good at his job — adding/removing money from individual accounts. But he only knows ONE operation at a time:
- "Add ₹1000 to Laxmi's account" ✅
- "Remove ₹1000 from Venkatesh's account" ✅

He does NOT know how to coordinate BOTH steps together safely. If you ask him to "transfer ₹1000 from Venkatesh to Laxmi," he doesn't know what to do if step 2 fails after step 1 succeeds.

**Without `transaction-service`:**
- The frontend would have to call `account-service` twice directly
- If the second call fails (network error, account not found), Venkatesh's money is GONE — deducted but never credited to Laxmi
- This is called **money disappearing into thin air** — the worst bug in any fintech system
- There is no one to send the SMS either

**With `transaction-service`:**
- One call to the Hawala Agent: "Transfer ₹1000 from Account 1 to Account 2"
- He handles the two steps in the right order
- If anything fails midway, he AUTO-REVERSES the transaction (compensating transaction)
- He also notifies the Announcer (notification-service) after every outcome

---

## Why Are There TWO Files? (`index.js` and `publisher.js`)

Think of it this way:

| File | Role | Village Job |
|---|---|---|
| `index.js` | **Orchestrator** — runs the HTTP server, receives transfer requests, calls the Accountant, decides what to do | The **Hawala Agent's brain** — who decides the steps |
| `publisher.js` | **Messenger** — knows HOW to send event notifications, whether locally or to GCP cloud | The **Agent's peon** who goes and shouts the announcement after the work is done |

**Why separate them?** Because the notification method changes depending on the environment:
- **Local docker-compose** → peon walks directly to Notification-Service's door (HTTP call)
- **GCP Production** → peon uses the city's public broadcast system (Google Cloud Pub/Sub)

The Agent (index.js) should NOT need to know these details. He just says "publish this event" and the peon (publisher.js) figures out the route. This is called **Separation of Concerns** — aadodu pani aadodu chestadu, illu teesedi illu teestadu.

---

## Which File Acts FIRST? Then NEXT? Why?

### Startup Sequence

```
node src/index.js          ← Node starts HERE (package.json "main")
    │
    ├── line 2: const { publish } = require('./publisher')
    │           ← publisher.js is LOADED into memory right now
    │           ← But it doesn't DO anything yet. Just sitting ready.
    │
    ├── Express server is set up (routes registered)
    │
    └── app.listen(8080)   ← Server starts accepting requests
```

**So: `index.js` starts first. `publisher.js` is loaded silently in the background, waiting to be called.**

Think of it like the Hawala Agent arriving at his shop (index.js starts), and he tells his peon "be ready, stand near the door" (publisher.js loads). The peon doesn't move until the Agent calls him.

### Request Flow — When a Transfer Comes In

```
Customer (API Gateway) → POST /transactions/transfer
        │
        ▼
    index.js (Hawala Agent brain)
        │
        ├── Step 1: Validate inputs
        │     "Are the account IDs valid? Is amount > 0? Same account?"
        │
        ├── Step 2: callAccount() → Debit sender
        │     HTTP POST to account-service: /accounts/{from}/debit
        │     (Agent calls the Accountant: "Venkatesh nundi teesuko")
        │
        ├── If debit FAILS → publish(transaction.failed) → publisher.js sends alert
        │     Return error to customer. STOP.
        │
        ├── Step 3: callAccount() → Credit receiver
        │     HTTP POST to account-service: /accounts/{to}/credit
        │     (Agent calls the Accountant: "Laxmi ki ivvu")
        │
        ├── If credit FAILS → AUTO-REFUND!
        │     callAccount() → Credit back the SENDER (compensating transaction)
        │     publish(transaction.failed) → publisher.js sends failure alert
        │     Return error. STOP.
        │
        └── If ALL SUCCESS → publish(transaction.completed) → publisher.js sends success SMS
              Return 201 completed to customer.
```

---

## Deep Dive: The SAGA Pattern (The Most Important Concept)

This service uses what engineers call a **"Saga"** or **"Compensating Transaction"**.

### Village Story — The Hawala Agent's Rule

Imagine Venkatesh wants to send ₹5000 to his cousin Ramu in Hyderabad via the Hawala Agent.

**Step 1:** Agent takes ₹5000 from Venkatesh's hand. ✅
**Step 2:** Agent tries to give ₹5000 to Ramu. ❌ But Ramu's account is CLOSED.

**What does the Hawala Agent do?**
He does NOT keep the ₹5000. He IMMEDIATELY returns it to Venkatesh and says "Ramu ki account ledu, meeru teesukondi" (Ramu has no account, take it back).

**This is exactly what the code does:**

```javascript
// Step 1: Debit sender
const debit = await callAccount(`/accounts/${from_account_id}/debit`, { amount_cents });

// Step 2: Credit receiver
const credit = await callAccount(`/accounts/${to_account_id}/credit`, { amount_cents });

if (!credit.ok) {
  // COMPENSATING TRANSACTION — Auto-refund
  await callAccount(`/accounts/${from_account_id}/credit`, { amount_cents });
  // ↑ This is the Agent returning money to Venkatesh
}
```

**Why debit FIRST, not credit first?**

Because the Hawala Agent needs to confirm the money EXISTS before promising to deliver it. You take the money first, THEN deliver. If you promise delivery first and then find out the sender has no money — you're in trouble (you'd need to recover money from the receiver, which is much harder).

---

## Deep Dive: `callAccount()` — The Internal Phone

```javascript
async function callAccount(path, body) {
  const res = await fetch(`${ACCOUNT_URL}${path}`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify(body),
  });
  const data = await res.json().catch(() => ({}));
  return { ok: res.ok, status: res.status, data };
}
```

This is the Hawala Agent picking up his internal phone and calling the Accountant at the counter.

- `ACCOUNT_URL` = `http://account-service:8080` — this is the Accountant's phone number inside Docker's internal network
- The agent does NOT go to the database directly — he calls the Accountant (account-service), who is the ONLY one allowed to touch the almiraah
- `.catch(() => ({}))` — if the Accountant picks up but speaks gibberish (broken JSON), default to empty object instead of crashing

**This is the Service-to-Service (S2S) communication pattern.**

---

## Deep Dive: `publisher.js` — The Smart Announcer

```javascript
const PUBSUB_TOPIC_ID   = process.env.PUBSUB_TOPIC_ID   || '';
const NOTIFICATION_URL  = process.env.NOTIFICATION_URL  || 'http://notification-service:8080/events';
```

The peon knows TWO ways to announce:

### Mode 1 — Local / docker-compose (No PUBSUB_TOPIC_ID set)
```
publish(event)
    → getTopic() → returns null (no topic ID configured)
    → falls to else branch
    → HTTP POST directly to notification-service:8080/events
```
Peon walks directly to the Announcer's window and hands him a chit. Direct delivery.

### Mode 2 — GCP Production (PUBSUB_TOPIC_ID is set)
```
publish(event)
    → getTopic() → connects to Google Cloud Pub/Sub topic
    → publishes message to the topic
    → GCP delivers it to all subscribers (notification-service is one subscriber)
```
Peon goes to the city's broadcasting tower (Google Cloud Pub/Sub) and announces on the public channel. Anyone who is "subscribed" to hear announcements will receive it — not just notification-service, potentially multiple listeners.

### Why This Design? (Local fallback pattern)
In a real company:
- **Development/Testing** → no GCP account, no costs, just docker-compose talking to each other
- **Production on GKE** → Google Pub/Sub for reliability, scalability, retry logic

The code handles BOTH without changing a single line — just by setting/not setting an environment variable. This is called **environment-driven configuration**.

### The `_topic` Caching Trick

```javascript
let _topic;
async function getTopic() {
  if (_topic) return _topic;   // ← Already connected? Return immediately.
  ...
  _topic = new PubSub().topic(PUBSUB_TOPIC_ID);
  return _topic;
}
```

The peon does NOT walk to the broadcasting tower for every single transaction. He goes ONCE, gets the connection, and remembers it (`_topic`). For the next transaction, he already has the path memorized. This is called **lazy initialization + caching** — first time is slow, every time after is instant.

### The `try/catch` Safety Net

```javascript
try {
  ...publish...
} catch (err) {
  console.error(`publish error: ${err.message}`);
}
```

**Critical design decision:** If the Announcer is asleep (notification-service is down), the transaction is NOT rolled back. The peon just logs "could not announce" and moves on. The money transfer already happened successfully — it should not be reversed just because the SMS failed.

This is called **fire-and-forget** — the transfer is the main job, the notification is best-effort.

---

## Service Dependencies — Who Calls Whom

```
api-gateway
    │
    └──► transaction-service (POST /transactions/transfer or /deposit)
                │
                ├──► account-service (debit sender)      ← REQUIRED (must succeed)
                ├──► account-service (credit receiver)   ← REQUIRED (or auto-refund)
                ├──► account-service (refund if needed)  ← COMPENSATING call
                │
                └──► publisher.js
                          │
                          ├── [LOCAL]  notification-service (HTTP POST)  ← best-effort
                          └── [GCP]    Google Cloud Pub/Sub              ← best-effort
```

### Who DEPENDS on transaction-service?
- `api-gateway` — it routes all transfer/deposit calls here
- `frontend` — indirectly, through api-gateway

### Who does transaction-service DEPEND on?
- `account-service` — **hard dependency**. Cannot function without it. If account-service is down, every transfer fails.
- `notification-service` — **soft dependency**. If it's down, transactions still succeed. Only SMS is lost.

### Does account-service know about transaction-service?
**NO.** This is very important. The Accountant does NOT know that a Hawala Agent exists. He just receives phone calls saying "debit this account" or "credit that account" — he doesn't know who is calling or why.

This is called **loose coupling** — prati okkariki tanam pani taanu chestaru, evaro call chesaru ani telusu kaadu (each one does its own job, doesn't know who called them).

---

## What This Service Does NOT Have (And Why)

| Missing Thing | Why It's Missing |
|---|---|
| **No `db.js`** | It has no database. It is stateless. All data lives in account-service's PostgreSQL. |
| **No `SELECT FOR UPDATE`** | It doesn't touch the database. The locking happens INSIDE account-service during the debit call. |
| **No schema/migrations** | Nothing to create. No tables. No persistent state. |
| **No `readyz` database check** | `/readyz` just returns `{ status: "ready" }` immediately — there is no DB to check. |

**Being stateless is a STRENGTH:**
- Can run 10 copies of this service simultaneously (horizontal scaling) — no conflicts
- If one copy crashes, another picks up the next request instantly
- Easy to deploy, easy to scale, easy to replace

---

## Endpoints Summary

| Endpoint | Method | What It Does | Village Analogy |
|---|---|---|---|
| `/healthz` | GET | Is service alive? | Is the Hawala Agent's shop open? |
| `/readyz` | GET | Is service ready? | Is the Agent sitting at his desk? |
| `/transactions/transfer` | POST | Move money between two accounts | "Venkatesh nundi Laxmi ki pampinchu" |
| `/transactions/deposit` | POST | Add money to one account (no sender) | "Rythu Bandhu amount credit cheyyi" |

---

## The Three Questions (Platform Engineering Framework)

### 1. Contract — What does this service promise?
- Input: `{ from_account_id, to_account_id, amount_cents }` all required, amount must be positive
- Output: `{ status: "completed", from_account_id, to_account_id, amount_cents, at }` on success
- Guarantee: If transfer returns 201, money has moved. If it returns an error, money is back where it started.

### 2. Failure Mode — What breaks and how?
| Failure | What Happens |
|---|---|
| account-service is DOWN | Transfer fails immediately. Money never moved. Safe. |
| Debit succeeds, credit fails | Auto-refund kicks in. Money returns to sender. Safe. |
| Refund also fails | Money is debited but NOT credited. **This is the one dangerous edge case.** In production, this would need a dead-letter queue and manual reconciliation. |
| notification-service is DOWN | Transaction succeeds. SMS is lost. Acceptable. |

### 3. Portability — Can it run anywhere?
- **docker-compose:** HTTP to notification-service directly. Works with zero GCP setup.
- **GKE + GCP:** Set `PUBSUB_TOPIC_ID` env var. Switches to Google Pub/Sub automatically.
- **Any cloud:** Replace `publisher.js` internals without touching `index.js` at all.

---

## Summary in One Sentence

The `transaction-service` is the **stateless Hawala Agent** who safely moves money between two accounts by calling the Accountant (account-service) twice — debit first, then credit — and if anything goes wrong midway, immediately reverses the debit (Saga pattern), and always shouts the outcome to the Announcer (notification-service) in a fire-and-forget manner.
