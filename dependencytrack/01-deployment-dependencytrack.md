# Déploiement de DependencyTrack - Guide Complet

## Vue d'ensemble

DependencyTrack remplace Snyk pour la gestion centralisée des vulnérabilités sur les projets SaaS. Déploiement simple sur serveur Linux via Docker Compose avec alertes Slack intégrées.

**Projets concernés:**
- `saas_local/app`
- `saas_local/modulesjs`
- `saas_local/branch_hardening`

---

## 1. Prérequis

### Infrastructure

- Serveur Linux (Ubuntu 20.04+, Rocky Linux 8+)
- Docker & Docker Compose installés
- 2 CPU, 4 GB RAM minimum
- 30 GB disque (pour base de données + uploads)
- Accès réseau sortant HTTPS (pour webhooks GitHub)
- Certificat SSL/TLS (auto-signé ou Let's Encrypt)

### Credentials

- Token GitHub avec permissions `repo:status` + `public_repo`
- Slack Webhook URL (canal #security-alerts)
- Clé privée TLS et certificat

### Serveurs DNS

- `dependencytrack.oo-medical.local` (ou domaine production)

---

## 2. Architecture

```
┌──────────────────────────────────────────────┐
│      Serveur Linux (Ubuntu 20.04+)           │
├──────────────────────────────────────────────┤
│                                              │
│  Host: dependencytrack.oo-medical.local      │
│                                              │
│  ┌──────────────────────────────────────┐   │
│  │    Nginx (Reverse Proxy) - Host      │   │
│  │    - Port 80 (→ HTTPS)               │   │
│  │    - Port 443 (TLS)                  │   │
│  │    - Upstream: localhost:8080        │   │
│  └──────────────────────────────────────┘   │
│              ↓                               │
│  ┌──────────────────────────────────────┐   │
│  │   Docker Compose Network             │   │
│  │  (bridge: dependencytrack_default)   │   │
│  │                                      │   │
│  │  ┌──────────────────────────────┐   │   │
│  │  │ Frontend (node)              │   │   │
│  │  │ Port 8080                    │   │   │
│  │  └──────────────────────────────┘   │   │
│  │                                      │   │
│  │  ┌──────────────────────────────┐   │   │
│  │  │ API Backend (Java/Quarkus)   │   │   │
│  │  │ Port 8081                    │   │   │
│  │  └──────────────────────────────┘   │   │
│  │                                      │   │
│  │  ┌──────────────────────────────┐   │   │
│  │  │ PostgreSQL Database          │   │   │
│  │  │ Port 5432                    │   │   │
│  │  │ Volume: /data/dependencytrack│   │   │
│  │  └──────────────────────────────┘   │   │
│  │                                      │   │
│  └──────────────────────────────────────┘   │
│                                              │
└──────────────────────────────────────────────┘
         ↓              ↓
    [GitHub]      [Slack Webhooks]
```

### Composants

| Composant | Image | Ressources | Port |
|-----------|-------|-----------|------|
| Nginx Reverse Proxy | nginx:alpine | 0.25 CPU, 128M RAM | 80/443 |
| Frontend | dependencytrack/frontend | 0.5 CPU, 512M RAM | 8080 |
| API Backend | dependencytrack/apiserver | 1 CPU, 2G RAM | 8081 |
| PostgreSQL | postgres:15-alpine | 0.5 CPU, 1G RAM | 5432 |

---

## 3. Structure des répertoires

```bash
/opt/dependencytrack/
├── docker-compose.yml           # Stack Docker
├── .env                         # Variables d'environnement
├── ssl/
│   ├── cert.pem                # Certificat TLS
│   └── key.pem                 # Clé privée TLS
├── nginx/
│   └── dependencytrack.conf    # Config Nginx
├── backups/                     # Sauvegardes PostgreSQL
├── init-db.sql                 # Initialisation DB
└── scripts/
    ├── deploy.sh               # Script de déploiement
    ├── backup.sh               # Script de sauvegarde
    └── restore.sh              # Script de restauration
```

---

## 4. Préparation serveur

### 4.1 Installation des dépendances

```bash
# Mises à jour système
sudo apt update && sudo apt upgrade -y

# Installer Docker et Docker Compose
sudo apt install -y curl wget git jq nginx

# Installer Docker (Ubuntu/Debian)
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Installer Docker Compose
sudo apt install -y docker-compose

# Ajouter l'utilisateur au groupe docker
sudo usermod -aG docker $USER
newgrp docker

# Vérifier l'installation
docker --version
docker-compose --version
```

### 4.2 Créer la structure de répertoires

```bash
# Créer le répertoire de travail
sudo mkdir -p /opt/dependencytrack/{ssl,backups,scripts}
sudo chown -R $USER:$USER /opt/dependencytrack

# Créer les dossiers de backup et scripts
mkdir -p /opt/dependencytrack/{backups,scripts}

cd /opt/dependencytrack
```

**Note:** Le dossier `nginx/` n'est pas nécessaire si Nginx est déjà configuré via `/etc/nginx/sites-available/`

### 4.3 Certificats SSL — Approche optimisée

**Si Nginx tourne déjà sur ports 80/443 (avec SonarQube ou autre):**

#### Option A: Auto-signé temporaire (PLUS SIMPLE, recommandé)

```bash
# Générer un certificat auto-signé pour démarrer
mkdir -p /opt/dependencytrack/ssl
cd /opt/dependencytrack/ssl

openssl req -x509 -newkey rsa:4096 \
  -keyout key.pem -out cert.pem -days 365 -nodes \
  -subj "/C=FR/ST=Paris/L=Paris/O=OneOrtho/CN=dependencytrack.oo-medical.local"

chmod 644 cert.pem key.pem
```

**Avantages:** Rapide (30 sec), pas de dépendance, juste pour tester
**Inconvénient:** Navigateur montre warning SSL (normal)

---

#### Option B: Let's Encrypt via webroot (après Nginx configuré)

Si vous avez déjà Let's Encrypt/Certbot:

```bash
# 1. D'abord configurer le vhost Nginx (voir section 4.4)

# 2. Générer Let's Encrypt via webroot (pas --standalone)
sudo certbot certonly --webroot \
  -w /var/www/html \
  -d dependencytrack.oo-medical.local \
  --agree-tos -m security@oo-medical.local

# 3. Copier les certificats
sudo cp /etc/letsencrypt/live/dependencytrack.oo-medical.local/fullchain.pem \
  /opt/dependencytrack/ssl/cert.pem
sudo cp /etc/letsencrypt/live/dependencytrack.oo-medical.local/privkey.pem \
  /opt/dependencytrack/ssl/key.pem
sudo chown $USER:$USER /opt/dependencytrack/ssl/*.pem
```

**Avantage:** Certificat valide, pas de warning SSL
**Pré-requis:** Nginx vhost déjà configuré et actif

---

**⚠️ IMPORTANT:** Ne pas utiliser `--standalone` si Nginx tourne déjà (ports 80/443 en utilisation)

### 4.4 Configurer Nginx — Ajouter vhost DependencyTrack

**Situation:** Nginx tourne déjà (SonarQube, autres services)

**Solution:** Ajouter un vhost séparé pour DependencyTrack

---

**File: `/etc/nginx/sites-available/dependencytrack`**

```nginx
upstream dt_frontend {
    server 127.0.0.1:8080;
}

upstream dt_api {
    server 127.0.0.1:8081;
}

# Redirection HTTP → HTTPS
server {
    listen 80;
    server_name dependencytrack.oo-medical.local;
    return 301 https://$server_name$request_uri;
}

# HTTPS avec SSL
server {
    listen 443 ssl http2;
    server_name dependencytrack.oo-medical.local;

    # Certificats SSL
    # Option A: Auto-signé (temporaire, rapide)
    ssl_certificate /opt/dependencytrack/ssl/cert.pem;
    ssl_certificate_key /opt/dependencytrack/ssl/key.pem;
    
    # Option B: Let's Encrypt (après certbot)
    # ssl_certificate /etc/letsencrypt/live/dependencytrack.oo-medical.local/fullchain.pem;
    # ssl_certificate_key /etc/letsencrypt/live/dependencytrack.oo-medical.local/privkey.pem;

    # Configuration SSL
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    # Taille max upload (SBOM, fichiers)
    client_max_body_size 50M;

    # Logs
    access_log /var/log/nginx/dependencytrack_access.log;
    error_log /var/log/nginx/dependencytrack_error.log;

    # Frontend (UI)
    location / {
        proxy_pass http://dt_frontend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # API Backend
    location /api/ {
        proxy_pass http://dt_api;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

**Activation du vhost:**

```bash
# 1. Copier la config
sudo cp /etc/nginx/sites-available/dependencytrack /etc/nginx/sites-available/

# 2. Activer le vhost
sudo ln -s /etc/nginx/sites-available/dependencytrack \
  /etc/nginx/sites-enabled/dependencytrack

# 3. Tester la config
sudo nginx -t
# Doit afficher: nginx: configuration file test is successful

# 4. Recharger Nginx (sans restart, applique à chaud)
sudo systemctl reload nginx

# 5. Vérifier le vhost est actif
sudo systemctl is-active nginx
```

**Vérification:**

```bash
# Vérifier les vhosts actifs
sudo nginx -T | grep -A 5 "dependencytrack"

# Tester la résolution DNS
nslookup dependencytrack.oo-medical.local
# (ou si nom d'hôte local)
curl -k https://dependencytrack.oo-medical.local/
```

---

**⚠️ Notes:**

- Le vhost coexiste avec les autres (SonarQube, etc.) sur les mêmes ports 80/443
- Nginx route automatiquement par le header `Host:`
- Certificats auto-signés → navigateur affiche warning (normal, ignorer pour test)
- Let's Encrypt → certificat valide après certbot (pas de warning)

---

## 4.5 Résumé des étapes 4.1-4.4

```bash
# 4.1 Dépendances système
sudo apt install -y docker.io docker-compose

# 4.2 Répertoires
sudo mkdir -p /opt/dependencytrack/{ssl,backups,scripts}
sudo chown -R $USER:$USER /opt/dependencytrack

# 4.3 Certificats SSL (option A: auto-signé = rapide)
cd /opt/dependencytrack/ssl
openssl req -x509 -newkey rsa:4096 \
  -keyout key.pem -out cert.pem -days 365 -nodes \
  -subj "/C=FR/ST=Paris/L=Paris/O=OneOrtho/CN=dependencytrack.oo-medical.local"

# 4.4 Nginx vhost
sudo cp /etc/nginx/sites-available/dependencytrack /etc/nginx/sites-available/
sudo ln -s /etc/nginx/sites-available/dependencytrack /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx
```

**Durée:** ~5 minutes
**Résultat:** Infrastructure prête pour Docker Compose

---

## 5. Docker Compose Stack

### 5.1 Fichier .env

**File: `/opt/dependencytrack/.env`**

```bash
# DependencyTrack
DEPENDENCYTRACK_VERSION=4.10.0
DEPENDENCYTRACK_DOMAIN=dependencytrack.oo-medical.local

# PostgreSQL
POSTGRES_USER=dependencytrack
POSTGRES_PASSWORD=YourSecurePasswordHere123!
POSTGRES_DB=dependencytrack
POSTGRES_INITDB_ARGS=-c max_connections=200

# DependencyTrack API
ALPINE_API_KEY=YourAPIKeyHere123456789
ALPINE_LOGGING_LEVEL=INFO
ALPINE_METRICS_ENABLED=true
```

**Générer une clé API sécurisée:**

```bash
openssl rand -hex 32
```

### 5.2 Fichier docker-compose.yml

**File: `/opt/dependencytrack/docker-compose.yml`**

```yaml
version: '3.8'

services:
  dependencytrack-frontend:
    image: "dependencytrack/frontend:${DEPENDENCYTRACK_VERSION:-4.10.0}"
    container_name: dt-frontend
    restart: unless-stopped
    ports:
      - "127.0.0.1:8080:8080"
    environment:
      API_BASE_URL: "https://${DEPENDENCYTRACK_DOMAIN}/api"
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
    networks:
      - dependencytrack
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"

  dependencytrack-apiserver:
    image: "dependencytrack/apiserver:${DEPENDENCYTRACK_VERSION:-4.10.0}"
    container_name: dt-apiserver
    restart: unless-stopped
    ports:
      - "127.0.0.1:8081:8080"
    environment:
      ALPINE_DATABASE_MODE: "external"
      ALPINE_DATABASE_URL: "jdbc:postgresql://dependencytrack-db:5432/${POSTGRES_DB}"
      ALPINE_DATABASE_DRIVER: "org.postgresql.Driver"
      ALPINE_DATABASE_USERNAME: "${POSTGRES_USER}"
      ALPINE_DATABASE_PASSWORD: "${POSTGRES_PASSWORD}"
      ALPINE_LOGGING_LEVEL: "${ALPINE_LOGGING_LEVEL}"
      ALPINE_API_KEY: "${ALPINE_API_KEY}"
      ALPINE_METRICS_ENABLED: "${ALPINE_METRICS_ENABLED}"
    depends_on:
      dependencytrack-db:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/api/version"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s
    networks:
      - dependencytrack
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"

  dependencytrack-db:
    image: "postgres:15-alpine"
    container_name: dt-postgres
    restart: unless-stopped
    environment:
      POSTGRES_DB: "${POSTGRES_DB}"
      POSTGRES_USER: "${POSTGRES_USER}"
      POSTGRES_PASSWORD: "${POSTGRES_PASSWORD}"
      POSTGRES_INITDB_ARGS: "${POSTGRES_INITDB_ARGS}"
    volumes:
      - dependencytrack-db-data:/var/lib/postgresql/data
      - ./init-db.sql:/docker-entrypoint-initdb.d/01-init.sql:ro
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER}"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - dependencytrack
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"

volumes:
  dependencytrack-db-data:
    driver: local

networks:
  dependencytrack:
    driver: bridge
```

### 5.3 Initialisation de la base de données

**File: `/opt/dependencytrack/init-db.sql`**

```sql
-- Initialisation minimale (optionnel)
-- DependencyTrack crée les tables automatiquement

-- Créer l'extension UUID si nécessaire
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Paramètres de performance
ALTER SYSTEM SET max_connections = 200;
ALTER SYSTEM SET shared_buffers = '256MB';
```

---

## 6. Déploiement

### 6.1 Script de déploiement

**File: `/opt/dependencytrack/scripts/deploy.sh`**

```bash
#!/bin/bash

set -e

echo "=== DependencyTrack Deployment ==="

cd /opt/dependencytrack

# Vérifier les dépendances
echo "Checking dependencies..."
docker --version > /dev/null || { echo "Docker not installed"; exit 1; }
docker-compose --version > /dev/null || { echo "Docker Compose not installed"; exit 1; }

# Vérifier les fichiers nécessaires
echo "Checking required files..."
[ -f docker-compose.yml ] || { echo "docker-compose.yml not found"; exit 1; }
[ -f .env ] || { echo ".env not found"; exit 1; }
[ -f ssl/cert.pem ] || { echo "ssl/cert.pem not found"; exit 1; }
[ -f ssl/key.pem ] || { echo "ssl/key.pem not found"; exit 1; }

# Créer les répertoires
echo "Creating directories..."
mkdir -p backups

# Vérifier que les ports sont libres
echo "Checking ports..."
! netstat -tuln | grep -q ":80 " || { echo "Port 80 already in use"; exit 1; }
! netstat -tuln | grep -q ":443 " || { echo "Port 443 already in use"; exit 1; }

# Démarrer les services
echo "Starting Docker Compose stack..."
docker-compose up -d

# Attendre que les services soient prêts
echo "Waiting for services to be ready..."
for i in {1..30}; do
    if curl -sf http://localhost:8081/api/version > /dev/null 2>&1; then
        echo "✅ API Backend is ready"
        break
    fi
    echo "Waiting... ($i/30)"
    sleep 10
done

# Vérifier que tous les services sont up
echo ""
echo "=== Service Status ==="
docker-compose ps

echo ""
echo "✅ DependencyTrack deployment completed successfully!"
echo ""
echo "Access URL: https://dependencytrack.oo-medical.local"
echo "Default credentials: admin / admin"
echo ""
echo "⚠️  IMPORTANT: Change the admin password immediately!"
```

Rendre le script exécutable:

```bash
chmod +x /opt/dependencytrack/scripts/deploy.sh
```

### 6.2 Exécuter le déploiement

```bash
cd /opt/dependencytrack

# Vérifier les configurations
cat .env
cat docker-compose.yml
cat nginx/dependencytrack.conf

# Déployer
./scripts/deploy.sh

# Ou manuellement
docker-compose up -d

# Vérifier les logs
docker-compose logs -f dt-apiserver
```

### 6.3 Vérification post-déploiement

```bash
# Vérifier que les conteneurs tournent
docker ps | grep dt-

# Vérifier la connectivité
curl -k https://dependencytrack.oo-medical.local/

# Vérifier les logs
docker logs dt-apiserver
docker logs dt-postgres
docker logs dt-frontend

# Tester l'API
curl -k https://dependencytrack.oo-medical.local/api/version
```

---

## 7. Configuration initiale

### 7.1 Accéder à l'interface

1. Ouvrir https://dependencytrack.oo-medical.local
2. Login avec credentials par défaut: `admin` / `admin`
3. ⚠️ **Changer le password immédiatement**

### 7.2 Créer équipe Security

1. Aller dans **Administration > Access Management > Teams**
2. Créer équipe "Security" avec permissions:
   - Portfolio Management
   - Policy Management
   - Vulnerability Management

### 7.3 Générer API Key pour les scans

```bash
# Via l'UI
# Administration > Teams > Security > API Key

# Ou via l'API
curl -k -X POST https://dependencytrack.oo-medical.local/api/v1/team \
  -H "X-API-Key: ${ALPINE_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "CI-CD-Service",
    "permissions": ["PORTFOLIO_MANAGEMENT", "VULNERABILITY_MANAGEMENT"]
  }'
