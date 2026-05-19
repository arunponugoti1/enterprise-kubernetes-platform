# Architecture Foundations — The Biggest Doubts Answered
## Telangana Village Deep Explanation

---
admin
admin1

## READ THIS FIRST — Your Current Understanding Is Mostly Correct

You said:
> "index.html is just a template wrapper where we give user inputs, it does not have any database"
> "app.js is pulling all the info and responding to the inputs of users"

**That is 100% correct.** Now let's fix the gaps.

---

# QUESTION 1 — What Is an API? Why Does It Exist?

This is the most foundational question. Everything else builds on this.

## The Problem Without an API

Imagine you are the bank manager. Venkatesh walks up to your desk and says:
**"I want to see my account balance."**

You have two choices:

**Option A (No API — Bad):** You hand Venkatesh the almiraah key and say "Go check the register yourself."
- Venkatesh now has the almiraah key → security disaster
- He could change any number in any account
- He needs to know exactly how the register is organized
- 100 customers = 100 people with the almiraah key

**Option B (With API — Good):** You say "Fill in this slip: Account ID, your signature. I will check for you and read only your balance."
- Venkatesh never sees the almiraah
- Venkatesh can only ask for what is on the slip
- You control exactly what he can ask and what you give back

**An API is Option B.** It is a defined list of questions you are allowed to ask and the answers you will get back.

## What Does "API" Actually Mean?

API = Application Programming Interface

**Interface** means "the official way two things talk to each other."

Think of a **light switch**. You don't know how electricity works. You don't know what's inside the wall. You just know: flip up = light on, flip down = light off. That is the **interface** — the agreed-upon contract between you and the electrical system.

Our APIs work the same way:
```
You ask:   POST /accounts  with { owner_name, email }
You get:   { id, owner_name, email, balance_cents, created_at }

You ask:   POST /accounts/1/debit  with { amount_cents }
You get:   { id, balance_cents }   OR  { error: "insufficient funds" }
```

Nobody cares how the database works inside. They just know: if I send THIS, I get THAT.

## Without an API — What Would Happen?

If there was NO api-gateway, NO account-service REST API — just a raw database:

```
Browser → directly query PostgreSQL?
```

**This is IMPOSSIBLE.** Here's why:
1. A browser cannot speak PostgreSQL language (SQL). Browsers speak HTTP only.
2. Exposing a database directly to the internet is a catastrophic security hole.
3. If you change the database table structure, every frontend breaks.
4. There is no place to put business logic (like "balance cannot go below zero").

The REST API (HTTP endpoints) is the **translator and gatekeeper** between the outside world and the database.

```
BROWSER speaks HTTP                DATABASE speaks SQL
─────────────────                  ──────────────────
POST /accounts/1/debit   ──────►   UPDATE accounts
{ amount_cents: 5000 }             SET balance = balance - 5000
                                   WHERE id = 1
                                   AND balance >= 5000
```

The account-service does that translation. The API is the contract that makes this possible.

---

# QUESTION 2 — What Is nginx? Where Does It Sit? What Does It Do?

## The Biggest Misunderstanding — nginx Does NOT Control Microservices

nginx has NO connection to account-service, transaction-service, or notification-service.

**nginx has exactly TWO jobs:**
1. Give files (HTML, CSS, JS) to the browser
2. Forward `/api/` requests to api-gateway

That is ALL. nginx does not know that transaction-service or account-service even exist.

## Where nginx Sits — The Physical Location

