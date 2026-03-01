# Sprint 2: Code Execution Engine

> **Duration**: Week 5-6
> **Phase**: 🟢 Docker Compose
> **Goal**: Users can submit code and get results — code runs securely in sandboxed Docker containers.
> **Depends on**: Sprint 1 (Problem Service + Frontend working)

---

## 📚 DevOps Learning Objectives

| Topic | What to Learn | Resources |
|-------|--------------|-----------|
| **Container Security** | Read-only FS, network isolation, resource limits, Seccomp profiles | Docker security docs |
| **Docker SDK** | Programmatically create/run/destroy containers from Python | docker-py docs |
| **Container Lifecycle** | Create → Start → Wait → Collect output → Remove | Docker Engine API |
| **Resource Limits** | `--cpus`, `--memory`, `--pids-limit` flags and cgroup enforcement | Linux cgroups, Docker docs |
| **Process Isolation** | Namespaces, seccomp, read-only root filesystem | Linux security fundamentals |
| **Structured Logging** | JSON structured logs for machine parsing, correlation IDs | ELK/EFK patterns |

---

## Tasks

### Code Runner Containers

Build a Docker image per supported language. Each image contains:
- Language runtime (Python 3.11 / Node.js 20 / OpenJDK 17)
- Test harness script that reads JSON input, runs user code, compares output
- Data structure helpers (TreeNode, ListNode, etc.)

| Image | Base | Harness Script | Helpers |
|-------|------|---------------|---------|
| `runner-python` | python:3.11-slim | `run.py` | `structures/tree.py`, `structures/linked_list.py` |
| `runner-javascript` | node:20-alpine | `run.js` | `structures/tree.js`, `structures/linked_list.js` |
| `runner-java` | eclipse-temurin:17-jdk-alpine | `Run.java` | `structures/TreeNode.java`, `structures/ListNode.java` |

**Test harness flow**:
1. Read test cases JSON from mounted volume
2. Read user code from mounted volume
3. For each test case: deserialize input → call user function → compare output with expected
4. Write results JSON to mounted volume (pass/fail, execution time, actual output)

### Security & Isolation

Every container must run with:

| Security Measure | Flag/Config | Purpose |
|-----------------|-------------|---------|
| Read-only filesystem | `--read-only` + tmpfs on `/tmp` | Prevent writing to disk |
| CPU limit | `--cpus=1` | Prevent CPU hogging |
| Memory limit | `--memory=256m` | Prevent memory bombs |
| No network | `--network none` | Prevent outbound calls |
| Timeout | 5-second kill | Prevent infinite loops |
| PID limit | `--pids-limit=50` | Prevent fork bombs |
| Seccomp | Default Docker seccomp profile | Block dangerous syscalls |
| No privilege escalation | `--security-opt=no-new-privileges` | Prevent root escalation |

### Worker Service (Python)

- [ ] Receive execution request (problem_id, code, language, test_cases)
- [ ] Create temp directory, write user code + test cases
- [ ] Spawn runner container using Docker SDK:
  - Mount temp dir as read-only volume
  - Apply all security flags
  - Wait for completion or timeout
- [ ] Read results from container stdout/mounted output
- [ ] Clean up container and temp dir
- [ ] Return structured results to caller

### Submission Service (FastAPI)

- [ ] `POST /api/submissions` — accept code, call Worker synchronously, return results
- [ ] Store submission + results in database
- [ ] API Gateway route `/api/submissions/**` → Submission Service

### Frontend

- [ ] Wire Submit button on Problem Detail page
- [ ] Show results: pass/fail per test case, execution time
- [ ] Handle errors: timeout, runtime error, compilation error

---

## Testing

| Service | Type | What to Test |
|---------|------|-------------|
| Worker | Unit (mock Docker SDK) | Container creation params (security flags), timeout handling, cleanup |
| Worker | Integration (real Docker) | Submit known-good code → pass, submit bad code → fail |
| Submission Service | API (httpx) | `POST /api/submissions` → correct results, invalid language → 400 |
| Code Runner | Self-test | Each harness runs correctly for Two Sum, FizzBuzz, tree problems |
| Security | Integration | Infinite loop → killed in 5s, `import os; os.system("rm -rf /")` → blocked, network call → blocked, memory bomb → killed |

---

## Checklist

- [ ] Runner images built for Python, JavaScript, Java
- [ ] Test harness works for at least 3 different problem types
- [ ] Submit code on frontend → see pass/fail per test case
- [ ] Infinite loop code → timeout within 5 seconds
- [ ] Network access attempt → blocked
- [ ] Memory-heavy code → killed by OOM
- [ ] All security flags verified via `docker inspect`
- [ ] Unit + integration + security tests pass
- [ ] **Still runs via `docker-compose up`**