```

### 7.4 Configuration SMTP (optionnel)

**Administration > Settings > Notifications**

```
SMTP Host: smtp.company.local
SMTP Port: 587
From Email: dependencytrack@oo-medical.local
Use TLS: true
Username: noreply@oo-medical.local
Password: [your-password]
```

---

## 8. Intégration avec Slack

Voir document dédié: [Stratégie d'alertes Slack](02-slack-alerts-strategy.md)

---

## 9. Intégration des projets Git

Voir document dédié: [Intégration des projets](03-project-integration.md)

---

## 10. Migration depuis Snyk

### 10.1 Export des vulnérabilités Snyk

```bash
# Installer CLI Snyk
npm install -g snyk

# Authentifier
snyk auth

# Exporter les projets
snyk monitor --json > snyk-baseline.json

# Exporter les issues
snyk test --json > snyk-issues.json
```

### 10.2 Importer dans DependencyTrack

```bash
# Via l'API DependencyTrack (voir document 03)
python3 migrate_snyk_to_dt.py \
  --snyk-report snyk-baseline.json \
  --dt-url https://dependencytrack.oo-medical.local \
  --dt-api-key $(grep ALPINE_API_KEY .env | cut -d= -f2)
```

### 10.3 Désactiver Snyk

1. Supprimer les webhooks Snyk de GitHub
2. Archiver les intégrations Snyk
3. Mettre à jour les CODEOWNERS pour diriger vers l'équipe Sec
4. Documenter dans CHANGELOG

---

## 11. Maintenance et monitoring

### 11.1 Script de sauvegarde

**File: `/opt/dependencytrack/scripts/backup.sh`**

```bash
#!/bin/bash

