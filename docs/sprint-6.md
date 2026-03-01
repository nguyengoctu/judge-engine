# Sprint 6: Terraform & AWS Foundations

> **Duration**: Week 13-14
> **Phase**: 🟠 AWS
> **Goal**: Provision AWS infrastructure with Terraform — VPC, ECR, RDS, ElastiCache, SQS.

---

## 📚 DevOps Learning Objectives

| Topic | What to Learn | Why It Matters |
|-------|--------------|----------------|
| **Terraform** | HCL, providers, resources, state, modules | Industry-standard IaC |
| **AWS VPC** | Subnets, NAT, IGW, route tables | Foundation of AWS networking |
| **AWS ECR** | Container registry, lifecycle policies | Where images live in AWS |
| **AWS RDS** | Managed PostgreSQL, security groups | Replace self-managed Postgres |
| **AWS ElastiCache** | Managed Redis | Replace self-managed Redis |
| **AWS SQS** | Standard queues, DLQ | Replace RabbitMQ in AWS |
| **AWS IAM** | OIDC for GitHub Actions, least privilege | No hardcoded AWS keys |

---

## Tasks

### Terraform Modules

| Module | Resources |
|--------|-----------|
| VPC | VPC, 2 public + 2 private subnets, NAT, IGW |
| ECR | 5 repos with lifecycle policies |
| RDS | 2× PostgreSQL (private subnets) |
| ElastiCache | Redis single node |
| SQS | Submissions queue + DLQ |

### Key DevOps moment: DB Migration

When RDS starts empty, Flyway in Problem Service auto-creates schema + seed data. This is the Stateful Flow (Sprint 1) paying off — no manual SQL needed.

### GitHub OIDC → AWS

- [ ] No hardcoded AWS keys
- [ ] CD pushes images to ECR
- [ ] Terraform plan in CI, apply on merge

---

## Checklist

- [ ] `terraform apply` creates VPC, ECR, RDS ×2, ElastiCache, SQS
- [ ] State in S3 with DynamoDB locking
- [ ] CD pushes to ECR, Terraform CI on infra PRs
- [ ] OIDC auth (no long-lived keys)
