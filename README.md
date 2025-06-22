# infra-linter

A lightweight and fast linter written in Go that helps DevOps and SRE teams enforce best practices across infrastructure-related files like Dockerfile, Makefile, .env, crontab, and systemd unit files.

It can be used as a CLI tool or as a pre-commit hook to automatically catch common misconfigurations, security issues, and anti-patterns before they hit your repository.

## Features

- **Dockerfile**: Detects usage of latest tag, missing USER directive, lack of HEALTHCHECK, and other common issues
- **Makefile**: Warns about missing .PHONY declarations, repeated targets, and unquoted variables
- **Environment files**: Finds weak passwords, duplicate keys, and syntax errors in .env files
- **Crontab**: Detects risky schedules, missing logging, and malformed time expressions
- **Systemd units**: Warns about missing Restart directives, unsafe paths, and insecure configurations

## Installation

### Binary Releases

Download the latest binary from the [releases page](https://github.com/Gosayram/infra-linter/releases).

### From Source

```bash
go install github.com/Gosayram/infra-linter@latest
```

### Using Go

```bash
git clone https://github.com/Gosayram/infra-linter.git
cd infra-linter
go build -o infra-linter ./cmd/infra-linter
```

## Usage

### CLI Usage

```bash
# Lint specific files
infra-linter Dockerfile .env Makefile

# Lint all supported files in current directory
infra-linter .

# Show help
infra-linter --help

# Show version
infra-linter --version
```

### Pre-commit Hook

Add to your `.pre-commit-config.yaml`:

```yaml
repos:
  - repo: https://github.com/Gosayram/infra-linter
    rev: v1.0.0
    hooks:
      - id: infra-linter
        name: Infrastructure Linter
        entry: infra-linter
        language: golang
        files: \.(dockerfile|Dockerfile|env|makefile|Makefile|service|timer|socket)$
        pass_filenames: true
```

## Supported File Types

### Dockerfile

The linter checks for:

- Usage of `FROM image:latest` without specific version tags
- Missing `USER` directive (running as root)
- Absence of `HEALTHCHECK` for long-running services
- Inefficient layer caching patterns
- Security vulnerabilities in base images

### Environment Files (.env)

The linter validates:

- Weak passwords in variables containing `password`, `secret`, or `token`
- Common weak values like `admin`, `123456`, `qwerty`
- Duplicate variable declarations
- Malformed syntax (incorrect spacing, quotes)
- Missing required environment variables

### Makefile

The linter detects:

- Missing `.PHONY` declarations for non-file targets
- Duplicate target names
- Unquoted variable references
- Inconsistent indentation (tabs vs spaces)
- Missing error handling in critical targets

### Crontab

The linter identifies:

- Risky scheduling patterns that might cause system overload
- Missing logging or output redirection
- Malformed time expressions
- Jobs running as privileged users without justification

### Systemd Unit Files

The linter checks for:

- Missing `Restart=` directives for services
- Unsafe file paths or permissions
- Insecure service configurations
- Missing security hardening options
- Improper dependency declarations

## Configuration

Create a `.infra-linter.yaml` configuration file in your project root:

```yaml
# Global settings
severity: warning
output_format: text

# File type specific settings
dockerfile:
  allow_latest_tag: false
  require_user: true
  require_healthcheck: true

env:
  check_weak_passwords: true
  allowed_weak_patterns: []
  require_quotes: false

makefile:
  require_phony: true
  check_duplicates: true
  enforce_tabs: true

systemd:
  require_restart: true
  check_security: true
  enforce_user: true
```

## Output Format

The linter outputs messages in standard linter format:

```
[severity] file:line:column: message
[WARNING] Dockerfile:1:6: Using 'latest' tag is not recommended for production
[ERROR] .env:15:1: Duplicate environment variable 'DATABASE_PASSWORD'
[INFO] Makefile:23:1: Consider adding '.PHONY: clean' for non-file target
```

## Integration with CI/CD

### GitHub Actions

```yaml
name: Infrastructure Lint
on: [push, pull_request]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-go@v4
        with:
          go-version: '1.21'
      - name: Install infra-linter
        run: go install github.com/Gosayram/infra-linter@latest
      - name: Run linter
        run: infra-linter .
```

### GitLab CI

```yaml
infra-lint:
  image: golang:1.21
  script:
    - go install github.com/Gosayram/infra-linter@latest
    - infra-linter .
  rules:
    - changes:
        - "**/{Dockerfile,*.env,Makefile,*.service,*.timer}"
```

## Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### Development Setup

1. Clone the repository
2. Install Go 1.21 or later
3. Run tests: `go test ./...`
4. Build: `go build -o infra-linter ./cmd/infra-linter`

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Roadmap

See [IDEA.md](IDEA.md) for future plans and feature requests.

## Support

- Create an [issue](https://github.com/Gosayram/infra-linter/issues) for bug reports
- Start a [discussion](https://github.com/Gosayram/infra-linter/discussions) for feature requests
- Check existing [documentation](https://github.com/Gosayram/infra-linter/wiki) 