# Live Traffic Observation — Watch the Whole Village Bank Work in Real Time
## A Story-Narrative Walkthrough for the Telangana Village DevOps Learner

---

Venkatesh sits down at his laptop in his village. The Wi-Fi is humming, the cows outside are chewing, and inside Docker — invisible to his eye — six containers are quietly running. The almiraah is full of accounts. The Accountant is at his desk. The Hawala Agent is waiting by his phone. The Announcer is standing ready to log every event. The Main Gate Guard is checking visitor badges. And the nginx receptionist is sitting at the front counter with HTML forms stacked beside him.

But Venkatesh cannot see any of this. All he sees is his laptop screen. So today, he is going to open a secret window — a window built into every web browser — that will let him see every single conversation between his browser and the bank, as it happens.

Before he begins, he opens his terminal and confirms the bank is running. He types `docker compose ps` and sees six green entries: postgres, account-service, notification-service, transaction-service, api-gateway, and frontend. The bank is open. The almiraah is full. Everyone is at their post.

Now he opens a SECOND terminal window — keeping the first one untouched — and in this second terminal he types:

```
docker compose logs -f frontend api-gateway transaction-service notification-service
```

The `-f` means "follow" — keep showing me new lines as they appear. The terminal goes quiet for a moment, then prints the startup messages of each service: "api-gateway listening on 8080", "transaction-service listening on 8080", and so on. From this moment on, every time any of these services receives a request, a new line will appear in this terminal. This terminal is now Venkatesh's window into the BACKEND world. He drags it to the right half of his screen and leaves it running.

He then opens Google Chrome (or Edge, or Firefox — any modern browser will do) and types `http://localhost:3000` into the address bar. He presses Enter.

At this exact moment, his laptop sends a small message asking for the front page. It travels into port 3000 — which docker-compose has mapped as a door into the nginx container — and reaches the nginx receptionist. The receptionist looks at the URL — it is just `/`, the front door — and reaches into his shelf at `/usr/share/nginx/html/`. He finds `index.html`, picks it up, and hands it back to Venkatesh's browser. The browser starts reading the HTML.

But the HTML is not complete by itself. It references two more files: `/styles.css` and `/app.js`. So the browser immediately asks nginx for those two files as well. Three trips to nginx, three files returned, and the page appears on screen — the heading "FinDevOps Demo", five sections, a few empty forms, and an empty Log box at the bottom. The browser also notices a small message in the header: "not signed in".

What Venkatesh now sees on his laptop is just the appearance of the bank. The forms are paper. The buttons do nothing yet. The whole page is silent. But somewhere inside the browser, the script `app.js` has loaded and is now sitting ready, listening for button clicks. It is the brain. The HTML is the body. The brain is awake.

Now comes the magical moment. Venkatesh presses the F12 key on his keyboard. (On a Mac, it would be Cmd+Option+I. On Windows, F12.) A panel slides out from the right or bottom of the browser. This panel is called **DevTools** — the developer's tools — and it has many tabs at the top. He clicks the tab labeled **Network**.

The Network tab is empty for now. But it has a small note that says "Recording network activity." Venkatesh refreshes the page (Ctrl+R), and the Network tab suddenly fills up with rows. Each row is one conversation between his browser and a server. He sees:

- A row for `localhost` (the HTML)
- A row for `styles.css`
- A row for `app.js`
- A row for `favicon.ico` (the little icon in the browser tab)

Each row shows the URL, the HTTP method (GET), the status code (200 means success), the type of file, and how long it took. Venkatesh clicks on the first row — `localhost`. A side panel opens with even more details: the request headers (what his browser sent), the response headers (what the server sent back), and the response body (the actual HTML content). He can SEE the HTML his browser received. The cow outside seems to moo in agreement.

He also glances at the right terminal — the docker logs window. There, three lines have appeared, written by nginx, reporting each file it served. The same conversations he saw in the Network tab are also being reported by nginx from the server side. He is now watching the SAME event from two sides — the browser side and the server side. This is the magic.

Now the real test begins. Venkatesh clears the Network tab (clicking the small slash-circle icon) so he can watch fresh activity. He types his email "venkatesh@village.com" into the Sign In form and clicks "Get token."

Instantly, ONE new row appears in the Network tab: `auth/login`. Venkatesh clicks on it. He sees the URL is `/api/auth/login`. The method is POST. The status code is 200. He scrolls down to "Request Payload" and sees the JSON he sent: `{"email":"venkatesh@village.com"}`. Then he scrolls to "Response" and sees the JSON the server returned: `{"token":"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...","expires_in_seconds":3600}`. He has just SEEN, with his own eyes, a JWT token being created and handed to his browser. The token is a long string that looks like nonsense, but he now knows it has three parts separated by dots — header, payload, signature. He has read about this in ARCHITECTURE_FOUNDATIONS.md, and now he is seeing it real.

