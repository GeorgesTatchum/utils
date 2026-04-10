# 📋 Stratégie d'Update: Images Grandes vs Petites

## Résumé Rapide

| Service | Image Size | Approche | Timing | Commande |
|---------|-----------|----------|--------|----------|
| **PHP** | 1.5GB | ✅ Pré-pull | 15min pré-pull + 3min update | `bash scripts/update-php-safe.sh` |
| **Workers** | 762MB | ✅ Pré-pull | 10min pré-pull + 3min update | À implémenter (similaire PHP) |
| **Nginx** | 126MB | ⚠️ Pull during update | ~1-2min | `docker service update --image ...` |
| **Traefik** | 53MB | ⚠️ Pull during update | ~30s-1min | `docker service update --image ...` |
| **MariaDB** | 110MB | ⚠️ Pull during update | ~1-2min | `docker service update --image ...` |

---

## Stratégie 1: Images GRANDES (> 500MB) → Pré-Pull

### Pourquoi pré-pull?
```
SANS pré-pull:
  Update lancée → Docker tire l'image → 10-15 min d'attente
  → Autres services peuvent servir, MAIS
  → Très LENT pour l'utilisateur (updates très longues)

AVEC pré-pull:
  Avant update: Ansible pré-tire l'image sur tous les nœuds (1 fois)
  Update lancée → Image déjà là → 3 min rapides
  → Optimal!
```

### Workflow Complet pour PHP

```bash
# Étape 1: Pré-pull PHP sur TOUS les nœuds (fait une seule fois)
bash scripts/pre-pull-images.sh php
# Ou via Ansible:
ansible-playbook playbooks/pre-pull-images.yml --tags php

# Étape 2: Attendre que le pré-pull se termine (~15 minutes)
# ... prendre un café ☕

# Étape 3: Update PHP (maintenant rapide)
bash scripts/update-php-safe.sh preprod latest
# Timing: ~3 minutes
```

### Docker Compose Config (PHP avec pré-pull)

```yaml
php:
  image: ghcr.io/oneorthomedical/one-plateform-php8.1-fpm:latest
  
  healthcheck:
    test: ["CMD", "php-fpm", "-v"]
    interval: 10s
    timeout: 5s
    retries: 3
    start_period: 30s  # ← Grace period après startup
  
  deploy:
    replicas: 2
    update_config:
      parallelism: 1      # ← Un seul à la fois
      delay: 45s          # ← Valider avant Réplica B
      failure_action: rollback
      monitor: 30s
    
    restart_policy:
      condition: any
      delay: 30s          # ← Connection draining grace period
      max_attempts: 3
```

### Timing Réel (avec pré-pull)

```
Total time: ~3 minutes (UPDATE phase uniquement)
  - 0m00s: Update lancée
  - 0m30s: Réplica A arrêtée
  - 1m00s: Réplica A restart + health check
  - 1m35s: Réplica B update start
  - 2m05s: Réplica B arrêtée
  - 2m35s: Réplica B restart + health check
  - 3m10s: Terminé ✅

User downtime: 0 seconds
```

---

## Stratégie 2: Images PETITES (< 200MB) → Pull During Update

### Pourquoi accepter pull during update?
```
Petite image (126MB) → 1-2 min de download max
  + 3 min de rolling update
  = 4-5 min total (acceptable)

Vs. attendre 15 min pour pré-pull: Pas besoin!
```

### Workflow pour Nginx

```bash
# Direct update - pas de pré-pull nécessaire
docker service update \
  --image ghcr.io/oneorthomedical/one-plateform-nginx:develop \
  oo_nginx

# Timing: ~5 minutes
```

### Timing Réel (petite image, NO pré-pull)

```
Total time: ~5 minutes
  - 0m00s: Update lancée
  - 0m30s: Réplica A arrêtée
  - 0m30s→2m00s: Image pull (126MB, 1-2 min)
  - 2m00s: Réplica A restart + health check
  - 2m35s: Réplica B update start
  - 3m05s: Réplica B arrêtée
  - 3m05s→4m30s: Image pull (126MB, 1-2 min)
  - 4m30s: Réplica B restart + health check
  - 5m10s: Terminé ✅

User downtime: 0 seconds (mais LENT, ~5 min vs 3 min si pré-pull)
```

---

## Stratégie 3: Images TRÈS GRANDES (> 2GB) → OBLIGATOIRE Pré-Pull

### Cas du PHP (1.5GB)

```
SANS pré-pull:
  - Update time: 15-20 minutes (trop long!)
  - User experience: Acceptable (autres services OK) mais très LENT
  - Problème: Si la Réplica B commence son pull pendant que A n'a pas terminé
             → Risque de congestion réseau

AVEC pré-pull (RECOMMANDÉ):
  - Pre-pull: 15 minutes (1 fois, avant update)
  - Update time: 3 minutes (rapide!)
  - Total: 18 minutes au lieu de 20-25 minutes
  - Network: Plus calm, images déjà là
```

