
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
