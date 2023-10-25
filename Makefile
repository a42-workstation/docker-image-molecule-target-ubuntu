CURRENT_UID := $(shell id -u)
CURRENT_GID := $(shell id -g)
ENV_FILE := $(PWD)/.env
NEW_VERSION_HASH := $(shell cat .env | grep -v VERSION_HASH | md5sum | cut -f1 -d" " | head -c 5)

include ${ENV_FILE}

## Compute the version hash
change_version:
	$(shell sed -i -e "s/VERSION_HASH=.*/VERSION_HASH=\"-${NEW_VERSION_HASH}\"/g" .env)
	@printf "New version: ${NEW_VERSION_HASH}\n"
	@printf "Change version was done.\n"

## Build the docker image
build: fresh
	export DOCKER_BUILDKIT=0
	bash -c "docker compose --progress plain build"
	bash -c "VERSION_HASH=\"-latest\" docker compose --progress plain build"
	@printf "\n--> Build was done:\n\
			\t${DOCKER_REGISTRY_WORKSTATION}${IMAGE_NAME}:${UBUNTU_VERSION}-${NEW_VERSION_HASH}\n"

publish: build test
	bash -c "docker compose push"
	bash -c "VERSION_HASH=\"-latest\" docker compose push"
	@printf "\n--> Build was pushed to repository ${DOCKER_REGISTRY_WORKSTATION}:\n\
			\t ${IMAGE_NAME}:${UBUNTU_VERSION}-${NEW_VERSION_HASH}\n\
			\t ${IMAGE_NAME}:${UBUNTU_VERSION}-latest\n"
test:
	bash -c "docker run -it --rm --name ${IMAGE_NAME}-${UBUNTU_VERSION}-${NEW_VERSION_HASH} ${DOCKER_REGISTRY_WORKSTATION}${IMAGE_NAME}:${UBUNTU_VERSION}-${NEW_VERSION_HASH}  bash -v"
	@printf "\n--> Test was done:\n\
			\t${DOCKER_REGISTRY_WORKSTATION}${IMAGE_NAME}:${UBUNTU_VERSION}-${NEW_VERSION_HASH}\n"

## Configure a fresh working version
##
## !!! This will call clean, init, and change_version
fresh: clean init change_version
	@printf "Project refresh was done.\n"

## Init env variables for a fresh environment
init:
	cp .env.sample .env

## Clean this repository of ignored files
##
## !!! All the changes will be lost
clean:
	git clean -dfX

## Help command
.PHONY: help
help:
	@printf "Usage\n";

	@awk '{ \
			if ($$0 ~ /^.PHONY: [a-zA-Z\-_0-9]+$$/) { \
				helpCommand = substr($$0, index($$0, ":") + 2); \
				if (helpMessage) { \
					printf "\033[36m%-20s\033[0m %s\n", \
						helpCommand, helpMessage; \
					helpMessage = ""; \
				} \
			} else if ($$0 ~ /^[a-zA-Z\-_0-9.]+:/) { \
				helpCommand = substr($$0, 0, index($$0, ":")); \
				if (helpMessage) { \
					printf "\033[36m%-20s\033[0m %s\n", \
						helpCommand, helpMessage; \
					helpMessage = ""; \
				} \
			} else if ($$0 ~ /^##/) { \
				if (helpMessage) { \
					helpMessage = helpMessage"\n                     "substr($$0, 3); \
				} else { \
					helpMessage = substr($$0, 3); \
				} \
			} else { \
				if (helpMessage) { \
					print "\n                     "helpMessage"\n" \
				} \
				helpMessage = ""; \
			} \
		}' \
		$(MAKEFILE_LIST)
