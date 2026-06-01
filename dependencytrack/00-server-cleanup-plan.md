# Plan de nettoyage serveur - SonarQube conservé

## 📋 Stratégie validée

```
Etat actuel:      3.7 GB RAM (SonarQube + Jenkins + Datadog)
Après nettoyage:  ~2.9 GB RAM (SonarQube seul)
Après upgrade:    ~8 GB RAM (OVH en cours)
─────────────────────────────────────────────
Résultat:         SonarQube + DependencyTrack sans limitation
```

---

## À ARRÊTER et SUPPRIMER

### 1. Jenkins (702 MB RAM)

```bash
# Arrêter et désactiver
sudo systemctl stop jenkins
sudo systemctl disable jenkins

# Vérifier arrêt
ps aux | grep jenkins
# (pas de résultat = bon)

# Supprimer le service
sudo apt purge jenkins -y

# Nettoyer fichiers
sudo rm -rf /var/cache/jenkins
sudo rm -rf /var/lib/jenkins

# Libère: 702 MB RAM + disque
```

**Raison:** CI/CD peut être remplacé par GitHub Actions (gratuit)

---

### 2. Datadog Agent (151 MB RAM)

```bash
# Arrêter et désactiver
sudo systemctl stop datadog-agent
sudo systemctl disable datadog-agent

# Supprimer
sudo apt purge datadog-agent -y

# Nettoyer
sudo rm -rf /opt/datadog-agent

# Libère: 151 MB RAM + disque
```

**Raison:** Monitoring peut utiliser Prometheus/Grafana (gratuit)

---

### 3. ModemManager (inutile en VPS)

```bash
sudo systemctl stop ModemManager
sudo systemctl disable ModemManager
sudo apt purge modemmanager -y

# Libère: ~50 MB RAM
```

---

### 4. LXD (virtualisation non utilisée)

```bash
# Arrêter
sudo systemctl stop snap.lxd.daemon
sudo snap remove lxd --purge

# Vérifier
snap list | grep lxd
# (rien = bon)

# Libère: ~200 MB RAM + 230 MB disque
```

---

### 5. Snapd et snaps inutiles (nettoyage)

```bash
# Lister tous les snaps
snap list --all

# Supprimer les anciennes versions
snap list --all | grep "disabled\|old" | \
  awk '{print $1, $3}' | while read snap rev; do
    snap remove "$snap" --revision="$rev"
  done

# Supprimer snaps inutiles
sudo snap remove gnome-3-28-1804  # GUI inutile
sudo snap remove gtk-common-themes  # Thèmes GUI
# (garder: certbot, core)

# Libère: ~500 MB disque
```

---

### 6. Nettoyage APT

```bash
# Supprimer cache ancien
sudo apt clean
sudo apt autoclean

# Supprimer packages non utilisés
sudo apt autoremove -y

# Libère: ~200 MB disque
```

---

### 7. Nettoyage disque

```bash
# Voir ce qui prend de la place
sudo du -sh /var/lib/*
sudo du -sh /var/cache/*
sudo du -sh /home/*

# Nettoyer les logs
sudo journalctl --vacuum=30d

# Nettoyer les fichiers temporaires
sudo rm -rf /tmp/*
sudo rm -rf /var/tmp/*
```

---

## À CONSERVER

### ✅ SonarQube

```bash
# Vérifier en cours d'exécution
ps aux | grep sonarqube

# Tester l'interface
curl -k https://localhost/sonarqube || \
curl http://localhost:9000

# Garder le service activé
sudo systemctl is-enabled sonarqube
# (doit afficher: enabled)
```

**RAM actuel:** 2,600 MB
**Après upgrade RAM:** ~0.6 GB (32% de 8 GB)
**État:** Optimal

---

### ✅ PostgreSQL 13

```bash
# Vérifier en cours d'exécution
sudo systemctl is-active postgresql

# Tester
sudo -u postgres psql -l

# Vérifier les bases existantes
sudo -u postgres psql -l | grep sonarqube
```

**Usage:** SonarQube + DependencyTrack (bases séparées)
**État:** Optimal

---

### ✅ Docker & Docker Compose

```bash
# Vérifier
docker --version
docker-compose --version

# Services actifs
docker ps

# Vérifier containerd
sudo systemctl is-active containerd
```

**State:** Optimal, requis pour DependencyTrack

---

### ✅ Nginx

```bash
# Vérifier
sudo systemctl is-active nginx

# Tester la config
sudo nginx -t

# Lister les vhosts
ls -la /etc/nginx/sites-enabled/
```

