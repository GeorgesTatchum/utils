# 🎯 Mise à jour service par service - Guide complet

## 📌 Concept clé

**Vous pouvez mettre à jour CHAQUE SERVICE INDÉPENDAMMENT, sans toucher aux autres!**

```
Quand vous updatez PHP:
  ✅ PHP est updaté (0 downtime pour PHP)
  ✅ Nginx reste up (continue à router)
  ✅ Traefik reste up (continue entry point)
  ✅ DB reste up (reste accessible)
  ✅ Users continuent à naviguer normalement!

Les opérations utilisateurs en cours continuent
car Nginx, Traefik et DB ne sont pas affectés.
```

---

## 🛠️ Updater UN SERVICE INDIVIDUEL

### Option 1: Script guidé (Recommandé)

```bash
# Update WORKERS seul
bash scripts/update-cluster.sh preprod workers

# Update WEB (PHP + Nginx ensemble, ou séparément)
bash scripts/update-cluster.sh preprod web

# Update TRAEFIK seul
bash scripts/update-cluster.sh preprod traefik

# Update DB seule
bash scripts/update-cluster.sh preprod db
```

**Le script:**
- Confirmera avant de faire l'update
- Fera les checks de santé
- Monitorer les replicas
- Confirmera la completion

### Option 2: Commandes docker manuelles (Plus de contrôle)

Voir ci-dessous par service.

---

## 📋 PAR SERVICE

### 1. UPDATER PHP SEUL

```bash
# Vérifier l'état actuel
docker service ls --filter name=oo_php

# 1. Scale up PHP (pour HA durant update)
docker service scale oo_php=3

# 2. Attendre stabilisation
echo "Waiting for 3 replicas to start..."
sleep 60

# 3. Update image
docker service update \
  --image symfony:NEW_VERSION \
  --update-parallelism 1 \
  --update-delay 45s \
  --update-failure-action rollback \
  oo_php

# 4. Monitor update (dans un autre terminal)
bash scripts/monitor-update.sh oo_php

# 5. Scale down to normal (2 replicas)
docker service scale oo_php=2

# Vérifier
docker service ls --filter name=oo_php
docker service ps oo_php --no-trunc
```

**Résultat:**
- ✅ PHP updaté avec zéro downtime
- ✅ Ancien PHP a fermé gracieusement
- ✅ Nouveau PHP a démarré
- ✅ Nginx et Traefik ont continué à fonctionner normalement
- ✅ Users ne voient RIEN

---

### 2. UPDATER NGINX SEUL

```bash
# Vérifier l'état
docker service ls --filter name=oo_nginx

# Nginx a déjà 2+ replicas, pas besoin de scale

# Update image (rolling, 1 par 1)
docker service update \
  --image nginx:NEW_VERSION \
  --update-parallelism 1 \
  --update-delay 45s \
  --update-failure-action rollback \
  oo_nginx

# Monitor
bash scripts/monitor-update.sh oo_nginx

# Vérifier
docker service ps oo_nginx --no-trunc
```

**Résultat:**
- ✅ Nginx updaté
- ✅ Toujours 2+ replicas running
- ✅ Routing jamais interruption
- ✅ PHP et Traefik non affectés

---

### 3. UPDATER TRAEFIK SEUL

```bash
# Vérifier
docker service ls --filter name=traefik

# Update (simple, déjà HA)
docker service update \
  --image traefik:NEW_VERSION \
  --update-parallelism 1 \
  --update-delay 40s \
  --update-failure-action rollback \
  traefik

# Monitor
bash scripts/monitor-update.sh traefik

# Vérifier routing fonctionne
curl -I http://localhost/

# Vérifier
docker service ps traefik --no-trunc
```

**Résultat:**
- ✅ Traefik updaté
- ✅ Entry point jamais down
- ✅ PHP et Nginx non affectés
- ✅ DNS routing continue

---

### 4. UPDATER DATABASE SEULE

⚠️ **Database = CRITIQUE. 2 options selon version:**

#### Option A: MINOR patch (11.4.8 → 11.4.9) - SÛRE

