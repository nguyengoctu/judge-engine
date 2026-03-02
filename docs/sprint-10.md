# Sprint 10: Full Serverless (Bonus)

> **Duration**: Week 21-22
> **Phase**: ☁️ Serverless
> **Goal**: Deploy the same app as fully serverless — Lambda, API Gateway, S3, DynamoDB, SQS. Compare all 4 architectures.

---

## 📚 DevOps Learning Objectives

| Topic | What to Learn | Why It Matters |
|-------|--------------|----------------|
| **AWS Lambda** | Functions, layers, cold starts, concurrency | Serverless compute, pay-per-invocation |
| **API Gateway (AWS)** | HTTP API, routes, stages, throttling | Managed API layer, no server |
| **S3 + CloudFront** | Static hosting, OAC, cache invalidation | Serverless frontend hosting |
| **DynamoDB** | Tables, GSI, single-table design, on-demand | Serverless database, zero maintenance |
| **SQS → Lambda** | Event source mapping, batch size, concurrency | Auto-scale workers by queue depth |
| **SAM / CDK** | Infrastructure as Code for serverless | Deploy Lambda + API GW in one command |
| **Step Functions** | Orchestrate Lambda workflows | Complex submission flow orchestration |

---

## Architecture

```
CloudFront ──▶ S3 (Angular static files)

AWS API Gateway (HTTP API)
  ├── GET  /problems      → Lambda: problem-handler    → DynamoDB
  ├── GET  /problems/{id} → Lambda: problem-handler    → DynamoDB
  ├── POST /submissions   → Lambda: submission-handler → DynamoDB + SQS
  └── GET  /submissions/{id} → Lambda: submission-handler → DynamoDB

SQS (submissions queue)
  └── Lambda: worker-handler (triggered by SQS, concurrency = 10)
      → mock_execute() → update DynamoDB → done
```

---

## Tasks

### Frontend → S3 + CloudFront

- [ ] `ng build --prod` → upload to S3 bucket
- [ ] CloudFront distribution with OAC (Origin Access Control)
- [ ] Custom domain + ACM certificate
- [ ] Cache invalidation on deploy

### Lambda Functions

| Function | Runtime | Trigger | Connect to |
|----------|---------|---------|-----------|
| problem-handler | Python 3.12 | API Gateway | DynamoDB |
| submission-handler | Python 3.12 | API Gateway | DynamoDB + SQS |
| worker-handler | Python 3.12 | SQS event | DynamoDB |

- [ ] Reuse existing logic, wrap in Lambda handler
- [ ] Lambda Layers for shared dependencies
- [ ] Environment variables for table names, queue URL
- [ ] Worker concurrency limit = 10 (prevent runaway scaling)

### DynamoDB Tables

| Table | PK | SK | GSI |
|-------|----|----|-----|
| Problems | PK: `PROBLEM#<id>` | SK: `METADATA` | GSI1: `level-index` |
| Submissions | PK: `SUB#<id>` | SK: `METADATA` | GSI1: `status-index` |

- [ ] Seed problems via Lambda or script
- [ ] On-demand capacity (auto-scale)

### API Gateway (AWS HTTP API)

- [ ] Routes matching current API paths
- [ ] CORS configuration
- [ ] Throttling: 1000 req/s burst, 500 sustained
- [ ] Stage: `prod`

### SAM / CDK Deployment

- [ ] `template.yaml` (SAM) or CDK app defining all resources
- [ ] `sam deploy` / `cdk deploy` for one-command deployment
- [ ] CD pipeline: merge → build → deploy serverless stack

### Queue-Triggered Worker

- [ ] SQS event source mapping on worker Lambda
- [ ] Batch size = 1 (one submission per invocation)
- [ ] Reserved concurrency = 10
- [ ] DLQ for failed submissions
- [ ] mock_execute() runs inside Lambda (CPU/memory = Lambda config)

---

## The Big Comparison

After all architectures are running, write the comparison doc:

| Dimension | Docker Compose | ECS Fargate | EKS | Serverless |
|-----------|---------------|-------------|-----|-----------|
| Setup complexity | Low | Medium | High | Medium |
| Scaling | Manual | Auto (tasks) | Auto (HPA+CA) | Auto (instant) |
| Cold start | None | None | None | 1-5s |
| Cost at 0 traffic | Server cost | ~$30/mo | ~$75/mo | **$0** |
| Cost at 10K req/day | Server cost | ~$50/mo | ~$100/mo | ~$5/mo |
| Monitoring | docker stats | CloudWatch | Prometheus | CloudWatch |
| Deployment | docker compose | update-service | helm upgrade | sam deploy |
| Rollback | docker compose | Task revision | helm rollback | Alias shift |
| Vendor lock-in | None | AWS | Low (K8s) | High (Lambda) |
| DevOps complexity | Low | Medium | High | Low-Medium |

---

## Testing

| Type | What to Test |
|------|-------------|
| Deploy | `sam deploy` → all resources created |
| API | All endpoints respond correctly |
| Queue | POST submission → SQS → Lambda worker fires |
| Scale | Spam 1000 submissions → Lambda auto-scales to 10 concurrent |
| Cold start | Measure first invocation latency |
| Cost | Calculate monthly cost with AWS Calculator |

---

## Checklist

- [ ] Frontend hosted on S3 + CloudFront
- [ ] 3 Lambda functions deployed
- [ ] API Gateway routes working
- [ ] SQS triggers worker Lambda
- [ ] DynamoDB tables with seed data
- [ ] SAM/CDK template for one-command deploy
- [ ] Comparison doc: Docker Compose vs ECS vs EKS vs Serverless
- [ ] ✅ **Same app running 4 different ways**

---

## 🎓 Final Portfolio

Your repo now demonstrates the **same application** deployed 4 ways:
1. **Docker Compose** — local development
2. **ECS Fargate** — AWS container orchestration
3. **EKS** — Kubernetes on AWS
4. **Serverless** — Lambda + API Gateway + DynamoDB

This is an extremely strong DevOps portfolio piece.
