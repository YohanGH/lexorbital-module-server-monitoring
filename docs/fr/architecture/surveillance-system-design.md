# Architecture - Système de Surveillance

> **Design document** pour le système de surveillance multi-couches de LexOrbital Module Server.

---

## 🎯 Vision

Créer un système de surveillance **autonome, modulaire et respectueux du RGPD** capable de détecter les anomalies systèmes et de sécurité, et de les reporter sous forme structurée (JSON) vers la console orbitale.

---

## 🏛️ Principes Architecturaux

### 1. Séparation des Responsabilités

```
┌─────────────────────────────────────────────────────┐
│              Console Orbitale (Frontend)            │
│              Vue Surveillance / Healthcheck         │
└─────────────────────┬───────────────────────────────┘
                      │ JSON via API
                      ▼
┌─────────────────────────────────────────────────────┐
│           Orchestrateur de Surveillance             │
│         (surveillance-orchestrator.sh)              │
│                                                     │
│  - Agrège les rapports                              │
│  - Génère le JSON final                             │
│  - Gère les alertes                                 │
└──────────┬──────────────────────────────────────────┘
           │ appelle
           ▼
┌─────────────────────────────────────────────────────┐
│              Modules de Surveillance                │
│                                                     │
│  ┌──────────────────┐  ┌──────────────────┐       │
│  │   Ressources     │  │    Sécurité      │       │
│  │  (CPU, RAM, I/O) │  │  (auth, sudo)    │       │
│  └──────────────────┘  └──────────────────┘       │
│                                                     │
│  ┌──────────────────┐  ┌──────────────────┐       │
│  │    Services      │  │     Réseau       │       │
│  │  (journalctl)    │  │  (ports, nmap)   │       │
│  └──────────────────┘  └──────────────────┘       │
│                                                     │
│  ┌──────────────────┐                              │
│  │   Intégrité      │                              │
│  │  (checksums)     │                              │
│  └──────────────────┘                              │
└─────────────────────────────────────────────────────┘
           │ génère
           ▼
┌─────────────────────────────────────────────────────┐
│              Rapports JSON Modulaires               │
│  - resources.json                                   │
│  - security.json                                    │
│  - services.json                                    │
│  - network.json                                     │
│  - integrity.json                                   │
└─────────────────────────────────────────────────────┘
```

### 2. Interfaces & Contrats

Chaque module de surveillance doit respecter le **contrat JSON suivant** :

```typescript
interface SurveillanceReport {
  metadata: ReportMetadata;
  status: HealthStatus;
  checks: Check[];
  metrics?: Record<string, Metric>;
  alerts?: Alert[];
}

interface ReportMetadata {
  module: string;           // "resources" | "security" | "services" | "network" | "integrity"
  version: string;          // "1.0.0"
  timestamp: string;        // ISO 8601
  hostname: string;
  executionTime: number;    // milliseconds
}

type HealthStatus = "healthy" | "warning" | "critical" | "unknown";

interface Check {
  id: string;
  name: string;
  status: HealthStatus;
  message: string;
  value?: number | string | boolean;
  threshold?: {
    warning: number;
    critical: number;
  };
  tags?: string[];
}

interface Metric {
  value: number;
  unit: string;
  timestamp: string;
}

interface Alert {
  severity: "info" | "warning" | "critical";
  source: string;
  message: string;
  timestamp: string;
  data?: Record<string, unknown>;
}
```

### 3. Modules de Surveillance

#### 3.1 Module Ressources (`surveillance-resources.sh`)

**Responsabilité** : Surveiller CPU, RAM, disque, I/O.

**Checks** :
- `cpu.usage`: Utilisation CPU (%)
- `cpu.load`: Load average (1, 5, 15 min)
- `memory.used`: RAM utilisée (%)
- `memory.swap`: Swap utilisé (%)
- `disk.root.usage`: Espace disque / (%)
- `disk.var.usage`: Espace disque /var (%)
- `disk.inodes`: Inodes disponibles (%)
- `io.read`: I/O lecture
- `io.write`: I/O écriture

