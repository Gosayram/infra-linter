# infra-linter Makefile

# Project-specific constants
BINARY_NAME := infra-linter
OUTPUT_DIR := bin
CMD_DIR := cmd/infra-linter

# Version and build constants
TAG_NAME ?= $(shell head -n 1 .release-version 2>/dev/null || echo "v0.1.0")
VERSION ?= $(shell head -n 1 .release-version 2>/dev/null | sed 's/^v//' || echo "dev")
BUILD_INFO ?= $(shell date +%s)
GOOS ?= $(shell go env GOOS)
GOARCH ?= $(shell go env GOARCH)
GO_VERSION := $(shell cat .go-version 2>/dev/null || echo "1.21")
GO_FILES := $(wildcard $(CMD_DIR)/*.go internal/**/*.go pkg/**/*.go)

# Tool paths
GOPATH ?= $(shell go env GOPATH)
GOLANGCI_LINT = $(GOPATH)/bin/golangci-lint
STATICCHECK = $(GOPATH)/bin/staticcheck
GOIMPORTS = $(GOPATH)/bin/goimports
GOSEC = $(GOPATH)/bin/gosec
ERRCHECK = $(GOPATH)/bin/errcheck
GOVULNCHECK = $(GOPATH)/bin/govulncheck
SYFT = $(GOPATH)/bin/syft

# Security scanning constants
GOSEC_VERSION := v2.22.5
GOSEC_OUTPUT_FORMAT := sarif
GOSEC_REPORT_FILE := gosec-report.sarif
GOSEC_JSON_REPORT := gosec-report.json
GOSEC_SEVERITY := medium

# Vulnerability checking constants
GOVULNCHECK_VERSION := latest
VULNCHECK_OUTPUT_FORMAT := json
VULNCHECK_REPORT_FILE := vulncheck-report.json

# Error checking constants
ERRCHECK_VERSION := v1.9.0

# SBOM generation constants
SYFT_VERSION := latest
SYFT_OUTPUT_FORMAT := syft-json
SYFT_SBOM_FILE := sbom.syft.json
SYFT_SPDX_FILE := sbom.spdx.json
SYFT_CYCLONEDX_FILE := sbom.cyclonedx.json

# Build constants
COMMIT ?= $(shell git rev-parse --short HEAD 2>/dev/null || echo "unknown")
DATE ?= $(shell date -u '+%Y-%m-%d_%H:%M:%S')
BUILT_BY ?= $(shell git remote get-url origin 2>/dev/null | sed -n 's/.*[:/]\([^/]*\)\/[^/]*\.git.*/\1/p' || git config user.name 2>/dev/null | tr ' ' '_' || echo "unknown")

# Build flags
BUILD_FLAGS := -buildvcs=false
LDFLAGS := -ldflags "-s -w -X 'github.com/Gosayram/infra-linter/internal/version.Version=$(VERSION)' \
				   -X 'github.com/Gosayram/infra-linter/internal/version.Commit=$(COMMIT)' \
				   -X 'github.com/Gosayram/infra-linter/internal/version.Date=$(DATE)' \
				   -X 'github.com/Gosayram/infra-linter/internal/version.BuiltBy=$(BUILT_BY)'"

# Testing constants
MATRIX_MIN_GO_VERSION := 1.21
MATRIX_STABLE_GO_VERSION := 1.21.5
MATRIX_LATEST_GO_VERSION := 1.21
MATRIX_TEST_TIMEOUT := 10m
MATRIX_COVERAGE_THRESHOLD := 80

# Package building constants
PACKAGE_DIR := packages
RPM_BUILD_DIR := $(HOME)/rpmbuild
DEB_BUILD_DIR := $(PACKAGE_DIR)/deb
TARBALL_NAME := $(BINARY_NAME)-$(VERSION).tar.gz
SPEC_FILE := $(BINARY_NAME).spec

# Test file constants for infra-linter
TEST_DOCKERFILE := testdata/Dockerfile
TEST_ENV_FILE := testdata/.env
TEST_MAKEFILE := testdata/Makefile
SAMPLE_FILES_DIR := testdata/samples

# Default maximum values
MAX_TEST_FILES := 100
MAX_RESULTS_LIMIT := 1000
DEFAULT_TIMEOUT_SECONDS := 30

# Ensure directories exist
$(OUTPUT_DIR):
	@mkdir -p $(OUTPUT_DIR)

