
# Project Learning Journal

## Context & Goals
- **Mission:** Transition from Support to Platform/DevOps Engineer by rebuilding and understanding 100% of this project.
- **Methodology:** 6-Phase approach (App -> Infra -> CI -> GitOps -> Mesh -> Ops).
- **Update Frequency:** The journal MUST be updated at the end of every phase to capture takeaways, doubts resolved, and current state.
- **Session Protocol:** Every time a new session starts, the FIRST action must be to read this `JOURNAL.md` file to re-establish context and goals.
- **Core Strategy:** Focus on "The Three Questions": Contract, Failure Mode, and Portability.

---

## 2026-05-06: Phase 1 - Application & Containerization
### Progress
- Analyzed `account-service` code (`index.js`).
- Identified enterprise patterns: Liveness/Readiness probes, DB retries, and transactional safety (debit logic).
- Dissected `Dockerfile`: Learned about multi-stage builds, non-root users, and image efficiency.
- Clarified PostgreSQL setup: Using official `postgres:16-alpine` image via `docker-compose`.

### Doubts & Breakthroughs
- **Doubt:** Where does the PostgreSQL "code" live?
- **Breakthrough:** Realized that in DevOps, we often pull trusted, managed images rather than writing database code from scratch.
- **Breakthrough:** Understood that `db.js` acts as the bridge/handshake between the container and the data.

### Next Steps
- Run `docker-compose up -d --build postgres account-service` to verify the local handshake.
- Test the endpoints using `curl` to see the database schema creation in action.

### Completion of account service
- we have successfully understood and executed account service with 13 test cases , we have verified logs too
- we have added the files created those test validation and implementation files under the account service
- **2026-05-10:** Confirmed all 13 tests pass end-to-end following the DATABASE_TESTING.md walkthrough (health, readiness, CRUD, credit, debit, edge cases). Phase 1 — account-service — is DONE.

### 2026-05-10: transaction-service — Code Understanding Complete
Created `transaction-service/UNDERSTANDING.md` with full layman breakdown.

Key breakthroughs:
- **Why two files:** `index.js` = orchestrator (Hawala Agent brain), `publisher.js` = smart messenger (knows local HTTP vs GCP Pub/Sub)
- **Startup order:** `index.js` starts first, loads `publisher.js` silently at startup. Publisher waits to be called.
- **Saga pattern:** Debit first, credit second. If credit fails → auto-refund sender immediately. Venkatesh ka paisa waapis.
- **Stateless service:** No DB, no `db.js`. Horizontal scaling friendly. All state lives in account-service.
- **Fire-and-forget notifications:** SMS failure does NOT roll back the transaction.
- **publisher.js dual mode:** No `PUBSUB_TOPIC_ID` → HTTP to notification-service. With it → Google Cloud Pub/Sub.
- **Loose coupling:** account-service does NOT know transaction-service exists. It just receives debit/credit calls.

### 2026-05-10: transaction-service — Implementation & Testing COMPLETE
Brought up full 4-service stack: postgres + account-service + notification-service + transaction-service.
Ran 12 tests covering all endpoints and all failure modes. Created `transaction-service/TESTING_WALKTHROUGH.md`.

Tests passed:
- `/healthz`, `/readyz` — basic health
- Deposit ₹10,000 to Venkatesh via `/transactions/deposit` ✅
- Transfer ₹3,000 Venkatesh → Laxmi via `/transactions/transfer` ✅
- notification-service `/notifications` shows both events (source: "http", publisher local mode) ✅
- Insufficient funds → rejected, balance unchanged ✅
- Transfer to non-existent account (999) → SAGA / compensating refund fired, Venkatesh kept ₹7,000 ✅
- Same account transfer → blocked by input validation ✅
- Missing fields / negative amount → blocked before any service calls ✅
- Deposit to non-existent account → error passthrough ✅
- Notification logs show `[NOTIFY] OK` and `[NOTIFY] FAIL` for the right events ✅

Total money in system: ₹10,000 conserved (no money created or lost across all tests).

### 2026-05-10: notification-service — COMPLETE
Already running and verified during transaction-service testing. Understood: in-memory event log (`recent` array, max 100), dual listener (HTTP POST `/events` locally, Pub/Sub pull in GCP), `dispatch()` switch for `[NOTIFY] OK` vs `[NOTIFY] FAIL` logs. No separate understanding/testing session needed.

### 2026-05-10: api-gateway — Code Understanding Complete
Created `api-gateway/UNDERSTANDING.md`. Three files, three jobs.

Key breakthroughs:
- **What it is:** The Mandal Office main gate — single entry point for ALL external traffic
- **Three files:** `rateLimit.js` (traffic constable), `auth.js` (ID check guard), `index.js` (gate supervisor + proxy)
- **Middleware chain order:** rateLimit → route match → requireAuth → proxy. Rate limit comes FIRST (cheap) before JWT verify (expensive) to stop flood attacks early.
- **JWT (Gate Pass):** Three parts — header, payload (base64, readable by anyone), signature (tamper-proof stamp). Content is NOT secret, only tamper-proof. Expires in 1 hour.
- **`next()` pattern:** Express middleware — either call `next()` to pass to next handler, or respond directly to stop the chain.
- **Proxy + URL rewriting:** `/api/accounts/1` → strips `/api` → forwards `GET /accounts/1` to account-service. Internal services never know the gateway exists.
- **Rate limit token bucket:** Each IP gets 120 requests per 60 seconds (in-memory Map). Production needs Redis for shared state across pods.
- **502 vs 404:** 502 = gateway alive but backend service unreachable. 404 = route doesn't exist on the gateway itself.
- **Loose coupling:** account-service and transaction-service have NO knowledge that a gateway is in front of them.

