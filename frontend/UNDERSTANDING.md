# Frontend — Telangana Village Layman's Guide

---

## The Village Setup — What Is This Service?

So far our village bank has:
- **Accountant** (`account-service`) — owns the register, handles balances
- **Hawala Agent** (`transaction-service`) — coordinates transfers
- **Peon** (`notification-service`) — announces events
- **Main Gate Guard** (`api-gateway`) — checks identity passes, limits entry

But all of these are **back-office staff**. The customer on the street has no idea any of them exist. The customer only sees one thing — **the front window of the bank**.

The **frontend** is that front window. It is the only thing the customer (browser) ever looks at directly.

---

## Why Four Files? What Does Each Do?

| File | Village Role | Job |
|---|---|---|
| `Dockerfile` | **Blueprint** of the reception counter | How to build and run the frontend container |
| `nginx.conf` | **Receptionist's rulebook** | Which files to serve, where to forward `/api/*` requests |
| `public/index.html` | **The bank's display board + forms** | The visible web page (sections, buttons, table) |
| `public/app.js` | **The smart self-filling form logic** | JavaScript that makes the page interactive |

---

## Why nginx? Why NOT Node.js?

Every other service (account, transaction, notification, api-gateway) runs with **Node.js** because they have logic — they read databases, make HTTP calls, verify tokens.

The frontend has **no logic to run on the server**. It is just files sitting on disk:
- `index.html` — a document
- `app.js` — a script
- `styles.css` — a style sheet

**nginx** is a world-class static file server. It reads files from disk and sends them to the browser at extremely high speed, using almost no memory or CPU. Using Node.js just to serve files would be like hiring a senior engineer to open and close a filing cabinet.

**Village analogy:** You don't hire a bank manager to hand out application forms at the reception desk. You hire a simple clerk (nginx). The manager (Node.js) works in the back office where actual decisions are made.

---

## The Dockerfile — Simplest of All

```dockerfile
FROM nginx:1.27-alpine        # Start with official nginx image
COPY nginx.conf /etc/nginx/conf.d/default.conf  # Give nginx our rules
COPY public /usr/share/nginx/html               # Put our HTML/JS/CSS files in place
EXPOSE 8080                   # Open the window
```

Compare this to account-service's Dockerfile: that had a multi-stage build, npm install, non-root user setup. This has **4 lines**.

Why so simple?
- No dependencies to install (no `package.json`, no `npm install`)
- No code to compile or build
- nginx comes pre-installed in the base image
- We just copy our files and config in place

**Village analogy:** Setting up the reception counter. You bring in a pre-made counter (nginx image), paste your rules on it (nginx.conf), put your forms on the desk (public/), and open the shutter (EXPOSE 8080). Done.

---

## Deep Dive: `nginx.conf` — The Receptionist's Rulebook

```nginx
server {
  listen 8080;
  server_name _;

  root /usr/share/nginx/html;    # where our files live
  index index.html;

  location / {
    try_files $uri $uri/ /index.html;
  }

  location /api/ {
    proxy_pass http://api-gateway:8080;
    proxy_http_version 1.1;
    proxy_set_header Host             $host;
    proxy_set_header X-Real-IP        $remote_addr;
    proxy_set_header X-Forwarded-For  $proxy_add_x_forwarded_for;
  }

  location = /healthz { return 200 "ok\n"; }
}
```

### Rule 1 — `location /` — Serve Static Files

```nginx
location / {
  try_files $uri $uri/ /index.html;
}
```

When a browser asks for a file, nginx tries in this order:
1. Is there an exact file at this path? → serve it
2. Is there a directory at this path? → serve its index
3. Neither exists → serve `/index.html` anyway (fallback)

**Why the fallback to `/index.html`?**
This is called **SPA routing** (Single Page Application). When the user bookmarks a URL like `/accounts/1`, there is no file called `accounts/1` on disk. The fallback ensures `index.html` is always served, and then `app.js` takes over and handles the route in the browser.

