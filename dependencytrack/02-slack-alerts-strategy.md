# Stratégie d'alertes DependencyTrack via Slack

## Aperçu

Intégration Slack directe avec DependencyTrack pour notifier en temps réel les vulnérabilités détectées. Basée sur la sévérité CVSS avec escalade progressive et mentions intelligentes.

---

## Architecture des alertes

```
┌────────────────────────────────────────────────────┐
│ DependencyTrack détecte vuln dans scan SBOM        │
├────────────────────────────────────────────────────┤
│                                                    │
│  CVSS >= 9.0 (CRITICAL)                           │
│  ├─ Alerte immédiate                              │
│  ├─ Mention @security-team                        │
│  └─ Mentions @on-call                             │
│                                                    │
│  CVSS 7.0 - 8.9 (HIGH)                            │
│  ├─ Alerte priorité moyenne                       │
│  ├─ Mention @security-team                        │
│  └─ Escalade à 4h si non-résolue                  │
│                                                    │
│  CVSS 4.0 - 6.9 (MEDIUM)                          │
│  ├─ Rapport quotidien consolidé (02h00)           │
│  └─ Avis sans mention spécifique                  │
│                                                    │
│  CVSS < 4.0 (LOW)                                 │
│  ├─ Rapport hebdomadaire (lundi 09h00)            │
│  └─ Digest par projet                             │
│                                                    │
└────────────────────────────────────────────────────┘
```

---

## Configuration Slack

### Étape 1 : Créer les Webhooks

**Pour les alertes CRITICAL/HIGH :**

1. Accéder à https://api.slack.com/apps → Create New App
2. Créer "DependencyTrack Alerts"
3. **Incoming Webhooks** → Ajouter New Webhook to Workspace
4. Sélectionner canal `#security-alerts`
5. Copier URL Webhook → Stocker dans Vault :
   ```bash
   vault kv put secret/dependencytrack/slack \
     webhook_critical_high='https://hooks.slack.com/services/...'
   ```

**Pour les rapports (MEDIUM/LOW) :**

1. Répéter pour `#security-reports`
2. Stocker dans Vault :
   ```bash
   vault kv put secret/dependencytrack/slack \
     webhook_medium_low='https://hooks.slack.com/services/...'
   ```

### Étape 2 : Configurer les User Groups

```bash
# Dans Slack : Admin → User Groups
# Créer les groupes :
# - @security-team (tous les membres sécurité)
# - @on-call (rotation d'astreinte)
# - @app-owners (propriétaires des projets)

# ID des groupes (nécessaires pour mentions) :
SECURITY_TEAM_ID="S02ABC123XYZ"
ON_CALL_ID="S03DEF456UVW"
```

---

## Payloads Slack (Templates Freemarker)

### ⚠️ IMPORTANT: Syntaxe Freemarker vs JSON

DependencyTrack utilise **Freemarker** (pas JSON simple) pour les templates. La syntaxe est:
```
{{ variable }}                    ← Freemarker (pas ${variable})
{% if condition %} ... {% endif %} ← Conditions Freemarker
```

### Comment DependencyTrack filtre par sévérité?

**PAS dans le template, mais dans les ALERTS!**

Flux correct:
1. **Alert CRITICAL** (Administration → Alerts)
   - Condition: `CVSS >= 9.0` ← Filtre par sévérité
   - Template: "Slack CRITICAL" ← Détermine l'apparence
   - Publisher: Slack

2. **Alert HIGH** (Administration → Alerts)
   - Condition: `CVSS 7.0-8.9` ← Filtre par sévérité
   - Template: "Slack HIGH" ← Détermine l'apparence
   - Publisher: Slack

**Le template ne sait PAS qu'il est CRITICAL ou HIGH — c'est l'Alert qui décide!**

### Variables Freemarker disponibles

