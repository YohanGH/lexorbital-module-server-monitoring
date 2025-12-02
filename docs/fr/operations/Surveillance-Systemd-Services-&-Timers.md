# LexOrbital Surveillance Systemd Services & Timers

This directory contains systemd units for automated surveillance execution.

## 📁 Files

### Services

- `lexorbital-surveillance-fast.service` - Fast checks (resources, services)
- `lexorbital-surveillance-full.service` - Full surveillance (all modules)
- `lexorbital-surveillance-integrity.service` - File integrity checks only

### Timers

- `lexorbital-surveillance-fast.timer` - Every 5 minutes
- `lexorbital-surveillance-full.timer` - Every hour
- `lexorbital-surveillance-integrity.timer` - Daily at 3 AM

## 🚀 Installation

### 1. Install Surveillance Scripts

First, ensure the surveillance scripts are installed:

```bash
# Copy orchestrator to system bin
sudo cp monitoring/orchestrator/surveillance-orchestrator.sh \
  /usr/local/bin/lexorbital-surveillance-orchestrator.sh

# Copy modules
sudo mkdir -p /usr/local/lib/lexorbital/surveillance
sudo cp -r monitoring/modules/* /usr/local/lib/lexorbital/surveillance/
sudo cp -r monitoring/lib/* /usr/local/lib/lexorbital/surveillance/

# Make executable
sudo chmod +x /usr/local/bin/lexorbital-surveillance-orchestrator.sh
sudo chmod +x /usr/local/lib/lexorbital/surveillance/*.sh

# Update script paths in orchestrator
sudo sed -i 's|${SCRIPT_DIR}/../modules|/usr/local/lib/lexorbital/surveillance|g' \
  /usr/local/bin/lexorbital-surveillance-orchestrator.sh
```

### 2. Install Systemd Units

```bash
# Copy service and timer files
sudo cp systemd/surveillance/*.service /etc/systemd/system/
sudo cp systemd/surveillance/*.timer /etc/systemd/system/

# Reload systemd daemon
sudo systemctl daemon-reload
```

### 3. Configure Surveillance

```bash
# Create configuration directory
sudo mkdir -p /var/lib/lexorbital/surveillance/config

# Copy and edit configuration
sudo cp monitoring/config/surveillance.conf.example \
  /var/lib/lexorbital/surveillance/config/surveillance.conf

sudo nano /var/lib/lexorbital/surveillance/config/surveillance.conf
```

### 4. Initialize File Integrity Database

```bash
# Initialize checksums (required for integrity module)
sudo /usr/local/bin/lexorbital-surveillance-orchestrator.sh --modules integrity
```

### 5. Enable and Start Timers

```bash
# Enable timers (start on boot)
sudo systemctl enable lexorbital-surveillance-fast.timer
sudo systemctl enable lexorbital-surveillance-full.timer
sudo systemctl enable lexorbital-surveillance-integrity.timer

# Start timers immediately
sudo systemctl start lexorbital-surveillance-fast.timer
sudo systemctl start lexorbital-surveillance-full.timer
sudo systemctl start lexorbital-surveillance-integrity.timer
```

## 📊 Monitoring

### Check Timer Status

```bash
# List all LexOrbital timers
systemctl list-timers | grep lexorbital-surveillance

# Detailed status
sudo systemctl status lexorbital-surveillance-fast.timer
sudo systemctl status lexorbital-surveillance-full.timer
sudo systemctl status lexorbital-surveillance-integrity.timer
```

### Check Service Logs

```bash
# View logs for fast surveillance
sudo journalctl -u lexorbital-surveillance-fast.service -f

# View logs for full surveillance
sudo journalctl -u lexorbital-surveillance-full.service -f

# View logs for integrity checks
sudo journalctl -u lexorbital-surveillance-integrity.service -f

# View all surveillance logs
sudo journalctl -t lexorbital-surveillance-* -f
```

### Manual Execution

```bash
# Run fast surveillance manually
sudo systemctl start lexorbital-surveillance-fast.service

# Run full surveillance manually
sudo systemctl start lexorbital-surveillance-full.service

# Run integrity check manually
sudo systemctl start lexorbital-surveillance-integrity.service

# Or run directly
sudo /usr/local/bin/lexorbital-surveillance-orchestrator.sh
```

## ⚙️ Customization

### Adjust Frequency

Edit timer files to change execution frequency:

```bash
sudo systemctl edit --full lexorbital-surveillance-fast.timer
```

Example: Change to every 10 minutes:
```ini
[Timer]
OnBootSec=10min
OnUnitActiveSec=10min
```

Then reload:
```bash
sudo systemctl daemon-reload
sudo systemctl restart lexorbital-surveillance-fast.timer
```

### Resource Limits

Edit service files to adjust CPU/memory limits:

```bash
sudo systemctl edit --full lexorbital-surveillance-full.service
```

Example: Increase memory limit:
```ini
[Service]
MemoryMax=1G
CPUQuota=50%
```

## 🔧 Troubleshooting

### Timer Not Running

```bash
# Check if timer is active
sudo systemctl is-active lexorbital-surveillance-full.timer

# Check timer logs
sudo journalctl -u lexorbital-surveillance-full.timer

# Restart timer
sudo systemctl restart lexorbital-surveillance-full.timer
```

### Service Failing

```bash
# Check service status
sudo systemctl status lexorbital-surveillance-full.service

# View detailed logs
sudo journalctl -u lexorbital-surveillance-full.service -n 50

# Test script manually
sudo /usr/local/bin/lexorbital-surveillance-orchestrator.sh
```

### Permission Issues

```bash
# Check directory permissions
sudo ls -la /var/lib/lexorbital/surveillance
sudo ls -la /var/log/lexorbital

# Fix permissions
sudo chown -R root:root /var/lib/lexorbital/surveillance
sudo chmod -R 750 /var/lib/lexorbital/surveillance
sudo chmod -R 640 /var/lib/lexorbital/surveillance/reports/*.json
```

## 🗑️ Uninstallation

```bash
# Stop and disable timers
sudo systemctl stop lexorbital-surveillance-*.timer
sudo systemctl disable lexorbital-surveillance-*.timer

# Remove systemd units
sudo rm /etc/systemd/system/lexorbital-surveillance-*.service
sudo rm /etc/systemd/system/lexorbital-surveillance-*.timer

# Reload daemon
sudo systemctl daemon-reload

# Remove scripts (optional)
sudo rm /usr/local/bin/lexorbital-surveillance-orchestrator.sh
sudo rm -rf /usr/local/lib/lexorbital/surveillance

# Remove data (optional - WARNING: deletes all reports)
# sudo rm -rf /var/lib/lexorbital/surveillance
```

## 📚 See Also

- [Surveillance Architecture](../../docs/fr/architecture/surveillance-system-design.md)
- [Operations Guide](../../docs/fr/operations/surveillance-guide.md)
- [Configuration Reference](../../monitoring/config/surveillance.conf.example)

---

**Version**: 1.0.0  
**Last updated**: 2025-12-02

