# 📦 Module Manifest - LexOrbital Module Server Monitoring

> **Inventaire complet** du module de surveillance serveur LexOrbital.

---

## 📋 Identification

| Propriété | Valeur |
|-----------|--------|
| **Nom** | lexorbital-module-server-monitoring |
| **Version** | 1.0.0 |
| **Type** | Infrastructure (Ring 2) |
| **Statut** | ✅ Production Ready |
| **Licence** | MIT |
| **Maintainer** | YohanGH |
| **Repository** | [GitHub](https://github.com/YohanGH/lexorbital-module-server-monitoring) |

---

## 📁 Structure Complète

### Code Source (`monitoring/`)

```
monitoring/
├── config/                         # Configuration
│   └── surveillance.conf.example   # 200 lignes - Configuration complète
├── lib/                            # Bibliothèques communes
│   └── surveillance-common.sh      # 450 lignes - Fonctions partagées
├── modules/                        # Modules de surveillance
│   ├── surveillance-resources.sh   # 350 lignes - CPU, RAM, disque, I/O
│   ├── surveillance-security.sh    # 400 lignes - SSH, brute-force, sudo
│   ├── surveillance-services.sh    # 380 lignes - Systemd, Docker, Nginx
│   ├── surveillance-network.sh     # 300 lignes - Ports, firewall
│   └── surveillance-integrity.sh   # 350 lignes - Checksums fichiers
├── orchestrator/                   # Orchestration
│   └── surveillance-orchestrator.sh # 450 lignes - Coordination modules
├── schemas/                        # Schemas JSON
│   ├── surveillance-report.schema.json        # Schema rapport individuel
│   └── global-surveillance-report.schema.json # Schema rapport global
├── types/                          # Définitions TypeScript
│   └── surveillance.types.ts       # 400 lignes - Interfaces complètes
└── tests/                          # Tests
    ├── test-surveillance-common.sh # 200 lignes - Tests unitaires (13 tests)
    └── test-integration.sh         # 300 lignes - Tests intégration (20+ tests)
```

**Total Code**: ~3600 lignes

### Automatisation (`systemd/`)

```
systemd/surveillance/
├── lexorbital-surveillance-fast.service       # Service fast (5min)
├── lexorbital-surveillance-fast.timer         # Timer fast
├── lexorbital-surveillance-full.service       # Service full (1h)
├── lexorbital-surveillance-full.timer         # Timer full
├── lexorbital-surveillance-integrity.service  # Service integrity (daily)
└── lexorbital-surveillance-integrity.timer    # Timer integrity
```

**Total**: 6 fichiers systemd

### Documentation (`docs/`)

```
docs/fr/
├── index.md                                     # 300 lignes - Index principal
├── architecture/
│   ├── diagrams/                               # Diagrammes
│   └── surveillance-system-design.md           # 500 lignes - Architecture complète
├── compliance/
│   ├── gdpr-technical.md                       # Mesures RGPD techniques
│   └── surveillance-gdpr.md                    # 500 lignes - Conformité complète
├── operations/
│   ├── surveillance-guide.md                   # 600 lignes - Guide opérationnel
│   ├── Surveillance Tests.md                   # Guide tests
│   ├── Surveillance-Systemd-Services-&-Timers.md # Guide systemd
│   └── Surveillance-System.md                  # Vue d'ensemble système
├── project/
│   └── overview.md                             # 400 lignes - Vue d'ensemble projet
├── reference/
│   └── scripts.md                              # Référence scripts
└── howto/
    └── troubleshooting.md                      # Guide dépannage
```

**Total Documentation**: ~2500 lignes

### Fichiers Root

```
/
├── .github/
│   └── MODULE-MANIFEST.md                      # Ce fichier
├── CHANGELOG.md                                # Historique versions
├── CODE_OF_CONDUCT.md                          # Code de conduite
├── CONTRIBUTING.md                             # Guide contribution
├── LICENSE                                     # Licence MIT
├── lexorbital.module.json                      # Manifest module
├── QUICK-START.md                              # 300 lignes - Démarrage rapide
├── README.md                                   # README anglais
├── README-fr.md                                # README français (principal)
├── SECURITY.md                                 # Politique sécurité
└── SUPPORT.md                                  # Support
```

---

## 📊 Métriques

### Code

| Métrique | Valeur |
|----------|--------|
| **Lignes de code Bash** | ~2600 |
| **Lignes TypeScript** | ~400 |
| **Lignes JSON/Schema** | ~300 |
| **Lignes configuration** | ~200 |
| **Total code** | ~3600 |

### Documentation

| Métrique | Valeur |
|----------|--------|
| **Documents markdown** | 15 |
| **Lignes documentation** | ~2500 |
| **Langue** | Français (FR) |

### Tests

| Métrique | Valeur |
|----------|--------|
| **Scripts de test** | 2 |
| **Tests unitaires** | 13 |
| **Tests intégration** | 20+ |
| **Couverture** | Core functions |

### Fonctionnalités

| Métrique | Valeur |
|----------|--------|
| **Modules surveillance** | 5 |
| **Checks système** | 34 |
| **Timers systemd** | 3 |
| **Schemas JSON** | 2 |

---

## 🎯 Capacités

### Surveillance

✅ **Resources** (8 checks):
- CPU usage et load average
- Memory (RAM + swap)
- Disk space et inodes
- I/O statistics

✅ **Security** (7 checks):
- SSH failed logins
- Brute-force detection
- Sudo usage et anomalies
- Failed login tracking

✅ **Services** (9 checks):
- Critical system errors (journalctl)
- Failed systemd units
- Docker containers health
- Nginx status et errors

✅ **Network** (5 checks):
- Open ports detection
- Unexpected services
- Firewall status
- Connection tracking

✅ **Integrity** (5 checks):
- SHA256 checksums
- Permission/ownership changes
- Critical system files

### Rapports

✅ **JSON structurés** avec schemas  
✅ **Validation** JSON Schema  
✅ **Agrégation** multi-modules  
✅ **Métadonnées** complètes  
✅ **Status** aggregated (healthy/warning/critical)  

### Automatisation

✅ **Systemd timers** (3 fréquences)  
✅ **Parallel execution** modules  
✅ **Timeout management**  
✅ **Resource limits** (CPU, memory)  
✅ **Security hardening**  

### Alerting

✅ **Email notifications**  
✅ **Webhook/API integration**  
✅ **Severity levels** (info, warning, critical)  
✅ **Alert aggregation**  
✅ **Configurable thresholds**  

### Conformité

✅ **GDPR by design**  
✅ **IP pseudonymization** (`192.168.xxx.xxx`)  
✅ **Username hashing**  
✅ **Data retention** (30 days)  
✅ **Data minimization**  
✅ **Audit logging**  
✅ **Documentation complète** (Article 30)  

---

## 🔧 Dépendances

### Système Requis

| Dépendance | Version | Type | Usage |
|------------|---------|------|-------|
| **Bash** | >= 4.0 | Obligatoire | Scripts |
| **jq** | >= 1.5 | Obligatoire | JSON manipulation |
| **systemd** | >= 232 | Obligatoire | Automation |
| **sysstat** | >= 11.0 | Optionnel | iostat (I/O) |
| **net-tools** | >= 1.60 | Optionnel | netstat fallback |

### OS Supportés

✅ Debian 11+  
✅ Ubuntu 20.04+  
✅ Debian-based distributions  

---

## 🚀 Installation

### Rapide (5 minutes)

```bash
# 1. Dépendances
sudo apt-get install -y jq sysstat net-tools

# 2. Scripts
sudo cp monitoring/orchestrator/surveillance-orchestrator.sh \
  /usr/local/bin/lexorbital-surveillance-orchestrator.sh
sudo mkdir -p /usr/local/lib/lexorbital/surveillance
sudo cp -r monitoring/{modules,lib}/* /usr/local/lib/lexorbital/surveillance/
sudo chmod +x /usr/local/bin/lexorbital-surveillance-orchestrator.sh
sudo chmod +x /usr/local/lib/lexorbital/surveillance/*.sh

# 3. Configuration
sudo mkdir -p /var/lib/lexorbital/surveillance/{reports,config,checksums}
sudo cp monitoring/config/surveillance.conf.example \
  /var/lib/lexorbital/surveillance/config/surveillance.conf

# 4. Test
sudo /usr/local/bin/lexorbital-surveillance-orchestrator.sh

# 5. Automation
sudo cp systemd/surveillance/*.{service,timer} /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now lexorbital-surveillance-full.timer
```

Voir [QUICK-START.md](../QUICK-START.md) pour détails.

---

## 📚 Documentation

| Document | Description | Lignes |
|----------|-------------|--------|
| [README-fr.md](../README-fr.md) | README principal (FR) | ~350 |
| [QUICK-START.md](../QUICK-START.md) | Démarrage rapide | ~300 |
| [Architecture](../docs/fr/architecture/surveillance-system-design.md) | Design système complet | ~500 |
| [Operations](../docs/fr/operations/surveillance-guide.md) | Guide opérationnel | ~600 |
| [RGPD](../docs/fr/compliance/surveillance-gdpr.md) | Conformité RGPD | ~500 |
| [Tests](../docs/fr/operations/Surveillance%20Tests.md) | Guide tests | ~200 |
| [Systemd](../docs/fr/operations/Surveillance-Systemd-Services-&-Timers.md) | Automation | ~300 |

**Total**: ~2500 lignes de documentation

---

## 🎯 Roadmap

### Version 1.0.0 (Actuelle) ✅

- [x] 5 modules de surveillance
- [x] 34 checks système
- [x] Rapports JSON structurés
- [x] Automatisation systemd
- [x] Conformité RGPD
- [x] Documentation complète
- [x] Tests (20+)

### Version 1.1.0 (Q1 2026)

- [ ] Intégration Prometheus/Grafana
- [ ] Monitoring distribué multi-serveurs
- [ ] Dashboard temps réel
- [ ] Notifications Slack/Teams
- [ ] Rapports hebdomadaires automatiques

### Version 2.0.0 (Q2 2026)

- [ ] Machine Learning pour détection anomalies
- [ ] Prédiction pannes
- [ ] Auto-remédiation
- [ ] API REST complète

---

## 🔗 Liens

- **Repository**: https://github.com/YohanGH/lexorbital-module-server-monitoring
- **Documentation**: [docs/fr/](../docs/fr/)
- **Issues**: https://github.com/YohanGH/lexorbital-module-server-monitoring/issues
- **Meta-Kernel**: https://github.com/YohanGH/lexorbital-core
- **Module Server**: https://github.com/YohanGH/lexorbital-module-server

---

## 📄 Licence

MIT License - Voir [LICENSE](../LICENSE)

---

**Version Manifest**: 1.0.0  
**Date**: 2025-12-02  
**Maintenu par**: [YohanGH](https://github.com/YohanGH)

