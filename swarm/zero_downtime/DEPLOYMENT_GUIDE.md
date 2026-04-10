# 🏥 Guide de Déploiement - Docker Swarm Cluster Zero-Downtime

**Pour domaine médical avec exigences de compliance RGPD/RCPD**

---

## ⚠️ IMPORTANT - LISEZ D'ABORD

Vous devez choisir une stratégie de déploiement appropriée à votre contexte médical.

### 4 Options Disponibles:

#### 🚫 Option 1: Rolling Updates Simple (NON RECOMMANDÉ pour médical)
- **Risques**: Version mismatch, transaction hybrid, audit trail incohérent
- **Downtime**: Zéro
- **Compliance**: ❌ Non conforme RGPD strict
- **Quand l'utiliser**: Seulement si risques explicitement acceptés par médecins/compliance

📖 **Lire d'abord**: [MEDICAL_DEPLOYMENT_ANALYSIS.md](MEDICAL_DEPLOYMENT_ANALYSIS.md) - Section "Risques Spécifiques"

---

#### ✅ Option 2: Blue-Green Single Service (RECOMMANDÉ pour mises à jour individuelles)
- **Risques**: Très minimisés (une seule service change)
- **Downtime**: Zéro
- **Compliance**: ✅ Conforme RGPD/RCPD/HIPAA (si backward compatible)
- **Effort**: 20-30 min par service, répéter pour chaque
- **Quand l'utiliser**: Mise à jour PHP, Nginx, Workers individuellement

📖 **Lire**: [BLUE_GREEN_SINGLE_SERVICE.md](BLUE_GREEN_SINGLE_SERVICE.md) ⭐ **NOUVEAU**

✅ **Commande recommandée**:
```bash
bash scripts/deploy-service-blue-green.sh php v1.1
```

---

#### ✅ Option 3: Blue-Green Whole Stack (RECOMMANDÉ pour changes multi-service)
- **Risques**: Minimisés (version cohérente, DB alignée)
- **Downtime**: Zéro
- **Compliance**: ✅ Conforme RGPD/RCPD/HIPAA
- **Effort**: 2-3 jours de setup, puis operational
- **Quand l'utiliser**: Changement multi-services, migration majeure

📖 **Lire**: [BLUE_GREEN_IMPLEMENTATION.md](BLUE_GREEN_IMPLEMENTATION.md)

✅ **Commandement recommandé**: 
```bash
bash scripts/deploy-blue-green.sh preprod v1.1
```

---

#### ⏰ Option 4: Scheduled Maintenance Window
- **Risques**: Nuls (tous les services redémarrés ensemble)
- **Downtime**: 30-45 minutes (prévisible)
- **Compliance**: ✅ Parfait pour RGPD
- **Effort**: Minimal
- **Quand l'utiliser**: Actions critiques, migrations majeures

📖 **Quand l'utiliser**: Actions critiques, migrations majeures

---

## 🎯 Choisissez Votre Chemin

### Vous mettez à jour UN SEUL SERVICE (PHP, Nginx, Workers):
→ Utilisez **Blue-Green Single Service** (RECOMMANDÉ)
→ Temps: 20-30 minutes
→ Répétez pour chaque service

### Vous mettez à jour PLUSIEURS SERVICES ensemble (PHP + Nginx):
→ Utilisez **Blue-Green Whole Stack**
→ Temps: 45-60 minutes
→ Ou faire service-par-service avec single-service BG

### Vous êtes en PRE-PROD et testez:
→ Commencez par **Blue-Green Single Service** pour comprendre
→ Puis planifiez **Blue-Green Whole Stack** pour la prod

### Vous allez en PROD maintenant:
→ Utilisez **Blue-Green Single Service** (service par service)
→ C'est le standard de l'industrie healthcare
→ Rollback ultra-rapide (< 1 minute)

### Vous avez une mise à jour CRITIQUE (sécurité):
→ Utilisez **Blue-Green Single Service** pour rapidité ET sécurité
→ Canary 10% d'abord
→ Puis 100%

### Vous devez changer le schéma BD:
→ Utilisez **Blue-Green Whole Stack**
→ Ou **Scheduled Maintenance Window**
→ Les migrations DB doivent être séparées du code

---

## 📚 Documentation Complète

### Pour Comprendre les Risques:

1. **MEDICAL_DEPLOYMENT_ANALYSIS.md** (15 minutes)
   - Analyse des risques en contexte médical
   - Pourquoi rolling updates simple ne suffisent pas
   - Matrice de décision par type de déploiement
   - **Lecture obligatoire si vous avez des responsabilités compliance**

