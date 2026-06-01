# Analyse pré-déploiement DependencyTrack

## État du serveur

```
OS:             Ubuntu 22.04.5 LTS (Jammy)
Kernel:         5.15.0-179-generic
Architecture:   x86_64
Uptime:         11 days
CPU:            2x Intel Core (Haswell)
RAM:            3.7 GB (3.2 GB utilisé, 152 MB libre)
Disque:         80 GB (36 GB utilisé, 43 GB libre)
```

---

## 🔴 PROBLÈMES CRITIQUES

### 1. RAM insuffisante — **ACTION PRIORITAIRE**

**État actuel:** 152 MB disponible sur 3.7 GB

**Ressources requises par DependencyTrack:**
- API Backend: 2000 MB (minimum)
- Frontend: 512 MB
- PostgreSQL: 1000 MB (si nouvelle instance)
- Nginx: 128 MB
- **Total minimum: 3.6 GB**

**Impact:** ⚠️ Le serveur est **LIMITE** (3.7 GB total vs 3.6 GB requis)

**Solutions:**

#### Option A: Réduire les services existants (RECOMMANDÉ)
```bash
# Identifier les consommateurs RAM
ps aux --sort=-%mem | head -20

# Services candidates à arrêter/limiter
- Datadog Agent (monitoring non-critique)
- LXD (virtualisation non utilisée)
- ModemManager (inutile en VPS)
- Snapd (cause des fuites mémoire)
```

#### Option B: Augmenter la RAM du VPS
Contact hosting provider pour upgrade RAM (4 GB → 8 GB recommandé)

#### Option C: Réduire DependencyTrack
```yaml
# Dans docker-compose.yml
dependencytrack-apiserver:
  environment:
    JAVA_OPTS: "-Xmx1024m"  # Limiter à 1 GB au lieu de 2 GB
```

**❌ Non recommandé — API deviendra instable**

---

### 2. Port 8080 — Conflit Jenkins

**État actuel:**
```
Jenkins:        Port 8080 (Java)
DependencyTrack Frontend: Port 8080 (requis)
```

**Solutions:**

#### Option A: Reconfigurer Jenkins (RECOMMANDÉ)
```bash
# Éditer config Jenkins
sudo nano /etc/default/jenkins

# Changer le port
PORT=8090

# Redémarrer Jenkins
sudo systemctl restart jenkins

# Vérifier
ss -tlnp | grep java
```

#### Option B: Exposer DependencyTrack sur autre port
```yaml
# docker-compose.yml
dependencytrack-frontend:
  ports:
    - "127.0.0.1:8082:8080"  # Port local 8082 au lieu de 8080
```

**Impact:** ⚠️ Configuration Nginx doit être adaptée (plus complexe)

---

### 3. PostgreSQL — Coexistence requise

**État actuel:**
```
PostgreSQL 13 lancé
Port: 5432 (localhost seulement)
Utilisé par: SonarQube
```

**Solutions:**

#### Option A: Réutiliser la PostgreSQL existante (RECOMMANDÉ)
```bash
# Créer un utilisateur et base DependencyTrack dans la PostgreSQL 13
sudo -u postgres psql

CREATE USER dependencytrack WITH PASSWORD 'your-secure-password';
CREATE DATABASE dependencytrack OWNER dependencytrack;
GRANT ALL PRIVILEGES ON DATABASE dependencytrack TO dependencytrack;
ALTER USER dependencytrack SUPERUSER;  # Requis pour DependencyTrack
```

**Avantage:** Économise 1 GB de RAM (pas de PostgreSQL Docker)

**docker-compose.yml:**
```yaml
# Retirer le service dependencytrack-db
# Utiliser la PostgreSQL host
environment:
  ALPINE_DATABASE_URL: "jdbc:postgresql://host.docker.internal:5432/dependencytrack"
```

#### Option B: PostgreSQL Docker séparé
**Non recommandé — aggrave le problème RAM**

---

## 🟡 PROBLÈMES IMPORTANTS

### 4. Snapd — Consommation disque excessive

**État actuel:**
```
Snaps occupant:  ~1.2 GB (loopback devices)
core22:           2 versions = 148 MB
core24:           2 versions = 133 MB
lxd:              2 versions = 230 MB
certbot:          2 versions = 147 MB
```

**Action:**
```bash
# Nettoyer les anciens snaps
sudo snap list --all
sudo snap remove --revision=<old-revision> <package>

# Ou nettoyer complètement
sudo snap remove lxd --purge
sudo apt purge snapd
```

**Gain:** ~500 MB disque, ~100 MB RAM

---

### 5. Erreur GPG Jenkins — Correctif simple