$(SAMPLE_FILES_DIR):
	@mkdir -p $(SAMPLE_FILES_DIR)

# Default target
.PHONY: default
default: fmt vet imports lint staticcheck build quicktest

# Display help information
.PHONY: help
help:
	@echo "infra-linter - Infrastructure Files Linter"
	@echo ""
	@echo "Available targets:"
	@echo "  Building and Running:"
	@echo "  ===================="
	@echo "  default         - Run formatting, linting, build, and tests"
	@echo "  run             - Run the application locally"
	@echo "  dev             - Run in development mode"
	@echo "  build           - Build the application"
	@echo "  build-debug     - Build debug version with symbols"
	@echo "  build-cross     - Build for multiple platforms"
	@echo "  install         - Install binary to /usr/local/bin"
	@echo "  uninstall       - Remove binary from /usr/local/bin"
	@echo ""
	@echo "  Testing and Validation:"
	@echo "  ======================"
	@echo "  test            - Run all tests with coverage"
	@echo "  test-with-race  - Run tests with race detection"
	@echo "  quicktest       - Run quick tests"
	@echo "  test-coverage   - Generate coverage report"
	@echo "  test-integration- Run integration tests"
	@echo "  test-samples    - Test linter on sample files"
	@echo "  test-dockerfile - Test Dockerfile linting rules"
	@echo "  test-env        - Test .env file linting rules"
	@echo "  test-makefile   - Test Makefile linting rules"
	@echo ""
	@echo "  Code Quality:"
	@echo "  ============="
	@echo "  fmt             - Format Go code"
	@echo "  vet             - Run go vet"
	@echo "  imports         - Format imports"
	@echo "  lint            - Run golangci-lint"
	@echo "  lint-fix        - Run linters with auto-fix"
	@echo "  staticcheck     - Run staticcheck"
	@echo "  security-scan   - Run security scanning"
	@echo "  vuln-check      - Check for vulnerabilities"
	@echo "  check-all       - Run all quality checks"
	@echo ""
	@echo "  Sample Management:"
	@echo "  =================="
	@echo "  create-samples  - Create sample test files"
	@echo "  clean-samples   - Clean sample test files"
	@echo "  validate-samples- Validate sample files"
	@echo ""
	@echo "  Dependencies:"
	@echo "  ============="
	@echo "  deps            - Install dependencies"
	@echo "  install-tools   - Install development tools"
	@echo "  upgrade-deps    - Upgrade dependencies"
	@echo ""
	@echo "  Cleanup:"
	@echo "  ========"
	@echo "  clean           - Clean build artifacts"
	@echo "  clean-all       - Clean everything"
	@echo ""
	@echo "  Version Management:"
	@echo "  =================="
	@echo "  version         - Show version information"
	@echo "  bump-patch      - Bump patch version"
	@echo "  bump-minor      - Bump minor version"
	@echo "  bump-major      - Bump major version"
	@echo ""
	@echo "Examples:"
	@echo "  make build                    - Build the linter"
	@echo "  make test-samples             - Test on sample files"
	@echo "  make run ARGS=\"Dockerfile\"    - Lint a Dockerfile"
	@echo "  make create-samples           - Create test samples"

# Build and run targets
.PHONY: run dev build build-debug build-cross

run:
	@echo "Running $(BINARY_NAME)..."
	go run ./$(CMD_DIR) $(ARGS)

dev:
	@echo "Running in development mode..."
	go run ./$(CMD_DIR) $(ARGS)

build: $(OUTPUT_DIR)
	@echo "Building $(BINARY_NAME) with version $(VERSION)..."
	GOOS=$(GOOS) GOARCH=$(GOARCH) CGO_ENABLED=0 go build \
		$(BUILD_FLAGS) $(LDFLAGS) \
		-o $(OUTPUT_DIR)/$(BINARY_NAME) ./$(CMD_DIR)

build-debug: $(OUTPUT_DIR)
	@echo "Building debug version..."
	CGO_ENABLED=0 go build \
		$(BUILD_FLAGS) -gcflags="all=-N -l" \
		$(LDFLAGS) \
		-o $(OUTPUT_DIR)/$(BINARY_NAME)-debug ./$(CMD_DIR)

