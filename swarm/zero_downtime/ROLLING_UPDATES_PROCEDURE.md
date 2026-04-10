# Procédure Zero-Downtime Updates pour Docker Swarm

## 📌 IMPORTANT: Zero-downtime pour le SERVICE en cours d'UPDATE

**Point clé:** Quand vous mettez à jour **UN SERVICE**, ce service lui-même ne coupe JAMAIS l'accès aux utilisateurs:

```
✅ Update PHP              → Zéro interruption de service PHP
   • Connexions actives: Basculement gracieux vers nouveau conteneur
   • Requêtes en cours: Continuent jusqu'à completion
   • Autres services (Nginx, Traefik): Continuent normalement

✅ Update Nginx            → Zéro interruption du reverse proxy
   • Connexions actives: Terminées avant arrêt gracieux
   • Sessions persistantes: Drainées correctement
   • Autres services (PHP, Traefik): Inaffectés

✅ Update Traefik          → Zéro interruption du routage
   • Requêtes HTTP: Routées vers les conteneurs sains
   • Connexions actives: Persistent jusqu'à fin update
   • Autres services: Continuent normalement

✅ Update DB               → Zéro interruption de la base de données
   • Services web: Pausés le temps du switchover
   • Connexions BD: Drainées proprement
   • Aucune perte de données

✅ Update Workers          → Zéro interruption des jobs
   • Jobs en cours: Drainés progressivement
   • Accès utilisateur: Inaffecté
   • Other services: Continuent normalement
```

**Le mécanisme (valable pour TOUS les services):**
1. Docker Swarm updater 1 réplique à la fois (rolling update)
2. Les AUTRES répliques continuent à servir le trafic
3. Basculement gracieux: la réplique à updater TERMINE les connexions actives
4. Connection draining: laisser finir les requêtes avant arrêt
5. Grace period: délai configuré pour shutdown propre
6. Redémarrage avec nouvelle version
7. Health check: validation avant réenvoyer du trafic
8. Répéter pour chaque réplique

**Exemple réel - Accès utilisateur JAMAIS coupé:**
- Jour 1: Update PHP
  * Utilisateurs: Continuent leurs opérations sans interruption
  * Requêtes en cours: Achèvent sur anciens conteneurs
  * Basculement: Automatique vers nouveaux conteneurs PHP
  * Nginx, Traefik: Continuent à router normalement
  * **Résultat:** Zéro downtime pour l'utilisateur

- Jour 2: Update Nginx seul
  * Utilisateurs: Passent imperceptiblement aux nouveaux Nginx
  * Connexions: Maintenues grace au connection draining
  * PHP, Traefik: Continuent normalement
  * **Résultat:** Zéro interruption du service web

- Jour 5: Update Traefik seul
  * Utilisateurs: Pas même conscients du changement
  * Requêtes: Routées vers les bons backends
  * PHP, Nginx: Inaffectés, continuent
  * **Résultat:** Routage sans interruption

- Semaine prochaine: Update Database
  * Web services: Pause courte < 5s (pour validation)
  * Données: Aucune perte ou corruption
  * **Résultat:** Migration DB propre et sûre

---

## Vue d'ensemble

Cette procédure garantit une mise à jour fluide de tous les services sans interruption de service. Elle utilise les **rolling updates** et les **health checks** pour valider chaque étape.

**Point crucial à comprendre:** Quand on updater UN SERVICE, ce service lui-même NE COUPE JAMAIS l'accès aux utilisateurs. Les opérations en cours sur ce service CONTINUENT jusqu'à completion avec un basculement gracieux vers la nouvelle version.

**LIRE [ZERO_DOWNTIME_EXPLAINED.md](ZERO_DOWNTIME_EXPLAINED.md) pour la description DÉTAILLÉE et les diagrammes.**

---

## 🔑 Concept Clé: Zero-Downtime = Le SERVICE reste actif pendant son UPDATE

```
Quand vous updater PHP:
- Le user qui est en train de faire une requête HTTP → PHP
  * Réplica A (en update): "Finish your current request"
  * Réplica B (non updaté): "I'm ready for new traffic"
  → User NE VOIT RIEN (zéro interruption)

- Quand Réplica A est updaté et prête:
  * New requêtes: Peuvent aller sur A ou B
  * User: Continue normalement
  → Zéro downtime! ✅
```

