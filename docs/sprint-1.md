# Sprint 1: 3 Core Flows ✅

> **Duration**: Week 3-4
> **Phase**: 🟢 Local
> **Status**: COMPLETED
> **Goal**: Wire all services together with 3 minimal flows so the app actually does something end-to-end.
> **Depends on**: Sprint 0 (all services running with `/health`)

---

## Why This Sprint Exists

A DevOps pipeline is meaningless if services don't talk to each other. These 3 flows are the **minimum viable app** that makes every DevOps sprint after this one actually testable:

| Flow | What It Tests in Later Sprints |
|------|-------------------------------|
| Submission → Queue → Worker | **HPA**: spam requests, queue fills, K8s auto-scales Workers |
| Mock CPU/RAM execution | **Resource Limits**: Worker without limits crashes the cluster |
| Problem list + status polling | **DB Migrations**: Flyway schema auto-creates on RDS deploy |

---

## Flow 1: Submission (Async Queue)

The full path: **Frontend → API Gateway → Submission Service → RabbitMQ → Worker → Database**

### Submission Service

- [x] `POST /api/submissions` — accepts `code`, `language`, optional `problem_id`
- [x] Save submission to `submissions` table with status = `pending`
- [x] Publish message to RabbitMQ exchange `submissions` (durable, persistent)
- [x] Return immediately: `{"submission_id": "<uuid>", "status": "pending"}`

### Worker

- [x] Connect to RabbitMQ, consume from queue `submissions.execute` (prefetch=1)
- [x] On message: update status → `running`, mock execute, update → `passed`/`failed`, ACK
- [x] On failure: NACK + log error

### Frontend

- [x] Submit page: textarea + language dropdown + submit button
- [x] POST to `/api/submissions` via API Gateway
- [x] Receive `submission_id`, start polling every 2 seconds

---

## Flow 2: Mock Execution (Random Outcomes)

### Worker Mock Executor

- [x] Function `mock_execute(code, language)` with random outcomes:

| Outcome | Probability | What Happens | CPU/RAM Impact |
|---------|-------------|-------------|----------------|
| ✅ `passed` | 60% | Light CPU burn (1-3s), return mock output | Low |
| ⏱️ `timeout` | 25% | Heavy CPU burn (exceeds `MOCK_EXEC_TIMEOUT`, default 5s) | High CPU |
| 💀 `oom_killed` | 15% | Allocate ~256-512MB memory, simulate OOM | High RAM |

- [x] CPU and memory usage is **real** (not faked) — triggers K8s limits
- [x] Configurable via env vars: `MOCK_EXEC_TIMEOUT`, `MOCK_EXEC_MAX_MEMORY_MB`
- [x] Detailed logging per submission

### Frontend — Show Results

- [x] ✅ **passed**: green badge + execution time + output
- [x] ⏱️ **timeout**: orange badge + "exceeded time limit"
- [x] 💀 **oom_killed**: red badge + "memory exceeded"
- [x] Shows execution_time_ms and memory_mb

---

## Flow 3: Problem List + Status Polling

### Problem Service

- [x] `GET /api/problems` — returns all problems from seed data (`ProblemSummaryDto`)
- [x] `GET /api/problems/{id}` — returns detail with code stubs (`ProblemDetailDto`)
- [x] JPA entity + repository + controller

### Submission Service

- [x] `GET /api/submissions/{id}` — returns full status with results
- [x] Status transitions: `pending` → `running` → `passed`/`failed`

### Frontend

- [x] Polls every 2 seconds, stops on final status
- [x] Problem list on home page with level badges and tags
- [x] "Solve →" links to submit page per problem

---

## Bonus: Queue Monitoring

- [x] `GET /api/queue/status` — returns pending messages + active consumers
- [x] Frontend queue status bar: pending count, worker count, estimated wait
- [x] Auto-refreshes every 10 seconds

---

## What Was Built

| Service | Files Added |
|---------|-----------|
| Problem Service | `Problem.java`, `ProblemRepository.java`, `ProblemController.java`, `ProblemSummaryDto.java`, `ProblemDetailDto.java`, `ProblemControllerTest.java` |
| Submission Service | `database.py`, `submission.py` (model), `schemas.py`, `submissions.py` (routes), `queue.py`, `queue_status.py` |
| Worker | `mock_executor.py`, `consumer.py`, updated `main.py` with lifespan |
| Frontend | `api.service.ts`, `app.component.ts`, `home.component.ts`, `submit.component.ts`, `app.routes.ts`, `styles.scss` |

## Testing

- [x] Worker mock executor: 3 tests (valid result, passed output, all outcomes) — via Docker
- [x] Problem Service: 3 tests (list, detail found, 404) — MockMvc + @MockitoBean
- [x] Submission Service: 3 tests (health, OpenAPI, POST submission)
- [x] Docker Compose: all 5 images build, 9 containers start healthy
