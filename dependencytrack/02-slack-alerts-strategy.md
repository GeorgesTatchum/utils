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

## Payloads Slack

### 1. Alerte CRITICAL (CVSS >= 9.0)

**Déclenche immédiatement — sans délai**

```json
{
  "channel": "#security-alerts",
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
          "text": "*CVE:*\nCVE-2024-12345"
        },
        {
          "type": "mrkdwn",
          "text": "*CVSS Score:*\n9.8 (CRITICAL)"
        },
        {
          "type": "mrkdwn",
          "text": "*Project:*\napp"
        },
        {
          "type": "mrkdwn",
          "text": "*Component:*\nOpenSSL 3.0.0"
        },
        {
          "type": "mrkdwn",
          "text": "*Severity:*\nCRITICAL"
        },
        {
          "type": "mrkdwn",
          "text": "*Status:*\nNo patch available"
        }
      ]
    },
    {
      "type": "section",
      "text": {
        "type": "mrkdwn",
        "text": "*Description:*\nBuffer overflow in OpenSSL X.509 certificate verification allows remote code execution"
      }
    },
    {
      "type": "section",
      "text": {
        "type": "mrkdwn",
        "text": "*Affected Versions:*\n3.0.0 - 3.0.5\n\n*Recommended Action:*\nUpgrade immediately to 3.0.6+ or apply security patch"
      }
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
          "url": "https://dependencytrack.oo-medical.local/project/app",
          "style": "danger"
        },
        {
          "type": "button",
          "text": {
            "type": "plain_text",
            "text": "View CVE Details"
          },
          "url": "https://nvd.nist.gov/vuln/detail/CVE-2024-12345"
        }
      ]
    }
  ]
}
```

### 2. Alerte HIGH (CVSS 7.0 - 8.9)

**Alerte standard — sans mention channel**

```json
{
  "channel": "#security-alerts",
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
          "text": "*CVE:*\nCVE-2024-56789"
        },
        {
          "type": "mrkdwn",
          "text": "*CVSS Score:*\n7.5 (HIGH)"
        },
        {
          "type": "mrkdwn",
          "text": "*Project:*\nmodulsjs"
        },
        {
          "type": "mrkdwn",
          "text": "*Component:*\nExpress.js 4.18.0"
        }
      ]
    },
    {
      "type": "section",
      "text": {
        "type": "mrkdwn",
        "text": "*Issue:*\nAuthentication bypass via crafted HTTP headers"
      }
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
          "url": "https://dependencytrack.oo-medical.local/project/modulesjs",
          "style": "danger"
        }
      ]
    }
  ]
}
```

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
          "url": "https://dependencytrack.oo-medical.local/dashboard"
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
          "url": "https://dependencytrack.oo-medical.local/dashboard"
        }
      ]
    }
  ]
}
```

---

## Configuration dans DependencyTrack UI

### Notifications Webhook

1. **Administration → Notifications → Add Notification**

   | Champ | Valeur |
   |-------|--------|
   | Name | Slack CRITICAL Alerts |
   | Alert Level | PORTFOLIO_VULN_ADDED |
   | Published | ☑ |
   | Publisher | Slack |
   | Template | Default |

2. **Configuration Publisher (Slack) :**

   ```
   Slack API Key: [laisser vide — webhook URL suffit]
   Webhook URL: https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXX
   Channel: #security-alerts
   ```

3. **Ajouter filtres par sévérité :**

   Créer 4 notifications Slack séparées :
   - `Slack CRITICAL (CVSS >= 9.0)`
   - `Slack HIGH (7.0 - 8.9)`
   - `Slack MEDIUM Daily (4.0 - 6.9)` — scheduled
   - `Slack LOW Weekly (< 4.0)` — scheduled

### Configuration des flux par sévérité

Dans `Administration → Notifications → Rules` :

```yaml
# Rule 1: CRITICAL
Event Type: "VULNERABILITY_IDENTIFIED"
Severity: "CRITICAL"
Project: "ALL"
→ Notification: "Slack CRITICAL Alerts"
→ Execute Immediately

# Rule 2: HIGH
Event Type: "VULNERABILITY_IDENTIFIED"
Severity: "HIGH"
Project: "ALL"
→ Notification: "Slack HIGH Alerts"
→ Execute Immediately
→ Escalate after 4h

# Rule 3: MEDIUM (scheduled)
Event Type: "DAILY_SUMMARY"
Severity: "MEDIUM"
Project: "ALL"
→ Notification: "Slack MEDIUM Daily"
→ Execute at 02:00 UTC

# Rule 4: LOW (scheduled)
Event Type: "WEEKLY_SUMMARY"
Severity: "LOW"
Project: "ALL"
→ Notification: "Slack LOW Weekly"
→ Execute Mondays 09:00 UTC
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
