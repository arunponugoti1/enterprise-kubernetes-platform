# Frontend Code Walkthrough — Line by Line
## Telangana Village Layman's Deep Explanation

---

## The Big Picture First — Who Does What

Before reading a single line of code, understand the cast of characters involved when a customer clicks any button on this page:

```
CUSTOMER (browser)
    │  clicks a button on the webpage
    ▼
index.html  ← the visible page (boards, forms, table)
app.js      ← the invisible brain (listens, sends, updates)
    │  makes a fetch() call to /api/...
    ▼
nginx (frontend container — port 3000)
    │  sees /api/ → forwards to api-gateway
    ▼
api-gateway (port 8080)
    │  checks rate limit, checks JWT token
    │  strips /api → routes to correct service
    ▼
account-service      OR     transaction-service
    │                               │
    ▼                               ▼
PostgreSQL                   account-service
(database)                   (for debit/credit)
```

The customer sees ONLY the webpage. They have no idea that 5 services are working behind the scenes.

---

# PART 1 — `index.html` — The Bank's Display Board

Think of `index.html` as the **physical display board, forms, and counter layout** of the village bank. It describes WHAT to show — no logic, no calculations, just structure.

---

## Line 1: `<!DOCTYPE html>`

```html
<!DOCTYPE html>
```

The first line of every HTML file in the world. It tells the browser: "Read this file as modern HTML5 rules." Without this, the browser uses old compatibility mode and may display things incorrectly.

**Village analogy:** The cover page of an official government document that says "This is a Telangana State Government Form (2024 edition)." It tells the reader which rules apply.

---

## Lines 3–8: The `<head>` — Instructions the Customer Never Sees

```html
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Fin-DevOps Demo</title>
  <link rel="stylesheet" href="/styles.css" />
</head>
```

The `<head>` section contains **setup instructions for the browser** — the customer never sees this content directly.

| Line | What it does | Village analogy |
|---|---|---|
| `charset="UTF-8"` | Support Telugu, Hindi, Arabic, emojis — all characters | "We accept all languages at this counter" |
| `viewport` | Makes the page fit on mobile screens | "The counter adjusts its height for short people and tall people" |
| `<title>` | Text shown on browser tab | The name written on the bank's signboard outside |
| `<link rel="stylesheet">` | Load the CSS file that makes things look pretty | Call the interior decorator to paint and arrange the counter |

---

## Lines 10–13: The `<header>` — The Bank's Signboard

```html
<header>
  <h1>FinDevOps Demo</h1>
  <div id="auth-status">not signed in</div>
</header>
```

The top of every page. Two things:
1. `<h1>FinDevOps Demo</h1>` — the big bank name written at the top
2. `<div id="auth-status">not signed in</div>` — the status display

**The `id="auth-status"` is critical.** The `id` attribute is like a **name tag** on a specific element. JavaScript uses these name tags to find and update elements. When you log in, `app.js` finds this element by its id and changes the text from "not signed in" to "signed in."

**Village analogy:** The board outside the cashier's window that says "Counter Open" or "Counter Closed." When you sign in, the board flips. The `id="auth-status"` is the name we gave that specific board so the JavaScript knows exactly which board to flip.

---

## Lines 16–22: Section 1 — The Login Form

```html
<section>
  <h2>1. Sign in</h2>
  <form id="login-form">
    <input type="email" id="email" placeholder="you@example.com" required />
    <button type="submit">Get token</button>
  </form>
</section>
```

A simple form with one email input and one button.

**Every element has a job:**

| Element | `id` | Why the id exists |
|---|---|---|
| `<form>` | `login-form` | JavaScript attaches a "submit" listener to this form |
| `<input type="email">` | `email` | JavaScript reads `$('email').value` to get what you typed |
| `<button type="submit">` | none | Clicking this button triggers the form's submit event |

**`type="email"`** — the browser validates it's a proper email format before allowing submit. Catches basic typos without any JavaScript needed.

**`required`** — browser won't allow submit if the field is empty.

**`placeholder="you@example.com"`** — the grey hint text shown when the field is empty. Disappears when you start typing.

---

## Lines 24–30: Section 2 — Create Account Form

