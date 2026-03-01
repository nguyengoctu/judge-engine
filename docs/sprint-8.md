# Sprint 8: Migrate to AWS EKS

> **Duration**: Week 17-18
> **Phase**: 🟣 AWS EKS
> **Goal**: Provision EKS cluster, deploy app with Helm, compare with ECS.
> **Depends on**: Sprint 7 (app running on ECS)
> **Milestone**: ✅ App live on EKS

---

## 📚 DevOps Learning Objectives

| Topic | What to Learn | Resources |
|-------|--------------|-----------|
| **EKS** | AWS managed Kubernetes, control plane, managed node groups | AWS EKS docs |
| **EKS vs ECS** | When to use which: flexibility vs simplicity, K8s ecosystem vs AWS-native | AWS comparison guides |
| **Managed Node Groups** | Auto-scaling groups, instance types, AMIs, node labels | AWS EKS Node Groups docs |
| **IRSA** | IAM Roles for Service Accounts — pod-level AWS permissions | AWS IRSA docs |
| **ALB Ingress Controller** | AWS Load Balancer Controller, Ingress → ALB mapping | aws-lb-controller docs |
| **External Secrets Operator** | Sync AWS Secrets Manager → K8s Secrets automatically | ESO docs |
| **Cluster Autoscaler** | Scale node groups based on pending pods | Cluster Autoscaler docs |
| **Helm on Cloud** | Same chart, different values file — `values-eks.yaml` | Helm best practices |
| **EKS Add-ons** | CoreDNS, kube-proxy, vpc-cni, EBS CSI driver | AWS EKS add-ons docs |

---

## Tasks

### Terraform — EKS Module

Add to existing Terraform codebase (reuse VPC, RDS, ElastiCache, SQS modules):

| Resource | Configuration |
|----------|--------------|
| EKS Cluster | K8s version 1.29+, private endpoint, public endpoint (staging only) |
| Managed Node Group | t3.medium, min 2 / max 5 nodes, 50Gi disk |
| OIDC Provider | Enable IRSA for pod-level IAM |
| EKS Add-ons | vpc-cni, CoreDNS, kube-proxy, EBS CSI driver |
| Security Groups | Cluster SG, node SG, allow nodes → RDS/ElastiCache |

New environment directory:

```
terraform/environments/
├── ecs-staging/         # Existing from Sprint 7
├── eks-staging/         # New
│   ├── main.tf          # Compose modules: vpc, eks, rds, elasticache, sqs, ecr
│   ├── variables.tf
│   ├── outputs.tf
│   └── terraform.tfvars
└── eks-prod/            # Future
```

### Install EKS Components

After `terraform apply` creates the cluster:

| Component | Method | Purpose |
|-----------|--------|---------|
| AWS Load Balancer Controller | Helm chart | Ingress → ALB |
| External Secrets Operator | Helm chart | Secrets Manager → K8s Secrets |
| Cluster Autoscaler | Helm chart | Scale node groups |
| Metrics Server | Helm chart | HPA metrics |
| (Optional) Calico | Helm chart | Network policies |

### IRSA — IAM Roles for Service Accounts

| Service Account | IAM Policy | Used By |
|----------------|-----------|---------|
| `problem-service-sa` | RDS access | problem-service pods |
| `submission-service-sa` | RDS + ElastiCache access | submission-service pods |
| `worker-sa` | SQS + RDS + ElastiCache access | worker pods |
| `external-secrets-sa` | Secrets Manager read | External Secrets Operator |

### Helm Values — values-eks.yaml

Key overrides from `values-dev.yaml`:

| Setting | Dev (Kind) | EKS |
|---------|-----------|-----|
| Image registry | local | `<account>.dkr.ecr.<region>.amazonaws.com/online-judge` |
| Image tag | `latest` | `{{ .Values.global.imageTag }}` (set by CD) |
| Databases | StatefulSets enabled | **Disabled** — use RDS endpoints |
| Redis | StatefulSet enabled | **Disabled** — use ElastiCache endpoint |
| Queue | RabbitMQ StatefulSet | **Disabled** — use SQS endpoint |
| Ingress class | nginx | alb |
| Ingress annotations | nginx-specific | ALB-specific (scheme, subnets, cert ARN) |
| Service accounts | default | IRSA-annotated |
| Node selector | none | managed node group label |

### Deployment

1. `aws eks update-kubeconfig --name online-judge-staging --region <region>`
2. `kubectl get nodes` → verify nodes ready
3. Install components (ALB Controller, ESO, Cluster Autoscaler, Metrics Server)
4. `helm install online-judge ./helm/online-judge -f values-eks.yaml --set global.imageTag=<sha>`
5. Verify: `kubectl get pods -n online-judge` → all Running
6. `kubectl get ingress` → ALB DNS name
7. Test: access ALB URL in browser

### CD Pipeline — EKS Variant

Add `deploy-eks.yml` workflow:

| Step | Description |
|------|-------------|
| 1 | Build + push images to ECR (reuse from ECS workflow) |
| 2 | Configure kubectl: `aws eks update-kubeconfig` |
| 3 | `helm upgrade --install online-judge ./helm -f values-eks.yaml --set global.imageTag=${{ github.sha }}` |
| 4 | `kubectl rollout status deployment/<service>` per service |
| 5 | Smoke tests against ALB URL |
| 6 | On staging success → manual approval → deploy to prod |

Rollback: `helm rollback online-judge` (< 2 minutes)

### ECS vs EKS Comparison

Document this comparison after both are running:

| Dimension | ECS Fargate | EKS |
|-----------|-------------|-----|
| Setup complexity | Lower (AWS-native) | Higher (K8s + add-ons) |
| Flexibility | Limited to AWS | Full K8s ecosystem |
| Cost | Pay per task vCPU/memory | Cluster fee ($73/mo) + EC2 nodes |
| Scaling | ECS auto-scaling | HPA + Cluster Autoscaler |
| Networking | AWS VPC mode | K8s services + Ingress |
| Secrets | Secrets Manager native | Needs External Secrets Operator |
| Monitoring | CloudWatch native | Prometheus + Grafana (more powerful) |
| Deploy | `update-service` | `helm upgrade` |
| Rollback | Task def revision | `helm rollback` |
| Learning curve | Low | High (but transferable to any K8s) |

---

## Testing

| Type | What to Test |
|------|-------------|
| Deploy | `helm install` succeeds, all pods Running |
| E2E | Full flow via ALB URL |
| IRSA | Pods can access AWS resources without hardcoded credentials |
| Scaling | HPA + Cluster Autoscaler work under load |
| Rollback | `helm rollback` restores previous version in < 2 min |
| Comparison | Run same load test on ECS and EKS, compare latency/cost |
| Secrets | External Secrets Operator syncs secrets correctly |

---

## Checklist

- [ ] EKS cluster provisioned via Terraform
- [ ] `kubectl get nodes` → nodes Ready
- [ ] ALB Controller, ESO, Cluster Autoscaler installed
- [ ] `helm install` deploys all services
- [ ] All pods Running, no CrashLoopBackOff
- [ ] App accessible via ALB URL
- [ ] IRSA working — no AWS keys in pods
- [ ] CD pipeline: merge → build → push → helm upgrade → smoke test
- [ ] `helm rollback` works < 2 min
- [ ] ECS vs EKS comparison document written
- [ ] ✅ **App live on EKS**