### Pour Rolling Updates (Simple):

2. **QUICK_START.md** (5 min)
   - Comprendre le concept en 5 minutes
   - Timeline par service
   - Commandes basiques

3. **UPDATE_STRATEGY.md** (10 min)
   - Quand faire pre-pull (large images)
   - Timing exact par service
   - Décision matrice

4. **ROLLING_UPDATES_PROCEDURE.md** (Step-by-Step)
   - Procédure complète détaillée
   - Par étapes
   - Avec vérifications

### Pour Blue-Green (Recommandé):

5. **BLUE_GREEN_SINGLE_SERVICE.md** ⭐ (NOUVEAU - Pour mises à jour individuelles)
   - Architecture Blue-Green pour UN service
   - Mise à jour service par service
   - Backward compatibility patterns
   - Quand c'est safe vs risqué
   - Checklist complète
   - **Utilisez ceci pour la plupart de vos déploiements**

6. **BLUE_GREEN_IMPLEMENTATION.md** (Pour changes multi-service)
   - Architecture blue-green whole-stack
   - Setup infrastructure double
   - Phases de déploiement
   - Automation complète
   - Checklist pre-deployment

### Pour Audit & Compliance:

6. **TRACEABILITY_AUDIT.md** (Compliance médical)
   - 5 approches pour tracer les requêtes
   - REQUEST_ID tracking (recommandé)
   - Exemple d'audit trail complet
   - Checklist RGPD

7. **IMPLEMENTATION_SYMFONY_LARAVEL.md** (Code)
   - Code PHP prêt à l'emploi
   - Intégration Symfony/Laravel
   - Database audit table
   - Test request tracing

8. **AUDIT_WORKFLOW_E2E_EXAMPLE.md** (Scenario réel)
   - Exemple complet patient consultation
   - Tracer requête de bout en bout
   - Compliance report

### Pour Mise en Place Pratique:

9. **UPDATE_SINGLE_SERVICE.md**
   - Par service (PHP, Nginx, Traefik, DB, Workers)
   - Procédure optimisée par service
   - Timing exact

10. **PRODUCTION_SCRIPTS.md**
    - Scripts prêts à l'emploi
    - Utilisation immediate
    - Support pre-pull pour grandes images

---

## 🚀 Démarrer Maintenant

### Scenario 1: Vous testez en PRE-PROD

```bash
# 1. Comprendre le concept (5 min)
cat QUICK_START.md

# 2. Choisir sa stratégie (10 min)
cat UPDATE_STRATEGY.md

# 3. Pre-pull les images (une fois)
bash scripts/pre-pull-images.sh php

# 4. Mettre à jour un service
bash scripts/update-php-safe.sh preprod v1.1

# 5. Monitorer
bash scripts/monitor-update.sh oo_php
```

### Scenario 2: Vous allez en PRODUCTION (sûr)

```bash
# 1. Lire les risques (15 min)
cat MEDICAL_DEPLOYMENT_ANALYSIS.md

# 2. Décider: Blue-Green?
# Réponse: OUI pour domaine médical

# 3. Implémenter Blue-Green (2-3 jours)
cat BLUE_GREEN_IMPLEMENTATION.md
# → Suivre les étapes

# 4. Déployer avec Blue-Green
bash scripts/deploy-blue-green.sh prod v1.1

# 5. Monitorer (24h)
watch -n 10 'docker stats --no-stream'
```

### Scenario 3: Vous changez le schéma BD

```bash
# Rolling updates ne suffisent PAS
# Options:
#   1. Scheduled maintenance (downtime)
#   2. Blue-Green avec migration préalable

# Lire:
cat MEDICAL_DEPLOYMENT_ANALYSIS.md  # Section "DB Schema Mismatch"
cat BLUE_GREEN_IMPLEMENTATION.md    # Section "Phase 2: DB Migrations"
```

---

## 🔍 Vérifications Avant Déploiement

### Checklist Minimal:

```
Avant tout déploiement:
☐ Lire MEDICAL_DEPLOYMENT_ANALYSIS.md (risques)
☐ Backups actuels pris
☐ Plan de rollback documenté
☐ Monitoring activé (logs, metrics)
☐ Team notifiée
☐ Heures de déploiement: hors-pic traffic
☐ Grace period configuré (≥ 30-60s)
☐ Health check endpoints testés

Avant pre-pull (pour grandes images):
☐ Espace disque vérifié (+ 2GB par image)
☐ Réseau stable
☐ No other deployments running

Avant traffic switch (Blue-Green):
☐ GREEN healthchecks: 100%
☐ DB migrations: 100% success
☐ Critical APIs tested on GREEN
☐ Load tests passed
☐ Medical team validation done
```