```html
<form id="create-account-form">
  <input type="text"  id="owner_name"    placeholder="Owner name"    required />
  <input type="email" id="account_email" placeholder="Account email" required />
  <button type="submit">Create</button>
</form>
```

Two inputs — owner name and email. JavaScript reads both using their `id`s.

**Notice:** The email input here has `id="account_email"` — NOT `id="email"`. That's because we already used `id="email"` for the login email input. Each `id` must be unique on the entire page. If two elements had the same `id`, JavaScript's `getElementById()` would get confused.

**Village analogy:** Two different counters in the bank. Counter 1 has a "Login Name Card" (`id="email"`). Counter 2 has an "Account Email Card" (`id="account_email"`). Different cards, different counters, no confusion.

---

## Lines 32–40: Section 3 — The Accounts Table

```html
<section>
  <h2>3. Accounts</h2>
  <button id="refresh-accounts">Refresh</button>
  <table id="accounts-table">
    <thead>
      <tr><th>ID</th><th>Owner</th><th>Email</th><th>Balance</th></tr>
    </thead>
    <tbody></tbody>       ← THIS IS EMPTY ON PURPOSE
  </table>
</section>
```

**The `<tbody></tbody>` is empty when the page loads.** This is intentional. JavaScript fills it in after it fetches account data from the server.

**The table structure:**
- `<thead>` — the header row (column titles: ID, Owner, Email, Balance). Fixed, never changes.
- `<tbody>` — the data rows. JavaScript clears and refills this every time "Refresh" is clicked.

**Village analogy:** A whiteboard at the bank with column headers already written: "Khata Number | Customer Name | Email | Balance." The rows below the header are empty. Every time the teller clicks Refresh, he erases the rows and rewrites them with current data from the register.

---

## Lines 42–65: Sections 4 & 5 — Transfer and Deposit Forms

```html
<!-- Transfer -->
<form id="transfer-form">
  <input type="number" id="from_id"  placeholder="From ID"        required />
  <input type="number" id="to_id"    placeholder="To ID"          required />
  <input type="number" id="amount"   placeholder="Amount (cents)" required />
  <button type="submit">Transfer</button>
</form>

<!-- Deposit -->
<form id="deposit-form">
  <input type="number" id="dep_id"     placeholder="Account ID"     required />
  <input type="number" id="dep_amount" placeholder="Amount (cents)" required />
  <button type="submit">Deposit</button>
</form>
```

**`type="number"`** — browser only allows numeric input, no letters.

**`dep_id` and `dep_amount`** — named differently from `from_id` and `amount` to avoid duplicate ids. The `dep_` prefix means "deposit."

---

## Line 61–64: The Log Section

```html
<section>
  <h2>Log</h2>
  <pre id="log"></pre>
</section>
```

`<pre>` means "preformatted text" — spaces and newlines are shown exactly as written (like a terminal output). JavaScript writes messages here to tell the user what happened after every action.

`id="log"` — JavaScript finds this element and adds text to it.

---

## Line 67: `<script>` — Why at the BOTTOM?

```html
  <script src="/app.js"></script>
</body>
```

The script is loaded at the **very end of the body** — after all HTML elements are on the page. This is critical.

**Why not at the top?**

If `<script>` was in the `<head>`, `app.js` would run BEFORE the HTML elements (forms, table, buttons) exist on the page. Then when `app.js` tries `document.getElementById('login-form')` — it would find nothing because the element hasn't been created yet. Everything would crash.

By putting it at the bottom, the entire page structure is loaded first, THEN the JavaScript runs and finds everything it needs.

**Village analogy:** You can't unlock a door before the door is built. HTML builds the door (the elements). JavaScript runs after the door is built and installs the lock (`addEventListener`). Script at top = trying to install a lock on a door that doesn't exist yet.

---

# PART 2 — `app.js` — The Brain, Line by Line

---

## Line 1: `const API_BASE = '/api'` — The Routing Design Decision

```javascript
const API_BASE = '/api';
```

**This single line is the key to how the entire frontend routing works.**

Every single API call in this file is built as:
```
API_BASE + path  =  '/api' + '/accounts'  =  '/api/accounts'
```