build-cross: $(OUTPUT_DIR)
	@echo "Building cross-platform binaries..."
	GOOS=linux   GOARCH=amd64   CGO_ENABLED=0 go build $(BUILD_FLAGS) $(LDFLAGS) -o $(OUTPUT_DIR)/$(BINARY_NAME)-linux-amd64 ./$(CMD_DIR)
	GOOS=linux   GOARCH=arm64   CGO_ENABLED=0 go build $(BUILD_FLAGS) $(LDFLAGS) -o $(OUTPUT_DIR)/$(BINARY_NAME)-linux-arm64 ./$(CMD_DIR)
	GOOS=darwin  GOARCH=arm64   CGO_ENABLED=0 go build $(BUILD_FLAGS) $(LDFLAGS) -o $(OUTPUT_DIR)/$(BINARY_NAME)-darwin-arm64 ./$(CMD_DIR)
	GOOS=darwin  GOARCH=amd64   CGO_ENABLED=0 go build $(BUILD_FLAGS) $(LDFLAGS) -o $(OUTPUT_DIR)/$(BINARY_NAME)-darwin-amd64 ./$(CMD_DIR)
	GOOS=windows GOARCH=amd64   CGO_ENABLED=0 go build $(BUILD_FLAGS) $(LDFLAGS) -o $(OUTPUT_DIR)/$(BINARY_NAME)-windows-amd64.exe ./$(CMD_DIR)
	@echo "Cross-platform binaries built successfully"

# Dependencies
.PHONY: deps install-deps upgrade-deps clean-deps install-tools

deps: install-deps

install-deps:
	@echo "Installing Go dependencies..."
	go mod init github.com/Gosayram/infra-linter 2>/dev/null || true
	go mod download
	go mod tidy
	@echo "Dependencies installed successfully"

upgrade-deps:
	@echo "Upgrading all dependencies..."
	go get -u ./...
	go mod tidy
	@echo "Dependencies upgraded"

clean-deps:
	@echo "Cleaning dependencies..."
	rm -rf vendor

install-tools:
	@echo "Installing development tools..."
	go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
	go install honnef.co/go/tools/cmd/staticcheck@latest
	go install golang.org/x/tools/cmd/goimports@latest
	go install github.com/secureco/gosec/v2/cmd/gosec@$(GOSEC_VERSION)
	go install golang.org/x/vuln/cmd/govulncheck@$(GOVULNCHECK_VERSION)
	go install github.com/kisielk/errcheck@$(ERRCHECK_VERSION)
	@echo "Development tools installed"

# Testing targets
.PHONY: test test-with-race quicktest test-coverage test-integration

test:
	@echo "Running Go tests with coverage..."
	go test -v -cover ./...

test-with-race:
	@echo "Running tests with race detection..."
	go test -v -race -cover ./...

quicktest:
	@echo "Running quick tests..."
	go test ./...

test-coverage:
	@echo "Generating coverage report..."
	go test -v -coverprofile=coverage.out -covermode=atomic ./...
	go tool cover -html=coverage.out -o coverage.html
	@echo "Coverage report: coverage.html"

test-integration: build
	@echo "Running integration tests..."
	@mkdir -p testdata/integration
	@echo "Testing basic functionality..."
	./$(OUTPUT_DIR)/$(BINARY_NAME) --version > testdata/integration/version.out
	./$(OUTPUT_DIR)/$(BINARY_NAME) --help > testdata/integration/help.out 2>&1 || true
	@echo "Integration tests completed"

# Code quality targets
.PHONY: fmt vet imports lint lint-fix staticcheck errcheck security-scan vuln-check check-all

fmt:
	@echo "Formatting Go code..."
	go fmt ./...

vet:
	@echo "Running go vet..."
	go vet ./...

imports:
	@if command -v $(GOIMPORTS) >/dev/null 2>&1; then \
		echo "Formatting imports..."; \
		$(GOIMPORTS) -local github.com/Gosayram/infra-linter -w $(GO_FILES); \
	else \
		echo "Installing goimports..."; \
		go install golang.org/x/tools/cmd/goimports@latest; \
		$(GOIMPORTS) -local github.com/Gosayram/infra-linter -w $(GO_FILES); \
	fi

lint:
	@if command -v $(GOLANGCI_LINT) >/dev/null 2>&1; then \
		echo "Running golangci-lint..."; \
		$(GOLANGCI_LINT) run; \
	else \
		echo "Installing golangci-lint..."; \
		go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest; \
		$(GOLANGCI_LINT) run; \
	fi

