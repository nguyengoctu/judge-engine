# Sprint 0: Project Skeleton ✅

> **Duration**: Week 1-2
> **Phase**: 🟢 Local
> **Status**: COMPLETED
> **Goal**: Monorepo with 5 service skeletons, all running via Docker Compose.

---

## 📚 DevOps Concepts Learned

| Topic | What You Practiced |
|-------|-------------------|
| **Docker Multi-stage Builds** | Separate build and runtime stages to minimize image size |
| **Docker Compose** | Orchestrate 9 containers with dependencies and health checks |
| **Monorepo Structure** | Organize multiple services in a single repository |
| **Health Checks** | Every service exposes `/health` for monitoring |
| **Makefile** | Standardized commands for dev workflow (`make dev`, `make test`) |

## What Was Built

- 5 service skeletons (API Gateway, Problem Service, Submission Service, Worker, Frontend)
- 2 PostgreSQL databases with seed data
- Redis + RabbitMQ infrastructure
- 5 multi-stage Dockerfiles
- Docker Compose with health checks and dependency ordering
- Makefile with Docker-based testing (no local installs)
- Swagger/OpenAPI on all services

## Verification

- `make dev` → all 9 containers start and become healthy
- `make test` → Python tests pass via Docker
- `make health` → all `/health` endpoints return 200
- `localhost:4200` → Angular default page
- `localhost:8082/docs` → FastAPI Swagger UI