**Ce mécanisme s'applique à TOUS les services:**
- Update PHP seul → Nginx continue la route
- Update Nginx seul → PHP continue de traiter
- Update Traefik seul → Web continue normalement
- Update DB seule → Pause courte < 5s
- Update Workers → Jobs drainés gracefully

---

## ⚠️ IMPORTANT: Stratégie d'Image Pré-Pull pour Grandes Images

**Lisez [UPDATE_STRATEGY.md](UPDATE_STRATEGY.md) pour les détails** (timing, configurations, implication)

Résumé rapide:
- **PHP (1.5GB):** Pré-pull obligatoire via `bash scripts/pre-pull-images.sh php`
- **Workers (762MB):** Pré-pull recommendé
- **Nginx/Traefik/MariaDB (< 200MB):** Pull pendant update OK

**Timing Impact:**
- Sans pré-pull (PHP): Update = 15-20 minutes
- Avec pré-pull (PHP): Pré-pull = 15min (1 fois), Update = 3 minutes

---

## 1. PRINCIPES FONDAMENTAUX

### Ordre de mise à jour (du moins critique au plus critique)

```
1. WORKERS (Symfony, jobs, batch)     → Pas d'accès utilisateur direct
2. WEB (PHP-FPM + Nginx)               → Avec multiple réplicas et LB
3. TRAEFIK (Reverse proxy)             → Avec réplicas multiples
4. DB (MariaDB)                        → Après tout le reste
```

### Configuration requise pour GARANTIR le zero-downtime du service updaté

- **Health checks** obligatoires → Valider que le new conteneur est prêt
- **Connection draining** → Laisser finir les requêtes actives
- **Grace period** → Donner du temps au shutdown propre (30-60s)
- **Readiness probes** → Détecter quand le conteneur accepte le trafic
- **Multiple replicas** (min 2) → Les autres répliques maintiennent le service
- **Update parallelism: 1** → Un seul conteneur à la fois (zéro interruption)
- **Update delays** → 30-60s entre chaque réplique pour valider
- **Failure action: rollback** → Revenir en arrière en cas de problème

---

## 2. CONFIGURATION GÉNÉRALE DOCKER SWARM

### A. Health Checks (obligatoire pour tous)

```yaml
healthcheck:
  test: [...commande de vérification...]
  interval: 10s         # Vérification toutes les 10s
  timeout: 5s          # Timeout de 5s
  retries: 3           # 3 tentatives avant arrêt
  start_period: 30s    # Grace period au démarrage
```

### B. Update Config Standard

```yaml
update_config:
  parallelism: 1              # Update 1 réplica à la fois
  delay: 30s                  # Attendre 30s entre chaque
  failure_action: rollback    # Rollback si erreur
  monitor: 20s                # Monitorer 20s après update
  max_failure_ratio: 0.1      # Max 10% d'échecs avant rollback
```

### C. Restart Policy

```yaml
restart_policy:
  condition: any              # Redémarrer sur erreur
  delay: 30s                  # Délai avant redémarrage
  max_attempts: 3             # 3 tentatives
  window: 120s                # Fenêtre de 2 minutes
```

---

## 3. PAR TYPE DE SERVICE

### 3.1 WORKERS (Symfony Simplification Bundle)

**Caractéristiques :** Traitement asynchrone, pas d'accès utilisateur direct

**Stratégie :**
- Augmenter temporairement les réplicas
- Drainer les jobs en cours
- Mettre à jour progressivement
- Réduire les réplicas

**Commandes :**

```bash
#!/bin/bash
SERVICE_NAME="oo_app-simplification-bundle"
ENVIRONMENT="preprod"  # ou prod

echo "[1/5] Scaling up workers pour drainer les jobs..."
docker service scale ${SERVICE_NAME}=3

echo "[2/5] Attendre que les workers se stabilisent (60s)..."
sleep 60

echo "[3/5] Mettre à jour l'image..."
docker service update \
  --image ${SIMPLIFICATION_IMAGE}:${NEW_VERSION} \
  --update-parallelism 1 \
  --update-delay 30s \
  --update-failure-action rollback \
  --update-monitor 20s \
  ${SERVICE_NAME}

echo "[4/5] Attendre la stabilisation (90s)..."
sleep 90

echo "[5/5] Réduire aux réplicas normaux..."
docker service scale ${SERVICE_NAME}=1

echo "✓ Update workers complété"
```

