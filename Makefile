.PHONY: dev dev-detached stop clean build test test-java test-python test-frontend status logs health build-runners \
	k8s-cluster k8s-delete k8s-load-images k8s-deploy k8s-fix-ingress k8s-status k8s-logs k8s-health

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

.PHONY: k8s-cluster k8s-delete k8s-load-images k8s-deploy k8s-fix-ingress k8s-status k8s-logs k8s-health

# ─── Kind Cluster ───
k8s-cluster:
	kind create cluster --name judge-engine --config k8s/kind-config.yml
	kubectl apply -f https://kind.sigs.k8s.io/examples/ingress/deploy-ingress-nginx.yaml
	kubectl wait --namespace ingress-nginx \
		--for=condition=ready pod \
		--selector=app.kubernetes.io/component=controller \
		--timeout=120s
	$(MAKE) k8s-fix-ingress
	kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
	kubectl patch deployment metrics-server -n kube-system --type='json' -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls"}]'
	kubectl wait --for=condition=ready pod -l k8s-app=metrics-server -n kube-system --timeout=120s


k8s-clean:
	@echo "Deleting app resources (keeping cluster)..."
	-kubectl delete -f k8s/ingress.yml
	-kubectl delete -f k8s/frontend.yml
	-kubectl delete -f k8s/worker.yml
	-kubectl delete -f k8s/submission-service.yml
	-kubectl delete -f k8s/problem-service.yml
	-kubectl delete -f k8s/api-gateway.yml
	-kubectl delete -f k8s/redis.yml
	-kubectl delete -f k8s/rabbitmq.yml
	-kubectl delete -f k8s/judge-db.yml
	-kubectl delete -f k8s/secrets.yml
	-kubectl delete -f k8s/configMap.yml
	-kubectl delete -f k8s/namespace.yml
	@echo "Resources deleted. Cluster still running."

k8s-delete:
	kind delete cluster --name judge-engine

# ─── Build & Load Images ───
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

# ─── Fix Ingress Controller → control-plane node ───
k8s-fix-ingress:
	kubectl patch deployment ingress-nginx-controller -n ingress-nginx \
		-p '{"spec":{"template":{"spec":{"nodeSelector":{"ingress-ready":"true"},"tolerations":[{"key":"node-role.kubernetes.io/control-plane","operator":"Equal","effect":"NoSchedule"}]}}}}'
	@echo "Waiting for ingress controller to be ready..."
	kubectl wait --namespace ingress-nginx \
		--for=condition=ready pod \
		--selector=app.kubernetes.io/component=controller \
		--timeout=120s

# ─── One-Command Full Deploy ───
k8s-deploy:
	@echo "╔══════════════════════════════════════════╗"
	@echo "║  Judge Engine — K8s Deploy          	  ║"
	@echo "╚══════════════════════════════════════════╝"

	@echo "\n── 1/3 Build & Load images ──"
	$(MAKE) k8s-load-images

	@echo "\n── 2/3 Applying config + deploying infra ──"
	kubectl apply -f k8s/namespace.yml
	kubectl config set-context --current --namespace=judge-engine
	kubectl apply -f k8s/configMap.yml
	kubectl apply -f k8s/secrets.yml

	@echo "Deploying infra (DB, RabbitMQ, Redis)..."
	kubectl apply -f k8s/judge-db.yml
	kubectl apply -f k8s/rabbitmq.yml
	kubectl apply -f k8s/redis.yml
	@echo "Waiting for infra pods to be created..."
	@sleep 5
	kubectl wait --for=condition=ready pod -l app=judge-db --timeout=120s
	kubectl wait --for=condition=ready pod -l app=rabbitmq --timeout=120s
	kubectl wait --for=condition=ready pod -l app=redis --timeout=120s
	@echo "Infra ready ✅"

	@echo "\n── 3/3 Deploying app services ──"
	kubectl apply -f k8s/api-gateway.yml
	kubectl apply -f k8s/problem-service.yml
	kubectl apply -f k8s/submission-service.yml
	kubectl apply -f k8s/worker.yml
	kubectl apply -f k8s/frontend.yml
	kubectl apply -f k8s/ingress.yml
	@echo "Waiting for app services to be ready..."
	@sleep 5
	kubectl wait --for=condition=ready pod -l app=api-gateway --timeout=120s
	kubectl wait --for=condition=ready pod -l app=frontend --timeout=120s
	kubectl wait --for=condition=ready pod -l app=problem-service --timeout=180s
	kubectl wait --for=condition=ready pod -l app=submission-service --timeout=120s

	@echo "✅ Deploy complete"
	@echo "→ http://localhost"
	@echo "→ make k8s-status"
	@echo "→ make k8s-health"

# ─── Status & Monitoring ───
k8s-status:
	@echo "=== Pods ==="
	kubectl get pods -o wide
	@echo "\n=== Services ==="
	kubectl get svc
	@echo "\n=== Ingress ==="
	kubectl get ingress
	@echo "\n=== PVCs ==="
	kubectl get pvc

k8s-logs:
	@echo "Usage: kubectl logs deployment/<name>"
	@echo "  api-gateway | problem-service | submission-service | worker | frontend"

k8s-health:
	@echo "=== Pod Readiness ==="
	@kubectl get pods --no-headers | awk '{printf "%-40s %s\n", $$1, $$2}'
	@echo "\n=== Ingress Health ==="
	@printf "Frontend:        "; curl -sf http://localhost/ -o /dev/null -w "HTTP %{http_code}\n" 2>/dev/null || echo "UNREACHABLE"
	@printf "API Problems:    "; curl -sf http://localhost/api/problems -o /dev/null -w "HTTP %{http_code}\n" 2>/dev/null || echo "UNREACHABLE"
	@printf "API Submissions: "; curl -sf http://localhost/api/queue/status -o /dev/null -w "HTTP %{http_code}\n" 2>/dev/null || echo "UNREACHABLE"