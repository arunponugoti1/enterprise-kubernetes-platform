# Account-Service — Do It Yourself: Database + Testing Guide

This guide teaches you how to:
1. Start the service fresh
2. Connect to the database and see the register (like sitting behind the bank counter)
3. Run each test yourself and observe what changes in the database live

---

## Part 1 — Start Everything Fresh

### Step 1: Go to the project root folder
```bash
cd D:\Downloads_Cdrive\GKEcloud\enterprise-kubernetes-platform
```

### Step 2: Stop and wipe everything (clean slate)
```bash
docker compose down -v
```
> `-v` deletes the database volume too. All previous accounts are gone.
> This is like burning the old register and starting a new one.

### Step 3: Start only postgres + account-service
```bash
docker compose up -d --build postgres account-service
```

### Step 4: Wait ~5 seconds, then confirm both are running
```bash
docker ps
```

**What to observe:**
```
NAMES                                              STATUS        PORTS
enterprise-kubernetes-platform-account-service-1   Up X seconds  0.0.0.0:8081->8080/tcp
enterprise-kubernetes-platform-postgres-1          Up X seconds  0.0.0.0:5432->5432/tcp
```
Both should say **Up** and **healthy**. If account-service says "Restarting" — wait 10 more seconds and run `docker ps` again.

### Step 5: Check the startup log
```bash
docker compose logs account-service
```

**What to observe:**
```
account-service-1 | account-service listening on 8080
```
This means the cashier opened for business.

---

## Part 2 — Connect to the Database (Sit Behind the Counter)

Open a **second terminal** and keep this open the whole time.
This is your "behind the counter" view — you see the register as it changes.

### Connect to PostgreSQL inside the container:
```bash
docker exec -it enterprise-kubernetes-platform-postgres-1 psql -U fintech -d fintech
```

You will see this prompt:
```
fintech=#
```
This means you are now **inside the database**. You are the bank manager looking at the register.

---

## Part 3 — Useful Database Commands (Learn These)

Run these inside the `fintech=#` prompt:

### See all tables in the database
```sql
\dt
```
**What to observe:** You should see one table called `accounts`.

### See the structure of the accounts table (the register page format)
```sql
\d accounts
```
**What to observe:** All columns — id, owner_name, email, balance_cents, created_at. This is the format of every page in the register.

### See all accounts (the full register)
```sql
SELECT * FROM accounts;
```
**What to observe:** All rows. Right now — empty table, "0 rows".

### See account balances nicely (convert paise to rupees)
```sql
SELECT id, owner_name, balance_cents, balance_cents / 100.0 AS balance_rupees FROM accounts;
```
**What to observe:** balance_cents column shows raw paise, balance_rupees shows readable rupees.

### Count how many accounts exist
```sql
SELECT COUNT(*) FROM accounts;
```

### Exit the database when done
```sql
\q
```

---

## Part 4 — Test Every Endpoint Yourself

Keep **two terminals open**:
- **Terminal A** — for `curl` commands (the customer side)
- **Terminal B** — for `psql` database commands (the bank manager side)

---

### TEST 1 — Is the service alive? (`/healthz`)

**Terminal A — run:**
```bash
curl http://localhost:8081/healthz
```

**Expected response:**
```json
{"status":"ok"}
```

**Terminal B — run:**
```sql
SELECT COUNT(*) FROM accounts;
```

**What to observe:**
- API says "ok" — service is running
- Database shows 0 rows — nothing has changed yet
- This endpoint never touches the database at all

---

### TEST 2 — Is database connected? (`/readyz`)

**Terminal A — run:**
```bash
curl http://localhost:8081/readyz
```

**Expected response:**
```json
{"status":"ready"}
```

**Terminal B — run:**
```sql
SELECT COUNT(*) FROM accounts;
```

**What to observe:**
- API says "ready" — the service successfully ran `SELECT 1` on the database behind the scenes
- If you stop postgres and run this again, you will see `{"status":"not-ready"}` — try it!

---

### TEST 3 — Create Account for Venkatesh

**Terminal A — run:**
```bash
curl -X POST http://localhost:8081/accounts -H "Content-Type: application/json" -d "{\"owner_name\":\"Venkatesh Reddy\",\"email\":\"venkatesh@mandal.com\"}"
```

**Expected response:**
```json
{"id":1,"owner_name":"Venkatesh Reddy","email":"venkatesh@mandal.com","balance_cents":"0","created_at":"..."}
```

**Terminal B — immediately run:**
```sql
SELECT * FROM accounts;
```

**What to observe:**
- One new row appeared in the database
- `id` is 1 — auto-assigned by PostgreSQL (SERIAL)
- `balance_cents` is 0 — starts with zero money
- `created_at` is the exact time the row was written
- The API response and the database row are **identical** — the code returned exactly what it wrote

