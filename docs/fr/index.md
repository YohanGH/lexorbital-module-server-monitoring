# 📚 Documentation LexOrbital Module Server Monitoring

> **Documentation complète** du système de surveillance serveur multi-couches LexOrbital.

---

## 🎯 Bienvenue

Cette documentation couvre tous les aspects du **système de surveillance LexOrbital**, incluant l'architecture, l'installation, la configuration, et la conformité RGPD.

---

## 🛰️ À Propos

**LexOrbital Module Server Monitoring** est un système de surveillance autonome et modulaire offrant :

- ✅ **5 modules** de surveillance (ressources, sécurité, services, réseau, intégrité)
- ✅ **34 vérifications** système automatisées
- ✅ **Rapports JSON** structurés et validés
- ✅ **Conformité RGPD** intégrée par design
- ✅ **Automatisation** via systemd timers
- ✅ **Alertes** intelligentes (email, webhook)

---

## 🗂️ Navigation

### 📖 Vue d'Ensemble

- **[🚀 Démarrage Rapide](../../README-fr.md#démarrage-rapide-5-minutes)** - Installation en 5 minutes
- **[📊 Modules de Surveillance](../../README-fr.md#modules-de-surveillance)** - Vue d'ensemble des 5 modules
- **[🏛️ Architecture Orbitale](../../README-fr.md#architecture)** - Position dans l'écosystème

### 🏗️ Architecture

- **[Design Système Complet](./architecture/surveillance-system-design.md)** ⭐
  - Architecture multi-couches
  - Interfaces et contrats JSON
  - Stratégie de tests
  - Conformité RGPD intégrée
  - Roadmap d'implémentation

### 🔧 Opérations

- **[Guide Opérationnel Complet](./operations/surveillance-guide.md)** ⭐
  - Installation pas-à-pas
  - Configuration détaillée
  - Utilisation quotidienne
  - Maintenance
  - Dépannage complet

- **[Tests Surveillance](./operations/Surveillance%20Tests.md)**
  - Tests unitaires et intégration
  - Guide d'utilisation
  - Couverture de tests

- **[Services & Timers Systemd](./operations/Surveillance-Systemd-Services-&-Timers.md)**
  - Installation des timers
  - Configuration systemd
  - Gestion et monitoring

- **[Vue d'Ensemble Système](./operations/Surveillance-System.md)**
  - Fonctionnement global
  - Architecture technique

### ✅ Conformité & Sécurité

- **[Conformité RGPD](./compliance/surveillance-gdpr.md)** ⭐
  - Cadre juridique (Articles 6, 30, 32)
  - Registre des traitements
  - Mesures techniques
  - Analyse d'impact (DPIA)
  - Droits des personnes
  - Checklist conformité

- **[Mesures Techniques RGPD](./compliance/gdpr-technical.md)**
  - Pseudonymisation
  - Chiffrement
  - Contrôle d'accès

### 📘 Référence

- **[Scripts](./reference/scripts.md)**
  - Référence des scripts
  - Paramètres et options

### 📝 How-To

- **[Dépannage](./howto/troubleshooting.md)**
  - Résolution des problèmes courants
  - FAQ

---

## 🚀 Par où Commencer ?

### Pour Décideurs / Recruteurs

1. [Vue d'ensemble (README)](../../README-fr.md)
2. [Architecture Système](./architecture/surveillance-system-design.md)
3. [Conformité RGPD](./compliance/surveillance-gdpr.md)

### Pour DevOps / SysAdmins

1. **Installation** : [README - Démarrage Rapide](../../README-fr.md#démarrage-rapide-5-minutes)
2. **Configuration** : [Guide Opérationnel](./operations/surveillance-guide.md)
3. **Automatisation** : [Services Systemd](./operations/Surveillance-Systemd-Services-&-Timers.md)
4. **Dépannage** : [Guide Troubleshooting](./howto/troubleshooting.md)

### Pour Sécurité / Conformité

1. [Conformité RGPD Complète](./compliance/surveillance-gdpr.md)
2. [Mesures Techniques](./compliance/gdpr-technical.md)
3. [Architecture Sécurité](./architecture/surveillance-system-design.md#sécurité--rgpd)

### Pour Développeurs

1. [Architecture Design](./architecture/surveillance-system-design.md)
2. [Tests](./operations/Surveillance%20Tests.md)
3. [Référence Scripts](./reference/scripts.md)

---

## 📦 Structure du Projet

```
lexorbital-module-server-monitoring/
├── monitoring/                      # Code source
│   ├── config/                     # Configuration
│   ├── lib/                        # Bibliothèques communes (450 lignes)
│   ├── modules/                    # 5 modules surveillance (1800+ lignes)
│   ├── orchestrator/               # Orchestrateur principal (450 lignes)
│   ├── schemas/                    # Schemas JSON
│   ├── types/                      # Types TypeScript
│   └── tests/                      # Tests (20+)
├── systemd/                        # Automation
│   └── surveillance/               # Services & timers
├── docs/fr/                        # Documentation (vous êtes ici)
│   ├── architecture/               # Design & architecture
│   ├── operations/                 # Guides opérationnels
│   ├── compliance/                 # RGPD & conformité
│   ├── reference/                  # Référence technique
│   └── howto/                      # Tutoriels pratiques
└── README-fr.md                    # README principal
```

---

## 🔍 Fonctionnalités Clés

### 5 Modules de Surveillance

| Module | Checks | Fréquence | Description |
|--------|--------|-----------|-------------|
| **Resources** | 8 | 5 min | CPU, RAM, disque, I/O |
| **Security** | 7 | 5 min | SSH, brute-force, sudo |
| **Services** | 9 | 5 min | Systemd, Docker, Nginx |
| **Network** | 5 | 1h | Ports, firewall |
| **Integrity** | 5 | Quotidien | Checksums fichiers |

**Total : 34 vérifications système**

### Rapports JSON Structurés

Tous les modules génèrent des rapports JSON validés par schemas :

```json
{
  "metadata": {
    "module": "resources",
    "version": "1.0.0",
    "timestamp": "2025-12-02T10:30:00Z",
    "hostname": "server.example.com"
  },
  "status": "warning",
  "checks": [...],
  "alerts": [...]
}
```

### Conformité RGPD

✅ Pseudonymisation par défaut  
✅ Rétention limitée (30 jours)  
✅ Minimisation des données  
✅ Sécurisation (permissions strictes)  
✅ Documentation complète  

---

## 🎯 Cas d'Usage

### 1. Surveillance Production

```bash
# Surveillance automatisée toutes les 5 minutes
sudo systemctl enable --now lexorbital-surveillance-fast.timer
```

### 2. Détection Attaques SSH

Le module sécurité détecte automatiquement :
- Tentatives brute-force (>10 échecs/IP)
- Logins depuis IPs inhabituelles
- Usage sudo non autorisé

### 3. Monitoring Containers Docker

```bash
# Check santé containers
sudo /usr/local/bin/lexorbital-surveillance-orchestrator.sh --modules services
```

### 4. Audit Conformité RGPD

Tous les rapports sont GDPR-compliant :
- IPs pseudonymisées : `192.168.xxx.xxx`
- Rétention automatique 30 jours
- Logs d'audit complets

---

## 📊 Métriques

- **Code** : ~3000 lignes (Bash, TypeScript, JSON)
- **Documentation** : 2500+ lignes (FR)
- **Tests** : 20+ tests (unitaires + intégration)
- **Modules** : 5 modules indépendants
- **Checks** : 34 vérifications système
- **Couverture** : Ressources, Sécurité, Services, Réseau, Intégrité

---

## 🤝 Contribuer

Ce module fait partie de l'écosystème LexOrbital. Pour contribuer :

1. Lire [CONTRIBUTING.md](../../CONTRIBUTING.md)
2. Respecter l'architecture orbitale
3. Suivre les conventions de code
4. Ajouter des tests
5. Mettre à jour la documentation

---

## 📄 Licence

[MIT](../../LICENSE)

---

## 🔗 Modules Liés

- [lexorbital-core](https://github.com/YohanGH/lexorbital-core) - Meta-Kernel
- [lexorbital-module-server](https://github.com/YohanGH/lexorbital-module-server) - Infrastructure serveur
- [lexorbital-module-ui-kit](https://github.com/YohanGH/lexorbital-module-ui-kit) - Composants UI

---

## 📞 Support

- **Issues** : [GitHub Issues](https://github.com/YohanGH/lexorbital-module-server-monitoring/issues)
- **Security** : [SECURITY.md](../../SECURITY.md)
- **Community** : [LexOrbital Discussions](https://github.com/orgs/YohanGH/discussions)

---

**Version Documentation** : 1.0.0  
**Dernière mise à jour** : 2025-12-02  
**Maintenu par** : [YohanGH](https://github.com/YohanGH)

---

<div align="center">

**Made with 🛰️ by the LexOrbital community**

[GitHub](https://github.com/YohanGH/lexorbital-module-server-monitoring) • [Documentation](.) • [Contributing](../../CONTRIBUTING.md)

</div>
