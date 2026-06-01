# Quick Start - DependencyTrack Deployment

## 📋 Situation

```
Etat:           Jenkins + Datadog + SonarQube sur 3.7 GB RAM
Décision:       Garder SonarQube, supprimer Jenkins/Datadog
Upgrade OVH:    4 GB → 8 GB (en cours)
Résultat:       SonarQube + DependencyTrack ensemble sur 8 GB
```

---

## 🚀 3 ÉTAPES SIMPLES

### ✅ ÉTAPE 1: Nettoyage immédiat (30 min) — À FAIRE MAINTENANT

```bash
cd /home/gtatchum/Sites/wwwroot/utils/dependencytrack

# Exécuter le script de nettoyage
./phase1-cleanup.sh
```

**Ce que ça fait:**
- Arrête Jenkins, Datadog, LXD
- Nettoie les snaps inutiles
- Libère ~900 MB RAM + 1.5 GB disque
- Gardes SonarQube, PostgreSQL, Docker, Nginx

**Durée:** 30 minutes
**Résultat attendu:** ✅ Phase 1 complete!

---

### ⏳ ÉTAPE 2: Attendre upgrade OVH (24-48h)

```
Demande:   RAM 4 GB → 8 GB
Status:    En cours ✅
ETA:       24-48h
```

**Pendant ce temps:** Rien à faire, le serveur fonctionne normalement

---

### ✅ ÉTAPE 3: Vérifier l'upgrade (5 min) — À FAIRE APRÈS OVH

```bash
cd /home/gtatchum/Sites/wwwroot/utils/dependencytrack

# Exécuter le script de vérification
./phase2-verify.sh
```

**Ce que ça fait:**
- Vérifie RAM 8 GB reçue
- Teste services critiques
- Affiche état disque
- Prêt pour DependencyTrack

**Durée:** 5 minutes
**Résultat attendu:** ✅ All critical services operational

---

## 📚 APRÈS LES 3 ÉTAPES: Déploiement DependencyTrack

Une fois Phase 2 terminée avec succès:

1. **Créer DB PostgreSQL** (5 min)
   ```bash
   sudo -u postgres psql <<EOF
   CREATE USER dependencytrack WITH PASSWORD 'secure-password-here';
   CREATE DATABASE dependencytrack OWNER dependencytrack;
   GRANT ALL PRIVILEGES ON DATABASE dependencytrack TO dependencytrack;
   ALTER USER dependencytrack SUPERUSER;
   EOF
   ```

2. **Préparer dossier DependencyTrack**
   ```bash
   sudo mkdir -p /opt/dependencytrack/{ssl,nginx,backups,scripts}
   sudo chown -R $USER:$USER /opt/dependencytrack
   ```

3. **Copier fichiers depuis doc 01**
   - `.env` (voir section 5.1)
   - `docker-compose.yml` (voir section 5.2)
   - `nginx/dependencytrack.conf` (voir section 4.4)

4. **Générer certificats SSL**
   ```bash
   cd /opt/dependencytrack/ssl
   openssl req -x509 -newkey rsa:4096 \
     -keyout key.pem -out cert.pem -days 365 -nodes \
     -subj "/C=FR/ST=Paris/L=Paris/O=OneOrtho/CN=dependencytrack.oo-medical.local"
   ```

5. **Déployer**
   ```bash
   cd /opt/dependencytrack
   docker-compose up -d
   ```

6. **Accéder à l'interface**
   - https://dependencytrack.oo-medical.local
   - Login: `admin` / `admin`
   - Changer le password immédiatement ⚠️

---

## 📖 DOCUMENTATION COMPLÈTE

Pour plus de détails, consultez:

| Document | Pour | Durée |
|----------|------|-------|
| [00-server-cleanup-plan.md](00-server-cleanup-plan.md) | Comprendre le plan | 5 min |
| [00-pre-deployment-analysis.md](00-pre-deployment-analysis.md) | Détails pré-déploiement | 10 min |
| [01-deployment-dependencytrack.md](01-deployment-dependencytrack.md) | Déploiement Docker Compose | 20 min |
| [02-slack-alerts-strategy.md](02-slack-alerts-strategy.md) | Configurer Slack | 30 min |
| [03-project-integration.md](03-project-integration.md) | Intégrer projets Git | 1h |

