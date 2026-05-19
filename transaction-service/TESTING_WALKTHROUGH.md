# Transaction-Service — Live Testing Walkthrough

## Setup

**What was running:**
- `postgres` container — the almiraah (database)
- `account-service` container — the Accountant at the bank counter
- `notification-service` container — the Announcer/Peon who logs SMS alerts
- `transaction-service` container — the Hawala Agent (this service)

**Port mapping:**
- `http://localhost:8082` → transaction-service (port 8080 inside)
- `http://localhost:8081` → account-service (port 8080 inside)
- `http://localhost:8083` → notification-service (port 8080 inside)

**How to start (all 4 services together):**
```bash
docker compose up -d --build postgres account-service notification-service transaction-service
```

**How to check logs:**
```bash
docker compose logs -f transaction-service
docker compose logs -f notification-service
```

Expected startup logs:
```
transaction-service-1  | transaction-service listening on 8080
notification-service-1 | notification-service listening on 8080
```

---

## Key Difference From account-service Tests

In account-service tests, we tested ONE service talking to its database.

Here, we are testing a **chain of three services**:
```
Our curl → transaction-service → account-service → postgres
                              → notification-service (after every outcome)
```

Every test will verify BOTH the transaction-service response AND the side effects on account-service balances and notification logs.

---

## Test 1 — Is the Agent's Shop Open? (`/healthz`)

```bash
curl http://localhost:8082/healthz
```

**Response:**
```json
{"status":"ok"}
```

**What this means:**
Hawala Agent's shop board says "OPEN". Service process is alive.

---

## Test 2 — Is the Agent Ready to Work? (`/readyz`)

```bash
curl http://localhost:8082/readyz
```

**Response:**
```json
{"status":"ready"}
```

**What this means:**
Agent is sitting at his desk, ready to take transfer instructions.

Notice: NO database check here (unlike account-service). This service has no database. Ready = process is running = ready.

---

## Test 3 — Setup: Create Two Village Accounts (via account-service)

Before testing transfers, we need two accounts. We call account-service directly for this.

```bash
# Account 1 — Venkatesh (Sender)
curl -X POST http://localhost:8081/accounts \
  -H "Content-Type: application/json" \
  -d '{"owner_name":"Venkatesh Reddy","email":"venkatesh@village.com"}'
```

**Response:**
```json
{"id":1,"owner_name":"Venkatesh Reddy","email":"venkatesh@village.com","balance_cents":"0","created_at":"2026-05-10T10:29:22.984Z"}
```

```bash
# Account 2 — Laxmi (Receiver)
curl -X POST http://localhost:8081/accounts \
  -H "Content-Type: application/json" \
  -d '{"owner_name":"Laxmi Devi","email":"laxmi@village.com"}'
```

**Response:**
```json
{"id":2,"owner_name":"Laxmi Devi","email":"laxmi@village.com","balance_cents":"0","created_at":"2026-05-10T10:29:23.629Z"}
```

Both accounts at zero balance. Khata opened. Now we use the Hawala Agent for everything else.

---

## Test 4 — Deposit ₹10,000 into Venkatesh's Account (`/transactions/deposit`)

```bash
curl -X POST http://localhost:8082/transactions/deposit \
  -H "Content-Type: application/json" \
  -d '{"account_id":1,"amount_cents":1000000}'
```

**Response:**
```json
{"status":"completed","account_id":1,"amount_cents":1000000}
```

**Verify the balance directly on account-service:**
```bash
curl http://localhost:8081/accounts/1
```

```json
{"id":1,"owner_name":"Venkatesh Reddy","balance_cents":"1000000",...}
```

**What happened behind the scenes:**
1. transaction-service received the deposit request
2. Called account-service: `POST /accounts/1/credit` with `{amount_cents: 1000000}`
3. account-service updated PostgreSQL balance: 0 → 1000000
4. transaction-service called publisher.js: `publish({ type: "transaction.completed", kind: "deposit" })`
5. publisher.js HTTP POST'd the event to notification-service `/events`
6. notification-service logged: `[NOTIFY] OK {...}`

**Village analogy:** Rythu Bandhu money arrived. The Agent (transaction-service) told the Accountant (account-service) to credit Venkatesh's page in the register. Then the Peon (notification-service) got the "success SMS" chit.

---

## Test 5 — Transfer ₹3,000 from Venkatesh to Laxmi (`/transactions/transfer`)

