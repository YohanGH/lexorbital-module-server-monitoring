# Guide Opérationnel - Système de Surveillance

> **Guide complet** pour l'utilisation et la maintenance du système de surveillance LexOrbital.

---

## 🎯 Objectif

Ce guide fournit les instructions pour installer, configurer, utiliser et maintenir le système de surveillance multi-couches de LexOrbital.

---

## 📋 Table des Matières

1. [Prérequis](#prérequis)
2. [Installation](#installation)
3. [Configuration](#configuration)
4. [Utilisation](#utilisation)
5. [Maintenance](#maintenance)
6. [Dépannage](#dépannage)

---

## 🔧 Prérequis

### Système d'exploitation

- Debian 11+ ou Ubuntu 20.04+
- systemd (pour l'automatisation)
- Accès root ou sudo

### Logiciels requis

```bash
# Installation des dépendances
sudo apt-get update
sudo apt-get install -y \
  jq \
  sysstat \
  net-tools \
  coreutils \
  util-linux
```

### Espace disque

- `/var/lib/lexorbital/surveillance` : ~100 MB (rapports)
- `/var/log/lexorbital` : ~50 MB (logs)

---

## 📦 Installation

### 1. Cloner le Dépôt

```bash
git clone https://github.com/YohanGH/lexorbital-module-server
cd lexorbital-module-server
```

### 2. Installer les Scripts

```bash
# Copier l'orchestrateur
sudo cp monitoring/orchestrator/surveillance-orchestrator.sh \
  /usr/local/bin/lexorbital-surveillance-orchestrator.sh

# Copier les modules
sudo mkdir -p /usr/local/lib/lexorbital/surveillance
sudo cp -r monitoring/modules/* /usr/local/lib/lexorbital/surveillance/
sudo cp -r monitoring/lib/* /usr/local/lib/lexorbital/surveillance/

# Rendre exécutable
sudo chmod +x /usr/local/bin/lexorbital-surveillance-orchestrator.sh
sudo chmod +x /usr/local/lib/lexorbital/surveillance/*.sh
```

### 3. Installer les Timers Systemd

```bash
# Copier les services et timers
sudo cp systemd/surveillance/*.service /etc/systemd/system/
sudo cp systemd/surveillance/*.timer /etc/systemd/system/

# Recharger systemd
sudo systemctl daemon-reload
```

### 4. Créer les Répertoires

```bash
# Créer les répertoires nécessaires
sudo mkdir -p /var/lib/lexorbital/surveillance/{reports,config,checksums}
sudo mkdir -p /var/log/lexorbital

# Permissions
sudo chmod 750 /var/lib/lexorbital/surveillance
sudo chmod 750 /var/log/lexorbital
```

---

## ⚙️ Configuration

### 1. Fichier de Configuration Principal

```bash
# Copier l'exemple de configuration
sudo cp monitoring/config/surveillance.conf.example \
  /var/lib/lexorbital/surveillance/config/surveillance.conf

# Éditer la configuration
sudo nano /var/lib/lexorbital/surveillance/config/surveillance.conf
```

### 2. Paramètres Essentiels

#### a) RGPD & Confidentialité

```bash
# Activer la pseudonymisation des IPs (recommandé)
GDPR_PSEUDONYMIZE_IPS="true"

# Rétention des données (jours)
GDPR_RETENTION_DAYS="30"
```

#### b) Modules Actifs

```bash
# Activer/désactiver les modules
MODULE_RESOURCES_ENABLED="true"
MODULE_SECURITY_ENABLED="true"
MODULE_SERVICES_ENABLED="true"
MODULE_NETWORK_ENABLED="true"
MODULE_INTEGRITY_ENABLED="true"
```

#### c) Seuils d'Alerte

```bash
# CPU (%)
THRESHOLD_CPU_WARNING="70"
THRESHOLD_CPU_CRITICAL="85"

# Mémoire (%)
THRESHOLD_MEMORY_WARNING="75"
THRESHOLD_MEMORY_CRITICAL="90"

# Disque (%)
THRESHOLD_DISK_WARNING="80"
THRESHOLD_DISK_CRITICAL="90"

# SSH tentatives échouées
THRESHOLD_SSH_FAILED_WARNING="5"
THRESHOLD_SSH_FAILED_CRITICAL="10"
```

#### d) Alertes

```bash
# Activer les alertes
ALERTS_ENABLED="true"

# Méthodes d'alerte
ALERT_METHODS="console,email"

# Email (si activé)
ALERT_EMAIL_ENABLED="true"
ALERT_EMAIL_RECIPIENTS="admin@example.com"
```

#### e) API Console Orbitale

```bash
# Activer l'envoi à la console
API_ENABLED="true"
API_ENDPOINT="https://console.example.com/api/surveillance/report"
API_TOKEN="your-api-token-here"
```

### 3. Initialiser l'Intégrité Fichiers

```bash
# Initialiser la base de données des checksums
sudo /usr/local/bin/lexorbital-surveillance-orchestrator.sh --modules integrity
```

---

## 🚀 Utilisation

### Exécution Manuelle

#### Exécuter Tous les Modules

```bash
sudo /usr/local/bin/lexorbital-surveillance-orchestrator.sh
```

#### Exécuter un Module Spécifique

```bash
# Module ressources uniquement
sudo /usr/local/bin/lexorbital-surveillance-orchestrator.sh --modules resources

# Plusieurs modules
sudo /usr/local/bin/lexorbital-surveillance-orchestrator.sh --modules resources,security
```

#### Avec Configuration Personnalisée

```bash
sudo /usr/local/bin/lexorbital-surveillance-orchestrator.sh \
  --config /path/to/custom.conf
```

### Automatisation (Systemd)

#### Activer les Timers

```bash
# Surveillance rapide (5 minutes)
sudo systemctl enable --now lexorbital-surveillance-fast.timer

# Surveillance complète (1 heure)
sudo systemctl enable --now lexorbital-surveillance-full.timer

# Intégrité fichiers (quotidien)
sudo systemctl enable --now lexorbital-surveillance-integrity.timer
```

#### Vérifier le Statut

```bash
# Lister tous les timers
systemctl list-timers | grep lexorbital-surveillance

# Statut détaillé
sudo systemctl status lexorbital-surveillance-full.timer
```

#### Exécuter Manuellement un Service

```bash
sudo systemctl start lexorbital-surveillance-full.service
```

---

## 📊 Consultation des Rapports

### Rapports JSON

Les rapports sont stockés dans `/var/lib/lexorbital/surveillance/reports/` :

```bash
# Rapport global (tous modules)
cat /var/lib/lexorbital/surveillance/reports/global.json | jq '.'

# Rapport ressources
cat /var/lib/lexorbital/surveillance/reports/resources.json | jq '.'

# Statut global
jq -r '.globalStatus' /var/lib/lexorbital/surveillance/reports/global.json
```

### Résumé Rapide

```bash
# Afficher le résumé
jq -r '.summary' /var/lib/lexorbital/surveillance/reports/global.json

# Compter les alertes critiques
jq '[.alerts[] | select(.severity == "critical")] | length' \
  /var/lib/lexorbital/surveillance/reports/global.json
```

### Logs

```bash
# Logs de surveillance
sudo journalctl -u lexorbital-surveillance-full.service -f

# Logs détaillés
sudo tail -f /var/log/lexorbital/surveillance.log
```

---

## 🔧 Maintenance

### Rotation des Rapports

```bash
# Script de nettoyage (exemple)
find /var/lib/lexorbital/surveillance/reports/ \
  -name "*.json" -mtime +30 -delete
```

### Mise à Jour des Seuils

```bash
# Éditer la configuration
sudo nano /var/lib/lexorbital/surveillance/config/surveillance.conf

# Redémarrer les timers
sudo systemctl restart lexorbital-surveillance-*.timer
```

### Réinitialiser les Checksums

```bash
# Si des fichiers légitimes ont changé
sudo /usr/local/lib/lexorbital/surveillance/surveillance-integrity.sh --init
```

### Tester la Configuration

```bash
# Exécution test avec debug
SURVEILLANCE_DEBUG=true \
sudo /usr/local/bin/lexorbital-surveillance-orchestrator.sh
```

---

## 🐛 Dépannage

### Problème : Module ne s'exécute pas

**Symptômes** : Aucun rapport généré

**Solutions** :

```bash
# Vérifier les permissions
ls -la /usr/local/lib/lexorbital/surveillance/

# Rendre exécutable
sudo chmod +x /usr/local/lib/lexorbital/surveillance/*.sh

# Tester manuellement
sudo bash /usr/local/lib/lexorbital/surveillance/surveillance-resources.sh
```

### Problème : JSON invalide

**Symptômes** : Erreur "invalid JSON"

**Solutions** :

```bash
# Valider le JSON
jq empty /var/lib/lexorbital/surveillance/reports/resources.json

# Voir les erreurs
cat /var/lib/lexorbital/surveillance/reports/resources.json
```

### Problème : Timer ne démarre pas

**Symptômes** : Timer inactif

**Solutions** :

```bash
# Vérifier le statut
sudo systemctl status lexorbital-surveillance-full.timer

# Voir les logs
sudo journalctl -u lexorbital-surveillance-full.timer -n 50

# Redémarrer
sudo systemctl daemon-reload
sudo systemctl restart lexorbital-surveillance-full.timer
```

### Problème : Permissions refusées

**Symptômes** : "Permission denied"

**Solutions** :

```bash
# Vérifier les permissions
sudo ls -la /var/lib/lexorbital/surveillance

# Corriger
sudo chown -R root:root /var/lib/lexorbital/surveillance
sudo chmod -R 750 /var/lib/lexorbital/surveillance
```

### Problème : Dépendances manquantes

**Symptômes** : "command not found"

**Solutions** :

```bash
# Installer jq
sudo apt-get install -y jq

# Installer sysstat (pour iostat)
sudo apt-get install -y sysstat
```

---

## 📈 Bonnes Pratiques

### 1. Surveillance Proactive

- Consulter les rapports quotidiennement
- Configurer les alertes email pour les événements critiques
- Ajuster les seuils selon votre environnement

### 2. Sécurité

- Limiter l'accès aux rapports (chmod 640)
- Activer la pseudonymisation RGPD
- Rotation régulière des logs

### 3. Performance

- Ajuster la fréquence des timers selon la charge
- Utiliser la surveillance rapide pour les ressources critiques
- Exécuter l'intégrité en dehors des heures de pointe

### 4. Documentation

- Documenter les changements de seuils
- Tenir un journal des incidents
- Mettre à jour les configurations après modifications système

---

## 📚 Voir Aussi

- [Architecture du Système](../architecture/surveillance-system-design.md)
- [Sécurité](../security/surveillance-security.md)
- [Conformité RGPD](../compliance/surveillance-gdpr.md)
- [Référence API](../reference/surveillance-api.md)

---

**Version** : 1.0.0  
**Dernière mise à jour** : 2025-12-02  
**Auteur** : LexOrbital DevOps Team @YohanGH
