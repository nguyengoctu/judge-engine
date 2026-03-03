# Sprint 2.5: Docker Sandbox Executor

> **Duration**: Week 5-6
> **Phase**: 🟢 Local
> **Goal**: Replace mock CPU/RAM burn with real Docker-based code execution. Worker spawns isolated containers to run user code safely.

---

## 📚 DevOps Learning Objectives

| Topic | What to Learn | Why It Matters |
|-------|--------------|----------------|
| **Docker-in-Docker** | Docker socket mount, spawning containers from inside containers | Core of sandboxed execution |
| **Container Isolation** | Network isolation, read-only filesystem, drop capabilities | Security: user code can't escape |
| **Resource Limits** | `--memory`, `--cpus`, `--pids-limit` in `docker run` | Prevent fork bombs, OOM on host |
| **Timeout Management** | Container timeout, kill after N seconds | Prevent infinite loops |
| **Image Management** | Pre-built language images (python, java, node) | Fast cold-start, controlled environment |

---

## Architecture

```
                    Worker Container
                    ┌──────────────────────────────┐
                    │  consumer.py                 │
                    │    ↓                          │
                    │  docker_executor.py           │
                    │    ↓                          │
                    │  docker.sock ──────────────┐  │
                    └────────────────────────────│──┘
                                                 ↓
                    Sandbox Container (ephemeral)
                    ┌──────────────────────────────┐
                    │  python:3.11-alpine           │
                    │  --memory=256m --cpus=0.5     │
                    │  --network=none               │
                    │  --read-only                  │
                    │  --pids-limit=50              │
                    │                              │
                    │  > python /code/solution.py   │
                    │  > stdout → captured          │
                    │  > exit code → status         │
                    └──────────────────────────────┘
                    (auto-removed after execution)
```

---

## Tasks

### 1. Language Runner Images

- [ ] Create lightweight Docker images for each supported language:
  - `judge-runner-python:latest` (python:3.11-alpine)
  - `judge-runner-java:latest` (eclipse-temurin:21-jre-alpine)
  - `judge-runner-node:latest` (node:20-alpine)
- [ ] Pre-pull images on worker startup
- [ ] Store Dockerfiles in `docker/runners/`

### 2. Docker Executor (`docker_executor.py`)

Replace `mock_executor.py` with real execution:

- [ ] Create `docker_executor.py` alongside `mock_executor.py` (keep mock for testing)
- [ ] Spawn container with:
  ```
  docker run --rm
    --network=none            # no internet access
    --memory=256m             # memory limit
    --cpus=0.5                # CPU limit
    --pids-limit=50           # prevent fork bombs
    --read-only               # no filesystem writes
    --tmpfs /tmp:rw,size=10m  # writable /tmp only
    --timeout {EXEC_TIMEOUT}  # kill after N seconds
    -v /tmp/code:/code:ro     # mount user code read-only
    judge-runner-python:latest
    python /code/solution.py
  ```
- [ ] Capture stdout, stderr, exit code
- [ ] Map exit codes to status: 0=passed, 1=failed, 137=oom, 124=timeout
- [ ] Measure real execution time and memory usage
- [ ] Clean up container on completion (--rm)

### 3. Security Hardening

- [ ] Drop all Linux capabilities: `--cap-drop=ALL`
- [ ] No new privileges: `--security-opt=no-new-privileges`
- [ ] User namespace: run as non-root inside sandbox
- [ ] Filesystem: read-only except /tmp
- [ ] Network: completely disabled

### 4. Consumer Integration

- [ ] Add env var `EXECUTOR_MODE=docker|mock` to switch between executors
- [ ] Update `consumer.py` to use `docker_executor` when mode=docker
- [ ] Keep `mock_executor` as fallback for environments without Docker socket
- [ ] Configurable resource limits via env vars:
  - `SANDBOX_MEMORY_LIMIT=256m`
  - `SANDBOX_CPU_LIMIT=0.5`
  - `SANDBOX_TIMEOUT=10`
  - `SANDBOX_PIDS_LIMIT=50`

### 5. Test Cases

- [ ] Unit tests: executor returns correct status for each exit code
- [ ] Integration test: submit Python `print("hello")` → status=passed, output="hello"
- [ ] Security test: `import os; os.system("rm -rf /")` → no damage
- [ ] Timeout test: `while True: pass` → status=timeout
- [ ] OOM test: `x = [0] * 10**9` → status=oom_killed
- [ ] Fork bomb test: `import os; [os.fork() for _ in range(100)]` → limited by pids-limit

---

## Checklist

- [ ] `make dev-start` runs with Docker executor
- [ ] Submit Python code → real execution in sandbox
- [ ] Submit Java code → compiles and runs in sandbox
- [ ] Timeout/OOM correctly detected
- [ ] No network access from sandbox
- [ ] Mock executor still works with `EXECUTOR_MODE=mock`
