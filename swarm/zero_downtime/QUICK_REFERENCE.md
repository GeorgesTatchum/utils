# Quick Reference - Zero-Downtime Updates

## 🚀 Démarrage rapide

**💡 IMPORTANT:** Chaque service peut être mis à jour SEUL, indépendamment des autres!

### 1️⃣ Préparation (5 min)

```bash
cd /home/ubuntu/ansible
source scripts/.env.update.preprod

# Vérifier le cluster
bash scripts/pre-update-check.sh
```

### Choisissez le service à mettre à jour

**Exemple: Mettre à jour PHP SEULEMENT**

```bash
# Option 1: Script guidé
bash scripts/update-cluster.sh preprod web  # Met à jour PHP et Nginx (option "web")

# Option 2: Commandes manuelles
docker service update --image symfony:NEW oo_php  # PHP seul
```

**Ou:**

### 2️⃣ Update Workers seul (5 min)

```bash
docker service scale oo_app-simplification-bundle=3
sleep 60
docker service update --image bundle:NEW oo_app-simplification-bundle
sleep 90
docker service scale oo_app-simplification-bundle=1
```

### 3️⃣ Update PHP seul (10 min)

```bash
# Scale up pour HA
docker service scale oo_php=3
sleep 60

# Update
docker service update \
  --image symfony:NEW \
  --update-parallelism 1 \
  --update-delay 45s \
  oo_php

# Attendre convergence
sleep 90

# Scale down
docker service scale oo_php=2
```atabase seule (20 min)

```bash
# IMPORTANT: Vérifier backup AVANT
ls -lh /opt/backups/mariadb/

# Option 1: MINOR patch (11.4.8 → 11.4.9)
# Pause les services web qui accèdent à la DB
docker service update --replicas 0 oo_php
docker service update --replicas 0 oo_nginx
sleep 60

# Update DB
docker service update --image mariadb:NEW oo_mariadb
sleep 120

# Resume web
docker service update --replicas 2 oo_php
docker service update --replicas 2 oo_nginx

# Option 2: MAJOR version - Voir DEPLOYMENT_GUIDE.md Phase 4 Option B
docker service update --image traefik:NEW traefik
sleep 90
```

### 5️⃣ Update DB (20 min)

```bash
# IMPORTANT: Vérifier backup AVANT
ls -lh /opt/backups/mariadb/

# Puase web
docker service update --replicas 0 oo_php
sleep 60

# Update DB
docker service update --image mariadb:NEW oo_mariadb
sleep 120

# Resume web
docker service update --replicas 2 oo_php
```

---

## 📊 État de convergence

### Vérifier que tout est OK

```bash
# Quick health
docker service ls

# Détails par service
docker service ps traefik --no-trunc
docker service ps oo_php --no-trunc
docker service ps oo_nginx --no-trunc
```

**Tous doivent afficher:** `Replicas: X/X` avec state `Running`

---

## 🛠️ Commands essentielles

| Action | Commande |
|--------|----------|
| **Status** | `docker service ls` |
| **Tasks** | `docker service ps SERVICE` |
| **Logs** | `docker service logs SERVICE --tail 50` |
| **Update image** | `docker service update --image NEW SERVICE` |
| **Update replicas** | `docker service scale SERVICE=N` |
| **Rollback** | `docker service update --rollback SERVICE` |

---

## ⚠️ Points critiques

### DO ✅

- ✅ TOUJOURS backup DB avant update
- ✅ Update `parallelism: 1` (un à la fois)
- ✅ Vérifier health checks avant d'update
- ✅ Monitor pendant update
- ✅ Avoir plan B (rollback script)
- ✅ Notify users avant update
- ✅ Test configs en PREPROD d'abord

### DON'T ❌

- ❌ Ne JAMAIS `--force-update` sur DB
- ❌ Ne pas update plusieurs services simultanément
- ❌ Ne pas passer les health checks
- ❌ Ne pas réduire les replicas en dessous de 2 (web)
- ❌ Ne pas update sans backup DB
- ❌ Ne pas ignorer les convergence timeouts

---

## 📈 Status monitoring

