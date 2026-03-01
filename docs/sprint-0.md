# Sprint 0: Project Setup & Foundation

> **Duration**: Week 1-2
> **Goal**: Initialize monorepo, create service skeletons, wire everything up with Docker Compose.
> **End state**: `docker-compose up` boots all services, every `/health` returns 200, `make test` passes, Swagger UI accessible.

---

## Project Structure

```
online-judge/
├── services/
│   ├── frontend/                    # Angular 17+ SPA
│   ├── api-gateway/                 # Java Spring Boot — port 8080
│   ├── problem-service/             # Java Spring Boot — port 8081
│   ├── submission-service/          # Python FastAPI — port 8082
│   ├── worker/                      # Python — port 8083
│   └── code-runner/                 # Sandbox Dockerfiles
│       ├── python/
│       ├── javascript/
│       └── java/
├── database/
│   ├── problem-db/migrations/      # Flyway SQL migrations
│   └── submission-db/migrations/   # Alembic / raw SQL migrations
├── docker/
│   ├── docker-compose.yml           # Development
│   └── docker-compose.prod.yml      # Production (Sprint 3)
├── k8s/                             # Phase 2
├── helm/                            # Phase 2
├── terraform/                       # Phase 3
├── .github/workflows/               # Phase 3
├── docs/
├── Makefile
├── .editorconfig
├── .gitignore
└── README.md
```

---

## Service Specifications

### 1. API Gateway — Java Spring Boot

| Item | Detail |
|------|--------|
| **Port** | 8080 |
| **Role** | Single entry point, routes requests to downstream services |
| **Framework** | Spring Cloud Gateway (WebFlux) |
| **Routes** | `/api/problems/**` → Problem Service, `/api/submissions/**` + `/api/competitions/**` → Submission Service |
| **Features** | CORS config for Angular, request logging, error handling |
| **Dependencies** | spring-cloud-starter-gateway, spring-boot-starter-actuator, springdoc-openapi-starter-webflux-ui |

### 2. Problem Service — Java Spring Boot

| Item | Detail |
|------|--------|
| **Port** | 8081 |
| **Role** | CRUD for coding problems, code stubs, test cases |
| **Framework** | Spring Boot Web + JPA |
| **Database** | PostgreSQL (problem-db, port 5432) |
| **Migrations** | Flyway |
| **Layers** | Entity → Repository → Service → Controller |
| **Dependencies** | spring-boot-starter-web, spring-boot-starter-data-jpa, postgresql, flyway-core, springdoc-openapi-starter-webmvc-ui, testcontainers (test) |

### 3. Submission Service — Python FastAPI

| Item | Detail |
|------|--------|
| **Port** | 8082 |
| **Role** | Handle code submissions, check status, leaderboard |
| **Framework** | FastAPI + Uvicorn |
| **Database** | PostgreSQL (submission-db, port 5433) |
| **ORM** | SQLAlchemy 2.0 + Alembic |
| **Config** | pydantic-settings (`.env` based) |
| **Dependencies** | fastapi, uvicorn, sqlalchemy, psycopg2-binary, alembic, pydantic-settings, redis, pika, httpx, pytest |

### 4. Worker Service — Python

| Item | Detail |
|------|--------|
| **Port** | 8083 (health check only) |
| **Role** | Consume jobs from queue, orchestrate code execution in Docker containers |
| **Framework** | FastAPI (minimal, for health check) |
| **Dependencies** | fastapi, uvicorn, pika, docker (Python SDK), pytest |

### 5. Frontend — Angular

| Item | Detail |
|------|--------|
| **Port** | 4200 (dev) / 80 (prod via NGINX) |
| **Role** | SPA — problem list, code editor, submit, leaderboard |
| **Init** | `npx @angular/cli@17 new` with routing, SCSS |
| **UI Library** | Angular Material |
| **Production** | NGINX serves static files, proxies `/api/` to API Gateway |
| **Structure** | `core/` (services, interceptors), `features/` (problems, submission, leaderboard), `shared/` (components, pipes) |

---

## Database Schemas

### Problem DB (PostgreSQL, port 5432)

**Table: `problems`**

| Column | Type | Constraints |
|--------|------|-------------|
| id | UUID | PK, auto-generated |
| title | VARCHAR(255) | NOT NULL |
| question | TEXT | NOT NULL |
| level | VARCHAR(20) | NOT NULL, CHECK (easy/medium/hard) |
| tags | TEXT[] | DEFAULT '{}' |
| code_stubs | JSONB | NOT NULL — `{"python": "...", "java": "..."}` |
| test_cases | JSONB | NOT NULL — `[{"type": "array", "input": {...}, "output": ...}]` |
| created_at | TIMESTAMPTZ | DEFAULT NOW() |
| updated_at | TIMESTAMPTZ | DEFAULT NOW() |