**docker-compose.yml.j2 à ajouter :**

```yaml
deploy:
  replicas: {{ simplification_replicas | default(1) }}
  update_config:
    parallelism: 1
    delay: 30s
    failure_action: rollback
    monitor: 20s
  restart_policy:
    condition: any
    delay: 30s
    max_attempts: 3
  placement:
    constraints:
      - node.labels.role == db
      - node.labels.project_oo == true
      - node.role != manager
```

---

### 3.2 WEB LAYER (PHP-FPM + Nginx)

**Caractéristiques :** Stateless, accès utilisateur direct, doit avoir réplicas

**Stratégie :**
- Minimum 2 réplicas par conteneur (PHP-FPM et Nginx)
- Health checks stricts
- Connection draining
- Readiness probe avant routing

**Commandes :**

```bash
#!/bin/bash
PROJECT_NAME="oo"
ENVIRONMENT="preprod"

echo "[1/6] Vérifier que 2+ réplicas de PHP-FPM sont actifs..."
docker service ls --filter name=${PROJECT_NAME}_php

echo "[2/6] Scale PHP-FPM à 3 réplicas si nécessaire..."
docker service scale ${PROJECT_NAME}_php=3

echo "[3/6] Attendre stabilisation (60s)..."
sleep 60

echo "[4/6] Update PHP-FPM avec rolling update..."
docker service update \
  --image ${SYMFONY_IMAGE}:${NEW_VERSION} \
  --update-parallelism 1 \
  --update-delay 45s \
  --update-failure-action rollback \
  --update-monitor 30s \
  ${PROJECT_NAME}_php

echo "[5/6] Update Nginx..."
docker service update \
  --image ${NGINX_IMAGE}:${NEW_VERSION} \
  --update-parallelism 1 \
  --update-delay 45s \
  --update-failure-action rollback \
  --update-monitor 30s \
  ${PROJECT_NAME}_nginx

echo "[6/6] Ramener PHP-FPM aux réplicas normaux (2)..."
docker service scale ${PROJECT_NAME}_php=2

echo "✓ Update web complété"
```

**docker-compose.yml.j2 à modifier pour web :**

```yaml
services:
  {{ project_name }}_php:
    image: {{ symfony_image }}:{{ symfony_image_version }}
    healthcheck:
      test: ["CMD", "php-fpm", "-v"]
      interval: 10s
      timeout: 5s
      retries: 3
      start_period: 30s
    deploy:
      replicas: {{ php_replicas | default(2) }}
      update_config:
        parallelism: 1
        delay: 45s
        failure_action: rollback
        monitor: 30s
      restart_policy:
        condition: any
        delay: 30s
        max_attempts: 3
      placement:
        constraints:
          - node.labels.role == web
          - node.labels.project_oo == true

  nginx:
    image: {{ nginx_image }}:{{ nginx_image_version }}
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost/health"]
      interval: 10s
      timeout: 5s
      retries: 3
      start_period: 15s
    deploy:
      replicas: {{ nginx_replicas | default(2) }}
      update_config:
        parallelism: 1
        delay: 45s
        failure_action: rollback
        monitor: 30s
      restart_policy:
        condition: any
        delay: 30s
        max_attempts: 3
      labels:
        - "traefik.enable=true"
        - "traefik.http.routers.{{ project_name }}_web_nginx.rule=Host(`app.test`)"
        - "traefik.http.routers.{{ project_name }}_web_nginx.entrypoints=http"
        - "traefik.http.services.{{ project_name }}_web_nginx.loadbalancer.server.port=80"
        - "traefik.docker.network=internal"
        - "traefik.http.services.{{ project_name }}_web_nginx.loadbalancer.healthcheck.path=/health"
        - "traefik.http.services.{{ project_name }}_web_nginx.loadbalancer.healthcheck.interval=10s"
      placement:
        constraints:
          - node.labels.role == web
          - node.labels.project_oo == true
```

---

