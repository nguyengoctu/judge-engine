# Sprint 4: Kubernetes Manifests & Local Deploy

> **Duration**: Week 9-10
> **Phase**: 🔵 Kubernetes Local
> **Goal**: Write K8s manifests for all services, deploy on a Kind cluster locally.
> **Depends on**: Sprint 3 (complete app on Docker Compose)
> **Milestone**: Same app now runs on Kubernetes

---

## 📚 DevOps Learning Objectives

| Topic | What to Learn | Resources |
|-------|--------------|-----------|
| **Kubernetes Architecture** | Control plane (API server, etcd, scheduler, controller manager), worker nodes (kubelet, kube-proxy) | kubernetes.io/docs/concepts |
| **Pods & Containers** | Pod lifecycle, multi-container pods, init containers | K8s Pod docs |
| **Deployments** | Declarative updates, replica sets, rolling updates, rollback | K8s Deployment docs |
| **StatefulSets** | Stable network identity, ordered deployment, persistent storage for databases | K8s StatefulSet docs |
| **Services** | ClusterIP (internal), NodePort (external), Service discovery via DNS | K8s Service docs |
| **ConfigMaps & Secrets** | Externalize config, mount as env vars or files, base64 encoding | K8s Configuration docs |
| **PersistentVolumes** | PVC, PV, storage classes, dynamic provisioning | K8s Storage docs |
| **Ingress** | Layer 7 routing, host/path-based rules, TLS termination | NGINX Ingress Controller docs |
| **Kind** | Kubernetes in Docker, multi-node clusters, local development | kind.sigs.k8s.io |
| **kubectl** | Core commands: apply, get, describe, logs, exec, port-forward, delete | kubectl cheat sheet |

---

## Tasks

### K8s Manifest Structure

```
k8s/
├── namespace.yaml
├── databases/
│   ├── problem-db-statefulset.yaml
│   ├── problem-db-service.yaml
│   ├── problem-db-pvc.yaml
│   ├── submission-db-statefulset.yaml
│   ├── submission-db-service.yaml
│   └── submission-db-pvc.yaml
├── infrastructure/
│   ├── redis-statefulset.yaml
│   ├── redis-service.yaml
│   ├── rabbitmq-statefulset.yaml
│   └── rabbitmq-service.yaml
├── services/
│   ├── api-gateway-deployment.yaml
│   ├── api-gateway-service.yaml
│   ├── problem-service-deployment.yaml
│   ├── problem-service-service.yaml
│   ├── submission-service-deployment.yaml
│   ├── submission-service-service.yaml
│   ├── worker-deployment.yaml
│   └── frontend-deployment.yaml
│   └── frontend-service.yaml
├── config/
│   ├── configmaps.yaml
│   └── secrets.yaml
└── ingress.yaml
```

### Deployments (Stateless Services)

| Service | Replicas | Port | Probes | Resource Requests |
|---------|----------|------|--------|-------------------|
| api-gateway | 1 | 8080 | `/health` liveness + readiness | 256Mi / 0.25 CPU |
| problem-service | 1 | 8081 | `/health` liveness + readiness | 512Mi / 0.5 CPU |
| submission-service | 1 | 8082 | `/health` liveness + readiness | 256Mi / 0.25 CPU |
| worker | 1 | 8083 | `/health` liveness + readiness | 512Mi / 0.5 CPU |
| frontend | 1 | 80 | HTTP `/` liveness | 128Mi / 0.1 CPU |

### StatefulSets (Stateful Services)

| Service | Replicas | Port | Storage |
|---------|----------|------|---------|
| problem-db (PostgreSQL) | 1 | 5432 | 5Gi PVC |
| submission-db (PostgreSQL) | 1 | 5432 | 5Gi PVC |
| redis | 1 | 6379 | 1Gi PVC |
| rabbitmq | 1 | 5672, 15672 | 1Gi PVC |

### Services (Networking)

| Service | Type | Purpose |
|---------|------|---------|
| All backend services | ClusterIP | Internal communication only |
| frontend | NodePort or via Ingress | External access |

### ConfigMaps

Store non-sensitive configuration:
- Database hostnames, ports, database names
- Redis and RabbitMQ hostnames
- Service URLs for gateway routing
- Application-specific settings

### Secrets

Store sensitive data (base64 encoded):
- Database passwords
- RabbitMQ credentials
- Redis auth password (if set)

### Ingress (NGINX)

| Path | Backend Service | Port |
|------|----------------|------|
| `/` | frontend | 80 |
| `/api/problems/**` | api-gateway | 8080 |
| `/api/submissions/**` | api-gateway | 8080 |
| `/api/competitions/**` | api-gateway | 8080 |

### Local Deployment Steps

1. Install Kind: `go install sigs.k8s.io/kind@latest` or `brew install kind`
2. Create cluster: `kind create cluster --name online-judge --config kind-config.yaml`
3. Load local images: `kind load docker-image <image> --name online-judge` (for each service)
4. Install NGINX Ingress Controller: `kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/...`
5. Apply manifests: `kubectl apply -f k8s/ --recursive`
6. Verify: `kubectl get pods -n online-judge`
7. Access: `kubectl port-forward svc/frontend 4200:80 -n online-judge` or via Ingress

---

## kubectl Commands to Learn

| Command | Purpose |
|---------|---------|
| `kubectl get pods -n online-judge` | List all pods |
| `kubectl get svc -n online-judge` | List all services |
| `kubectl describe pod <name>` | Debug pod issues |
| `kubectl logs <pod> -f` | Tail logs |
| `kubectl exec -it <pod> -- /bin/sh` | Shell into container |
| `kubectl port-forward svc/<name> <local>:<remote>` | Access service locally |
| `kubectl apply -f k8s/ --recursive` | Apply all manifests |
| `kubectl delete -f k8s/ --recursive` | Tear down everything |
| `kubectl rollout status deployment/<name>` | Check deployment progress |
| `kubectl rollout undo deployment/<name>` | Rollback deployment |

---

## Testing

| Type | What to Test |
|------|-------------|
| Pod health | All pods in `Running` state, no restarts |
| E2E | Full user flow works through K8s networking |
| Pod resilience | `kubectl delete pod <name>` → auto-recreated by Deployment |
| Config change | Update ConfigMap → rolling restart picks up changes |
| Data persistence | Delete and recreate PostgreSQL pod → data survives (PVC) |
| DNS resolution | Services can reach each other via K8s DNS names |

---

## Checklist

- [ ] Kind cluster created
- [ ] All manifests applied successfully
- [ ] `kubectl get pods` → all Running, no CrashLoopBackOff
- [ ] App accessible via port-forward or Ingress
- [ ] E2E flow works: problems → submit → results → leaderboard
- [ ] Pod restart → auto-recovery
- [ ] Data persists across pod restarts
- [ ] Add `make k8s-deploy` and `make k8s-teardown` to Makefile
