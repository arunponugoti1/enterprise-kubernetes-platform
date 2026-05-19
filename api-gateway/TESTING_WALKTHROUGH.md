# API-Gateway — Live Testing Walkthrough

## Setup

**What is running (all 5 services):**
```
postgres          — almiraah (database), no host port needed
account-service   — Accountant at counter,  localhost:8081
notification-service — Announcer/Peon,      localhost:8083
transaction-service  — Hawala Agent,        localhost:8082
api-gateway       — Main Security Gate,     localhost:8080  ← THE ONLY ONE WE CALL
```

**How to start:**
```bash
docker compose up -d --build postgres account-service notification-service transaction-service api-gateway
```

**How to check logs:**
```bash
docker compose logs -f api-gateway
```

Expected startup log:
```
api-gateway-1 | api-gateway listening on 8080
```

---

## IMPORTANT — Token-Based Testing

This service is the first one where you need to **login first, get a token, then use it**.

Every test after login needs this header:
```
Authorization: Bearer <your-token-here>
```

### Save Your Token (PowerShell — recommended)
```powershell
$response = Invoke-RestMethod -Uri "http://localhost:8080/api/auth/login" `
  -Method POST -ContentType "application/json" `
  -Body '{"email":"venkatesh@village.com"}'
$TOKEN = $response.token
Write-Host "Token saved: $TOKEN"
```

### Save Your Token (Git Bash / WSL)
```bash
TOKEN=$(curl -s -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"venkatesh@village.com"}' | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
echo $TOKEN
```

Once saved, use `$TOKEN` in all curl commands below.

---

## Test 1 — Is the Gate Open? (`/healthz`)

```bash
curl http://localhost:8080/healthz
```

**Response:**
```json
{"status":"ok"}
```

**What this means:**
The main gate is open. api-gateway process is alive. No auth needed — this is a public health endpoint.

---

## Test 2 — Is the Gate Ready? (`/readyz`)

```bash
curl http://localhost:8080/readyz
```

**Response:**
```json
{"status":"ready"}
```

**What this means:**
Gate is ready for traffic. Like account-service, this has no DB check — api-gateway is stateless. Ready = process running = ready.

---

## Test 3 — Get Your Gate Pass (`/api/auth/login`)

This is the **public counter** — no token needed. You give your email, you get your pass.

```bash
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"venkatesh@village.com\"}"
```

**Response:**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ2ZW5rYXRlc2hAdmlsbGFnZS5jb20iLCJpYXQiOjE3Nzg1MDkyMzUsImV4cCI6MTc3ODUxMjgzNX0.muWTg8ERQKBXkmL1winYZsGKVjpQwBo3Qg3m0tCqu7E",
  "expires_in_seconds": 3600
}
```

**What this means:**
You received your sealed Gate Pass (JWT). It is valid for 3600 seconds (1 hour).

**The token has THREE parts separated by dots:**
```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9        ← Part 1: Header (algorithm used)
.eyJzdWIiOiJ2ZW5rYXRlc2hAdmlsbGFnZS5jb20...  ← Part 2: Payload (your email, issued-at, expiry)
.muWTg8ERQKBXkmL1winYZsGKVjpQwBo3Qg3m0tCqu7E ← Part 3: Signature (tamper-proof stamp)
```

Parts 1 and 2 are base64 — anyone can decode and read them. Only Part 3 can verify authenticity.

---

## Test 4 — Try Without a Token (Should Fail → 401)

```bash
curl -X POST http://localhost:8080/api/accounts \
  -H "Content-Type: application/json" \
  -d "{\"owner_name\":\"Venkatesh Reddy\",\"email\":\"venkatesh@village.com\"}"
```

**Response:**
```json
{"error":"missing bearer token"}
```

**What this means:**
You walked up to the protected counter without showing your pass. Guard says "Pass chupinchu, lekapothe andar raadu" (Show your pass, otherwise no entry).

Notice: The gateway rejected this BEFORE even calling account-service. account-service never knew this request existed.

---

## Test 5 — Try With a FAKE Token (Should Fail → 401)

```bash
curl -X POST http://localhost:8080/api/accounts \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer faketoken.invalid.abc123" \
  -d "{\"owner_name\":\"Venkatesh Reddy\",\"email\":\"venkatesh@village.com\"}"
```

**Response:**
```json
{"error":"invalid token","detail":"invalid token"}
```

**What this means:**
You showed a fake/forged pass. Guard held it to the light — the HMAC signature didn't match. "Naqli pass hai, bahar jao" (Fake pass, get out).

Again: account-service was never called. Gateway stopped it completely.

---

## Test 6 — Create Venkatesh's Account (With Valid Token → 201)

**PowerShell:**
```powershell
Invoke-WebRequest -Uri "http://localhost:8080/api/accounts" `
  -Method POST -ContentType "application/json" `
  -Headers @{Authorization="Bearer $TOKEN"} `
  -Body '{"owner_name":"Venkatesh Reddy","email":"venkatesh@village.com"}' `
  -UseBasicParsing
