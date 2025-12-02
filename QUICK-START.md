# 🚀 Quick Start - LexOrbital Module Server Monitoring

> **Installation et configuration en 5 minutes.**

---

## ⚡ Installation Express

### 1. Prérequis (30 secondes)

```bash
sudo apt-get update && sudo apt-get install -y jq sysstat net-tools
```

### 2. Installation Scripts (2 minutes)

```bash
# Copier l'orchestrateur
sudo cp monitoring/orchestrator/surveillance-orchestrator.sh \
  /usr/local/bin/lexorbital-surveillance-orchestrator.sh

# Copier les modules et bibliothèques
sudo mkdir -p /usr/local/lib/lexorbital/surveillance
sudo cp -r monitoring/modules/* /usr/local/lib/lexorbital/surveillance/
sudo cp -r monitoring/lib/* /usr/local/lib/lexorbital/surveillance/

# Rendre exécutable
sudo chmod +x /usr/local/bin/lexorbital-surveillance-orchestrator.sh
sudo chmod +x /usr/local/lib/lexorbital/surveillance/*.sh
```

### 3. Configuration (1 minute)

```bash
# Créer répertoires
sudo mkdir -p /var/lib/lexorbital/surveillance/{reports,config,checksums}
sudo mkdir -p /var/log/lexorbital

# Copier configuration
sudo cp monitoring/config/surveillance.conf.example \
  /var/lib/lexorbital/surveillance/config/surveillance.conf

# (Optionnel) Éditer la configuration
sudo nano /var/lib/lexorbital/surveillance/config/surveillance.conf
```

### 4. Premier Test (30 secondes)

```bash
# Exécuter surveillance complète
sudo /usr/local/bin/lexorbital-surveillance-orchestrator.sh

# Voir le résultat
cat /var/lib/lexorbital/surveillance/reports/global.json | jq '.globalStatus'
```

### 5. Automatisation (1 minute)

```bash
# Installer timers systemd
sudo cp systemd/surveillance/*.service /etc/systemd/system/
sudo cp systemd/surveillance/*.timer /etc/systemd/system/

# Activer
sudo systemctl daemon-reload
sudo systemctl enable --now lexorbital-surveillance-fast.timer
sudo systemctl enable --now lexorbital-surveillance-full.timer
sudo systemctl enable --now lexorbital-surveillance-integrity.timer

# Vérifier
systemctl list-timers | grep lexorbital-surveillance
```

---

## ✅ Vérification

### Rapports Générés

```bash
# Lister les rapports
ls -lh /var/lib/lexorbital/surveillance/reports/

# Voir rapport global
jq '.' /var/lib/lexorbital/surveillance/reports/global.json

# Voir status de chaque module
jq '.modules | to_entries[] | {module: .key, status: .value.status}' \
  /var/lib/lexorbital/surveillance/reports/global.json
```

### Logs

```bash
# Logs surveillance
sudo journalctl -u lexorbital-surveillance-full.service -n 50

# Logs fichier
sudo tail -f /var/log/lexorbital/surveillance.log
```

### Status Timers

```bash
# Lister les timers actifs
systemctl list-timers | grep lexorbital

# Status détaillé
systemctl status lexorbital-surveillance-full.timer
```

---

## 🔧 Configuration Rapide

### Ajuster les Seuils

```bash
# Éditer configuration
sudo nano /var/lib/lexorbital/surveillance/config/surveillance.conf

# Exemple: augmenter seuil CPU
# THRESHOLD_CPU_WARNING="80"
# THRESHOLD_CPU_CRITICAL="90"
```

### Activer Alertes Email

```bash
# Dans surveillance.conf
ALERT_EMAIL_ENABLED="true"
ALERT_EMAIL_RECIPIENTS="admin@example.com"
ALERT_MIN_SEVERITY="warning"
```

### Configurer API Console Orbitale

```bash
# Dans surveillance.conf
API_ENABLED="true"
API_ENDPOINT="https://console.example.com/api/surveillance/report"
API_TOKEN="your-secure-token-here"
```

---

## 📊 Commandes Utiles

### Exécution Manuelle

```bash
# Tous les modules
sudo /usr/local/bin/lexorbital-surveillance-orchestrator.sh

# Un module spécifique
sudo /usr/local/bin/lexorbital-surveillance-orchestrator.sh --modules resources

# Plusieurs modules
sudo /usr/local/bin/lexorbital-surveillance-orchestrator.sh --modules resources,security

# Mode debug
SURVEILLANCE_DEBUG=true sudo /usr/local/bin/lexorbital-surveillance-orchestrator.sh
```

