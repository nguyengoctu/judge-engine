.PHONY: build-runners \
	dev dev-detached dev-stop dev-logs dev-status dev-clean dev-build \
	deploy-compose deploy-stop deploy-logs deploy-status deploy-clean \
	test test-java test-python health \
	k8s-up k8s-down \
	k8s-cluster k8s-fix-ingress k8s-install-keda k8s-uninstall-keda \
	k8s-load-images k8s-deploy k8s-push-runners \
	k8s-install-monitoring k8s-uninstall-monitoring k8s-import-dashboards \
	k8s-status k8s-logs k8s-health

# ─── Runner Images (sandbox) ───
build-runners:
	cd docker && docker compose --profile build build

# ═══════════════════════════════════════════════════════════════
# ─── Docker Compose: Dev ───
# ═══════════════════════════════════════════════════════════════

dev: build-runners
	cd docker && docker compose -f docker-compose.yml -f docker-compose.dev.yml up --build

dev-detached: build-runners
	cd docker && docker compose -f docker-compose.yml -f docker-compose.dev.yml up --build -d

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

# ═══════════════════════════════════════════════════════════════
# ─── Docker Compose: Deploy (prod) ───
# ═══════════════════════════════════════════════════════════════

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

# ═══════════════════════════════════════════════════════════════
# ─── Test ───
# ═══════════════════════════════════════════════════════════════

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

# ─── Health Check (Compose) ───
health:
	@echo "=== API Gateway ===";        curl -sf http://localhost:8080/health | python3 -m json.tool 2>/dev/null || echo "UNREACHABLE"
	@echo "=== Problem Service ===";    curl -sf http://localhost:8081/health | python3 -m json.tool 2>/dev/null || echo "UNREACHABLE"
	@echo "=== Submission Service ==="; curl -sf http://localhost:8082/health | python3 -m json.tool 2>/dev/null || echo "UNREACHABLE"
	@echo "=== Worker ===";             curl -sf http://localhost:8083/health | python3 -m json.tool 2>/dev/null || echo "UNREACHABLE"
	@echo "=== Frontend ===";           curl -sfI http://localhost:4200 | head -1 || echo "UNREACHABLE"
	@echo "=== NGINX ===";              curl -sf http://localhost/nginx-health | python3 -m json.tool 2>/dev/null || echo "UNREACHABLE"
	@echo "=== API via NGINX ===";      curl -sf http://localhost/api/problems | head -c 100 || echo "UNREACHABLE"
	@echo "=== Frontend via NGINX ==="; curl -sfI http://localhost/ | head -1 || echo "UNREACHABLE"

# ═══════════════════════════════════════════════════════════════
# ─── Kubernetes (Kind)
#
#   make k8s-up    — spin up full cluster (mirroring: docker compose up)
#   make k8s-down  — destroy everything  (mirroring: docker compose down)
# ═══════════════════════════════════════════════════════════════

# ─── 🚀 ONE COMMAND: UP ───────────────────────────────────────
# Order: cluster → KEDA (inside k8s-cluster) → app images →
#        helm deploy → runner images → monitoring + dashboards
k8s-up: k8s-cluster k8s-load-images k8s-install-monitoring k8s-deploy k8s-push-runners
	@echo ""
	@echo "╔══════════════════════════════════════════════════════════════╗"
	@echo "║  Judge Engine is fully deployed and ready!                   ║"
	@echo "╚══════════════════════════════════════════════════════════════╝"
	@echo "→ Application : http://localhost"
	@echo "→ Grafana     : kubectl port-forward -n monitoring svc/my-prometheus-grafana 3000:80"
	@echo "→ Status      : make k8s-status"
	@echo "→ Health      : make k8s-health"

# ─── 💣 ONE COMMAND: DOWN ─────────────────────────────────────
# Kind cluster deletion nukes everything: namespaces, volumes, images loaded into cluster
k8s-down:
	@echo "Destroying Kind cluster (removes all namespaces, volumes, releases)..."
	kind delete cluster --name judge-engine
	@echo "Cluster deleted ✅"

# ═══════════════════════════════════════════════════════════════
# ─── Step 1: Cluster + Ingress + Metrics Server + KEDA ───
# ═══════════════════════════════════════════════════════════════

