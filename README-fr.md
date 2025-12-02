# 🛰️ LexOrbital Module Server Monitoring

> **Système de surveillance serveur multi-couches** avec conformité RGPD et alertes automatisées pour l'écosystème LexOrbital.

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Bash](https://img.shields.io/badge/Bash-4.0+-green)](https://www.gnu.org/software/bash/)
[![Documentation](https://img.shields.io/badge/docs-complète-brightgreen)](./docs/fr)

---

## 🌍 Langue / Language

- 🇫🇷 **Vous êtes ici** - Documentation technique complète en français
- 🇬🇧 **[English version](./README.md)** - Professional showcase version

---

## 🎯 Qu'est-ce que c'est ?

Un **système de surveillance production-ready** offrant :

- **Surveillance multi-couches** : Ressources, Sécurité, Services, Réseau, Intégrité fichiers
- **34 vérifications système** : CPU, RAM, attaques SSH, santé Docker, ports ouverts, checksums...
- **Conformité RGPD** : Pseudonymisation IPs, minimisation données, rétention 30 jours
- **Exécution automatisée** : Timers systemd (5min, 1h, quotidien)
- **Rapports structurés** : JSON consommable par API
- **Alertes intelligentes** : Notifications email et webhook

**Idéal pour** : Serveurs de production nécessitant une surveillance complète avec conformité légale.

---

## 🚀 Démarrage Rapide (5 minutes)

### Prérequis

```bash
# Installer les dépendances
sudo apt-get update && sudo apt-get install -y jq sysstat net-tools
```

### Installation

```bash
# 1. Copier les scripts
sudo cp monitoring/orchestrator/surveillance-orchestrator.sh \
  /usr/local/bin/lexorbital-surveillance-orchestrator.sh

sudo mkdir -p /usr/local/lib/lexorbital/surveillance
sudo cp -r monitoring/{modules,lib}/* /usr/local/lib/lexorbital/surveillance/

sudo chmod +x /usr/local/bin/lexorbital-surveillance-orchestrator.sh
sudo chmod +x /usr/local/lib/lexorbital/surveillance/*.sh

# 2. Créer les répertoires
sudo mkdir -p /var/lib/lexorbital/surveillance/{reports,config,checksums}
sudo mkdir -p /var/log/lexorbital

# 3. Configurer
sudo cp monitoring/config/surveillance.conf.example \
  /var/lib/lexorbital/surveillance/config/surveillance.conf

# 4. Premier test
sudo /usr/local/bin/lexorbital-surveillance-orchestrator.sh

# 5. Voir le rapport
cat /var/lib/lexorbital/surveillance/reports/global.json | jq '.'
```

### Automatisation (Optionnel)

```bash
# Installer les timers systemd
sudo cp systemd/surveillance/*.{service,timer} /etc/systemd/system/
sudo systemctl daemon-reload

# Activer les timers
sudo systemctl enable --now lexorbital-surveillance-fast.timer
sudo systemctl enable --now lexorbital-surveillance-full.timer
sudo systemctl enable --now lexorbital-surveillance-integrity.timer

# Vérifier
systemctl list-timers | grep lexorbital
```

---

## 📊 Modules de Surveillance

| Module | Checks | Description | Fréquence |
|--------|--------|-------------|-----------|
| **Resources** | 8 | CPU, RAM, disque, I/O | 5 min |
| **Security** | 7 | Attaques SSH, brute-force, sudo | 5 min |
| **Services** | 9 | Systemd, Docker, Nginx, logs | 5 min |
| **Network** | 5 | Ports ouverts, firewall, connexions | 1h |
| **Integrity** | 5 | Checksums fichiers, permissions | Quotidien |

**Total** : 34 vérifications système

---

## 🏛️ Architecture

### Architecture Orbitale LexOrbital

- **Meta-Kernel** : Orchestration centrale ([lexorbital-core](https://github.com/YohanGH/lexorbital-core))
- **Ring 1** : Modules UI ([lexorbital-module-ui-kit](https://github.com/YohanGH/lexorbital-module-ui-kit))
- **Ring 2** : Modules infrastructure
  - [lexorbital-module-server](https://github.com/YohanGH/lexorbital-module-server) - Infrastructure serveur
  - **lexorbital-module-server-monitoring** ← **vous êtes ici**
- **Ring 3** : Modules applicatifs

Ce module fait partie du **Ring 2** et fournit une surveillance complète pour l'infrastructure serveur.

### Stack Technique

- **Langage** : Bash 4.0+
- **JSON** : jq pour manipulation et validation
- **Automatisation** : Timers systemd
- **Schemas** : JSON Schema + définitions TypeScript
- **Tests** : Framework Bash (20+ tests)

---

## 🔒 Conformité RGPD

✅ **Conforme RGPD par défaut** :

- **Pseudonymisation** : IPs (`192.168.xxx.xxx`) et usernames (hashés)
- **Minimisation** : Seules les données essentielles collectées
- **Rétention** : 30 jours pour rapports, 7 jours pour logs
- **Sécurité** : Permissions fichiers strictes (640/750)
- **Documentation** : Guide RGPD complet

Configuration :

```bash
# Dans surveillance.conf
GDPR_PSEUDONYMIZE_IPS="true"
GDPR_RETENTION_DAYS="30"
GDPR_ENABLE_AUDIT_LOG="true"
```

Voir [Documentation RGPD](./docs/fr/compliance/surveillance-gdpr.md) pour détails.

---

## 📚 Documentation

👉 **[Documentation Complète (FR)](./docs/fr/index.md)**

### Liens Rapides

**Pour Décideurs** :
- [Vue d'ensemble](./docs/fr/project/overview.md)
- [Architecture Système](./docs/fr/architecture/surveillance-system-design.md)
- [Conformité RGPD](./docs/fr/compliance/surveillance-gdpr.md)

**Pour DevOps / SysAdmins** :
- [Guide d'Installation](./docs/fr/operations/installation.md)
- [Guide Opérationnel](./docs/fr/operations/surveillance-guide.md)
- [Déploiement](./docs/fr/operations/deployment.md)

**Pour Sécurité** :
- [Mesures Sécurité](./docs/fr/security/hardening.md)
- [Mesures RGPD Techniques](./docs/fr/compliance/gdpr-technical.md)

---

## 🔍 Fonctionnalités Clés

### 1. Surveillance Ressources

- Utilisation CPU et load average
- Consommation mémoire (RAM + swap)
- Espace disque et inodes
- Statistiques I/O

### 2. Surveillance Sécurité

- Tentatives connexion SSH échouées
- Détection brute-force (>10 tentatives/IP)
- Usage sudo et anomalies
- Suivi logins échoués (btmp/wtmp)

### 3. Surveillance Services

- Erreurs système critiques (journalctl)
- Unités systemd en échec
- Santé containers Docker
- Status et erreurs Nginx

### 4. Surveillance Réseau

- Détection ports ouverts
- Services inattendus
- Status firewall (UFW/iptables)
- Suivi connexions

### 5. Intégrité Fichiers

- Vérification checksums SHA256
- Changements permissions/ownership
- Surveillance fichiers système critiques

---

## 🧪 Tests

```bash
# Tests unitaires
cd monitoring/tests
./test-surveillance-common.sh

# Tests d'intégration
./test-integration.sh
```

**Couverture** : 20+ tests couvrant toutes les fonctions et modules.

---

## ⚙️ Configuration

### Paramètres Clés

```bash
# Seuils
THRESHOLD_CPU_WARNING="70"
THRESHOLD_CPU_CRITICAL="85"
THRESHOLD_MEMORY_WARNING="75"
THRESHOLD_MEMORY_CRITICAL="90"
THRESHOLD_DISK_WARNING="80"
THRESHOLD_DISK_CRITICAL="90"

# Sécurité
THRESHOLD_SSH_FAILED_WARNING="5"
THRESHOLD_SSH_FAILED_CRITICAL="10"
SUDO_ALLOWED_USERS="root,admin,deploy"

# Réseau
NETWORK_ALLOWED_PORTS="22,80,443"

# RGPD
GDPR_PSEUDONYMIZE_IPS="true"
GDPR_RETENTION_DAYS="30"
```

Configuration complète : [`monitoring/config/surveillance.conf.example`](./monitoring/config/surveillance.conf.example)

---

## 🛠️ Développement

### Structure du Projet

```
lexorbital-module-server-monitoring/
├── monitoring/
│   ├── config/              # Fichiers de configuration
│   ├── lib/                 # Bibliothèques communes (450 lignes)
│   ├── modules/             # 5 modules surveillance (1800+ lignes)
│   ├── orchestrator/        # Orchestrateur principal (450 lignes)
│   ├── schemas/             # Schemas JSON
│   ├── types/               # Définitions TypeScript
│   └── tests/               # Suite de tests (20+ tests)
├── systemd/                 # Services & timers systemd
├── docs/                    # Documentation complète (FR)
│   └── fr/
│       ├── architecture/
│       ├── operations/
│       ├── compliance/
│       └── security/
└── README.md
```

**Total** : ~3000 lignes de code + 2500 lignes de documentation

---

## 🤝 Contribuer

Voir [CONTRIBUTING.md](./CONTRIBUTING.md) pour les guidelines de contribution.

---

## 📄 Licence

[MIT](./LICENSE)

---

## 🔐 Sécurité

Voir [SECURITY.md](./SECURITY.md) pour signaler des vulnérabilités.

---

## 📞 Support

- **Documentation** : [docs/fr/](./docs/fr/)
- **Issues** : [GitHub Issues](https://github.com/YohanGH/lexorbital-module-server-monitoring/issues)
- **Sécurité** : [SECURITY.md](./SECURITY.md)

---

## 🌟 Points Forts

✅ **5 modules de surveillance** avec 34 checks système  
✅ **Conforme RGPD** par design (pseudonymisation, rétention)  
✅ **Exécution automatisée** via timers systemd  
✅ **Rapports JSON structurés** avec schemas  
✅ **Alertes intelligentes** (email, webhook)  
✅ **Tests complets** (unitaires + intégration)  
✅ **Documentation exhaustive** (2500+ lignes FR)  
✅ **Production-ready** déployable immédiatement  

---

## 📈 Modules Liés

- [lexorbital-core](https://github.com/YohanGH/lexorbital-core) - Meta-Kernel orchestration
- [lexorbital-module-server](https://github.com/YohanGH/lexorbital-module-server) - Infrastructure serveur
- [lexorbital-module-ui-kit](https://github.com/YohanGH/lexorbital-module-ui-kit) - Composants UI

---

**Version** : 1.0.0  
**Dernière mise à jour** : 2025-12-02  
**Maintenu par** : [YohanGH](https://github.com/YohanGH)

---

<div align="center">

**Made with 🛰️ by the LexOrbital community**

[Documentation](./docs/fr) • [Contribuer](./CONTRIBUTING.md) • [Issues](https://github.com/YohanGH/lexorbital-module-server-monitoring/issues)

</div>

