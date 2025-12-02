# Vue d'Ensemble - LexOrbital Module Server Monitoring

> **Présentation du système de surveillance serveur multi-couches LexOrbital**.

---

## 🎯 Qu'est-ce que LexOrbital Module Server Monitoring ?

Un système de **surveillance serveur autonome et modulaire** conçu pour détecter les anomalies, les attaques, les erreurs système et les dérives de ressources, tout en respectant la conformité RGPD.

---

## 🌟 Proposition de Valeur

### Pour les Équipes DevOps

✅ **Surveillance complète** en une seule solution  
✅ **Installation rapide** (5 minutes)  
✅ **Automatisation** via systemd timers  
✅ **Alertes intelligentes** (email, webhook)  
✅ **Rapports structurés** (JSON validé)  

### Pour les Responsables Sécurité

✅ **Détection brute-force** automatique  
✅ **Audit complet** (SSH, sudo, services)  
✅ **Intégrité fichiers** (checksums SHA256)  
✅ **Conformité RGPD** intégrée  
✅ **Journalisation** sécurisée  

### Pour les DPO / Conformité

✅ **RGPD by design** (pseudonymisation, minimisation)  
✅ **Documentation complète** (Article 30)  
✅ **Rétention automatique** (30 jours)  
✅ **Mesures techniques** (Article 32)  
✅ **Audit trail** complet  

---

## 📊 En Chiffres

| Métrique | Valeur |
|----------|--------|
| **Modules** | 5 |
| **Checks système** | 34 |
| **Lignes de code** | ~3000 |
| **Lignes documentation** | 2500+ |
| **Tests** | 20+ |
| **Temps installation** | 5 min |
| **Fréquence minimale** | 5 min |

---

## 🏗️ Architecture Orbitale

Ce module s'inscrit dans l'architecture orbitale LexOrbital :

```
                    ┌─────────────────┐
                    │  Meta-Kernel    │
                    │ (lexorbital-core)│
                    └────────┬─────────┘
                             │
              ┌──────────────┼──────────────┐
              │              │              │
         ┌────▼────┐    ┌────▼────┐   ┌────▼────┐
         │ Ring 1  │    │ Ring 2  │   │ Ring 3  │
         │   UI    │    │  Infra  │   │   App   │
         └─────────┘    └────┬────┘   └─────────┘
                             │
                    ┌────────┴────────┐
                    │                 │
            ┌───────▼────────┐ ┌─────▼──────────┐
            │ module-server  │ │ module-server- │
            │                │ │   monitoring   │◄── VOUS ÊTES ICI
            └────────────────┘ └────────────────┘
```

**Position** : Ring 2 - Infrastructure  
**Type** : Module de surveillance autonome  
**Dépendances** : Aucune (standalone)  

---

## 🔍 Modules de Surveillance

### 1. Resources (8 checks)

**Surveillance** :
- CPU (usage, load average)
- RAM (usage, swap)
- Disque (espace, inodes)
- I/O (lecture, écriture)

**Fréquence recommandée** : 5 minutes

### 2. Security (7 checks)

**Surveillance** :
- Tentatives SSH échouées
- Détection brute-force (>10 tentatives/IP)
- Usage sudo et anomalies
- Logins échoués (btmp)
- Connexions inhabituelles (wtmp)

**Fréquence recommandée** : 5 minutes

### 3. Services (9 checks)

**Surveillance** :
- Erreurs critiques (journalctl -p 3)
- Unités systemd en échec
- Services critiques (sshd, docker, nginx)
- Containers Docker (health check)
- Erreurs Nginx

**Fréquence recommandée** : 5 minutes

### 4. Network (5 checks)

**Surveillance** :
- Ports ouverts
- Services non autorisés
- Firewall (UFW/iptables)
- Connexions établies

**Fréquence recommandée** : 1 heure

### 5. Integrity (5 checks)

**Surveillance** :
- Checksums fichiers (SHA256)
- Permissions et ownership
- Modifications récentes
- Fichiers critiques système