lint-fix:
	@echo "Running linters with auto-fix..."
	$(GOLANGCI_LINT) run --fix

staticcheck:
	@if command -v $(STATICCHECK) >/dev/null 2>&1; then \
		echo "Running staticcheck..."; \
		$(STATICCHECK) ./...; \
	else \
		echo "Installing staticcheck..."; \
		go install honnef.co/go/tools/cmd/staticcheck@latest; \
		$(STATICCHECK) ./...; \
	fi

errcheck:
	@if command -v $(ERRCHECK) >/dev/null 2>&1; then \
		echo "Running errcheck..."; \
		$(ERRCHECK) ./...; \
	else \
		echo "Installing errcheck..."; \
		go install github.com/kisielk/errcheck@$(ERRCHECK_VERSION); \
		$(ERRCHECK) ./...; \
	fi

security-scan:
	@if command -v $(GOSEC) >/dev/null 2>&1; then \
		echo "Running security scan..."; \
		$(GOSEC) -fmt $(GOSEC_OUTPUT_FORMAT) -out $(GOSEC_REPORT_FILE) ./...; \
	else \
		echo "Installing gosec..."; \
		go install github.com/secureco/gosec/v2/cmd/gosec@$(GOSEC_VERSION); \
		$(GOSEC) -fmt $(GOSEC_OUTPUT_FORMAT) -out $(GOSEC_REPORT_FILE) ./...; \
	fi

vuln-check:
	@if command -v $(GOVULNCHECK) >/dev/null 2>&1; then \
		echo "Running vulnerability check..."; \
		$(GOVULNCHECK) ./...; \
	else \
		echo "Installing govulncheck..."; \
		go install golang.org/x/vuln/cmd/govulncheck@$(GOVULNCHECK_VERSION); \
		$(GOVULNCHECK) ./...; \
	fi

check-all: fmt vet imports lint staticcheck errcheck security-scan vuln-check
	@echo "All code quality checks completed"

# infra-linter specific targets
.PHONY: create-samples clean-samples validate-samples test-samples test-dockerfile test-env test-makefile

