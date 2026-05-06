# Game Day — Chaos Scenarios

Run these scenarios quarterly to validate reliability assumptions.
Each scenario has a **hypothesis**, **blast radius**, **inject**, **expected outcome**, and **rollback**.

Prerequisite: notify the team on `#fintech-alerts` before injecting. Confirm Cloud Monitoring dashboards are open.

---

## Scenario 1 — Pod Kill (Resilience)

**Hypothesis:** Killing all pods of a service causes < 1s observable downtime due to HPA/PDB keeping minimum replicas.

**Blast radius:** One service namespace. No data loss.

### Inject
```bash
kubectl -n account-service delete pods --all --grace-period=0 --force
```

### Expected outcome
- PDB (`minAvailable: 1`) prevents simultaneous deletion; at least one pod remains.
- New pods start within 30 s.
- Grafana shows a brief spike in 5xx rate that recovers below SLO threshold.
- No `on-sync-failed` ArgoCD alert fires (ArgoCD self-heals the count).

### Verify
```bash
kubectl -n account-service get pods -w
# Watch pod count recover to replicaCount=2 within 30s

# Check for 5xx spike in Grafana "Golden Signals" dashboard
# Error rate should not trigger SLO fast-burn alert (14x budget consumption)
```

### Rollback
No action needed — self-healing. If pods are stuck, check `kubectl describe pod`.

---

## Scenario 2 — Node Drain (Zone Resilience)

**Hypothesis:** Draining one node in one zone moves workloads to the remaining two zones within 5 min without violating any PDB.

**Blast radius:** One GKE node. No data loss.

### Inject
```bash
# Pick a node to drain
NODE=$(kubectl get nodes -o name | head -1 | cut -d/ -f2)
kubectl cordon "${NODE}"
kubectl drain "${NODE}" \
  --ignore-daemonsets \
  --delete-emptydir-data \
  --grace-period=30
```

### Expected outcome
- Topology spread constraints (`maxSkew: 1`) redistribute pods across remaining zones.
- No PDB violations (each service has `minAvailable: 1`).
- All services remain `Healthy` in ArgoCD.
- Cloud Monitoring node CPU alert does not fire on the remaining nodes.

### Verify
```bash
kubectl get pods -A -o wide | grep -v "${NODE}"
# Confirm pods are on other nodes

kubectl -n account-service exec deploy/account-service -- \
  wget -qO- http://localhost:8080/health
# Health check passes
```

### Rollback
```bash
kubectl uncordon "${NODE}"
```

---

## Scenario 3 — Cloud SQL HA Failover

**Hypothesis:** Cloud SQL automatic failover to the standby replica completes in < 2 min with < 5 s transaction interruption.

**Blast radius:** Temporary write unavailability (< 2 min). No data loss.

### Inject
```bash
gcloud sql instances failover fintech-dev-pg-XXXX \
  --project=fintech-dev
```

### Expected outcome
- Cloud SQL initiates synchronous failover to the HA standby.
- `account-service` pods experience connection resets; Cloud SQL Auth Proxy reconnects automatically.
- `DB_password` secrets and connection names are unchanged (same instance, failover is transparent).
- Grafana shows a brief error rate spike on `/accounts/*` endpoints that recovers < 2 min.

### Verify
```bash
# Watch failover state
gcloud sql operations list \
  --instance=fintech-dev-pg-XXXX \
  --project=fintech-dev \
  --filter="operationType=FAILOVER"

# Confirm service recovers
kubectl -n account-service logs deploy/account-service --since=5m | grep -i error
```

### Rollback
Automatic. Failover is complete when `gcloud sql instances describe` shows `state: RUNNABLE`.

---

## Scenario 4 — Pub/Sub Consumer Down (Message Backlog)

**Hypothesis:** Taking `notification-service` offline causes the Pub/Sub subscription backlog to grow, triggering the Cloud Monitoring `pubsub_backlog` alert before 1000 unacked messages.