---

## ⏱️ TIMELINE COMPLÈTE

```
Jour 0 (maintenant):
  09h00 - Exécuter phase1-cleanup.sh (30 min)
  09h30 - ✅ Cleanup terminé

Jour 1:
  OVH upgrade RAM en cours...

Jour 2 (demain+1):
  10h00 - Exécuter phase2-verify.sh (5 min)
  10h05 - ✅ Vérification terminée

Jour 2 (suite):
  10h05 - Créer DB PostgreSQL (5 min)
  10h10 - Préparer dossier /opt/dependencytrack (10 min)
  10h20 - Générer certificats SSL (5 min)
  10h25 - Déployer DependencyTrack (15 min)
  10h40 - ✅ DependencyTrack opérationnel!

Jour 3 (demain+2):
  09h00 - Configurer Slack (30 min)
  09h30 - ✅ Slack opérationnel

Jour 4 (demain+3):
  09h00 - Intégrer projets Git (1h)
  10h00 - ✅ CI/CD workflows actifs
```

**TOTAL:** 2.5 jours de travail (dont 24h attente OVH)

---

## 🆘 EN CAS DE PROBLÈME

### Phase 1 échoue

```bash
# Vérifier l'erreur
journalctl -xe

# Ou relancer manuellement chaque commande
sudo systemctl stop jenkins
sudo apt-get purge jenkins -y
# etc...
```

### Phase 2: RAM pas mise à jour

```bash
# Vérifier la RAM
free -h

# Si pas 8 GB, contacter OVH
# URL: https://www.ovh.com
```

### DependencyTrack ne démarre pas

```bash
# Voir les logs
cd /opt/dependencytrack
docker-compose logs -f

# Vérifier PostgreSQL
docker exec dt-postgres psql -U dependencytrack -d dependencytrack -c "SELECT 1;"

# Redémarrer
docker-compose restart
```

### PostgreSQL refuse la connexion

```bash
# Vérifier l'user/DB
sudo -u postgres psql -l | grep dependencytrack

# Si manquant, créer (voir ÉTAPE 3 ci-dessus)

# Vérifier le mot de passe dans .env
cat /opt/dependencytrack/.env | grep POSTGRES_PASSWORD
```

---

## ✅ CHECKLIST FINALE

### Phase 1 (Cleanup)
- [ ] Script phase1-cleanup.sh exécuté
- [ ] Jenkins arrêté (vérifier: `ps aux | grep jenkins` = rien)
- [ ] Datadog arrêté (vérifier: `ps aux | grep datadog` = rien)
- [ ] RAM libérée (vérifier: `free -h` = ~2.9 GB)
- [ ] Disque nettoyé (vérifier: `df -h` = +1.5 GB disponible)

### Phase 2 (After OVH upgrade)
- [ ] Serveur redémarré (optionnel)
- [ ] Script phase2-verify.sh exécuté
- [ ] RAM 8 GB détectée
- [ ] SonarQube toujours actif
- [ ] PostgreSQL actif
- [ ] Docker actif

### Phase 3 (DependencyTrack deploy)
- [ ] DB dependencytrack créée
- [ ] Dossier /opt/dependencytrack prêt
- [ ] Certificats SSL générés
- [ ] docker-compose.yml configuré
- [ ] .env configuré avec password PostgreSQL
- [ ] Stack déployée (`docker-compose up -d`)
- [ ] Interface accessible (https://...)
- [ ] Admin password changé ⚠️

---

## 📞 Questions/Problèmes

- Erreur à Phase 1? → Relancer le script ou consulter [00-server-cleanup-plan.md](00-server-cleanup-plan.md)
- Erreur à Phase 2? → Contactez OVH ou consultant DevOps
- Erreur à Phase 3? → Voir section troubleshooting ou consulter [01-deployment-dependencytrack.md](01-deployment-dependencytrack.md)

---

## 🎯 FIN

Une fois DependencyTrack opérationnel:

1. Configurer Slack (doc 02) — 30 min
2. Intégrer projets Git (doc 03) — 1h
3. Migration depuis Snyk — 30 min

**Bravo! 🎉 Vous avez DependencyTrack en production!**

