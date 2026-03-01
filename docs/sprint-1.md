# Sprint 1: Problem Service & Frontend

> **Duration**: Week 3-4
> **Phase**: 🟢 Docker Compose
> **Goal**: Fully functional Problem CRUD API + Angular frontend with problem list and code editor.
> **Depends on**: Sprint 0 (all services running)

---

## 📚 DevOps Learning Objectives

| Topic | What to Learn | Resources |
|-------|--------------|-----------|
| **Layered Architecture** | Controller → Service → Repository pattern in Spring Boot | Spring Boot docs |
| **Database Migrations** | Flyway versioned migrations, rollback strategy | Flyway documentation |
| **Integration Testing** | Testcontainers — spin up real PostgreSQL in tests | testcontainers.org |
| **API Testing** | MockMvc for Spring, httpx for FastAPI | Framework docs |
| **Hot Reload** | Spring DevTools (auto-restart), Angular `ng serve` (HMR) | — |
| **Environment Config** | Externalized config with `.env`, Spring profiles | 12-Factor App |

---

## Tasks

### Problem Service (Java Spring Boot)

- [ ] Create `Problem` JPA entity matching the DB schema
- [ ] Create `ProblemRepository` extending `JpaRepository`
- [ ] Create `ProblemService` with business logic
- [ ] Implement `ProblemController`:
  - `GET /api/problems?page=0&size=20` — returns paginated summary (id, title, level, tags only)
  - `GET /api/problems/{id}?language=python` — returns full problem + code stub for specified language
- [ ] Create DTOs: `ProblemSummaryDto` (list), `ProblemDetailDto` (detail)
- [ ] Add validation: 404 for non-existent problem, validate `language` param
- [ ] Seed 10-15 problems via Flyway migration `V2__seed_problems.sql`
  - Include: Two Sum, FizzBuzz, Valid Parentheses, Reverse Linked List, Max Depth Binary Tree, etc.

### API Gateway

- [ ] Verify routes forward correctly to Problem Service
- [ ] Add request/response logging filter
- [ ] Error handling: return proper JSON errors, not HTML stack traces

### Frontend (Angular)

- [ ] **Problem List page** (`/problems`)
  - Angular Material table with columns: title, level, tags
  - Color-coded level badges (green/orange/red)
  - Pagination component
  - Search/filter by level (optional)
- [ ] **Problem Detail page** (`/problems/:id`)
  - Split-panel layout: problem description (left) + code editor (right)
  - Integrate Monaco Editor (via `ngx-monaco-editor`)
  - Language selector dropdown (Python, JavaScript, Java)
  - Language change → fetch code stub from API → update editor
  - Submit button (wired up in Sprint 2)
- [ ] `ApiService` — centralized HTTP client calling API Gateway
- [ ] Responsive layout with Angular Material breakpoints

### DevOps

- [ ] Update `docker-compose.yml` with volume mounts for hot-reload:
  - Java: mount `src/` + Spring DevTools
  - Angular: mount `src/` + `ng serve` proxy
- [ ] Create `.env.example` with documented variables
- [ ] Add `make seed` command to re-run seed migration

---

## Testing

| Service | Type | What to Test |
|---------|------|-------------|
| Problem Service | Unit (Mockito) | `ProblemService.findAll()` pagination, `findById()` with/without language |
| Problem Service | Integration (Testcontainers) | Full API flow with real PostgreSQL, verify Flyway migrations |
| Problem Service | API (MockMvc) | `GET /api/problems` → 200 + paginated JSON, `GET /api/problems/{id}` → 200 or 404, language param |
| API Gateway | Integration | Route forwarding, CORS headers in response |
| Frontend | Component (Karma) | ProblemListComponent renders table, ProblemDetailComponent renders editor |
| Frontend | Service (Karma) | ApiService mocked HTTP calls |

**Coverage target**: ≥ 80% on Problem Service business logic.

---

## Checklist

- [ ] `GET /api/problems` returns paginated list with seed data
- [ ] `GET /api/problems/{id}?language=java` returns correct code stub
- [ ] Frontend displays problem list, click → detail with Monaco Editor
- [ ] Language switch updates code stub in editor
- [ ] Unit + integration tests pass (≥ 80% coverage Problem Service)
- [ ] `make test` passes for all services
- [ ] Swagger UI shows documented Problem endpoints