```bash
curl -X POST http://localhost:8082/transactions/transfer \
  -H "Content-Type: application/json" \
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
  "at": "2026-05-10T10:29:39.563Z"
}
```

**Verify both balances:**
```bash
curl http://localhost:8081/accounts/1   # Venkatesh: 1000000 - 300000 = 700000
curl http://localhost:8081/accounts/2   # Laxmi:    0 + 300000 = 300000
```

```json
{"id":1,"balance_cents":"700000",...}
{"id":2,"balance_cents":"300000",...}
```

**What happened behind the scenes (SAGA):**
1. Validate: both IDs present, amount positive, not same account ✅
2. `callAccount(/accounts/1/debit, {300000})` → account-service: 1000000 - 300000 = 700000 ✅
3. `callAccount(/accounts/2/credit, {300000})` → account-service: 0 + 300000 = 300000 ✅
4. `publish({ type: "transaction.completed" })` → notification-service logs `[NOTIFY] OK`

**Village analogy:** Venkatesh nundi ₹3000 teesuko, Laxmi ki ivvu. Both steps worked. Agent announces "transfer complete."

---

## Test 6 — Check Notification Log (Publisher Proof)

```bash
curl http://localhost:8083/notifications
```

**Response (newest first):**
```json
[
  {
    "received_at": "2026-05-10T10:29:39.571Z",
    "event": {"type":"transaction.completed","from_account_id":1,"to_account_id":2,"amount_cents":300000,"at":"..."},
    "source": "http"
  },
  {
    "received_at": "2026-05-10T10:29:28.374Z",
    "event": {"type":"transaction.completed","account_id":1,"amount_cents":1000000,"kind":"deposit","at":"..."},
    "source": "http"
  }
]
```

**What this proves:**
- `source: "http"` → publisher.js used the local docker-compose path (no `PUBSUB_TOPIC_ID` set)
- Both events arrived — deposit event and transfer event
- notification-service is storing last 100 events in memory (`recent` array)

---

## Test 7 — Insufficient Funds Transfer (Saga — Debit Fails)

Venkatesh has ₹7,000. Try to transfer ₹9,99,999.

```bash
curl -X POST http://localhost:8082/transactions/transfer \
  -H "Content-Type: application/json" \
  -d '{"from_account_id":1,"to_account_id":2,"amount_cents":999999999}'
```

**Response:**
```json
{"error":"insufficient funds"}
```

**Verify Venkatesh's balance is UNCHANGED:**
```bash
curl http://localhost:8081/accounts/1
```
```json
{"balance_cents":"700000",...}
```

**What happened:**
1. `callAccount(/accounts/1/debit, {999999999})` → account-service said "paisa ledu" (insufficient funds) → 409
2. Since debit failed, credit step was NEVER called — nothing to reverse
3. `publish({ type: "transaction.failed", reason: "insufficient funds" })` → notification-service logs `[NOTIFY] FAIL`