**Indexes**: `level`, `tags` (GIN)
**Seed data**: Two Sum, FizzBuzz (with code stubs for Python, JavaScript, Java)

### Submission DB (PostgreSQL, port 5433)

**Table: `submissions`**

| Column | Type | Constraints |
|--------|------|-------------|
| id | UUID | PK, auto-generated |
| user_id | VARCHAR(255) | NOT NULL |
| problem_id | UUID | NOT NULL |
| code | TEXT | NOT NULL |
| language | VARCHAR(50) | NOT NULL, CHECK (python/javascript/java) |
| status | VARCHAR(20) | NOT NULL, DEFAULT 'pending', CHECK (pending/running/passed/failed/error) |
| results | JSONB | NULLABLE |
| execution_time | INTEGER | NULLABLE, milliseconds |
| memory_used | INTEGER | NULLABLE, KB |
| competition_id | UUID | NULLABLE |
| submitted_at | TIMESTAMPTZ | DEFAULT NOW() |

**Indexes**: `user_id`, `problem_id`, `status`, `competition_id` (partial)

**Table: `competitions`**

| Column | Type | Constraints |
|--------|------|-------------|
| id | UUID | PK |
| title | VARCHAR(255) | NOT NULL |
| description | TEXT | NULLABLE |
| start_time | TIMESTAMPTZ | NOT NULL |
| end_time | TIMESTAMPTZ | NOT NULL |
| problem_ids | UUID[] | NOT NULL |
| created_at | TIMESTAMPTZ | DEFAULT NOW() |

---

## Docker Setup

### Dockerfile Strategy

All services use **multi-stage builds**:

| Service | Build stage | Runtime stage | Notes |
|---------|-------------|---------------|-------|
| API Gateway | `maven:3.9-eclipse-temurin-21` | `eclipse-temurin:21-jre-alpine` | EXPOSE 8080 |
| Problem Service | `maven:3.9-eclipse-temurin-21` | `eclipse-temurin:21-jre-alpine` | EXPOSE 8081 |
| Submission Service | `python:3.11-slim` (pip install) | `python:3.11-slim` | EXPOSE 8082 |
| Worker | `python:3.11-slim` (pip install) | `python:3.11-slim` | EXPOSE 8083 |
| Frontend | `node:20-alpine` (ng build) | `nginx:alpine` | EXPOSE 80 |

All containers include a `HEALTHCHECK` instruction.

### Docker Compose Services

| Service | Image | Ports | Depends On |
|---------|-------|-------|------------|
| **problem-db** | postgres:16-alpine | 5432 | — |
| **submission-db** | postgres:16-alpine | 5433 | — |
| **redis** | redis:7-alpine | 6379 | — |
| **rabbitmq** | rabbitmq:3-management-alpine | 5672, 15672 | — |
| **problem-service** | Build | 8081 | problem-db |
| **submission-service** | Build | 8082 | submission-db, redis, rabbitmq |
| **worker** | Build | 8083 | rabbitmq, submission-db (+ Docker socket mount) |
| **api-gateway** | Build | 8080 | problem-service, submission-service |
| **frontend** | Build | 4200→80 | api-gateway |

All services use `condition: service_healthy` for dependency ordering.

**Volumes**: `problem-db-data`, `submission-db-data`, `redis-data`, `rabbitmq-data`

---

## Makefile Commands

| Command | Description |
|---------|-------------|
| `make dev` | Start all services with `docker compose up --build` |
| `make dev-detached` | Same but detached (`-d`) |
| `make stop` | Stop all services |
| `make clean` | Stop + remove volumes + remove images |
| `make build` | Build all images |
| `make test` | Run all unit tests (Java + Python + Angular) |
| `make test-java` | Run JUnit tests for api-gateway and problem-service |
| `make test-python` | Run pytest for submission-service and worker |
| `make test-frontend` | Run Angular Karma tests (headless Chrome) |
| `make status` | Show container status |
| `make logs` | Tail logs for all services |
| `make health` | Curl `/health` on all services |

---

## API Documentation (Swagger/OpenAPI)

Set up in Sprint 0 so all future endpoints are automatically documented.

### Access URLs

| Service | Swagger UI | OpenAPI Spec |
|---------|------------|-------------|
| API Gateway | http://localhost:8080/swagger-ui.html | http://localhost:8080/v3/api-docs |
| Problem Service | http://localhost:8081/swagger-ui.html | http://localhost:8081/v3/api-docs |
| Submission Service | http://localhost:8082/docs | http://localhost:8082/openapi.json |
| Worker Service | http://localhost:8083/docs | http://localhost:8083/openapi.json |