```
YOUR LAPTOP (outside Docker)
────────────────────────────────────────────────────────────────

  Your browser
       │
       │ You type: http://localhost:3000
       │
       ▼ Port 3000 on YOUR LAPTOP
─── DOCKER HOST PORT MAPPING ──── (the door between outside and inside)
       │ docker-compose: "3000:8080" means localhost:3000 → nginx container port 8080
       ▼

DOCKER'S PRIVATE NETWORK (containers talk here — your laptop cannot reach this directly)
────────────────────────────────────────────────────────────────
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│   ┌─────────────────┐                                       │
│   │ frontend         │  ← This is the nginx container      │
│   │ (nginx :8080)    │    It contains: nginx + html + js    │
│   │                  │                                       │
│   │ Job 1: browser   │                                       │
│   │ asks /app.js  →  │ reads from /usr/share/nginx/html/    │
│   │ sends the file   │ sends app.js back to browser         │
│   │                  │                                       │
│   │ Job 2: browser   │                                       │
│   │ calls /api/*  →  │ proxies to api-gateway:8080          │
│   └────────┬─────────┘                                       │
│            │ /api/* only                                     │
│            ▼                                                 │
│   ┌─────────────────┐                                       │
│   │  api-gateway     │  ← checks JWT, rate limit            │
│   │  (:8080)         │  ← routes /api/accounts or           │
│   │                  │    /api/transactions                  │
│   └────────┬─────────┘                                       │
│            │                                                 │
│     ┌──────┴──────┐                                         │
│     ▼             ▼                                         │
│   ┌────────┐ ┌────────────┐ ┌──────────────┐               │
│   │account │ │transaction │ │notification  │               │
│   │service │ │service     │ │service       │               │
│   │(:8080) │ │(:8080)     │ │(:8080)       │               │
│   └────┬───┘ └──────┬─────┘ └──────────────┘               │
│        │            │                                        │
│        └─────┬───── ┘                                       │
│              ▼                                               │
│         ┌──────────┐                                        │
│         │ postgres  │                                       │
│         │(:5432)    │                                       │
│         └──────────┘                                        │
└─────────────────────────────────────────────────────────────┘
```

## The Door Concept — Port Mapping

Your laptop cannot reach Docker's private network directly. The only way in is through the **doors** (port mappings) defined in docker-compose.yml:

```yaml
frontend:
  ports:
    - "3000:8080"      # laptop:3000 → nginx container:8080
api-gateway:
  ports:
    - "8080:8080"      # laptop:8080 → api-gateway container:8080
account-service:
  ports:
    - "8081:8080"      # laptop:8081 → account-service container:8080
```

Format is always: `"HOST_PORT:CONTAINER_PORT"`

**Left side** = port on YOUR LAPTOP (the door from outside)
**Right side** = port INSIDE the container (the room number)

```
Your laptop:3000  ────► (door) ────► nginx container:8080
Your laptop:8080  ────► (door) ────► api-gateway container:8080
Your laptop:8081  ────► (door) ────► account-service container:8080
```

**Why do all containers use port 8080 internally?**

Because inside their own container, each service is alone. `account-service` is in its own isolated box — it doesn't know that `transaction-service` also uses 8080 in ITS box. Each container is its own separate world. The HOST PORT (left side) must be unique on your laptop — that's why we use 8080, 8081, 8082, 8083, 3000.

## Why Do We Need nginx At All? Can We Skip It?

If you removed nginx:
- app.js, index.html, styles.css would have no server to live on — the browser cannot load them
- There would be no reverse proxy to forward `/api/` calls

Alternatives to nginx for serving static files:
- Apache (older, heavier)
- Node.js `express.static()` (wasteful — running a full JS engine just to serve files)
- Python `http.server` (dev only, not production)
- AWS S3 + CloudFront (in cloud, skip nginx entirely)

nginx is the industry standard for this job because it is extremely fast, uses almost no memory, and handles thousands of concurrent connections.

---

# QUESTION 3 — The Frontend Dockerfile: Where Are app.js and index.html?

This is a very sharp question. Let's read the Dockerfile carefully:

```dockerfile
FROM nginx:1.27-alpine                              # Line 1
COPY nginx.conf /etc/nginx/conf.d/default.conf      # Line 2
COPY public /usr/share/nginx/html                   # Line 3
EXPOSE 8080                                         # Line 4
```

**Line 3 is the answer to your question:**

```
COPY public /usr/share/nginx/html
```

This copies the ENTIRE `public/` folder from your laptop INTO the nginx image, placing files at `/usr/share/nginx/html/` inside the container.

After `docker build`, the nginx container's file system looks like this:
```
Inside the nginx container:
/usr/share/nginx/html/
    ├── index.html    ← COPIED from frontend/public/index.html
    ├── app.js        ← COPIED from frontend/public/app.js
    └── styles.css    ← COPIED from frontend/public/styles.css

/etc/nginx/conf.d/
    └── default.conf  ← COPIED from frontend/nginx.conf
```

**There is NO separate "frontend container" and "nginx container."**

They are ONE container. The nginx container IS the frontend container. The nginx image is used as the base, and then we put our HTML/JS/CSS files inside it. nginx knows to look in `/usr/share/nginx/html/` for files to serve — that is its default configured folder.