create-samples: $(SAMPLE_FILES_DIR)
	@echo "Creating sample test files..."
	@echo "# Sample Dockerfile with issues" > $(SAMPLE_FILES_DIR)/bad.Dockerfile
	@echo "FROM ubuntu:latest" >> $(SAMPLE_FILES_DIR)/bad.Dockerfile
	@echo "RUN apt-get update && apt-get install -y curl" >> $(SAMPLE_FILES_DIR)/bad.Dockerfile
	@echo "COPY . /app" >> $(SAMPLE_FILES_DIR)/bad.Dockerfile
	@echo "WORKDIR /app" >> $(SAMPLE_FILES_DIR)/bad.Dockerfile
	@echo "CMD [\"./app\"]" >> $(SAMPLE_FILES_DIR)/bad.Dockerfile
	@echo "" >> $(SAMPLE_FILES_DIR)/bad.Dockerfile
	@echo "# Good Dockerfile example" > $(SAMPLE_FILES_DIR)/good.Dockerfile
	@echo "FROM ubuntu:20.04" >> $(SAMPLE_FILES_DIR)/good.Dockerfile
	@echo "RUN apt-get update && apt-get install -y curl \\" >> $(SAMPLE_FILES_DIR)/good.Dockerfile
	@echo "    && rm -rf /var/lib/apt/lists/*" >> $(SAMPLE_FILES_DIR)/good.Dockerfile
	@echo "USER nobody" >> $(SAMPLE_FILES_DIR)/good.Dockerfile
	@echo "COPY . /app" >> $(SAMPLE_FILES_DIR)/good.Dockerfile
	@echo "WORKDIR /app" >> $(SAMPLE_FILES_DIR)/good.Dockerfile
	@echo "HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \\" >> $(SAMPLE_FILES_DIR)/good.Dockerfile
	@echo "    CMD curl -f http://localhost:8080/health || exit 1" >> $(SAMPLE_FILES_DIR)/good.Dockerfile
	@echo "CMD [\"./app\"]" >> $(SAMPLE_FILES_DIR)/good.Dockerfile
	@echo "" >> $(SAMPLE_FILES_DIR)/good.Dockerfile
	@echo "# Bad .env file" > $(SAMPLE_FILES_DIR)/bad.env
	@echo "DATABASE_PASSWORD=123456" >> $(SAMPLE_FILES_DIR)/bad.env
	@echo "API_SECRET = admin" >> $(SAMPLE_FILES_DIR)/bad.env
	@echo "JWT_TOKEN=qwerty" >> $(SAMPLE_FILES_DIR)/bad.env
	@echo "DATABASE_PASSWORD=password" >> $(SAMPLE_FILES_DIR)/bad.env
	@echo "" >> $(SAMPLE_FILES_DIR)/bad.env
	@echo "# Good .env file" > $(SAMPLE_FILES_DIR)/good.env
	@echo "DATABASE_PASSWORD=SecureP@ssw0rd123!" >> $(SAMPLE_FILES_DIR)/good.env
	@echo "API_SECRET=randomly-generated-secret-key-here" >> $(SAMPLE_FILES_DIR)/good.env
	@echo "JWT_TOKEN=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9" >> $(SAMPLE_FILES_DIR)/good.env
	@echo "DATABASE_HOST=localhost" >> $(SAMPLE_FILES_DIR)/good.env
	@echo "" >> $(SAMPLE_FILES_DIR)/good.env
	@echo "# Bad Makefile" > $(SAMPLE_FILES_DIR)/bad.Makefile
	@echo "build:" >> $(SAMPLE_FILES_DIR)/bad.Makefile
	@echo "	go build -o app" >> $(SAMPLE_FILES_DIR)/bad.Makefile
	@echo "" >> $(SAMPLE_FILES_DIR)/bad.Makefile
	@echo "clean:" >> $(SAMPLE_FILES_DIR)/bad.Makefile
	@echo "	rm -f app" >> $(SAMPLE_FILES_DIR)/bad.Makefile
	@echo "" >> $(SAMPLE_FILES_DIR)/bad.Makefile
	@echo "build:" >> $(SAMPLE_FILES_DIR)/bad.Makefile
	@echo "	echo 'duplicate target'" >> $(SAMPLE_FILES_DIR)/bad.Makefile
	@echo "" >> $(SAMPLE_FILES_DIR)/bad.Makefile
	@echo "# Good Makefile" > $(SAMPLE_FILES_DIR)/good.Makefile
	@echo ".PHONY: build clean test" >> $(SAMPLE_FILES_DIR)/good.Makefile
	@echo "" >> $(SAMPLE_FILES_DIR)/good.Makefile
	@echo "build:" >> $(SAMPLE_FILES_DIR)/good.Makefile
	@echo "	go build -o app" >> $(SAMPLE_FILES_DIR)/good.Makefile
	@echo "" >> $(SAMPLE_FILES_DIR)/good.Makefile
	@echo "clean:" >> $(SAMPLE_FILES_DIR)/good.Makefile
	@echo "	rm -f app" >> $(SAMPLE_FILES_DIR)/good.Makefile
	@echo "" >> $(SAMPLE_FILES_DIR)/good.Makefile
	@echo "test:" >> $(SAMPLE_FILES_DIR)/good.Makefile
	@echo "	go test ./..." >> $(SAMPLE_FILES_DIR)/good.Makefile
	@echo "Sample files created in $(SAMPLE_FILES_DIR)/"

clean-samples:
	@echo "Cleaning sample files..."
	rm -rf $(SAMPLE_FILES_DIR)

validate-samples: create-samples
	@echo "Validating sample files..."
	@echo "Sample files validation completed"

test-samples: build create-samples
	@echo "Testing linter on sample files..."
	@echo "Testing bad Dockerfile..."
	-./$(OUTPUT_DIR)/$(BINARY_NAME) $(SAMPLE_FILES_DIR)/bad.Dockerfile || echo "Expected issues found"
	@echo "Testing good Dockerfile..."
	-./$(OUTPUT_DIR)/$(BINARY_NAME) $(SAMPLE_FILES_DIR)/good.Dockerfile || echo "Issues found in good file"
	@echo "Testing bad .env file..."
	-./$(OUTPUT_DIR)/$(BINARY_NAME) $(SAMPLE_FILES_DIR)/bad.env || echo "Expected issues found"
	@echo "Testing good .env file..."
	-./$(OUTPUT_DIR)/$(BINARY_NAME) $(SAMPLE_FILES_DIR)/good.env || echo "Issues found in good file"
	@echo "Testing bad Makefile..."
	-./$(OUTPUT_DIR)/$(BINARY_NAME) $(SAMPLE_FILES_DIR)/bad.Makefile || echo "Expected issues found"
	@echo "Testing good Makefile..."
	-./$(OUTPUT_DIR)/$(BINARY_NAME) $(SAMPLE_FILES_DIR)/good.Makefile || echo "Issues found in good file"
	@echo "Sample testing completed"

