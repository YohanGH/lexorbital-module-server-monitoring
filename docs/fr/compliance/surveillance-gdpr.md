# Conformité RGPD - Système de Surveillance

> **Documentation de conformité** pour le système de surveillance LexOrbital selon le RGPD.

---

## 🎯 Objectif

Ce document détaille les mesures techniques et organisationnelles mises en œuvre pour assurer la conformité RGPD du système de surveillance, conformément aux articles 25 (Privacy by Design) et 32 (Sécurité du traitement) du RGPD.

---

## 📋 Cadre Juridique

### Base Légale du Traitement

Le traitement des données par le système de surveillance repose sur :

**Article 6.1.f du RGPD** : Intérêt légitime
- **Finalité** : Détection des anomalies système et des incidents de sécurité
- **Intérêt** : Protection des systèmes d'information et des données
- **Balance** : Mesures de minimisation et pseudonymisation pour limiter l'impact sur les droits des personnes

**Article 9.2.j du RGPD** (si applicable) : Archivage dans l'intérêt public
- Pour les logs de sécurité nécessaires à la preuve en cas d'incident

---

## 🔒 Données Personnelles Traitées

### Catégories de Données

| Donnée | Catégorie | Traitement | Pseudonymisation |
|--------|-----------|------------|------------------|
| Adresses IP | Identifiant réseau | Détection brute-force | ✅ Oui (xxx.xxx) |
| Noms d'utilisateurs | Identité | Audit sudo | ✅ Oui (hash partiel) |
| Logs d'authentification | Connexion | Analyse tentatives | ⚠️ Partiel |
| Horodatages | Temporel | Corrélation | ❌ Non (nécessaire) |

### Pseudonymisation des IPs

**Méthode appliquée** :
```
192.168.1.42 → 192.168.xxx.xxx
```

**Code d'implémentation** :
```bash
# Voir lib/surveillance-common.sh
pseudonymize_ip() {
  echo "$ip" | sed -E 's/([0-9]+\.[0-9]+)\.[0-9]+\.[0-9]+/\1.xxx.xxx/'
}
```

**Justification** : Conservation des deux premiers octets pour analyse réseau tout en préservant l'anonymat.

### Pseudonymisation des Usernames

**Méthode appliquée** :
```
admin → ad***f8a3b2c1
```

**Justification** : Hash SHA256 tronqué permettant la détection de récurrence sans identification directe.

---

## 🕒 Rétention des Données

### Durées de Conservation

| Type de Donnée | Durée | Justification |
|----------------|-------|---------------|
| Rapports JSON surveillance | 30 jours | Analyse tendances |
| Logs surveillance | 7 jours | Débogage système |
| Alertes critiques | 90 jours | Investigation incidents |
| Checksums intégrité | Permanent | Détection modifications |

### Mise en Œuvre

```bash
# Script de purge automatique (exemple)
find /var/lib/lexorbital/surveillance/reports/ \
  -name "*.json" -mtime +30 -delete

find /var/log/lexorbital/ \
  -name "surveillance.log*" -mtime +7 -delete
```

**Recommandation** : Mettre en place un cron job quotidien pour la purge.

---

## 🛡️ Mesures de Sécurité (Article 32)

### 1. Contrôle d'Accès

```bash
# Permissions strictes
chmod 750 /var/lib/lexorbital/surveillance/
chmod 640 /var/lib/lexorbital/surveillance/reports/*.json
chmod 640 /var/log/lexorbital/surveillance.log

# Propriété
chown root:root /var/lib/lexorbital/surveillance/
```

**Principe** : Seuls root et le groupe lexorbital peuvent accéder aux données.

### 2. Chiffrement au Repos

**Recommandation** : Utiliser LUKS pour chiffrer `/var/lib/lexorbital/surveillance/`

```bash
# Exemple de configuration LUKS (non inclus par défaut)
cryptsetup luksFormat /dev/sdX
cryptsetup open /dev/sdX surveillance_encrypted
mkfs.ext4 /dev/mapper/surveillance_encrypted
```

### 3. Chiffrement en Transit

**Pour l'API Console Orbitale** :
- HTTPS obligatoire (TLS 1.2+)
- Authentification par token Bearer
- Validation certificat SSL

```bash
# Configuration dans surveillance.conf
API_ENDPOINT="https://console.example.com/api/surveillance/report"
API_TOKEN="secure-token-here"
```

### 4. Journalisation Sécurisée

```bash
# Logs systemd chiffrés (optionnel)
journalctl --rotate
journalctl --vacuum-time=7d
```

### 5. Minimisation des Données

Le système collecte **uniquement** les données nécessaires :

❌ **Non collecté** :
- Contenu des fichiers utilisateurs
- Historique complet des commandes
- Données applicatives