**Village analogy:** Think of nginx as a pre-built bookshelf (the Docker image). We put our books (app.js, index.html) onto the shelves (COPY command). Now when someone asks "give me the book called app.js," the shelf serves it. The shelf and the books are one unit.

**So when the browser requests `http://localhost:3000/app.js`:**
1. Request reaches nginx container (via port mapping 3000 → 8080)
2. nginx reads `/usr/share/nginx/html/app.js` from its own file system
3. nginx sends the file contents back to the browser
4. Browser receives app.js and runs it

---

# QUESTION 4 — How Do Microservices Find Each Other? The Docker DNS Secret

This is the MOST important thing you must understand for Kubernetes too.

## The Question: Where in the Code Does transaction-service Call account-service?

Open `transaction-service/src/index.js`, line 7:

```javascript
const ACCOUNT_URL = process.env.ACCOUNT_SERVICE_URL || 'http://account-service:8080';
```

And line 13:
```javascript
const res = await fetch(`${ACCOUNT_URL}${path}`, { ... });
```

So when transaction-service wants to debit Venkatesh, it calls:
```
fetch('http://account-service:8080/accounts/1/debit', ...)
```

**The question is: what is `account-service`? Is it a hostname? An IP address?**

## Docker's Internal DNS — How Containers Find Each Other

Inside Docker's private network, **every container gets a hostname equal to its service name in docker-compose.yml**.

In docker-compose.yml:
```yaml
services:
  account-service:     # ← this name becomes a hostname inside Docker network
    ...
  transaction-service:
    ...
```

Inside Docker's private network:
- `account-service` resolves to the IP of the account-service container
- `transaction-service` resolves to the IP of the transaction-service container
- `postgres` resolves to the IP of the postgres container

**This is Docker's built-in DNS.** Just like how `google.com` resolves to `142.250.x.x`, Docker resolves `account-service` to the container's private IP automatically.

**Nobody writes an IP address anywhere.** You just use the service name.

## Where Is the Address Configured?

Look at docker-compose.yml:

```yaml
transaction-service:
  environment:
    ACCOUNT_SERVICE_URL: http://account-service:8080      # ← HERE
    NOTIFICATION_URL: http://notification-service:8080/events  # ← and HERE
```

```yaml
api-gateway:
  environment:
    ACCOUNT_SERVICE_URL: http://account-service:8080       # ← HERE
    TRANSACTION_SERVICE_URL: http://transaction-service:8080  # ← HERE
```

These environment variables are **injected into the container at startup**. The code reads them with `process.env.ACCOUNT_SERVICE_URL`. If not set, the code falls back to the default (`|| 'http://account-service:8080'`).

## The Full Chain — Who Knows Whose Address

```
frontend/nginx.conf:
  proxy_pass http://api-gateway:8080;     ← nginx knows api-gateway's address

api-gateway (from env var):
  ACCOUNT_SERVICE_URL=http://account-service:8080      ← knows account-service
  TRANSACTION_SERVICE_URL=http://transaction-service:8080  ← knows transaction-service

transaction-service (from env var):
  ACCOUNT_SERVICE_URL=http://account-service:8080      ← knows account-service
  NOTIFICATION_URL=http://notification-service:8080/events ← knows notification-service

account-service (from env var):
  DB_HOST=postgres    ← knows postgres
  DB_PORT=5432
```

**The pattern:** Each service only knows about the services it DIRECTLY needs. Nobody knows about everyone. This is loose coupling.

## In Kubernetes — Same Concept, Different Name

In Kubernetes, the same thing happens through **Services** (Kubernetes Services, not microservices). Each microservice gets a Kubernetes Service object that gives it a stable DNS name inside the cluster. `account-service` in Kubernetes resolves via Kubernetes DNS just like it does in Docker via Docker DNS. **This is why understanding Docker DNS now makes Kubernetes service discovery obvious later.**

---

# QUESTION 5 — What Does nginx.conf Actually Do? Line by Line

```nginx
server {
  listen 8080;
  server_name _;
```

nginx wakes up and says: "I will listen for requests on port 8080. Accept requests for any hostname (`_` means wildcard)."

---

```nginx
  root /usr/share/nginx/html;
  index index.html;
```

"When someone asks for a file, look in `/usr/share/nginx/html/` to find it. If they ask for a folder (like `/`), serve `index.html` from that folder."

This is where app.js and index.html live inside the container (put there by the Dockerfile `COPY` command).

---

```nginx
  location / {
    try_files $uri $uri/ /index.html;
  }
```