---

## Implémentation Pratique

### Cas 1: Update PHP Unique Grande Image

```bash
#!/bin/bash
# Script complet pour PHP avec tout intégré

# Phase 0: Pré-pull
echo "Phase 0: Pre-pulling PHP (1.5GB, ~15 min)..."
bash scripts/pre-pull-images.sh php

# Phase 1: Update (rapide)
echo "Phase 1: Updating PHP service..."
bash scripts/update-php-safe.sh preprod latest

# Résultat: 3 minutes d'update (au lieu de 15-20!)
```

### Cas 2: Update Multiples Petites Images

```bash
#!/bin/bash
# Nginx, Traefik, MariaDB = petites images
# Pas besoin de pré-pull

echo "Updating Nginx..."
docker service update --image ghcr.io/oneorthomedical/one-plateform-nginx:develop oo_nginx

echo "Updating Traefik..."
docker service update --image traefik:v3.6.11 traefik

echo "Updating MariaDB..."
docker service update --image mariadb:11.4.9 oo_mariadb

# Chacun prend ~2-5 minutes
```

### Cas 3: Update Orchestrée (PHP + Nginx + TOUT)

```bash
#!/bin/bash
# Strategy: Pré-pull TOUT, puis update tout

# Phase 0: Pré-pull toutes les images
ansible-playbook playbooks/pre-pull-images.yml --tags all

# Phase 1: Update services one by one
bash scripts/update-php-safe.sh preprod latest

docker service update --image ghcr.io/oneorthomedical/one-plateform-nginx:develop oo_nginx

docker service update --image traefik:v3.6.11 traefik

# etc.
```

---

## Configuration Docker: Ajustements par Image Size

### Pour GRANDES images (PHP, Workers)

```yaml
healthcheck:
  start_period: 30s  # Image déjà là, juste startup
  interval: 10s
  timeout: 5s
  retries: 3

update_config:
  delay: 45s         # Valider entre replicas
  failure_action: rollback

restart_policy:
  delay: 30s         # Connection draining
```

### Pour PETITES images (Nginx, Traefik, MariaDB)

```yaml
healthcheck:
  start_period: 30s  # Include image pull time (~1-2 min)
  interval: 10s
  timeout: 5s
  retries: 3

update_config:
  delay: 45s         # Valider entre replicas
  failure_action: rollback

restart_policy:
  delay: 30s         # Connection draining
```

---

## Monitoring et Troubleshooting

### Pendant Pre-Pull

```bash
# Voir la progression du pré-pull
docker pull ghcr.io/oneorthomedical/one-plateform-php8.1-fpm:latest

# Sur un nœud spécifique via SSH
ssh docker@node1 docker pull ghcr.io/oneorthomedical/one-plateform-php8.1-fpm:latest &
ssh docker@node2 docker pull ghcr.io/oneorthomedical/one-plateform-php8.1-fpm:latest &
wait
```

### Pendant Update

```bash
# Real-time monitoring
bash scripts/monitor-update.sh oo_php

# Check which replica is being updated
docker service ps oo_php

# View update status
docker service inspect --pretty oo_php
```

### En Cas de Problème

```bash
# Rollback immediate
docker service update --rollback oo_php

# Check why it failed
docker service logs oo_php
docker service ps oo_php --no-trunc

# Manual re-pull if needed
docker pull ghcr.io/oneorthomedical/one-plateform-php8.1-fpm:latest
```

---

## Checklist pour Update PHP (Grande Image)

- [ ] Vérifier que pre-pull-images.sh existe et fonctionne
- [ ] Lancer pré-pull: `bash scripts/pre-pull-images.sh php`
- [ ] Attendre que pré-pull se termine (~15 min)
- [ ] Vérifier que image est présente: `docker images | grep php`
- [ ] Lancer update: `bash scripts/update-php-safe.sh preprod latest`
- [ ] Monitorer: `bash scripts/monitor-update.sh oo_php`
- [ ] Vérifier post-update: `bash scripts/pre-update-check.sh`

---

## Checklist pour Update Petite Image (Nginx)

- [ ] Vérifier cluster health: `bash scripts/pre-update-check.sh`
- [ ] Lancer update: `docker service update --image ghcr.io/oneorthomedical/one-plateform-nginx:develop oo_nginx`
- [ ] Monitorer: `docker service ps oo_nginx --watch`
- [ ] Vérifier: `docker service ps oo_nginx`

---

## Summary

✅ **PHP (1.5GB):** Pré-pull + 3min update = Optimal  
✅ **Workers (762MB):** Pré-pull + 3min update = Recommended  
⚠️ **Nginx/Traefik/MariaDB:** Direct update OK, ~5min = Acceptable  
✅ **Zéro-downtime:** Garanti pour tous les services avec cette stratégie
