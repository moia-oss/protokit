.PHONY: bench release setup test

TEST_PKGS = ./ ./utils
VERSION = $(shell cat version.go | sed -n 's/.*const Version = "\(.*\)"/\1/p')

GOVERAGE = github.com/haya14busa/goverage
GORELEASER = github.com/goreleaser/goreleaser

BOLD = \033[1m
CLEAR = \033[0m
CYAN = \033[36m

help: ## Display this help
	@awk '\
		BEGIN {FS = ":.*##"; printf "Usage: make $(CYAN)<target>$(CLEAR)\n"} \
		/^[a-z0-9]+([\/]%)?([\/](%-)?[a-z\-0-9%]+)*:.*? ##/ { printf "  $(CYAN)%-15s$(CLEAR) %s\n", $$1, $$2 } \
		/^##@/ { printf "\n$(BOLD)%s$(CLEAR)\n", substr($$0, 5) }' \
		$(MAKEFILE_LIST)

##@ Test

test: fixtures/fileset.pb ## Run unit tests
	@go test -race -cover $(TEST_PKGS)

test/bench: ## Run benchmark tests
	go test -bench=.

test/ci: fixtures/fileset.pb test/bench ## Run CI tests include benchmarks with coverage
	@go run $(GOVERAGE) -race -coverprofile=coverage.txt -covermode=atomic $(TEST_PKGS)

##@ Release
release:
	git tag v$(VERSION)
	git push origin --tags

release/snapshot:
	@go run $(GORELEASER) --snapshot --rm-dist

release/validate:
	@go run $(GORELEASER) check

################################################################################
# Indirect targets
################################################################################

fixtures/fileset.pb: fixtures/*.proto
	$(info Generating fixtures...)
	@cd fixtures && go generate