The `/api` prefix is the agreed-upon signal between the browser and nginx:

```
Browser calls:   /api/accounts
nginx sees it:   /api/ matches → proxy to api-gateway:8080
api-gateway sees: /api/accounts → auth check → strips /api → /accounts → account-service
```

**Why not just call `http://api-gateway:8080/accounts` directly?**

Because `api-gateway:8080` is an internal Docker network address. The browser runs on YOUR LAPTOP — it cannot reach Docker's internal network. The browser can only reach `localhost:3000` (nginx). nginx is inside Docker and CAN reach `api-gateway:8080`.

```
YOUR LAPTOP                     DOCKER NETWORK
─────────────────               ──────────────────────────────────
Browser                         nginx (frontend) :3000
  └──► localhost:3000   ──────►     │
                                    │ /api/* → proxy
                                    ▼
                                api-gateway :8080
                                    │
                                    ├──► account-service :8080
                                    └──► transaction-service :8080
```

**Village analogy:** You are standing outside the Mandal Office (on the street). You can only enter through the Main Gate (port 3000 / nginx). Once inside, the receptionist (nginx) can call any internal department (api-gateway, account-service) via the internal phone network. You on the street cannot call those internal phones directly — you go through the receptionist.

---

## Line 2: `let token = sessionStorage.getItem('token') || null`

```javascript
let token = sessionStorage.getItem('token') || null;
```

**Two things happening here:**

**1. `sessionStorage`** — The browser's temporary memory for the current tab.

| Memory type | Lives until | Example use |
|---|---|---|
| JavaScript variable | Page refresh or tab close | Temporary calculations |
| `sessionStorage` | Tab closes | Login tokens (our case) |
| `localStorage` | User manually clears it | App preferences |
| Cookie | Set expiry date | Remember-me logins |

We use `sessionStorage` so if you close the browser tab, your token is gone — you're automatically logged out next time. Like tearing up your visitor badge when you leave the building.

**2. `|| null`** — This means: "Try to get token from sessionStorage. If nothing is stored there (first visit, or after tab was closed), use `null` (no token)."

So on page load:
- First visit ever → `sessionStorage` is empty → `token = null`
- Came back after login in same tab → `sessionStorage` has token → `token = "eyJhbG..."`

---

## Line 4: `const $ = (id) => document.getElementById(id)`

```javascript
const $ = (id) => document.getElementById(id);
```

`document.getElementById('login-form')` is too long to type 20 times. This creates a shortcut: `$('login-form')` means the same thing.

`$` is just a variable name — it has no special meaning in vanilla JavaScript (unlike in jQuery). The developer chose `$` because it's short and familiar.

**Used everywhere:**
```javascript
$('email').value          // get what the user typed in the email field
$('log').textContent      // get/set the log text
$('accounts-table')       // find the table element
$('auth-status')          // find the "signed in" div
```

---

## Lines 5–8: `const log = (msg)` — The Activity Log

```javascript
const log = (msg) => {
  const ts = new Date().toLocaleTimeString();
  $('log').textContent = `[${ts}] ${msg}\n` + $('log').textContent;
};
```

Every action (login, create, transfer, deposit) calls `log('something happened')` to show a message on screen.

**Breaking it down:**
- `new Date().toLocaleTimeString()` → current time like `"10:45:32 AM"`
- `` `[${ts}] ${msg}\n` `` → formats as `"[10:45:32 AM] transfer ok: {...}\n"`
- The `\n` adds a new line after each message
- `+ $('log').textContent` → PREPEND new message BEFORE old messages

**Why prepend instead of append?**
So newest messages appear at the TOP of the log. If you appended, you'd have to scroll down to see the latest. Prepending shows the most recent first — like a WhatsApp chat in reverse.

**Village analogy:** The bank teller's notebook. Every transaction is written on a new line at the TOP, so the most recent is always visible without flipping pages.

---

## Lines 10–20: `setAuthStatus()` — Flip the "Open/Closed" Sign

```javascript
function setAuthStatus() {
  const el = $('auth-status');
  if (token) {
    el.textContent = 'signed in';
    el.classList.add('signed-in');
  } else {
    el.textContent = 'not signed in';
    el.classList.remove('signed-in');
  }
}
setAuthStatus();   // ← runs ONCE when the page first loads
```

