# CONTAINER_RUNTIME
CONTAINER_RUNTIME?=$(shell which podman)

# HELM_IMAGE
HELM_IMAGE_REGISTRY_HOST?=docker.io
HELM_IMAGE_REPOSITORY?=volkerraschek/helm
HELM_IMAGE_VERSION?=3.19.0 # renovate: datasource=docker registryUrl=https://docker.io depName=docker.io/volkerraschek/helm
HELM_IMAGE_FULLY_QUALIFIED=${HELM_IMAGE_REGISTRY_HOST}/${HELM_IMAGE_REPOSITORY}:${HELM_IMAGE_VERSION}

# NODE_IMAGE
NODE_IMAGE_REGISTRY_HOST?=docker.io
NODE_IMAGE_REPOSITORY?=library/node
NODE_IMAGE_VERSION?=25.2.0-alpine # renovate: datasource=docker registryUrl=https://docker.io depName=docker.io/library/node packageName=library/node
NODE_IMAGE_FULLY_QUALIFIED=${NODE_IMAGE_REGISTRY_HOST}/${NODE_IMAGE_REPOSITORY}:${NODE_IMAGE_VERSION}

# MISSING DOT
# ==============================================================================
missing-dot:
	grep --perl-regexp '## @(param|skip).*[^.]$$' values.yaml

# CONTAINER RUN - README
# ==============================================================================
PHONY+=container-run/readme
container-run/readme: container-run/readme/link container-run/readme/lint container-run/readme/parameters

container-run/readme/link:
	${CONTAINER_RUNTIME} run \
		--rm \
		--volume $(shell pwd):$(shell pwd) \
		--workdir $(shell pwd) \
			${NODE_IMAGE_FULLY_QUALIFIED} \
				npm install && npm run readme:link

container-run/readme/lint:
	${CONTAINER_RUNTIME} run \
		--rm \
		--volume $(shell pwd):$(shell pwd) \
		--workdir $(shell pwd) \
			${NODE_IMAGE_FULLY_QUALIFIED} \
				npm install && npm run readme:lint

container-run/readme/parameters:
	${CONTAINER_RUNTIME} run \
		--rm \
		--volume $(shell pwd):$(shell pwd) \
		--workdir $(shell pwd) \
			${NODE_IMAGE_FULLY_QUALIFIED} \
				npm install && npm run readme:parameters

# CONTAINER RUN - HELM UNITTESTS
# ==============================================================================
PHONY+=container-run/helm-unittests
container-run/helm-unittests:
	${CONTAINER_RUNTIME} run \
		--env HELM_REPO_PASSWORD=${CHART_SERVER_PASSWORD} \
		--env HELM_REPO_USERNAME=${CHART_SERVER_USERNAME} \
		--rm \
		--volume $(shell pwd):$(shell pwd) \
		--workdir $(shell pwd) \
			${HELM_IMAGE_FULLY_QUALIFIED} \
				unittest --strict --file 'unittests/**/*.yaml' ./

# CONTAINER RUN - HELM UPDATE DEPENDENCIES
# ==============================================================================
PHONY+=container-run/helm-update-dependencies
container-run/helm-update-dependencies:
	${CONTAINER_RUNTIME} run \
		--env HELM_REPO_PASSWORD=${CHART_SERVER_PASSWORD} \
		--env HELM_REPO_USERNAME=${CHART_SERVER_USERNAME} \
		--rm \
		--volume $(shell pwd):$(shell pwd) \
		--workdir $(shell pwd) \
			${HELM_IMAGE_FULLY_QUALIFIED} \
				dependency update

# CONTAINER RUN - MARKDOWN-LINT
# ==============================================================================
PHONY+=container-run/helm-lint
container-run/helm-lint:
	${CONTAINER_RUNTIME} run \
		--rm \
		--volume $(shell pwd):$(shell pwd) \
		--workdir $(shell pwd) \
		${HELM_IMAGE_FULLY_QUALIFIED} \
			lint --values values.yaml .

# PHONY
# ==============================================================================
# Declare the contents of the PHONY variable as phony. We keep that information
# in a variable so we can use it in if_changed.
.PHONY: ${PHONY}
