# Sprint 3.5: Jenkins CI/CD Pipeline

> **Duration**: Week 8-9
> **Phase**: 🟢 Local
> **Goal**: Reproduire le pipeline CI/CD du Sprint 3 avec Jenkins — un outil platform-agnostic, self-hosted.

---

## 📚 DevOps Learning Objectives

| Topic | What to Learn | Why It Matters |
|-------|--------------|----------------|
| **Jenkins** | Controller/Agent architecture, Jenkinsfile, Groovy DSL | Industry-standard self-hosted CI/CD |
| **Pipeline as Code** | Declarative vs Scripted pipelines, stages, steps | Même logique que GitHub Actions mais syntax différente |
| **Multibranch Pipeline** | Auto-discovery de branches, PR builds | Monorepo + branch management |
| **Jenkins Plugins** | Docker Pipeline, SonarQube Scanner, Credentials | Extensibilité de Jenkins |
| **Webhook Triggers** | Generic Webhook Trigger, polling SCM | Connecter Jenkins à n'importe quel Git repo |
| **OWASP Dependency-Check** | Scan dependencies pour CVE (platform-agnostic) | Alternative à Dependabot (GitHub-only) |

---

## Pourquoi Jenkins Après GitHub Actions ?

```
Sprint 3:  GitHub Actions  → Rapide, intégré GitHub, SaaS
Sprint 3.5: Jenkins         → Self-hosted, platform-agnostic, enterprise

Même pipeline:  Lint → Test → Build → Scan → Push
Outil différent: comprendre les CONCEPTS, pas juste un outil
```

| | GitHub Actions | Jenkins |
|---|---|---|
| **Hébergement** | SaaS (GitHub) | Self-hosted (Docker) |
| **Config** | `.github/workflows/*.yml` | `Jenkinsfile` |
| **Triggers** | GitHub events | Webhooks, polling, cron |
| **Secrets** | GitHub Secrets | Jenkins Credentials |
| **Plugins** | Marketplace Actions | Jenkins Plugin ecosystem |
| **Git provider** | GitHub uniquement | GitHub, GitLab, Bitbucket, tout |

---

## Tasks

### Jenkins Setup (Docker Compose)

- [ ] Ajouter Jenkins Controller dans Docker Compose
- [ ] Configurer Docker-in-Docker (DinD) pour builds Docker
- [ ] Installer plugins essentiels (Pipeline, Docker, Git, Blue Ocean)
- [ ] Créer credentials pour Docker registry

### CI Pipeline (`Jenkinsfile` — sur PR/branch)

- [ ] Détecter services modifiés (`changeset` directive)
- [ ] Par service : lint → test → build Docker image → Trivy scan
- [ ] Stages parallèles pour Java et Python
- [ ] Bloquer merge si pipeline échoue

### CD Pipeline (sur merge à main)

- [ ] Build images pour services modifiés
- [ ] Tag avec `<service>:<git-sha>` et `:latest`
- [ ] Push vers Docker Hub (ou tout registry)

### SonarQube Integration

- [ ] Installer SonarQube Scanner plugin
- [ ] Configurer `withSonarQubeEnv` dans Jenkinsfile
- [ ] Quality gate avec `waitForQualityGate`
- [ ] Réutiliser SonarQube Docker Compose du Sprint 3

### Container Scanning (Trivy)

- [ ] Installer Trivy dans Jenkins agent
- [ ] Scan images après build, avant push
- [ ] Fail pipeline si CRITICAL/HIGH CVE

### Webhook + Dependency Scanning

- [ ] Configurer Generic Webhook Trigger plugin
- [ ] Multibranch Pipeline auto-discovery
- [ ] OWASP Dependency-Check plugin (remplace Dependabot)
- [ ] Scan automatique des dépendances pour CVE

---

## Checklist

- [ ] Jenkins tourne en local via Docker Compose
- [ ] CI pipeline se déclenche sur chaque branche/PR
- [ ] Seuls les services modifiés sont testés (changeset filter)
- [ ] SonarQube quality gate intégré
- [ ] Trivy scan passe
- [ ] CD push tagged images au merge
- [ ] OWASP Dependency-Check scan les dépendances
