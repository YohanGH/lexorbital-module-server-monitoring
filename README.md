# 🛰️ LexOrbital Module Server Monitoring

> **Multi-layer server surveillance system** with GDPR compliance and automated alerting for the LexOrbital ecosystem.

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Bash](https://img.shields.io/badge/Bash-4.0+-green)](https://www.gnu.org/software/bash/)
[![Documentation](https://img.shields.io/badge/docs-complete-brightgreen)](./docs/fr)

---

## 🎯 What is This?

A **production-ready surveillance system** providing:

- **Multi-layer monitoring**: Resources, Security, Services, Network, File Integrity
- **34 system checks**: CPU, RAM, SSH attacks, Docker health, open ports, checksums...
- **GDPR-compliant**: IP pseudonymization, data minimization, 30-day retention
- **Automated execution**: Systemd timers (5min, 1h, daily)
- **Structured reporting**: JSON reports consumable by APIs
- **Intelligent alerting**: Email and webhook notifications

**Ideal for:** Production servers requiring comprehensive monitoring with legal compliance.

---

## 🚀 Quick Start (5 minutes)

### Prerequisites

```bash
# Install dependencies
sudo apt-get update && sudo apt-get install -y jq sysstat net-tools
```

### Installation

```bash
# 1. Copy scripts
sudo cp monitoring/orchestrator/surveillance-orchestrator.sh \
  /usr/local/bin/lexorbital-surveillance-orchestrator.sh

sudo mkdir -p /usr/local/lib/lexorbital/surveillance
sudo cp -r monitoring/{modules,lib}/* /usr/local/lib/lexorbital/surveillance/

sudo chmod +x /usr/local/bin/lexorbital-surveillance-orchestrator.sh
sudo chmod +x /usr/local/lib/lexorbital/surveillance/*.sh

# 2. Create directories
sudo mkdir -p /var/lib/lexorbital/surveillance/{reports,config,checksums}
sudo mkdir -p /var/log/lexorbital

# 3. Configure
sudo cp monitoring/config/surveillance.conf.example \
  /var/lib/lexorbital/surveillance/config/surveillance.conf

# 4. First test
sudo /usr/local/bin/lexorbital-surveillance-orchestrator.sh

# 5. View report
cat /var/lib/lexorbital/surveillance/reports/global.json | jq '.'
```

### Automation (Optional)

```bash
# Install systemd timers
sudo cp systemd/surveillance/*.{service,timer} /etc/systemd/system/
sudo systemctl daemon-reload

# Enable timers
sudo systemctl enable --now lexorbital-surveillance-fast.timer
sudo systemctl enable --now lexorbital-surveillance-full.timer
sudo systemctl enable --now lexorbital-surveillance-integrity.timer

# Verify
systemctl list-timers | grep lexorbital
```

---

## 📊 Surveillance Modules

| Module | Checks | Description | Frequency |
|--------|--------|-------------|-----------|
| **Resources** | 8 | CPU, RAM, disk, I/O | 5 min |
| **Security** | 7 | SSH attacks, brute-force, sudo | 5 min |
| **Services** | 9 | Systemd, Docker, Nginx, logs | 5 min |
| **Network** | 5 | Open ports, firewall, connections | 1h |
| **Integrity** | 5 | File checksums, permissions | Daily |

**Total**: 34 system checks

---

## 🏛️ Architecture

### LexOrbital Orbital Architecture

- **Meta-Kernel**: Central orchestration ([lexorbital-core](https://github.com/YohanGH/lexorbital-core))
- **Ring 1**: UI modules ([lexorbital-module-ui-kit](https://github.com/YohanGH/lexorbital-module-ui-kit))
- **Ring 2**: Infrastructure modules
  - [lexorbital-module-server](https://github.com/YohanGH/lexorbital-module-server) - Server infrastructure
  - **lexorbital-module-server-monitoring** ← **you are here**
- **Ring 3**: Application modules

This module is part of **Ring 2** and provides comprehensive monitoring for server infrastructure.

### Tech Stack

- **Language**: Bash 4.0+
- **JSON**: jq for manipulation and validation
- **Automation**: Systemd timers
- **Schemas**: JSON Schema + TypeScript definitions
- **Testing**: Bash test framework (20+ tests)

---

## 🔒 GDPR Compliance

✅ **GDPR-compliant by default**:

- **Pseudonymization**: IPs (`192.168.xxx.xxx`) and usernames (hashed)
- **Data minimization**: Only essential data collected
- **Retention**: 30 days for reports, 7 days for logs
- **Security**: Strict file permissions (640/750)
- **Documentation**: Complete GDPR compliance guide

Configuration:

```bash
# In surveillance.conf
GDPR_PSEUDONYMIZE_IPS="true"
GDPR_RETENTION_DAYS="30"
GDPR_ENABLE_AUDIT_LOG="true"
```

See [GDPR Documentation](./docs/fr/compliance/surveillance-gdpr.md) for details.

---

## 📚 Documentation

👉 **[Complete Documentation (FR)](./docs/fr/index.md)**

### Quick Links

**For Decision Makers**:
- [Project Overview](./docs/fr/project/overview.md)
- [System Architecture](./docs/fr/architecture/surveillance-system-design.md)
- [GDPR Compliance](./docs/fr/compliance/surveillance-gdpr.md)

**For DevOps / SysAdmins**:
- [Installation Guide](./docs/fr/operations/installation.md)
- [Operations Guide](./docs/fr/operations/surveillance-guide.md)
- [Deployment](./docs/fr/operations/deployment.md)

**For Security**:
- [Security Measures](./docs/fr/security/hardening.md)
- [GDPR Technical Measures](./docs/fr/compliance/gdpr-technical.md)

---

## 🔍 Key Features

### 1. Resources Monitoring

- CPU usage and load average
- Memory (RAM + swap) consumption
- Disk space and inodes
- I/O statistics

### 2. Security Monitoring

- SSH failed login attempts
- Brute-force detection (>10 attempts/IP)
- Sudo usage and anomalies
- Failed login tracking (btmp/wtmp)

### 3. Services Monitoring

- Critical system errors (journalctl)
- Failed systemd units
- Docker containers health
- Nginx status and errors

### 4. Network Monitoring

- Open ports detection
- Unexpected services
- Firewall status (UFW/iptables)
- Connection tracking

### 5. File Integrity

- SHA256 checksums verification
- Permission/ownership changes
- Critical system files monitoring

---

## 📊 Output Example

### JSON Report Structure

```json
{
  "metadata": {
    "version": "1.0.0",
    "timestamp": "2025-12-02T10:30:00Z",
    "hostname": "server.example.com",
    "modulesExecuted": 5
  },
  "globalStatus": "warning",
  "summary": {
    "totalChecks": 34,
    "healthyChecks": 30,
    "warningChecks": 3,
    "criticalChecks": 1
  },
  "modules": {
    "resources": { ... },
    "security": { ... },
    "services": { ... },
    "network": { ... },
    "integrity": { ... }
  },
  "alerts": [
    {
      "severity": "critical",
      "source": "security.brute_force",
      "message": "Brute-force attack detected from 3 IP(s)",
      "timestamp": "2025-12-02T10:30:00Z"
    }
  ]
}
```

---

## 🧪 Testing

```bash
# Unit tests
cd monitoring/tests
./test-surveillance-common.sh

# Integration tests
./test-integration.sh
```

**Test Coverage**: 20+ tests covering all core functions and modules.

---

## ⚙️ Configuration

### Key Parameters

```bash
# Thresholds
THRESHOLD_CPU_WARNING="70"
THRESHOLD_CPU_CRITICAL="85"
THRESHOLD_MEMORY_WARNING="75"
THRESHOLD_MEMORY_CRITICAL="90"
THRESHOLD_DISK_WARNING="80"
THRESHOLD_DISK_CRITICAL="90"

# Security
THRESHOLD_SSH_FAILED_WARNING="5"
THRESHOLD_SSH_FAILED_CRITICAL="10"
SUDO_ALLOWED_USERS="root,admin,deploy"

# Network
NETWORK_ALLOWED_PORTS="22,80,443"

# GDPR
GDPR_PSEUDONYMIZE_IPS="true"
GDPR_RETENTION_DAYS="30"
```

Full configuration: [`monitoring/config/surveillance.conf.example`](./monitoring/config/surveillance.conf.example)

---

## 🛠️ Development

### Project Structure

```
lexorbital-module-server-monitoring/
├── monitoring/
│   ├── config/              # Configuration files
│   ├── lib/                 # Common libraries (450 lines)
│   ├── modules/             # 5 surveillance modules (1800+ lines)
│   ├── orchestrator/        # Main orchestrator (450 lines)
│   ├── schemas/             # JSON schemas
│   ├── types/               # TypeScript definitions
│   └── tests/               # Test suite (20+ tests)
├── systemd/                 # Systemd services & timers
├── docs/                    # Complete documentation (FR)
│   └── fr/
│       ├── architecture/
│       ├── operations/
│       ├── compliance/
│       └── security/
└── README.md
```

**Total**: ~3000 lines of code + 2500 lines of documentation

---

## 🤝 Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md) for contribution guidelines.

---

## 📄 License

[MIT](./LICENSE)

---

## 🔐 Security

See [SECURITY.md](./SECURITY.md) to report vulnerabilities.

---

## 📞 Support

- **Documentation**: [docs/fr/](./docs/fr/)
- **Issues**: [GitHub Issues](https://github.com/YohanGH/lexorbital-module-server-monitoring/issues)
- **Security**: [SECURITY.md](./SECURITY.md)

---

## 🌟 Highlights

✅ **5 surveillance modules** with 34 system checks  
✅ **GDPR-compliant by design** (pseudonymization, retention)  
✅ **Automated execution** via systemd timers  
✅ **Structured JSON reports** with schemas  
✅ **Intelligent alerting** (email, webhook)  
✅ **Comprehensive tests** (unit + integration)  
✅ **Complete documentation** (2500+ lines FR)  
✅ **Production-ready** deployable immediately  

---

## 📈 Related Modules

- [lexorbital-core](https://github.com/YohanGH/lexorbital-core) - Meta-Kernel orchestration
- [lexorbital-module-server](https://github.com/YohanGH/lexorbital-module-server) - Server infrastructure
- [lexorbital-module-ui-kit](https://github.com/YohanGH/lexorbital-module-ui-kit) - UI components

---

**Version**: 1.0.0  
**Last updated**: 2025-12-02  
**Maintained by**: [YohanGH](https://github.com/YohanGH)

---

<div align="center">

**Made with 🛰️ by the LexOrbital community**

[Documentation](./docs/fr) • [Contributing](./CONTRIBUTING.md) • [Issues](https://github.com/YohanGH/lexorbital-module-server-monitoring/issues)

</div>
