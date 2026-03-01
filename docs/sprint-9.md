# Sprint 9: Production Hardening & Observability

> **Duration**: Week 19-20
> **Phase**: 🟣 AWS EKS
> **Goal**: Production-grade monitoring, alerting, security, disaster recovery, cost optimization.
> **Depends on**: Sprint 8 (app running on EKS)
> **Milestone**: ✅ Production-ready system

---

## 📚 DevOps Learning Objectives

| Topic | What to Learn | Resources |
|-------|--------------|-----------|
| **Observability Pillars** | Metrics, Logs, Traces — the three pillars | observability.io |
| **Prometheus on EKS** | kube-prometheus-stack, ServiceMonitor, PrometheusRule | Prometheus Operator docs |
| **Grafana Dashboards** | Build dashboards, variables, templating, sharing | Grafana docs |
| **Alerting** | AlertManager, routing, receivers (Slack/email), silence/inhibit | AlertManager docs |
| **OpenTelemetry** | Instrumentation, exporters, collectors, context propagation | opentelemetry.io |
| **Distributed Tracing** | Trace spans across microservices, find bottlenecks | Jaeger or X-Ray docs |
| **Pod Security Standards** | Restricted, Baseline, Privileged levels | K8s PSS docs |
| **Network Policies** | Calico on EKS, ingress/egress rules, deny-all default | Calico docs |
| **Container Image Security** | Trivy scanning, distroless images, non-root users | Container security best practices |
| **Disaster Recovery** | RPO, RTO, backup strategies, failover procedures | AWS Well-Architected |
| **Cost Optimization** | Spot instances, right-sizing, savings plans, cost explorer | AWS Cost Management docs |
| **Incident Management** | Runbooks, on-call, post-mortems, SLOs/SLIs | SRE book (Google) |

---

## Tasks

### Observability — Prometheus + Grafana on EKS

- [ ] Install kube-prometheus-stack via Helm on EKS
- [ ] Configure persistent storage for Prometheus (EBS volumes)
- [ ] Integrate with CloudWatch for EKS control plane logs

#### Application Metrics

| Service | Metrics Library | Key Metrics |
|---------|----------------|-------------|
| API Gateway (Java) | Micrometer + Prometheus | `http_server_requests_seconds`, `jvm_memory_used_bytes` |
| Problem Service (Java) | Micrometer + Prometheus | `http_server_requests_seconds`, `db_query_duration` |
| Submission Service (Python) | prometheus_client | `http_request_duration_seconds`, `submissions_total`, `queue_publish_duration` |
| Worker (Python) | prometheus_client | `code_execution_duration_seconds`, `submissions_processed_total`, `container_timeout_total` |

#### Grafana Dashboards

| Dashboard | Panels |
|-----------|--------|
| **Cluster Overview** | Node count, pod count, CPU/memory utilization, pod restarts |
| **API Performance** | Request rate, latency percentiles (p50/p95/p99), error rate, status codes |
| **Submission Pipeline** | SQS queue depth, submissions/min, processing time, pass/fail ratio, timeouts |
| **Code Execution** | Execution time histogram, memory usage per language, container create/destroy rate |
| **Database** | RDS CPU, connections, read/write latency, storage used |
| **Cache** | ElastiCache hit rate, memory usage, evictions, connections |

### Alerting

| Alert | Condition | Severity | Action |
|-------|-----------|----------|--------|
| High Error Rate | API 5xx rate > 5% for 5 min | Critical | Page on-call |
| Pod Restart Loop | Pod restarts > 3 in 10 min | Warning | Investigate logs |
| Queue Depth High | SQS messages > 1000 for 5 min | Warning | Check worker scaling |
| CPU Saturation | Pod CPU > 80% for 10 min | Warning | Review HPA settings |
| Memory Near Limit | Pod memory > 85% for 5 min | Warning | Review resource limits |
| Database Connections | RDS connections > 80% max | Critical | Connection pool issue |
| DLQ Messages | DLQ count > 0 | Warning | Investigate failed submissions |
| Certificate Expiry | TLS cert expires in < 14 days | Warning | Renew ACM cert |

Alert routing:
- Critical → Slack `#alerts-critical` + email
- Warning → Slack `#alerts-warning`

### Distributed Tracing (OpenTelemetry)

- [ ] Instrument all services with OpenTelemetry SDKs:
  - Java: `opentelemetry-javaagent` (auto-instrumentation)
  - Python: `opentelemetry-instrument` (auto-instrumentation)
- [ ] Deploy OpenTelemetry Collector on EKS (DaemonSet)
- [ ] Export traces to AWS X-Ray or Jaeger
- [ ] Trace a full request: Frontend → Gateway → Problem Service → DB
- [ ] Trace submission flow: Gateway → Submission Service → SQS → Worker → Runner Container

### Security Hardening

| Area | Action |
|------|--------|
| **Pod Security** | Enforce `restricted` Pod Security Standard on namespace |
| **Non-root containers** | All containers run as non-root user |
| **Read-only root FS** | All app containers use read-only root filesystem |
| **Network Policies** | Calico deny-all default, explicit allow rules per service |
| **Image Scanning** | Trivy in CI (existing) + ECR scanning enabled |
| **RBAC** | Least-privilege ClusterRoles, no cluster-admin for apps |
| **Audit Logging** | EKS audit logs → CloudWatch |
| **Secrets Rotation** | Secrets Manager auto-rotation for DB passwords |