**Village analogy:** Customer walks in and asks for "Form 7B." Clerk looks in drawer — it's there, hands it over. If it's not there, clerk says "Here, take the general form, you'll find what you need in there."

### Rule 2 — `location /api/` — The Intercom to the Back Office

```nginx
location /api/ {
  proxy_pass http://api-gateway:8080;
  ...
}
```

This is the **most important line in the entire nginx.conf**.

When the browser sends any request starting with `/api/`, nginx does NOT look for a file on disk. Instead it **forwards (proxies) the request to api-gateway** running at `http://api-gateway:8080`.

**The path is preserved** (because `proxy_pass` has no trailing slash). So:
```
Browser sends:    GET /api/accounts
nginx forwards:   GET /api/accounts  → api-gateway:8080
                  (same path, api-gateway understands /api/...)
```

**Why does the browser use `/api/`?**
The browser only knows one address — the frontend's address (`localhost:3000`). It does NOT know that api-gateway exists at port 8080. nginx is the middleman that secretly forwards the request.

**Village analogy:** Customer fills in an application form at the reception counter and hands it to the clerk. The clerk has an intercom. She presses the button and forwards the form to the back office (api-gateway). Customer never sees the back office. Customer only deals with the reception desk.

### Rule 3 — `proxy_set_header X-Real-IP $remote_addr`

```nginx
proxy_set_header X-Real-IP        $remote_addr;
proxy_set_header X-Forwarded-For  $proxy_add_x_forwarded_for;
```

**The problem:** When nginx proxies a request to api-gateway, the request arrives at api-gateway FROM nginx's IP address — not the actual customer's IP. The `rateLimit.js` uses `req.ip` to count requests per customer. Without this header, api-gateway would see nginx's IP for EVERY request, and all customers would share ONE rate limit bucket — one person's flood attack would block everyone.

**The fix:** nginx tells api-gateway "the real customer's IP is in `X-Real-IP`." api-gateway (Express) can then use this to correctly identify each individual customer.

**Village analogy:** The receptionist is taking applications on behalf of customers. When she sends the form to the back office, she writes on it: "This form was brought to me by Venkatesh, who lives at House #42." Without that note, the back office would think ALL forms came from the receptionist herself.

### Rule 4 — `location = /healthz { return 200 "ok\n"; }`

This is nginx's own health check — no file, no proxy, just an instant `200 ok` response. Kubernetes uses this to check if nginx is alive without any backend involved.

---

## Deep Dive: `index.html` — The Bank's Display Board

```html
<section><h2>1. Sign in</h2>...</section>
<section><h2>2. Create account</h2>...</section>
<section><h2>3. Accounts</h2>...</section>
<section><h2>4. Transfer</h2>...</section>
<section><h2>5. Deposit</h2>...</section>
<section><h2>Log</h2><pre id="log"></pre></section>
```

Six sections, each matching one operation. This is purely HTML structure — no logic here. All logic is in `app.js`.

**Notice:** `<script src="/app.js"></script>` is at the BOTTOM of the body. This is intentional — all HTML elements are loaded first, then the script runs. If the script ran first, it would try to find elements that don't exist yet.

---

## Deep Dive: `app.js` — The Smart Form Logic

This is pure vanilla JavaScript (no React, no Vue, no Angular). Let's go section by section.

### 1. The Starting State

```javascript
const API_BASE = '/api';
let token = sessionStorage.getItem('token') || null;
```

- `API_BASE = '/api'` — all API calls go to `/api/...` which nginx proxies to api-gateway. The browser never directly talks to api-gateway's port.
- `sessionStorage` — the browser's temporary memory for the current tab. When the tab is closed, all sessionStorage data is wiped.

**sessionStorage vs localStorage:**
| | sessionStorage | localStorage |
|---|---|---|
| Lives until | Tab is closed | Browser clears it (weeks/months) |
| Security | Safer for tokens | Riskier for tokens |
| Use case | JWT tokens, session data | User preferences, settings |

