# Documentation DependencyTrack — Migration depuis Snyk

Guide complet de déploiement et intégration de DependencyTrack pour remplacer Snyk sur l'infrastructure OneOrtho Medical.

---

## 🚀 STRATÉGIE VALIDÉE

**Décision:** Garder SonarQube + Nettoyer le reste + Upgrade RAM 8 GB

État après exécution:
- Jenkins, Datadog, LXD supprimés
- SonarQube conservé (2.6 GB)
- Disque nettoyé (~1.5 GB libérés)
- RAM 8 GB en cours de déploiement OVH
- Résultat: SonarQube + DependencyTrack sans limitation

---

## 📋 Documents

### 0. [00-server-cleanup-plan.md](00-server-cleanup-plan.md) — **À EXÉCUTER D'ABORD**
**Plan de nettoyage serveur** — Arrêter Jenkins/Datadog/LXD, garder SonarQube

Phases:
1. **Phase 1 (30 min):** Exécuter le script de nettoyage immédiatement
2. **Phase 2 (attente 24h):** OVH upgrade RAM 4 → 8 GB
3. **Phase 3 (5 min):** Vérifier l'upgrade et tester services

Scripts fournis:
- `phase1-cleanup.sh` — Exécuter maintenant
- `phase2-verify.sh` — Exécuter après upgrade OVH

**Durée totale:** 2 jours (dont 24h attente OVH)

---

### 00B. [00-ram-analysis.md](00-ram-analysis.md) — (Historique, obsolète)
**Analyse détaillée RAM** — Conservé pour référence, ne plus utiliser
**Analyse RAM et choix stratégiques** — CRITIQUE pour le serveur 3.7 GB

État du serveur:
- 3.7 GB RAM (SonarQube 2.6 GB + Jenkins 0.7 GB = critique)
- 152 MB disponible (insuffisant pour DependencyTrack)

Recommandations:
- **Arrêter SonarQube** (récupère 2.1 GB)
- Limiter DependencyTrack à 1 GB RAM (configuration fournie)
- Utiliser PostgreSQL 13 existant (économise 1 GB)
- Long terme: upgrade VPS RAM 4 GB → 8 GB

**Durée:** 5 min pour décision, 15 min pour exécution

---

### 00B. [00-pre-deployment-analysis.md](00-pre-deployment-analysis.md)
**Checklist pré-déploiement détaillée** — Nettoyage et préparation serveur

Actions essentielles:
- Libérer RAM (arrêter services inutiles)
- Libérer disque (nettoyer snaps, apt cache)
- Reconfigurer ports (Jenkins 8080 → 8090)
- Créer DB PostgreSQL
- Configurer Nginx

**Durée:** 70 minutes (une fois)

---

### 1. [01-deployment-dependencytrack.md](01-deployment-dependencytrack.md)
**Déploiement et configuration initiale**

Guide complet pour déployer DependencyTrack sur un serveur Linux via Ansible et Docker Swarm.

**Couvre:**
- Architecture (Frontend, API Backend, PostgreSQL)
- Template Docker Compose Stack
- Rôles et variables Ansible
- Configuration initiale (admin, équipes, SMTP)
- Migration depuis Snyk
- Sauvegardes et maintenance
- Troubleshooting

**Durée:** ~1-2 heures de déploiement
**Audience:** DevOps, Infrastructure

---

### 2. [02-slack-alerts-strategy.md](02-slack-alerts-strategy.md)
**Stratégie d'alertes et notifications Slack**

Configuration complète des webhooks Slack avec alertes graduées par sévérité CVSS.

**Couvre:**
- Niveaux de sévérité (CRITICAL, HIGH, MEDIUM, LOW)
- Payloads Slack prêts à l'emploi (format Block Kit)
- Configuration dans l'UI DependencyTrack
- Script de test des webhooks
- Gestion des faux positifs
- Monitoring et escalade

**Niveaux de sévérité:**
- **CRITICAL (CVSS ≥ 9.0)** : Alerte immédiate + mention @security-team
- **HIGH (7.0-8.9)** : Alerte standard, escalade après 4h
- **MEDIUM (4.0-6.9)** : Rapport quotidien à 02h00
- **LOW (< 4.0)** : Rapport hebdomadaire le lundi

**Durée:** ~30 minutes de configuration
**Audience:** Security, Ops

---

### 3. [03-project-integration.md](03-project-integration.md)
**Intégration des projets Git avec SBOM**

Configuration des trois projets `saas_local/` (app, modulesjs, branch_hardening) pour générer et uploader automatiquement les SBOM CycloneDX.

**Couvre:**
- Création des projets dans DependencyTrack via API
- Générateurs SBOM par type (PHP Composer, Node/npm)
- GitHub Actions workflows réutilisables
- Configuration des secrets GitHub
- Versioning et tagging
- Monitoring des scans
- Troubleshooting

**Projets:**
| Projet | Type | Outil SBOM |
|--------|------|-----------|
| app | PHP 8.2 | cyclonedx-composer |
| modulesjs | Node 18 | @cyclonedx/npm |
| branch_hardening | Rules/Docs | CycloneDX manuel |

**Durée:** ~1 heure par projet (3 projets)
**Audience:** Developers, DevOps