### Production Readiness

| Feature | Configuration |
|---------|--------------|
| **PDB** (Pod Disruption Budget) | `minAvailable: 1` for api-gateway, submission-service |
| **Rolling Update** | `maxUnavailable: 0`, `maxSurge: 1` |
| **Topology Spread** | Spread pods across AZs |
| **Graceful Shutdown** | `terminationGracePeriodSeconds: 30`, handle SIGTERM in apps |
| **Resource Quotas** | Limit total namespace resources to prevent runaway |

### Disaster Recovery

| Component | Backup Strategy | RPO | RTO |
|-----------|----------------|-----|-----|
| RDS PostgreSQL | Automated daily backups + manual snapshot before deploy | 24 hours (auto) / 0 (manual) | 30 min (point-in-time restore) |
| ElastiCache Redis | Daily snapshots | 24 hours | 15 min |
| Terraform State | S3 versioning enabled | 0 (every change) | 5 min |
| Application Config | Git repo (Helm values, K8s manifests) | 0 | 10 min (redeploy) |
| Docker Images | ECR (cross-region replication optional) | 0 | 5 min |

#### DR Runbook Topics

1. Service is down — check pods, logs, health endpoints
2. Database is corrupted — point-in-time restore from RDS backup
3. Bad deployment — `helm rollback`
4. Node failure — Cluster Autoscaler replaces node
5. Full cluster failure — Terraform recreate + Helm install
6. Region failure — (document but out of scope for this project)

### Cost Optimization

| Strategy | Estimated Savings |
|----------|-------------------|
| **Spot Instances** for worker nodes | 60-70% on EC2 costs |
| **Right-sizing** based on actual CPU/memory usage | 20-30% |
| **Scale-to-zero** worker during off-hours (CronHPA) | Variable |
| **Reserved Instances** for RDS if running long-term | 30-40% |
| **S3 lifecycle policies** for old CloudWatch logs | Minor |

#### Cost Report Structure

| Resource | Monthly Cost (On-Demand) | With Optimization |
|----------|------------------------|-------------------|
| EKS Cluster | $73 | $73 (fixed) |
| EC2 Nodes (3× t3.medium) | ~$100 | ~$40 (spot) |
| RDS ×2 (db.t3.micro) | ~$30 | ~$20 (reserved) |
| ElastiCache (cache.t3.micro) | ~$15 | ~$10 (reserved) |
| ALB | ~$20 | $20 |
| SQS | ~$1 | $1 |
| CloudWatch | ~$10 | $10 |
| **Total** | **~$250** | **~$175** |

---

## Testing

| Type | What to Test |
|------|-------------|
| Monitoring | Grafana dashboards populated with live data |
| Alerting | Simulate high error rate → alert fires in Slack |
| Tracing | Full request trace visible in X-Ray/Jaeger |
| Security | Pod Security Standards enforced, non-root verified |
| Network Policies | Worker cannot reach frontend directly |
| PDB | `kubectl drain node` → PDB prevents all pods terminating |
| DR — DB restore | Point-in-time restore from RDS backup |
| DR — Rollback | `helm rollback` restores previous version |
| DR — Full redeploy | `terraform apply` + `helm install` from scratch |
| Cost | Cost Explorer matches estimates |

---

## Checklist

- [ ] Prometheus + Grafana running on EKS with persistent storage
- [ ] All 6 Grafana dashboards created and populated
- [ ] Alerting rules configured, test alert delivered to Slack
- [ ] OpenTelemetry tracing across all services
- [ ] Pod Security Standards enforced (`restricted`)
- [ ] Network Policies deny unauthorized traffic
- [ ] Image scanning enabled in CI + ECR
- [ ] PDB configured for critical services
- [ ] DR runbook written and tested (DB restore, rollback, redeploy)
- [ ] Cost report created with optimization recommendations
- [ ] Spot instances configured for worker nodes
- [ ] ✅ **Production-ready system**

---

## 🎓 Final Portfolio Deliverables

After Sprint 9, your GitHub repo demonstrates:

| Skill | Evidence |
|-------|---------|
| **Containerization** | Multi-stage Dockerfiles, security-hardened runner containers |
| **Docker Compose** | Full app orchestration, production compose |
| **Kubernetes** | K8s manifests, Helm charts, HPA, Network Policies, PDB |
| **CI/CD** | GitHub Actions with per-service builds, test gates, automated deploys |
| **IaC** | Terraform modules for VPC, ECS, EKS, RDS, ElastiCache, SQS |
| **AWS ECS** | Fargate services, ALB, Cloud Map service discovery |
| **AWS EKS** | Managed K8s, IRSA, ALB Controller, Cluster Autoscaler |
| **Monitoring** | Prometheus, Grafana dashboards, alerting rules |
| **Tracing** | OpenTelemetry instrumentation, distributed tracing |
| **Security** | Container security, IRSA, Pod Security Standards, Network Policies |
| **Testing** | Unit, integration, E2E, load tests, security tests |
| **DR** | Backup strategies, runbooks, RTO/RPO documented |
| **Cost Management** | Right-sizing, Spot instances, cost analysis |
