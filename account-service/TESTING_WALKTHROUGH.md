# Account-Service — Live Testing Walkthrough

## Setup

**What was running:**
- `postgres` container — the actual database (register almiraah)
- `account-service` container — the cashier (our microservice)

**Port mapping:**
`http://localhost:8081` on your laptop → port `8080` inside the container

**How to start:**
```bash
docker compose up -d --build postgres account-service
```

**How to check logs:**
```bash
docker compose logs -f account-service
```

Expected startup log:
```
account-service-1 | account-service listening on 8080
```

---

## Bug Fixed Before Starting

The `Dockerfile` had a typo on line 1:
```
# WRONG
yeFROM node:20-alpine AS deps

# FIXED
FROM node:20-alpine AS deps
```
Build would have completely failed without fixing this first.

---

## Test 1 — Is the Service Alive? (`/healthz`)

```bash
curl http://localhost:8081/healthz
```

**Response:**
```json
{"status":"ok"}
```

**What this means:**
The "OPEN" board outside the bank. Service is running.
No database check — just confirms the process is alive.

---

## Test 2 — Is the Database Connected? (`/readyz`)

```bash
curl http://localhost:8081/readyz
```

**Response:**
```json
{"status":"ready"}
```

**What this means:**
Cashier is sitting AND the almiraah (PostgreSQL) key is working.
The code runs `SELECT 1` against the database. If it succeeds → ready.
Kubernetes uses this before sending any real traffic.

---

## Test 3 — Create Account for Venkatesh (`POST /accounts`)

```bash
curl -X POST http://localhost:8081/accounts \
  -H "Content-Type: application/json" \
  -d '{"owner_name":"Venkatesh Reddy","email":"venkatesh@village.com"}'
```

**Response:**
```json
{
  "id": 1,
  "owner_name": "Venkatesh Reddy",
  "email": "venkatesh@village.com",
  "balance_cents": "0",
  "created_at": "2026-05-09T07:46:59.503Z"
}
```

**What this means:**
New page created in the register. Khata number = 1. Balance starts at zero paise.

---

## Test 4 — Create Account for Laxmi (`POST /accounts`)

```bash
curl -X POST http://localhost:8081/accounts \
  -H "Content-Type: application/json" \
  -d '{"owner_name":"Laxmi Devi","email":"laxmi@village.com"}'
```

**Response:**
```json
{
  "id": 2,
  "owner_name": "Laxmi Devi",
  "email": "laxmi@village.com",
  "balance_cents": "0",
  "created_at": "2026-05-09T07:47:04.901Z"
}
```

**What this means:**
Second page in the register. Khata number = 2. Auto-numbered by PostgreSQL (`SERIAL`).

---

## Test 5 — Try Duplicate Email (Should Fail)

```bash
curl -X POST http://localhost:8081/accounts \
  -H "Content-Type: application/json" \
  -d '{"owner_name":"Duplicate Venkatesh","email":"venkatesh@village.com"}'
```

**Response:**
```json
{"error":"email already exists"}
```

**What this means:**
Email column is `UNIQUE` in the database.
PostgreSQL throws error code `23505` (unique violation).
Cashier catches it and returns 409 — one Aadhaar = one account.

---

## Test 6 — Try Missing Fields (Should Fail)

```bash
curl -X POST http://localhost:8081/accounts \
  -H "Content-Type: application/json" \
  -d '{"owner_name":"NoEmail Person"}'
```

**Response:**
```json
{"error":"owner_name and email are required"}
```

**What this means:**
Input validation runs BEFORE touching the database.
Cashier checks the form first — "Poori details teesko randi."
Returns 400 — bad request, your fault.

---

## Test 7 — List All Accounts (`GET /accounts`)

```bash
curl http://localhost:8081/accounts
```

**Response:**
```json
[
  {"id":1,"owner_name":"Venkatesh Reddy","email":"venkatesh@village.com","balance_cents":"0",...},
  {"id":2,"owner_name":"Laxmi Devi","email":"laxmi@village.com","balance_cents":"0",...}
]
```