**Erreur:**
```
NO_PUBKEY 7198F4B714ABFC68
```

**Solution:**
```bash
# Ajouter la clé GPG Jenkins
wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo apt-key add -

# Ou (méthode moderne)
sudo gpg --no-default-keyring --keyring=/usr/share/keyrings/jenkins.gpg --keyserver keyserver.ubuntu.com --recv-keys 7198F4B714ABFC68

# Mettre à jour apt
sudo apt update
```

---

### 6. Mises à jour disponibles

**5 packages en attente:**
```
datadog-agent        (1:7.67.0 → 1:7.79.0)
libnetplan0          (0.107.1-3ubuntu0.22.04.3 → .22.04.4)
netplan-generator    (0.107.1-3ubuntu0.22.04.3 → .22.04.4)
netplan.io           (0.107.1-3ubuntu0.22.04.3 → .22.04.4)
python3-netplan      (0.107.1-3ubuntu0.22.04.3 → .22.04.4)
```

**Action:**
```bash
# Appliquer les mises à jour
sudo apt update
sudo apt upgrade -y

# Vérifier les services après
systemctl status nginx docker postgresql
```

---

## 🟢 POINTS POSITIFS

### ✅ Docker déjà installé
```
Docker Engine: Actif
Containerd: Actif
docker-compose: Présent
```

### ✅ Nginx déjà configuré
```
Ports 80/443: Ouverts et actifs
Config reverse proxy: Existante
Certificats: En place
```

### ✅ Disque suffisant
```
80 GB total
43 GB libre
Après nettoyage: ~44 GB libre
```

### ✅ Services stables
```
Uptime: 11 jours
Load average: 0.04 (très bas)
Kernel: À jour
```

---

## 📋 PLAN D'ACTION RECOMMANDÉ

### Phase 1: Préparation (30 minutes)

**Actions critiques (À FAIRE AVANT DT):**

1. **Décider RAM**
   - [ ] Arrêter Datadog Agent (gain: ~200 MB)
     ```bash
     sudo systemctl stop datadog-agent
     sudo systemctl disable datadog-agent
     ```
   - [ ] Arrêter ModemManager (gain: ~50 MB)
     ```bash
     sudo systemctl stop ModemManager
     sudo systemctl disable ModemManager
     ```
   - [ ] Arrêter LXD (gain: ~150 MB)
     ```bash
     sudo snap remove lxd --purge
     ```
   - **Total gain: ~400 MB RAM**

2. **Libérer disque & nettoyage**
   - [ ] Nettoyer les snaps
     ```bash
     sudo snap list --all | grep -E "core|lxd|certbot"
     sudo snap remove <old-versions>
     ```
   - [ ] Supprimer apt cache
     ```bash
     sudo apt clean
     sudo apt autoclean
     ```
   - **Gain: ~500 MB disque**

3. **Corriger erreurs**
   - [ ] Ajouter clé GPG Jenkins
   - [ ] Appliquer apt upgrade
   - [ ] Vérifier services après

### Phase 2: Configuration Nginx (15 minutes)

- [ ] Vérifier les vhosts existants
  ```bash
  sudo nginx -T
  ls -la /etc/nginx/sites-enabled/
  ```
- [ ] Créer vhost DependencyTrack
  ```bash
  # Voir doc 01 section 4.4
  sudo cp /opt/dependencytrack/nginx/dependencytrack.conf \
    /etc/nginx/sites-available/
  sudo ln -s ../sites-available/dependencytrack /etc/nginx/sites-enabled/
  sudo nginx -t && sudo systemctl reload nginx
  ```

### Phase 3: PostgreSQL (10 minutes)

- [ ] Créer DB et user dans PostgreSQL 13
  ```bash
  sudo -u postgres psql
  CREATE USER dependencytrack WITH PASSWORD 'secure-pass';
  CREATE DATABASE dependencytrack OWNER dependencytrack;
  ALTER USER dependencytrack SUPERUSER;
  ```

### Phase 4: Jenkins (5 minutes)

- [ ] Reconfigurer port Jenkins
  ```bash
  sudo systemctl stop jenkins
  sudo sed -i 's/PORT=8080/PORT=8090/' /etc/default/jenkins
  sudo systemctl start jenkins
  ```
- [ ] Vérifier
  ```bash
  ss -tlnp | grep 8090
  ```

### Phase 5: Déploiement DependencyTrack (voir doc 01)

---

## ⚠️ CHECKLIST PRÉ-DÉPLOIEMENT

### RAM & Ressources
- [ ] RAM disponible > 500 MB après nettoyage
- [ ] CPU pas saturé (`load average < 1.0`)
- [ ] Disque libre > 40 GB

