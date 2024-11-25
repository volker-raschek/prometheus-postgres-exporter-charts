# CONTAINER_RUNTIME
CONTAINER_RUNTIME?=$(shell which podman)

# HELM_IMAGE
HELM_IMAGE_REGISTRY_HOST?=docker.io
HELM_IMAGE_REPOSITORY=volkerraschek/helm
HELM_IMAGE_VERSION?=3.16.1 # renovate: datasource=docker registryUrl=https://docker.io depName=volkerraschek/helm
HELM_IMAGE_FULLY_QUALIFIED=${HELM_IMAGE_REGISTRY_HOST}/${HELM_IMAGE_REPOSITORY}:${HELM_IMAGE_VERSION}

# MARKDOWNLINKCHECKER_IMAGE
MARKDOWNLINKCHECK_IMAGE_REGISTRY_HOST?=ghcr.io
MARKDOWNLINKCHECK_IMAGE_REPOSITORY=tcort/markdown-link-check
MARKDOWNLINKCHECK_IMAGE_VERSION?=3.12.2 # renovate: datasource=docker registryUrl=https://ghcr.io depName=tcort/markdown-link-check
MARKDOWNLINKCHECK_IMAGE_FULLY_QUALIFIED=${MARKDOWNLINT_IMAGE_REGISTRY_HOST}/${MARKDOWNLINT_IMAGE_REPOSITORY}:${MARKDOWNLINT_IMAGE_VERSION}

# NODE_IMAGE
NODE_IMAGE_REGISTRY_HOST?=docker.io
NODE_IMAGE_REPOSITORY=library/node
NODE_IMAGE_VERSION?=22.9.0-alpine # renovate: datasource=docker registryUrl=https://docker.io depName=library/node
NODE_IMAGE_FULLY_QUALIFIED=${NODE_IMAGE_REGISTRY_HOST}/${NODE_IMAGE_REPOSITORY}:${NODE_IMAGE_VERSION}

# CHART_SERVER
CHART_SERVER_HOST?=charts.u.orbis-healthcare.com
CHART_SERVER_NAMESPACE?=orbis-u
CHART_SERVER_REPOSITORY?=qu-seed
CHART_VERSION?=0.1.0

# MISSING DOT
# ==============================================================================
missing-dot:
	grep --perl-regexp '## @(param|skip).*[^.]$$' values.yaml

# CONTAINER RUN - PREPARE ENVIRONMENT
# ==============================================================================
PHONY+=container-run/readme
container-run/readme:
	${CONTAINER_RUNTIME} run \
		--rm \
		--volume $(shell pwd):$(shell pwd) \
		--workdir $(shell pwd) \
			${NODE_IMAGE_FULLY_QUALIFIED} \
				npm install && npm run readme:parameters && npm run readme:lint

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

# CONTAINER RUN - DEPLOY2CHART-REPO
# ==============================================================================
container-run/deploy2chart-repo:
	${CONTAINER_RUNTIME} run \
		--env HELM_REPO_PASSWORD=${CHART_SERVER_PASSWORD} \
		--env HELM_REPO_USERNAME=${CHART_SERVER_USERNAME} \
		--entrypoint /bin/bash \
		--rm \
		--volume $(shell pwd):$(shell pwd) \
		--workdir $(shell pwd) \
			${HELM_IMAGE_FULLY_QUALIFIED} \
				-c "helm repo add ${CHART_SERVER_NAMESPACE} http://${CHART_SERVER_HOST}/${CHART_SERVER_NAMESPACE} && helm package --version ${CHART_VERSION} . && helm cm-push ./${CHART_SERVER_REPOSITORY}-${CHART_VERSION}.tgz ${CHART_SERVER_NAMESPACE}"

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

# CONTAINER RUN - MARKDOWN-LINK-CHECK
# ==============================================================================
PHONY+=container-run/markdown-link-check
container-run/markdown-link-check:
	${CONTAINER_RUNTIME} run \
		--rm \
		--volume $(shell pwd):/work \
		${MARKDOWNLINKCHECK_IMAGE_FULLY_QUALIFIED} \
			*.md

# PHONY
# ==============================================================================
# Declare the contents of the PHONY variable as phony. We keep that information
# in a variable so we can use it in if_changed.
.PHONY: ${PHONY}