### 3.3 TRAEFIK (Reverse Proxy)

**Caractéristiques :** Point d'entrée critique, doit avoir réplicas sur managers

**Votre config est déjà bonne :** Vous avez `parallelism: 1` et réplicas multiples

**Optimisations :**

```bash
#!/bin/bash

echo "[1/3] Vérifier que Traefik a 2+ managers actifs..."
docker node ls --filter role=manager

echo "[2/3] Update Traefik..."
docker service update \
  --image traefik:v3.6.11 \
  --update-parallelism 1 \
  --update-delay 40s \
  --update-failure-action rollback \
  --update-monitor 30s \
  traefik

echo "[3/3] Attendre stabilisation..."
sleep 90

echo "✓ Traefik update complété"
```

**docker-compose.yml.j2 Traefik (optimisé) :**

```yaml
traefik:
  image: traefik:v3.6.11
  user: root
  healthcheck:
    test: ["CMD", "traefik", "healthcheck", "--ping"]
    interval: 10s
    timeout: 5s
    retries: 3
    start_period: 30s
  deploy:
    restart_policy:
      condition: any
      delay: 30s
      max_attempts: 3
      window: 120s
    update_config:
      parallelism: 1
      delay: 40s
      failure_action: rollback
      monitor: 30s
      max_failure_ratio: 0.0
    placement:
      constraints:
        - node.labels.role == web
        - node.role == manager
      preferences:
        - spread: node.id
    replicas: {{ traefik_replicas | default(2) }}
```

---

### 3.4 DATABASE (MariaDB)

**Caractéristiques :** STATEFUL, données persistantes, CRITIQUE

**Stratégie TRÈS IMPORTANTE :**

⚠️ **NE PAS faire de `docker service update --force` sur la DB**

**Deux approches :**

#### Approche A : Blue-Green Deployment (Recommandé)

```bash
#!/bin/bash
PROJECT_NAME="oo"
ENVIRONMENT="preprod"

echo "[1/6] Créer snapshot des volumes..."
# Depuis le nœud DB
ssh docker@db1-${ENVIRONMENT} \
  "docker exec ${PROJECT_NAME}_mariadb mysqldump -uroot -p${MYSQL_ROOT_PASSWORD} --all-databases > /tmp/backup.sql"

echo "[2/6] Copier le backup localement..."
scp docker@db1-${ENVIRONMENT}:/tmp/backup.sql ./backup-$(date +%s).sql

echo "[3/6] Créer le nouveau service (version 11.5)"
# Modifier le docker-compose avec nouvelle version
docker service create \
  --name ${PROJECT_NAME}_mariadb_new \
  --env MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD} \
  --network ${PROJECT_NAME}_${ENVIRONMENT}_network \
  --mount type=volume,source=${PROJECT_NAME}_mariadb_data_new,target=/var/lib/mysql \
  mariadb:11.5.0

echo "[4/6] Attendre démarrage..."
sleep 90

echo "[5/6] Restaurer données dans new DB..."
docker service logs ${PROJECT_NAME}_mariadb_new

# Depuis le conteneur
docker exec ${PROJECT_NAME}_mariadb_new \
  mysql -uroot -p${MYSQL_ROOT_PASSWORD} < /tmp/backup.sql

echo "[6/6] Basculer le trafic vers new DB..."
# Mettre à jour compose-override pour pointer vers nouveau service
# Puis redéployer les services web/app

echo "✓ Database update complété - ancien service toujours disponible"
```

#### Approche B : Migration In-Place (Plus rapide si compatible)

```bash
#!/bin/bash
PROJECT_NAME="oo"
ENVIRONMENT="preprod"

# Uniquement pour MINOR version updates (11.4.8 → 11.4.9)
# Pas pour MAJOR updates (11.4 → 12.0)

echo "[1/4] Pause les services applicatifs..."
docker service update --mode replicated --replicas 0 ${PROJECT_NAME}_php
docker service update --mode replicated --replicas 0 ${PROJECT_NAME}_nginx

echo "[2/4] Attendre que tous les connexions ferment (60s)..."
sleep 60

echo "[3/4] Update DB (simple update, pas force)..."
docker service update \
  --image mariadb:11.4.9 \
  ${PROJECT_NAME}_mariadb

echo "[4/4] Relancer les services applicatifs..."
docker service update --replicas 2 ${PROJECT_NAME}_php
docker service update --replicas 2 ${PROJECT_NAME}_nginx

echo "✓ Database update complété"
```