### 2026-05-11: api-gateway — Implementation & Testing COMPLETE
Ran 13 tests against the full 5-service stack. Created `api-gateway/TESTING_WALKTHROUGH.md`.
Also fixed `docker-compose.yml` — removed postgres host port binding (5432 is blocked by Windows; host port was never needed since all services talk to postgres via Docker internal network).

Tests passed:
- `/healthz`, `/readyz` — public, no auth needed ✅
- `POST /api/auth/login` → JWT issued with 3600s expiry ✅
- Protected route with NO token → 401 missing bearer token ✅
- Protected route with FAKE token → 401 invalid token ✅
- Create Venkatesh + Laxmi accounts via gateway with valid JWT ✅
- Deposit ₹10,000 via gateway → routed to transaction-service → account-service ✅
- Transfer ₹3,000 Venkatesh → Laxmi via gateway ✅
- GET list accounts via gateway → correct balances (700000 / 300000) ✅
- Login with missing email → 400 ✅
- Stopped account-service → 502 upstream unreachable (gateway alive, backend down) ✅
- 125 rapid requests → 429 rate limit exceeded after request 121 ✅

Key insight confirmed: Internal services (account-service, transaction-service) never knew the gateway existed — they just received forwarded requests with `/api` prefix stripped.

### 2026-05-11: frontend — Code Understanding Complete
Created `frontend/UNDERSTANDING.md` with full layman breakdown.

Key breakthroughs:
- **Why nginx (not Node.js):** Frontend is just static files. nginx is a lightweight file server — no logic, no npm install, Dockerfile is only 4 lines.
- **Two nginx jobs:** Serve static files (HTML/CSS/JS) for `/` routes. Proxy `/api/*` to api-gateway for API calls.
- **The proxy trick:** Browser only knows `localhost:3000`. nginx secretly forwards `/api/*` to `api-gateway:8080`. Browser never sees the gateway directly.
- **`try_files` SPA routing:** If URL has no matching file on disk, serve `index.html` anyway — lets client-side JS handle routing.
- **`X-Real-IP` header:** nginx passes actual customer IP to api-gateway so rate limiting works per-customer, not per-nginx-instance.
- **`call()` helper in app.js:** Every API call goes through this — auto-attaches Bearer token, auto-parses response, throws on error.
- **sessionStorage for JWT:** Token lives only for the current browser tab — tab close = auto logout. Safer than localStorage.
- **Two-layer token check:** `requireToken()` in browser (UX) + `requireAuth` in api-gateway (security). Browser check is skippable by curl — server check is not.
- **No framework (React/Vue):** Demo project — vanilla JS, no build step, nginx serves files directly.

### 2026-05-15: frontend — Line-by-Line Code Walkthrough Complete
Created `frontend/CODE_WALKTHROUGH.md` — deepest explanation yet.

Key breakthroughs:
- **`API_BASE = '/api'`** — the single design decision that connects browser → nginx → api-gateway. All calls prefixed with `/api` which nginx's `location /api/` rule intercepts and proxies.
- **`call()` function** — master HTTP helper, auto-attaches Bearer token to every request, auto-parses JSON, throws on non-2xx. All 4 API operations go through it.
- **Why login uses `fetch()` directly** — `call()` auto-attaches token; login doesn't have one yet. Circle avoided.
- **`Number()` on inputs** — HTML always returns strings; APIs expect integers. Explicit conversion.
- **`e.preventDefault()`** — stops browser from page-refreshing on form submit; JS handles it instead.
- **`<script>` at bottom** — HTML elements must be built before JS tries to find them by id.
- **URL transformation table** — `/api/accounts` stays intact through nginx, only stripped inside api-gateway's `proxy()` function.
- **Full deposit trace** — traced one button click through 6 layers: browser → nginx → api-gateway → transaction-service → account-service → PostgreSQL → back.

### 2026-05-15: Architecture Foundations — Deep Confusion Resolved
Created `ARCHITECTURE_FOUNDATIONS.md` at project root covering all fundamental gaps.

Breakthroughs confirmed:
- **What is an API:** Browser cannot speak SQL. API is the HTTP translator + gatekeeper between browser and database. Without it, browser would need direct DB access — impossible + insecure.
- **nginx does NOT control microservices:** nginx only serves files + proxies /api/ to api-gateway. Zero knowledge of account/transaction/notification services.
- **app.js + index.html live INSIDE nginx container:** Placed there by `COPY public /usr/share/nginx/html` in Dockerfile. One container = nginx + html + js. Not two separate containers.
- **Port mapping:** `"3000:8080"` = LEFT is laptop port (the door), RIGHT is container port (the room). Docker-compose is the only place these doors are defined.
- **Docker DNS:** Inside Docker network, containers find each other by service name. `http://account-service:8080` works because Docker resolves `account-service` to the container's internal IP automatically.
- **Where service calls happen in code:** `transaction-service/src/index.js` line 7 reads `ACCOUNT_SERVICE_URL` env var set in docker-compose.yml. Line 13 calls `fetch(ACCOUNT_URL + path)`.
- **Why api-gateway is not optional:** Removes auth, rate limiting, single entry point, and URL abstraction in one blow. Security disaster without it.
- **12-step button-click trace** documented: browser → nginx → api-gateway → transaction-service → account-service → postgres → back.
- **Key insight for future:** Docker DNS + env vars + port mapping is IDENTICAL to how Kubernetes service discovery works. Master this, Kubernetes becomes obvious.

### Next Step — Phase 1 COMPLETION
- Start the FULL 5-service stack including frontend: `docker compose up`
- Open browser at `http://localhost:3000` and test through the UI
- Phase 1 (Application & Containerization) will be COMPLETE after this