```bash
# BACKUP OBLIGATOIRE!
ssh docker@db1-preprod "docker exec oo_mariadb mysqldump \
  -uroot -p${MYSQL_ROOT_PASSWORD} \
  --all-databases > /tmp/db_backup_$(date +%s).sql"

# 1. Pause les services qui accèdent à la DB
docker service update --mode replicated --replicas 0 oo_php
docker service update --mode replicated --replicas 0 oo_nginx
docker service update --mode replicated --replicas 0 oo_app-simplification-bundle

# 2. Attendre que les connexions se ferment
echo "Waiting for DB connections to close..."
sleep 60

# 3. Update DB
docker service update \
  --image mariadb:NEW_VERSION \
  --update-failure-action pause \
  oo_mariadb

# 4. Attendre quelques secondes puis check
sleep 30
docker exec oo_mariadb mysqladmin -uroot -p${MYSQL_ROOT_PASSWORD} version

# 5. Resume services
docker service update --replicas 2 oo_php
docker service update --replicas 2 oo_nginx
docker service update --replicas 1 oo_app-simplification-bundle

# Vérifier
docker service ls
docker service ps oo_mariadb --no-trunc
```

**Résultat:**
- ✅ DB updaté
- ✅ Migration réussie
- ✅ Zéro corruption
- ✅ Services resumés

#### Option B: MAJOR version (11.4 → 12.0) - PLUS SÛR

**Voir DEPLOYMENT_GUIDE.md - Phase 4 Option B (Blue-Green Deployment)**

---

### 5. UPDATER WORKERS SEUL

```bash
# Vérifier
docker service ls --filter name=app-simplification

# 1. Scale up pour drainer les jobs en cours
docker service scale oo_app-simplification-bundle=3

# 2. Attendre stabilisation
sleep 60

# 3. Update
docker service update \
  --image simplification-bundle:NEW_VERSION \
  --update-parallelism 1 \
  --update-delay 30s \
  --update-failure-action rollback \
  oo_app-simplification-bundle

# 4. Monitor
bash scripts/monitor-update.sh oo_app-simplification-bundle

# 5. Scale down
docker service scale oo_app-simplification-bundle=1

# Vérifier
docker service ps oo_app-simplification-bundle --no-trunc
```

**Résultat:**
- ✅ Workers updatés
- ✅ Jobs drainés avant update
- ✅ Zéro job lost
- ✅ Web services non affectés

---

## 🎯 Scénarios d'utilisation

### Scénario 1: Mettre à jour PHP pour bug fix

```bash
# 1. Check it's safe
bash scripts/pre-update-check.sh

# 2. Update PHP
docker service scale oo_php=3 && sleep 60 && \
docker service update --image symfony:8.2.1 oo_php && \
sleep 90 && \
docker service scale oo_php=2

# 3. Verify
curl http://app.test/health
```

**Utilisateurs:** Aucun impact visible!

---

### Scénario 2: Mettre à jour Traefik pour nouvelle config

```bash
# Traefik seul, très sûr
docker service update --image traefik:v3.7.0 traefik && \
sleep 30 && \
curl -I http://localhost/
```

**Utilisateurs:** Pas de downtime, pas d'erreur!

---

### Scénario 3: Mettre à jour DB pour performance

```bash
# 1. Backup
ssh docker@db1-preprod "mysqldump ... > /backup.sql"

# 2. Pause web (car elle dépend de la DB)
docker service scale oo_php=0
docker service scale oo_nginx=0
sleep 30

# 3. Update DB (in-place pour minor version)
docker service update --image mariadb:11.5.0 oo_mariadb
sleep 60

# 4. Resume web
docker service scale oo_php=2

# 5. Test
curl http://app.test/
```

**Utilisateurs:** Très court downtime (< 2 min) car seule la DB était affectée!

---

### Scénario 4: Mettre à jour plusieurs services (au fil du temps)

```
Jour 1: Update PHP
  bash scripts/update-cluster.sh preprod web
  (Nginx sera inclus - vous pouvez le faire ensemble ou séparer)

Jour 5: Update Traefik
  bash scripts/update-cluster.sh preprod traefik

Jour 10: Update DB (après avoir testé PHP/Traefik)
  bash scripts/update-cluster.sh preprod db

Chaque update = 10-60 min, UNE SEULE à la fois
Users never see any problem!
```

---