```

**curl (Git Bash / WSL):**
```bash
curl -X POST http://localhost:8080/api/accounts \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"owner_name":"Venkatesh Reddy","email":"venkatesh@village.com"}'
```

**Response:**
```json
{"id":1,"owner_name":"Venkatesh Reddy","email":"venkatesh@village.com","balance_cents":"0","created_at":"2026-05-11T14:21:34.678Z"}
```

**What happened behind the scenes:**
```
curl → api-gateway:8080
          ↓ rateLimit ✅ (count 1 of 120)
          ↓ requireAuth ✅ (token valid, req.user = { sub: "venkatesh@village.com" })
          ↓ proxy: /api/accounts → strips /api → /accounts
          ↓ account-service:8080 POST /accounts
          ↓ response passed back to curl
```

The gate let you in, directed you to the Accountant's counter, Accountant opened a new khata.

---

## Test 7 — Create Laxmi's Account (With Valid Token)

**PowerShell:**
```powershell
Invoke-WebRequest -Uri "http://localhost:8080/api/accounts" `
  -Method POST -ContentType "application/json" `
  -Headers @{Authorization="Bearer $TOKEN"} `
  -Body '{"owner_name":"Laxmi Devi","email":"laxmi@village.com"}' `
  -UseBasicParsing
```

**Response:**
```json
{"id":2,"owner_name":"Laxmi Devi","email":"laxmi@village.com","balance_cents":"0","created_at":"2026-05-11T14:21:34.744Z"}
```

---

## Test 8 — Deposit ₹10,000 via Gateway (Routed to transaction-service)

**PowerShell:**
```powershell
Invoke-WebRequest -Uri "http://localhost:8080/api/transactions/deposit" `
  -Method POST -ContentType "application/json" `
  -Headers @{Authorization="Bearer $TOKEN"} `
  -Body '{"account_id":1,"amount_cents":1000000}' `
  -UseBasicParsing
```

**curl (Git Bash / WSL):**
```bash
curl -X POST http://localhost:8080/api/transactions/deposit \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"account_id":1,"amount_cents":1000000}'
```

**Response:**
```json
{"status":"completed","account_id":1,"amount_cents":1000000}
```

**What happened:**
```
api-gateway received POST /api/transactions/deposit
    ↓ rateLimit ✅
    ↓ requireAuth ✅
    ↓ proxy: /api/transactions/deposit → /transactions/deposit
    ↓ transaction-service:8080
         ↓ transaction-service called account-service: POST /accounts/1/credit
         ↓ transaction-service published event to notification-service
    ↓ response returned through gateway back to you
```

The gate + three services all worked in a chain. You only called one address (port 8080).

---

## Test 9 — Transfer ₹3,000 from Venkatesh to Laxmi via Gateway

**PowerShell:**
```powershell
Invoke-WebRequest -Uri "http://localhost:8080/api/transactions/transfer" `
  -Method POST -ContentType "application/json" `
  -Headers @{Authorization="Bearer $TOKEN"} `
  -Body '{"from_account_id":1,"to_account_id":2,"amount_cents":300000}' `
  -UseBasicParsing
```

**curl (Git Bash / WSL):**
```bash
curl -X POST http://localhost:8080/api/transactions/transfer \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"from_account_id":1,"to_account_id":2,"amount_cents":300000}'
```

**Response:**
```json
{
  "status": "completed",
  "type": "transaction.completed",
  "from_account_id": 1,
  "to_account_id": 2,
  "amount_cents": 300000,
  "at": "2026-05-11T14:22:31.997Z"
}
```

---

## Test 10 — List All Accounts via Gateway (GET with Token)

**PowerShell:**
```powershell
Invoke-WebRequest -Uri "http://localhost:8080/api/accounts" `
  -Method GET `
  -Headers @{Authorization="Bearer $TOKEN"} `
  -UseBasicParsing
```

**curl (Git Bash / WSL):**
```bash
curl http://localhost:8080/api/accounts \
  -H "Authorization: Bearer $TOKEN"
```

**Response:**
```json
[
  {"id":1,"owner_name":"Venkatesh Reddy","balance_cents":"700000",...},
  {"id":2,"owner_name":"Laxmi Devi","balance_cents":"300000",...}
]
```

**What this proves:**
Both GET and POST go through the same auth middleware. The gateway handles ALL HTTP methods — one `app.use()` line covers everything under `/api/accounts`.

---

## Test 11 — Login With Missing Email (Validation at Gateway → 400)

```bash
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d "{}"
```

**Response:**
```json
{"error":"email required"}
```

**What this means:**
The login endpoint validates input before issuing any token. "Email ivvandi bhai" (Give your email, brother).