This function looks at whether `token` has a value, and updates the header display accordingly.

- `el.textContent = 'signed in'` → changes the text shown
- `el.classList.add('signed-in')` → adds a CSS class that changes the color to green

`setAuthStatus()` is called on line 20 immediately when the page loads (to set the correct state if user already had a token from before). It's also called again inside the login handler after a successful login.

**Village analogy:** The board at the reception desk that says "Visitor Not Registered" or "Visitor Registered." When you show your ID, the receptionist flips it to "Registered." `setAuthStatus()` is the act of flipping that board.

---

## Lines 22–31: `call()` — THE MOST IMPORTANT FUNCTION

```javascript
async function call(path, opts = {}) {
  const headers = { 'content-type': 'application/json', ...(opts.headers || {}) };
  if (token) headers.authorization = `Bearer ${token}`;
  const res = await fetch(API_BASE + path, { ...opts, headers });
  const text = await res.text();
  let data;
  try { data = JSON.parse(text); } catch { data = text; }
  if (!res.ok) throw Object.assign(new Error(`HTTP ${res.status}`), { data });
  return data;
}
```

This is the **master HTTP helper function** that ALL API calls go through (except login). Understanding this function means understanding how the entire frontend communicates with the backend.

### Step 1 — Build the headers

```javascript
const headers = { 'content-type': 'application/json', ...(opts.headers || {}) };
```

Starts with `{ 'content-type': 'application/json' }` — tells the server "I am sending JSON data."

`...opts.headers` — if the caller passed custom headers, merge them in. The `...` (spread operator) is like saying "also include these items."

### Step 2 — Auto-attach the JWT token

```javascript
if (token) headers.authorization = `Bearer ${token}`;
```

If the user is logged in (`token` has a value), AUTOMATICALLY add the Authorization header to every request:
```
Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ...
```

**This is the genius of the `call()` function.** You NEVER have to remember to add the token manually for each API call. The function does it for you every time. If token is null (not logged in), this line is skipped — no auth header sent.

**Village analogy:** Every application form goes through the same clerk. She has a stamp that says "Visitor Badge #42". She stamps EVERY form automatically before sending it to the back office. You don't need to remember to put your badge number on every form — she does it for you.

### Step 3 — Make the HTTP request

```javascript
const res = await fetch(API_BASE + path, { ...opts, headers });
```

`API_BASE + path` = `'/api'` + `'/accounts'` = `'/api/accounts'`

`fetch()` is the browser's built-in function to make HTTP requests.

`await` means: "Wait for the response before continuing." Without `await`, the code would move on immediately without waiting for the server's reply.

### Step 4 — Read the response body

```javascript
const text = await res.text();
let data;
try { data = JSON.parse(text); } catch { data = text; }
```

`res.text()` — reads the entire response body as a plain string.

Then tries to parse it as JSON:
- If the server returned `{"id":1,"balance_cents":"500000"}` → `JSON.parse()` succeeds → `data` is a JavaScript object
- If the server returned something weird (HTML error page, plain text) → `JSON.parse()` throws an error → `catch` sets `data = text` (keep as raw string)

This prevents the entire page from crashing when a non-JSON response comes back.

### Step 5 — Handle errors

```javascript
if (!res.ok) throw Object.assign(new Error(`HTTP ${res.status}`), { data });
```

`res.ok` is true for status codes 200–299. False for 400, 401, 404, 500, etc.

If the status is an error, throw an exception. The error carries the status code (`HTTP 401`) AND the server's error message (`{ data }` — whatever the server returned).

This is caught in each form's `catch` block and displayed in the log as:
```
create failed: {"error":"email already exists"}
```

### Step 6 — Return the data

```javascript
return data;
```

On success, return the parsed JSON to whoever called `call()`.

### The Call in Practice

When the "Create" button is clicked:
```javascript
const data = await call('/accounts', {
  method: 'POST',
  body: JSON.stringify({ owner_name: 'Venkatesh', email: 'v@v.com' }),
});
```

