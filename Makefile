.PHONY: help build-images build-and-push-images k8s-dev k8s-production k8s k8s-delete

help: ## Display this help message.
	@echo "Please use \`make <target>\` where <target> is one of:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; \
	{printf "\033[36m%-40s\033[0m %s\n", $$1, $$2}'

build-images: ## Build Docker images.
	docker image build -t ghcr.io/ajharry69/keycloak:26.3.1 .

build-and-push-images: build-images ## Build and push Docker images.
	docker image push ghcr.io/ajharry69/keycloak:26.3.1

k8s-dev: ## Start kubernetes development cluster.
	kubectl apply -k ./ops/k8s/overlays/development/

k8s-dev-delete: ## Delete kubernetes development cluster.
	kubectl delete -k ./ops/k8s/overlays/development/

k8s-production: ## Start kubernetes production cluster.
	kubectl apply -k ./ops/k8s/overlays/production/

k8s-production-delete: ## Delete kubernetes production cluster.
	kubectl delete -k ./ops/k8s/overlays/production/

k8s: k8s-production ## Start kubernetes production cluster.

k8s-delete: k8s-production-delete ## Start kubernetes production cluster.