---

## 🚀 Quick Start

### Déploiement en 3 étapes

```bash
# 1. Déployer l'infrastructure
cd /home/gtatchum/Sites/wwwroot/oo-infra
ansible-playbook -i inventory/preprod/hosts.yml \
  projects/oo/deploy_dependencytrack.yml

# 2. Configurer Slack
# → Voir 02-slack-alerts-strategy.md section "Configuration Slack"

# 3. Intégrer les projets
# → Voir 03-project-integration.md section "Créer les projets"
```

---

## 📊 Checkpoints clés

| Étape | Document | Status |
|-------|----------|--------|
| Infrastructure Docker Swarm | 01 | ✅ |
| PostgreSQL + données persistantes | 01 | ✅ |
| Interface web accessible | 01 | ✅ |
| Webhooks Slack configurés | 02 | ⏳ |
| Projets créés dans DT | 03 | ⏳ |
| SBOM générés et uploadés | 03 | ⏳ |
| Alertes fonctionnelles E2E | 02 + 03 | ⏳ |
| Migration Snyk terminée | 01 | ⏳ |

---

## 🔐 Secrets et Vault

Tous les secrets doivent être stockés dans Ansible Vault :

```bash
vault kv put secret/dependencytrack \
  api_key="[api-key-from-ui]" \
  postgres_password="[secure-password]"

vault kv put secret/dependencytrack/slack \
  webhook_critical_high="https://hooks.slack.com/services/..." \
  webhook_medium_low="https://hooks.slack.com/services/..."

vault kv put secret/github \
  token="ghp_..." \
  org="OneOrthoMedical"
```

**Jamais en clair dans:**
- Variables Ansible
- Fichiers YAML
- Commits Git
- Logs

---

## 📈 Architecture globale

```
┌─────────────────────────────────────────────────┐
│                 Internet                        │
├─────────────────────────────────────────────────┤
│                                                 │
│  GitHub Webhooks ──────┐                        │
│  (on push)             │                        │
│                        ↓                        │
│  ┌────────────────────────────────────────┐    │
│  │  GitHub Actions (CI/CD)                │    │
│  │  - Generate SBOM (CycloneDX)           │    │
│  │  - Upload to DependencyTrack API       │    │
│  └────────────────────────────────────────┘    │
│                        │                        │
│                        ↓                        │
│  ┌────────────────────────────────────────┐    │
│  │    DependencyTrack (Swarm)             │    │
│  │  - Frontend (8080)                     │    │
│  │  - API Backend (8081)                  │    │
│  │  - PostgreSQL (5432)                   │    │
│  └────────────────────────────────────────┘    │
│                        │                        │
│         ┌──────────────┼──────────────┐        │
│         ↓              ↓              ↓        │
│   [Slack]        [PagerDuty]    [Prometheus]  │
│   Alerts          (CRITICAL)     (Metrics)    │
│                                                 │
└─────────────────────────────────────────────────┘
```

---

## 🛡️ Conformité MDR / IEC 62304

Cette documentation ne contient:
- ❌ Aucun conseil médical
- ❌ Aucune validation clinique
- ❌ Aucun secret en clair
- ✅ Références traçables (sources officielles DependencyTrack)
- ✅ Processus documentés et reproductibles

---

## 📞 Contacts d'escalade

| Rôle | Contact | Escalade |
|------|---------|----------|
| DevSecOps Lead | gtatchum@oneortho-medical.com | OncCall |
| Infrastructure | ops-team@oneortho-medical.com | Manager Infra |
| Security Team | security@oneortho-medical.com | CISO |

---

## 📝 Historique

| Date | Version | Changements |
|------|---------|-------------|
| 2026-05-27 | 1.0.0 | Documentation initiale |
| | | - Déploiement Ansible |
| | | - Alertes Slack |
| | | - Intégration projets saas_local |

---

## 🔗 Ressources externes

- [DependencyTrack Official Docs](https://docs.dependencytrack.org/)
- [CycloneDX Specification](https://cyclonedx.org/)
- [Slack Block Kit Builder](https://app.slack.com/block-kit-builder)
- [CVSS v3.1 Scoring](https://www.first.org/cvss/v3.1/specification-document)
- [Ansible Documentation](https://docs.ansible.com/)
- [Docker Swarm Reference](https://docs.docker.com/engine/swarm/)

---

## 📖 Index complet

1. **Déploiement Infrastructure**
   - 01-deployment-dependencytrack.md (sections 1-10)
   - Prérequis, architecture, playbooks Ansible, configuration initiale

2. **Alertes et Notifications**
   - 02-slack-alerts-strategy.md (sections 1-9)
   - Webhooks, payloads JSON, configuration UI, test et monitoring

3. **Intégration CI/CD**
   - 03-project-integration.md (sections 1-9)
   - Création projets, SBOM generation, workflows GitHub Actions, versioning

4. **Maintenance**
   - 01-deployment-dependencytrack.md (sections 9)
   - Sauvegardes, monitoring, troubleshooting

---

**Dernière mise à jour:** 2026-05-27 | **Version:** 1.0.0 | **Statut:** ✅ Prêt pour déploiement