**Seuils** :
- Warning: 70%
- Critical: 85%

**Output** : `/var/lib/lexorbital/surveillance/reports/resources.json`

---

#### 3.2 Module Sécurité (`surveillance-security.sh`)

**Responsabilité** : Détecter tentatives d'intrusion, brute-force, sudo suspect.

**Checks** :
- `ssh.failed_logins`: Tentatives SSH échouées (dernières 24h)
- `ssh.brute_force`: Détection brute-force (>10 échecs/IP)
- `sudo.usage`: Commandes sudo récentes
- `sudo.anomalies`: Sudo depuis utilisateurs non autorisés
- `btmp.entries`: Entrées btmp (logins échoués)
- `wtmp.anomalies`: Connexions inhabituelles

**Seuils** :
- Warning: >5 tentatives échouées / IP
- Critical: >10 tentatives échouées / IP

**RGPD** :
- ⚠️ Ne PAS stocker les IPs complètes → pseudonymisation
- Format: `192.168.xxx.xxx` ou hash SHA256 tronqué
- Rétention: 7 jours maximum

**Output** : `/var/lib/lexorbital/surveillance/reports/security.json`

---

#### 3.3 Module Services (`surveillance-services.sh`)

**Responsabilité** : Détecter erreurs critiques, crashs, services down.

**Checks** :
- `journal.errors`: Erreurs critiques (journalctl -p 3)
- `journal.failed_units`: Unités systemd en échec
- `docker.containers`: Status containers Docker
- `docker.health`: Health checks Docker
- `nginx.status`: Status Nginx
- `nginx.errors`: Erreurs Nginx

**Output** : `/var/lib/lexorbital/surveillance/reports/services.json`

---

#### 3.4 Module Réseau (`surveillance-network.sh`)

**Responsabilité** : Auditer ports ouverts, connexions suspectes.

**Checks** :
- `ports.open`: Ports ouverts (ss -tuln)
- `ports.unexpected`: Ports non autorisés
- `connections.established`: Connexions établies
- `connections.suspicious`: Connexions vers IPs suspectes
- `firewall.status`: Status UFW/iptables

**RGPD** :
- ⚠️ Ne PAS logger les IPs externes complètes

**Output** : `/var/lib/lexorbital/surveillance/reports/network.json`

---

#### 3.5 Module Intégrité (`surveillance-integrity.sh`)

**Responsabilité** : Vérifier l'intégrité des fichiers critiques.

**Checks** :
- `files.checksums`: Checksums des fichiers sensibles
- `files.modified`: Fichiers modifiés depuis dernier check
- `files.permissions`: Permissions incorrectes
- `files.ownership`: Ownership incorrecte

**Fichiers surveillés** :
- `/etc/passwd`, `/etc/shadow`, `/etc/group`
- `/etc/ssh/sshd_config`
- `/etc/nginx/nginx.conf`
- Scripts de surveillance eux-mêmes

**Output** : `/var/lib/lexorbital/surveillance/reports/integrity.json`

---

### 4. Orchestrateur (`surveillance-orchestrator.sh`)

**Responsabilité** : Coordonner l'exécution de tous les modules et générer le rapport global.

**Workflow** :
1. Exécuter tous les modules en parallèle (via `&` et `wait`)
2. Collecter les rapports JSON individuels
3. Agréger dans un rapport global
4. Calculer le status global (worst-case)
5. Générer les alertes si nécessaire
6. Envoyer le rapport à la console orbitale (API POST)
7. Optionnel: envoyer email si alertes critiques

**Output** : `/var/lib/lexorbital/surveillance/reports/global.json`

**Structure du rapport global** :

```typescript
interface GlobalSurveillanceReport {
  metadata: {
    version: string;
    timestamp: string;
    hostname: string;
    totalExecutionTime: number;
  };
  globalStatus: HealthStatus;
  modules: {
    resources: SurveillanceReport;
    security: SurveillanceReport;
    services: SurveillanceReport;
    network: SurveillanceReport;
    integrity: SurveillanceReport;
  };
  summary: {
    totalChecks: number;
    healthyChecks: number;
    warningChecks: number;
    criticalChecks: number;
  };
  alerts: Alert[];
}
```

