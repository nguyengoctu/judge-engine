# 🗺️ Online Judge — Sprint Roadmap

> **Goal**: Build a full Online Judge platform using microservices architecture, practicing DevOps end-to-end — from local Docker Compose to production AWS EKS.
> **Certifications**: AWS Solutions Architect Associate (SAA) ✅ | AWS DevOps Professional (DOP) ✅
> **Timeline**: 10 sprints × 2 weeks = ~5 months
> **Stack**: Angular (Frontend), Java Spring Boot (API Gateway, Problem Service), Python FastAPI (Submission Service, Worker)

---

## Functional Requirements

| # | Requirement | Sprint |
|---|-------------|--------|
| FR1 | Users can view a list of coding problems (paginated) | 1 |
| FR2 | Users can view a problem, code a solution in multiple languages (Monaco Editor) | 1 |
| FR3 | Users can submit their solution and get instant feedback (pass/fail per test case) | 2-3 |
| FR4 | Users can view a live leaderboard for competitions | 3 |

**Out of scope**: User authentication, profiles, payment, analytics, social features.
User identity is assumed via session/JWT.

## Non-Functional Requirements

| # | Requirement | How We Address It | Sprint |
|---|-------------|-------------------|--------|
| NFR1 | Prioritize availability over consistency | Multi-AZ deployment, health checks, auto-scaling | 4-9 |
| NFR2 | Isolation and security when running user code | Docker containers: read-only FS, no network, CPU/memory limits, Seccomp, 5s timeout | 2 |
| NFR3 | Return submission results within 5 seconds | Container execution with timeout, async queue for buffering | 2-3 |
| NFR4 | Scale to support competitions with 100,000 users | HPA, queue buffering, Redis leaderboard, ECS/EKS auto-scaling | 3-9 |

**Out of scope (for now)**: Fault tolerance, payment security, regular backups (addressed in Sprint 9).

---

## 🚀 Deployment Progression

```
Phase 1: Docker Compose (Sprint 0-3) → Phase 2: K8s Local (Sprint 4-5) → Phase 3: AWS ECS (Sprint 6-7) → Phase 4: AWS EKS (Sprint 8-9)
```

| Phase | Platform | DevOps Focus |
|-------|----------|-------------|
| **1** | Docker Compose (Local) | Containerization, multi-service orchestration |
| **2** | Kubernetes — Kind (Local) | K8s concepts, Helm, Prometheus, Grafana |
| **3** | AWS ECS Fargate | Terraform IaC, CI/CD pipelines, managed AWS services |
| **4** | AWS EKS | Full Kubernetes on cloud, production-grade operations |

---

## Microservices Architecture

```
Angular Frontend → API Gateway (Spring Boot) → Problem Service (Spring Boot) → PostgreSQL (Problems DB)
                                              → Submission Service (FastAPI) → PostgreSQL (Submissions DB)
                                                                             → RabbitMQ/SQS → Worker (Python) → Code Runner Containers
                                                                             → Redis (Leaderboard)
```

| Service | Language | Description |
|---------|----------|-------------|
| **Frontend** | Angular 17+ | SPA — Problem list, Monaco Editor, Submit, Leaderboard |
| **API Gateway** | Java Spring Boot | Routing, rate limiting, request validation |
| **Problem Service** | Java Spring Boot | CRUD problems, code stubs, test cases |
| **Submission Service** | Python FastAPI | Submit code, check status, leaderboard |
| **Worker Service** | Python | Consume queue, orchestrate code execution |
| **Code Runner** | Docker containers | Sandboxed execution per language (Python, JS, Java) |

---

## 🧪 Testing Strategy

> **Rule: No tests = no merge.**

| Type | Java | Python | Angular | When |
|------|------|--------|---------|------|
| Unit Test | JUnit 5 + Mockito | pytest | Jasmine + Karma | Every PR |
| Integration | Testcontainers | pytest + Testcontainers | — | Every PR |
| API Test | MockMvc | httpx + pytest | — | Every PR |
| E2E | — | — | Cypress / Playwright | Every sprint |
| Load Test | — | k6 / Locust | — | Sprint 5+ |

Coverage target: ≥ 80% business logic, ≥ 60% overall.

---

# 🟢 Phase 1: Docker Compose (Sprint 0-3)

## Sprint 0: Project Setup & Foundation (Week 1-2)

**Goal**: Monorepo, service skeletons, Docker Compose running locally.

- [ ] Monorepo structure: `services/`, `database/`, `docker/`, `k8s/`, `helm/`, `terraform/`
- [ ] Service skeletons with health endpoints: API Gateway (8080), Problem Service (8081), Submission Service (8082), Worker, Frontend
- [ ] Database schemas: `problems` + `submissions` tables (PostgreSQL)
- [ ] Dockerfile per service (multi-stage builds)
- [ ] `docker-compose.yml` — 6 services + 2 DBs + Redis + RabbitMQ
- [ ] Test framework setup: JUnit 5, pytest, Karma
- [ ] Health check unit tests, `Makefile` (`make dev/build/test`)

