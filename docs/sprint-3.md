# Sprint 3: Queue, Leaderboard & Docker Compose Production

> **Duration**: Week 7-8
> **Phase**: 🟢 Docker Compose
> **Goal**: Async submission processing, real-time leaderboard, production-ready Docker Compose.
> **Depends on**: Sprint 2 (code execution working)
> **Milestone**: ✅ Complete application running via Docker Compose

---

## 📚 DevOps Learning Objectives

| Topic | What to Learn | Resources |
|-------|--------------|-----------|
| **Message Queues** | Producer/consumer pattern, acknowledgments, dead letter queues | RabbitMQ tutorials |
| **Async Architecture** | Decoupling services via queues, eventual consistency | Microservices Patterns book |
| **Redis Data Structures** | Sorted sets (ZADD, ZRANGE, ZREVRANGE), TTL, persistence | redis.io docs |
| **Retry & DLQ** | Exponential backoff, poison messages, dead letter exchanges | RabbitMQ DLX docs |
| **Reverse Proxy** | NGINX as single entry point, proxy_pass, load balancing basics | NGINX docs |
| **Docker Compose Production** | Restart policies, resource constraints, named volumes, health checks | Docker Compose spec |
| **E2E Testing** | Cypress/Playwright for full user flow testing | Cypress docs |

---

## Tasks

### RabbitMQ Integration

- [ ] Define exchange and queue topology:
  - Exchange: `submissions` (direct)
  - Queue: `submissions.execute` (main work queue)
  - Queue: `submissions.dlq` (dead letter queue)
  - Routing: submission created → `submissions.execute`, failed after 3 retries → `submissions.dlq`
- [ ] Submission Service: publish message to queue on `POST /api/submissions`
  - Message payload: `{submission_id, problem_id, code, language, test_cases}`
  - Return `submission_id` immediately with status `pending`
- [ ] Worker: consume from `submissions.execute`
  - Process submission (spawn container, run code)
  - Update submission status in database: `pending` → `running` → `passed`/`failed`
  - ACK message on success, NACK + requeue on transient failure
- [ ] Retry logic: max 3 attempts, then route to DLQ
- [ ] Monitor DLQ for failed submissions (log alert)

### Polling Mechanism

- [ ] `GET /api/submissions/{id}` — return current status + results
- [ ] Frontend: after submit, poll every 1 second until status is `passed`, `failed`, or `error`
- [ ] Show progress: `pending` → `running` → final result
- [ ] Display per test case: pass/fail, expected vs actual, execution time

### Redis Leaderboard

- [ ] Redis sorted set key pattern: `competition:leaderboard:{competitionId}`
- [ ] Score formula: `(problems_solved * 1_000_000) - total_solve_time_seconds`
  - Higher score = better rank (more problems solved wins; ties broken by faster time)
- [ ] When a submission passes during a competition:
  - `ZADD competition:leaderboard:{id} {score} {userId}`
  - Only update if score is better than existing
- [ ] `GET /api/competitions/{id}/leaderboard?top=100`
  - `ZREVRANGE` with scores → map to leaderboard entries
  - Include: rank, user_id, problems_solved, total_time

### Competition Basics

- [ ] CRUD for competitions (minimal — focus is on leaderboard)
- [ ] Submission Service checks if submission is part of a competition → updates leaderboard

### Frontend

- [ ] Submission flow: Submit button → spinner → polling → test case results display
- [ ] Leaderboard page (`/competitions/:id/leaderboard`)
  - Table: rank, user, problems solved, time
  - Auto-refresh every 5 seconds
  - Highlight current user (mock user_id for now)
- [ ] Competition timer (countdown to end)

### Docker Compose Production Setup

Make the app deployable as a "production" Docker Compose stack:

| Feature | Development Compose | Production Compose |
|---------|--------------------|--------------------|
| Build | `build: context: ...` | `image: <registry>/<service>:<tag>` (or build) |
| Restart | none | `restart: unless-stopped` |
| Volumes | source mounts for hot reload | named volumes for data only |
| Resources | no limits | `deploy.resources.limits` (CPU, memory) |
| Ports | all exposed | only frontend (80) and gateway (8080) exposed |
| Networking | default | custom networks (frontend-net, backend-net) |
| Proxy | direct port access | NGINX reverse proxy as single entry |

- [ ] Create `docker-compose.prod.yml`
- [ ] Add NGINX reverse proxy container:
  - Route `/` → frontend
  - Route `/api/` → api-gateway
  - Single port 80 exposed
- [ ] Create isolated networks: `frontend-net` (frontend + nginx + gateway), `backend-net` (all backend services)
- [ ] `make deploy-compose` — one-command production deploy

---

## Testing

| Service | Type | What to Test |
|---------|------|-------------|
| Submission Service | Unit (mock pika) | Message published with correct payload, submission saved as pending |
| Worker | Unit (mock pika) | Message consumed, ACK/NACK behavior, retry count tracking |
| Worker | Integration | Full async flow: publish → consume → execute → DB updated |
| Submission Service | Unit (mock Redis) | ZADD called with correct score, ZREVRANGE returns sorted entries |
| Submission Service | Integration (real Redis) | Leaderboard updates and retrieval work correctly |
| Frontend | Component | Submission polling UI, leaderboard table, countdown timer |
| E2E (Cypress) | Full flow | Browse problems → select problem → write code → submit → see results → view leaderboard |
| Docker Compose | Deploy test | `docker-compose -f docker-compose.prod.yml up` → all services healthy, accessible via NGINX |

---

## Checklist

- [ ] Submit code → get `submissionId` immediately
- [ ] Poll status → see `pending` → `running` → `passed`/`failed`
- [ ] RabbitMQ Management UI shows messages flowing
- [ ] Failed submission retried up to 3 times, then in DLQ
- [ ] Leaderboard updates when competition submission passes
- [ ] Leaderboard auto-refreshes on frontend every 5s
- [ ] E2E test passes: full user flow
- [ ] `docker-compose.prod.yml` runs complete app behind NGINX on port 80
- [ ] ✅ **Application fully functional via Docker Compose**
