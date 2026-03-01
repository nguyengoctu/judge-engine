# Sprint 4: Kubernetes Basics (Local)

> **Duration**: Week 9-10
> **Phase**: 🔵 Kubernetes Local
> **Goal**: Write K8s manifests, deploy the working app on a Kind cluster.

---

## 📚 DevOps Learning Objectives

| Topic | What to Learn | Why It Matters |
|-------|--------------|----------------|
| **K8s Architecture** | Control plane, worker nodes, kubelet, kube-proxy | Understand K8s internals |
| **Deployments** | Declarative replicas, rolling updates, rollback | Production app management |
| **Services** | ClusterIP, NodePort, DNS discovery | Pod-to-pod communication |
| **ConfigMaps & Secrets** | Externalize config, separate sensitive data | Never hardcode in images |
| **StatefulSets** | Stable identity, persistent storage for DBs | Databases on K8s |
| **PersistentVolumes** | PVC, PV, storage classes | Data survives pod restarts |
| **Ingress** | Layer 7 routing, path-based rules | Single entry point |
| **kubectl** | apply, get, describe, logs, exec, port-forward | Essential CLI |

---

## Tasks

### Kind Cluster Setup

- [ ] Create multi-node cluster (1 control + 2 workers)
- [ ] Install NGINX Ingress Controller
- [ ] Load local Docker images

### K8s Manifests

- [ ] Namespace, ConfigMaps, Secrets
- [ ] Deployments: api-gateway, problem-service, submission-service, worker, frontend
- [ ] StatefulSets: problem-db, submission-db, redis, rabbitmq
- [ ] Services (ClusterIP) for all
- [ ] Ingress: `/` → frontend, `/api/*` → api-gateway
- [ ] Liveness + readiness probes on all pods

### Test the Flows on K8s

- [ ] Submit code via Ingress → queue → worker processes → status updates
- [ ] `docker stats` equivalent: `kubectl top pods` shows Worker CPU burn
- [ ] Problem list returns seed data from DB

---

## Checklist

- [ ] All pods Running, no CrashLoopBackOff
- [ ] App works via Ingress (all 3 flows)
- [ ] Pod delete → auto-recovery
- [ ] DB data persists across pod restarts
- [ ] `make k8s-deploy` and `make k8s-teardown`