### Logs en direct

```bash
# Terminal 1: Monitor Traefik
watch -n 2 'docker service ps traefik --no-trunc'

# Terminal 2: Monitor Web
watch -n 2 'docker service ps oo_php --no-trunc'

# Terminal 3: Follow traefik logs
docker service logs -f traefik
```

### État global

```bash
# Voir toutes les replicas
docker service ls --format "table {{.Name}}\t{{.Replicas}}\t{{.Image}}"

# Voir les erreurs
for svc in traefik oo_php oo_nginx oo_mariadb; do
  echo "=== $svc ==="
  docker service logs $svc --tail 5 | grep -i error || echo "OK"
done
```

---

## 🔄 Service-by-Service

### 1. WORKERS (Simplification Bundle)

```bash
# Augmenter pendant update
docker service scale oo_app-simplification-bundle=3

# Update
docker service update \
  --image $SIMPLIFICATION_IMAGE:$NEW_VERSION \
  --update-parallelism 1 \
  --update-delay 30s \
  oo_app-simplification-bundle

# Réduire après
docker service scale oo_app-simplification-bundle=1

# Check: tous les jobs continuent de s'exécuter
docker service logs oo_app-simplification-bundle --tail 20
```

**Raison:** Drainer les jobs en cours avant update

---

### 2. WEB: PHP-FPM

```bash
# Augmenter pour HA
docker service scale oo_php=3

# Update (parallelism 1, delay 45s pour connexions actives)
docker service update \
  --image $SYMFONY_IMAGE:$NEW_SYMFONY_VERSION \
  --update-parallelism 1 \
  --update-delay 45s \
  --update-failure-action rollback \
  oo_php

# Check: pas d'erreurs PHP
docker service ps oo_php --no-trunc | grep Running

# Réduire après
docker service scale oo_php=2
```

**Health:** `php-fpm -v` doit réussir

---

### 3. WEB: Nginx

```bash
# Update (après PHP-FPM!)
docker service update \
  --image $NGINX_IMAGE:$NEW_NGINX_VERSION \
  --update-parallelism 1 \
  --update-delay 45s \
  --update-failure-action rollback \
  oo_nginx

# Check: health endpoint responsive
docker exec $(docker ps --filter "label=com.docker.swarm.service.name=oo_nginx" -q | head -1) \
  wget --quiet --spider http://localhost/health
```

**Health:** HTTP 200 sur `/health`

---

### 4. TRAEFIK

```bash
# Update simple (déjà HA)
docker service update \
  --image traefik:$TRAEFIK_VERSION \
  --update-parallelism 1 \
  --update-delay 40s \
  --update-failure-action rollback \
  traefik

# Check: routing fonctionne
curl -H "Host: app.test" http://localhost/ | head -10

# Check health
docker exec $(docker ps --filter "label=com.docker.swarm.service.name=traefik" -q | head -1) \
  traefik healthcheck --ping
```

**Health:** `traefik healthcheck --ping` = OK

---

### 5. DATABASE (ATTENTION!)

#### Option A: Minor patch (11.4.8 → 11.4.9)

```bash
# 1. Backup OBLIGATOIRE
ssh docker@db1-preprod "docker exec oo_mariadb mysqldump \
  -uroot -p${MYSQL_ROOT_PASSWORD} --all-databases > /tmp/backup.sql"

# 2. Pause web (critical!)
docker service update --replicas 0 oo_php
docker service update --replicas 0 oo_nginx
sleep 60

# 3. Update
docker service update --image mariadb:11.4.9 oo_mariadb

# 4. Wait et check
sleep 120
docker exec oo_mariadb mysqladmin -uroot -p${MYSQL_ROOT_PASSWORD} version

# 5. Resume web
docker service update --replicas 2 oo_php
docker service update --replicas 2 oo_nginx
```

#### Option B: Major update (11.4 → 11.5)

```bash
# Voir DEPLOYMENT_GUIDE.md - Blue-Green deployment
# BEAUCOUP plus sûr pour major updates
```

---

## 🚨 En cas de problème

### Service doesn't converge

