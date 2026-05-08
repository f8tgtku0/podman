# Makefile for podman
# See docs/make.md for usage

EXPORT_GOPATH ?= 1

ifeq ($(EXPORT_GOPATH),1)
export GOPATH := $(shell go env GOPATH)
endif

GOBIN  := $(shell go env GOBIN)
ifeq ($(GOBIN),)
GOBIN  := $(GOPATH)/bin
endif

GO     ?= go
GOTAGS ?= $(shell ./hack/btrfs_tag.sh) $(shell ./hack/btrfs_installed_tag.sh) $(shell ./hack/libdm_tag.sh) $(shell ./hack/selinux_tag.sh) $(shell ./hack/apparmor_tag.sh) $(shell ./hack/systemd_tag.sh)
GOFLAGS ?= -trimpath
GO_LDFLAGS ?= $(shell ./hack/ldflags.sh)

BINDIR ?= $(DESTDIR)/usr/bin
LIBEXECDIR ?= $(DESTDIR)/usr/libexec
MANDIR ?= $(DESTDIR)/usr/share/man
COMPLETIONSDIR ?= $(DESTDIR)/usr/share/bash-completion/completions
SYSTEMDDIR ?= $(DESTDIR)/usr/lib/systemd/system

BINARY ?= bin/podman
REMOTE_BINARY ?= bin/podman-remote

.PHONY: all
all: binaries

.PHONY: binaries
binaries: $(BINARY) $(REMOTE_BINARY) ## Build all binaries

.PHONY: $(BINARY)
$(BINARY): ## Build podman binary
	$(GO) build \
		$(GOFLAGS) \
		-tags "$(GOTAGSS)" \
		-ldflags "$(GO_LDFLAGS)" \
		-o $@ ./cmd/podman

.PHONY: $(REMOTE_BINARY)
$(REMOTE_BINARY): ## Build podman-remote binary
	$(GO) build \
		$(GOFLAGS) \
		-tags "$(GOTAGSS) remote" \
		-ldflags "$(GO_LDFLAGS)" \
		-o $@ ./cmd/podman

.PHONY: test
test: unit integration ## Run all tests

.PHONY: unit
unit: ## Run unit tests
	$(GO) test -v -tags "$(GOTAGSS)" ./...

.PHONY: integration
integration: ## Run integration tests
	$(GO) test -v -tags "$(GOTAGSS) integration" ./test/...

.PHONY: lint
lint: ## Run linters
	golangci-lint run --timeout=10m

.PHONY: vendor
vendor: ## Update vendor directory
	$(GO) mod tidy
	$(GO) mod vendor
	$(GO) mod verify

.PHONY: install
install: $(BINARY) ## Install podman binary
	install -d -m 755 $(BINDIR)
	install -m 755 $(BINARY) $(BINDIR)/podman

.PHONY: install.remote
install.remote: $(REMOTE_BINARY) ## Install podman-remote binary
	install -d -m 755 $(BINDIR)
	install -m 755 $(REMOTE_BINARY) $(BINDIR)/podman-remote

.PHONY: clean
clean: ## Clean build artifacts
	rm -rf bin/
	$(GO) clean -cache

.PHONY: fmt
fmt: ## Format Go source files
	gofmt -l -w $(shell find . -type f -name '*.go' -not -path './vendor/*')

.PHONY: help
help: ## Display this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n\nTargets:\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)
