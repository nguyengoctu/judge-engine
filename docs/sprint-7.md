# Sprint 7: Deploy on AWS ECS Fargate

> **Duration**: Week 15-16
> **Phase**: 🟠 AWS ECS
> **Goal**: Full application running on ECS Fargate with managed AWS services.
> **Depends on**: Sprint 6 (CI/CD + Terraform infra ready)
> **Milestone**: ✅ App live on AWS via ECS

---

## 📚 DevOps Learning Objectives

| Topic | What to Learn | Resources |
|-------|--------------|-----------|
| **ECS Concepts** | Clusters, services, tasks, task definitions, launch types (Fargate vs EC2) | AWS ECS docs |
| **Fargate** | Serverless containers, no EC2 management, vCPU/memory sizing | AWS Fargate docs |
| **Task Definitions** | Container definitions, port mappings, env vars, log config, IAM roles | AWS Task Definition docs |
| **ECS Services** | Desired count, deployment types (rolling), circuit breaker, health checks | AWS ECS Service docs |
| **ALB** | Application Load Balancer, target groups, listener rules, health checks | AWS ALB docs |
| **Service Discovery** | AWS Cloud Map, DNS-based discovery between ECS services | AWS Cloud Map docs |
| **AWS SQS** | Standard vs FIFO queues, visibility timeout, DLQ, long polling | AWS SQS docs |
| **RDS** | PostgreSQL on RDS, parameter groups, security groups, backups | AWS RDS docs |
| **ElastiCache** | Redis on ElastiCache, cluster mode, failover, security | AWS ElastiCache docs |
| **Secrets Manager** | Store/rotate secrets, IAM access, ECS integration | AWS Secrets Manager docs |
| **CloudWatch Logs** | Log groups, log streams, insights queries, retention | AWS CloudWatch docs |

---

## Tasks

### Adapt Application for AWS

Changes needed when moving from Docker Compose to AWS managed services:

| Component | Docker Compose | AWS ECS | Code Change |
|-----------|---------------|---------|-------------|
| Queue | RabbitMQ (pika) | SQS (boto3) | Worker: replace pika with boto3 SQS client |
| Database | PostgreSQL container | RDS PostgreSQL | Connection string only (env var change) |
| Cache | Redis container | ElastiCache Redis | Connection string only (env var change) |
| Logs | stdout / Docker logs | CloudWatch Logs | awslogs log driver in task definition |
| Secrets | `.env` files | Secrets Manager | Reference secrets ARN in task definition |

**Key code change**: Worker must support both RabbitMQ (local) and SQS (AWS):
- Strategy pattern or environment-based toggle
- SQS: use `boto3` — `receive_message()`, `delete_message()`, long polling
- DLQ: configure `RedrivePolicy` on SQS queue

### Terraform — ECS Module (add to existing infra)

#### ECS Cluster

- [ ] Create Fargate cluster
- [ ] No EC2 instances to manage

#### Task Definitions (one per service)

| Service | CPU | Memory | Port | Log Group |
|---------|-----|--------|------|-----------|
| frontend | 256 | 512 | 80 | `/ecs/online-judge/frontend` |
| api-gateway | 512 | 1024 | 8080 | `/ecs/online-judge/api-gateway` |
| problem-service | 512 | 1024 | 8081 | `/ecs/online-judge/problem-service` |
| submission-service | 512 | 1024 | 8082 | `/ecs/online-judge/submission-service` |
| worker | 1024 | 2048 | 8083 | `/ecs/online-judge/worker` |

Each task definition includes:
- Container image from ECR (`<account>.dkr.ecr.<region>.amazonaws.com/online-judge/<service>:<tag>`)
- Environment variables from Secrets Manager and parameter store
- `awslogs` log driver configuration
- Health check command

#### ECS Services

| Service | Desired Count | Min Healthy | Max % | Health Check Path |
|---------|--------------|-------------|-------|-------------------|
| frontend | 1 | 50% | 200% | `/` |
| api-gateway | 2 | 50% | 200% | `/health` |
| problem-service | 1 | 50% | 200% | `/health` |
| submission-service | 2 | 50% | 200% | `/health` |
| worker | 2 | 50% | 200% | `/health` |

Features:
- Rolling update deployment
- Deployment circuit breaker (auto-rollback on failure)
- ECS Service auto-scaling based on CPU/SQS queue depth

#### ALB (Application Load Balancer)

| Listener Rule | Target Group | Path |
|---------------|-------------|------|
| Default | frontend | `/*` |
| Rule 1 | api-gateway | `/api/*` |

#### Service Discovery (AWS Cloud Map)

| Service | DNS Name | Used By |
|---------|----------|---------|
| problem-service | `problem-service.online-judge.local` | api-gateway |
| submission-service | `submission-service.online-judge.local` | api-gateway |
| worker | (no ingress needed) | — |

#### Networking & Security

| Security Group | Inbound | Outbound |
|---------------|---------|----------|
| ALB SG | 80, 443 from 0.0.0.0/0 | All to VPC |
| ECS Services SG | From ALB SG only | All to VPC |
| RDS SG | 5432 from ECS SG | — |
| ElastiCache SG | 6379 from ECS SG | — |

#### IAM Roles

| Role | Purpose | Permissions |
|------|---------|-------------|
| Task Execution Role | ECS pulls images, writes logs | ECR read, CloudWatch Logs write, Secrets Manager read |
| Task Role (per service) | App-level permissions | SQS (worker), RDS (services), ElastiCache (submission-service) |

### CD Pipeline Update

Add ECS deployment step to `cd.yml`:

| Step | Description |
|------|-------------|
| 1 | Build + push images to ECR (existing) |
| 2 | Update task definitions with new image tag |
| 3 | `aws ecs update-service --force-new-deployment` per service |
| 4 | Wait for service stability |
| 5 | Run smoke tests against ALB URL |
| 6 | Slack/Discord notification on success/failure |

Deploy flow: merge to main → build → push ECR → deploy staging → smoke tests → manual approval → deploy prod

---

## Testing

| Type | What to Test |
|------|-------------|
| Smoke | All `/health` endpoints return 200 via ALB |
| E2E | Full user flow through ALB URL |
| SQS | Submissions flow through SQS correctly (no RabbitMQ) |
| CloudWatch | Logs appearing in correct log groups |
| Auto-scaling | ECS service scales with CPU threshold |
| Circuit breaker | Bad deployment → auto-rollback |
| Load test (k6) | 100+ concurrent users, all requests served |

---

## Checklist

- [ ] ECS cluster running on Fargate
- [ ] All 5 services as ECS services with Fargate tasks
- [ ] ALB routes traffic correctly (`/` → frontend, `/api/*` → gateway)
- [ ] RDS PostgreSQL ×2 accessible from ECS tasks
- [ ] ElastiCache Redis accessible from submission-service + worker
- [ ] SQS replacing RabbitMQ — submissions flow correctly
- [ ] CloudWatch Logs receiving logs from all services
- [ ] Secrets stored in Secrets Manager, not env vars
- [ ] CD pipeline deploys to ECS on merge
- [ ] Smoke tests pass after deployment
- [ ] ✅ **App live on ECS Fargate**
