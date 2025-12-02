# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-12-02

### 🎉 Initial Release

**Complete multi-layer server surveillance system for LexOrbital ecosystem.**

### Added

#### Surveillance Modules (5)
- **Resources Module** (`surveillance-resources.sh`)
  - CPU usage and load average monitoring
  - Memory (RAM + swap) tracking
  - Disk space and inode monitoring
  - I/O statistics (optional)
  - 8 checks total

- **Security Module** (`surveillance-security.sh`)
  - SSH failed login detection
  - Brute-force attack detection (>10 attempts/IP)
  - Sudo usage and anomaly tracking
  - Failed login analysis (btmp/wtmp)
  - Unusual login time detection
  - GDPR-compliant IP pseudonymization
  - 7 checks total

- **Services Module** (`surveillance-services.sh`)
  - System journal critical errors
  - Failed systemd units detection
  - Critical services status (sshd, docker, nginx)
  - Docker daemon and container health
  - Nginx status and error tracking
  - 9 checks total

- **Network Module** (`surveillance-network.sh`)
  - Open ports detection
  - Unexpected services identification
  - Firewall status verification (UFW/iptables)
  - Connection tracking
  - 5 checks total

- **Integrity Module** (`surveillance-integrity.sh`)
  - SHA256 file checksums verification
  - Permission and ownership change detection
  - Recent modifications tracking (24h)
  - Critical system files monitoring
  - 5 checks total

**Total: 34 system checks**

#### Core Infrastructure
- **Common Library** (`surveillance-common.sh`)
  - Structured logging functions
  - JSON report building and manipulation
  - GDPR pseudonymization utilities
  - Status evaluation logic
  - File operations helpers
  - 450+ lines of reusable functions

- **Orchestrator** (`surveillance-orchestrator.sh`)
  - Multi-module coordination (parallel/sequential)
  - Report aggregation and status calculation
  - Alert management (email, webhook)
  - API integration for Console Orbitale
  - Timeout and error handling
  - 450+ lines

#### Schemas & Types
- JSON Schema for surveillance reports
- JSON Schema for global reports
- TypeScript type definitions (400+ lines)
- Full schema validation support

#### Automation
- **Systemd Timers** (3)
  - Fast timer (5 min): Resources + Services
  - Full timer (1h): All modules
  - Integrity timer (daily): File integrity only
- Security hardening directives
- Resource limits (CPU, memory)
- Persistent execution across reboots

#### Tests
- Unit tests for common library (13 tests)
- Integration tests for all modules (20+ tests)
- JSON validation tests
- Test automation scripts
- Isolated test environment

#### Documentation (2500+ lines)
- Complete architecture design (500 lines)
- Operations guide with installation (600 lines)
- GDPR compliance documentation (500 lines)
- Quick start guide (300 lines)
- Module READMEs
- Troubleshooting guide

### Features

#### GDPR Compliance
- IP pseudonymization by default (`192.168.xxx.xxx`)
- Username pseudonymization (hashed)
- Configurable data retention (30 days default)
- Data minimization principles
- Strict file permissions (640/750)
- Complete GDPR documentation

#### Reporting
- Structured JSON reports with schemas
- Report validation
- Metadata tracking (hostname, timestamp, execution time)
- Status aggregation (healthy/warning/critical/unknown)
- Alert aggregation from all modules

#### Alerting
- Email notifications for critical events
- Webhook support for API integration
- Configurable severity thresholds
- Alert deduplication

#### Configuration
- Comprehensive configuration file (50+ parameters)
- Adjustable thresholds per module
- GDPR settings
- API integration settings
- Module enable/disable flags

### Security

- No plaintext sensitive data logging
- GDPR-compliant data handling
- Secure file permissions
- Input validation
- No external code execution
- Audit logging

### Performance

- Parallel module execution support
- Configurable timeouts (60s default)
- Resource limits via systemd
- Optimized for minimal CPU/memory footprint

---

## Release Notes

### Version 1.0.0

This is the **initial production release** of the LexOrbital Server Monitoring module, extracted from `lexorbital-module-server` into a dedicated, standalone module.

**Key Highlights**:
- ✅ 5 surveillance modules with 34 checks
- ✅ GDPR-compliant by design
- ✅ Automated via systemd timers
- ✅ Comprehensive documentation (FR)
- ✅ Production-ready

**Migration from lexorbital-module-server**:
- All monitoring functionality moved to this dedicated module
- Improved modularity and maintainability
- Independent versioning and releases
- Dedicated documentation structure

---

[1.0.0]: https://github.com/YohanGH/lexorbital-module-server-monitoring/releases/tag/v1.0.0