### Services conflictuels
- [ ] Port 8080 libéré (Jenkins déplacé)
- [ ] Port 8081 disponible (API Backend)
- [ ] Port 5432 accessible à Docker

### Bases de données
- [ ] PostgreSQL accessible (`psql -U dependencytrack`)
- [ ] Base `dependencytrack` créée
- [ ] User `dependencytrack` avec privileges suffisants

### Nginx
- [ ] Config DependencyTrack ajoutée
- [ ] Nginx reloaded (`nginx -t && systemctl reload nginx`)
- [ ] Certificats SSL en place

### Système
- [ ] Pas d'erreurs GPG
- [ ] Mises à jour appliquées
- [ ] Services critiques stables

---

## 📊 Estimations temps

| Phase | Durée | Notes |
|-------|-------|-------|
| 1. Préparation | 30 min | Critique pour la stabilité |
| 2. Nginx | 15 min | Basique, bien documenté |
| 3. PostgreSQL | 10 min | Simple création DB |
| 4. Jenkins | 5 min | Juste reconfigurer port |
| 5. DependencyTrack | 10 min | Déploiement Docker |
| **TOTAL** | **70 min** | Déploiement prêt pour demain |

---

## 🚀 Commandes pré-déploiement (Copier/coller)

```bash
#!/bin/bash
set -e

echo "=== DependencyTrack Pre-Deployment Cleanup ==="

# 1. Arrêter services inutiles
echo "Stopping unnecessary services..."
sudo systemctl stop datadog-agent ModemManager || true
sudo systemctl disable datadog-agent ModemManager || true

# 2. Nettoyer snaps
echo "Cleaning snapd..."
sudo snap remove lxd --purge || true
sudo apt purge snapd -y || true

# 3. Nettoyer apt cache
echo "Cleaning apt cache..."
sudo apt clean && sudo apt autoclean

# 4. Corriger GPG Jenkins
echo "Fixing Jenkins GPG key..."
wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo apt-key add - || true

# 5. Mise à jour
echo "Updating system..."
sudo apt update && sudo apt upgrade -y

# 6. Reconfigurer Jenkins
echo "Moving Jenkins from port 8080 to 8090..."
sudo systemctl stop jenkins
sudo sed -i 's/PORT=8080/PORT=8090/' /etc/default/jenkins
sudo systemctl start jenkins

# 7. Créer DB PostgreSQL
echo "Creating DependencyTrack database..."
sudo -u postgres psql <<EOF
CREATE USER IF NOT EXISTS dependencytrack WITH PASSWORD 'change-me-please';
CREATE DATABASE IF NOT EXISTS dependencytrack OWNER dependencytrack;
GRANT ALL PRIVILEGES ON DATABASE dependencytrack TO dependencytrack;
ALTER USER dependencytrack SUPERUSER;
\q
EOF

echo ""
echo "✅ Pre-deployment cleanup completed!"
echo ""
echo "Next steps:"
echo "1. Edit .env with PostgreSQL password"
echo "2. Run deploy.sh from /opt/dependencytrack"
echo ""
echo "Verification:"
echo "- RAM available: $(free -h | grep Mem | awk '{print $7}')"
echo "- Jenkins port: $(ss -tlnp | grep java | awk '{print $4}')"
echo "- PostgreSQL: $(sudo -u postgres psql -lqt | grep dependencytrack | wc -l) DB found"
```

Sauvegarde et exécution:

```bash
chmod +x pre-deploy.sh
./pre-deploy.sh
```

---

## 📞 En cas de problème

| Problème | Solution |
|----------|----------|
| RAM insuffisante après nettoyage | Arrêter Jenkins aussi (`systemctl stop jenkins`) |
| PostgreSQL refusé | Vérifier `sudo -u postgres psql` fonctionne |
| Nginx rejet config | Vérifier certificats SSL path corrects |
| Port 5432 non accessible | `sudo netstat -tlnp \| grep 5432` |
| Docker Compose ne démarre pas | `docker-compose logs -f` pour voir erreurs |

---

## ✅ État final attendu

Après cette préparation:

```
RAM:                 ~800 MB libre (vs 152 MB actuel)
Disque:              ~44 GB libre (vs 43 GB actuel)
Port 8080:           Libre (Jenkins sur 8090)
Port 8081:           Disponible pour DependencyTrack
PostgreSQL:          Prête avec DB dependencytrack
Nginx:               Configuré pour vhost DependencyTrack
Système:             À jour, stable, prêt pour production
```

Vous pouvez alors **procéder au déploiement DependencyTrack** (doc 01) sans risque.

