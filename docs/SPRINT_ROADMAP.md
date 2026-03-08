  # Online Judge — Sprint Roadmap

> **Goal**: Practice DevOps from local Docker Compose to AWS EKS.
> **Strategy**: Build 3 minimal core flows first (so services actually talk to each other), then deploy through all environments.
> **Target**: AWS SAA + DOP certified engineer portfolio project.

---

## Strategy: Core Flows → DevOps Pipeline

```
Sprint 0-1: Working App          Sprint 2-5: Local DevOps         Sprint 6-9: Cloud
┌──────────────────────┐    ┌──────────────────────┐    ┌──────────────────────┐
│ 0: Service skeletons  │    │ 2: Compose production │    │ 6: Terraform + AWS   │
│ 1: 3 core flows       │───▶│ 3: CI/CD (GitHub Act) │───▶│ 7: ECS Fargate       │
│    (services wired)   │    │ 3.5: CI/CD (Jenkins)  │    │ 8: EKS               │
│                       │    │ 4: K8s manifests      │    │ 9: Prod hardening    │
│                       │    │ 5: Helm + Monitoring  │    │                      │
└──────────────────────┘    └──────────────────────┘    └──────────────────────┘
```

**The 3 Core Flows** (Sprint 1) — minimum viable "blood vessels":

1. **Submission Flow (Async)**: Frontend → Submission Service → Queue → Worker → DB update
   - *Why*: Tests HPA — spam 10K requests, queue fills up, K8s auto-scales Workers
2. **Mock Execution (CPU/RAM burn)**: Worker runs a CPU/RAM-intensive fake job
   - *Why*: Tests Resource Limits — without limits, Worker eats all Node resources and crashes cluster
3. **Problem List + Status Polling**: GET problems from DB, GET submission status by ID
   - *Why*: Tests DB Migrations — deploy to RDS, schema must auto-create via Flyway

---

## Sprint Overview

| Sprint | Phase | Focus | Key DevOps Skill Practiced |
|--------|-------|-------|---------------------------|
| 0 ✅ | 🟢 Local | Service skeletons | Docker multi-stage builds, Compose |
| 1 ✅ | 🟢 Local | 3 core flows | Service integration, async messaging, DB migrations |
| 2 ✅ | 🟢 Local | Docker Compose production | Networking, NGINX proxy, logging, env management |
| 2.5 ✅ | 🟢 Local | Docker Sandbox Executor | Docker-in-Docker, container isolation, resource limits, security |
| 3 | 🟢 Local | CI/CD pipeline (GitHub Actions) | GitHub Actions, SonarCloud, Trivy, Dependabot |
| 3.5 | 🟢 Local | CI/CD pipeline (Jenkins) | Jenkins, Jenkinsfile, Webhook, OWASP Dependency-Check |
| 4 | 🔵 K8s | Kubernetes basics | Manifests, Deployments, Services, ConfigMaps, kubectl |
| 5 | 🔵 K8s | Helm + Monitoring | Helm charts, Prometheus, Grafana, HPA, load testing |
| 6 | 🟠 AWS | Terraform + AWS | IaC modules, VPC, ECR, RDS, ElastiCache, SQS |
| 7 | 🟠 AWS | Deploy ECS Fargate | ECS, ALB, Route53, ACM, CloudFront, Blue/Green, CD |
| 8 | 🟣 EKS | Deploy EKS | EKS, IRSA, ArgoCD, Canary deploy, Cluster Autoscaler |
| 9 | 🟣 EKS | Production hardening | EFK logging, OpenTelemetry, WAF, Chaos Engineering |
| 10 | ☁️ Serverless | Full serverless | Lambda, API Gateway, S3, DynamoDB, SQS, SAM/CDK |

---

## Architecture

```
              ┌──────────┐
              │ Frontend │ GET /problems, POST /submit, GET /status/:id
              └────┬─────┘
                   │
              ┌────▼─────┐
              │ API GW   │ Route to backend services
              └────┬─────┘
           ┌───────┴───────┐
     ┌─────▼─────┐   ┌─────▼──────────┐
     │ Problem   │   │ Submission     │──── POST → Queue
     │ Service   │   │ Service        │◄─── GET status
     └─────┬─────┘   └───────┬────────┘
           │                 │
     ┌─────▼─────┐   ┌──────▼──────┐   ┌────────────┐
     │Problem DB │   │  RabbitMQ/  │──▶│   Worker    │
     │(Postgres) │   │    SQS      │   │ (mock exec) │
     └───────────┘   └─────────────┘   └──────┬─────┘
                                              │
                                       ┌──────▼─────┐
                                       │Submission  │
                                       │DB (Postgres)│
                                       └────────────┘
```

## Definition of Done (every sprint)

- All services healthy via `make health`
- Tests pass via `make test`
- Documentation updated
- Git commit with meaningful message