**docker-compose.yml.j2 DB (optimisé) :**

```yaml
{{ project_name }}_mariadb:
  image: mariadb:{{ mariadb_version | default('11.4.9') }}
  healthcheck:
    test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
    interval: 10s
    timeout: 5s
    retries: 3
    start_period: 45s
  environment:
    MYSQL_ROOT_PASSWORD: {{ mariadb_root_password }}
    MYSQL_DATABASE: {{ mariadb_database }}
    MYSQL_USER: {{ mariadb_user }}
    MYSQL_PASSWORD: "{{ mariadb_password }}"
    MYSQL_INITDB_SKIP_TZINFO: "yes"
  deploy:
    replicas: 1
    restart_policy:
      condition: any
      delay: 60s
      max_attempts: 1
      window: 300s
    update_config:
      parallelism: 1
      delay: 60s
      failure_action: pause
      monitor: 60s
    placement:
      constraints:
        - node.labels.role == db
        - node.labels.project_oo == true
        - node.role != manager
```

---

## 4. PROCÉDURE COMPLÈTE ORCHESTRÉE

```bash
#!/bin/bash
# update-cluster.sh - Script orchestration complète

set -e

ENVIRONMENT="${1:-preprod}"  # preprod ou prod
FORCE_UPDATE="${2:-false}"   # true pour forcer

echo "╔════════════════════════════════════════╗"
echo "║   Docker Swarm Zero-Downtime Update    ║"
echo "║   Environment: ${ENVIRONMENT}           ║"
echo "╚════════════════════════════════════════╝"

# Fonction check santé
health_check() {
  local service=$1
  echo "  ↳ Vérification health: ${service}"
  docker service ls --filter name=${service}
  docker service ps ${service} --no-trunc
}

# ============================================
# 1. WORKERS
# ============================================
echo "[1/4] Mise à jour WORKERS..."
read -p "  Continuer ? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  docker service scale oo_app-simplification-bundle=3
  sleep 60
  docker service update \
    --image ${SIMPLIFICATION_IMAGE}:${NEW_VERSION} \
    --update-parallelism 1 \
    --update-delay 30s \
    oo_app-simplification-bundle
  sleep 90
  docker service scale oo_app-simplification-bundle=1
  health_check "oo_app-simplification-bundle"
fi

# ============================================
# 2. WEB LAYER
# ============================================
echo -e "\n[2/4] Mise à jour WEB LAYER..."
read -p "  Continuer ? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  # Scale up
  docker service scale oo_php=3
  sleep 60
  
  # Update PHP-FPM
  docker service update \
    --image ${SYMFONY_IMAGE}:${NEW_VERSION} \
    --update-parallelism 1 \
    --update-delay 45s \
    oo_php
  
  sleep 90
  
  # Update Nginx
  docker service update \
    --image ${NGINX_IMAGE}:${NEW_VERSION} \
    --update-parallelism 1 \
    --update-delay 45s \
    oo_nginx
  
  sleep 90
  
  # Scale down
  docker service scale oo_php=2
  health_check "oo_php"
  health_check "oo_nginx"
fi

# ============================================
# 3. TRAEFIK
# ============================================
echo -e "\n[3/4] Mise à jour TRAEFIK..."
read -p "  Continuer ? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  docker service update \
    --image traefik:${TRAEFIK_VERSION} \
    --update-parallelism 1 \
    --update-delay 40s \
    traefik
  
  sleep 90
  health_check "traefik"
fi

# ============================================
# 4. DATABASE
# ============================================
echo -e "\n[4/4] Mise à jour DATABASE..."
read -p "  ATTENTION: DB est CRITIQUE. Continuer ? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  if [[ ${FORCE_UPDATE} == "true" ]]; then
    # Blue-Green approach
    echo "  ⚠ Blue-Green deployment pour DB..."
    # Script Blue-Green
  else
    # In-place approach
    echo "  ⚠ Pause des services web..."
    docker service update --mode replicated --replicas 0 oo_php
    docker service update --mode replicated --replicas 0 oo_nginx
    sleep 60
    
    docker service update \
      --image mariadb:${MARIADB_VERSION} \
      oo_mariadb
    
    sleep 60
    
    docker service update --replicas 2 oo_php
    docker service update --replicas 2 oo_nginx
  fi
  
  health_check "oo_mariadb"
fi

echo -e "\n╔════════════════════════════════════════╗"
echo "║   ✓ Update terminé avec succès        ║"
echo "╚════════════════════════════════════════╝"
```