He glances at the right terminal. A new line has appeared in the nginx access log: `POST /api/auth/login HTTP/1.1 200`. The nginx receptionist reports she forwarded a POST request to `/api/auth/login` and got back a 200. So in the browser, he saw the OUTGOING request and the RETURNING response. In the docker logs, he sees that nginx forwarded it onward. The forwarding happened to api-gateway, but the api-gateway in this demo does not log every request — so it processed silently. Still, the front-side proof is undeniable: a JWT was issued.

Venkatesh looks at the "auth-status" indicator in the top right of the webpage. It has changed from "not signed in" to "signed in." The token has been saved into the browser's sessionStorage. The brain (app.js) flipped the auth-status sign by itself, because that is the rule it follows after a successful login.

Now he tries something interesting — he clicks "Get token" AGAIN, just to see what happens. Another POST to `/api/auth/login` appears in the Network tab. Another fresh token comes back. The old token is overwritten in sessionStorage with the new one. He realizes the bank does not mind issuing tokens repeatedly — it just keeps making new ones with new expiry times. In a real bank, this would be a security concern (you would want some rate limiting), but for our learning demo, it is fine.

He clears the Network tab again. Now for the real flow. He scrolls down to "Create Account", types "Venkatesh Reddy" and "venkatesh@village.com", and clicks Create.

One row appears: `accounts` with method POST and status 201. He clicks on it. The URL is `/api/accounts`. In the Request Headers section, he scrolls down and finds something new — a header called `authorization` with the value `Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`. The Bearer token. The Visitor Badge. The auto-stamped pass. The `call()` function in `app.js` quietly attached this header without Venkatesh having to do anything. The token he got 30 seconds ago in the login response is now being presented at every door, automatically.

He scrolls to the Request Payload: `{"owner_name":"Venkatesh Reddy","email":"venkatesh@village.com"}`. He scrolls to the Response: `{"id":1,"owner_name":"Venkatesh Reddy","email":"venkatesh@village.com","balance_cents":"0","created_at":"..."}`. He has now SEEN, on his own screen, the exact moment an account was born in the database. ID 1. Balance 0.

He glances at the right terminal. nginx logged `POST /api/accounts HTTP/1.1 201`. The api-gateway processed it silently. The account-service processed it silently. But postgres has now stored a row in the accounts table — invisible but very real.

He goes back to the webpage and creates Laxmi: "Laxmi Devi", "laxmi@village.com". Another POST, status 201, account ID 2 is born. The Log section at the bottom of the page is filling up: "created account #1 (venkatesh@village.com)", "created account #2 (laxmi@village.com)". This Log is `app.js` reporting back to Venkatesh in plain English what just happened, so he does not have to read DevTools to know.

He clicks the Refresh button under the Accounts table. ONE row appears in Network: `GET /api/accounts` with status 200. He clicks it. Response: `[{"id":1,...},{"id":2,...}]` — a JSON array with both accounts. The webpage table fills up with two rows showing Venkatesh and Laxmi, both with balance 0.

Now the deposit. He fills in account_id=1 and amount=1000000 (which is one million paise = ₹10,000) and clicks Deposit.

ONE row appears: `transactions/deposit`. Method POST. Status 201. He clicks. The URL is `/api/transactions/deposit`. The Authorization Bearer token is automatically there. The payload is `{"account_id":1,"amount_cents":1000000}`. The response is `{"status":"completed","account_id":1,"amount_cents":1000000}`. But here is the interesting part — RIGHT AFTER this row, ANOTHER row appears automatically: `GET /api/accounts`. This is the auto-refresh that `app.js` triggers after every operation that changes a balance. Two requests for one button click. The accounts table on the webpage updates: Venkatesh now shows balance 1000000.

He glances at the docker logs terminal. Now the notification-service comes alive. He sees a new line in cyan or yellow text:

```
notification-service-1  | [NOTIFY] OK   {"type":"transaction.completed","account_id":1,"amount_cents":1000000,"kind":"deposit",...}
```

This is the proof he has been waiting to see — proof that transaction-service called notification-service after the deposit. The fire-and-forget event was fired, and it was caught. The whole chain works. Without lifting a finger to write any curl commands, Venkatesh has seen the deposit ripple through the system from the browser all the way to the announcement peon's log book.

Now the most important test of his understanding — the transfer. He fills in from_id=1, to_id=2, amount=300000 (₹3,000), and clicks Transfer.

ONE row appears in Network: `transactions/transfer`. POST. Status 201. He clicks and reads: URL `/api/transactions/transfer`, Bearer token attached, payload `{"from_account_id":1,"to_account_id":2,"amount_cents":300000}`, response `{"status":"completed","type":"transaction.completed","from_account_id":1,"to_account_id":2,"amount_cents":300000,"at":"..."}`. Then the auto-refresh row appears. The accounts table updates: Venkatesh now 700000, Laxmi now 300000. Total still 1000000. Money was moved, not created.

He glances at the docker logs. Another `[NOTIFY] OK` line appears, this one for the transfer. The chain was:

```
browser → nginx → api-gateway → transaction-service → account-service (debit Venkatesh)
                                                  ↘ account-service (credit Laxmi)
                                                  ↘ notification-service (publish event)
```