```
{{ notification.group }}              — Type d'événement (NEW_VULNERABILITY, etc.)
{{ notification.level }}              — Niveau (INFO, WARNING, ERROR, etc.)
{{ notification.scope }}              — Scope (SYSTEM, PORTFOLIO, PROJECT, etc.)
{{ notification.title }}              — Titre de la notification
{{ notification.content }}            — Contenu complet

{{ subject.vulnerability.vulnId }}    — ID du CVE (CVE-2024-12345)
{{ subject.vulnerability.severity }}  — Sévérité (CRITICAL, HIGH, MEDIUM, LOW)
{{ subject.vulnerability.source }}    — Source (NVD, GitHub, etc.)

{{ subject.component.toString }}      — Nom + version du composant
{{ subject.component.uuid }}          — UUID du composant

{{ subject.project.toString }}        — Nom + version du projet
{{ subject.project.uuid }}            — UUID du projet

{{ baseUrl }}                          — URL de base DependencyTrack
```

**Exemple:**
- Template: `{{ subject.vulnerability.vulnId }}` → Slack: `CVE-2024-12345` ✅
- Template: `CVE-2024-12345` → Slack: `CVE-2024-12345` ❌ (valeur figée)

---

### Adapter les templates JSON fournis (syntaxe Freemarker)

Les templates JSON fournis ci-dessous doivent être enrobés dans une condition Freemarker `NEW_VULNERABILITY`. Voici le pattern:

```freemarker
{% if notification.group == "NEW_VULNERABILITY" %}
{
  "blocks": [
    // Votre JSON ici, avec variables Freemarker
    {
      "type": "section",
      "fields": [
        {
          "type": "mrkdwn",
          "text": "*CVE:*\n{{ subject.vulnerability.vulnId | escape(strategy='json') }}"
        },
        {
          "type": "mrkdwn",
          "text": "*Severity:*\n{{ subject.vulnerability.severity | escape(strategy='json') }}"
        }
      ]
    }
  ]
}
{% endif %}
```

**Remplacements clés:**
- `${vulnerability.cveId}` → `{{ subject.vulnerability.vulnId }}`
- `${vulnerability.cvssV3Score}` → Utiliser `{{ subject.vulnerability.severity }}` (pas de CVSS dans le template)
- `${project.name}` → `{{ subject.project.toString }}`
- `${component.name} ${component.version}` → `{{ subject.component.toString }}`

⚠️ **Note:** Le score CVSS n'est pas disponible dans les variables du template! C'est pourquoi les filtres de sévérité doivent être définis dans les **Alerts**, pas dans le template.