**Done when**: `docker-compose up` → all healthy, `make test` → pass

---

## Sprint 1: Problem Service & Frontend (Week 3-4)

**Goal**: Full Problem CRUD API + Frontend with code editor.

- [ ] Problem Service: `GET /api/problems` (paginated), `GET /api/problems/{id}` (detail + code stub)
- [ ] API Gateway: route forwarding, CORS configuration
- [ ] Frontend: Problem List + Problem Detail (Monaco Editor + language selector)
- [ ] Seed 10-15 sample problems via Flyway migrations
- [ ] **Tests**: Unit (Mockito), Integration (Testcontainers), API (MockMvc), Frontend components (Karma)

**Done when**: Frontend list/detail works, ≥ 80% coverage on Problem Service

---

## Sprint 2: Code Execution Engine (Week 5-6)

**Goal**: Sandboxed containers for secure code execution.

- [ ] Code Runner images: `runner-python`, `runner-javascript`, `runner-java`
- [ ] Test harness per language: JSON deserialize → run user code → compare output
- [ ] Security: read-only FS, CPU/memory limits, no network, 5s timeout, Seccomp profile
- [ ] Worker: spawn container (Docker SDK for Python), collect results, cleanup
- [ ] `POST /api/submissions` — synchronous mode
- [ ] **Tests**: Worker unit/integration, Code Runner self-tests, security tests (infinite loop, memory bomb, network escape)

**Done when**: Submit → pass/fail < 5s, malicious code killed properly, **still runs via `docker-compose up`**

---

## Sprint 3: Queue, Leaderboard & Compose Production (Week 7-8)

**Goal**: Async processing + real-time leaderboard + production-ready Docker Compose.

- [ ] RabbitMQ integration: async submit, dead letter queue, retry (max 3)
- [ ] Redis sorted set leaderboard: `ZADD` on pass, `ZRANGE` for ranking
- [ ] Frontend: polling submission status, leaderboard auto-refresh every 5s
- [ ] `docker-compose.prod.yml`: restart policies, named volumes, resource limits, health checks
- [ ] NGINX reverse proxy container for unified entry point
- [ ] **Tests**: Queue unit/integration, leaderboard tests, **E2E (Cypress)**, compose deploy verification

**Done when**: ✅ **Complete app running via Docker Compose (production mode)**, async + leaderboard working

---

# 🔵 Phase 2: Kubernetes Local (Sprint 4-5)

## Sprint 4: K8s Manifests & Local Deploy (Week 9-10)

**Goal**: Write K8s manifests, deploy on Kind cluster locally.

- [ ] Deployments: api-gateway, problem-service, submission-service, worker, frontend
- [ ] StatefulSets: postgres ×2, rabbitmq, redis
- [ ] Services (ClusterIP/NodePort), ConfigMaps, Secrets, PVCs
- [ ] Ingress (NGINX): `/api/*` → gateway, `/` → frontend
- [ ] `kind create cluster` → `kubectl apply -f k8s/`
- [ ] **Tests**: All pods Running, E2E through K8s, pod restart recovery test

**Done when**: `kubectl get pods` → all Running, app fully functional on Kind

---

## Sprint 5: Helm, HPA & Monitoring (Week 11-12)

**Goal**: Helm charts, auto-scaling, Prometheus + Grafana.

- [ ] Helm chart with `values-dev.yaml`, `values-ecs.yaml`, `values-eks.yaml`
- [ ] HPA for API Gateway, Submission Service, Worker
- [ ] Resource requests/limits, liveness/readiness probes, Network Policies
- [ ] Prometheus + Grafana (kube-prometheus-stack)
- [ ] Dashboards: API latency, queue depth, pod resources, execution time
- [ ] **Tests**: `helm lint`, load test (k6) → verify HPA triggers

**Done when**: `helm install` succeeds, HPA auto-scales under load, Grafana shows live metrics

---

# 🟠 Phase 3: AWS ECS (Sprint 6-7)

## Sprint 6: CI/CD + Terraform + ECR (Week 13-14)

**Goal**: CI/CD pipeline with GitHub Actions, Terraform for AWS infra, ECR setup.

- [ ] **CI (GitHub Actions)**: lint → unit tests → integration tests → Docker build → Trivy security scan
- [ ] Per-service CI with path filters, test/coverage reports in PR, block merge on failure
- [ ] **CD**: merge to main → build → tag `<service>:<sha>` → push to ECR
- [ ] **Terraform modules**: VPC (2 AZs, public + private subnets), ECR, ECS cluster, ALB, RDS ×2, ElastiCache, SQS
- [ ] S3 remote backend + DynamoDB locking, `terraform validate` + `tflint` in CI

