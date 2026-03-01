# Sprint 5: Helm, HPA & Monitoring

> **Duration**: Week 11-12
> **Phase**: 🔵 Kubernetes Local
> **Goal**: Package app with Helm, auto-scale with HPA, observe with Prometheus + Grafana.
> **Depends on**: Sprint 4 (app running on Kind)

---

## 📚 DevOps Learning Objectives

| Topic | What to Learn | Resources |
|-------|--------------|-----------|
| **Helm** | Charts, templates, values files, release management, rollback | helm.sh docs |
| **Helm Templating** | Go template syntax, `{{ .Values }}`, conditionals, loops, helpers | Helm template guide |
| **HPA** | Horizontal Pod Autoscaler, CPU/memory metrics, custom metrics | K8s HPA docs |
| **Metrics Server** | Cluster-level resource metrics, required for HPA | K8s Metrics Server |
| **Prometheus** | Time-series DB, scraping, PromQL, service discovery | prometheus.io docs |
| **Grafana** | Dashboard creation, data sources, alerting basics | grafana.com docs |
| **kube-prometheus-stack** | All-in-one: Prometheus, Grafana, AlertManager, node-exporter | Helm chart docs |
| **Application Metrics** | Exposing `/metrics` endpoint (Micrometer for Java, prometheus_client for Python) | Library docs |
| **Network Policies** | Restrict pod-to-pod communication, ingress/egress rules | K8s Network Policy docs |
| **Load Testing** | k6 or Locust for generating traffic to test scaling | k6.io, locust.io |

---

## Tasks

### Helm Chart

Structure:

```
helm/online-judge/
├── Chart.yaml                 # Chart metadata
├── values.yaml                # Default values
├── values-dev.yaml            # Kind local overrides
├── values-ecs.yaml            # ECS overrides (Sprint 7)
├── values-eks.yaml            # EKS overrides (Sprint 8)
└── templates/
    ├── _helpers.tpl            # Template helpers
    ├── namespace.yaml
    ├── api-gateway/
    │   ├── deployment.yaml
    │   ├── service.yaml
    │   └── hpa.yaml
    ├── problem-service/
    │   ├── deployment.yaml
    │   ├── service.yaml
    │   └── hpa.yaml
    ├── submission-service/
    │   ├── deployment.yaml
    │   ├── service.yaml
    │   └── hpa.yaml
    ├── worker/
    │   ├── deployment.yaml
    │   └── hpa.yaml
    ├── frontend/
    │   ├── deployment.yaml
    │   └── service.yaml
    ├── databases/              # StatefulSets (dev only, prod uses managed)
    ├── infrastructure/         # Redis, RabbitMQ (dev only)
    ├── configmap.yaml
    ├── secrets.yaml
    └── ingress.yaml
```

Key values to template:
- Image repository + tag per service
- Replica counts
- Resource requests/limits
- Database/Redis/RabbitMQ connection strings
- Enable/disable StatefulSets (off in prod — using managed services)

### HPA (Horizontal Pod Autoscaler)

| Service | Min | Max | Scale Metric | Target |
|---------|-----|-----|-------------|--------|
| api-gateway | 1 | 5 | CPU utilization | 70% |
| submission-service | 1 | 5 | CPU utilization | 70% |
| worker | 1 | 10 | CPU utilization | 60% |

Prerequisites:
- [ ] Install Metrics Server on Kind cluster
- [ ] Verify `kubectl top pods` works
- [ ] Define HPA manifests with `autoscaling/v2`

### Liveness & Readiness Probes

| Service | Liveness | Readiness | Initial Delay | Period |
|---------|----------|-----------|---------------|--------|
| api-gateway | `GET /health` | `GET /health` | 30s | 10s |
| problem-service | `GET /health` | `GET /health` + DB check | 45s | 10s |
| submission-service | `GET /health` | `GET /health` + DB + Redis check | 30s | 10s |
| worker | `GET /health` | `GET /health` + RabbitMQ check | 30s | 10s |
| frontend | `GET /` | `GET /` | 10s | 10s |

### Network Policies

| Source | Destination | Allowed |
|--------|------------|---------|
| frontend | api-gateway | ✅ Port 8080 |
| api-gateway | problem-service, submission-service | ✅ |
| submission-service | problem-db, submission-db, redis, rabbitmq | ✅ |
| worker | submission-db, redis, rabbitmq, Docker socket | ✅ |
| problem-service | problem-db | ✅ |
| Any other combination | — | ❌ Denied |

### Observability — Prometheus + Grafana

- [ ] Install kube-prometheus-stack via Helm
- [ ] Configure service monitors for each service
- [ ] Expose application metrics:
  - **Java**: Add Micrometer + Prometheus registry → `/actuator/prometheus`
  - **Python**: Add prometheus_client → `/metrics`

#### Grafana Dashboards

| Dashboard | Panels |
|-----------|--------|
| **API Overview** | Request rate, latency (p50/p95/p99), error rate, status code distribution |
| **Queue Monitoring** | Queue depth, consumer count, publish rate, DLQ count |
| **Pod Resources** | CPU usage vs limit, memory usage vs limit, restarts, pod count |
| **Code Execution** | Execution time distribution, pass/fail ratio, timeout rate |

### Structured Logging

- [ ] All services output JSON logs with fields: `timestamp`, `level`, `service`, `message`, `trace_id`
- [ ] Java: Logback JSON encoder
- [ ] Python: `python-json-logger` or structlog

---

## Testing

| Type | What to Test |
|------|-------------|
| Helm | `helm lint ./helm/online-judge` passes |
| Helm | `helm template ./helm/online-judge --debug` renders correctly |
| Helm | `helm install` + `helm upgrade` + `helm rollback` work |
| HPA | Load test → pods scale up, load stops → pods scale down |
| Probes | Kill `/health` → pod restarted by liveness probe |
| Network Policy | Worker cannot reach frontend directly |
| Grafana | Dashboards show live data from all services |
| Metrics | `/metrics` endpoint returns Prometheus format data |

### Load Testing

Use k6 or Locust to generate traffic:
- Target: API Gateway `GET /api/problems` and `POST /api/submissions`
- Ramp: 10 → 100 → 500 concurrent users over 5 minutes
- Verify: HPA triggers at threshold, new pods become ready, latency stays acceptable

---

## Checklist

- [ ] `helm install online-judge ./helm/online-judge -f values-dev.yaml` succeeds
- [ ] `helm upgrade` applies changes, `helm rollback` reverts
- [ ] HPA scales worker pods under load (verify with `kubectl get hpa`)
- [ ] Prometheus scrapes all services
- [ ] Grafana dashboards accessible at `localhost:3000`
- [ ] All 4 dashboards populated with live data
- [ ] Network policies block unauthorized access
- [ ] Load test report documented with results