---

## 📊 Matrice de Décision Rapide

| Mise à Jour | Service(s) | Taille | Risque | Stratégie Recommandée | Temps |
|-------------|-----------|--------|--------|----------------------|-------|
| Bugfix | PHP seul | <100MB | Bas | Blue-Green Single ✅ | 15-20min |
| UX Change | Nginx seul | <200MB | Bas | Blue-Green Single ✅ | 10-15min |
| Nouvelle feature | PHP seul | <500MB | Moyen | Blue-Green Single ✅ | 20-30min |
| Code refacto | PHP + Workers | ~2GB | Haut | Blue-Green Whole Stack | 45-60min |
| DB Migration | Multi-service | ~500MB | Haut | Scheduled Window | 45min downtime |
| Grosse refacto | Multi-service | >1GB | Très haut | Blue-Green Whole Stack | 1-2h |
| Security patch | PHP/Nginx | Variable | URGENT | Blue-Green Single ASAP | 15-25min |
| PHP update | PHP v1.0→v1.1 | 1.5GB | Moyen | BG Single + Pre-pull | 25-30min |
| Workers update | Workers seul | 762MB | Moyen | Blue-Green Single | 15-20min |
| Traefik config | Traefik seul | 53MB | Bas | Blue-Green Single ou Rolling | 5-10min |

---

## ⏱️ Timing Réaliste par Service

###  Avec Rolling Update Simple (risqué):

| Service | Image Size | Avec Pre-Pull | Sans Pre-Pull |
|---------|-----------|--------------|--------------|
| PHP | 1.5GB | 3 min | 15-20 min |
| Workers | 762MB | 2 min | 10-15 min |
| Nginx | 126MB | 1 min | 5-7 min |
| Traefik | 53MB | 1 min | 2-3 min |
| MariaDB | 110MB | 1 min | 3-5 min |

### Avec Blue-Green Single Service (sûr):

| Service | Prépare Green | Tests & Health | Canary (10→50→100%) | Total |
|---------|--------------|----------------|-------------------|-------|
| PHP | 5 min | 5 min | 20 min (monitor) | ~30 min |
| Nginx | 3 min | 3 min | 15 min (monitor) | ~20 min |
| Workers | 4 min | 2 min | 10 min (monitor) | ~15 min |

### Avec Blue-Green Whole Stack (safest):

| Étape | Temps | Notes |
|-------|-------|-------|
| Préparer GREEN | 5 min | Build, démarrer services |
| DB Migrations | 5-10 min | Selon complexité |
| Health checks | 5 min | Vérifier endpoints |
| 10% canary | 30 min | Monitorer |
| 50% canary | 30 min | Monitorer |
| 100% switch | 2 min | Traffic basculement |
| Validation 24h | 24h | Confirmer stablité |
| **Total** | **~50 min + 24h** | **Zero downtime** |

---

## 🛠️ Outils & Scripts Disponibles

### Pre-Pull (pour grandes images):

```bash
# Pre-pull PHP image on all nodes
bash scripts/pre-pull-images.sh php

# Pre-pull workers
bash scripts/pre-pull-images.sh workers

# Support update-php-safe.sh (intégré)
bash scripts/update-php-safe.sh preprod v1.1 --skip-pre-pull
```

### Monitoring:

```bash
# Monitor update en real-time
bash scripts/monitor-update.sh oo_php

# Check deployment status
docker stack services oo

# View logs
docker service logs oo_php --follow

# Check health
docker service ps oo_php
```

### Blue-Green Single Service:

```bash
# Deploy single service with Blue-Green (NEW!)
bash scripts/deploy-service-blue-green.sh php v1.1
bash scripts/deploy-service-blue-green.sh nginx v1.1
bash scripts/deploy-service-blue-green.sh workers v1.1

# Interactive process with canary stages (10% → 50% → 100%)
```

### Audit Tracing:

```bash
# Setup request tracing (one-time)
bash scripts/setup-request-tracing.sh preprod

# Deploy tracing config to cluster
bash scripts/deploy-request-tracing.sh preprod

# Test tracing works
bash scripts/test-request-tracing.sh

# Query audit logs
bash scripts/query-audit.sh req-abc123-xyz
```

---

## 📞 Support & Troubleshooting

### Si quelque chose échoue:

1. **Arrêt de service immédiat**:
   ```bash
   docker service rollback oo_php
   ```