Inside `call()` this becomes:
```
fetch('/api/accounts', {
  method: 'POST',
  headers: {
    'content-type': 'application/json',
    'authorization': 'Bearer eyJhbGci...'   ← auto-attached
  },
  body: '{"owner_name":"Venkatesh","email":"v@v.com"}'
})
```

---

## Lines 33–52: Login Form — Getting the Gate Pass

```javascript
$('login-form').addEventListener('submit', async (e) => {
  e.preventDefault();
  try {
    const res = await fetch('/api/auth/login', {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ email: $('email').value }),
    });
    const data = await res.json();
    if (!res.ok || !data.token) throw new Error(data.error || `HTTP ${res.status}`);
    token = data.token;
    sessionStorage.setItem('token', token);
    setAuthStatus();
    log(`signed in as ${$('email').value}, token expires in ${data.expires_in_seconds}s`);
  } catch (err) {
    log(`login failed: ${err.message}`);
  }
});
```

**`$('login-form').addEventListener('submit', ...)`**

"Find the element with id `login-form`. When its submit event fires (user clicks the button or presses Enter), run this function."

**`e.preventDefault()`**

By default, submitting an HTML form causes the browser to refresh the entire page (old-school web behavior). `preventDefault()` cancels that default behavior. We handle the submission ourselves with JavaScript instead.

**Why does login use `fetch()` directly instead of `call()`?**

Because `call()` auto-attaches the token header. For login, we don't have a token yet — we're getting it for the first time. Using `fetch()` directly is cleaner and clearer: "this is the one request that doesn't go through the normal auth flow."

**After successful login:**
```javascript
token = data.token;                          // save in JavaScript variable
sessionStorage.setItem('token', token);      // save in browser memory (survives page refresh)
setAuthStatus();                             // flip the "signed in" sign
log(`signed in as venkatesh@village.com, token expires in 3600s`);
```

**Village analogy:** You walk to the registration counter. The clerk asks your email. She creates a Visitor Badge (JWT) and hands it to you. You put it in your pocket (`token = data.token`). You also write the badge number in your notebook in case you need it later (`sessionStorage.setItem`). The "Visitor Registered" board flips (`setAuthStatus()`). Teller writes in log "Venkatesh registered at 10:45 AM."

---

## Lines 54–60: `requireToken()` — The Frontend Checkpoint

```javascript
function requireToken() {
  if (!token) {
    log('not signed in — click "Get token" in step 1 first');
    return false;
  }
  return true;
}
```

Every protected operation (create account, refresh, transfer, deposit) calls this first.

- No token → log a message → return `false` → the calling code sees `false` and stops
- Has token → return `true` → the calling code continues

**Usage pattern:**
```javascript
if (!requireToken()) return;   // if no token, stop here
// ... rest of the operation
```

**Important:** This is a USER EXPERIENCE protection, NOT a security protection. Anyone can open browser DevTools, set `token = 'fake'`, and bypass this check. The real security is in `requireAuth` inside api-gateway (server side). You cannot bypass server-side checks from the browser.

**Village analogy:** The self-check reminder at the counter. "Before filling in this form, make sure you have your Visitor Badge. No badge? Go to the registration counter first." A determined person could walk past this reminder — that's why there's also an actual security guard (api-gateway) at the inner door.

---

## Lines 62–78: Create Account Form

```javascript
$('create-account-form').addEventListener('submit', async (e) => {
  e.preventDefault();
  if (!requireToken()) return;         // ← stop if no token
  try {
    const data = await call('/accounts', {
      method: 'POST',
      body: JSON.stringify({
        owner_name: $('owner_name').value,     // read from input field
        email: $('account_email').value,       // read from input field
      }),
    });
    log(`created account #${data.id} (${data.email})`);
    refreshAccounts();                         // auto-refresh the table
  } catch (err) {
    log(`create failed: ${JSON.stringify(err.data || err.message)}`);
  }
});
```

**The routing chain when Create is clicked:**

```
User fills "Venkatesh Reddy" + "v@v.com" → clicks Create
            │
            ▼
app.js: call('/accounts', { method:'POST', body: {...} })
            │
            │  fetch('/api/accounts')  ← /api prefix added by call()
            ▼