### Setup per Stack

- **Java (Spring Boot)**: Use `springdoc-openapi-starter-webmvc-ui` (Problem Service) and `springdoc-openapi-starter-webflux-ui` (API Gateway). Add `OpenApiConfig.java` class with title, version, description, server URLs.
- **Python (FastAPI)**: Built-in — configure `title`, `description`, `version`, `docs_url`, `openapi_tags` in the FastAPI constructor.
- **API Gateway aggregation**: Configure `springdoc.swagger-ui.urls` in `application.yml` to pull specs from Problem Service and Submission Service.

### Full API Contract

| Method | Path | Service | Sprint | Description |
|--------|------|---------|--------|-------------|
| `GET` | `/health` | All | 0 | Health check |
| `GET` | `/api/problems` | Problem | 1 | List problems (paginated) |
| `GET` | `/api/problems/{id}` | Problem | 1 | Get problem detail + code stub |
| `POST` | `/api/submissions` | Submission | 2 | Submit code solution |
| `GET` | `/api/submissions/{id}` | Submission | 2-3 | Poll submission status |
| `GET` | `/api/competitions/{id}/leaderboard` | Submission | 3 | Get competition leaderboard |

All endpoints must include: summary, description, parameter descriptions, example values, and response codes in their Swagger annotations.

---

## Testing — Sprint 0 Scope

Each service gets a basic health check unit test:

| Service | Framework | What to test |
|---------|-----------|-------------|
| API Gateway | JUnit 5 + MockMvc | `GET /health` → 200, body contains `status: UP` |
| Problem Service | JUnit 5 + MockMvc | `GET /health` → 200, body contains `status: UP` |
| Submission Service | pytest + TestClient | `GET /health` → 200, body contains `status: UP` |
| Worker | pytest + TestClient | `GET /health` → 200, body contains `status: UP` |
| Frontend | Karma | AppComponent renders successfully |

---

## Git Strategy

```
main          ← stable, deployable
  └── develop ← integration branch
       ├── feature/project-setup
       ├── feature/api-gateway-skeleton
       ├── feature/problem-service-skeleton
       ├── feature/submission-service-skeleton
       ├── feature/worker-skeleton
       ├── feature/frontend-skeleton
       ├── feature/docker-compose
       └── feature/database-schemas
```

### Key Config Files

- **`.gitignore`**: Java (`target/`, `.idea/`), Python (`__pycache__/`, `.venv/`), Angular (`node_modules/`, `dist/`), Docker, `.env` files, IDE files, OS files
- **`.editorconfig`**: 2-space indent default, 4-space for `.java` and `.py`, tabs for `Makefile`, LF line endings, UTF-8

---

## Checklist

- [ ] **Project Structure**
  - [ ] Create monorepo directory layout
  - [ ] Initialize Git repo, set up `main` and `develop` branches
  - [ ] Add `.gitignore`, `.editorconfig`, `README.md`

- [ ] **Service Skeletons**
  - [ ] API Gateway — Spring Boot app with `/health`
  - [ ] Problem Service — Spring Boot app with `/health`, JPA + Flyway configured
  - [ ] Submission Service — FastAPI app with `/health`, SQLAlchemy configured
  - [ ] Worker — Python app with `/health`
  - [ ] Frontend — Angular app with routing + Angular Material

- [ ] **API Documentation (Swagger)**
  - [ ] SpringDoc OpenAPI on Problem Service + API Gateway
  - [ ] FastAPI docs on Submission Service + Worker
  - [ ] Swagger UI accessible on all services
  - [ ] API Gateway aggregates all service specs

- [ ] **Database**
  - [ ] Problem DB schema + seed data
  - [ ] Submission DB schema

- [ ] **Docker**
  - [ ] Multi-stage Dockerfile per service
  - [ ] `docker-compose.yml` with all services + infra
  - [ ] Health checks on all containers

- [ ] **Testing**
  - [ ] Health check unit test per service
  - [ ] `make test` passes

- [ ] **Verification**
  - [ ] `docker-compose up` → all containers healthy
  - [ ] `make health` → all endpoints return 200
  - [ ] `make test` → all tests pass
  - [ ] RabbitMQ Management UI at http://localhost:15672
  - [ ] Swagger UI at http://localhost:8081/swagger-ui.html and http://localhost:8082/docs
  - [ ] API Gateway aggregated docs at http://localhost:8080/swagger-ui.html
