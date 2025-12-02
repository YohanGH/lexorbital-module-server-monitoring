# LexOrbital Surveillance System

> **Multi-layer server surveillance system** with GDPR compliance and automated alerting.

---

## 🎯 Overview

This surveillance system provides comprehensive monitoring for:

- **Resources**: CPU, RAM, disk, I/O
- **Security**: SSH attacks, brute-force, sudo anomalies
- **Services**: Systemd units, Docker containers, critical errors
- **Network**: Open ports, suspicious connections
- **Integrity**: File checksums, permission audits

All modules produce structured JSON reports consumable by the LexOrbital Console Orbitale.

---

## 📁 Structure

```
monitoring/
├── config/
│   └── surveillance.conf.example   # Configuration template
├── lib/
│   └── surveillance-common.sh      # Shared utilities
├── modules/
│   ├── surveillance-resources.sh   # Resources monitoring
│   ├── surveillance-security.sh    # Security audits
│   ├── surveillance-services.sh    # Services health
│   ├── surveillance-network.sh     # Network audits
│   └── surveillance-integrity.sh   # File integrity
├── orchestrator/
│   └── surveillance-orchestrator.sh # Main orchestrator
├── schemas/
│   ├── surveillance-report.schema.json
│   └── global-surveillance-report.schema.json
├── types/
│   └── surveillance.types.ts       # TypeScript interfaces
└── README.md                        # This file
```

---

## 🚀 Quick Start

### 1. Installation

```bash
# Copy configuration
sudo cp monitoring/config/surveillance.conf.example \
  /var/lib/lexorbital/surveillance/config/surveillance.conf

# Edit configuration
sudo nano /var/lib/lexorbital/surveillance/config/surveillance.conf

# Make scripts executable
sudo chmod +x monitoring/modules/*.sh
sudo chmod +x monitoring/orchestrator/*.sh
```

### 2. Manual Execution

```bash
# Run individual module
sudo ./monitoring/modules/surveillance-resources.sh

# Run all modules (orchestrator)
sudo ./monitoring/orchestrator/surveillance-orchestrator.sh
```

### 3. Automated Execution (Systemd Timers)

```bash
# Install systemd timers
sudo cp systemd/surveillance/*.timer /etc/systemd/system/
sudo cp systemd/surveillance/*.service /etc/systemd/system/

# Enable and start
sudo systemctl enable --now lexorbital-surveillance-full.timer
sudo systemctl enable --now lexorbital-surveillance-fast.timer
```

---

## 📊 Output

### JSON Reports

Reports are saved to `/var/lib/lexorbital/surveillance/reports/`:

- `resources.json` - Resources module
- `security.json` - Security module
- `services.json` - Services module
- `network.json` - Network module
- `integrity.json` - Integrity module
- `global.json` - Aggregated report

### Report Structure

```json
{
  "metadata": {
    "module": "resources",
    "version": "1.0.0",
    "timestamp": "2025-12-02T10:30:00Z",
    "hostname": "server.example.com",
    "executionTime": 1234
  },
  "status": "warning",
  "checks": [
    {
      "id": "cpu.usage",
      "name": "CPU Usage",
      "status": "warning",
      "message": "CPU usage is 75%",
      "value": 75,
      "threshold": {
        "warning": 70,
        "critical": 85
      }
    }
  ],
  "metrics": {},
  "alerts": []
}
```

---

## 🔒 Security & GDPR

### GDPR Compliance

- **IP Pseudonymization**: `192.168.1.42` → `192.168.xxx.xxx`
- **Data Retention**: 30 days by default
- **Minimization**: Only essential data collected
- **Access Control**: Reports readable only by root and lexorbital user

### Security Features

- Least privilege execution (non-root when possible)
- Strict file permissions (750 for scripts, 640 for reports)
- Input validation on all parameters
- No external code execution
- Structured logging

---

## ⚙️ Configuration

Edit `/var/lib/lexorbital/surveillance/config/surveillance.conf`:

```bash
# Enable/disable modules
MODULE_RESOURCES_ENABLED="true"
MODULE_SECURITY_ENABLED="true"

# Adjust thresholds
THRESHOLD_CPU_WARNING="70"
THRESHOLD_CPU_CRITICAL="85"

# Configure GDPR
GDPR_PSEUDONYMIZE_IPS="true"
GDPR_RETENTION_DAYS="30"

# Configure alerts
ALERTS_ENABLED="true"
ALERT_METHODS="console,email"
```

---

## 🧪 Testing

```bash
# Run tests (requires bats)
./tests/surveillance/run-tests.sh

# Validate JSON output
jq empty /var/lib/lexorbital/surveillance/reports/global.json

# Check systemd timers
systemctl list-timers | grep lexorbital-surveillance
```

---

## 📚 Documentation

- [Architecture](../docs/fr/architecture/surveillance-system-design.md)
- [Operations Guide](../docs/fr/operations/surveillance-guide.md)
- [Security](../docs/fr/security/surveillance-security.md)
- [GDPR Compliance](../docs/fr/compliance/surveillance-gdpr.md)

---

## 🐛 Troubleshooting

### Check logs

```bash
sudo journalctl -u lexorbital-surveillance-full
sudo tail -f /var/log/lexorbital/surveillance.log
```

### Debug mode

```bash
SURVEILLANCE_DEBUG=true ./monitoring/orchestrator/surveillance-orchestrator.sh
```

### Validate configuration

```bash
bash -n monitoring/modules/surveillance-resources.sh  # Syntax check
shellcheck monitoring/modules/*.sh                    # Linting
```

---

## 📝 License

MIT

---

**Version**: 1.0.0  
**Last updated**: 2025-12-02