set -e

BACKUP_DIR="/opt/dependencytrack/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="${BACKUP_DIR}/dt-postgres-${TIMESTAMP}.sql.gz"

mkdir -p ${BACKUP_DIR}

echo "Backing up DependencyTrack database..."

# Dump base de données
docker exec dt-postgres pg_dump \
  -U dependencytrack \
  dependencytrack | gzip > ${BACKUP_FILE}

echo "✅ Backup saved: ${BACKUP_FILE}"

# Garder 30 jours de backups
find ${BACKUP_DIR} -type f -mtime +30 -delete
echo "Cleaned up old backups"
```

Configurer le cron:

```bash
chmod +x /opt/dependencytrack/scripts/backup.sh

# Ajouter au crontab (daily 2 AM)
(crontab -l 2>/dev/null; echo "0 2 * * * /opt/dependencytrack/scripts/backup.sh") | crontab -
```

### 11.2 Monitoring des ressources

```bash
# Afficher l'utilisation des ressources
docker stats dt-apiserver dt-frontend dt-postgres

# Taille de la base de données
docker exec dt-postgres psql -U dependencytrack -d dependencytrack \
  -c "SELECT pg_size_pretty(pg_database_size('dependencytrack'));"

# Logs en temps réel
docker-compose logs -f

# Logs spécifiques
docker logs -f dt-apiserver --tail 100
docker logs -f dt-postgres --tail 100
```

### 11.3 Commandes utiles

```bash
# Redémarrer un service
docker-compose restart dt-apiserver