✅ **Collecté** :
- Métriques système (CPU, RAM, disque)
- Métadonnées de sécurité (tentatives d'accès)
- Statut des services

---

## 📊 Registre des Traitements (Article 30)

### Fiche de Traitement

**Nom du traitement** : Surveillance Infrastructure LexOrbital

**Responsable du traitement** : [Votre Organisation]

**Finalité** :
- Détection d'anomalies système
- Prévention des incidents de sécurité
- Maintien de la disponibilité des services

**Base légale** : Article 6.1.f (intérêt légitime)

**Catégories de personnes concernées** :
- Administrateurs système
- Utilisateurs du serveur
- Visiteurs (logs réseau)

**Catégories de données** :
- Identifiants réseau (IPs pseudonymisées)
- Logs d'authentification
- Métriques système

**Destinataires** :
- Équipe DevOps/SysAdmin
- Équipe Sécurité (en cas d'incident)

**Transferts hors UE** : Non

**Durée de conservation** : 7 à 90 jours selon type

**Mesures de sécurité** :
- Pseudonymisation
- Contrôle d'accès strict
- Chiffrement (recommandé)
- Purge automatique

---

## 🔍 Analyse d'Impact (DPIA)

### Évaluation du Risque

| Risque | Probabilité | Impact | Mesure d'Atténuation |
|--------|-------------|--------|----------------------|
| Accès non autorisé aux rapports | Faible | Moyen | Permissions 640, SELinux |
| Collecte excessive de données | Faible | Élevé | Minimisation, config par défaut stricte |
| Identification d'individus | Très faible | Élevé | Pseudonymisation IPs/usernames |
| Rétention excessive | Faible | Moyen | Purge automatique 30j |

### Nécessité d'une DPIA Formelle

**Selon article 35 du RGPD**, une DPIA formelle est requise si :
- Surveillance systématique à grande échelle ❌ (non, serveur unique)
- Traitement de données sensibles ❌ (non, métriques système)
- Profilage ❌ (non)

**Conclusion** : DPIA formelle non obligatoire mais recommandée pour les déploiements multi-serveurs ou données RH.

---

## 👥 Droits des Personnes Concernées

### Droit d'Accès (Article 15)

Les administrateurs peuvent consulter leurs propres données :

```bash
# Extraire les logs concernant un utilisateur spécifique
grep "username" /var/log/lexorbital/surveillance.log
```

**Note** : Pseudonymisation rend l'identification difficile → respecte la minimisation.

### Droit à l'Effacement (Article 17)

Suppression des données d'un utilisateur :

```bash
# Supprimer logs concernant une IP spécifique
sed -i '/192.168.1.42/d' /var/log/lexorbital/surveillance.log

# Purger tous les rapports
rm -f /var/lib/lexorbital/surveillance/reports/*.json
```

### Droit d'Opposition (Article 21)

Un administrateur peut demander l'exclusion de la surveillance.

**Procédure** :
1. Désactiver la surveillance des actions de l'utilisateur spécifique
2. Documenter la demande
3. Purger les données existantes

---

## 📝 Documentation et Traçabilité

### Logs d'Audit

Le système génère des logs d'audit pour :

- Initialisation des checksums (intégrité)
- Exécution des modules
- Génération des alertes critiques
- Accès aux rapports (via systemd journal)

```bash
# Consulter l'audit
sudo journalctl -u lexorbital-surveillance-full.service
```

### Notification des Violations (Article 33)

En cas de violation de données (ex : accès non autorisé aux rapports) :

1. **Détecter** : Vérifier logs d'accès
2. **Documenter** : Circonstances, données concernées
3. **Notifier** : CNIL sous 72h si risque pour droits des personnes
4. **Corriger** : Renforcer sécurité

**Contact CNIL** : https://www.cnil.fr/

---

## ✅ Checklist de Conformité

### Mise en Œuvre Technique

- [x] Pseudonymisation des IPs activée par défaut
- [x] Rétention limitée (30 jours)
- [x] Permissions strictes (640/750)
- [x] Minimisation des données
- [x] Purge automatique configurée
- [ ] Chiffrement au repos (optionnel mais recommandé)
- [ ] TLS pour API Console Orbitale

### Documentation

- [x] Registre des traitements (ce document)
- [x] Finalités documentées
- [x] Mesures de sécurité documentées
- [ ] DPIA (si nécessaire)
- [ ] Politique de conservation

### Organisationnel

- [ ] Formation de l'équipe DevOps
- [ ] Procédure de violation de données
- [ ] Point de contact DPO
- [ ] Révision annuelle de la conformité

---

## 🔗 Références

- [RGPD - Texte officiel](https://eur-lex.europa.eu/legal-content/FR/TXT/?uri=CELEX:32016R0679)
- [CNIL - Guide de la sécurité](https://www.cnil.fr/fr/la-securite-des-donnees)
- [ANSSI - Guide d'hygiène informatique](https://www.ssi.gouv.fr/guide/guide-dhygiene-informatique/)

---

## 📞 Contact

**DPO (Data Protection Officer)** : [dpo@example.com]  
**Responsable Sécurité** : [security@example.com]

---

**Version** : 1.0.0
**Dernière mise à jour** : 2025-12-02
**Validé par** : [DPO / RSSI] @YohanGH
**Prochaine révision** : 2026-12-02