**Done when**: PR triggers CI automatically, `terraform apply` provisions infra, images in ECR

---

## Sprint 7: Deploy on AWS ECS Fargate (Week 15-16)

**Goal**: Full deployment on ECS Fargate with managed AWS services.

- [ ] ECS Cluster (Fargate), Task Definitions per service, ECS Services with health checks
- [ ] ALB + Target Groups, Service Discovery via AWS Cloud Map
- [ ] **Managed services**: RDS PostgreSQL ×2, ElastiCache Redis, SQS (replacing RabbitMQ)
- [ ] Adapt Worker: RabbitMQ → SQS (boto3)
- [ ] Security Groups, IAM task roles, Secrets Manager
- [ ] CloudWatch Logs, Route53 + ACM TLS (optional)
- [ ] **CD Pipeline**: merge → ECR → deploy ECS staging → manual approval → production
- [ ] **Tests**: Smoke tests post-deploy, E2E on staging, load test on ECS

**Done when**: ✅ **App running on ECS Fargate** via public ALB URL, full CI/CD operational

---

# 🟣 Phase 4: AWS EKS (Sprint 8-9)

## Sprint 8: Migrate to EKS (Week 17-18)

**Goal**: Provision EKS, deploy with Helm, reuse managed services from ECS phase.

- [ ] Terraform EKS module (managed node groups), reuse existing VPC/RDS/ElastiCache/SQS modules
- [ ] IRSA (IAM Roles for Service Accounts)
- [ ] Install: AWS ALB Ingress Controller, External Secrets Operator, Cluster Autoscaler
- [ ] `helm install -f values-eks.yaml`
- [ ] **CD Pipeline**: merge → ECR → `helm upgrade` on EKS staging → approval → production
- [ ] **Tests**: Smoke, E2E on staging, rollback test (`helm rollback` < 2 min), ECS vs EKS comparison

**Done when**: ✅ **App running on EKS** via ALB, CI/CD works, Helm rollback verified

---

## Sprint 9: Production Hardening & Observability (Week 19-20)

**Goal**: Production-grade monitoring, security, and disaster recovery.

- [ ] Prometheus + Grafana on EKS, CloudWatch integration
- [ ] Alerting rules: error rate > 5%, pod restarts > 3, queue depth > 1000, CPU > 80%
- [ ] Distributed tracing (OpenTelemetry)
- [ ] Pod Security Standards, Network Policies (Calico), container image scanning
- [ ] PDB (Pod Disruption Budget), rolling update strategy
- [ ] DB backups (RDS automated + manual), Terraform state backup (S3 versioning)
- [ ] DR runbook documented & tested
- [ ] Cost optimization: spot instances, right-sizing, ECS vs EKS cost comparison

**Done when**: Monitoring + alerting operational, DR tested, cost report completed

---

## 📊 DevOps Skills per Sprint

| Sprint | Phase | Key DevOps Skills |
|--------|-------|-------------------|
| 0 | Compose | Docker, Compose, Multi-stage builds |
| 1 | Compose | Microservice development, API Gateway, Testing |
| 2 | Compose | Container security, Resource isolation |
| 3 | Compose | Message queues, Redis, NGINX proxy, Production Compose |
| 4 | K8s | K8s manifests, Deployments, StatefulSets, Ingress |
| 5 | K8s | Helm, HPA, Prometheus, Grafana |
| 6 | ECS | GitHub Actions CI/CD, Terraform, ECR |
| 7 | ECS | ECS Fargate, ALB, RDS, ElastiCache, SQS, CloudWatch |
| 8 | EKS | EKS, Helm on cloud, IRSA, Cluster Autoscaler |
| 9 | EKS | Monitoring, Security, DR, Cost optimization |

## 🛠️ Tech Stack per Phase

| Layer | Compose | K8s Local | ECS | EKS |
|-------|---------|-----------|-----|-----|
| Orchestration | Docker Compose | Kind | ECS Fargate | EKS |
| Database | PostgreSQL (Docker) | PostgreSQL (K8s) | RDS | RDS |
| Cache | Redis (Docker) | Redis (K8s) | ElastiCache | ElastiCache |
| Queue | RabbitMQ (Docker) | RabbitMQ (K8s) | SQS | SQS |
| Proxy/LB | NGINX (Docker) | K8s Ingress | ALB | ALB |
| Registry | Local | Local | ECR | ECR |
| IaC | docker-compose.yml | K8s manifests | Terraform | Terraform |
| Monitoring | Docker logs | Prometheus+Grafana | CloudWatch | CloudWatch+Prometheus |

---

> **AWS Cost Estimate** (Phase 3-4): ECS + RDS ×2 + ElastiCache + EKS running together → ~$300-500/month. Always `terraform destroy` when not in use!
