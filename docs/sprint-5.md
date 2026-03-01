# Sprint 5: Helm Charts & Monitoring

> **Duration**: Week 11-12
> **Phase**: 🔵 Kubernetes Local
> **Goal**: Package app with Helm, auto-scale with HPA, observe with Prometheus + Grafana.

---

## 📚 DevOps Learning Objectives

| Topic | What to Learn | Why It Matters |
|-------|--------------|----------------|
| **Helm** | Charts, templates, values, install/upgrade/rollback | Standard K8s packaging |
| **HPA** | Horizontal Pod Autoscaler, CPU/memory metrics | Auto-scale under load |
| **Prometheus** | Metrics scraping, PromQL, service discovery | Industry-standard monitoring |
| **Grafana** | Dashboards, data sources, panels | Visualize metrics |
| **Application Metrics** | `/metrics` endpoint (Micrometer, prometheus_client) | Custom app metrics |
| **Load Testing** | k6 or Locust for generating traffic | Prove HPA works |
| **Network Policies** | Restrict pod-to-pod communication | Least-privilege networking |

---

## Tasks

### Helm Chart

- [ ] Template all K8s manifests
- [ ] `values.yaml` (default), `values-dev.yaml` (Kind)
- [ ] `helm install/upgrade/rollback` work

### HPA — The Real Test

| Service | Min | Max | Target CPU |
|---------|-----|-----|-----------|
| worker | 1 | 10 | 60% |
| submission-service | 1 | 5 | 70% |

**Load test**: Spam `POST /api/submissions` with k6 → Queue fills → HPA scales Worker pods → Watch `kubectl get hpa` → Pods scale up → Queue drains

This is where the mock CPU burn (Sprint 1) pays off — each Worker pod actually uses CPU, triggering real scaling.

### Monitoring

- [ ] Install kube-prometheus-stack
- [ ] Java: Micrometer → `/actuator/prometheus`
- [ ] Python: prometheus_client → `/metrics`
- [ ] Grafana dashboards: API latency, queue depth, pod CPU/memory, Worker execution times

### Network Policies

- [ ] Default deny all
- [ ] Explicit allow per flow (frontend→gateway, gateway→services, etc.)

---

## Checklist

- [ ] `helm install` deploys app
- [ ] HPA scales Workers under load (verified with load test report)
- [ ] Prometheus + Grafana dashboards live
- [ ] Network policies enforced
