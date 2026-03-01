# Sprint 6: CI/CD + Terraform + ECR

> **Duration**: Week 13-14
> **Phase**: 🟠 AWS ECS
> **Goal**: CI/CD pipeline with GitHub Actions, Terraform for AWS infra, push images to ECR.
> **Depends on**: Sprint 5 (Helm + monitoring working locally)

---

## 📚 DevOps Learning Objectives

| Topic | What to Learn | Resources |
|-------|--------------|-----------|
| **GitHub Actions** | Workflows, jobs, steps, triggers, secrets, matrix builds, path filters | GitHub Actions docs |
| **CI Pipeline Design** | Lint → test → build → scan → deploy, fail fast, parallel jobs | CI/CD best practices |
| **Docker Image Building** | BuildKit, layer caching, multi-platform builds | Docker BuildKit docs |
| **Container Security Scanning** | Trivy for vulnerability detection in images | Trivy docs |
| **Terraform Basics** | HCL syntax, providers, resources, data sources, state | terraform.io learn |
| **Terraform Modules** | Reusable modules, input/output variables, module composition | Terraform module docs |
| **Terraform State** | Remote backend (S3), state locking (DynamoDB), import, refresh | Terraform state docs |
| **AWS VPC** | Subnets (public/private), NAT Gateway, Internet Gateway, route tables | AWS VPC docs |
| **AWS ECR** | Container registry, lifecycle policies, image scanning | AWS ECR docs |
| **AWS IAM** | Policies, roles, least privilege, OIDC for GitHub Actions | AWS IAM docs |

---

## Tasks

### CI Pipeline — GitHub Actions

#### Workflow: `ci.yml` (on Pull Request)

| Step | Job | Description |
|------|-----|-------------|
| 1 | **Detect changes** | Determine which services changed (path filters) |
| 2 | **Lint** | Java: Checkstyle, Python: ruff/flake8, Angular: ESLint, Terraform: `tflint` |
| 3 | **Unit tests** | Per-service: JUnit (Java), pytest (Python), Karma (Angular) |
| 4 | **Integration tests** | Testcontainers (Java), pytest with Docker (Python) |
| 5 | **Build Docker images** | Multi-stage build, tag with PR number |
| 6 | **Security scan** | Trivy scan on built images, fail on HIGH/CRITICAL |
| 7 | **Report** | Publish test results + coverage to PR comments |

Key design decisions:
- **Per-service CI**: Use path filters — only build/test services with changes
- **Matrix strategy**: Run Java services in parallel, Python services in parallel
- **Block merge**: Required status checks — all CI jobs must pass
- **Coverage gate**: Fail if coverage drops below threshold (JaCoCo for Java, coverage.py for Python)

#### Workflow: `cd.yml` (on merge to main)

| Step | Description |
|------|-------------|
| 1 | Build Docker images for changed services |
| 2 | Tag with `<service>:<git-sha>` and `<service>:latest` |
| 3 | Push to Amazon ECR |
| 4 | Trigger deployment (Sprint 7) |

### Amazon ECR Setup

| Repository | Lifecycle Policy |
|------------|-----------------|
| `online-judge/frontend` | Keep last 10 images |
| `online-judge/api-gateway` | Keep last 10 images |
| `online-judge/problem-service` | Keep last 10 images |
| `online-judge/submission-service` | Keep last 10 images |
| `online-judge/worker` | Keep last 10 images |
| `online-judge/runner-python` | Keep last 5 images |
| `online-judge/runner-javascript` | Keep last 5 images |
| `online-judge/runner-java` | Keep last 5 images |

### GitHub → AWS Authentication

- Use **OIDC Federation** (no long-lived AWS keys in GitHub Secrets)
- Create IAM Role with trust policy for GitHub OIDC provider
- Permissions: ECR push, ECS deploy (Sprint 7), EKS access (Sprint 8)

### Terraform

#### Module Structure

```
terraform/
├── modules/
│   ├── vpc/                    # VPC, subnets, NAT, IGW
│   ├── ecr/                    # ECR repositories
│   ├── ecs/                    # ECS cluster, services, tasks (Sprint 7)
│   ├── alb/                    # Application Load Balancer (Sprint 7)
│   ├── rds/                    # PostgreSQL instances
│   ├── elasticache/            # Redis cluster
│   ├── sqs/                    # SQS queues
│   └── eks/                    # EKS cluster (Sprint 8)
├── environments/
│   ├── ecs-staging/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── terraform.tfvars
│   └── eks-staging/            # Sprint 8
├── backend.tf                  # S3 + DynamoDB
└── versions.tf
```

#### Sprint 6 Scope (provision these now)

| Module | Resources Created |
|--------|------------------|
| **VPC** | VPC, 2 public subnets, 2 private subnets, NAT Gateway, Internet Gateway, route tables |
| **ECR** | 8 repositories with lifecycle policies |
| **RDS** | 2× PostgreSQL instances (problem-db, submission-db) in private subnets, security groups |
| **ElastiCache** | Redis cluster (single node for staging), security group |
| **SQS** | Main queue + Dead letter queue |

#### Terraform in CI

- [ ] `terraform fmt --check` on PR
- [ ] `terraform validate` on PR
- [ ] `tflint` on PR
- [ ] `terraform plan` output as PR comment (manual review required)
- [ ] `terraform apply` only via manual dispatch or merge to main

#### Remote State

| Component | Resource |
|-----------|----------|
| State file | S3 bucket: `online-judge-terraform-state` |
| State lock | DynamoDB table: `terraform-locks` |

---

## Testing

| Type | What to Test |
|------|-------------|
| CI | Push a PR → workflow triggers, tests run, results posted |
| CI | Failing test → merge blocked |
| CI | Only changed services are built (path filter verification) |
| CD | Merge to main → images built and pushed to ECR |
| ECR | Images visible in ECR console, tagged correctly |
| Terraform | `terraform plan` shows expected resources |
| Terraform | `terraform apply` creates VPC + ECR + RDS + ElastiCache + SQS |
| Terraform | `terraform destroy` tears down cleanly |
| Security | Trivy finds no HIGH/CRITICAL in base images |

---

## Checklist

- [ ] CI workflow runs on every PR
- [ ] Tests + coverage reports visible in PR
- [ ] Merge blocked if CI fails
- [ ] CD pushes images to ECR on merge to main
- [ ] GitHub OIDC → AWS IAM role works (no hardcoded keys)
- [ ] `terraform apply` creates: VPC, ECR, RDS ×2, ElastiCache, SQS
- [ ] Terraform state stored in S3 with DynamoDB locking
- [ ] `terraform plan` runs in CI on infrastructure PRs
- [ ] Branch protection enabled on `main`
