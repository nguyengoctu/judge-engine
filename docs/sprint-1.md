# Sprint 1: 3 Core Flows

> **Duration**: Week 3-4
> **Phase**: 🟢 Local
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

- [ ] `POST /api/submissions` — accepts JSON body:
  - `code` (string): the submitted code
  - `language` (string): python/javascript/java
  - `problem_id` (string, optional): which problem
- [ ] Save submission to `submissions` table with status = `pending`
- [ ] Publish message to RabbitMQ exchange `submissions`:
  - Payload: `{"submission_id": "<uuid>", "code": "<code>", "language": "<lang>"}`
- [ ] Return immediately: `{"submission_id": "<uuid>", "status": "pending"}`

### Worker

- [ ] Connect to RabbitMQ, consume from queue `submissions.execute`
- [ ] On message received:
  1. Update submission status to `running` in database
  2. Run mock execution (see Flow 2)
  3. Update submission status to `passed` or `failed` in database
  4. ACK the message
- [ ] On failure: NACK + log error

### Frontend

- [ ] Simple page with:
  - Textarea for code input
  - Language dropdown (python/javascript/java)
  - Submit button
- [ ] On submit: POST to `/api/submissions` via API Gateway
- [ ] Receive `submission_id`, start polling (see Flow 3)

---

## Flow 2: Mock Execution (Random Outcomes)

**Purpose**: Simulate realistic code execution — some pass, some timeout, some get killed for using too much memory. This is what triggers HPA and tests resource limits in later sprints.

### Worker Mock Executor

- [ ] Function `mock_execute(code, language)` with **random outcomes**:

| Outcome | Probability | What Happens | CPU/RAM Impact |
|---------|-------------|-------------|----------------|
| ✅ `passed` | 60% | Light CPU burn (1-3s), return mock output | Low |
| ⏱️ `timeout` | 25% | Heavy CPU burn (exceeds `MOCK_EXEC_TIMEOUT` env var, default 5s) | High CPU |
| 💀 `oom_killed` | 15% | Allocate huge memory (~500MB+), simulate OOM | High RAM |

- [ ] Each outcome returns a detailed result:
  - `passed`: `{"status": "passed", "execution_time_ms": 1247, "output": "mock output", "memory_mb": 32}`
  - `timeout`: `{"status": "timeout", "execution_time_ms": 5000, "error": "Execution exceeded 5s time limit"}`
  - `oom_killed`: `{"status": "oom_killed", "execution_time_ms": 812, "error": "Process killed: memory limit exceeded (512MB)"}`
- [ ] CPU and memory usage must be **real** (not faked) — this is what triggers K8s limits
- [ ] Log clearly: `"Submission {id}: outcome={status}, cpu_time={n}s, memory={m}MB"`
- [ ] Configurable via env vars: `MOCK_EXEC_TIMEOUT=5`, `MOCK_EXEC_MAX_MEMORY_MB=512`

### Why Random Matters for DevOps

| Scenario | What It Tests in K8s/ECS |
|----------|------------------------|
| `passed` (60%) | Normal flow: HPA stays calm |
| `timeout` (25%) | High CPU → HPA scales up Workers when queue fills |
| `oom_killed` (15%) | Memory spike → K8s OOMKill if no resource limits → pod restart → lesson learned |

### Frontend — Show Results

- [ ] After polling `GET /api/submissions/{id}`, display result based on status:
  - ✅ **passed**: green badge, execution time, output
  - ⏱️ **timeout**: orange badge, "Execution exceeded time limit (5s)"
  - 💀 **oom_killed**: red badge, "Process killed: memory limit exceeded"
- [ ] Show execution_time_ms and memory_mb for all outcomes

---

## Flow 3: Problem List + Status Polling

### Problem Service

- [ ] `GET /api/problems` — return all problems from database (from seed data)
  - Response: array of `{id, title, level, tags}`
  - No pagination needed yet — just return all
- [ ] `GET /api/problems/{id}` — return single problem detail
  - Response: `{id, title, question, level, tags, code_stubs}`

### Submission Service

- [ ] `GET /api/submissions/{id}` — return submission status
  - Response: `{id, status, results, execution_time, submitted_at}`
  - Status transitions: `pending` → `running` → `passed`/`failed`

### Frontend

- [ ] After submitting code, poll `GET /api/submissions/{id}` every 2 seconds
- [ ] Display: `pending...` → `running...` → `✅ passed (1247ms)` or `❌ failed`
- [ ] Show problem list on home page (simple list, click → detail page is optional)

---

## Database

No schema changes needed — V1__init.sql already has `problems` table (with seed data) and `submissions` table. Flyway handles migration on service start.

---

## Testing

| Service | Type | What to Test |
|---------|------|-------------|
| Submission Service | Unit (mock pika) | POST saves to DB, publishes to queue, returns pending |
| Submission Service | Unit | GET returns correct status |
| Worker | Unit (mock pika) | Consumes message, calls mock_execute, updates DB |
| Worker | Unit | mock_execute actually burns CPU for configured seconds |
| Problem Service | Unit (MockMvc) | GET /api/problems returns seed data |
| Problem Service | Unit (MockMvc) | GET /api/problems/{id} returns 200 or 404 |
| Integration | Docker Compose | POST submission → poll → status eventually = passed |

---

## Checklist

- [ ] `POST /api/submissions` → returns `{submission_id, status: "pending"}`
- [ ] Message appears in RabbitMQ Management UI (localhost:15672)
- [ ] Worker picks up message, logs "Processing submission..."
- [ ] Worker burns CPU for N seconds (visible in `docker stats`)
- [ ] `GET /api/submissions/{id}` → status transitions from `pending` → `running` → `passed`
- [ ] `GET /api/problems` → returns seed data from database
- [ ] Frontend: type code → submit → see status updates → final result
- [ ] All tests pass via `make test`
- [ ] **End-to-end flow works in Docker Compose**
