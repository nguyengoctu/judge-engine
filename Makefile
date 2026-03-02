.PHONY: dev dev-detached stop clean build test test-java test-python test-frontend status logs health

# ─── Development ───
dev:
	cd docker && docker compose up --build

dev-detached:
	cd docker && docker compose up --build -d

stop:
	cd docker && docker compose down

clean:
	cd docker && docker compose down -v --rmi local

# ─── Build ───
build:
	cd docker && docker compose build

# ─── Test (all via Docker, no local installs needed) ───
test: test-java test-python

test-java:
	@echo "=== Testing API Gateway ==="
	docker run --rm -v $(PWD)/services/api-gateway:/app -w /app maven:3.9-eclipse-temurin-21 mvn test -q
	@echo "=== Testing Problem Service ==="
	docker run --rm -v $(PWD)/services/problem-service:/app -w /app maven:3.9-eclipse-temurin-21 mvn test -q

test-python:
	@echo "=== Testing Submission Service ==="
	docker run --rm -v $(PWD)/services/submission-service:/app -w /app python:3.11-slim sh -c "pip install -q -r requirements.txt && pytest tests/ -v"
	@echo "=== Testing Worker ==="
	docker run --rm -v $(PWD)/services/worker:/app -w /app python:3.11-slim sh -c "pip install -q -r requirements.txt && pytest tests/ -v"

# ─── Status ───
status:
	cd docker && docker compose ps

logs:
	cd docker && docker compose logs -f

logs-%:
	cd docker && docker compose logs -f $*

# ─── Health Check ───
health:
	@echo "=== API Gateway ===";        curl -sf http://localhost:8080/health | python3 -m json.tool 2>/dev/null || echo "UNREACHABLE"
	@echo "=== Problem Service ===";    curl -sf http://localhost:8081/health | python3 -m json.tool 2>/dev/null || echo "UNREACHABLE"
	@echo "=== Submission Service ==="; curl -sf http://localhost:8082/health | python3 -m json.tool 2>/dev/null || echo "UNREACHABLE"
	@echo "=== Worker ===";             curl -sf http://localhost:8083/health | python3 -m json.tool 2>/dev/null || echo "UNREACHABLE"
	@echo "=== Frontend ===";           curl -sfI http://localhost:4200 | head -1 || echo "UNREACHABLE"
	@echo "=== NGINX ===";              curl -sf http://localhost/nginx-health | python3 -m json.tool 2>/dev/null || echo "UNREACHABLE"
	@echo "=== API via NGINX ===";      curl -sf http://localhost/api/problems | head -c 100 || echo "UNREACHABLE"
	@echo "=== Frontend via NGINX ==="; curl -sfI http://localhost/ | head -1 || echo "UNREACHABLE"
