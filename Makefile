RUN_FROM_CI?=false
GOLANG_IMAGE?=golang:1.18.3
IMAGE_TAG?=latest
IMAGE_PREFIX?=

AIR_VERSION=1.40.4
GOLANGCI_LINT_VERSION=1.49.0

CURL:=curl -sSLf
BINDIR:=$(shell pwd)/bin
AIR:=$(BINDIR)/air-$(AIR_VERSION)
GOLANGCI_LINT:=$(BINDIR)/golangci-lint

GOTEST_OPTIONS:=
DEV_TOOLS:=$(AIR)
ifneq ($(RUN_FROM_CI),false)
GOTEST_OPTIONS:=-count 1
DEV_TOOLS:=
endif

.PHONY: all
all: help

##@ General

# The help target prints out all targets with their descriptions organized
# beneath their categories. The categories are represented by '##@' and the
# target descriptions by '##'. The awk commands is responsible for reading the
# entire set of makefiles included in this invocation, looking for lines of the
# file as xyz: ## something, and then pretty-format the target and help. Then,
# if there's a line with ##@ something, that gets pretty-printed as a category.
# More info on the usage of ANSI control characters for terminal formatting:
# https://en.wikipedia.org/wiki/ANSI_escape_code#SGR_parameters
# More info on the nd.org/lc3_adv_awk.php

.PHONY: help
help: ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

##@ Development

.PHONY: update-module
update-module: ## Update Module.
	go mod download
	go mod tidy

.PHONY: run
run: ## Running app with air.
	$(AIR) --build.cmd 'go build -o bin/server server.go' --build.bin 'bin/server'

.PHONY: lint
lint: ## Run lint.
	$(GOLANGCI_LINT) run --config=./.golangci-lint.yaml

.PHONY: lint-fix
lint-fix: ## Run lint(with fix option).
	$(GOLANGCI_LINT) run --config=./.golangci-lint.yaml --fix

.PHONY: test
test: ## Run tests.
	go test $(GOTEST_OPTIONS) -race -v ./...

.PHONY: check-uncommitted
check-uncommitted: ## Check if latest generated artifacts are committed.
	git diff --exit-code --name-only

##@ Build

.PHONY: build
build: ## Build docker image.
	docker build \
		--no-cache \
		--build-arg GOLANG_IMAGE="$(GOLANG_IMAGE)" \
		-t $(IMAGE_PREFIX)devcontainer-example:devel \
		.

.PHONY: tag
tag: ## Set a docker tag to the image.
	docker tag $(IMAGE_PREFIX)devcontainer-example:devel $(IMAGE_PREFIX)devcontainer-example:v$(IMAGE_TAG)

.PHONY: push
push: ## Push docker image.
	docker push $(IMAGE_PREFIX)devcontainer-example:v$(IMAGE_TAG)

##@ Setup

.PHONY: setup
setup: $(BINDIR) golangci-lint $(DEV_TOOLS) ## Setup tools.

$(BINDIR):
	mkdir -p $(BINDIR)

clean: ## Clean tools.
	rm -fr $(BINDIR)

.PHONY: golangci-lint
golangci-lint: ## Install golangci-lint.
	@if [ ! -f $(GOLANGCI_LINT) ] || [ $$($(GOLANGCI_LINT) version | awk '{print $$4}') != "$(GOLANGCI_LINT_VERSION)" ]; then \
		$(CURL) https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b $(BINDIR) v$(GOLANGCI_LINT_VERSION); \
		chmod u+x $(GOLANGCI_LINT); \
	fi

.PHONY: air
$(AIR):
	GOBIN=$(BINDIR) go install github.com/cosmtrek/air@v$(AIR_VERSION)
	mv $(BINDIR)/air $(AIR)

