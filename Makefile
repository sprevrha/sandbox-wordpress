# Makefile
# This Makefile provides a structured way to manage Docker Compose services
# for a WordPress application, including loading environment variables,
# starting, stopping, and building services, and validating configurations.
# It uses a modular approach to load environment variables from .env files
# and supports debugging output.
# It also includes targets for health checks, cleaning up resources, and showing configurations.
# It is designed to be used in a development environment with Docker Compose.
# Ensure that the Makefile is run in the directory in which it is located.

# Generate debug output
DEBUG_MAKE = OFF

# Include the make_env.mk file which defines the load_env_vars and helper functions
include make_env.mk

# Set the current working directory (CWD) to the directory of this Makefile and export it
# While the docker compose command will use the current working directory,
# we also want to ensure that the CWD is available as an environment variable for 
# entries in the container configuration files that need absolute paths, for instance volumes: mappings.
# This must be a Linux-style path, so we use forward slashes.
# If you are running on Windows, ensure that the CWD is set correctly in your environment
CWD := $(shell pwd)
export CWD
$(call debug,"CWD: $(CWD)")	

# --- START .env file loading ---
# This variable specifies the .env file to load
# If already defined in the environment, it will not be overwritten.
PRIMARY_ENV_FILE := .env
# Define empty and space variables in the main Makefile too, for consistency
empty :=
space := $(empty) $(empty)
# 1. Load the primary .env file(s)
# This call will define variables like STAGE and ENV_FILE
$(call debug,"Loading environment variables from: $(PRIMARY_ENV_FILE)")	
$(call load_env_vars,$(PRIMARY_ENV_FILE))
# 2. Now, load any additional .env files specified by the ENV_FILE variable.
# This variable should now be defined from the previous step (Step 1).
# The order in $(ENV_FILE) (e.g., ".env,${STAGE}/.env") will determine precedence.
# Variables in later files will override those in earlier files,
# unless they are already set in the shell environment (highest precedence).
$(if $(ENV_FILE),$(call load_env_vars,$(ENV_FILE)),$(eval ENV_FILE := $(PRIMARY_ENV_FILE)))
# --- END .env file loading ---

# --- Docker Compose Command Base ---
DOCKER_COMPOSE_CMD = docker compose --project-name $(PROJECT_NAME)\
	$(strip $(foreach f,$(DOCKER_COMPOSE_FILE),--file $(f)))\
	$(strip $(foreach f,$(DOCKER_COMPOSE_ENV_FILE),--env-file $(f)))
$(call debug,"Docker Compose command: $(DOCKER_COMPOSE_CMD)")

# --- Targets ---
# Define the default target
# This will be executed when you run `make` without any arguments.
# It will start the Docker Compose stack.
# If you want to run a specific service, you can use `make up SERVICE=<service_name>`.
# The SERVICE variable can be used to specify a single service to start.
all: up  ## Start the Docker Compose stack (default target)

# Define a variable to capture the service argument
SERVICE ?= # Default to empty, meaning all services
$(info SERVICE: $(SERVICE))
# The up target with optional service argument
up: validate pull build ## Start the Docker Compose stack (pulls, builds, then starts)
	@echo "Starting Docker Compose services: $(if $(SERVICE),$(SERVICE),all) ..."
	$(DOCKER_COMPOSE_CMD) up -d --remove-orphans $(if $(SERVICE),$(SERVICE),)
	@echo "Docker Compose services started: $(if $(SERVICE),$(SERVICE),all)."
	@echo "Use 'make down' to stop all services or 'make down SERVICE=<service_name>' to stop a specific service."

down: ## Stop and remove Docker Compose services
	@echo "Stopping and removing Docker Compose services: $(if $(SERVICE),$(SERVICE),all) ..."
	@$(DOCKER_COMPOSE_CMD) down --remove-orphans $(if $(SERVICE),$(SERVICE),)
	@echo "Docker Compose services stopped and removed: $(if $(SERVICE),$(SERVICE),all)."

restart: ## Restart the Docker Compose stack (stops, removes, then starts)
	@echo "Restarting Docker Compose services: $(if $(SERVICE),$(SERVICE),all) ..."
	@$(DOCKER_COMPOSE_CMD) restart $(if $(SERVICE),$(SERVICE),)
	@echo "Docker Compose services restarted: $(if $(SERVICE),$(SERVICE),all)."

build: ## Build Docker images defined in the compose file
	@echo "Building Docker Compose images: $(if $(SERVICE),$(SERVICE),all) ..."
	@$(DOCKER_COMPOSE_CMD) build $(if $(SERVICE),$(SERVICE),)
	@echo "Docker Compose images built: $(if $(SERVICE),$(SERVICE),all)."

remove: ## Remove Docker images defined in the compose file
	@echo "Removing Docker images: $(if $(SERVICE),$(SERVICE),all) ..."
	@$(DOCKER_COMPOSE_CMD) rm --force $(if $(SERVICE),$(SERVICE),)
	@echo "Docker images removed: $(if $(SERVICE),$(SERVICE),all)."
	
rebuild: ## Rebuild Docker images defined in the compose file and remove old containers
	@echo "Stopping and removing Docker Compose services and removing volumes: $(if $(SERVICE),$(SERVICE),all) ..."
	$(DOCKER_COMPOSE_CMD) down --volumes --remove-orphans $(if $(SERVICE),$(SERVICE),)
	@echo "Removing Docker images: $(if $(SERVICE),$(SERVICE),all) ..."
	@$(DOCKER_COMPOSE_CMD) rm --force $(if $(SERVICE),$(SERVICE),)
	@echo "Building Docker images: $(if $(SERVICE),$(SERVICE),all) ..."
	@$(DOCKER_COMPOSE_CMD) build $(if $(SERVICE),$(SERVICE),)
	@echo "Starting Docker Compose services: $(if $(SERVICE),$(SERVICE),all) ..."
	$(DOCKER_COMPOSE_CMD) up -d --remove-orphans $(if $(SERVICE),$(SERVICE),)
	@echo "Docker Compose images rebuilt and started: $(if $(SERVICE),$(SERVICE),all)."