nginx: sees /api/accounts
       location /api/ matches
       proxy_pass → http://api-gateway:8080
            │
            │  POST /api/accounts  (path unchanged)
            ▼
api-gateway: app.use('/api/accounts', requireAuth, proxy)
       rateLimit ✅
       requireAuth: jwt.verify() ✅
       proxy(): /api/accounts → strip /api → /accounts
       fetch('http://account-service:8080/accounts')
            │
            ▼
account-service: app.post('/accounts', ...)
       INSERT INTO accounts (owner_name, email) VALUES (...)
       returns: {"id":1, "owner_name":"Venkatesh Reddy", ...}
            │
            ▼ response bubbles back up
api-gateway → nginx → browser
            │
            ▼
app.js: data = {"id":1, "owner_name":"Venkatesh Reddy", ...}
log("created account #1 (v@v.com)")
refreshAccounts()    ← table updates automatically
```

---

## Lines 80–95: `refreshAccounts()` — The Live Table

```javascript
async function refreshAccounts() {
  if (!requireToken()) return;
  try {
    const accounts = await call('/accounts');          // GET /api/accounts
    const tbody = $('accounts-table').querySelector('tbody');
    tbody.innerHTML = '';                              // CLEAR the table
    for (const a of accounts) {
      const tr = document.createElement('tr');
      tr.innerHTML = `<td>${a.id}</td><td>${a.owner_name}</td><td>${a.email}</td><td>${a.balance_cents}</td>`;
      tbody.appendChild(tr);                           // ADD new row
    }
  } catch (err) {
    log(`refresh failed: ${JSON.stringify(err.data || err.message)}`);
  }
}
$('refresh-accounts').addEventListener('click', refreshAccounts);
```

**Step by step:**

1. `call('/accounts')` → `GET /api/accounts` → nginx proxies → api-gateway checks token → strips `/api` → `GET /accounts` → account-service returns all accounts as JSON array
2. `tbody.innerHTML = ''` → erase all existing rows in the table (start fresh)
3. Loop through each account in the array
4. `document.createElement('tr')` → create a new table row element
5. `tr.innerHTML = ...` → fill it with four cells (ID, name, email, balance)
6. `tbody.appendChild(tr)` → add the row to the table

**Why erase and refill instead of update existing rows?**
Simpler code. Erasing and rebuilding is O(n) either way. We don't need to track which rows changed — just rebuild from scratch with latest data.

**Why is `refreshAccounts` called automatically after Create, Transfer, Deposit?**
Because after any operation that changes a balance, the table would be stale. Auto-refreshing ensures the customer always sees current data without having to click Refresh manually.

---

## Lines 97–132: Transfer and Deposit Forms

### Transfer

```javascript
$('transfer-form').addEventListener('submit', async (e) => {
  e.preventDefault();
  if (!requireToken()) return;
  try {
    const data = await call('/transactions/transfer', {
      method: 'POST',
      body: JSON.stringify({
        from_account_id: Number($('from_id').value),    // ← Number() converts "1" string to 1 integer
        to_account_id:   Number($('to_id').value),
        amount_cents:    Number($('amount').value),
      }),
    });
    log(`transfer ok: ${JSON.stringify(data)}`);
    refreshAccounts();
  } catch (err) {
    log(`transfer failed: ${JSON.stringify(err.data || err.message)}`);
  }
});
```

**`Number($('from_id').value)`** — HTML inputs always return strings. The server expects numbers. `Number("1")` converts the string `"1"` to the integer `1`.

**The routing chain for `/transactions/transfer`:**

```
call('/transactions/transfer')
    │  fetch('/api/transactions/transfer')
    ▼
nginx: /api/ matches → proxy → api-gateway:8080
    ▼
api-gateway: app.use('/api/transactions', requireAuth, proxy)
    auth check ✅
    proxy: /api/transactions/transfer → strip /api → /transactions/transfer
    fetch('http://transaction-service:8080/transactions/transfer')
    ▼
transaction-service: app.post('/transactions/transfer', ...)
    callAccount(/accounts/from_id/debit)    → account-service
    callAccount(/accounts/to_id/credit)     → account-service
    publish(event)                          → notification-service
    returns: { status: "completed", ... }
    ▼