**Fréquence recommandée** : Quotidien

---

## 🛠️ Workflow de Surveillance

```
┌──────────────┐
│ Systemd Timer│
│  (déclenche) │
└──────┬───────┘
       │
       ▼
┌──────────────────┐      ┌───────────────┐
│  Orchestrateur   │─────►│ Module 1      │
│                  │      │ (Resources)   │
└──────────────────┘      └───────┬───────┘
       │                          │
       │                          ▼
       │                  ┌───────────────┐
       │                  │ Rapport JSON  │
       │                  └───────┬───────┘
       │                          │
       ▼                          │
┌──────────────────┐              │
│ Modules 2-5      │──────────────┘
│ (en parallèle)   │
└──────┬───────────┘
       │
       ▼
┌──────────────────┐
│ Agrégation       │
│ Rapport Global   │
└──────┬───────────┘
       │
       ├──────►┌──────────────┐
       │       │ Alertes Email│
       │       └──────────────┘
       │
       ├──────►┌──────────────┐
       │       │ API Webhook  │
       │       └──────────────┘
       │
       └──────►┌──────────────┐
               │ Fichier JSON │
               │ /var/lib/... │
               └──────────────┘
```

---

## 🔒 Conformité RGPD

### Principes Appliqués

1. **Privacy by Design** (Article 25)
   - Pseudonymisation par défaut
   - Minimisation des données
   - Sécurité dès la conception

2. **Sécurité du Traitement** (Article 32)
   - Permissions strictes (640/750)
   - Chiffrement recommandé
   - Journalisation sécurisée

3. **Accountability** (Article 30)
   - Registre des traitements
   - Documentation complète
   - Mesures techniques documentées

### Données Traitées

| Donnée | Pseudonymisation | Rétention | Justification |
|--------|------------------|-----------|---------------|
| IPs | ✅ Oui (`192.168.xxx.xxx`) | 7 jours | Détection brute-force |
| Usernames | ✅ Oui (hash) | 7 jours | Audit sudo |
| Métriques système | ❌ Non | 30 jours | Monitoring ressources |
| Checksums | ❌ Non | Permanent | Intégrité fichiers |

---

## 🚀 Cas d'Usage

### 1. Startup Tech

**Besoin** : Surveillance serveur production sans budget monitoring externe  
**Solution** : Installation complète en 5 minutes, gratuit, open-source  
**Bénéfice** : Détection proactive incidents, conformité RGPD  

### 2. PME avec Contraintes RGPD

**Besoin** : Monitoring conforme CNIL  
**Solution** : Pseudonymisation automatique, documentation RGPD  
**Bénéfice** : Conformité légale garantie, audit trail  

### 3. DevOps Team

**Besoin** : Visibilité complète infrastructure  
**Solution** : 34 checks, rapports JSON, alertes automatiques  
**Bénéfice** : Réduction MTTR, automatisation  

---

## 📈 Roadmap

### Version 1.0.0 (Actuelle)

✅ 5 modules de surveillance  
✅ 34 checks système  
✅ Rapports JSON structurés  
✅ Automatisation systemd  
✅ Conformité RGPD  
✅ Documentation complète  

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

## 🤝 Contribution

### Comment Contribuer

1. **Fork** le repository
2. **Créer** une branche feature
3. **Implémenter** avec tests
4. **Documenter** les changements
5. **Soumettre** une PR

### Guidelines

- Respecter l'architecture modulaire
- Ajouter des tests (couverture >80%)
- Documenter en français
- Suivre conventions de code (shellcheck)
- Maintenir conformité RGPD

---

## 📞 Contact

- **Maintainer** : [YohanGH](https://github.com/YohanGH)
- **Issues** : [GitHub Issues](https://github.com/YohanGH/lexorbital-module-server-monitoring/issues)
- **Security** : Voir [SECURITY.md](../../SECURITY.md)

---

**Version** : 1.0.0  
**Date** : 2025-12-02  
**Statut** : ✅ Production Ready

