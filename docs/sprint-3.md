# Sprint 3: CI/CD Pipeline

> **Duration**: Week 7-8
> **Phase**: 🟢 Local
> **Goal**: Automated testing and Docker image building with GitHub Actions on every push/PR.

---

## 📚 DevOps Learning Objectives

| Topic | What to Learn | Why It Matters |
|-------|--------------|----------------|
| **GitHub Actions** | Workflows, jobs, steps, triggers, secrets, matrix builds | Industry-standard CI/CD |
| **CI Pipeline Design** | Lint → test → build → scan, fail fast, parallel jobs | Fast feedback loop |
| **Path Filters** | Only build/test changed services | Monorepo efficiency |
| **Docker Image Tags** | Git SHA tags, semantic versioning | Know which version is deployed |
| **Container Scanning** | Trivy vulnerability scanning | Catch CVEs before production |
| **SonarCloud** | Code quality, static analysis, test coverage, code smells | Quality gates block bad code |
| **Branch Protection** | Required checks, review rules | Prevent broken merges |
| **Dependabot** | Dependency vulnerability scanning, auto-PR | Keep dependencies secure |

---

## Tasks

### CI Workflow (`ci.yml` — on PR + push master)

- [x] Detect changed services (path filters via `dorny/paths-filter`)
- [x] Per service: lint → test → build Docker image → Trivy scan
- [x] SonarCloud scan (after tests, skips Dependabot PRs)
- [x] Trivy SARIF reports with conditional execution
- [x] GHA build cache per service

### CD Workflow (`cd.yml` — on tag push)

- [x] Trigger on `v*` tags only (not on every push to master)
- [x] Build images for all services (matrix strategy)
- [x] Tag with `<service>:<version>` and `:latest`
- [x] Push to GHCR (GitHub Container Registry)

### Branch Protection

- [x] Protect `master`, require CI status checks to pass
- [x] Required checks: `test-worker`, `test-submission-service`, `test-problem-service`, `test-api-gateway`, `test-frontend`

### SonarCloud

- [x] Configure `sonar-project.properties` for Java and Python services
- [x] Add SonarCloud scan step in CI workflow (after tests)
- [x] Skip SonarCloud for Dependabot PRs (no access to secrets)

### Container Scanning (Trivy)

- [x] Trivy scan all Docker images (worker, runners, submission-service, problem-service, api-gateway, frontend)
- [x] CRITICAL/HIGH severity gate (exit-code: 1)
- [x] Trivy DB caching
- [x] `.trivyignore` for managing false positives
- [x] SARIF report generation (conditional on build success)

### Dependabot

- [x] Configure `.github/dependabot.yml` for pip, Maven, npm, Docker, GitHub Actions
- [x] Weekly scan schedule
- [x] Labels per ecosystem
- [x] `open-pull-requests-limit: 1` per ecosystem
- [x] Dependabot alerts visible in GitHub Security tab

---

## Checklist

- [x] CI runs on every PR
- [x] CI runs on every push to master
- [x] Only changed services tested (path filters)
- [x] Trivy scan passes
- [x] CD pushes tagged images on tag push
- [x] Branch protection on `master`
- [x] Dependabot configured for all ecosystems