k8s-cluster:
	@echo "=== [1/5] Creating Kind cluster ==="
	kind create cluster --name judge-engine --config k8s/kind-config.yml || true
	@echo "--- Installing Ingress NGINX ---"
	kubectl apply -f https://kind.sigs.k8s.io/examples/ingress/deploy-ingress-nginx.yaml
	kubectl wait --namespace ingress-nginx \
		--for=condition=ready pod \
		--selector=app.kubernetes.io/component=controller \
		--timeout=120s
	$(MAKE) k8s-fix-ingress
	@echo "--- Installing Metrics Server ---"
	kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
	kubectl patch deployment metrics-server -n kube-system \
		--type='json' \
		-p='[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]'
	kubectl rollout status deployment/metrics-server -n kube-system --timeout=120s
	$(MAKE) k8s-install-keda

k8s-fix-ingress:
	@echo "--- Patching Ingress NGINX for control-plane node ---"
	kubectl patch deployment ingress-nginx-controller -n ingress-nginx \
		-p '{"spec":{"template":{"spec":{"nodeSelector":{"ingress-ready":"true"},"tolerations":[{"key":"node-role.kubernetes.io/control-plane","operator":"Equal","effect":"NoSchedule"}]}}}}'
	kubectl wait --namespace ingress-nginx \
		--for=condition=ready pod \
		--selector=app.kubernetes.io/component=controller \
		--timeout=120s

k8s-install-keda:
	@echo "--- Installing KEDA ---"
	helm repo add kedacore https://kedacore.github.io/charts 2>/dev/null || true
	helm repo update kedacore
	helm upgrade --install keda kedacore/keda \
		--namespace keda --create-namespace \
		--wait --timeout 120s
	@echo "KEDA installed ✅"

k8s-uninstall-keda:
	helm uninstall keda --namespace keda 2>/dev/null || true
	kubectl delete namespace keda 2>/dev/null || true

# ═══════════════════════════════════════════════════════════════
# ─── Step 2: Build & load app images into cluster ───
# ═══════════════════════════════════════════════════════════════

k8s-load-images:
	@echo "=== [2/5] Building & loading app images ==="
	docker build -t api-gateway:latest       ./services/api-gateway
	docker build -t problem-service:latest   ./services/problem-service
	docker build -t submission-service:latest ./services/submission-service
	docker build -t worker:latest            ./services/worker
	docker build -t frontend:latest          ./services/frontend
	kind load docker-image \
		api-gateway:latest \
		problem-service:latest \
		submission-service:latest \
		worker:latest \
		frontend:latest \
		--name judge-engine
	@echo "Images loaded ✅"

# ═══════════════════════════════════════════════════════════════
# ─── Step 3: Deploy application via Helm ───
# ═══════════════════════════════════════════════════════════════

k8s-deploy:
	@echo "=== [4/5] Deploying Judge Engine via Helm ==="
	helm upgrade --install dev k8s/helm/judge-engine/ \
		--namespace judge-engine --create-namespace \
		--timeout 300s
	@echo "Waiting for core services (excluding worker)..."
	kubectl wait --for=condition=ready pod \
		-l "app in (dev-judge-engine-api-gateway,dev-judge-engine-frontend,dev-judge-engine-submission-service,dev-judge-engine-rabbitmq,dev-judge-engine-redis,dev-judge-engine-registry)" \
		-n judge-engine --timeout=240s 2>/dev/null || true
	@echo "Application deployed ✅ (worker will be ready after runner images are pushed)"

# ═══════════════════════════════════════════════════════════════
# ─── Step 4: Build & push runner images to in-cluster registry ───
# ═══════════════════════════════════════════════════════════════

k8s-push-runners:
	@echo "=== [5/5] Building & pushing runner images to in-cluster registry ==="
	kubectl wait --for=condition=ready pod -l app=registry -n judge-engine --timeout=120s
	@kubectl port-forward -n judge-engine svc/dev-judge-engine-registry 5000:5000 &>/dev/null & \
	PF_PID=$$! && sleep 3 && \
	for lang in python javascript java; do \
		echo "Building judge-runner-$$lang..." && \
		docker build -t localhost:5000/judge-runner-$$lang:latest \
			-f docker/runners/Dockerfile.$$lang docker/runners/ && \
		echo "Pushing judge-runner-$$lang..." && \
		docker push localhost:5000/judge-runner-$$lang:latest; \
	done; \
	kill $$PF_PID 2>/dev/null || true
	@echo "Runner images pushed ✅"