**This rule handles all file requests (HTML, CSS, JS).**

`$uri` = whatever the browser asked for.

"Try in this order:
1. Is there an exact file called `$uri`? → serve it (`/app.js` → finds app.js → serves it)
2. Is there a directory called `$uri`? → serve its index (`/` → finds index.html → serves it)
3. Nothing found? → serve `/index.html` anyway (fallback)"

**Why the fallback to `/index.html`?**
If someone bookmarks `http://localhost:3000/transfers`, there is no file called `transfers` on disk. Without the fallback, nginx would return 404. With the fallback, it serves `index.html` and `app.js` takes over and handles the route in the browser.

---

```nginx
  location /api/ {
    proxy_pass http://api-gateway:8080;
    proxy_http_version 1.1;
    proxy_set_header Host             $host;
    proxy_set_header X-Real-IP        $remote_addr;
    proxy_set_header X-Forwarded-For  $proxy_add_x_forwarded_for;
  }
```

**This rule handles ALL API calls.**

"If the URL starts with `/api/`, do NOT look for a file. Instead, forward (proxy) the request to `http://api-gateway:8080`."

The extra `proxy_set_header` lines pass information to api-gateway:
- `X-Real-IP` → the actual customer's IP address (so rate limiting works per-customer)
- `X-Forwarded-For` → the chain of proxies the request went through
- Without `X-Real-IP`, api-gateway would think ALL requests come from nginx's IP

**nginx uses Docker DNS here too:** `http://api-gateway:8080` — `api-gateway` resolves to the api-gateway container's internal IP.

---

```nginx
  location = /healthz { return 200 "ok\n"; }
```

"If someone asks exactly for `/healthz`, immediately return HTTP 200 with text `ok`. Don't look for a file, don't proxy anywhere."

This is nginx's own health check. Kubernetes uses this to confirm the frontend pod is alive.

---

# QUESTION 6 — Without api-gateway, Can't We Manage?

Technically yes, but it would be a disaster. Let's see what would break:

## Scenario: Remove api-gateway, expose services directly

```yaml
# If we removed api-gateway and exposed services directly:
account-service:
  ports:
    - "8081:8080"    # browser directly calls localhost:8081
transaction-service:
  ports:
    - "8082:8080"    # browser directly calls localhost:8082
```

**Problems:**

1. **No Auth:** `app.js` would call `http://localhost:8081/accounts` — zero authentication. Anyone can access any account. No JWT check.

2. **Frontend knows ALL service addresses:** `app.js` would need:
   ```javascript
   const ACCOUNT_URL = 'http://localhost:8081';
   const TRANSACTION_URL = 'http://localhost:8082';
   ```
   If a service moves ports or a new service is added, frontend code must change.

3. **CORS problems:** Browser security blocks JavaScript from calling a different port (`localhost:3000` calling `localhost:8081` is a "cross-origin" request). You'd need CORS headers on every service.

4. **No rate limiting:** Each service needs its own rate limiter. Code duplication.

5. **No single entry point:** Multiple doors into the bank. Security nightmare.

**api-gateway solves all of this:**
- One address: `localhost:3000/api/...` → nginx → api-gateway
- JWT checked once at the gateway
- Rate limit enforced once at the gateway
- Services stay internal and private
- Frontend only knows one URL: `/api/`

---

# QUESTION 7 — The Complete Map: Who Talks To Whom and How

```
YOUR LAPTOP
──────────────────────────────────────────────────────────────

  Browser
    │ localhost:3000
    │ (only address the browser knows)
    │
─── PORT MAPPING 3000→8080 ───────────────────────────────────

DOCKER PRIVATE NETWORK
──────────────────────────────────────────────────────────────

  nginx container (frontend)
    │
    ├── GET /app.js      → reads /usr/share/nginx/html/app.js → browser
    ├── GET /index.html  → reads /usr/share/nginx/html/index.html → browser
    │
    └── ANY /api/*       → proxy to http://api-gateway:8080
                                        │
                              ┌─────────▼──────────┐
                              │    api-gateway      │
                              │                     │
                              │  rateLimit check    │
                              │  JWT check          │
                              │  strip /api prefix  │
                              └─────────┬───────────┘
                                        │
                          ┌─────────────┴─────────────┐
                          │                           │
              /accounts/* │                           │ /transactions/*
                          ▼                           ▼
              ┌───────────────────┐       ┌───────────────────────┐
              │  account-service  │       │  transaction-service  │
              │                   │       │                       │
              │  reads env var:   │       │  reads env var:       │
              │  DB_HOST=postgres │       │  ACCOUNT_SERVICE_URL  │
              │                   │       │  = http://account-    │
              │  SQL queries to   │       │    service:8080       │
              │  postgres         │       │                       │
              └────────┬──────────┘       └──────────┬────────────┘
                       │                             │
                       │                  calls account-service:
                       │                  fetch('http://account-service:8080/...')
                       │                             │
                       ▼                             │
              ┌───────────────────┐                  │
              │    PostgreSQL     │ ◄────────────────┘
              │    (postgres)     │   (account-service handles all DB writes)
              └───────────────────┘


notification-service
  ← called by transaction-service after every transfer/deposit
  ← fetch('http://notification-service:8080/events')
  ← no database, just logs events to memory
```

