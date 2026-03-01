# Online Judge

A microservices-based online judge platform for coding challenges and competitions.

## Architecture

```
┌──────────┐     ┌─────────────┐     ┌─────────────────┐     ┌──────────────┐
│ Frontend │────▶│ API Gateway │────▶│ Problem Service │────▶│ PostgreSQL   │
│ (Angular)│     │ (Spring)    │     │ (Spring Boot)   │     │ (Problems DB)│
└──────────┘     └─────────────┘     └─────────────────┘     └──────────────┘
                       │
                       │              ┌────────────────────┐  ┌──────────────┐
                       └─────────────▶│ Submission Service │─▶│ PostgreSQL   │
                                      │ (FastAPI)          │  │ (Submissions)│
                                      └────────────────────┘  └──────────────┘
                                             │
                                      ┌──────┴──────┐
                                      │  RabbitMQ   │
                                      └──────┬──────┘
                                             │
                                      ┌──────┴──────┐     ┌───────────────┐
                                      │   Worker    │────▶│  Code Runner  │
                                      │  (Python)   │     │  (Containers) │
                                      └─────────────┘     └───────────────┘
                                             │
                                      ┌──────┴──────┐
                                      │    Redis    │  (Leaderboard)
                                      └─────────────┘
```

## Tech Stack

| Service | Language | Port |
|---------|----------|------|
| Frontend | Angular 17+ | 4200 |
| API Gateway | Java Spring Cloud Gateway | 8080 |
| Problem Service | Java Spring Boot | 8081 |
| Submission Service | Python FastAPI | 8082 |
| Worker | Python | 8083 |

## Quick Start

```bash
# Start all services
make dev

# Run tests
make test

# Check health
make health

# View logs
make logs

# Stop
make stop

# Clean (remove volumes + images)
make clean
```

## Service Ports

| Service | Port | URL |
|---------|------|-----|
| Frontend | 4200 | http://localhost:4200 |
| API Gateway | 8080 | http://localhost:8080 |
| Problem Service | 8081 | http://localhost:8081 |
| Submission Service | 8082 | http://localhost:8082 |
| Worker | 8083 | http://localhost:8083 |
| PostgreSQL (Problems) | 5432 | — |
| PostgreSQL (Submissions) | 5433 | — |
| Redis | 6379 | — |
| RabbitMQ | 5672 | — |
| RabbitMQ Management | 15672 | http://localhost:15672 |

## API Documentation

| Service | Swagger UI |
|---------|-----------|
| API Gateway | http://localhost:8080/swagger-ui.html |
| Problem Service | http://localhost:8081/swagger-ui.html |
| Submission Service | http://localhost:8082/docs |
| Worker | http://localhost:8083/docs |

## Project Structure

```
online-judge/
├── services/
│   ├── frontend/           # Angular SPA
│   ├── api-gateway/        # Spring Cloud Gateway
│   ├── problem-service/    # Spring Boot + JPA
│   ├── submission-service/ # FastAPI
│   ├── worker/             # Python worker
│   └── code-runner/        # Sandbox containers
├── database/               # SQL migrations
├── docker/                 # Docker Compose files
├── docs/                   # Sprint documentation
├── k8s/                    # Kubernetes manifests
├── helm/                   # Helm charts
└── terraform/              # Infrastructure as Code
```
