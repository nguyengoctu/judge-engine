# Sprint 9: Production Hardening

> **Duration**: Week 19-20
> **Phase**: 🟣 EKS
> **Goal**: Production-ready: observability, alerting, security, disaster recovery, cost optimization.

---

## 📚 DevOps Learning Objectives

| Topic | What to Learn | Why It Matters |
|-------|--------------|----------------|
| **Observability** | Metrics + Logs + Traces | Know what's happening in production |
| **Alerting** | AlertManager, Slack notifications | Get notified before users notice |
| **OpenTelemetry** | Distributed tracing across services | Trace submission flow end-to-end |
| **Centralized Logging** | EFK (Elasticsearch + Fluentd + Kibana) or Loki + Grafana | Aggregate, search, and analyze logs across all services |
| **Pod Security Standards** | Restricted mode, non-root, read-only FS | Harden runtime |
| **Disaster Recovery** | RPO, RTO, backup/restore, runbooks | Plan for the worst |
| **Cost Optimization** | Spot instances, right-sizing | Cloud bills add up |
| **SRE** | SLOs, SLIs, incident management | How pros run production |

---

## Tasks

### Monitoring + Alerting

- [ ] kube-prometheus-stack on EKS
- [ ] Grafana dashboards: cluster, API, queue, Worker execution, DB, cache
- [ ] Alerts → Slack: high error rate, pod restart loop, queue depth, CPU saturation

### Distributed Tracing

- [ ] OpenTelemetry auto-instrumentation on all services
- [ ] Trace the submission flow: Gateway → Submission Service → SQS → Worker → DB
- [ ] Export to AWS X-Ray or Jaeger

### Centralized Logging (EFK or Loki)

- [ ] Deploy Elasticsearch + Fluentd + Kibana (EFK) or Loki + Promtail + Grafana
- [ ] Fluentd/Promtail collects JSON logs from all pods
- [ ] Kibana/Grafana: search, filter, correlate logs across services
- [ ] Dashboard: filter by service, level, trace_id
- [ ] Log retention policies (7 days hot, 30 days cold)

### Security

- [ ] Pod Security Standards: `restricted`
- [ ] Non-root containers, read-only FS
- [ ] ECR image scanning, RBAC, audit logging

### WAF (Web Application Firewall)

- [ ] Deploy AWS WAF in front of ALB
- [ ] Rules: rate limiting, SQL injection protection, XSS protection
- [ ] AWS Managed Rules (Core Rule Set, Known Bad Inputs)
- [ ] Custom rule: block requests > 10 req/s per IP
- [ ] WAF logs → S3 → analyze blocked requests

### Chaos Engineering

- [ ] Install Litmus Chaos or Chaos Mesh on EKS
- [ ] Experiment 1: Kill random Worker pods → HPA recovers
- [ ] Experiment 2: Network latency between services → app degrades gracefully
- [ ] Experiment 3: DB failover (RDS reboot) → app reconnects
- [ ] Document results: what broke, what survived, lessons learned
- [ ] Create GameDay runbook for team chaos exercises

### Production Readiness

- [ ] PDB, rolling updates, topology spread, graceful shutdown
- [ ] DR runbooks: service down, DB restore, rollback, full redeploy
- [ ] Cost report: Spot instances for workers, right-sizing from Grafana data

---

## Checklist

- [ ] Prometheus + Grafana with dashboards
- [ ] Alerts reach Slack
- [ ] Traces visible across services
- [ ] Security hardened
- [ ] DR runbooks written and tested
- [ ] Cost report with recommendations
- [ ] ✅ **Production-ready system**

---

## 🎓 Portfolio Summary

| Skill | Evidence |
|-------|---------|
| **Docker** | Multi-stage builds, Compose, production setup |
| **CI/CD** | GitHub Actions, per-service builds, automated deploys |
| **Kubernetes** | Manifests, Helm, HPA, Network Policies, PDB |
| **Terraform** | Modules for VPC, ECS, EKS, RDS, ElastiCache, SQS |
| **AWS ECS** | Fargate, ALB, Cloud Map, CloudWatch |
| **AWS EKS** | Managed K8s, IRSA, ALB Controller, Cluster Autoscaler |
| **Monitoring** | Prometheus, Grafana, alerting |
| **Tracing** | OpenTelemetry distributed tracing |
| **Security** | Container hardening, IRSA, Pod Security Standards |
| **DR** | Backups, runbooks, RTO/RPO |
| **Cost** | Right-sizing, Spot instances, cost analysis |