---

# QUESTION 8 — The Summary Table: Every Service's Job and Address

| Service | What it does | Who calls it | Who it calls | Docker DNS name |
|---|---|---|---|---|
| `frontend` (nginx) | Serve HTML/JS/CSS + proxy /api/ | Browser (from laptop) | api-gateway | `frontend` |
| `api-gateway` | JWT auth + rate limit + route | nginx (`/api/*`) | account-service, transaction-service | `api-gateway` |
| `account-service` | Manage accounts + balances in DB | api-gateway, transaction-service | postgres | `account-service` |
| `transaction-service` | Orchestrate transfers | api-gateway | account-service, notification-service | `transaction-service` |
| `notification-service` | Log events | transaction-service | nobody | `notification-service` |
| `postgres` | Store all data permanently | account-service | nobody (it IS the data) | `postgres` |

---

# QUESTION 9 — One Button Click, Full Journey with All Layers

**Action:** Venkatesh clicks "Transfer" — from Account 1 to Account 2, amount 300000 paise (₹3,000).

```
STEP 1 — BROWSER (app.js)
  User clicks Transfer button
  app.js: call('/transactions/transfer', { from:1, to:2, amount:300000 })
  Builds URL: '/api' + '/transactions/transfer' = '/api/transactions/transfer'
  Attaches header: Authorization: Bearer eyJhbGci...
  Calls: fetch('http://localhost:3000/api/transactions/transfer')
               ↑
               └── goes to localhost:3000 (the only address browser knows)

STEP 2 — PORT MAPPING (docker-compose)
  laptop:3000  →  nginx container:8080
  (docker-compose "3000:8080")

STEP 3 — NGINX (nginx.conf)
  Receives: POST /api/transactions/transfer
  Checks rules:
    location / ?   → NO, starts with /api/
    location /api/ ? → YES
  Action: proxy_pass http://api-gateway:8080
  Docker DNS resolves "api-gateway" → 172.18.0.4 (example internal IP)
  Adds header: X-Real-IP: 192.168.1.5 (your laptop's IP)
  Forwards request to api-gateway:8080

STEP 4 — API-GATEWAY (index.js + auth.js + rateLimit.js)
  Receives: POST /api/transactions/transfer
  
  rateLimit.js:
    key = req.ip (from X-Real-IP header set by nginx)
    bucket for this IP: count = 1, resetAt = now + 60s
    count(1) <= 120 → ✅ next()
  
  app.use('/api/transactions') → matches
  
  requireAuth (auth.js):
    header: "Bearer eyJhbGci..."
    jwt.verify(token, 'dev-secret-change-me')
    → { sub: 'venkatesh@village.com', iat: ..., exp: ... }
    → not expired ✅
    → req.user = { sub: 'venkatesh@village.com' }
    next()
  
  proxy() function:
    url = 'http://transaction-service:8080' + '/transactions/transfer'
          (removed /api from /api/transactions/transfer)
    Docker DNS: "transaction-service" → 172.18.0.5
    fetch('http://transaction-service:8080/transactions/transfer', {
      method: 'POST',
      body: '{"from_account_id":1,"to_account_id":2,"amount_cents":300000}'
    })

STEP 5 — TRANSACTION-SERVICE (index.js)
  Receives: POST /transactions/transfer
  Reads: from_account_id=1, to_account_id=2, amount_cents=300000
  
  callAccount('/accounts/1/debit', { amount_cents: 300000 }):
    ACCOUNT_URL = process.env.ACCOUNT_SERVICE_URL = 'http://account-service:8080'
    Docker DNS: "account-service" → 172.18.0.3
    fetch('http://account-service:8080/accounts/1/debit', { body: {300000} })

STEP 6 — ACCOUNT-SERVICE (index.js + db.js) — for DEBIT
  Receives: POST /accounts/1/debit
  db.js: connects to postgres (DB_HOST=postgres, Docker DNS resolves it)
  SQL:
    BEGIN
    SELECT balance_cents FROM accounts WHERE id=1 FOR UPDATE
    → balance = 700000 paise (₹7,000)
    700000 >= 300000 → enough money ✅
    UPDATE accounts SET balance_cents = 700000 - 300000 = 400000 WHERE id=1
    COMMIT
  Returns: { id:1, balance_cents: "400000" }

STEP 7 — BACK TO TRANSACTION-SERVICE
  Debit ✅ (account 1 now has 400000)
  
  callAccount('/accounts/2/credit', { amount_cents: 300000 }):
    fetch('http://account-service:8080/accounts/2/credit', { body: {300000} })

STEP 8 — ACCOUNT-SERVICE again — for CREDIT
  Receives: POST /accounts/2/credit
  SQL:
    UPDATE accounts SET balance_cents = balance_cents + 300000 WHERE id=2
  Returns: { id:2, balance_cents: "300000" }

STEP 9 — TRANSACTION-SERVICE — publish event
  Both debit and credit succeeded ✅
  publisher.js:
    No PUBSUB_TOPIC_ID set → local mode
    fetch('http://notification-service:8080/events', {
      body: { type:'transaction.completed', from_account_id:1, to_account_id:2, amount_cents:300000 }
    })
  notification-service logs: [NOTIFY] OK {...}
  
  Returns to api-gateway: { status:'completed', type:'transaction.completed', ... }

STEP 10 — API-GATEWAY
  Receives response from transaction-service
  Passes it back to nginx (res.send(text))

STEP 11 — NGINX
  Receives response from api-gateway
  Passes it back to browser

STEP 12 — BROWSER (app.js)
  fetch() resolves with { status:'completed', ... }
  call() returns the data
  log('transfer ok: {"status":"completed",...}')
  refreshAccounts() → new fetch('/api/accounts') → table updates

FINAL STATE:
  Account 1 (Venkatesh): was ₹7,000 → now ₹4,000
  Account 2 (Laxmi):     was ₹0     → now ₹3,000
  Notification-service:  logged the event
  Venkatesh sees:        "transfer ok" in the Log, table shows new balances
```