# ═══════════════════════════════════════════════════════════════
# ─── Step 5: Monitoring (Prometheus + Grafana + Dashboards) ───
# ═══════════════════════════════════════════════════════════════

k8s-install-monitoring:
	@echo "=== [3/5] Installing Prometheus & Grafana stack ==="
	helm repo add prometheus-community https://prometheus-community.github.io/helm-charts 2>/dev/null || true
	helm repo update prometheus-community
	helm upgrade --install my-prometheus prometheus-community/kube-prometheus-stack \
		--namespace monitoring --create-namespace \
		--set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false \
		--set prometheus.prometheusSpec.podMonitorSelectorNilUsesHelmValues=false \
		--wait --timeout 300s
	@echo "Monitoring installed ✅"
	@echo "Grafana Admin Password:"
	@kubectl get secret -n monitoring my-prometheus-grafana \
		-o jsonpath='{.data.admin-password}' | base64 -d && echo ""
	$(MAKE) k8s-import-dashboards

k8s-import-dashboards:
	@echo "--- Importing Grafana dashboards ---"
	@lsof -ti:3000 | xargs kill -9 2>/dev/null || true
	@GRAFANA_PASS=$$(kubectl get secret -n monitoring my-prometheus-grafana \
		-o jsonpath='{.data.admin-password}' | base64 -d) && \
	kubectl port-forward -n monitoring svc/my-prometheus-grafana 3000:80 &>/dev/null & \
	PF_PID=$$! && \
	echo "Waiting for Grafana API..." && \
	for i in $$(seq 1 30); do \
		sleep 3 && \
		STATUS=$$(curl -s -o /dev/null -w "%{http_code}" -u admin:$$GRAFANA_PASS http://localhost:3000/api/org) && \
		[ "$$STATUS" = "200" ] && echo "Grafana ready ($$i)" && break || echo "Not ready yet ($$i/30, HTTP $$STATUS)"; \
	done && \
	python3 -c "\
import json; \
d=json.load(open('k8s/grafana/judge-engine-dashboard.json')); \
d.pop('id',None); \
json.dump({'dashboard':d,'overwrite':True,'folderId':0},open('/tmp/gf-import.json','w'))" && \
	curl -s -X POST \
		-H 'Content-Type: application/json' \
		-u admin:$$GRAFANA_PASS \
		http://localhost:3000/api/dashboards/db \
		-d @/tmp/gf-import.json \
		| python3 -c "import json,sys; r=json.load(sys.stdin); print('Dashboard:', r.get('status','FAILED'), r.get('url',''))" && \
	kill $$PF_PID 2>/dev/null || true
	@echo "Dashboards imported ✅"

k8s-uninstall-monitoring:
	helm uninstall my-prometheus -n monitoring 2>/dev/null || true
	kubectl delete namespace monitoring 2>/dev/null || true

# ═══════════════════════════════════════════════════════════════
# ─── Utilities ───
# ═══════════════════════════════════════════════════════════════

k8s-status:
	@echo "=== Pods ==="
	kubectl get pods -n judge-engine -o wide
	@echo ""
	@echo "=== KEDA ScaledObjects & HPA ==="
	kubectl get scaledobjects,hpa -n judge-engine 2>/dev/null || true
	@echo ""
	@echo "=== Services ==="
	kubectl get svc -n judge-engine
	@echo ""
	@echo "=== Ingress ==="
	kubectl get ingress -n judge-engine

k8s-logs:
	@echo "Usage: kubectl logs -n judge-engine deployment/dev-judge-engine-<service>"
	@echo "Available: api-gateway, problem-service, submission-service, worker, frontend"

k8s-health:
	@echo "=== Pod Readiness ==="
	kubectl get pods -n judge-engine --no-headers | awk '{printf "%-45s %s\n", $$1, $$2}'
	@echo ""
	@echo "=== Endpoint Health ==="
	@printf "Frontend:    "; curl -sf http://localhost/ -o /dev/null -w "HTTP %{http_code}\n" 2>/dev/null || echo "UNREACHABLE"
	@printf "API Gateway: "; curl -sf http://localhost/api/problems -o /dev/null -w "HTTP %{http_code}\n" 2>/dev/null || echo "UNREACHABLE"
