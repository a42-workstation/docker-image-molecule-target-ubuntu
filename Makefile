CURRENT_UID := $(shell id -u)
CURRENT_GID := $(shell id -g)
ENV_FILE := $(PWD)/env/.env
$(shell touch "${ENV_FILE}")
FLEX_CLI_EXEC := $(shell which flex-cli)

NEW_VERSION_HASH := $(shell cat ${ENV_FILE} | grep -v VERSION_HASH | md5sum | cut -f1 -d" " | head -c 5)

ifneq (,$(wildcard ${ENV_FILE}))
    include ${ENV_FILE}
    export
endif

## Compute the version hash
change_version:
	$(eval NEW_VERSION_HASH := $(shell cat ${ENV_FILE} | grep -v VERSION_HASH | md5sum | cut -f1 -d" " | head -c 5))
	$(shell sed -i -e "s/VERSION_HASH=.*/VERSION_HASH=\"-${NEW_VERSION_HASH}\"/g" ${ENV_FILE})
	@printf "New version: ${NEW_VERSION_HASH}\n"
	@printf "Change version was done.\n"

## Build the docker image
build: fresh
	bash -c ". ${ENV_FILE} && docker compose --progress plain build"
	bash -c ". ${ENV_FILE} && VERSION_HASH=\"-latest\" docker compose --progress plain build"
	@printf "\n--> Build was done:\n\
			\t${DOCKER_REGISTRY_WORKSTATION}${IMAGE_NAME}:${UBUNTU_VERSION}-${NEW_VERSION_HASH}\n"

publish: build test
	bash -c ". ${ENV_FILE} && docker compose push"
	bash -c ". ${ENV_FILE} && VERSION_HASH=\"-latest\" docker compose push"
	@printf "\n--> Build was pushed to repository ${DOCKER_REGISTRY_WORKSTATION}:\n\
			\t ${IMAGE_NAME}:${UBUNTU_VERSION}-${NEW_VERSION_HASH}\n\
			\t ${IMAGE_NAME}:${UBUNTU_VERSION}-latest\n"
test:
	bash -c "docker run -it --rm --name ${IMAGE_NAME}-${UBUNTU_VERSION}-${NEW_VERSION_HASH} ${DOCKER_REGISTRY_WORKSTATION}${IMAGE_NAME}:${UBUNTU_VERSION}-${NEW_VERSION_HASH}  bash"
	@printf "\n--> Test was done:\n\
			\t${DOCKER_REGISTRY_WORKSTATION}${IMAGE_NAME}:${UBUNTU_VERSION}-${NEW_VERSION_HASH}\n"

## Configure a fresh working version
##
## !!! This will call clean, init, and change_version
fresh: clean init change_version
	@printf "Project refresh was done.\n"

## Init env variables for a fresh environment
init:
	FLEX_RELOAD_FLAG=1 ${FLEX_CLI_EXEC} -handler flex/bash/emulator "exit 0"

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