---

## Test 12 — 502 Bad Gateway (Backend Service Down)

This test shows what happens when you have a valid pass but the counter itself is closed.

**Step 1 — Stop account-service:**
```bash
docker compose stop account-service
```

**Step 2 — Try to list accounts (valid token, but service is down):**

```powershell
Invoke-WebRequest -Uri "http://localhost:8080/api/accounts" `
  -Method GET `
  -Headers @{Authorization="Bearer $TOKEN"} `
  -UseBasicParsing -ErrorAction SilentlyContinue
```

**Response (502):**
```json
{"error":"upstream unreachable","detail":"fetch failed"}
```

**What this means:**
- Your pass was valid ✅
- Rate limit was fine ✅
- Gateway tried to forward to account-service
- account-service was unreachable (container stopped)
- Gateway returned 502 Bad Gateway

**502 vs 401 vs 404:**
| Code | Meaning | Village Analogy |
|---|---|---|
| 401 | No or fake pass | "Pass nahi hai, andar mat aao" |
| 404 | Route doesn't exist on gateway | "Ee counter exist nahi karta" |
| 502 | Gateway is up, backend is down | "Gate khula, andar counter bandh hai" |

**Step 3 — Restart account-service:**
```bash
docker compose start account-service
```

---

## Test 13 — Rate Limit (429 Too Many Requests)

Send 125 rapid requests — the bucket holds 120, request 121+ gets blocked.

**PowerShell:**
```powershell
for ($i = 1; $i -le 125; $i++) {
    $r = Invoke-WebRequest -Uri "http://localhost:8080/healthz" `
         -Method GET -UseBasicParsing -ErrorAction SilentlyContinue
    if ($r.Content -match "rate limit") {
        Write-Host "429 hit on request #$i — $($r.Content)"
        break
    }
}
```

**Response (after request 121):**
```json
{"error":"rate limit exceeded"}
```

**What this means:**
- Requests 1–120: `{"status":"ok"}` — idly box has tokens left
- Request 121+: `{"error":"rate limit exceeded"}` — idly box empty
- After 60 seconds: box refills, you can make 120 more requests

**Why rate limit applies even to `/healthz`:**
Because `app.use(rateLimit)` is registered BEFORE any routes — it applies to EVERY request, including health checks, login, and everything else.

---

## Final State After All Tests

| Account | Owner | Final Balance |
|---|---|---|
| 1 | Venkatesh Reddy | ₹7,000 (700000 paise) |
| 2 | Laxmi Devi | ₹3,000 (300000 paise) |

Total: ₹10,000 conserved.

---

## The Full Request Journey — One Diagram

```
You (browser / curl)
        │
        │ POST /api/transactions/transfer
        │ Authorization: Bearer <jwt>
        ▼
┌──────────────────────────────────────────┐
│           api-gateway :8080              │
│                                          │
│  1. rateLimit.js — bucket check         │
│  2. requireAuth  — jwt.verify()         │
│  3. proxy()      — strip /api prefix    │
│     fetch → transaction-service:8080    │
└──────────────────────────────────────────┘
        │
        │ POST /transactions/transfer (no auth, internal)
        ▼
┌──────────────────────────────────────────┐
│       transaction-service :8080          │
│                                          │
│  1. callAccount → debit sender          │
│  2. callAccount → credit receiver       │
│  3. publish → notification-service      │
└──────────────────────────────────────────┘
        │
        │ POST /accounts/:id/debit  (internal)
        ▼
┌──────────────────────────────────────────┐
│        account-service :8081             │
│                                          │
│  SELECT FOR UPDATE → balance check      │
│  UPDATE balance → commit                │
└──────────────────────────────────────────┘
        │
        │ Responses bubble back up the chain
        ▼
You receive the final result
```

---

## All Endpoints Summary

| Endpoint | Method | Auth? | Rate Limited? | What It Does |
|---|---|---|---|---|
| `/healthz` | GET | No | Yes | Is gateway alive? |
| `/readyz` | GET | No | Yes | Is gateway ready? |
| `/api/auth/login` | POST | No | Yes | Get JWT token (show email) |
| `/api/accounts` | POST | **Yes** | Yes | Create account → account-service |
| `/api/accounts` | GET | **Yes** | Yes | List accounts → account-service |
| `/api/accounts/:id` | GET | **Yes** | Yes | Get one account → account-service |
| `/api/accounts/:id/credit` | POST | **Yes** | Yes | Credit → account-service |
| `/api/accounts/:id/debit` | POST | **Yes** | Yes | Debit → account-service |
| `/api/transactions/deposit` | POST | **Yes** | Yes | Deposit → transaction-service |
| `/api/transactions/transfer` | POST | **Yes** | Yes | Transfer → transaction-service |

---

## How to Stop

```bash
docker compose down
```

To also delete database data:
```bash
docker compose down -v
```