We use `sessionStorage` for the token so that closing the browser tab automatically logs you out. Like tearing up your visitor badge when you leave the building.

### 2. The `call()` Helper — The Auto-Stamp Machine

```javascript
async function call(path, opts = {}) {
  const headers = { 'content-type': 'application/json', ...(opts.headers || {}) };
  if (token) headers.authorization = `Bearer ${token}`;   // ← auto-attach token
  const res = await fetch(API_BASE + path, { ...opts, headers });
  const text = await res.text();
  let data;
  try { data = JSON.parse(text); } catch { data = text; }
  if (!res.ok) throw Object.assign(new Error(`HTTP ${res.status}`), { data });
  return data;
}
```

This is the single most important function in `app.js`. Every API call in the entire frontend goes through this function.

**What it does, step by step:**
1. **Adds `content-type: application/json`** to every request — tells the server "I am sending JSON"
2. **Auto-attaches the token** if one is saved — `Authorization: Bearer <token>` — so you never forget to include it
3. **Builds the full URL** — `API_BASE + path` = `/api` + `/accounts` = `/api/accounts`
4. **Makes the fetch call** — sends the request to nginx, which proxies to api-gateway
5. **Parses the response** — tries JSON first, falls back to raw text if parsing fails
6. **Throws on error** — if HTTP status is not 2xx, throws an error with the server's error message attached

**Village analogy:** Every application form goes through the same clerk. She automatically stamps your Visitor Badge number on every form before sending it to the back office. You don't have to remember to do it yourself every time.

### 3. Login — Getting the Gate Pass

```javascript
$('login-form').addEventListener('submit', async (e) => {
  e.preventDefault();
  try {
    const res = await fetch('/api/auth/login', { ... body: { email } });
    const data = await res.json();
    token = data.token;
    sessionStorage.setItem('token', token);   // save in browser memory
    setAuthStatus();                           // update "signed in" display
    log(`signed in as ${email}, token expires in ${data.expires_in_seconds}s`);
  } catch (err) {
    log(`login failed: ${err.message}`);
  }
});
```

**Notice:** The login form calls `fetch()` directly (NOT through the `call()` helper). Why? Because the `call()` function auto-attaches the token header — but for login, we DON'T have a token yet. If we used `call()`, it would just not attach a token and still work, but using `fetch()` directly is clearer — "this is the one call that doesn't need auth."

### 4. `requireToken()` — The Frontend Guard

```javascript
function requireToken() {
  if (!token) {
    log('not signed in — click "Get token" in step 1 first');
    return false;
  }
  return true;
}
```

Every action (create account, transfer, deposit) calls `requireToken()` first. If no token → show message in Log → return false → the action is cancelled before any API call is made.

**This is the frontend's equivalent of `requireAuth` in api-gateway.** Two layers of protection:
1. `requireToken()` in the browser — "don't even try the API call without a token" (fast, instant feedback)
2. `requireAuth` in api-gateway — "reject any request that doesn't have a valid token" (server-side enforcement)

The browser check is for user experience. The server check is for security. You always need BOTH — never rely only on the browser check, because anyone can bypass it with curl.

### 5. `refreshAccounts()` — Live Table Update

```javascript
async function refreshAccounts() {
  const accounts = await call('/accounts');
  const tbody = $('accounts-table').querySelector('tbody');
  tbody.innerHTML = '';                  // clear existing rows
  for (const a of accounts) {
    const tr = document.createElement('tr');
    tr.innerHTML = `<td>${a.id}</td><td>${a.owner_name}</td>...`;
    tbody.appendChild(tr);
  }
}
```

After every Create, Transfer, and Deposit operation, `refreshAccounts()` is called automatically. The table clears and refills with fresh data from the server.

**Village analogy:** After every transaction, the display board at the bank automatically updates to show all current account balances. You don't need to press F5 — the form itself triggers the refresh.

---

## The Complete Request Journey — Browser to Database

When the customer clicks "Transfer" in the browser:

