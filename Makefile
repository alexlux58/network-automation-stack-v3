# NetBox + Nautobot Stack Makefile
SHELL := /bin/bash
ENV ?= .env

.PHONY: help up down restart logs status init nb-admin na-admin nb-collectstatic clean

# Default target
help: ## Show this help message
	@echo "NetBox + Nautobot Stack Management"
	@echo "=================================="
	@echo ""
	@echo "Available commands:"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

up: ## Start the entire stack
	@echo "🚀 Starting NetBox + Nautobot stack..."
	@./scripts/first-run.sh
	@docker compose up -d
	@$(MAKE) status

down: ## Stop the entire stack
	@echo "🛑 Stopping NetBox + Nautobot stack..."
	@docker compose down

restart: ## Restart applications (NetBox and Nautobot)
	@echo "🔄 Restarting applications..."
	@docker compose restart netbox nautobot netbox-worker nautobot-worker

logs: ## Show logs from all services
	@echo "📋 Showing logs (Ctrl+C to exit)..."
	@docker compose logs -f --tail=200

status: ## Show status of all containers
	@echo "📊 Container status:"
	@docker ps --format "table {{.Names}}\t{{.Ports}}\t{{.Status}}"

init: ## First-time setup (generate secrets, create .env)
	@echo "🔧 Running first-time setup..."
	@./scripts/first-run.sh

nb-admin: ## Create NetBox superuser interactively
	@echo "👤 Creating NetBox superuser..."
	@docker compose exec netbox python manage.py createsuperuser

na-admin: ## Create Nautobot superuser non-interactively from .env
	@echo "👤 Creating Nautobot superuser..."
	@docker compose exec -e DJANGO_SUPERUSER_USERNAME=$${NAUTOBOT_SUPERUSER_NAME} \
	                    -e DJANGO_SUPERUSER_EMAIL=$${NAUTOBOT_SUPERUSER_EMAIL} \
	                    -e DJANGO_SUPERUSER_PASSWORD=$${NAUTOBOT_SUPERUSER_PASSWORD} \
	                    nautobot nautobot-server createsuperuser --noinput || true

nb-collectstatic: ## Collect NetBox static files
	@echo "📦 Collecting NetBox static files..."
	@docker compose exec netbox python manage.py collectstatic --noinput

nb-shell: ## Open NetBox Django shell
	@echo "🐍 Opening NetBox Django shell..."
	@docker compose exec netbox python manage.py shell

na-shell: ## Open Nautobot Django shell
	@echo "🐍 Opening Nautobot Django shell..."
	@docker compose exec nautobot nautobot-server shell

backup: ## Create backup of databases and media files
	@echo "💾 Creating backup..."
	@./scripts/backup.sh

restore: ## Restore from backup (usage: make restore BACKUP_DATE=20240101_120000)
	@echo "📥 Restoring from backup..."
	@if [ -z "$(BACKUP_DATE)" ]; then \
		echo "❌ Please specify BACKUP_DATE (e.g., make restore BACKUP_DATE=20240101_120000)"; \
		exit 1; \
	fi
	@./scripts/restore.sh $(BACKUP_DATE)

clean: ## Remove all containers, volumes, and networks
	@echo "🧹 Cleaning up everything..."
	@docker compose down -v --remove-orphans
	@docker system prune -f

# Development helpers
dev-logs: ## Show logs from specific service (usage: make dev-logs SERVICE=netbox)
	@if [ -z "$(SERVICE)" ]; then \
		echo "❌ Please specify SERVICE (e.g., make dev-logs SERVICE=netbox)"; \
		exit 1; \
	fi
	@docker compose logs -f $(SERVICE)

dev-shell: ## Open shell in specific service (usage: make dev-shell SERVICE=netbox)
	@if [ -z "$(SERVICE)" ]; then \
		echo "❌ Please specify SERVICE (e.g., make dev-shell SERVICE=netbox)"; \
		exit 1; \
	fi
	@docker compose exec $(SERVICE) /bin/bash

# Health checks
health: ## Check health of all services
	@echo "🏥 Checking service health..."
	@docker compose ps
	@echo ""
	@echo "Health check details:"
	@docker compose exec postgres pg_isready -U netops && echo "✅ PostgreSQL: Healthy" || echo "❌ PostgreSQL: Unhealthy"
	@docker compose exec redis valkey-cli ping && echo "✅ Redis: Healthy" || echo "❌ Redis: Unhealthy"
	@docker compose exec redis-cache valkey-cli ping && echo "✅ Redis Cache: Healthy" || echo "❌ Redis Cache: Unhealthy"
	@curl -s -o /dev/null -w "%{http_code}" http://localhost/netbox/ | grep -q "200\|302" && echo "✅ NetBox: Healthy" || echo "❌ NetBox: Unhealthy"
	@curl -s -o /dev/null -w "%{http_code}" http://localhost/nautobot/ | grep -q "200\|302" && echo "✅ Nautobot: Healthy" || echo "❌ Nautobot: Unhealthy"
