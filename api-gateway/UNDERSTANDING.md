# API-Gateway — Telangana Village Layman's Guide

---

## The Village Setup — What Is This Service?

So far our village bank has:
- **Accountant** (`account-service`) — owns the register and almiraah
- **Hawala Agent** (`transaction-service`) — coordinates transfers between accounts
- **Peon/Announcer** (`notification-service`) — logs and shouts every event

But right now, **anyone from outside can walk directly into any of these rooms.** A stranger can directly call the Accountant. A fraudster can directly call the Hawala Agent. No checking, no verification, no limits.

The **API Gateway** is the **Main Security Gate of the entire bank complex.**

Nobody enters without going through this gate. The gate has three jobs:

| Job | Who Does It | File |
|---|---|---|
| **Count how many times you came today** (rate limiting) | Traffic Constable at the gate | `rateLimit.js` |
| **Check your identity pass** (JWT auth) | ID Verification Guard | `auth.js` |
| **Direct you to the right counter** (proxy/routing) | Gate Supervisor | `index.js` |

---

## Real World Village Story — The Mandal Office

Imagine your village **Mandal Office** (government office) in Telangana.

To get any work done (land records, ration card, certificates) you have to go through these steps at the main gate:

**Step 1 — Traffic Police (rateLimit.js)**
A constable is standing outside. He has a register. Every time someone comes, he marks a tally. If one person comes more than 120 times in 60 minutes — "Arre, bahut baar aa rahe ho, wait karo bahar" (You're coming too many times, wait outside). This protects the office from being flooded.

**Step 2 — Show Your ID (auth.js)**
After the constable lets you through, the guard at the door checks your **Gate Pass** (JWT token). This pass was issued to you when you first registered at the Mandal Office. Without a valid pass — "Pass ledu, andar raaду" (No pass, you can't come in).

**Step 3 — Go to the Right Counter (index.js proxy)**
Once inside, the Supervisor looks at your request and says:
- "Account work? Counter 1 ki vello" (Go to counter 1 — account-service)
- "Transaction work? Counter 2 ki vello" (Go to counter 2 — transaction-service)

The gate doesn't do the actual work. It only checks, counts, and directs.

---

## Why Three Files? Which Loads First?

```
node src/index.js            ← Node starts HERE
    │
    ├── line 2: require('./auth')      → auth.js loaded into memory
    ├── line 3: require('./rateLimit') → rateLimit.js loaded into memory
    │
    ├── app.use(rateLimit)   ← Traffic constable posted at the gate FIRST
    ├── routes registered    ← Counters opened
    └── app.listen(8080)     ← Gate opens for business
```

**Load order:** `index.js` starts → `auth.js` loads → `rateLimit.js` loads → server starts.

**Why separate files?**

Because each job is completely independent:
- `rateLimit.js` has no idea what a JWT token is. It only counts requests per IP.
- `auth.js` has no idea what rate limiting is. It only verifies tokens.
- `index.js` doesn't handle auth logic or counting — it just wires them together and decides routing.

This is called **Single Responsibility Principle** — prati file okke pani chestundi (each file does only one job).

---

## The Request Journey — Every Request Goes Through Checkpoints

Think of the gate as a series of checkpoints. Every single request must pass ALL checkpoints in order.

```
Customer (browser/curl) sends request
            │
            ▼
┌─────────────────────────────────────────┐
│  CHECKPOINT 1: rateLimit (rateLimit.js) │
│  "Meeru ee nimisham lo enni sarlu       │
│   vaccharu?" (How many times this hour?)│
│                                         │
│  count <= 120 → ✅ next()              │
│  count > 120  → ❌ 429 Too Many        │
└─────────────────────────────────────────┘
            │ (only if passed)
            ▼
┌─────────────────────────────────────────┐
│  ROUTE MATCHING                         │
│                                         │
│  /api/auth/login  → PUBLIC (no auth)   │
│  /api/accounts/*  → go to checkpoint 2 │
│  /api/transactions/* → go to checkpoint2│
└─────────────────────────────────────────┘
            │ (only for protected routes)
            ▼
┌─────────────────────────────────────────┐
│  CHECKPOINT 2: requireAuth (auth.js)    │
│  "Meeru Gate Pass chuupinchandi"        │
│  (Show your Gate Pass)                  │
│                                         │
│  No token   → ❌ 401 missing bearer    │
│  Fake token → ❌ 401 invalid token     │
│  Valid token → ✅ next()              │
└─────────────────────────────────────────┘
            │ (only if passed)
            ▼
┌─────────────────────────────────────────┐
│  PROXY: Forward to correct service      │
│                                         │
│  /api/accounts/* → account-service     │
│  /api/transactions/* → txn-service     │
│                                         │
│  Service down → 502 Bad Gateway        │
└─────────────────────────────────────────┘
            │
            ▼
       Response back to customer
```

**The key insight:** Rate limit runs on EVERY request including login. Auth check runs only on PROTECTED routes. This order is intentional — explained in detail below.

---

## Deep Dive: `rateLimit.js` — The Traffic Constable

```javascript
const WINDOW_MS = 60_000;   // 60 seconds
const MAX_REQS  = 120;      // max 120 requests per 60 seconds per IP

const buckets = new Map();  // one bucket per IP address
```

### The Token Bucket — Village Analogy

Imagine the constable has a **tiffin box** (dabba) for each visitor. Every tiffin box starts with 120 idlies at the beginning of each hour.

- Every time you knock on the gate → constable takes 1 idly out of YOUR tiffin box
- You have 120 idlies → you can knock 120 times per hour
- Box empty → "Idlies khaali, wait karo" → 429 Too Many Requests
- After 60 minutes → fresh 120 idlies in your box → you can come again

```javascript
function rateLimit(req, res, next) {
  const key = req.ip;   // each visitor's IP = their own tiffin box
  const now = Date.now();
  const bucket = buckets.get(key) || { count: 0, resetAt: now + WINDOW_MS };

  if (now > bucket.resetAt) {     // 60 minutes passed? Refill the box
    bucket.count = 0;
    bucket.resetAt = now + WINDOW_MS;
  }

  bucket.count++;                  // take one idly
  buckets.set(key, bucket);

  if (bucket.count > MAX_REQS) {  // box empty?
    return res.status(429).json({ error: 'rate limit exceeded' });
  }
  next();                          // still has idlies → let them through
}
```

### Why Rate Limiting?

**Without it:** A fraudster can write a script that calls `/api/auth/login` 10,000 times per second trying different passwords (brute force attack). Or they can flood the system with fake requests making it slow for real users (DoS — Denial of Service).

**Village analogy:** If one person is allowed to knock on the gate unlimited times, they can block the entrance for everyone else. The constable prevents this.

### Where is the bucket stored?

`const buckets = new Map()` — stored IN MEMORY inside the container. Like the constable's handwritten register.

**Production note (already in the code comment):** "Replace with Redis-backed limiter." In production with 10 instances of api-gateway running, each instance has its own in-memory register — they don't share information. Someone could send 120 requests to instance-1 and another 120 to instance-2. Redis is a shared in-memory store all instances can use, like a single shared register at the gate.

---

## Deep Dive: `auth.js` — The Gate Pass System (JWT)

This is the most important concept in the entire gateway. Let's understand it step by step.

### What is a JWT? — The Sealed Envelope Analogy

JWT = JSON Web Token. Think of it as a **sealed government envelope** with your details written inside.

When you first visit the Mandal Office:
1. You show your email: "Naa email venkatesh@village.com"
2. The office stamps and seals an envelope with your details inside: `{ sub: "venkatesh@village.com", issued: today, expires: 1 hour from now }`
3. They hand you this sealed envelope: **"Ee envelope meeru Token. Ee roju manchi undi. Oka ganta tarvaata expire avutundi."**

Every time you come back within 1 hour:
- You show the sealed envelope
- Guard holds it up to the light (verifies the stamp)
- If the stamp is real and not expired → "andar jao"
- If someone tried to open and re-seal the envelope (tampered) → fake stamp → "bahar jao"

### `issueToken` — Creating the Gate Pass

```javascript
const JWT_SECRET = process.env.JWT_SECRET || 'dev-secret-change-me';

function issueToken(payload) {
  return jwt.sign(payload, JWT_SECRET, { expiresIn: JWT_TTL_SECONDS });
}
```

- `payload` = the data to put inside the envelope: `{ sub: "venkatesh@village.com" }`
- `JWT_SECRET` = the **stamp / seal ink** — the secret key only the Mandal Office has
- `jwt.sign()` = stamp + seal the envelope → produces a token string like:
  `eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ2ZW5rYXRlc2gifQ.HMAC_SIGNATURE`

**Three parts of a JWT (separated by dots):**
```
eyJhbGciOiJIUzI1NiJ9        ← Header: "I used HMAC-SHA256 to stamp this"
.eyJzdWIiOiJ2ZW5rYXRlc2gifQ ← Payload: { sub: "venkatesh@village.com" }
.HMAC_SIGNATURE              ← Signature: the actual tamper-proof stamp
```

The first two parts are just **base64-encoded** (like writing in a different script — anyone can read them by decoding). But the third part — the signature — can only be verified by someone who knows the `JWT_SECRET`. This is what makes it tamper-proof.

**Important:** JWT content is NOT secret (anyone can decode and read it). It is only TAMPER-PROOF (no one can change the content without breaking the signature). So never put passwords or sensitive data in a JWT.

### `requireAuth` — Checking the Gate Pass

```javascript
function requireAuth(req, res, next) {
  const header = req.headers.authorization || '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : null;

  if (!token) return res.status(401).json({ error: 'missing bearer token' });

  try {
    req.user = jwt.verify(token, JWT_SECRET);
    next();
  } catch (err) {
    res.status(401).json({ error: 'invalid token', detail: err.message });
  }
}
```

**Step by step:**

1. **`req.headers.authorization`** — The customer sends the token in a special HTTP header:
   ```
   Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ2Z...
   ```
   "Bearer" means "the person carrying this token." Like showing your pass at the gate.

2. **`header.slice(7)`** — Strips the word "Bearer " (7 characters) to get just the token.

3. **`jwt.verify(token, JWT_SECRET)`** — The guard holds up the envelope to the light:
   - Is the signature valid? (Was this really stamped by our office?)
   - Is it expired? (Token older than 1 hour?)
   - Both checks happen simultaneously
   - If valid: returns the payload `{ sub: "venkatesh@village.com" }` and stores it in `req.user`
   - If invalid: throws an error → caught → 401 returned

4. **`next()`** — "Pass ho jao" — move to the next checkpoint (the proxy)

### The Login Endpoint — Getting Your First Pass

```javascript
app.post('/api/auth/login', (req, res) => {
  const { email } = req.body || {};
  if (!email) return res.status(400).json({ error: 'email required' });
  const token = issueToken({ sub: email });
  res.json({ token, expires_in_seconds: 3600 });
});
```

**Notice: `/api/auth/login` has NO `requireAuth` middleware.** It's a public route — you can call it without a token. Makes sense: it's the counter where you GET your token in the first place. You can't need a token to get a token — that's a circular problem.

**Code comment says:** "Real impl would verify credentials against an IdP." Right now it accepts ANY email with no password check. That's fine for our learning — in production, it would check your username/password against an Identity Provider (like Google, Active Directory, or a users table).

---

## Deep Dive: `index.js` — The Gate Supervisor and Proxy

### The `proxy` Function — The Redirector

```javascript
async function proxy(target, req, res) {
  const url = `${target}${req.originalUrl.replace(/^\/api/, '')}`;
  ...
}
```

**The URL rewriting — most important line:**

```
Customer sends:  GET /api/accounts/1
                        ↓
proxy strips /api:  GET /accounts/1
                        ↓
Forwarded to:   account-service: GET /accounts/1
```

**Why the `/api` prefix?**

The outside world (browser, mobile app) talks to ONE address: `api-gateway:8080`. Everything is under `/api/...` so the gateway knows "this request needs routing."

The internal services (account-service, transaction-service) don't know they're behind a gateway. They just know their own routes (`/accounts`, `/transactions`). They don't understand `/api` — that's the gateway's concern.

**Village analogy:** The outside world knows: "Go to the Mandal Office main gate." Inside the Mandal Office, Counter 1 only knows "I handle land records." Counter 1 doesn't know it's called "Counter 1 of the Mandal Office Main Building" — it just knows its own job. The gate supervisor translates the public address to the internal address.

### What happens if a service is down?

```javascript
  } catch (err) {
    res.status(502).json({ error: 'upstream unreachable', detail: err.message });
  }
```

If account-service container crashes:
- The `fetch()` call throws an error (connection refused)
- Gateway catches it and returns **502 Bad Gateway**
- Customer sees: `{ "error": "upstream unreachable" }`

**502 vs 404:**
- **404** = "That route doesn't exist" — the gateway itself said no
- **502** = "I (the gateway) exist and the route is valid, but the service BEHIND me is unreachable"

**Village analogy:** You showed your pass and the gate let you through. You walked to Counter 1. The counter shutters are down. Gate Supervisor comes and says "Counter 1 bandh hai, baad mein aao" (Counter 1 is closed, come later). The gate is open, your pass is valid, but the counter itself is closed.

### The Routes

```javascript
app.use('/api/accounts',     requireAuth, (req, res) => proxy(ACCOUNT_URL, req, res));
app.use('/api/transactions',  requireAuth, (req, res) => proxy(TRANSACTION_URL, req, res));
```

**Reading this line:** "For ANY request starting with `/api/accounts`:
1. First run `requireAuth` (check the pass)
2. If pass is valid, run the proxy to `ACCOUNT_URL`"

This means:
- `GET /api/accounts/1` → auth check → proxy → `account-service GET /accounts/1`
- `POST /api/accounts` → auth check → proxy → `account-service POST /accounts`
- `POST /api/accounts/1/debit` → auth check → proxy → `account-service POST /accounts/1/debit`

**The gateway handles ALL methods (GET, POST, etc.) for any path under `/api/accounts`** — it's a wildcard match. One line of code covers all account operations.

---

## Why Rate Limit Comes BEFORE Auth — The Order Matters

```javascript
app.use(rateLimit);    // ← Line 7: runs on EVERY request
...
app.use('/api/accounts', requireAuth, proxy);  // ← Line 43: auth only for this route
```

**Why this order?**

Verifying a JWT takes CPU time — the server has to calculate the HMAC signature. If a bad actor sends 10,000 fake tokens per second, the server would waste time verifying each fake token before rejecting it.

Rate limiting is much cheaper — it's just a counter lookup in a Map (extremely fast). So we reject flood attacks FIRST (cheap operation), before doing token verification (more expensive operation).

**Village analogy:** The traffic constable is OUTSIDE the gate. The ID check guard is INSIDE the gate. If 500 people rush the gate at once, the constable turns away excess people BEFORE they even reach the ID check. The ID check guard's time is saved.

---

## Service Dependencies — Who Calls Whom

```
Browser / curl / frontend
        │
        ▼
   api-gateway (port 8080)       ← THE ONLY PUBLIC ENTRY POINT
        │
        ├── /api/auth/login      → handled internally (no downstream call)
        ├── /api/accounts/*      → account-service:8080
        └── /api/transactions/*  → transaction-service:8080
                                        │
                                        └── transaction-service → account-service
                                                               → notification-service
```

### What Does api-gateway NOT Know About?

- It does NOT know about `notification-service` — that's transaction-service's concern
- It does NOT know about `postgres` — that's account-service's concern
- It does NOT know how transfers work internally — that's transaction-service's job

The gateway only knows: "authenticated request for accounts? send to account-service. For transactions? send to transaction-service."

### Who Knows the Gateway Exists?

- `frontend` — yes, all API calls go to `http://api-gateway:8080`
- `account-service` — NO, it doesn't know a gateway exists. It just receives requests.
- `transaction-service` — NO, same — it just receives requests.

---

## What Would Happen Without the API Gateway?

**Scenario 1 — No Auth:**
Anyone on the internet could call `http://account-service:8080/accounts/1/debit` directly and drain any account. No login needed.

**Scenario 2 — No Rate Limiting:**
A fraudster's bot sends 50,000 requests per second to try different account IDs. Server melts. Real users can't do anything.

**Scenario 3 — Direct Service Exposure:**
The frontend would need to know the addresses of EVERY backend service (account-service URL, transaction-service URL). If a new service is added or an address changes, frontend code has to change. Gateway provides a single stable address — one door, many rooms behind it.

**Scenario 4 — No URL Abstraction:**
Internal service names (`account-service`, `transaction-service`) would leak to the public internet. Security risk — attackers now know your internal architecture.

**Village analogy without the gate:**
The Mandal Office has no main gate. Every department has its own street entrance. Anyone can walk into the Land Records room directly. Fraudsters can sit outside and knock 10,000 times. Staff addresses are written on every wall for anyone to see. Chaos.

---

## The Three Questions

### 1. Contract — What does api-gateway promise?

| Input | Output |
|---|---|
| `POST /api/auth/login` with `{ email }` | `{ token, expires_in_seconds }` |
| Any `GET/POST /api/accounts/*` with valid token | Whatever account-service returns |
| Any `POST /api/transactions/*` with valid token | Whatever transaction-service returns |
| Request without token to protected route | `401 missing bearer token` |
| More than 120 requests/minute from same IP | `429 rate limit exceeded` |
| Valid route but service is down | `502 upstream unreachable` |

### 2. Failure Modes

| Failure | Result |
|---|---|
| `JWT_SECRET` changed in env | All existing tokens instantly invalid — all users logged out |
| account-service crashes | 502 on all account routes, login still works |
| Both backend services down | 502 on all routes except `/healthz`, `/readyz`, `/api/auth/login` |
| Rate limit map fills up (memory) | In-memory Map grows with IPs. Not a real problem at this scale. |

### 3. Portability

- **docker-compose local:** `JWT_SECRET=dev-secret-change-me` — fine for learning
- **GKE Production:** `JWT_SECRET` comes from a Kubernetes Secret (encrypted, not in code)
- **Rate limit production:** Replace in-memory Map with Redis (shared across multiple gateway pods)
- **Auth production:** Replace the demo login with a real IdP (Google OAuth, Keycloak, etc.)

---

## Why Three Files — One-Line Summary Each

| File | One-Line Job | Can It Work Alone? |
|---|---|---|
| `rateLimit.js` | Count requests per IP, reject excess | Yes — completely standalone |
| `auth.js` | Issue and verify JWT tokens | Yes — knows nothing about routing or limits |
| `index.js` | Wire everything together, proxy to services | No — needs the other two |

---

## Endpoints Summary

| Endpoint | Method | Auth Required? | Rate Limited? | What It Does |
|---|---|---|---|---|
| `/healthz` | GET | No | Yes | Is gateway alive? |
| `/readyz` | GET | No | Yes | Is gateway ready? |
| `/api/auth/login` | POST | No | Yes | Get a JWT token (show email) |
| `/api/accounts/*` | Any | **Yes** | Yes | Proxy to account-service |
| `/api/transactions/*` | Any | **Yes** | Yes | Proxy to transaction-service |

---

## Summary in One Sentence

The `api-gateway` is the **Mandal Office main gate** — every request from the outside world must enter here, it first counts the visitor (rate limit), then checks their gate pass (JWT), then silently redirects them to the right internal counter (proxy), and none of the internal services ever need to know the gate even exists.