2. **Revert rollback Blue-Green**:
   ```bash
   # Switch traffic back to BLUE
   # (voir BLUE_GREEN_IMPLEMENTATION.md)
   ```

3. **Vérifier les logs**:
   ```bash
   docker service logs oo_php | tail -50
   ```

4. **Re-diagnostiquer**:
   ```bash
   # Check which issue (see TROUBLESHOOTING.md)
   docker service ps oo_php
   docker stats
   docker exec [container] ps
   ```

---

## 🎓 Formation Rapide par Rôle

### Pour Médecins & Compliance Officers:

1. Lire: MEDICAL_DEPLOYMENT_ANALYSIS.md (15 min)
2. Comprendre: Blue-Green vs Rolling Updates
3. Valider: Checklist pre-deployment
4. Approuver: Deployment plan

### Pour DevOps/SRE:

1. Lire: BLUE_GREEN_IMPLEMENTATION.md (30 min)
2. Setup: Infrastructure Blue-Green (2 days)
3. Automatiser: Scripts deployment
4. Documenter: Runbooks locaux

### Pour Développeurs:

1. Lire: QUICK_START.md (5 min)
2. Comprendre: Service dependencies
3. Test: Rolling update en preprod
4. Valider: Health checks après update

---

## Prochaines Étapes

0. **Décidez la stratégie** (15 min)
   - Rolling simple? (risqué pour médical)
   - Blue-Green? (recommandé)
   - Scheduled window? (sûr mais downtime)

1. **Pour Rolling Updates**:
   ```bash
   cat QUICK_START.md
   bash scripts/pre-pull-images.sh nginx  # Test safe
   ```

2. **Pour Blue-Green**:
   ```bash
   cat BLUE_GREEN_IMPLEMENTATION.md
   # Allocate 2-3 days pour setup
   ```

3. **Pour Audit Compliance**:
   ```bash
   bash scripts/setup-request-tracing.sh preprod
   ```

4. **Documentation**:
   - Mettre les docs dans votre wiki interne
   - Former l'équipe
   - Pratiquer rollback une fois

---

## Fichiers Clés de Référence

```
📖 CONCEPTS & STRATEGY
├─ MEDICAL_DEPLOYMENT_ANALYSIS.md ⭐ (lisez d'abord)
├─ CONCEPT.md
├─ QUICK_START.md
└─ UPDATE_STRATEGY.md

🚀 IMPLEMENTATION
├─ BLUE_GREEN_IMPLEMENTATION.md ⭐ (recommandé)
├─ ROLLING_UPDATES_PROCEDURE.md
├─ UPDATE_SINGLE_SERVICE.md
└─ PRODUCTION_SCRIPTS.md

🔐 AUDIT & COMPLIANCE
├─ TRACEABILITY_AUDIT.md
├─ IMPLEMENTATION_SYMFONY_LARAVEL.md
└─ AUDIT_WORKFLOW_E2E_EXAMPLE.md

🛠️ OPERATIONS
├─ scripts/pre-pull-images.sh
├─ scripts/update-php-safe.sh
├─ scripts/setup-request-tracing.sh
└─ scripts/deploy-request-tracing.sh

📋 CHECKLISTS
└─ (Dans les docs)
```

---

## Questions Fréquentes

**Q: C'est safe pour domaine médical?**
A: Rolling simple = risqué, Blue-Green = safe. LISEZ MEDICAL_DEPLOYMENT_ANALYSIS.md

**Q: Quel downtime?**
A: Rolling updates = 0min, Blue-Green = 0min, Scheduled = 30-45min

**Q: Je dois rollback, combien de temps?**
A: Rolling updates = pas possible, Blue-Green = 1-2min, Scheduled = redémarrage normal

**Q: Et si la BD change?**
A: Blue-Green avec migration préalable. Rolling updates = risqué. Scheduled = sûr.

**Q: Comment fonctionne la traçabilité?**
A: Voir TRACEABILITY_AUDIT.md + AUDIT_WORKFLOW_E2E_EXAMPLE.md

**Q: Mon image fait 2GB, c'est long?**
A: Oui, 15min sans pre-pull. Avec pre-pull (une fois) = 3min. VOIR UPDATE_STRATEGY.md

---

## Version et Date

- **Position du document**: v2.0 - Avril 2026
- **Last Updated**: 2026-04-08
- **Applicable pour**: Docker Swarm produits médicales
- **Conformité**: RGPD, RCPD, HIPAA (guide)

---

**Pour toute question, consultez la doc complète ou demandez à l'équipe DevOps.**

✅ **Prêt à déployer? Commencez par MEDICAL_DEPLOYMENT_ANALYSIS.md!**
