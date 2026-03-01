# Sprint 2: Docker Compose Production

> **Duration**: Week 5-6
> **Phase**: 🟢 Local
> **Goal**: Make Docker Compose production-grade — networking, NGINX reverse proxy, structured logging, env management.

---

## 📚 DevOps Learning Objectives

| Topic | What to Learn | Why It Matters |
|-------|--------------|----------------|
| **Docker Networking** | Custom bridge networks, service isolation, DNS | Services shouldn't all be on the same network |
| **NGINX Reverse Proxy** | Single entry point, proxy_pass, load balancing | Production apps use a proxy, not direct port access |
| **Docker Compose Profiles** | Dev vs prod configs, resource limits, restart policies | Dev and prod have different requirements |
| **Structured Logging** | JSON logs, log drivers, centralized output | Readable logs are critical for debugging |
| **Environment Management** | `.env` files, Docker secrets, config separation | Never hardcode credentials |

---

## Tasks

### Docker Networking

- [ ] Create isolated networks:
  - `frontend-net`: frontend + nginx + api-gateway
  - `backend-net`: all backend services + databases + infra
  - api-gateway bridges both networks
- [ ] Verify: frontend cannot directly reach databases

### NGINX Reverse Proxy

- [ ] Add NGINX container as single entry point (port 80)
- [ ] Route `/` → frontend, `/api/` → api-gateway
- [ ] Only port 80 exposed externally
- [ ] Rate limiting and request size limits

### Production Compose

- [ ] Create `docker-compose.prod.yml`:
  - `restart: unless-stopped`
  - Resource limits per service
  - No source volume mounts
  - Only port 80 exposed via NGINX
- [ ] `make deploy-compose` for one-command production start

### Structured Logging

- [ ] Java: Logback JSON encoder
- [ ] Python: `python-json-logger`
- [ ] All logs: `timestamp`, `level`, `service`, `message`

---

## Checklist

- [ ] NGINX serves app on port 80
- [ ] Network isolation verified
- [ ] `docker-compose.prod.yml` with resource limits
- [ ] All services output JSON logs
- [ ] Environment variables documented
