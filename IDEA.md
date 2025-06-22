# Development Ideas and Roadmap

This document outlines the development roadmap, feature ideas, and long-term vision for infra-linter.

## MVP Goals

Create a cross-platform Go tool that:

- Checks Dockerfile, .env, and Makefile files
- Runs as a standard CLI command (`infra-linter file1 file2 ...`)
- Integrates with pre-commit hooks
- Outputs messages in standard linter format (`[severity] file:line: message`)

## MVP Feature Set

### 1. Dockerfile Support

Priority checks to implement:

- **Latest Tag Detection**: Warn when using `FROM image:latest`
- **Root User Detection**: Alert when `USER` directive is missing (running as root)
- **Health Check Validation**: Detect missing `HEALTHCHECK` for long-running services

### 2. Environment File Support (.env)

Essential validations:

- **Weak Credential Detection**: Warn when variables containing `password`, `secret`, `token` have weak values (`admin`, `123456`, `qwerty`)
- **Duplicate Variable Detection**: Identify repeated variable declarations
- **Syntax Validation**: Check for malformed format (`KEY =VALUE`, improper spacing, unnecessary quotes)

### 3. Makefile Support

Core functionality:

- **PHONY Declaration Check**: Detect missing `.PHONY` for non-file targets
- **Duplicate Target Detection**: Identify repeated target names
- **Silent Command Analysis**: Optional check for `@` or `-` usage without comments

## Technical Architecture

### Core Components

```
cmd/
  infra-linter/           # Main CLI entry point
internal/
  linter/                 # Core linting engine
    dockerfile/           # Dockerfile-specific rules
    env/                  # Environment file rules
    makefile/             # Makefile rules
  config/                 # Configuration management
  output/                 # Output formatting
  rules/                  # Rule definitions and registry
pkg/
  scanner/                # File scanning utilities
  parser/                 # File parsing logic
```

### Design Principles

- **Modular Architecture**: Each file type has its own package
- **Pluggable Rules**: Easy to add new rules without changing core logic
- **Performance Focus**: Concurrent processing of multiple files
- **Zero External Dependencies**: Pure Go implementation where possible

## Future Enhancements

### Phase 2: Extended File Support

#### Crontab Support
- Risky schedule pattern detection
- Missing logging validation
- Malformed time expression checks
- Privilege escalation warnings

#### Systemd Unit Files
- Missing `Restart=` directive detection
- Unsafe path validation
- Security configuration auditing
- Dependency declaration verification

### Phase 3: Advanced Features

#### Configuration Management
- Custom rule configuration via `.infra-linter.yaml`
- Rule severity customization
- File-specific rule exclusions
- Team-wide configuration templates

#### Output Enhancements
- Multiple output formats (JSON, SARIF, JUnit XML)
- Integration with popular CI/CD platforms
- Detailed fix suggestions
- Interactive fix mode

#### Performance Optimizations
- Parallel file processing
- Incremental scanning (only changed files)
- Caching of parsing results
- Memory usage optimization for large codebases

### Phase 4: Enterprise Features

#### IDE Integration
- VS Code extension
- Language Server Protocol (LSP) support
- Real-time linting in editors
- Auto-fix capabilities

#### Advanced Security Scanning
- CVE database integration for base images
- Secret pattern detection using regex libraries
- Compliance framework validation (SOC 2, PCI DSS)
- Supply chain security checks

#### Reporting and Analytics
- Trend analysis across commits
- Team performance metrics
- Rule effectiveness statistics
- Custom dashboard integration

## Implementation Priorities

### High Priority (MVP)
1. Core CLI structure and argument parsing
2. File type detection and routing
3. Basic Dockerfile rules implementation
4. Environment file validation
5. Makefile analysis
6. Standard output formatting
7. Pre-commit hook configuration

### Medium Priority (Post-MVP)
1. Configuration file support
2. Additional output formats
3. Crontab support
4. Systemd unit file support
5. Performance optimizations
6. Comprehensive test coverage

### Low Priority (Future)
1. IDE integrations
2. Web dashboard
3. Advanced security features
4. Machine learning for rule suggestions
5. Custom rule scripting interface

## Technical Considerations

### Go-Specific Requirements

Based on project coding standards:

- All numeric literals must be named constants
- Error handling with proper context wrapping
- Dependency injection for testability
- Interface-based design for extensibility
- Comprehensive unit tests with table-driven patterns

### Constant Definitions

```go
const (
    // Exit codes
    ExitSuccess = 0
    ExitLintErrors = 1
    ExitFatalError = 2
    
    // File type identifiers
    FileTypeDockerfile = "dockerfile"
    FileTypeEnv = "env"
    FileTypeMakefile = "makefile"
    
    // Severity levels
    SeverityInfo = "INFO"
    SeverityWarning = "WARNING"
    SeverityError = "ERROR"
    
    // Default limits
    MaxConcurrentFiles = 10
    DefaultTimeoutSeconds = 30
    MaxFileSize = 10 * 1024 * 1024 // 10MB
)
```

### Performance Targets

- Process 1000+ files in under 10 seconds
- Memory usage under 100MB for typical repositories
- Support files up to 10MB in size
- Concurrent processing of multiple file types

## Community and Ecosystem

### Integration Targets

- **Pre-commit**: Official hook configuration
- **GitHub Actions**: Marketplace action
- **GitLab CI**: Template integration
- **Jenkins**: Plugin development
- **Docker**: Official container images

### Documentation Strategy

- Comprehensive rule documentation with examples
- Integration guides for popular CI/CD platforms
- Video tutorials for common use cases
- Community-contributed rule examples
- Best practices documentation

## Metrics and Success Criteria

### Adoption Metrics
- GitHub stars and forks
- Docker image pulls
- Package manager downloads
- Community contributions

### Quality Metrics
- Test coverage above 90%
- Zero critical security vulnerabilities
- Performance benchmarks within targets
- User satisfaction scores

### Feature Completeness
- All MVP features implemented and tested
- Pre-commit integration working
- CLI tool production-ready
- Documentation complete

## Risk Assessment

### Technical Risks
- **Parser Complexity**: Some file formats may be harder to parse accurately
- **Performance**: Large repositories might cause memory issues
- **Compatibility**: Different file format variations across ecosystems

### Mitigation Strategies
- Incremental parsing approach
- Memory profiling and optimization
- Extensive testing with real-world files
- Community feedback integration

### Market Risks
- Competition from existing tools
- Changing DevOps tool landscape
- Integration complexity with various platforms

### Success Factors
- Focus on ease of use and integration
- Strong community engagement
- Regular updates and maintenance
- Clear value proposition over alternatives 