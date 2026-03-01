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

## Flow 2: Mock Execution (CPU/RAM Burn)

**Purpose**: Simulate a resource-intensive code execution without building a real sandbox. This is what will trigger HPA and test resource limits.

### Worker Mock Executor

- [ ] Function `mock_execute(code, language)`:
  - Simulate CPU work: busy loop for 2-5 seconds (configurable via env var `MOCK_EXEC_SECONDS`)
  - Simulate memory: allocate a large list/array (~100MB) during execution
  - Return mock result: `{"passed": true, "execution_time_ms": <actual_time>, "output": "mock result"}`
- [ ] Log: `"Processing submission {id}, burning CPU for {n} seconds"`
- [ ] After execution, update submission in DB:
  - `status` = `passed`
  - `results` = JSON with execution time
  - `execution_time` = actual ms taken

**Important**: The execution time and memory usage must be real (not faked) — this is what triggers K8s resource limits and HPA scaling.

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
