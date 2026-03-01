# Sprint 7: Deploy on AWS ECS Fargate

> **Duration**: Week 15-16
> **Phase**: 🟠 AWS
> **Goal**: Deploy working app to ECS Fargate with ALB, CloudWatch, SQS, automated CD.

---

## 📚 DevOps Learning Objectives

| Topic | What to Learn | Why It Matters |
|-------|--------------|----------------|
| **ECS/Fargate** | Tasks, services, cluster, serverless containers | AWS-native container orchestration |
| **ALB** | Load balancer, target groups, listener rules | Single entry point with routing |
| **Cloud Map** | DNS-based service discovery | How ECS services find each other |
| **CloudWatch** | Logs, metrics, insights | Centralized logging/monitoring |
| **Secrets Manager** | Store/rotate secrets, ECS integration | Production secret management |
| **SQS** | Replace RabbitMQ — Worker reads from SQS | Managed queue in AWS |

---

## Tasks

### Adapt Code for AWS

- [ ] Worker: add SQS client (env-based toggle: RabbitMQ local / SQS on AWS)
- [ ] Connection strings via env vars (pointing to RDS, ElastiCache, SQS)

### Terraform — ECS Module

- [ ] ECS Fargate cluster, task definitions, services
- [ ] ALB: `/` → frontend, `/api/*` → gateway
- [ ] Cloud Map for internal routing
- [ ] Security groups: ALB → ECS → RDS/ElastiCache

### CD Pipeline → ECS

- [ ] Merge → build → push ECR → update ECS → smoke test

### Test the Flows on ECS

- [ ] Submit code → SQS → Worker processes → status = passed
- [ ] Problems list from RDS
- [ ] CloudWatch shows logs from all services

---

## Checklist

- [ ] All services on ECS Fargate behind ALB
- [ ] 3 flows work via ALB URL
- [ ] SQS replacing RabbitMQ
- [ ] CloudWatch logs, Secrets Manager
- [ ] CD deploys on merge
- [ ] ✅ **App live on ECS**