### Consulter les Rapports

```bash
# Status global
jq -r '.globalStatus' /var/lib/lexorbital/surveillance/reports/global.json

# Résumé des checks
jq '.summary' /var/lib/lexorbital/surveillance/reports/global.json

# Alertes critiques
jq '[.alerts[] | select(.severity == "critical")]' \
  /var/lib/lexorbital/surveillance/reports/global.json

# Checks en échec
jq '[.modules[].checks[] | select(.status != "healthy")]' \
  /var/lib/lexorbital/surveillance/reports/global.json
```

### Gestion Timers

```bash
# Démarrer timer
sudo systemctl start lexorbital-surveillance-full.timer

# Arrêter timer
sudo systemctl stop lexorbital-surveillance-full.timer

# Redémarrer timer
sudo systemctl restart lexorbital-surveillance-full.timer

# Désactiver timer
sudo systemctl disable lexorbital-surveillance-full.timer

# Forcer exécution immédiate
sudo systemctl start lexorbital-surveillance-full.service
```

---

## 🐛 Dépannage Express

### Module ne s'exécute pas

```bash
# Vérifier permissions
sudo chmod +x /usr/local/lib/lexorbital/surveillance/*.sh

# Tester manuellement
sudo bash /usr/local/lib/lexorbital/surveillance/surveillance-resources.sh
```

### JSON invalide

```bash
# Valider JSON
jq empty /var/lib/lexorbital/surveillance/reports/resources.json

# Si erreur, voir logs
sudo tail -f /var/log/lexorbital/surveillance.log
```

### Timer inactif

```bash
# Recharger systemd
sudo systemctl daemon-reload

# Vérifier status
systemctl status lexorbital-surveillance-full.timer

# Voir logs timer
sudo journalctl -u lexorbital-surveillance-full.timer -n 50
```

### Dépendances manquantes

```bash
# Installer toutes les dépendances
sudo apt-get install -y jq sysstat net-tools util-linux coreutils
```

---

## 📚 Documentation Complète

Pour aller plus loin :

- **[Guide Opérationnel Complet](./docs/fr/operations/surveillance-guide.md)** - Installation détaillée, configuration avancée
- **[Architecture](./docs/fr/architecture/surveillance-system-design.md)** - Design complet du système
- **[RGPD](./docs/fr/compliance/surveillance-gdpr.md)** - Conformité et mesures techniques
- **[README Principal](./README-fr.md)** - Vue d'ensemble

---

## 🎯 Checklist Production

Avant de déployer en production :

- [ ] Dépendances installées (jq, sysstat, net-tools)
- [ ] Scripts copiés et exécutables
- [ ] Configuration personnalisée
- [ ] Premier test manuel réussi
- [ ] Rapports JSON valides
- [ ] Timers systemd activés
- [ ] Seuils ajustés à votre environnement
- [ ] Alertes configurées (email ou webhook)
- [ ] RGPD vérifié (pseudonymisation active)
- [ ] Documentation lue
- [ ] Équipe formée

---

## 🌟 Next Steps

### Après Installation

1. **Monitorer** les premiers rapports (24h)
2. **Ajuster** les seuils selon votre environnement
3. **Configurer** les alertes critiques
4. **Documenter** votre configuration
5. **Former** l'équipe

### Optimisations

```bash
# Ajuster fréquence timers
sudo systemctl edit --full lexorbital-surveillance-fast.timer

# Ajouter fichiers à surveiller (integrity)
sudo nano /var/lib/lexorbital/surveillance/config/surveillance.conf
# INTEGRITY_MONITORED_PATHS="/etc/passwd,/etc/shadow,/custom/file"

# Réinitialiser checksums après modification légale
sudo /usr/local/lib/lexorbital/surveillance/surveillance-integrity.sh --init
```

---

**Temps total installation** : ⏱️ **5 minutes**  
**Prêt pour production** : ✅ **OUI**

---

<div align="center">

**🛰️ LexOrbital Module Server Monitoring**

[Documentation](./docs/fr) • [GitHub](https://github.com/YohanGH/lexorbital-module-server-monitoring) • [Issues](https://github.com/YohanGH/lexorbital-module-server-monitoring/issues)

</div>