---

## 🛠️ Stack Technique

### Langages & Outils
- **Shell** : Bash 4.0+ (portabilité Debian/Ubuntu)
- **JSON** : `jq` (manipulation JSON)
- **Systemd** : timers pour automatisation
- **Outils système** : `ss`, `journalctl`, `df`, `free`, `iostat`, `docker`, `sha256sum`

### Dépendances
```bash
# Paquets requis
apt-get install -y \
  jq \
  sysstat \
  net-tools \
  coreutils \
  util-linux
```

---

## ⚙️ Automatisation

### Systemd Timers

**Timer 1 : Surveillance rapide (5 min)**
```ini
# /etc/systemd/system/lexorbital-surveillance-fast.timer
[Unit]
Description=LexOrbital Fast Surveillance (CPU, RAM, Services)

[Timer]
OnBootSec=5min
OnUnitActiveSec=5min

[Install]
WantedBy=timers.target
```

**Timer 2 : Surveillance complète (1h)**
```ini
# /etc/systemd/system/lexorbital-surveillance-full.timer
[Unit]
Description=LexOrbital Full Surveillance (All Modules)

[Timer]
OnBootSec=10min
OnUnitActiveSec=1h

[Install]
WantedBy=timers.target
```

**Timer 3 : Intégrité fichiers (1x/jour)**
```ini
# /etc/systemd/system/lexorbital-surveillance-integrity.timer
[Unit]
Description=LexOrbital File Integrity Check

[Timer]
OnCalendar=daily
OnBootSec=15min

[Install]
WantedBy=timers.target
```

---

## 🔒 Sécurité & RGPD

### Principes de Sécurité
1. **Least Privilege** : Scripts s'exécutent avec utilisateur dédié (non-root si possible)
2. **Permissions strictes** : 
   - Scripts: `750` (rwxr-x---)
   - Rapports: `640` (rw-r-----)
   - Logs: `640`
3. **Validation des inputs** : Tous les paramètres sont validés
4. **Pas d'exécution de code externe** : Aucun `eval`, aucun téléchargement
5. **Logs structurés** : Journalisation systématique

### Conformité RGPD

#### Données Personnelles Identifiées
- **IPs** : Données personnelles selon CNIL
- **Usernames** : Données personnelles si nominatifs

#### Mesures de Protection (Article 32)
1. **Pseudonymisation des IPs** :
   ```bash
   # Exemple
   192.168.1.42 → 192.168.xxx.xxx
   # OU
   sha256sum <<< "192.168.1.42" | cut -c1-16  # hash tronqué
   ```

2. **Rétention limitée** :
   - Rapports JSON: 30 jours
   - Logs surveillance: 7 jours
   - Alertes critiques: 90 jours (justification sécurité)

3. **Minimisation** :
   - Ne collecter QUE les données nécessaires à la détection
   - Pas de logs verbeux inutiles
   - Pas de contenu de fichiers, uniquement métadonnées

4. **Sécurisation** :
   - Rapports stockés dans `/var/lib/lexorbital/surveillance/reports/`
   - Permissions: lecture limitée à `lexorbital` et `root`
   - Chiffrement au repos recommandé (LUKS)

5. **Documentation** :
   - Registre des traitements (Article 30)
   - Analyse d'Impact (DPIA) si données sensibles

#### Déclaration RGPD Manifest
Ajouter dans `/manifests/rgpd-manifest.json` :

```json
{
  "processing": {
    "surveillance": {
      "purpose": "Détection d'anomalies et sécurisation du système",
      "legal_basis": "Legitimate interest (Article 6.1.f)",
      "data_categories": ["IP addresses (pseudonymized)", "System logs", "Authentication attempts"],
      "retention": "7-30 days depending on criticality",
      "technical_measures": ["Pseudonymization", "Access control", "Encryption at rest"],
      "recipients": ["System administrators", "Security team"]
    }
  }
}
```