**État:** Optimal, servira de reverse proxy pour DependencyTrack

---

### ✅ SSH & Services système

```bash
# SSH (accès distant)
sudo systemctl is-active ssh

# Autres services système critiques
sudo systemctl is-active cron
sudo systemctl is-active rsyslog
```

---

## 🚀 PLAN D'EXÉCUTION

### Phase 1: Nettoyage immédiat (avant upgrade OVH)
**Durée:** 30 minutes

```bash
#!/bin/bash
set -e

echo "=== Phase 1: Server Cleanup (Immediate) ==="

# 1. Arrêter Jenkins
echo "[1/7] Stopping Jenkins..."
sudo systemctl stop jenkins
sudo systemctl disable jenkins
sudo apt purge jenkins -y
sudo rm -rf /var/cache/jenkins /var/lib/jenkins

# 2. Arrêter Datadog
echo "[2/7] Stopping Datadog Agent..."
sudo systemctl stop datadog-agent datadog-agent-trace 2>/dev/null || true
sudo systemctl disable datadog-agent datadog-agent-trace 2>/dev/null || true
sudo apt purge datadog-agent -y
sudo rm -rf /opt/datadog-agent

# 3. Arrêter ModemManager
echo "[3/7] Stopping ModemManager..."
sudo systemctl stop ModemManager
sudo systemctl disable ModemManager
sudo apt purge modemmanager -y

# 4. Supprimer LXD
echo "[4/7] Removing LXD..."
sudo snap remove lxd --purge 2>/dev/null || true

# 5. Nettoyer snaps
echo "[5/7] Cleaning old snaps..."
snap list --all | grep disabled | \
  awk '{print $1}' | while read snap; do
    sudo snap remove "$snap" --purge 2>/dev/null || true
  done

# 6. Nettoyer APT
echo "[6/7] Cleaning APT cache..."
sudo apt clean
sudo apt autoclean
sudo apt autoremove -y

# 7. Nettoyer temp files
echo "[7/7] Cleaning temporary files..."
sudo rm -rf /tmp/* /var/tmp/*
sudo journalctl --vacuum=30d

echo ""
echo "✅ Phase 1 completed!"
echo ""
echo "RAM Status:"
free -h
echo ""
echo "Disque Status:"
df -h /

echo ""
echo "Next step: Wait for OVH RAM upgrade (8 GB)"
```

Exécuter:
```bash
chmod +x phase1-cleanup.sh
./phase1-cleanup.sh
```

**Résultat attendu:**
```
RAM disponible: ~2.9 GB
Disque libéré: ~1.5 GB
Services stoppés: Jenkins, Datadog, ModemManager, LXD
Services actifs: SonarQube, PostgreSQL, Docker, Nginx
```

---

### Phase 2: Après upgrade RAM OVH (8 GB)
**Durée:** 5 minutes

```bash
#!/bin/bash
set -e

echo "=== Phase 2: Verify RAM upgrade (After OVH) ==="

# Vérifier la RAM
echo "RAM Status:"
free -h

# Doit afficher ~8 GB total
TOTAL_RAM=$(free -h | grep Mem | awk '{print $2}')
echo "Total RAM: $TOTAL_RAM"

# Vérifier les services critiques
echo ""
echo "Checking services..."
sudo systemctl status sonarqube --no-pager
sudo systemctl status postgresql --no-pager
sudo systemctl status docker --no-pager

# Tester SonarQube
echo ""
echo "Testing SonarQube accessibility..."
curl -s http://localhost:9000/api/system/health | jq .

echo ""
echo "✅ RAM upgrade verified!"
echo ""
echo "Next step: Deploy DependencyTrack (doc 01)"
```

Exécuter après upgrade:
```bash
chmod +x phase2-verify.sh
./phase2-verify.sh
```

---

## 📊 État avant/après

### AVANT (État actuel)

```
RAM:         3.7 GB
├─ SonarQube:     2.6 GB (70%)
├─ Jenkins:       0.7 GB (19%)
├─ Datadog:       0.15 GB (4%)
└─ Autres:        0.3 GB (7%)

Libre:       0.15 GB (4%) ← CRITIQUE!

Services inutiles:
- Jenkins (CI/CD)
- Datadog (monitoring)
- ModemManager (VPS)
- LXD (virtualisation)
- Snaps multiples
```

### APRÈS Phase 1 (avant upgrade OVH)

