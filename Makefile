
# Set Bash as the shell so that Bash-specific syntax works
SHELL := /bin/bash

# Load environment variables from .env file
ifneq (,$(wildcard ./.env))
	include .env
	export
endif

# Docker configuration
DOCKER_COMPOSE_DIR = docker/dev
DOCKER_IMAGE_NAME = dev-env
DOCKER_COMPOSE_FILE = $(DOCKER_COMPOSE_DIR)/docker-compose.dev.yml

# Docker run command that includes environment variables
COMPOSE = docker compose --file $(DOCKER_COMPOSE_FILE)
RUN_IN_DEV_ENV = $(COMPOSE) run --rm --service-ports $(DOCKER_IMAGE_NAME)

.PHONY: install clean dev run bootstrap synth diff deploy destroy

bootstrap: ## bootstrap the environment by initializing project with the configured package manager
	$(RUN_IN_DEV_ENV) /app/infrastructure/docker/dev/bootstrap.sh

install: create-env-file-if-missing verify-env docker-build aws-configure-check ## Install everything needed for development
install-force: create-env-file-if-missing verify-env docker-build-force aws-configure ## Install everything needed for development

dev: ## Start a development shell (alias to bash)
	@$(MAKE) bash

bash: verify-env ## Start a development shell
	@if [ $$( $(COMPOSE) ps --status running --services | grep -c cdk) -gt 0 ]; then \
		echo "cdk container is already running you should stop it first. If you want to force it down, use 'make stop'"; \
		exit 1; \
	fi
	$(RUN_IN_DEV_ENV) bash
	@echo "Cleaning up unused containers..."; \
	$(COMPOSE) down --remove-orphans; \
	
run: ## Run arbitrary command in dev-env container eg. make run cmd="npm run test"
	$(RUN_IN_DEV_ENV) $(cmd)

clean: npm-clean docker-clean ## Clean everything (containers, dependencies, generated files)


# AWS CLI Commands
aws-configure-check: ## Check if AWS profile is configured (fallback on aws-configure if not)
	@echo "Checking AWS profile configuration..."
	@$(RUN_IN_DEV_ENV) aws configure list >/dev/null 2>&1 || ( \
		echo "No AWS profile configured. Running aws-configure to set up credentials"; \
		$(MAKE) aws-configure; \
		exit 1 \
	)
	@echo "✓ AWS profile configured"

aws-configure: ## Configure AWS profile (sso or access key & secret)
	@echo "Choose AWS authentication method:"
	@echo "1) SSO login"
	@echo "2) Default credentials (access key & secret)"
	@read -p "Enter choice (1 or 2): " choice; \
	case $$choice in \
		1) \
			echo "Configuring AWS SSO..."; \
			$(RUN_IN_DEV_ENV) aws configure sso --profile $(AWS_PROFILE) --use-device-code --no-browser;; \
		2) \
			echo "Configuring AWS credentials..."; \
			$(RUN_IN_DEV_ENV) aws configure --profile $(AWS_PROFILE);; \
		*) \
			echo "Invalid choice"; \
			exit 1;; \
	esac
	@echo "✓ AWS profile configured"
	exit 0

aws-login:
	$(RUN_IN_DEV_ENV) aws sso login --profile $(AWS_PROFILE) --use-device-code --no-browser


# CDK commands
cdk-bootstrap: ## Bootstrap CDK in your AWS account
	$(RUN_IN_DEV_ENV) $(PACKAGE_MANAGER) cdk bootstrap

cdk-synth: ## Synthesize CloudFormation template
	$(RUN_IN_DEV_ENV) $(PACKAGE_MANAGER) cdk synth

cdk-diff: ## Show changes to be deployed
	$(RUN_IN_DEV_ENV) $(PACKAGE_MANAGER) cdk diff

cdk-deploy: ## Deploy the CDK stack
	$(RUN_IN_DEV_ENV) $(PACKAGE_MANAGER) cdk deploy --require-approval never

cdk-destroy: ## Destroy the CDK stack
	$(RUN_IN_DEV_ENV) $(PACKAGE_MANAGER) cdk destroy --force


# Docker commands
docker-build: ## Build the Docker image
	$(COMPOSE) build

docker-build-force: ## Build the Docker image without cache
	$(COMPOSE) build --no-cache

docker-build-debug: ## Build the Docker image with debug output
	$(COMPOSE) build --no-cache --progress=plain

docker-clean: ## Remove Docker containers, images, and volumes
	$(COMPOSE) down --rmi all --volumes --remove-orphans

docker-down: ## Stop all containers ()
	$(COMPOSE) down --remove-orphans


# Node package manager commands (run inside container)
npm-install: ## Install dependencies
	$(RUN_IN_DEV_ENV) $(PACKAGE_MANAGER) install

npm-upgrade: ## Upgrade all dependencies
	$(RUN_IN_DEV_ENV) $(PACKAGE_MANAGER) upgrade
	$(RUN_IN_DEV_ENV) $(PACKAGE_MANAGER) install

npm-clean: ## Clean dependencies and generated files
	$(RUN_IN_DEV_ENV) $(PACKAGE_MANAGER) run clean


# Miscellaneous Commands
corepack-upgrade: ## Upgrade corepack to the latest version (use when you see that a newer version current package manager is available)
	$(RUN_IN_DEV_ENV) corepack up


# Internal Utility Commands
help: ## Display this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

create-env-file-if-missing: ## Create a .env file if it doesn't exist
	@if [ ! -f .env ]; then \
		echo ".env file not found. Creating from template..."; \
		cp .env.example .env; \
		echo "Please fill in the .env file with your own values then rerun your command."; \
		exit 1; \
	fi

verify-env: ## Verify environment variables are set
	@echo "Verifying environment variables..."
	@test -n "$(AWS_PROFILE)" || (echo "AWS_PROFILE is not set" && exit 1)
	@test -n "$(PACKAGE_MANAGER)" || (echo "PACKAGE_MANAGER is not set" && exit 1)
	@echo "Environment variables verified ✓"

.DEFAULT_GOAL := help 