All of this happened in a few hundred milliseconds. In the browser, Venkatesh saw exactly ONE request go out and one response come back. He had no idea that behind that single request, FOUR more service-to-service calls happened. The browser sees only the OUTERMOST layer of the conversation. The api-gateway hides the rest. This is the beauty of microservices.

Now Venkatesh tries something that should fail. He sets from_id=1, to_id=2, amount=999999999 (₹99,99,999.99 — way more than Venkatesh has). He clicks Transfer.

A new row appears in Network: `transactions/transfer`. But this time the status is 409 — a red row in the Network tab. Conflict. He clicks it. Response: `{"error":"insufficient funds"}`. In the docker logs, he sees:

```
notification-service-1  | [NOTIFY] FAIL insufficient funds {...}
```

The Saga pattern worked. The debit was attempted, the database said "not enough", the transfer was rejected, and a FAIL notification was sent. He confirms by clicking Refresh — Venkatesh's balance is still 700000. Nothing moved.

Now the FINAL test — the one that proves api-gateway is actually doing its job. Venkatesh opens DevTools again (if it closed) and goes to the **Application** tab (or "Storage" in some browsers). On the left side, he expands "Session Storage" → `http://localhost:3000`. He sees one entry: `token`. He clicks on it and sees the JWT value. Then he RIGHT-CLICKS the token and chooses Delete. The token is gone from the browser.

He goes back to the webpage and clicks Refresh on the Accounts section.

A new row appears in Network: `GET /api/accounts`. But this time, the status is **401 Unauthorized** — red, angry. He clicks it. The Request Headers section now does NOT have an Authorization header (the token was deleted, so `app.js` had nothing to attach). The Response is `{"error":"missing bearer token"}`. The api-gateway, sitting between nginx and account-service, refused to forward the request. The Accountant inside the bank never saw this request. The gate stopped it.

The Log at the bottom of the webpage shows: "refresh failed: {"error":"missing bearer token"}".

Venkatesh signs in again. The token reappears. He clicks Refresh. Now the request succeeds — `GET /api/accounts` returns 200 with the data. The Bearer token is back in the header. The gate let it through.

He has now SEEN, with his own eyes:
- The HTML, CSS, and JS being downloaded by the browser
- The JWT token being issued at login
- The Bearer header being auto-attached to every subsequent request
- The full chain of microservices working together (deposit, transfer)
- The notification events being logged on the server side in real time
- A failed transfer being rejected and a FAIL notification being sent
- The api-gateway refusing requests without a valid token (401)

Every single thing he read about in ARCHITECTURE_FOUNDATIONS.md, he has now WATCHED happen in real time, from two angles — the browser side (DevTools Network tab) and the server side (docker compose logs).

To wrap up the session, he goes back to his FIRST terminal (the one without the log tail) and runs `docker compose logs notification-service` to see the full event history that built up:

```
[NOTIFY] OK   transaction.completed (deposit)
[NOTIFY] OK   transaction.completed (transfer)
[NOTIFY] FAIL insufficient funds
```

Every event, in order, with timestamps. The complete story of his session.

He smiles. The application is not running randomly. It is not running in a vacuum. There is a clear, logical, traceable flow:

> Browser → nginx (port 3000 → 8080) → api-gateway (auth check, route) → account-service or transaction-service → postgres or notification-service → response bubbles back up through every layer in reverse order → DevTools Network tab in the browser → app.js → the Log on screen.

If anyone ever asks him to explain how a microservices web app works, he no longer has to remember theory. He just has to remember THIS session. The forms he typed in. The Network tab rows. The Bearer tokens. The 401 when the token was deleted. The notification logs in green and red. The whole flow is now in his head as something he LIVED, not just something he read.

To stop the bank for today, he switches to his first terminal and types:

```
docker compose down
```

The containers shut down one by one. The notification-service goes quiet first. Then account-service. Then transaction-service. Then api-gateway. Then frontend. Then postgres. The network is removed. Everything is clean.

But the next time he runs `docker compose up`, the bank will be back exactly as it was — except the data is gone (unless he kept the `pgdata` volume). The forms will be the same. The Network tab will tell the same story. The flow will be the same. The logic will be the same.

This is the foundation. Everything in Kubernetes — Services, Ingress, Deployments, ConfigMaps — is just a more powerful, more scalable version of what he just observed today in Docker Compose. The names change. The story does not.

---

## Cheat Sheet — Things to Click and Look At

When you actually do this, here is the minimum you need to remember:

```
1. docker compose up -d
2. Second terminal: docker compose logs -f frontend api-gateway transaction-service notification-service
3. Browser: http://localhost:3000
4. F12 → Network tab
5. Click buttons on the page
6. Click any row in Network tab to see Headers / Payload / Response
7. Application tab → Session Storage to see the JWT
8. Delete the JWT and try to refresh → watch the 401
9. docker compose down
```

That is the whole thing. Read this story once. Do it once. The flow will live in your head forever.