## ⚠️ Pièges à éviter

### ❌ DON'T

```bash
# ❌ Ne pas mettre à jour PHP et Nginx simultanément
#    (sauf si vous le faites avec le script guidé)

# ❌ Ne pas update DB avant de terminer le web update
#    (risque de corruption pendant la migration)

# ❌ Ne pas oublier de vérifier health check après update
docker service ps SERVICE --no-trunc | grep healthy

# ❌ Ne pas update sans backup DB
ls -lh /opt/backups/mariadb/

# ❌ Ne pas ignorer les replicas (min 2 pour web/traefik)
docker service ls | grep "Replicas"
```

### ✅ DO

```bash
# ✅ Vérifier avant chaque update
bash scripts/pre-update-check.sh

# ✅ Update 1 service à la fois
bash scripts/update-cluster.sh preprod [service]

# ✅ Monitor durant update
bash scripts/monitor-update.sh [service] &

# ✅ Attendre convergence avant prochaine update
docker service ls | watch

# ✅ Documenter les updates
# (Voir CHECKLISTS.md pour formulaire)
```

---

## 🔍 Vérifier chaque update

```bash
# Après chaque update, vérifier:

# 1. Service convergible?
docker service ps SERVICE --no-trunc | grep "Running"

# 2. Health check OK?
docker service ps SERVICE --no-trunc | grep "healthy"

# 3. Logs propres?
docker service logs SERVICE --tail 20

# 4. Application fonctionne?
curl http://app.test/health

# 5. Pas d'erreurs utilisateurs?
# Contact vos users ou vérifier monitoring
```

---

## 🆘 Si quelque chose échoue

### Service ne converge pas

```bash
# 1. Voir ce qui se passe
docker service logs SERVICE --tail 50

# 2. Voir les replicas en erreur
docker service ps SERVICE --no-trunc

# 3. Rollback optionnel
bash scripts/rollback.sh SERVICE
```

### DB inaccessible après update

```bash
# 1. Stop web
docker service scale oo_php=0

# 2. Check DB
docker exec oo_mariadb mysql -uroot version

# 3. Si corrupted, restore
docker exec oo_mariadb mysql -uroot < /backup.sql

# 4. Resume web
docker service scale oo_php=2
```

### Users report errors after update

```bash
# 1. Immediate rollback
bash scripts/rollback.sh SERVICE

# 2. Check logs
docker service logs SERVICE --tail 100 | grep -i error

# 3. Analyze what went wrong
# (See DEPLOYMENT_GUIDE.md - Dépannage)
```

---

## 📊 Template pour vous

**À utiliser chaque fois que vous updatez un service:**

```bash
#!/bin/bash
SERVICE="oo_php"
NEW_VERSION="8.2.1"

echo "🚀 Starting update of $SERVICE to $NEW_VERSION"

# Pre-checks
bash scripts/pre-update-check.sh || exit 1

# Backup if DB
if [ "$SERVICE" == "oo_mariadb" ]; then
  echo "Backing up database..."
  ssh docker@db1-preprod "mysqldump ... > /bak.sql"
fi

# Scale up if needed
case $SERVICE in
  oo_php)
    docker service scale oo_php=3
    sleep 60
    ;;
esac

# Update
docker service update --image custom:${NEW_VERSION} $SERVICE \
  --update-parallelism 1 \
  --update-delay 45s \
  --update-failure-action rollback

# Monitor
bash scripts/monitor-update.sh $SERVICE

# Scale down if needed
case $SERVICE in
  oo_php)
    docker service scale oo_php=2
    ;;
esac

# Verify
echo "✅ Update complete, verifying..."
curl http://app.test/health

echo "✅ Success!"
```

---

## 🎉 Résumé

**Vous pouvez maintenant:**

✅ Update **PHP seul** (Nginx reste up)  
✅ Update **Nginx seul** (PHP reste up)  
✅ Update **Traefik seul** (tout reste up)  
✅ Update **DB seuls** (web pauses, resume après)  
✅ Update **Workers seuls** (web non affectés)  

**Chaque update = 0% downtime pour ce service!**

---

**Besoin d'aide?** Consultez [QUICK_REFERENCE.md](QUICK_REFERENCE.md) ou [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)

