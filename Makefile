# ENV_FILE = $(shell [ -e ".env" ] && echo ".env" || echo ".env.public")

# include $(ENV_FILE)

.DEFAULT_GOAL := help # when you run make, it defaults to printing available commands

# The name of container image
COMPOSE_PROJECT_NAME = personal-blog
# Available platforms: linux/amd64 | linux/arm64/v8 | linux/x86_64 | linux/arm/v7
PLATFORM = linux/amd64

DEV_VOLUME = \
	-v $(DIR):/app \
	-v /app/node_modules \
	-v $(COMPOSE_PROJECT_NAME)-packages:/app/node_modules

ifeq ($(OS),Windows_NT)
	DIR := $(shell powershell "(New-Object -ComObject Scripting.FileSystemObject).GetFolder('.').ShortPath")
else
	DIR := "$$(pwd)"
endif

.PHONY: docker-clean
docker-clean: ## stop+kill all running containers. prune stopped containers. remove all untagged images
ifeq ($(OS),Windows_NT)
	powershell "docker ps -qa | foreach-object {docker kill $$_}; docker container prune --force; docker system prune --force;"
else
	docker ps -qa | xargs docker kill; docker container prune --force; docker system prune --force;
endif

.PHONY: build-dev
build-dev: ## build docker image for local development
	docker build --platform $(PLATFORM) --target base \
		-t $(COMPOSE_PROJECT_NAME) .

.PHONY: install-dependencies
install-dependencies: ## install dependencies for dev image
	docker run -it --rm --workdir="$(CONTAINER_APP_FOLDER)" $(DEV_VOLUME) \
		--platform $(PLATFORM) \
		$(COMPOSE_PROJECT_NAME) /bin/ash -ci "npm i"

.PHONY: interactive
interactive: ## get a bash shell in the container
	docker run -it --rm --workdir /app \
		--platform $(PLATFORM) \
		$(DEV_VOLUME) \
		$(COMPOSE_PROJECT_NAME) /bin/ash

.PHONY: launch
launch: ## get a bash shell in the container
	docker run -it --rm --workdir /app \
		--platform $(PLATFORM) \
		$(DEV_VOLUME) \
		-p "4321:4321" \
		$(COMPOSE_PROJECT_NAME) /bin/ash -ci "npm run dev:container"

.PHONY: build
build: ## build astro app
	docker run -it --rm --workdir /app \
		--platform $(PLATFORM) \
		$(DEV_VOLUME) \
		$(COMPOSE_PROJECT_NAME) /bin/ash "npm run build"

.PHONY: help
help:  ## show all make commands
ifeq ($(OS),Windows_NT)
	powershell "((type Makefile) -match '##') -notmatch 'grep'"
else
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' Makefile | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
endif