test-dockerfile: build create-samples
	@echo "Testing Dockerfile linting rules..."
	-./$(OUTPUT_DIR)/$(BINARY_NAME) $(SAMPLE_FILES_DIR)/bad.Dockerfile
	-./$(OUTPUT_DIR)/$(BINARY_NAME) $(SAMPLE_FILES_DIR)/good.Dockerfile

test-env: build create-samples
	@echo "Testing .env file linting rules..."
	-./$(OUTPUT_DIR)/$(BINARY_NAME) $(SAMPLE_FILES_DIR)/bad.env
	-./$(OUTPUT_DIR)/$(BINARY_NAME) $(SAMPLE_FILES_DIR)/good.env

test-makefile: build create-samples
	@echo "Testing Makefile linting rules..."
	-./$(OUTPUT_DIR)/$(BINARY_NAME) $(SAMPLE_FILES_DIR)/bad.Makefile
	-./$(OUTPUT_DIR)/$(BINARY_NAME) $(SAMPLE_FILES_DIR)/good.Makefile

# Installation targets
.PHONY: install uninstall

install: build
	@echo "Installing $(BINARY_NAME) to /usr/local/bin..."
	sudo cp $(OUTPUT_DIR)/$(BINARY_NAME) /usr/local/bin/
	@echo "Installation completed"

uninstall:
	@echo "Removing $(BINARY_NAME) from /usr/local/bin..."
	sudo rm -f /usr/local/bin/$(BINARY_NAME)
	@echo "Uninstallation completed"

# Version management
.PHONY: version bump-patch bump-minor bump-major

version:
	@echo "Project: infra-linter"
	@echo "Go version: $(GO_VERSION)"
	@echo "Release version: $(VERSION)"
	@echo "Tag name: $(TAG_NAME)"
	@echo "Build target: $(GOOS)/$(GOARCH)"
	@echo "Commit: $(COMMIT)"
	@echo "Built by: $(BUILT_BY)"

bump-patch:
	@if [ ! -f .release-version ]; then echo "v0.1.0" > .release-version; fi
	@current=$$(cat .release-version | sed 's/^v//'); \
	new=$$(echo $$current | awk -F. '{$$3=$$3+1; print "v"$$1"."$$2"."$$3}'); \
	echo $$new > .release-version; \
	echo "Version bumped to $$new"

bump-minor:
	@if [ ! -f .release-version ]; then echo "v0.1.0" > .release-version; fi
	@current=$$(cat .release-version | sed 's/^v//'); \
	new=$$(echo $$current | awk -F. '{$$2=$$2+1; $$3=0; print "v"$$1"."$$2"."$$3}'); \
	echo $$new > .release-version; \
	echo "Version bumped to $$new"

bump-major:
	@if [ ! -f .release-version ]; then echo "v0.1.0" > .release-version; fi
	@current=$$(cat .release-version | sed 's/^v//'); \
	new=$$(echo $$current | awk -F. '{$$1=$$1+1; $$2=0; $$3=0; print "v"$$1"."$$2"."$$3}'); \
	echo $$new > .release-version; \
	echo "Version bumped to $$new"

# Cleanup targets
.PHONY: clean clean-all

clean:
	@echo "Cleaning build artifacts..."
	rm -rf $(OUTPUT_DIR)
	rm -f coverage.out coverage.html
	rm -f $(GOSEC_REPORT_FILE) $(GOSEC_JSON_REPORT)
	rm -f $(VULNCHECK_REPORT_FILE)
	rm -f $(SYFT_SBOM_FILE) $(SYFT_SPDX_FILE) $(SYFT_CYCLONEDX_FILE)
	rm -rf testdata/integration
	go clean -cache
	@echo "Cleanup completed"

clean-all: clean clean-deps clean-samples
	@echo "Deep cleanup completed" 