**Village analogy:** Agent tries to take ₹9,99,999 from Venkatesh. Accountant says "arey, aavadu ledandi" (sir, that much money doesn't exist). Agent returns empty-handed. Nothing happened to anyone's balance.

---

## Test 8 — Transfer to Non-Existent Account (Saga — COMPENSATING TRANSACTION)

This is the most important test. Debit succeeds, then credit fails — watch the auto-refund.

```bash
curl -X POST http://localhost:8082/transactions/transfer \
  -H "Content-Type: application/json" \
  -d '{"from_account_id":1,"to_account_id":999,"amount_cents":100000}'
```

**Response:**
```json
{"error":"not found"}
```

**Verify Venkatesh's balance — should be EXACTLY same as before (700000):**
```bash
curl http://localhost:8081/accounts/1
```
```json
{"balance_cents":"700000",...}
```

**What happened step by step (SAGA in action):**
```
Step 1: callAccount(/accounts/1/debit, {100000})
        → account-service: 700000 - 100000 = 600000 ✅ (debit succeeded!)
        Venkatesh temporarily has only ₹6,000

Step 2: callAccount(/accounts/999/credit, {100000})
        → account-service: account 999 doesn't exist → 404 ❌ (credit failed!)

Step 3: COMPENSATING TRANSACTION — AUTO REFUND
        callAccount(/accounts/1/credit, {100000})
        → account-service: 600000 + 100000 = 700000 ✅ (money returned!)
        Venkatesh is back to ₹7,000

Step 4: publish({ type: "transaction.failed", reason: "not found" })
        → notification-service: [NOTIFY] FAIL not found
```

**Village analogy:** Venkatesh sent ₹1000 via Hawala Agent for account 999. Agent debited Venkatesh. Then found out account 999 doesn't exist. Agent IMMEDIATELY returned ₹1000 to Venkatesh. Sent failure SMS. Total time: milliseconds. Venkatesh lost nothing.

---

## Test 9 — Same Account Transfer (Input Validation)

```bash
curl -X POST http://localhost:8082/transactions/transfer \
  -H "Content-Type: application/json" \
  -d '{"from_account_id":1,"to_account_id":1,"amount_cents":100000}'
```

**Response:**
```json
{"error":"cannot transfer to same account"}
```

**What this means:**
Caught at input validation — before ANY calls to account-service. Like the Agent saying "oka khata nundi same khata ki? Adi possible kadu" (from one account to same account? That's not possible).

---

## Test 10 — Missing Fields (Input Validation)

```bash
curl -X POST http://localhost:8082/transactions/transfer \
  -H "Content-Type: application/json" \
  -d '{"from_account_id":1,"amount_cents":100000}'
```

**Response:**
```json
{"error":"from_account_id, to_account_id, and positive amount_cents required"}
```

---

## Test 11 — Negative Amount (Input Validation)

```bash
curl -X POST http://localhost:8082/transactions/transfer \
  -H "Content-Type: application/json" \
  -d '{"from_account_id":1,"to_account_id":2,"amount_cents":-5000}'
```

**Response:**
```json
{"error":"from_account_id, to_account_id, and positive amount_cents required"}
```

---

## Test 12 — Deposit to Non-Existent Account

```bash
curl -X POST http://localhost:8082/transactions/deposit \
  -H "Content-Type: application/json" \
  -d '{"account_id":999,"amount_cents":50000}'
```

**Response:**
```json
{"error":"not found"}
```

No compensating transaction needed here — only one step (credit), so either it works or it doesn't.

---

## Final Notification Log — All Events

```bash
curl http://localhost:8083/notifications
```

All 4 events appear (newest first):
```
[NOTIFY] FAIL not found          ← Test 8: compensating transaction
[NOTIFY] FAIL insufficient funds ← Test 7: debit rejected
[NOTIFY] OK   transfer completed ← Test 5: Venkatesh → Laxmi
[NOTIFY] OK   deposit completed  ← Test 4: Rythu Bandhu deposit
```

**Note:** Tests 9, 10, 11, 12 produced NO events — they were caught by input validation BEFORE any service calls were made, so the publisher was never invoked.

---

## Notification-Service Logs

```bash
docker compose logs notification-service
```

```
notification-service-1 | notification-service listening on 8080
notification-service-1 | [NOTIFY] OK   {"type":"transaction.completed","account_id":1,"amount_cents":1000000,"kind":"deposit",...}
notification-service-1 | [NOTIFY] OK   {"type":"transaction.completed","from_account_id":1,"to_account_id":2,"amount_cents":300000,...}
notification-service-1 | [NOTIFY] FAIL insufficient funds {...}
notification-service-1 | [NOTIFY] FAIL not found {...}
```

---

## Final State After All Tests

| Account | Owner | Starting Balance | After Deposit | After Transfer | Final |
|---|---|---|---|---|---|
| 1 | Venkatesh Reddy | ₹0 | ₹10,000 | ₹7,000 | **₹7,000** |
| 2 | Laxmi Devi | ₹0 | ₹0 | ₹3,000 | **₹3,000** |

Total money in system: ₹10,000 (conservation — nothing lost, nothing created).

---

## All Endpoints Summary

| Endpoint | Method | What It Does | Village Analogy |
|---|---|---|---|
| `/healthz` | GET | Is service alive? | Agent's shop open board |
| `/readyz` | GET | Is service ready? | Agent sitting at desk |
| `/transactions/deposit` | POST | Credit one account (no sender) | Rythu Bandhu / government deposit |
| `/transactions/transfer` | POST | Move money between two accounts | Hawala transfer with auto-refund |

---

## How to Stop

```bash
docker compose down
```

To also delete all database data:
```bash
docker compose down -v
```