```bash
# 1. Voir les logs
docker service logs SERVICE_NAME --tail 100 | grep -i error

# 2. Voir l'état des tasks
docker service ps SERVICE_NAME --no-trunc

# 3. Si health check fail
docker exec ${CONTAINER_ID} bash -c "health check command"

# 4. Forcer update (tentative 2)
docker service update --force-update SERVICE_NAME

# 5. Rollback
docker service update --rollback SERVICE_NAME
```

### Rollback complet

```bash
# Un service
docker service update --rollback oo_php

# Tous
for svc in traefik oo_nginx oo_php oo_mariadb; do
  docker service update --rollback $svc
done

# Check
docker service ls
```

### DB corrupted

```bash
# STOP EVERYTHING
docker service update --replicas 0 oo_php
docker service update --replicas 0 oo_nginx
docker service update --replicas 0 oo_app-simplification-bundle

# SSH sur DB node
ssh docker@db1-preprod

# Check/fix
docker exec oo_mariadb mysqladmin status
docker exec oo_mariadb mysql -p${MYSQL_ROOT_PASSWORD} -e "SHOW DATABASES;"

# Restore si nécessaire
docker exec oo_mariadb mysql -p${MYSQL_ROOT_PASSWORD} < /opt/backups/mariadb/backup.sql

# Resume
docker service update --replicas 1 oo_php
docker service update --replicas 2 oo_nginx
```

---

## ✅ Validation post-update

```bash
#!/bin/bash

echo "=== Post-Update Checks ==="

# 1. Replicas convergent
echo "1. Service status:"
docker service ls

# 2. No errors in logs
echo ""
echo "2. Recent errors:"
for svc in traefik oo_php oo_nginx oo_mariadb; do
  errors=$(docker service logs $svc --tail 100 | grep -i "error\|critical" | wc -l)
  echo "  $svc: $errors errors"
done

# 3. Test application
echo ""
echo "3. Application test:"
curl -s -w "%{http_code}" -o /dev/null http://localhost/
echo " (should be 200/301)"

# 4. Test database
echo ""
echo "4. Database test:"
docker exec oo_mariadb mysqladmin -uroot -p${MYSQL_ROOT_PASSWORD} version | head -1

# 5. Test worker
echo ""
echo "5. Worker test:"
docker service logs oo_app-simplification-bundle --tail 5

echo ""
echo "✓ If all green: Update successful!"
```

---

## 📞 Support rapide

| Problème | Solution |
|----------|----------|
| Service pas converge | Voir logs, check health check, rollback |
| Erreur application | Rollback, comparer versions |
| DB not accessible | SSH sur node DB, check mysql, restore backup |
| Traefik pas route | Vérifier health, check labels, redeploy |
| Performance dégradée | Check CPU/mem, rollback, profile |

---

## 📚 Documentation complète

- `ROLLING_UPDATES_PROCEDURE.md` - Procédure détaillée (25+ pages)
- `DEPLOYMENT_GUIDE.md` - Étapses de déploiement
- `docker-compose.yml.j2.zero-downtime` - Fichiers optimisés
- `scripts/` - Scripts automation prêts à utiliser

---

## 🎯 Résumé des 10 règles d'or

1. **BACKUP DB avant CHAQUE update**
2. **Update parallelism TOUJOURS = 1**
3. **Health checks OBLIGATOIRES sur tous**
4. **Minimum 2 replicas pour web/traefik**
5. **DB = TOUJOURS 1 seule réplica**
6. **Notifications clients AVANT update**
7. **Monitor PENDANT update (logs/services)**
8. **Rollback script toujours disponible**
9. **Test en PREPROD en premier**
10. **Documentation à jour = santé du cluster**

---

## 📅 Timing guide

| Étape | Durée | Total |
|-------|-------|-------|
| Préparation | 5 min | 5 min |
| Workers | 8 min | 13 min |
| Web (PHP+Nginx) | 15 min | 28 min |
| Traefik | 10 min | 38 min |
| Database | 15 min | 53 min |
| Post-checks | 5 min | **58 min** |

**Durée totale: ~1 heure** (avec timeouts généreux)