---

### TEST 4 — Create Account for Laxmi

**Terminal A — run:**
```bash
curl -X POST http://localhost:8081/accounts -H "Content-Type: application/json" -d "{\"owner_name\":\"Laxmi Devi\",\"email\":\"laxmi@mandal.com\"}"
```

**Expected response:**
```json
{"id":2,"owner_name":"Laxmi Devi","email":"laxmi@mandal.com","balance_cents":"0","created_at":"..."}
```

**Terminal B — run:**
```sql
SELECT * FROM accounts;
```

**What to observe:**
- Now 2 rows in the table
- Laxmi got `id: 2` automatically — PostgreSQL increments it on its own
- Both balances are 0

---

### TEST 5 — Try Creating With Same Email (Duplicate)

**Terminal A — run:**
```bash
curl -X POST http://localhost:8081/accounts -H "Content-Type: application/json" -d "{\"owner_name\":\"Another Venkatesh\",\"email\":\"venkatesh@mandal.com\"}"
```

**Expected response:**
```json
{"error":"email already exists"}
```

**Terminal B — run:**
```sql
SELECT COUNT(*) FROM accounts;
```

**What to observe:**
- Count is still **2** — database was NOT changed
- The API returned an error before writing anything
- PostgreSQL threw error code `23505` (unique constraint) and the code caught it
- This protects your data — one email = one account, no duplicates

---

### TEST 6 — Try Creating Without Email (Missing Field)

**Terminal A — run:**
```bash
curl -X POST http://localhost:8081/accounts -H "Content-Type: application/json" -d "{\"owner_name\":\"Incomplete Person\"}"
```

**Expected response:**
```json
{"error":"owner_name and email are required"}
```

**Terminal B — run:**
```sql
SELECT COUNT(*) FROM accounts;
```

**What to observe:**
- Count still **2** — this error was caught BEFORE even trying to write to database
- The cashier checked the form first, rejected it, never opened the almiraah
- This is called "input validation" — first line of defence

---

### TEST 7 — List All Accounts

**Terminal A — run:**
```bash
curl http://localhost:8081/accounts
```

**Expected response:**
```json
[
  {"id":1,"owner_name":"Venkatesh Reddy",...},
  {"id":2,"owner_name":"Laxmi Devi",...}
]
```

**Terminal B — run:**
```sql
SELECT id, owner_name FROM accounts ORDER BY id;
```

**What to observe:**
- API response and database rows are the same data
- ORDER BY id means same order every time — predictable, not random

---

### TEST 8 — Fetch One Account (Exists)

**Terminal A — run:**
```bash
curl http://localhost:8081/accounts/1
```

**Expected response:**
```json
{"id":1,"owner_name":"Venkatesh Reddy","email":"venkatesh@mandal.com","balance_cents":"0",...}
```

**Terminal B — run:**
```sql
SELECT * FROM accounts WHERE id = 1;
```

**What to observe:**
- Same data, same row. The API is just a window into the database.

---

### TEST 9 — Fetch Account That Does Not Exist

**Terminal A — run:**
```bash
curl http://localhost:8081/accounts/999
```

**Expected response:**
```json
{"error":"not found"}
```

**Terminal B — run:**
```sql
SELECT * FROM accounts WHERE id = 999;
```

**What to observe:**
- Database returns **0 rows**
- The API saw 0 rows and returned 404 — "not found"
- `rows.length === 0` is the check in the code

---

### TEST 10 — Deposit ₹5000 into Venkatesh's Account (Credit)

**Terminal B — BEFORE running — check balance:**
```sql
SELECT id, owner_name, balance_cents FROM accounts WHERE id = 1;
```
Note the balance: `0`

**Terminal A — run:**
```bash
curl -X POST http://localhost:8081/accounts/1/credit -H "Content-Type: application/json" -d "{\"amount_cents\":500000}"
```

**Expected response:**
```json
{"id":1,"owner_name":"Venkatesh Reddy","balance_cents":"500000",...}
```

**Terminal B — AFTER running — check balance:**
```sql
SELECT id, owner_name, balance_cents, balance_cents / 100.0 AS rupees FROM accounts WHERE id = 1;
```

**What to observe:**
- Before: `balance_cents = 0`
- After: `balance_cents = 500000` (₹5000)
- The `UPDATE ... SET balance_cents = balance_cents + 500000` ran on the database
- No lock was needed — crediting money is always safe

---

### TEST 11 — Withdraw ₹2000 from Venkatesh (Debit — Success)

**Terminal B — BEFORE running:**
```sql
SELECT id, owner_name, balance_cents, balance_cents / 100.0 AS rupees FROM accounts WHERE id = 1;
```
Note the balance: `500000 paise (₹5000)`