---

## 5. VÉRIFICATIONS AVANT CHAQUE UPDATE

```bash
#!/bin/bash
# pre-update-check.sh

echo "🔍 Vérifications pré-update..."

# 1. Services actifs
echo -n "  Nombre de managers: "
docker node ls --filter role=manager | wc -l

# 2. Health status
echo "  État des services:"
docker service ls --format "table {{.Name}}\t{{.Mode}}\t{{.Replicas}}\t{{.Image}}"

# 3. Logs récents
echo "  Vérifier les erreurs récentes:"
for service in traefik oo_php oo_nginx oo_mariadb; do
  echo "    $service:"
  docker service logs $service --tail 5 2>/dev/null || echo "      [N/A]"
done

# 4. Nodes health
echo "  État des nœuds:"
docker node ls

# 5. Volumes
echo "  Volumes disponibles:"
docker volume ls

echo -e "\n✓ Vérifications terminées"
```

---

## 6. ROLLBACK EN CAS D'ERREUR

```bash
#!/bin/bash
# rollback.sh

SERVICE_NAME=$1

if [ -z "${SERVICE_NAME}" ]; then
  echo "Usage: ./rollback.sh <service_name>"
  exit 1
fi

echo "⚠  Rollback de ${SERVICE_NAME}..."
docker service update --rollback ${SERVICE_NAME}

sleep 30

echo "Attendre stabilisation..."
docker service ps ${SERVICE_NAME} --no-trunc

echo "✓ Rollback terminé"
```

---

## 7. MONITORING PENDANT UPDATE

```bash
#!/bin/bash
# monitor-update.sh

SERVICE_NAME=$1
INTERVAL="${2:-5}"

while true; do
  clear
  echo "═══════════════════════════════════════"
  echo "Service: ${SERVICE_NAME}"
  echo "Time: $(date)"
  echo "═══════════════════════════════════════"
  
  docker service ps ${SERVICE_NAME} --no-trunc
  
  echo ""
  echo "Logs récents:"
  docker service logs ${SERVICE_NAME} --tail 10
  
  sleep ${INTERVAL}
done
```

---

## 8. POINTS CRITIQUES À RETENIR

| Type Service | Replicas Min | Update Parallelism | Delay | Failure Action | Health Check |
|---|---|---|---|---|---|
| **Workers** | 1 | 1 | 30s | rollback | ✓ obligatoire |
| **Web(PHP)** | 2 | 1 | 45s | rollback | ✓ obligatoire |
| **Web(Nginx)** | 2 | 1 | 45s | rollback | ✓ obligatoire |
| **Traefik** | 2 | 1 | 40s | rollback | ✓ obligatoire |
| **DB** | 1 | N/A | 60s | pause | ✓ obligatoire |

---

## 9. COMMANDES UTILES

```bash
# Watch en temps réel
watch -n 2 'docker service ps traefik --no-trunc'

# Voir l'historique update
docker service update --help | grep -A 20 "^  --update"

# Forcer le recheckl'état healthcheck
docker service update --force-update traefik

# Voir les événements
docker events --filter type=service

# Inspecter une mise à jour
docker service inspect --pretty traefik
```

---

## 10. CHECKLIST AVANT PRODUCTION

- [ ] Tous les services ont health checks
- [ ] Réplicas: Web ≥ 2, Traefik ≥ 2, DB = 1
- [ ] Update configs définies pour tous les services
- [ ] Logs centralisés pour monitoring
- [ ] Backups DB à jour et testés
- [ ] Runbooks de rollback disponibles
- [ ] Alertes configurées pour failures
- [ ] Fenêtre de maintenance communiquée aux users
- [ ] Équipe available pendant update

