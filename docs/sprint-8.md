# Sprint 8: Deploy on AWS EKS

> **Duration**: Week 17-18
> **Phase**: 🟣 EKS
> **Goal**: Provision EKS cluster, deploy with Helm, test HPA with the mock executor, compare ECS vs EKS.

---

## 📚 DevOps Learning Objectives

| Topic | What to Learn | Why It Matters |
|-------|--------------|----------------|
| **EKS** | AWS managed Kubernetes, node groups, add-ons | K8s in production on AWS |
| **IRSA** | IAM Roles for Service Accounts | Pod-level AWS permissions |
| **ALB Ingress Controller** | Ingress backed by real AWS ALB | Bridge K8s and AWS networking |
| **Cluster Autoscaler** | Scale nodes based on pending pods | Infrastructure scales on demand |
| **External Secrets Operator** | Sync Secrets Manager → K8s Secrets | Bridge AWS secrets into K8s |

---

## Tasks

### Terraform — EKS Module

- [ ] EKS cluster, managed node group (t3.medium, 2-5 nodes)
- [ ] OIDC provider for IRSA
- [ ] Install: ALB Controller, ESO, Cluster Autoscaler, Metrics Server

### Helm Deploy

- [ ] `values-eks.yaml`: ECR images, RDS/ElastiCache/SQS endpoints, IRSA, disable StatefulSets
- [ ] `helm install -f values-eks.yaml`

### The Big HPA Test

This is the payoff of Sprint 1's mock executor:

1. Deploy Worker with resource limits: `cpu: 500m, memory: 512Mi`
2. Spam `POST /api/submissions` (10K requests via k6)
3. Queue fills up → Worker CPU spikes → HPA scales from 1 to 10 pods
4. Cluster Autoscaler adds nodes if needed
5. Queue drains → pods scale back down

**Without the mock executor**, HPA would never trigger because `/health` uses no CPU.

### CD Pipeline → EKS

- [ ] `helm upgrade --set global.imageTag=$SHA`
- [ ] Rollback: `helm rollback` (< 2 min)

### ECS vs EKS Comparison Doc

- [ ] Write after both are running: setup, flexibility, cost, monitoring, deploy, rollback

---

## Checklist

- [ ] EKS cluster via Terraform, all pods Running
- [ ] App works via ALB (3 flows)
- [ ] IRSA working (no AWS keys in pods)
- [ ] HPA scales Workers under load
- [ ] Cluster Autoscaler adds/removes nodes
- [ ] CD: merge → helm upgrade → smoke test
- [ ] ECS vs EKS comparison written
- [ ] ✅ **App live on EKS**