📖 **Référence complète:** Voir [DependencyTrack Notification Template Docs](https://docs.dependencytrack.org/integrations/notifications.html#template-variables)

### Pourquoi la version du projet est importante?

Chaque projet peut avoir plusieurs versions (branches):

| Projet | Version | Vulnérabilités | État |
|--------|---------|-----------------|------|
| **app** | master | 2 CRITICAL | Production actuelle |
| **app** | develop | 4 CRITICAL | En dev, peut être fixé |
| **app** | preprod | 3 CRITICAL | Staging avant prod |

**Sans la version:** "❌ CRITICAL found in app" → Ambiguïté (quelle branche?)

**Avec la version:** "❌ CRITICAL found in app [master]" → Clair (version production!)

Cela permet:
- ✅ Identifier exactement la branche affectée
- ✅ Prioriser (master > preprod > develop)
- ✅ Trier les actions (production immédiate, develop peut attendre)

---

### 1. Template CRITICAL (Freemarker)

**Déclenche immédiatement — sans délai**

**Condition d'Alert associée:** `CVSS >= 9.0`

```freemarker
{% if notification.group == "NEW_VULNERABILITY" %}
{
  "channel": "#devsecops_notif",
  "username": "DependencyTrack Alert",
  "icon_emoji": ":rotating_light:",
  "text": "🚨 CRITICAL Vulnerability Detected",
  "blocks": [
    {
      "type": "section",
      "text": {
        "type": "mrkdwn",
        "text": "*🚨 CRITICAL VULNERABILITY DETECTED*\n<!subteam^S02ABC123XYZ> <!subteam^S03DEF456UVW>"
      }
    },
    {
      "type": "divider"
    },
    {
      "type": "section",
      "fields": [
        {
          "type": "mrkdwn",
          "text": "*CVE:*"
        },
        {
          "type": "plain_text",
          "text": "{{ subject.vulnerability.vulnId | escape(strategy='json') }}"
        },
        {
          "type": "mrkdwn",
          "text": "*Severity:*"
        },
        {
          "type": "plain_text",
          "text": "{{ subject.vulnerability.severity | escape(strategy='json') }}"
        },
        {
          "type": "mrkdwn",
          "text": "*Project:*"
        },
        {
          "type": "plain_text",
          "text": "{{ subject.project.toString | escape(strategy='json') }}"
        },
        {
          "type": "mrkdwn",
          "text": "*Component:*"
        },
        {
          "type": "plain_text",
          "text": "{{ subject.component.toString | escape(strategy='json') }}"
        }
      ]
    },
    {
      "type": "actions",
      "elements": [
        {
          "type": "button",
          "text": {
            "type": "plain_text",
            "text": "View in DependencyTrack"
          },
          "url": "{{ baseUrl }}/projects/{{ subject.project.uuid | escape(strategy='json') }}/findings"
        },
        {
          "type": "button",
          "text": {
            "type": "plain_text",
            "text": "View CVE"
          },
          "url": "https://nvd.nist.gov/vuln/detail/{{ subject.vulnerability.vulnId | escape(strategy='json') }}"
        }
      ]
    }
  ]
}
{% endif %}
```

**Variables Freemarker utilisées:**
- `{{ subject.vulnerability.vulnId }}` — ID du CVE
- `{{ subject.vulnerability.severity }}` — Sévérité (CRITICAL = détecté par l'Alert)
- `{{ subject.project.toString }}` — Nom + version du projet
- `{{ subject.component.toString }}` — Nom + version du composant
- `{{ baseUrl }}` — URL DependencyTrack

### 2. Template HIGH (Freemarker)

**Alerte standard — sans mention channel**

**Condition d'Alert associée:** `CVSS 7.0-8.9`

```freemarker
{% if notification.group == "NEW_VULNERABILITY" %}
{
  "channel": "#devsecops_notif",
  "username": "DependencyTrack Alert",
  "icon_emoji": ":warning:",
  "text": "⚠️ HIGH Vulnerability Detected",
  "blocks": [
    {
      "type": "section",
      "text": {
        "type": "mrkdwn",
        "text": "*⚠️ HIGH VULNERABILITY DETECTED*\n_Requires action within 4 hours_"
      }
    },
    {
      "type": "divider"
    },
    {
      "type": "section",
      "fields": [
        {
          "type": "mrkdwn",
          "text": "*CVE:*"
        },
        {
          "type": "plain_text",
          "text": "{{ subject.vulnerability.vulnId | escape(strategy='json') }}"
        },
        {
          "type": "mrkdwn",
          "text": "*Severity:*"
        },
        {
          "type": "plain_text",
          "text": "{{ subject.vulnerability.severity | escape(strategy='json') }}"
        },
        {
          "type": "mrkdwn",
          "text": "*Project:*"
        },
        {
          "type": "plain_text",
          "text": "{{ subject.project.toString | escape(strategy='json') }}"
        },
        {
          "type": "mrkdwn",
          "text": "*Component:*"
        },
        {
          "type": "plain_text",
          "text": "{{ subject.component.toString | escape(strategy='json') }}"
        }
      ]
    },
    {
      "type": "actions",
      "elements": [
        {
          "type": "button",
          "text": {
            "type": "plain_text",
            "text": "View in DependencyTrack"
          },
          "url": "{{ baseUrl }}/projects/{{ subject.project.uuid | escape(strategy='json') }}/findings"
        },
        {
          "type": "button",
          "text": {
            "type": "plain_text",
            "text": "View CVE"
          },
          "url": "https://nvd.nist.gov/vuln/detail/{{ subject.vulnerability.vulnId | escape(strategy='json') }}"
        }
      ]
    }
  ]
}
{% endif %}
```

**Variables Freemarker utilisées:**
- `{{ subject.vulnerability.vulnId }}` — ID du CVE
- `{{ subject.vulnerability.severity }}` — Sévérité (HIGH = détecté par l'Alert)
- `{{ subject.project.toString }}` — Nom + version du projet  
- `{{ subject.component.toString }}` — Nom + version du composant

### 3. Rapport quotidien MEDIUM (CVSS 4.0 - 6.9)

**Envoyé quotidiennement à 02h00 — consolide toutes les vulnérabilités MEDIUM du jour précédent**

```json
{
  "channel": "#security-reports",
  "username": "DependencyTrack Daily Report",
  "icon_emoji": ":chart_with_upwards_trend:",
  "text": "📊 Daily Vulnerability Report",
  "blocks": [
    {
      "type": "header",
      "text": {
        "type": "plain_text",
        "text": "📊 Daily Vulnerability Report — 2026-05-27"
      }
    },
    {
      "type": "divider"
    },
    {
      "type": "section",
      "fields": [
        {
          "type": "mrkdwn",
          "text": "*CRITICAL*\n0"
        },
        {
          "type": "mrkdwn",
          "text": "*HIGH*\n1"
        },
        {
          "type": "mrkdwn",
          "text": "*MEDIUM*\n3"
        },
        {
          "type": "mrkdwn",
          "text": "*LOW*\n12"
        }
      ]
    },
    {
      "type": "divider"
    },
    {
      "type": "section",
      "text": {
        "type": "mrkdwn",
        "text": "*New MEDIUM Vulnerabilities (3)*"
      }
    },
    {
      "type": "section",
      "fields": [
        {
          "type": "mrkdwn",
          "text": "*app*\n• CVE-2024-11111 (6.5)\n  Django SQL Injection\n• CVE-2024-22222 (5.9)\n  Insecure deserialization"
        },
        {
          "type": "mrkdwn",
          "text": "*modulesjs*\n• CVE-2024-33333 (6.1)\n  Lodash prototype pollution"
        }
      ]
    },
    {
      "type": "divider"
    },
    {
      "type": "section",
      "text": {
        "type": "mrkdwn",
        "text": "*Summary by Project*\n\n*app:* 4 new vulns (1 HIGH, 2 MEDIUM, 1 LOW)\n*modulesjs:* 8 new vulns (1 MEDIUM, 7 LOW)\n*branch_hardening:* 3 new vulns (all LOW)"
      }
    },
    {
      "type": "actions",
      "elements": [
        {
          "type": "button",
          "text": {
            "type": "plain_text",
            "text": "View Full Report"
          },
          "url": "https://dependencytrack.3d4you.org/dashboard"
        }
      ]
    }
  ]
}
```

### 4. Rapport hebdomadaire LOW (CVSS < 4.0)

**Envoyé le lundi à 09h00 — digest informatif sans actions requises**

```json
{
  "channel": "#security-reports",
  "username": "DependencyTrack Weekly Report",
  "icon_emoji": ":memo:",
  "text": "📋 Weekly LOW Priority Summary",
  "blocks": [
    {
      "type": "header",
      "text": {
        "type": "plain_text",
        "text": "📋 Weekly LOW Priority Summary — Week 22"
      }
    },
    {
      "type": "divider"
    },
    {
      "type": "section",
      "fields": [
        {
          "type": "mrkdwn",
          "text": "*Reporting Period*\n2026-05-20 to 2026-05-26"
        },
        {
          "type": "mrkdwn",
          "text": "*Total LOW Issues*\n47"
        }
      ]
    },
    {
      "type": "divider"
    },
    {
      "type": "section",
      "text": {
        "type": "mrkdwn",
        "text": "*Distribution by Project*\n\n*app:* 18 LOW (mostly info disclosure)\n*modulesjs:* 22 LOW (mostly DoS risks)\n*branch_hardening:* 7 LOW (mostly log injection)"
      }
    },
    {
      "type": "section",
      "text": {
        "type": "mrkdwn",
        "text": "*Most common issues:*\n• Use of hardcoded credentials (12)\n• Missing security headers (11)\n• XXE vulnerabilities (8)\n• SSRF risks (7)"
      }
    },
    {
      "type": "actions",
      "elements": [
        {
          "type": "button",
          "text": {
            "type": "plain_text",
            "text": "View Detailed Report"
          },
          "url": "https://dependencytrack.3d4you.org/dashboard"
        }
      ]
    }
  ]
}
```

---

## Configuration dans DependencyTrack UI

### Étape 1️⃣ : Configurer le Publisher Slack (une seule fois)

**Administration → Notifications → Notification Publishers**

1. Chercher ou créer `Slack`
2. Remplir:
   ```
   Type: Slack
   Webhook URL: https://hooks.slack.com/services/T.../B.../XX... (depuis Slack API)
   ```
3. **Save**

### Étape 2️⃣ : Créer les Templates personnalisés (optionnel)

**Administration → Notifications → Templates**

Si vous voulez personnaliser les messages (ajouter branding, ton, infos custom):

1. Cliquer **+ Create Template**
2. Remplir:
   ```
   Name: "Slack CRITICAL Custom"
   Mime Type: application/json
   ```
3. Coller le JSON de la section "Payloads Slack" ci-dessus
4. Adapter les URLs (remplacer `dependencytrack.3d4you.org` par `dependencytrack.3d4you.org`)
5. **Save**

Sinon, utiliser le template `Slack` par défaut.

### Étape 3️⃣ : Créer les Alerts pour chaque sévérité

⚠️ **IMPORTANT:** Les **Alerts** sont les RÈGLES qui déclenchent les notifications, pas les templates.

**Administration → Notifications → Alerts → Create Alert**

#### Alert 1: CRITICAL (CVSS >= 9.0)

```
Nom: CRITICAL - Immediate Alert (< 1 min)
Type d'alerte: Portfolio vulnerability notification
Condition: CVSS Score >= 9.0
Publisher: Slack
Template: Slack (ou custom si créé)
Niveau de notification: NOTIFY_ADMIN (tous les admins)
Récurrence: À chaque détection (ne pas grouper)
Statut: Enabled ✅
```

**Résultat:** Alerte instantanée sur #devsecops_notif

---

#### Alert 2: HIGH (CVSS 7.0 - 8.9)

```
Nom: HIGH - Alert with 4h Review Window
Type d'alerte: Portfolio vulnerability notification
Condition: CVSS Score >= 7.0 AND CVSS Score < 9.0
Publisher: Slack
Template: Slack
Niveau de notification: NOTIFY_TEAM
Throttle: 1 message par 4h (ne pas spammer)
Statut: Enabled ✅
```

**Résultat:** Alerte Slack si nouvelle vuln HIGH, max 1x par 4h

---

#### Alert 3: MEDIUM (CVSS 4.0 - 6.9) — Digest quotidien

```
Nom: MEDIUM - Daily Digest (02h00 UTC)
Type d'alerte: Portfolio metrics report
Condition: CVSS Score >= 4.0 AND CVSS Score < 7.0
Publisher: Slack
Template: Slack (utiliser celui du "Rapport quotidien MEDIUM")
Récurrence: Scheduled
Schedule: Quotidien à 02:00 UTC
Grouping: Par projet
Statut: Enabled ✅
```

**Résultat:** Un seul message Slack par jour consolidant toutes les MEDIUM du jour précédent

---

#### Alert 4: LOW (CVSS < 4.0) — Digest hebdomadaire

```
Nom: LOW - Weekly Digest (Lundi 09h00 UTC)
Type d'alerte: Portfolio metrics report
Condition: CVSS Score < 4.0
Publisher: Slack
Template: Slack (utiliser celui du "Rapport hebdomadaire LOW")
Récurrence: Scheduled
Schedule: Chaque lundi à 09:00 UTC
Grouping: Par sévérité + type d'issue
Statut: Enabled ✅
```

**Résultat:** Un seul message Slack par semaine avec digest des LOW

---

### Étape 4️⃣ : Tester la configuration

1. Créer une vulnérabilité test dans un projet (ou importer un SBOM avec une vuln connue)
2. Vérifier que le webhook Slack reçoit le message
3. Exécuter le script de test (voir section "Script de test Slack" ci-dessous)

### Résumé des niveaux d'alerte

| Sévérité | Type | Fréquence | Template | Channel |
|----------|------|-----------|----------|---------|
| CRITICAL | Alerte immédiate | À chaque détection | CRITICAL | #devsecops_notif |
| HIGH | Alerte priorité | 1x par 4h max | HIGH | #devsecops_notif |
| MEDIUM | Digest quotidien | 02h00 UTC | Quotidien MEDIUM | #devsecops_notif |
| LOW | Digest hebdo | Lundi 09h00 UTC | Hebdo LOW | #devsecops_notif |

---

---

## ⚠️ Résumé: Comment DependencyTrack filtre par sévérité

**Le workflow complet:**

```
1. NEW_VULNERABILITY détectée
   ↓
2. DependencyTrack évalue toutes les Alerts
   ├─ Alert "CRITICAL": Condition "CVSS >= 9.0" → MATCH? ✅ → Exécute
   ├─ Alert "HIGH": Condition "CVSS 7.0-8.9" → MATCH? ✅ → Exécute
   ├─ Alert "MEDIUM": Condition "CVSS 4.0-6.9" → MATCH? ❌ → Skip
   └─ Alert "LOW": Condition "CVSS < 4.0" → MATCH? ❌ → Skip
   ↓
3. Pour chaque Alert qui match:
   ├─ Récupère le Template assigné (ex: "Slack CRITICAL")
   ├─ Évalue les variables Freemarker ({{ subject.vulnerability.vulnId }}, etc.)
   ├─ Envoie le message formaté au Publisher (Slack)
   └─ Alerte reçue dans #devsecops_notif
```

**Donc:**
- ✅ Les **Alerts** filtrent par sévérité (CVSS)
- ✅ Les **Templates** définissent l'apparence du message
- ✅ Les **Templates** NE savent PAS qu'ils sont CRITICAL/HIGH/etc.
- ✅ C'est l'Alert qui décide "appliquer ce template ou pas"

---

## Créer et tester les Templates

### Créer un Custom Template dans DependencyTrack

1. **Administration → Notifications → Templates → Create Template**

2. Remplir:
   ```
   Name: Slack CRITICAL Custom
   Mime Type: application/json
   Template Content: [coller le Freemarker + JSON ci-dessus]
   ```

3. **Important:** Copier/coller TOUT le template (y compris `{% if ... %}`)
   ```freemarker
   {% if notification.group == "NEW_VULNERABILITY" %}
   {
     "blocks": [
       ...
     ]
   }
   {% endif %}
   ```

4. **Validation:**
   - Le template DOIT contenir la condition `{% if notification.group == "NEW_VULNERABILITY" %}`
   - Le JSON à l'intérieur doit être valide
   - Les variables doivent être en Freemarker `{{ variable }}`, pas `${variable}`

### Tester le Template avec des valeurs réelles

Une fois le template créé, déclencher une alerte test:

```bash
# 1. Créer un projet test
# Administration → Projects → Create Project "test-payload"

# 2. Importer un SBOM avec une vulnérabilité connue
# (ou manuellement ajouter une fausse dépendance via l'API)

# 3. Vérifier le message Slack
# Le template sera évalué et les variables remplacées:
# ${project.name} → "test-payload"
# ${vulnerability.cveId} → "CVE-2024-xxxxx"
# etc.
```

### Debugger un Template qui ne fonctionne pas

**Erreur:** "Invalid template" en créant l'Alert

Solutions:
1. **Vérifier la syntaxe JSON:** Utiliser [JSONLint](https://jsonlint.com/)
2. **Vérifier les noms de variables:** Consulter [DependencyTrack docs](https://docs.dependencytrack.org/integrations/notifications.html#template-variables)
3. **Vérifier les accolades:** `${variable}` (pas `$variable` ou `{{variable}}`)
4. **Vérifier le Mime Type:** Doit être `application/json` pour Slack

**Erreur:** Template valide mais variables ne se remplacent pas

- Vérifier que la variable existe (ex: `${vulnerability.cvssV3Score}` vs `${vulnerability.cvssScore}`)
- Consulter la version de DependencyTrack (certaines variables peuvent varier)
- Tester avec un template simple d'abord:
  ```json
  {
    "text": "Project: ${project.name}, CVE: ${vulnerability.cveId}"
  }
  ```

---

## Script de test Slack

Valider la connectivité avant deployment en production.

**File: `test-slack-webhook.sh`**

```bash
#!/bin/bash

set -e

WEBHOOK_URL="${1:-}"

if [ -z "${WEBHOOK_URL}" ]; then
  echo "Usage: $0 <webhook_url>"
  echo "Example: $0 'https://hooks.slack.com/services/T00/B00/XX'"
  exit 1
fi

echo "Testing Slack Webhook connectivity..."

# Test 1: Simple message
echo "→ Test 1: Simple message"
curl -s -X POST "${WEBHOOK_URL}" \
  -H 'Content-Type: application/json' \
  -d '{"text":"✅ DependencyTrack Slack integration test (simple)"}' \
  || { echo "FAILED"; exit 1; }

sleep 2

# Test 2: Rich formatted message (CRITICAL)
echo "→ Test 2: CRITICAL alert (rich format)"
curl -s -X POST "${WEBHOOK_URL}" \
  -H 'Content-Type: application/json' \
  -d '{
    "blocks": [
      {
        "type": "section",
        "text": {
          "type": "mrkdwn",
          "text": "*✅ Test: CRITICAL Vulnerability Alert*\nThis is a test message from DependencyTrack"
        }
      },
      {
        "type": "section",
        "fields": [
          {"type": "mrkdwn", "text": "*CVE:*\nCVE-TEST-12345"},
          {"type": "mrkdwn", "text": "*CVSS:*\n9.8 (CRITICAL)"},
          {"type": "mrkdwn", "text": "*Project:*\nTest Project"},
          {"type": "mrkdwn", "text": "*Component:*\nTest Component"}
        ]
      }
    ]
  }' \
  || { echo "FAILED"; exit 1; }

echo ""
echo "✅ Slack Webhook tests passed"
echo "Check Slack channel for messages within the last 2 minutes"
```

Exécution :

```bash
chmod +x test-slack-webhook.sh

# Récupérer le webhook depuis Vault
WEBHOOK=$(vault kv get -field=webhook_critical_high secret/dependencytrack/slack)

./test-slack-webhook.sh "${WEBHOOK}"
```

---

## Gestion des faux positifs

### Suppression des alertes flottantes

Si une vulnérabilité doit être ignorée (faux positif, non applicable) :

1. **DependencyTrack UI :** Project → Vulnerability → Mark as False Positive
2. **Slack :** Notifier dans le fil #security-alerts avec raison
3. **Justification requise** pour traçabilité MDR :
   - Documenter dans Confluence
   - Lier au ticket de révision de sécurité

---

## Monitoring des alertes

### Métriques à suivre

| Métrique | Seuil | Action |
|----------|-------|--------|
| CRITICAL non-résolues > 1h | Alerte PagerDuty | Escalade CTO |
| HIGH non-résolues > 8h | Alerte Slack | Réunion quotidienne sécurité |
| MEDIUM + LOW croissance > 20% semaine | Rapport | Revue planification |
| Slack webhook failures | Toute erreur | Alert ops |

Requête Prometheus :
```promql
rate(slack_webhook_failures_total[5m]) > 0
```

---

## Intégration avec PagerDuty (optionnel)

Pour escalade automatique CRITICAL :

1. Créer intégration PagerDuty dans DependencyTrack
2. Mapper sévérité DependencyTrack → PagerDuty urgency
3. Configurer service ONCALL avec alerting

```yaml
PagerDuty Service: "Security Incidents"
Mapping:
  CRITICAL → Urgency: HIGH
  HIGH → Urgency: MEDIUM
```

---

## Contacts d'escalade

| Sévérité | Délai | Escalade |
|----------|-------|----------|
| CRITICAL | 0h | On-call security engineer + CISO |
| HIGH | 4h | Security team lead + Product owner |
| MEDIUM | 24h | Security team async review |
| LOW | Batch hebdo | Team backlog planning |

---

## Annexes

- [DependencyTrack Slack Publisher Docs](https://docs.dependencytrack.org/integrations/notifications.html)
- [CVSS v3.1 Scoring Guide](https://www.first.org/cvss/v3.1/specification-document)
- [Slack Block Kit Builder](https://app.slack.com/block-kit-builder)
