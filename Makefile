.PHONY: dev dev-detached stop clean build test test-java test-python test-frontend status logs health build-runners

# ─── Runner Images (sandbox) ───
build-runners:
	cd docker && docker compose --profile build build

# ─── Development ───
dev-detached: build-runners
	cd docker && docker compose -f docker-compose.yml -f docker-compose.dev.yml up --build -d

dev: build-runners
	cd docker && docker compose -f docker-compose.yml -f docker-compose.dev.yml up --build

dev-stop:
	cd docker && docker compose -f docker-compose.yml -f docker-compose.dev.yml down

dev-logs:
	cd docker && docker compose -f docker-compose.yml -f docker-compose.dev.yml logs -f

dev-status:
	cd docker && docker compose -f docker-compose.yml -f docker-compose.dev.yml ps

dev-clean:
	cd docker && docker compose -f docker-compose.yml -f docker-compose.dev.yml down -v --rmi local

dev-build:
	cd docker && docker compose -f docker-compose.yml -f docker-compose.dev.yml build

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


# deploy
deploy-compose: build-runners
	cd docker && docker compose -f docker-compose.yml -f docker-compose.prod.yml up --build -d
deploy-stop: 
	cd docker && docker compose -f docker-compose.yml -f docker-compose.prod.yml down
deploy-logs: 
	cd docker && docker compose -f docker-compose.yml -f docker-compose.prod.yml logs -f
deploy-status: 
	cd docker && docker compose -f docker-compose.yml -f docker-compose.prod.yml ps
deploy-clean:
	cd docker && docker compose -f docker-compose.yml -f docker-compose.prod.yml down -v --rmi local

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

# kind
k8s-cluster:
	kind create cluster --name judge-engine --config k8s/kind-config.yml
	docker build -t api-gateway:latest ./services/api-gateway
	docker build -t problem-service:latest ./services/problem-service
	docker build -t submission-service:latest ./services/submission-service
	docker build -t worker:latest ./services/worker
	docker build -t frontend:latest ./frontend
	kind load docker-image api-gateway:latest --name judge-engine
	kind load docker-image problem-service:latest --name judge-engine
	kind load docker-image submission-service:latest --name judge-engine
	kind load docker-image worker:latest --name judge-engine
	kind load docker-image frontend:latest --name judge-engine
	kubectl apply -f https://kind.sigs.k8s.io/examples/ingress/deploy-ingress-nginx.yaml
	kubectl wait --namespace ingress-nginx \
		--for=condition=ready pod \
		--selector=app.kubernetes.io/component=controller \
		--timeout=120s
k8s-delete:
	kind delete cluster --name judge-engine
k8s-load-images:
	docker build -t api-gateway:latest ./services/api-gateway
	docker build -t problem-service:latest ./services/problem-service
	docker build -t submission-service:latest ./services/submission-service
	docker build -t worker:latest ./services/worker
	docker build -t frontend:latest ./services/frontend
	kind load docker-image api-gateway:latest --name judge-engine
	kind load docker-image problem-service:latest --name judge-engine
	kind load docker-image submission-service:latest --name judge-engine
	kind load docker-image worker:latest --name judge-engine
	kind load docker-image frontend:latest --name judge-engine