**What this means:**
Cashier opened the full register and read every page. Returns all accounts ordered by id.

---

## Test 8a — Fetch One Account (Exists)

```bash
curl http://localhost:8081/accounts/1
```

**Response:**
```json
{"id":1,"owner_name":"Venkatesh Reddy","email":"venkatesh@village.com","balance_cents":"0",...}
```

---

## Test 8b — Fetch One Account (Does Not Exist)

```bash
curl http://localhost:8081/accounts/999
```

**Response:**
```json
{"error":"not found"}
```

**What this means:**
Page 999 doesn't exist in the register. Cashier returns 404 — "aa account ledu maaku."

---

## Test 9 — Deposit ₹5000 (Credit)

```bash
curl -X POST http://localhost:8081/accounts/1/credit \
  -H "Content-Type: application/json" \
  -d '{"amount_cents":500000}'
```

**Response:**
```json
{"id":1,"owner_name":"Venkatesh Reddy","balance_cents":"500000",...}
```

**What this means:**
500000 paise = ₹5000 added. Rythu Bandhu money credited.
Simple `UPDATE ... SET balance = balance + amount`. No lock needed for deposits.

---

## Test 10 — Withdraw ₹2000 (Debit — Success)

```bash
curl -X POST http://localhost:8081/accounts/1/debit \
  -H "Content-Type: application/json" \
  -d '{"amount_cents":200000}'
```

**Response:**
```json
{"id":1,"owner_name":"Venkatesh Reddy","balance_cents":"300000",...}
```

**What this means:**
Had ₹5000. Withdrew ₹2000. Now ₹3000 left (300000 paise).

Behind the scenes the code did:
1. `BEGIN` — locked the register page
2. `SELECT FOR UPDATE` — read balance (500000), locked it
3. 500000 ≥ 200000 → enough money
4. `UPDATE` — balance = 500000 - 200000 = 300000
5. `COMMIT` — write final value, release lock

---

## Test 11 — Withdraw More Than Balance (Should Fail)

```bash
curl -X POST http://localhost:8081/accounts/1/debit \
  -H "Content-Type: application/json" \
  -d '{"amount_cents":999999999}'
```

**Response:**
```json
{"error":"insufficient funds"}
```

**What this means:**
Had ₹3000. Tried to withdraw ₹9,99,999.
Code did:
1. `BEGIN` — locked the page
2. `SELECT FOR UPDATE` — read balance (300000)
3. 300000 < 999999999 → not enough
4. `ROLLBACK` — cancelled everything, released lock
5. Returned 409 — "paisa ledu anna"

---

## Test 12 — Negative Amount (Should Fail)

```bash
curl -X POST http://localhost:8081/accounts/1/debit \
  -H "Content-Type: application/json" \
  -d '{"amount_cents":-500}'
```

**Response:**
```json
{"error":"amount_cents must be a positive number"}
```

**What this means:**
Input validation again — caught before even opening the register.
`Number.isFinite(amount) && amount > 0` — negative and zero amounts are rejected.

---

## Final State After All Tests

| Account | Owner | Balance |
|---|---|---|
| 1 | Venkatesh Reddy | ₹3,000 (300000 paise) |
| 2 | Laxmi Devi | ₹0 (no deposits made) |

---

## All 6 Endpoints Summary

| Endpoint | Method | What It Does | Village Analogy |
|---|---|---|---|
| `/healthz` | GET | Is service alive? | "OPEN" board outside |
| `/readyz` | GET | Is DB connected? | Cashier + almiraah both ready |
| `/accounts` | POST | Create account | Open new khata |
| `/accounts` | GET | List all accounts | Read full register |
| `/accounts/:id` | GET | Get one account | Read one page |
| `/accounts/:id/credit` | POST | Add money | Deposit (no lock needed) |
| `/accounts/:id/debit` | POST | Remove money | Withdraw (lock + check) |

---

## How to Stop

```bash
docker compose down
```

To also delete the database data (start fresh):
```bash
docker compose down -v
```
docker compose ps
docker compose volumes