```
RAM:         3.7 GB (inchangé, upgrade en cours)
├─ SonarQube:     2.6 GB (70%)
└─ Autres:        1.1 GB (30%)

Libre:       ~0.9 GB ← Suffisant pour démarrage

Services:
✅ SonarQube
✅ PostgreSQL
✅ Docker
✅ Nginx
❌ Jenkins (supprimé)
❌ Datadog (supprimé)
❌ ModemManager (supprimé)
```

### APRÈS Phase 2 (après upgrade OVH à 8 GB)

```
RAM:         8.0 GB
├─ SonarQube:     2.6 GB (32%)
├─ DependencyTrack: 3.6 GB (45%)
└─ Autres:        1.8 GB (23%)

Libre:       ~3.0 GB ← OPTIMAL!

Capabilités:
✅ SonarQube (analyse de code)
✅ DependencyTrack (gestion vulnérabilités)
✅ PostgreSQL (base de données)
✅ Docker (containerisation)
✅ Nginx (reverse proxy)
```

---

## 🎯 TIMELINE

| Date | Phase | Durée | Blocage |
|------|-------|-------|---------|
| Aujourd'hui | Cleanup (Phase 1) | 30 min | ❌ Aucun |
| Aujourd'hui+1 | Attend OVH upgrade | 24h | ⏳ OVH |
| Demain+1 | Verify RAM (Phase 2) | 5 min | ✅ OVH |
| Demain+2 | Deploy DependencyTrack | 15 min | ✅ Prêt |
| Demain+3 | Configure Slack | 30 min | ✅ Prêt |
| Demain+4 | Integrate Git projects | 1h | ✅ Prêt |

**TOTAL:** 2 jours (attente OVH) + 2h de travail

---

## ✅ CHECKLIST EXÉCUTION

### Phase 1: Nettoyage (30 min)

- [ ] Exécuter `phase1-cleanup.sh`
- [ ] Vérifier Jenkins arrêté: `ps aux | grep jenkins` (rien)
- [ ] Vérifier Datadog arrêté: `ps aux | grep datadog` (rien)
- [ ] Vérifier SonarQube toujours actif: `curl http://localhost:9000`
- [ ] Vérifier PostgreSQL actif: `sudo -u postgres psql -l`
- [ ] Vérifier RAM libérée: `free -h` (devrait avoir ~2.9 GB libre)
- [ ] Vérifier disque nettoyé: `df -h` (+ ~1.5 GB disponible)

### Phase 2: Après upgrade OVH (5 min)

- [ ] Redémarrer le serveur (optionnel mais recommandé)
- [ ] Vérifier RAM: `free -h` (doit afficher ~8 GB)
- [ ] Vérifier SonarQube après reboot: `curl http://localhost:9000`
- [ ] Vérifier PostgreSQL: `sudo -u postgres psql -l`
- [ ] Exécuter `phase2-verify.sh`

### Phase 3: Déploiement DependencyTrack

- [ ] Créer DB PostgreSQL: voir doc 00-pre-deployment-analysis.md
- [ ] Configurer nginx vhost: voir doc 01 section 4.4
- [ ] Déployer stack Docker: `cd /opt/dependencytrack && ./scripts/deploy.sh`
- [ ] Vérifier interface: https://dependencytrack.oo-medical.local
- [ ] Tester API: `curl -k https://dependencytrack.oo-medical.local/api/version`

---

## 📞 Support OVH

**Demande:** "Upgrade RAM 4 GB → 8 GB"
**Status:** En cours ✅
**ETA:** 24-48h

**Après upgrade:**
```bash
# Reboot pour prendre la RAM
sudo reboot

# Vérifier après reboot
free -h  # Doit afficher ~8 GB
```

---

## 🎬 PROCHAINES ÉTAPES

1. ✅ **Maintenant:** Exécuter Phase 1 (nettoyage)
2. ⏳ **Demain:** OVH upgrade RAM
3. ✅ **Demain+1:** Exécuter Phase 2 (vérification)
4. ✅ **Demain+2:** Déployer DependencyTrack (doc 01)
5. ✅ **Demain+3:** Configurer Slack (doc 02)
6. ✅ **Demain+4:** Intégrer projets Git (doc 03)

---

## 📚 Ressources

- [Doc 00: Pre-deployment analysis](00-pre-deployment-analysis.md) — Encore utile pour Postgres/Nginx
- [Doc 01: Deployment](01-deployment-dependencytrack.md) — Déploiement avec 8 GB RAM
- [Doc 02: Slack alerts](02-slack-alerts-strategy.md) — Configuration webhooks
- [Doc 03: Project integration](03-project-integration.md) — GitHub Actions workflows

