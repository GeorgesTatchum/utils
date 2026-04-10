# ⚡ Quick Start: Update Services en 5 Etapes

## Pour services PETITS (Nginx, Traefik, MariaDB < 200MB)

```bash
# Étape 1: Vérifier le cluster
bash scripts/pre-update-check.sh

# Étape 2: Update (3-5 min, image tire automatiquement)
docker service update --image <nouvelle_image> <service_name>

# Étape 3: Monitor
bash scripts/monitor-update.sh <service_name>

# Résultat: Zéro downtime! ✅
```

**Exemples:**
```bash
# Update Nginx
docker service update --image ghcr.io/oneorthomedical/one-plateform-nginx:develop oo_nginx

# Update Traefik
docker service update --image traefik:v3.6.11 traefik

# Update MariaDB
docker service update --image mariadb:11.4.9 oo_mariadb
```

---

## Pour services GRANDS (PHP 1.5GB, Workers 762MB)

```bash
# Étape 1: Vérifier le cluster
bash scripts/pre-update-check.sh

# Étape 2: PRÉ-PULL l'image (~10-15 min, fait une seule fois!)
bash scripts/pre-pull-images.sh php  # ou workers

# Étape 3: Attendre que pré-pull se termine
# ... (prendre un café ☕)

# Étape 4: Update (3 min, image déjà présente)
bash scripts/update-php-safe.sh preprod latest

# Étape 5: Monitor
bash scripts/monitor-update.sh oo_php

# Résultat: Zéro downtime! ✅ (et plus rapide grâce à pré-pull)
```

---

## Rollback en Cas de Problème

```bash
# Rollback immédiat (revient à la version précédente)
docker service update --rollback <service_name>

# Vérifier le status
docker service ps <service_name>
```

---

## Monitoring (pendant l'update)

```bash
# Real-time monitoring(refresh auto)
bash scripts/monitor-update.sh <service_name>

# Ou manual:
docker service ps <service_name>      # Status des replicas
docker service logs <service_name>    # Logs du service
docker service inspect <service_name> # Infos détaillées
```

---

## Tableau Récapitulatif

| Service | Commande | Timing | Pré-pull? |
|---------|----------|--------|-----------|
| **PHP** | `bash scripts/update-php-safe.sh preprod latest` | 15min (pré-pull) + 3min (update) | ✅ OUI |
| **Nginx** | `docker service update --image ... oo_nginx` | ~5 min | ❌ Non |
| **Traefik** | `docker service update --image traefik:v3.6.11 traefik` | ~5 min | ❌ Non |
| **MariaDB** | `docker service update --image mariadb:11.4.9 oo_mariadb` | ~5 min | ❌ Non |
| **Workers** | `bash scripts/pre-pull-images.sh workers` puis update | 10min (pré-pull) + 3min (update) | ✅ OUI |

---

## Checkliste Rapide

### Avant Update
- [ ] `bash scripts/pre-update-check.sh` passe ✅
- [ ] Image correcte (nom, version)
- [ ] Backup recent pour DB
- [ ] Équipe disponible pour monitoring

### Pendant Update (si grosse image)
- [ ] Pré-pull lancé: `bash scripts/pre-pull-images.sh <service>`
- [ ] Attendre la fin (~10-15 min)
- [ ] Vérifier: `docker images | grep <service>`

### Update
- [ ] Commande executée
- [ ] Monitoring lancé: `bash scripts/monitor-update.sh <service>`
- [ ] Réplicas convergent progressivement

### Après Update
- [ ] `bash scripts/pre-update-check.sh` passe ✅
- [ ] Service répond correctement
- [ ] Logs sans erreurs: `docker service logs <service>`

---

## Troubleshooting Rapide

**Service reste en update (ne converge pas):**
```bash
# Voir pourquoi
docker service ps <service> --no-trunc

# Check les logs
docker service logs <service> --tail 20

# Rollback en dernier recours
docker service update --rollback <service>
```

**Erreur d'image:**
```bash
# Vérifier que l'image exists
docker pull ghcr.io/oneorthomedical/one-plateform-php8.1-fpm:latest

# Si pré-pull échoue (réseau?)
ssh docker@node1 docker pull <image>  # Test manual
```

---

## Pour Plus de Détails

- **Concept complet:** `CONCEPT.md`
- **Stratégie d'update:** `UPDATE_STRATEGY.md`
- **Procédure détaillée:** `ROLLING_UPDATES_PROCEDURE.md`
- **Commandes par service:** `UPDATE_SINGLE_SERVICE.md`
- **Répérence rapide:** `QUICK_REFERENCE.md`