pull: ## Pull the latest images defined in the compose file
	@echo "Pulling Docker images: $(if $(SERVICE),$(SERVICE),all) ..."
	@$(DOCKER_COMPOSE_CMD) pull $(if $(SERVICE),$(SERVICE),)
	@echo "Docker images pulled: $(if $(SERVICE),$(SERVICE),all)."

validate: ## Validate the Docker Compose file and check for environment files
	@echo "Validating Docker Compose file..."
	$(foreach f,$(DOCKER_COMPOSE_FILE),\
		$(if $(wildcard $(f)),,\
			$(error "Docker Compose file '$(f)' not found!")))
	@echo "Validating environment files..."
	$(foreach f,$(DOCKER_COMPOSE_ENV_FILE),\
		$(if $(wildcard $(f)),,\
			$(error "Environment file '$(f)' not found!")))
	@echo "Running: $(DOCKER_COMPOSE_CMD) config"
	$(DOCKER_COMPOSE_CMD) config > /dev/null
	@echo "Docker Compose file is valid."

healthcheck: ## Check the health status of Docker Compose services
	@echo "Checking health status of Docker Compose services..."
	$(if $(SERVICE),\
		$(DOCKER_COMPOSE_CMD) ps | grep -E "Name|$(SERVICE)"; \
		,\
		$(DOCKER_COMPOSE_CMD) ps\
	)
	@echo "Health check completed."
	
clean: ## Stop, remove, and clean up Docker volumes (use with caution!)
	@echo "Cleaning up Docker volumes (use with caution!) for $(if $(SERVICE),$(SERVICE),"all") ..."
	@$(DOCKER_COMPOSE_CMD) down --volumes --rmi local --remove-orphans $(if $(SERVICE),$(SERVICE),)
	@echo "Docker volumes and images cleaned for $(if $(SERVICE),$(SERVICE),all)."

# Define a variable to capture the container name argument
CONTAINER ?= # Default to empty, meaning no container specified
USER ?= root 
login: ## Log in to a specific Docker container given by CONTAINER_NAME=<container_name> USER=<username (default:root)>
	@if [ -z "$(CONTAINER)" ]; then \
		echo "Error: No container specified. Use 'make login CONTAINER=<container_name> USER=<username (default:root)>'"; \
	else \
		docker exec -u $(USER) -it $(CONTAINER) sh; \
	fi
# --- Help Target ---
help: ## Show this help message
	@echo "Available targets:"
	$(info "  %-20s %s" "Target" "Description")
	@echo "-------------------- ----------------------------------------"
	@awk '/^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-20s\033[0m %s\n", $$1, substr($$0, index($$0, "##") + 3)}' $(MAKEFILE_LIST) | sort
	@echo "-------------------- ----------------------------------------"

show_logs: ## Show the #Docker logs for the specified service or all services
	@echo "Docker logs for: $(if $(SERVICE),$(SERVICE),all) ..."
	@$(DOCKER_COMPOSE_CMD) logs $(if $(SERVICE),$(SERVICE),)

show_vars: ## Show the current environment variables and their values
	@echo "These values are loaded from the specified .env files or your shell environment."
	@echo "CWD: $(CWD)"
	@echo "STAGE: $(STAGE)"
	@echo "ENV_FILE: $(ENV_FILE)"
	@echo "PROJECT_NAME: $(PROJECT_NAME)"
	@echo "FASTCGI_PORT: $(FASTCGI_PORT)"
	@echo "DOCKER_COMPOSE_FILE: $(DOCKER_COMPOSE_FILE)"
	@echo "DOCKER_COMPOSE_ENV_FILE: $(DOCKER_COMPOSE_ENV_FILE)"
	@echo "NGINX_ENV_FILE: $(NGINX_ENV_FILE)"
	@echo "CONF_DIR: $(CONF_DIR)"
	@echo "CODE_DIR: $(CODE_DIR)"
	@echo "LOG_DIR: $(LOG_DIR)"
	@echo "Docker compose command: $(DOCKER_COMPOSE_CMD)"

show_docker_environment: ## Show the Docker Compose configuration
	@echo "# Showing Docker Compose environment..."
	@printf "# %s" "$(DOCKER_COMPOSE_CMD) config --environment"
	@$(DOCKER_COMPOSE_CMD) config --environment

show_docker_config: ## Show the Docker Compose configuration
	@echo "# Showing Docker Compose configuration..."
	@printf "# %s" "$(DOCKER_COMPOSE_CMD) config"
	@$(DOCKER_COMPOSE_CMD) config

show_docker_command: ## Show the Docker Compose command
	@echo "# Showing Docker Compose command..."
	@printf "%s\n" "$(DOCKER_COMPOSE_CMD)"

# --- Example of custom targets ---
# Define the URL of your WordPress main page
WP_URL := https://$(APP_DOMAIN):$(DOCKER_HOST_HTTPS_PORT)

 
open-wordpress: ## Open the WordPress main page in the default web browser
	@echo "Opening WordPress in the default browser on $(WP_URL)..."
ifeq ($(OS),Windows_NT)
	@start "" "$(WP_URL)"
else
	@open $(WP_URL) || xdg-open $(WP_URL) || echo "Could not open browser. Please open $(WP_URL) manually."
endif

.PHONY: all up down restart remove rebuild build pull validate clean show_logs show_vars show_docker_compose_config healthcheck help open-wordpress login

# --- End of Makefile ---