**Blast radius:** Notification delivery delayed. No message loss (messages retained 7 days).

### Inject
```bash
# Scale notification-service to zero replicas
kubectl -n notification-service scale deploy/notification-service --replicas=0

# Generate traffic that publishes to the topic (transaction flow)
# Wait 5-10 min for backlog to accumulate
```

### Expected outcome
- Cloud Monitoring `Pub/Sub Subscription Backlog High` alert fires at threshold 1000.
- ArgoCD notification appears in `#fintech-alerts` Slack channel.
- No messages are lost (Pub/Sub retention = 7 days; DLQ activates after 5 failed deliveries).

### Verify
```bash
gcloud pubsub subscriptions describe fintech-dev-transactions \
  --project=fintech-dev \
  --format='value(numUndeliveredMessages)'
# Should show growing backlog

# Check Cloud Monitoring alert
gcloud alpha monitoring policies list \
  --filter="displayName~'Pub/Sub'" \
  --project=fintech-dev
```

### Rollback
```bash
kubectl -n notification-service scale deploy/notification-service --replicas=2
kubectl -n notification-service rollout status deploy/notification-service
# Service will drain the backlog automatically
```

---

## Scenario 5 — mTLS Policy Enforcement (AuthorizationPolicy)

**Hypothesis:** A direct call from `frontend` to `account-service` (bypassing `api-gateway`) is blocked by the Istio AuthorizationPolicy.

**Blast radius:** None — the call should fail and that is the expected result.

### Inject
```bash
# Exec into the frontend pod and attempt a direct call to account-service
kubectl -n frontend exec deploy/frontend -c frontend -- \
  wget -qO- http://account-service.account-service.svc.cluster.local/accounts \
  --timeout=5 2>&1 || true
```

### Expected outcome
- Connection is rejected with `RBAC: access denied` (Istio 403).
- The `frontend` pod cannot reach `account-service` directly.
- Cloud Logging shows an `RBAC_ACCESS_DENIED` entry for the attempted call.

### Verify
```bash
# Confirm the denial appears in Istio access logs
kubectl -n account-service logs deploy/account-service -c istio-proxy \
  --since=2m | grep "RBAC\|deny"

# Now confirm the ALLOWED call path works (frontend → api-gateway → account-service)
kubectl -n frontend exec deploy/frontend -c frontend -- \
  wget -qO- http://api-gateway.api-gateway.svc.cluster.local/accounts \
  --timeout=5
# Should succeed
```

### Rollback
No action needed — no state was changed.

---

## Scenario 6 — Certificate Rotation (ASM mTLS)

**Hypothesis:** ASM-managed certificates rotate transparently with zero service disruption.

**Blast radius:** None — certs rotate in the background.

### Inject
ASM rotates certificates automatically. To force a rotation for testing:
```bash
# Restart istiod to trigger cert re-issuance
kubectl -n istio-system rollout restart deploy/istiod
kubectl -n istio-system rollout status deploy/istiod
```

### Expected outcome
- All sidecar proxies receive new leaf certificates within 5 min.
- No connection errors in any service during rotation.
- Grafana error rate stays flat.

### Verify
```bash
# Check cert expiry on a running sidecar
kubectl -n account-service exec deploy/account-service -c istio-proxy -- \
  openssl s_client -connect account-service.account-service.svc.cluster.local:80 \
  -alpn istio 2>/dev/null | openssl x509 -noout -dates
```

---

## Post-Game-Day Checklist

- [ ] All scenarios run; results recorded in incident tracker
- [ ] Alerts fired when expected — confirm thresholds are calibrated correctly
- [ ] No unexpected cascading failures
- [ ] Recovery times measured against RTO/RPO targets in `disaster-recovery.md`
- [ ] Any gap between hypothesis and observation → filed as a task
- [ ] Next game day scheduled (quarterly cadence recommended)