```
Browser (app.js — call('/transactions/transfer'))
    │
    │  POST /api/transactions/transfer
    │  Content-Type: application/json
    │  Authorization: Bearer <jwt>
    ▼
nginx (frontend container — nginx.conf)
    │  location /api/ matched
    │  proxy_pass → api-gateway:8080
    │  adds X-Real-IP header
    ▼
api-gateway (port 8080)
    │  rateLimit check ✅
    │  requireAuth: jwt.verify() ✅
    │  proxy: strip /api → /transactions/transfer
    ▼
transaction-service (port 8080 internal)
    │  callAccount: debit sender → account-service
    │  callAccount: credit receiver → account-service
    │  publish event → notification-service
    ▼
account-service (port 8080 internal)
    │  SELECT FOR UPDATE (lock row)
    │  UPDATE balance
    │  COMMIT
    ▼
PostgreSQL (port 5432 internal)
    Data written to disk
```

**The browser only ever talks to port 3000 (nginx).** Every other port is invisible to it.

---

## Service Dependencies — Who Knows Whom

```
Browser
  └──► frontend/nginx :3000
             │
             ├── /  → serves static files from disk (no downstream call)
             └── /api/* → proxy → api-gateway:8080
                                        │
                                        ├── /api/accounts/* → account-service:8080
                                        └── /api/transactions/* → transaction-service:8080
```

**frontend knows about:** api-gateway (it's in nginx.conf: `proxy_pass http://api-gateway:8080`)
**frontend does NOT know about:** account-service, transaction-service, postgres

**api-gateway does NOT know about:** frontend (api-gateway just receives requests — doesn't care who sent them)

---

## Why No Framework (React / Vue / Angular)?

This is a **demo project** for learning DevOps, not a production customer-facing app. Vanilla JavaScript means:
- No `npm install` → no `node_modules` → no build step
- Just three files: html, js, css
- nginx serves them directly with zero processing
- Anyone can read and understand without knowing any framework
- Dockerfile is 4 lines instead of 20+

In a real company product, you would use React/Vue/Next.js — but the concepts (token storage, API calls, auth headers) are identical. Only the syntax changes.

---

## What Would Happen Without the Frontend?

Everything still works — all the services still run. You would just have to use curl commands like we've been doing all along.

The frontend adds:
- A human-readable interface (buttons, forms, table)
- Token management (saves token to sessionStorage automatically)
- Automatic table refresh after every operation
- Log messages showing what happened

**Village analogy:** The back-office staff can still do their jobs even if the reception counter is closed. But the customer can no longer walk in and submit a form. They'd have to go around the back and talk to each department directly — which is exactly what `curl` is.

---

## The Three Questions

### 1. Contract — What does frontend promise?
It serves HTML/CSS/JS files on port 8080. For `/api/*` requests, it proxies to api-gateway. For `/healthz`, it returns `200 ok` instantly.

### 2. Failure Modes
| Failure | What Happens |
|---|---|
| api-gateway is down | Browser can still load the page (HTML/JS served by nginx), but every API call fails with a network error |
| nginx crashes | The page can't load at all. 502 from docker-compose or Kubernetes |
| Token expired | Next API call returns 401. User sees "HTTP 401" in the Log section. They must sign in again. |
| sessionStorage cleared (tab closed) | User is auto-logged out. Token is gone. They sign in again next time. |

### 3. Portability
- **docker-compose local:** nginx connects to `http://api-gateway:8080` via Docker internal network
- **GKE production:** Same nginx.conf works — `api-gateway` resolves to the Kubernetes Service DNS name
- **CDN production:** The `public/` folder (HTML/JS/CSS) can be uploaded directly to S3 or a CDN — nginx is only needed for the `/api/` proxy in that case

---

## Summary in One Sentence

The `frontend` is the **bank's reception counter** — nginx serves the HTML form (index.html + app.js) to the customer's browser, and when the customer submits anything, nginx's intercom (proxy) silently forwards the request to the api-gateway's back office, so the customer only ever sees one address and never knows the whole bank system running behind it.
