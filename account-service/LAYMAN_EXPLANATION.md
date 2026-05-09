# Account-Service — Explained Like a Telangana Village Bank

## The Big Picture

Imagine a **Telangana Grameena Vikas Bank** in your mandal.

This bank:
- Opens new accounts for farmers and villagers
- Keeps their balance in a pattadar passbook style register
- Accepts deposits (like Rythu Bandhu money coming in)
- Allows withdrawals — but only if balance is enough
- Has a big **ledger register** locked in a steel almiraah behind the counter

**The `account-service` IS that village bank. Written in code.**

---

## File 1: `src/db.js` — The Register Almiraah (Ledger)

```javascript
const pool = new Pool({
  host: 'postgres',
  user: 'fintech',
  password: 'fintech',
  database: 'fintech',
});
```

This is the **key to the steel almiraah** where the bank keeps all ledger registers.

| Code | Village Meaning |
|---|---|
| `host: 'postgres'` | Which building/room the almiraah is in |
| `user / password` | The key to open it |
| `database` | Which register inside (savings, loans...) |

```javascript
CREATE TABLE IF NOT EXISTS accounts (
  id            SERIAL PRIMARY KEY,
  owner_name    TEXT NOT NULL,
  email         TEXT UNIQUE NOT NULL,
  balance_cents BIGINT NOT NULL DEFAULT 0,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
)
```

This defines the **format of one page** in the register — like a pattadar passbook page:

| Column | Real Life Meaning |
|---|---|
| `id` | Khata number (101, 102, 103...) |
| `owner_name` | Farmer's name (Venkatesh, Laxmi...) |
| `email` | Aadhaar-linked contact — unique, no two people same |
| `balance_cents` | Balance in paise (not rupees — avoids rounding mistakes) |
| `created_at` | Date the account was opened |

> **Why paise instead of rupees?**
> Computers are bad at decimal math. ₹10.10 + ₹0.10 can give ₹10.199999 in code.
> Storing everything in whole paise (1000 paise = ₹10) avoids this problem entirely.

---

## File 2: `src/index.js` — The Bank Cashier

This file is the **counter employee** — the person sitting behind the glass.
When someone comes, he reads the request and decides what to do.

---

### Counter 1: Is Bank Open? — `GET /healthz`

```javascript
app.get('/healthz', (_req, res) => res.json({ status: 'ok' }));
```

Like the **"OPEN" board** hung outside the bank door.

Anyone can ask: "Anna, bank pani chestundaa?" — Answer: `{ status: 'ok' }`.
No register checking. Just — "yes we are running."

---

### Counter 2: Is Cashier AND Register Ready? — `GET /readyz`

```javascript
await pool.query('SELECT 1');
```

Different from the open board. This checks — **"cashier is sitting AND the almiraah key is working?"**

Like when the bank opens at 10am but the manager forgot the cupboard key.
Board says OPEN but no actual work can happen yet.

- Register reachable → `{ status: 'ready' }` — send customers in
- Register down → `{ status: 'not-ready' }` — Kubernetes waits, sends no traffic

---

### Counter 3: Open a New Account — `POST /accounts`

```javascript
const { owner_name, email } = req.body;
pool.query('INSERT INTO accounts (owner_name, email) VALUES ($1, $2)')
```

A farmer walks in: **"Anna, naaku account open cheyyandi."**

Cashier asks for name and email.

| Situation | What Happens | Error Code |
|---|---|---|
| Name or email missing | "Poori details teesko randi" | 400 |
| Email already registered | "Ee Aadhaar ki account already undi" | 409 |
| Everything fine | Writes in register, returns khata number | 201 |

---

### Counter 4: Check Someone's Account — `GET /accounts/:id`

```javascript
pool.query('SELECT * FROM accounts WHERE id = $1')
```

"Khata number 7 wadi balance chupiyyi." Cashier opens register, finds page 7, reads it.

- Page found → shows full details
- Page not found → `{ error: 'not found' }` — "aa account ledu maaku"

---

### Counter 5: Deposit Money — `POST /accounts/:id/credit`

```javascript
UPDATE accounts SET balance_cents = balance_cents + $1 WHERE id = $2
```

**Rythu Bandhu money came in. Add to account.**

Cashier opens register and adds the amount. Simple — no extra safety checks needed.
Adding money can never cause a problem.

---

### Counter 6: Withdraw Money — `POST /accounts/:id/debit`

This is the **most careful operation.** It happens in 4 locked steps.

```javascript
await client.query('BEGIN');                              // Step 1: Lock the page
const { rows } = await client.query(
  'SELECT balance_cents FROM accounts WHERE id = $1 FOR UPDATE'  // Step 2: Check balance
);
if (rows[0].balance_cents < amount) {
  await client.query('ROLLBACK');                        // Step 3a: Not enough — unlock, reject
  return res.status(409).json({ error: 'insufficient funds' });
}
await client.query('UPDATE accounts SET balance_cents = balance_cents - $1 ...');
await client.query('COMMIT');                            // Step 3b: Enough — deduct, unlock
```

**Why so careful? — The Twin ATM Problem:**

> Raju and Sujatha both go to ATM at the same time from two different villages.
> Account has only ₹1000. Both try to withdraw ₹1000 at the exact same moment.
> Without a lock — both succeed and the bank loses ₹1000.

`FOR UPDATE` puts a **token** on that register page:
"Nenu ee page chustunaanu — meeru wait cheyyandi."

| Step | Code | Village Analogy |
|---|---|---|
| 1 | `BEGIN` | Cashier puts token on register page |
| 2 | `SELECT FOR UPDATE` | Check balance, nobody else can touch this page |
| 3a | `ROLLBACK` | Balance not enough — remove token, send back |
| 3b | `COMMIT` | Deduct amount, write new balance, remove token |

---

## File 3: `Dockerfile` — Blueprint to Build the Bank Branch

```dockerfile
FROM node:20-alpine AS deps    # Stage 1: Workshop
COPY package.json ./
RUN npm install --omit=dev     # Install all tools

FROM node:20-alpine            # Stage 2: Clean delivery room
COPY --from=deps /app/node_modules  # Bring only finished goods
USER node                      # Cashier ≠ Bank Manager
EXPOSE 8080                    # Open window number 8080
CMD ["node", "src/index.js"]   # Start working
```

This is a **PWD blueprint** — build this exact bank branch anywhere in the world.

**Why 2 stages?**
Like a carpenter who builds furniture in his workshop (tools, sawdust, mess)
but delivers only the clean finished furniture to your house.
Final image has no build tools — smaller, safer, faster.

**Why `USER node`?**
The cashier is not the bank manager.
If a thief tricks the cashier, he cannot access the manager's vault.
Limited permissions = less damage if something goes wrong.

---

## Full Flow — How Everything Connects

```
Farmer (You / API caller)
         ↓
    Counter — index.js (cashier)
         ↓
    Almiraah key — db.js (connection)
         ↓
    Register — PostgreSQL (accounts table)
```

1. Farmer walks in → Cashier (index.js) listens
2. Cashier uses almiraah key (db.js) to open the cupboard
3. Reads or writes in the register (PostgreSQL)
4. Tells the farmer the result

---

## One Line — Explain to Anyone

> "Account-service is a digital village bank.
> `db.js` is the almiraah key.
> `index.js` is the smart cashier who makes depositing easy and withdrawing safe using a page lock.
> `Dockerfile` is the PWD blueprint to build this bank anywhere in the world."