**Terminal A — run:**
```bash
curl -X POST http://localhost:8081/accounts/1/debit -H "Content-Type: application/json" -d "{\"amount_cents\":200000}"
```

**Expected response:**
```json
{"id":1,"owner_name":"Venkatesh Reddy","balance_cents":"300000",...}
```

**Terminal B — AFTER running:**
```sql
SELECT id, owner_name, balance_cents, balance_cents / 100.0 AS rupees FROM accounts WHERE id = 1;
```

**What to observe:**
- Before: `500000 paise (₹5000)`
- After: `300000 paise (₹3000)`
- ₹2000 was deducted safely using BEGIN → SELECT FOR UPDATE → UPDATE → COMMIT
- The database shows the final committed value only — you cannot see the intermediate locked state from outside

---

### TEST 12 — Try to Withdraw More Than Balance (Insufficient Funds)

**Terminal B — BEFORE running:**
```sql
SELECT balance_cents FROM accounts WHERE id = 1;
```
Note: `300000`

**Terminal A — run:**
```bash
curl -X POST http://localhost:8081/accounts/1/debit -H "Content-Type: application/json" -d "{\"amount_cents\":999999999}"
```

**Expected response:**
```json
{"error":"insufficient funds"}
```

**Terminal B — AFTER running:**
```sql
SELECT balance_cents FROM accounts WHERE id = 1;
```

**What to observe:**
- Balance is STILL `300000` — nothing changed
- The ROLLBACK cancelled the transaction before any write happened
- This is the most important safety in the whole service — money can never go negative

---

### TEST 13 — Try Negative Amount (Bad Input)

**Terminal A — run:**
```bash
curl -X POST http://localhost:8081/accounts/1/debit -H "Content-Type: application/json" -d "{\"amount_cents\":-500}"
```

**Expected response:**
```json
{"error":"amount_cents must be a positive number"}
```

**Terminal B — run:**
```sql
SELECT balance_cents FROM accounts WHERE id = 1;
```

**What to observe:**
- Balance unchanged
- This error was caught by `if (!Number.isFinite(amount) || amount <= 0)` — before database was touched
- Two layers of protection: input validation first, then balance check in DB

---

## Part 5 — Advanced: Watch the Database Live

Open a **third terminal** and run this to watch all changes as they happen:

```bash
docker exec -it enterprise-kubernetes-platform-postgres-1 psql -U fintech -d fintech -c "SELECT * FROM accounts;"
```

Or watch just the balances:
```bash
docker exec enterprise-kubernetes-platform-postgres-1 psql -U fintech -d fintech -c "SELECT id, owner_name, balance_cents / 100.0 AS rupees FROM accounts ORDER BY id;"
```

Run this command after every curl test to see the register update in real time.

---

## Part 6 — See the Logs While Testing

In another terminal, stream the logs:
```bash
docker compose logs -f account-service
```

**What to observe:**
- Every request the service receives is logged
- You can see errors if something goes wrong
- The `DB init failed (attempt X)` message appears if postgres is slow to start

---

## Part 7 — Final State Check

After all 13 tests, run this in Terminal B:

```sql
SELECT id, owner_name, email, balance_cents, balance_cents / 100.0 AS rupees FROM accounts ORDER BY id;
```

**Expected final state:**
```
 id |   owner_name    |         email         | balance_cents | rupees
----+-----------------+-----------------------+---------------+--------
  1 | Venkatesh Reddy | venkatesh@mandal.com  |        300000 |   3000
  2 | Laxmi Devi      | laxmi@mandal.com      |             0 |      0
```

---

## Part 8 — How to Stop

```bash
# Stop containers but keep database data
docker compose down

# Stop containers AND delete all database data (fresh start next time)
docker compose down -v
```

---

## Quick Reference — All Commands

### Start
```bash
docker compose up -d --build postgres account-service
```

### Connect to DB
```bash
docker exec -it enterprise-kubernetes-platform-postgres-1 psql -U fintech -d fintech
```

### View register (inside psql)
```sql
SELECT id, owner_name, balance_cents / 100.0 AS rupees FROM accounts ORDER BY id;
```

### All API tests
```bash
# Health
curl http://localhost:8081/healthz
curl http://localhost:8081/readyz

# Accounts
curl -X POST http://localhost:8081/accounts -H "Content-Type: application/json" -d "{\"owner_name\":\"YOUR NAME\",\"email\":\"your@email.com\"}"
curl http://localhost:8081/accounts
curl http://localhost:8081/accounts/1

# Money
curl -X POST http://localhost:8081/accounts/1/credit -H "Content-Type: application/json" -d "{\"amount_cents\":500000}"
curl -X POST http://localhost:8081/accounts/1/debit  -H "Content-Type: application/json" -d "{\"amount_cents\":200000}"
```

### Stop
```bash
docker compose down -v
```