---

## 📊 Intégration Console Orbitale

### API Endpoint (à créer dans lexorbital-core)

**POST** `/api/surveillance/report`

**Headers** :
```
Content-Type: application/json
Authorization: Bearer <token>
```

**Body** : `GlobalSurveillanceReport` (voir ci-dessus)

**Réponse** :
```json
{
  "status": "received",
  "reportId": "uuid",
  "timestamp": "2025-12-02T10:30:00Z"
}
```

### Vue Dashboard

**Composants à créer dans lexorbital-core/frontend** :
1. `SurveillanceDashboard.tsx` : Vue d'ensemble
2. `HealthStatusCard.tsx` : Statut par module
3. `AlertsTimeline.tsx` : Timeline des alertes
4. `MetricsChart.tsx` : Graphiques de métriques
5. `CheckDetails.tsx` : Détails d'un check

---

## 🧪 Stratégie de Tests

### 1. Tests Unitaires (Bash + bats)

```bash
# tests/surveillance-resources.bats
@test "CPU usage check returns valid JSON" {
  run ./monitoring/surveillance-resources.sh --check cpu
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.status' > /dev/null
}

@test "CPU usage respects thresholds" {
  # Mock CPU at 90%
  export MOCK_CPU_USAGE=90
  run ./monitoring/surveillance-resources.sh --check cpu
  result=$(echo "$output" | jq -r '.checks[] | select(.id=="cpu.usage") | .status')
  [ "$result" = "critical" ]
}
```

### 2. Tests d'Intégration

```bash
# tests/integration/test-orchestrator.sh
#!/usr/bin/env bash

# Test complet de l'orchestrateur
./monitoring/surveillance-orchestrator.sh

# Vérifier que tous les rapports sont générés
[ -f /var/lib/lexorbital/surveillance/reports/global.json ]
[ -f /var/lib/lexorbital/surveillance/reports/resources.json ]

# Vérifier structure JSON
jq -e '.globalStatus' /var/lib/lexorbital/surveillance/reports/global.json
```

### 3. Tests de Sécurité

- Vérifier que les IPs sont pseudonymisées
- Vérifier les permissions des fichiers générés
- Tester l'isolation (pas d'accès root non nécessaire)
- Tester la résistance aux injections

---

## 📝 Documentation à Créer

1. **Architecture** : `docs/fr/architecture/surveillance-system-design.md` ✅ (ce fichier)
2. **Opérations** : `docs/fr/operations/surveillance-guide.md`
3. **Référence** : `docs/fr/reference/surveillance-api.md`
4. **Sécurité** : `docs/fr/security/surveillance-security.md`
5. **Compliance** : `docs/fr/compliance/surveillance-gdpr.md`
6. **HowTo** : `docs/fr/howto/configure-surveillance.md`

---

## ⚠️ Risques & Mitigations

| Risque | Impact | Probabilité | Mitigation |
|--------|--------|-------------|-----------|
| Surcharge CPU | Moyen | Moyenne | Limiter fréquence, optimiser scripts |
| Faux positifs | Élevé | Élevée | Tuner seuils, tests réels |
| Non-conformité RGPD | Critique | Faible | Revue juridique, pseudonymisation |
| Dépendances manquantes | Faible | Moyenne | Vérifier prérequis, Ansible |
| Permissions insuffisantes | Moyen | Moyenne | Documentation, principe least privilege |

---

## 🔗 Liens Connexes

- [Design Console Orbitale](../../lexorbital-core/docs/architecture/)
- [RGPD by Design](./compliance/overview.md)
- [Monitoring actuel](../operations/monitoring.md)
- [Audit Permissions](../../scripts/audit-permissions.sh)

---

**Version** : 1.0.0  
**Date** : 2025-12-02  
**Statut** : ✅ Approuvé pour implémentation  
**Auteur** : Architect Admin6