# Arrêter/démarrer la stack
docker-compose stop
docker-compose start

# Voir les logs
docker-compose logs -f [service-name]

# Exécuter une commande dans un conteneur
docker exec dt-postgres psql -U dependencytrack -d dependencytrack -c "SELECT version();"

# Mettre à jour les images
docker-compose pull
docker-compose up -d
```

### 11.4 Troubleshooting

```bash
# Vérifier la connectivité API
curl -k https://dependencytrack.oo-medical.local/api/version

# Vérifier les logs d'erreurs
docker logs dt-apiserver | grep -i error

# Vérifier la connexion à la base de données
docker exec dt-postgres psql \
  -U dependencytrack \
  -d dependencytrack \
  -c "SELECT 1;"

# Vérifier le disque
df -h /opt/dependencytrack

# Redémarrer les services
docker-compose restart
```

---

## 12. Checklist de déploiement

- [ ] Dépendances installées (Docker, Docker Compose, Nginx)
- [ ] Répertoires créés (`/opt/dependencytrack`)
- [ ] Certificats SSL générés
- [ ] Config Nginx copiée et testée
- [ ] Fichier `.env` créé avec des credentials sécurisés
- [ ] Fichier `docker-compose.yml` prêt
- [ ] Script de déploiement exécuté
- [ ] Services en cours d'exécution (`docker ps`)
- [ ] Interface accessible (HTTPS)
- [ ] Admin password changé
- [ ] Équipe Security créée
- [ ] API Key générée
- [ ] SMTP configuré (optionnel)
- [ ] Webhooks Slack configurés (voir doc 02)
- [ ] Projets Git intégrés (voir doc 03)
- [ ] Sauvegarde configurée (cron)
- [ ] Documentation mise à jour

---

## 13. Contacts et escalade

| Rôle | Contact | Escalade |
|------|---------|----------|
| DevSecOps Lead | gtatchum@oneortho-medical.com | OncCall |
| Infrastructure | ops-team@oneortho-medical.com | Manager Infra |
| Security Team | security@oneortho-medical.com | CISO |

---

## Annexes

- [Configuration Slack détaillée](02-slack-alerts-strategy.md)
- [Intégration projets Git](03-project-integration.md)
- [Docker Compose reference](https://docs.dependencytrack.org/deployment/docker/)
- [DependencyTrack API Documentation](https://docs.dependencytrack.org/api/)
- [PostgreSQL Backup & Restore](https://www.postgresql.org/docs/15/backup.html)