---

# SUMMARY — The 10 Things You Must Remember

1. **API = a defined list of questions and answers** between programs. Browser cannot touch a database directly. API is the translator.

2. **nginx sits between the browser and api-gateway.** It has exactly two jobs: serve files + proxy `/api/`. It knows NOTHING about account-service or transaction-service.

3. **app.js and index.html live INSIDE the nginx container** — put there by `COPY public /usr/share/nginx/html` in the Dockerfile. There is no separate "frontend container" and "nginx container" — they are ONE.

4. **Port mapping** (`"3000:8080"` in docker-compose) is the door from your laptop into Docker's private network. LEFT = your laptop port. RIGHT = container port.

5. **Docker DNS** — inside Docker network, containers find each other by SERVICE NAME, not by IP. `http://account-service:8080` works because Docker automatically resolves `account-service` to the container's private IP.

6. **Service addresses are set via environment variables** in docker-compose.yml (e.g. `ACCOUNT_SERVICE_URL: http://account-service:8080`). The code reads `process.env.ACCOUNT_SERVICE_URL`.

7. **api-gateway is NOT optional.** Without it: no auth, no rate limiting, frontend knows all service addresses, CORS problems, security disaster.

8. **nginx.conf** has two rules: `location /` (serve files from disk) and `location /api/` (proxy to api-gateway). That is the entire routing logic of the frontend.

9. **Each service only knows about its direct dependencies.** nginx knows api-gateway. api-gateway knows account-service and transaction-service. transaction-service knows account-service and notification-service. account-service knows postgres. Nobody knows everyone.

10. **This exact pattern (DNS names + environment variables + port mapping) is how Kubernetes works too.** The names change (Kubernetes Service instead of Docker service name, ConfigMap/Secret instead of docker-compose environment) but the concept is identical. Master this now and Kubernetes service mesh will make sense immediately.
