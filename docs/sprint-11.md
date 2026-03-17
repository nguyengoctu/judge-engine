# Sprint 11: Service Mesh — Istio

> **Duration**: Week 23-24
> **Phase**: 🔶 Advanced
> **Goal**: Deploy Istio service mesh on EKS cluster. Implement mTLS, traffic management (canary deploy, traffic splitting), fault injection, and observability with Kiali/Jaeger.

---

## 📚 DevOps Learning Objectives

| Topic | What to Learn | Why It Matters |
|-------|--------------|----------------|
| **Service Mesh Concepts** | Sidecar proxy, data plane vs control plane | Understand infrastructure-layer networking |
| **Istio Installation** | istioctl, profiles, sidecar injection | Deploy mesh on existing cluster |
| **mTLS** | Automatic mutual TLS between services | Zero-trust security without code changes |
| **Traffic Management** | VirtualService, DestinationRule, traffic splitting | Canary deploys, A/B testing at infra level |
| **Fault Injection** | Delay, abort injection | Chaos engineering, resilience testing |
| **Observability** | Kiali, Jaeger, Grafana dashboards | Service graph, distributed tracing, metrics |
| **Circuit Breaking** | Connection pools, outlier detection | Prevent cascading failures |

---

## Architecture

```
                    ┌───────────────────────────────────────────┐
                    │            Control Plane (istiod)          │
                    │                                           │
                    │  Pilot (config)  Citadel (certs)  Galley  │
                    └────────────┬──────────────────────────────┘
                                 │ push config + certs
                                 ▼
┌─ Data Plane ──────────────────────────────────────────────────┐
│                                                               │
│  Pod: api-gateway          Pod: problem-service               │
│  ┌──────┐ ┌──────┐        ┌──────┐ ┌──────┐                 │
│  │ app  │↔│envoy │◄──────►│envoy │↔│ app  │                 │
│  └──────┘ └──────┘  mTLS  └──────┘ └──────┘                 │
│                                                               │
│  Pod: submission-service   Pod: worker                        │
│  ┌──────┐ ┌──────┐        ┌──────┐ ┌──────┐                 │
│  │ app  │↔│envoy │        │envoy │↔│ app  │                 │
│  └──────┘ └──────┘        └──────┘ └──────┘                 │
│                                                               │
└───────────────────────────────────────────────────────────────┘
```

---

## Tasks

### 11.1: Install Istio on Kind/EKS

- [ ] Install `istioctl` CLI
- [ ] Deploy Istio with `demo` profile (Kind) or `default` profile (EKS)
- [ ] Enable sidecar injection on `judge-engine` namespace
- [ ] Restart all deployments → verify 2/2 containers per pod
- [ ] Install addons: Kiali, Jaeger, Prometheus, Grafana

### 11.2: mTLS — Zero-Trust Networking

- [ ] Verify mTLS is enabled (STRICT mode)
- [ ] Test: `kubectl exec` into a pod, inspect Envoy certs
- [ ] PeerAuthentication policy: STRICT for namespace
- [ ] Observe encrypted traffic in Kiali

### 11.3: Traffic Management — Canary Deploy

- [ ] Deploy api-gateway v1 and v2 (2 Deployments, same Service)
- [ ] Create DestinationRule with subsets (v1, v2)
- [ ] Create VirtualService: 90% → v1, 10% → v2
- [ ] Send 100 requests, verify traffic split ratio
- [ ] Gradually shift: 90/10 → 50/50 → 0/100

### 11.4: Fault Injection — Chaos Engineering

- [ ] Inject 3s delay on 50% of problem-service requests
- [ ] Inject HTTP 500 abort on 10% of requests
- [ ] Observe impact on upstream services (timeout? retry?)
- [ ] Test circuit breaker: connection pool limits, outlier detection

### 11.5: Observability Stack

- [ ] Kiali: visualize service graph, verify mTLS indicators
- [ ] Jaeger: trace a submission request across all services
- [ ] Grafana: Istio dashboards — latency, error rate, throughput
- [ ] Compare observability with vs without Istio

### 11.6: Advanced Traffic Patterns (Optional)

- [ ] Header-based routing (e.g., `x-version: v2` → v2)
- [ ] Mirror traffic (shadow testing: copy traffic to v2 without affecting users)
- [ ] Rate limiting via Envoy filter
- [ ] Retry policy at mesh level (replace app-level retry logic)

---

## Testing

| Type | What to Test |
|------|-------------|
| mTLS | Plaintext connections rejected, encrypted connections accepted |
| Canary | Traffic split matches configured percentages |
| Fault injection | Delays and aborts injected at correct rates |
| Circuit breaker | Service fails fast when downstream is unhealthy |
| Tracing | Full request trace visible in Jaeger |
| Performance | Measure latency overhead of Envoy sidecar (typically < 3ms) |

---

## Checklist

- [ ] Istio installed and running on cluster
- [ ] All pods have Envoy sidecar (2/2 containers)
- [ ] mTLS enforced across all services
- [ ] Canary deploy demonstrated (traffic splitting works)
- [ ] Fault injection tested (delay + abort)
- [ ] Kiali service graph shows all connections
- [ ] Jaeger shows distributed traces
- [ ] Documentation comparing: with Istio vs without Istio
- [ ] ✅ **Service mesh fully operational on judge-engine**