Response bubbles back → api-gateway → nginx → browser
```

### Deposit

```javascript
const data = await call('/transactions/deposit', {
  method: 'POST',
  body: JSON.stringify({
    account_id:   Number($('dep_id').value),
    amount_cents: Number($('dep_amount').value),
  }),
});
```

Same chain as transfer but hits `/transactions/deposit` endpoint on transaction-service.

---

# PART 3 — The Routing — How It All Connects

This is the most important section. Read this carefully.

## The Three Routing Layers

### Layer 1 — `app.js` builds the URL

```javascript
const API_BASE = '/api';
// ...
await call('/accounts')            // → fetch('/api/accounts')
await call('/accounts')            // → fetch('/api/accounts')
await call('/transactions/transfer') // → fetch('/api/transactions/transfer')
await call('/transactions/deposit')  // → fetch('/api/transactions/deposit')
```

All URLs have `/api` prepended. This is the signal for nginx.

### Layer 2 — nginx routes based on URL prefix

```nginx
# Rule 1: for /api/* → forward to api-gateway (do NOT serve from disk)
location /api/ {
  proxy_pass http://api-gateway:8080;
}

# Rule 2: for everything else → look for a file on disk
location / {
  try_files $uri $uri/ /index.html;
}
```

nginx has **two completely separate jobs** depending on the URL:

| URL starts with | nginx does |
|---|---|
| `/api/` | Proxy to api-gateway (call the back office) |
| Anything else (`/`, `/styles.css`, `/app.js`) | Serve file from disk (hand over the paper) |

```
GET /styles.css     → nginx looks in /usr/share/nginx/html/ → finds styles.css → sends it
GET /app.js         → nginx finds app.js → sends it
GET /               → nginx finds index.html → sends it
GET /api/accounts   → nginx sees /api/ → proxies to api-gateway:8080
GET /api/auth/login → nginx sees /api/ → proxies to api-gateway:8080
```

### Layer 3 — api-gateway routes based on service

```javascript
// Routes in api-gateway/src/index.js
app.post('/api/auth/login',         loginHandler);           // handled internally
app.use('/api/accounts',      requireAuth, proxy(ACCOUNT_URL));      // → account-service
app.use('/api/transactions',  requireAuth, proxy(TRANSACTION_URL));  // → transaction-service
```

api-gateway receives requests WITH the `/api` prefix (nginx preserved it). It matches:
- `/api/auth/login` → handle login internally (issue JWT)
- `/api/accounts/*` → check auth → strip `/api` → forward to account-service
- `/api/transactions/*` → check auth → strip `/api` → forward to transaction-service

**The URL stripping in the proxy:**
```javascript
const url = `${target}${req.originalUrl.replace(/^\/api/, '')}`;
```

`/api/accounts/1` → `.replace(/^\/api/, '')` → `/accounts/1`
`http://account-service:8080` + `/accounts/1` = `http://account-service:8080/accounts/1`

---

## Complete URL Transformation Table

| What browser calls | nginx receives | api-gateway receives | service receives |
|---|---|---|---|
| `GET /api/accounts` | `GET /api/accounts` | `GET /api/accounts` | `GET /accounts` |
| `POST /api/accounts` | `POST /api/accounts` | `POST /api/accounts` | `POST /accounts` |
| `GET /api/accounts/1` | `GET /api/accounts/1` | `GET /api/accounts/1` | `GET /accounts/1` |
| `POST /api/transactions/transfer` | `POST /api/transactions/transfer` | `POST /api/transactions/transfer` | `POST /transactions/transfer` |
| `POST /api/auth/login` | `POST /api/auth/login` | Handled internally | Never reaches a microservice |
| `GET /styles.css` | Served from disk | Never reaches api-gateway | Never reaches a microservice |

**Key observation:** The `/api` prefix passes through nginx unchanged and only gets stripped at the very last step inside the api-gateway's `proxy()` function.

---

## The Full Village Story — One Button Click

**Scenario:** Venkatesh clicks "Deposit" for ₹5,000 (500000 paise) into Account 1.

```
1. Venkatesh fills in Account ID = 1, Amount = 500000
   Clicks the "Deposit" button

2. app.js: deposit form submit event fires
   e.preventDefault() — browser won't refresh the page
   requireToken() — token is in memory ✅

3. app.js: call('/transactions/deposit', { method:'POST', body: {...} })
   Inside call():
     headers = { 'content-type': 'application/json' }
     headers.authorization = 'Bearer eyJhbGci...'  ← auto-attached
     fetch('/api/transactions/deposit', {
       method: 'POST',
       headers: { ... },
       body: '{"account_id":1,"amount_cents":500000}'
     })

4. Browser sends HTTP request to localhost:3000 (nginx)

5. nginx receives: POST /api/transactions/deposit
   Rule: location /api/ matches
   Action: proxy_pass → http://api-gateway:8080
   Also adds: X-Real-IP: <your laptop's IP>
   Forwards: POST /api/transactions/deposit with all headers

6. api-gateway receives: POST /api/transactions/deposit
   Step A: rateLimit middleware — count: 1 of 120 ✅
   Step B: app.use('/api/transactions') matches
   Step C: requireAuth middleware
           header: "Bearer eyJhbGci..."
           jwt.verify(token, 'dev-secret-change-me') ✅
           req.user = { sub: 'venkatesh@village.com' }
   Step D: proxy(TRANSACTION_URL, req, res)
           url = 'http://transaction-service:8080' + '/transactions/deposit'
                 (removed /api from path)
           fetch('http://transaction-service:8080/transactions/deposit', {
             method: 'POST',
             body: '{"account_id":1,"amount_cents":500000}'
           })

7. transaction-service receives: POST /transactions/deposit
   Reads: account_id=1, amount_cents=500000
   callAccount('/accounts/1/credit', { amount_cents: 500000 })
   → fetch('http://account-service:8080/accounts/1/credit')

8. account-service receives: POST /accounts/1/credit
   SQL: UPDATE accounts SET balance_cents = balance_cents + 500000 WHERE id = 1
   Returns: { id:1, owner_name:'Venkatesh Reddy', balance_cents:'500000', ... }

9. Response bubbles back up:
   account-service → transaction-service:
     { status:'completed', account_id:1, amount_cents:500000 }
   transaction-service → publish event to notification-service (fire-and-forget)
   transaction-service → api-gateway:
     { status:'completed', account_id:1, amount_cents:500000 }
   api-gateway → nginx → browser

10. app.js: call() receives the response
    data = { status:'completed', account_id:1, amount_cents:500000 }
    res.ok = true (status 201)
    returns data

11. app.js deposit handler:
    log('deposit ok: {"status":"completed","account_id":1,"amount_cents":500000}')
    refreshAccounts()   ← triggers another call('/accounts') → table updates

12. Venkatesh sees in the Log section:
    "[10:45:32 AM] deposit ok: {"status":"completed","account_id":1,"amount_cents":500000}"
    And the Accounts table now shows Account 1 with balance 500000
```

**Total services involved:** browser → nginx → api-gateway → transaction-service → account-service → PostgreSQL → and back.
**Venkatesh only saw:** a form and a log message.

---

## Summary — The Design Decisions Explained

| Decision | Why |
|---|---|
| `API_BASE = '/api'` | All API calls go through nginx's `/api/` proxy rule — single consistent prefix |
| `call()` helper function | Token is auto-attached to every request — no chance of forgetting it |
| `sessionStorage` for token | Tab-close = auto-logout — safer than localStorage for auth tokens |
| `e.preventDefault()` on all forms | Prevent old-school page refresh; handle everything with JavaScript |
| `<script>` at bottom of body | HTML elements must exist before JavaScript tries to find them |
| `refreshAccounts()` after every mutation | Customer always sees fresh data after any change |
| `Number()` on all numeric inputs | HTML inputs return strings; APIs expect integers |
| Login uses `fetch()` directly (not `call()`) | `call()` attaches token; login doesn't have a token yet |
| `requireToken()` before every action | Better UX — show clear message instead of cryptic 401 error |
| Empty `<tbody>` in HTML | Table is filled dynamically by JavaScript, not hardcoded in HTML |
