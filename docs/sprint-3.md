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
| **SonarQube** | Code quality, static analysis, test coverage, code smells | Quality gates block bad code |
| **Branch Protection** | Required checks, review rules | Prevent broken merges |

---

## Tasks

### CI Workflow (`ci.yml` — on PR)

- [ ] Detect changed services (path filters)
- [ ] Per service: lint → test → build Docker image → Trivy scan
- [ ] Post results as PR comment
- [ ] Block merge on failure

### CD Workflow (`cd.yml` — on merge to main)

- [ ] Build images for changed services
- [ ] Tag with `<service>:<git-sha>` and `:latest`
- [ ] Push to container registry

### Branch Protection

- [ ] Protect `main`, require CI pass

### SonarQube

- [ ] Add SonarQube container to Docker Compose (Community Edition, self-hosted)
- [ ] Configure sonar-project.properties for Java and Python services
- [ ] Add SonarQube scan step in CI workflow (after tests, before build)
- [ ] Set quality gate: no new bugs, no new vulnerabilities, coverage >= 70%
- [ ] Block PR merge if quality gate fails

### Dependabot

- [ ] Enable Dependabot for dependency vulnerability scanning
- [ ] Configure `.github/dependabot.yml` for Maven, pip, npm
- [ ] Auto-create PRs for vulnerable dependencies
- [ ] Dependabot alerts visible in GitHub Security tab

---

## Checklist

- [ ] CI runs on every PR
- [ ] Only changed services tested (path filters)
- [ ] Trivy scan passes
- [ ] CD pushes tagged images on merge
- [ ] Branch protection on `main`
