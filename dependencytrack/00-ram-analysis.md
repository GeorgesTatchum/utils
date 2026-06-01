# Analyse RAM détaillée - DependencyTrack vs SonarQube/Jenkins

## 🔴 Situation critique

### Consommateurs de RAM actuels

| Service | PID | %MEM | RSS (MB) | Notes |
|---------|-----|------|----------|-------|
| **SonarQube Elasticsearch** | 2849012 | 20.5% | 805 | Moteur de recherche ES |
| **Jenkins** | 722 | 17.9% | 702 | CI/CD server |
| **SonarQube CE Server** | 2849282 | 15.6% | 611 | Compute Engine |
| **SonarQube Web Server** | 2849140 | 15.2% | 595 | Interface web |
| **Datadog Agent** | 713 | 3.8% | 151 | Monitoring |
| **PostgreSQL** | 898 | 2.8% | 109 | Base de données |
| **Autres** | - | 9.2% | 160 | Système, Docker, etc. |
| **TOTAL** | - | 100% | 3,738 | **3.7 GB complet** |

### Espace disponible

```
RAM utilisée:    3,586 MB (96.5%)
RAM libre:         152 MB (4.1%)
```

---

## 💥 Conflit d'infrastructure

### DependencyTrack requirements

```
API Backend:     2,000 MB
Frontend:          512 MB
PostgreSQL:      1,000 MB (si nouveau)
Nginx:             128 MB
─────────────────────────
TOTAL:           3,640 MB minimum
```

### Impossible de faire coexister

```
SonarQube (2,615 MB)
+ Jenkins (702 MB)
+ DependencyTrack (3,640 MB)
= 6,957 MB REQUIS
─────────────────────────
Dispos: 3,738 MB
MANQUE: -3,219 MB (-86%)
```

---

## 🎯 Options réalistes

### Option A: ARRÊTER SonarQube (RECOMMANDÉ)

**Justification:**
- SonarQube = analyse de code
- DependencyTrack = gestion vulnérabilités
- Deux outils différents pour deux objectifs différents
- SonarQube + Jenkins peuvent tourner ailleurs ou être remplacés par DependencyTrack

**RAM libérée:**
```
SonarQube: 805 + 611 + 595 + 80 = 2,091 MB
Elasticsearch CLI: 80 MB
────────────────────────────────────
TOTAL: ~2,200 MB libérés
```

**État après action:**
```
RAM disponible: 152 + 2,200 = 2,352 MB
DependencyTrack requis: 3,640 MB
MANQUE: -1,288 MB (besoin 55% de plus)
```

❌ **Insuffisant seul**

---

### Option B: ARRÊTER SonarQube + Datadog

**Justification:**
- SonarQube: analyse code (optionnel)
- Datadog: monitoring (optionnel, peut utiliser Prometheus/Grafana)
- DependencyTrack: critique pour la sécurité

**RAM libérée:**
```
SonarQube:   2,091 MB
Datadog:     +151 MB
───────────────────────
TOTAL: 2,242 MB
```

**État après action:**
```
RAM disponible: 152 + 2,242 = 2,394 MB
DependencyTrack requis: 3,640 MB
MANQUE: -1,246 MB
```

❌ **Toujours insuffisant**

---

### Option C: ARRÊTER SonarQube + Jenkins (ALTERNATIF)

**Justification:**
- SonarQube = analyse code
- Jenkins = CI/CD
- DependencyTrack = sécurité vulnérabilités
- Jenkins peut être remplacé par GitHub Actions (gratuit)
- SonarQube peut être remplacé par analyse dans DependencyTrack

**RAM libérée:**
```
SonarQube: 2,091 MB
Jenkins:   +702 MB
Datadog:   +151 MB
───────────────────────
TOTAL: 2,944 MB
```

**État après action:**
```
RAM disponible: 152 + 2,944 = 3,096 MB
DependencyTrack requis: 3,640 MB
MANQUE: -544 MB (besoin 18% de plus)
```

⚠️ **Très serré, risqué**

---

### Option D: ARRÊTER TOUS LES TROIS (MAXIMUM)

**RAM libérée:**
```
SonarQube: 2,091 MB
Jenkins:   +702 MB
Datadog:   +151 MB
────────────────────────
TOTAL: 2,944 MB
```

**État après action:**
```
RAM disponible: 152 + 2,944 = 3,096 MB
DependencyTrack requis: 3,640 MB
MANQUE: -544 MB
```

❌ **Toujours 500 MB en moins**

---

### Option E: UPGRADE RAM (LONG TERME)

**Augmenter VPS RAM: 4 GB → 8 GB**

```
État avec 8 GB:
RAM utilisée: 3,586 MB
RAM libre: 4,414 MB (55%)
───────────────────────────
DependencyTrack peut déployer sans problème
Tous les services (SonarQube, Jenkins, DependencyTrack) cohabitent
```

**Coût:** ~€10-20/mois supplémentaire (dépend du provider)

✅ **Solution idéale, non urgente**

---

## 🎬 RECOMMANDATION

### Stratégie hybride

#### Étape 1: Déploiement DependencyTrack immédiat
```bash
# Arrêter SonarQube (qui consomme 2.1 GB)
sudo systemctl stop sonarqube
sudo systemctl disable sonarqube

# Gain: 2.1 GB RAM libre
# Disponible: 2.2 GB (insuffisant pour DependencyTrack seul)

# Configurer DependencyTrack avec moins de RAM
JAVA_OPTS="-Xmx1024m"  # API Backend limité à 1 GB au lieu de 2 GB

# Utiliser PostgreSQL 13 existant (gain 1 GB)
# Pas de PostgreSQL Docker
```

**État après:**
```
RAM disponible avant DT: ~2.2 GB
DT API:                  1.0 GB
DT Frontend:             0.5 GB
DT PostgreSQL (existing): 0 GB (externe)
Marge restante:          ~0.7 GB
```

✅ **Viable mais très serré**

#### Étape 2: Arrêter Jenkins (optionnel)
```bash
# Si DependencyTrack instable
sudo systemctl stop jenkins
sudo systemctl disable jenkins

# Remplacer par GitHub Actions (gratuit)
# Gain: +700 MB RAM
```

#### Étape 3: Upgrade RAM (long terme)
```bash
# Contactez le provider pour +4 GB RAM
# Cela permettra tout relancer
```

---

## 📋 PLAN D'ACTION

### Avant déploiement DependencyTrack

```bash
#!/bin/bash

# 1. Arrêter SonarQube
echo "Stopping SonarQube..."
sudo systemctl stop sonarqube
sudo systemctl disable sonarqube

# Vérifier les services arrêtés
sudo systemctl stop sonarqube.service || true
ps aux | grep -i sonar || echo "SonarQube stopped"

# 2. Vérifier RAM libérée
echo "RAM after stopping SonarQube:"
free -h

# 3. Vérifier PostgreSQL
echo "Testing PostgreSQL connection:"
sudo -u postgres psql -l | grep dependencytrack || \
  echo "Need to create dependencytrack DB"
```

### Configuration Docker Compose

**Limiter API Backend à 1 GB:**

```yaml
# /opt/dependencytrack/docker-compose.yml
dependencytrack-apiserver:
  environment:
    JAVA_OPTS: "-Xmx1024m -Xms512m"  # Limite mémoire
```

### .env

```bash
# .env
ALPINE_API_KEY=your-key-here
# SonarQube est arrêté, pas de limite supplémentaire
```

---

## ⚠️ RISQUES ET MITIGATIONS

### Risque: DependencyTrack instable avec 1 GB API

**Symptômes:**
- Timeouts sur les scans
- OOM (Out of Memory) errors
- Ralentissements

**Mitigation:**
```bash
# Augmenter JAVA_OPTS progressivement
# Commencer à 1 GB, monter à 1.5 GB si nécessaire
JAVA_OPTS="-Xmx1500m -Xms750m"

# Ou arrêter Jenkins en plus
sudo systemctl stop jenkins
```

### Risque: PostgreSQL instable

**Symptômes:**
- Connexions DB rejetées
- Slowness

**Mitigation:**
```bash
# SonarQube et DependencyTrack partagent PostgreSQL
# Créer bases/users séparées (déjà fait)

# Monitorer connexions
psql -U postgres -c "SELECT datname, count(*) FROM pg_stat_activity GROUP BY datname;"
```

---

## 📊 Scénarios de RAM

### Scénario 1: SonarQube arrêté (DÉPLOIEMENT MAINTENANT)

```
Avant:   152 MB libre
Action:  Arrêter SonarQube (-2.1 GB)
Après:   2.3 GB libre
─────────────────────
État:    ⚠️ LIMITE
Action:  Déployer DT avec Xmx=1024m
Risque:  Moyen (performances réduites)
```

✅ **Recommandé pour commencer**

### Scénario 2: SonarQube + Jenkins arrêtés

```
Avant:   152 MB libre
Action:  Arrêter SonarQube + Jenkins (-2.8 GB)
Après:   3.0 GB libre
─────────────────────
État:    ⚠️ LIMITE
Action:  Déployer DT avec Xmx=1024m
Risque:  Faible
```

✅ **Si Jenkins remplacé par GitHub Actions**

### Scénario 3: RAM upgrade 4 GB → 8 GB

```
Avant:   152 MB libre (sur 3.7 GB)
Action:  Upgrade VPS (+4 GB)
Après:   4.4 GB libre (sur 7.7 GB)
─────────────────────
État:    ✅ OPTIMAL
Action:  Relancer tous les services
Risque:  Aucun
```

✅ **Solution idéale, pas urgente**

---

## ✅ CHECKLIST PRÉ-DÉPLOIEMENT (RÉVISÉE)

- [ ] **CRITIQUE:** `sudo systemctl stop sonarqube`
- [ ] Vérifier RAM libre: `free -h` (doit être > 2 GB)
- [ ] Créer DB dependencytrack dans PostgreSQL 13
- [ ] Configurer docker-compose.yml avec `JAVA_OPTS="-Xmx1024m"`
- [ ] Tester PostgreSQL externe: `docker run --rm postgres:15-alpine psql -h host.docker.internal -U dependencytrack`
- [ ] Déployer DependencyTrack
- [ ] Monitorer RAM: `watch -n 5 'free -h'`
- [ ] Si instable: arrêter Jenkins aussi

---

## 📞 Contacts

| Situation | Action |
|-----------|--------|
| DT démarre mais lent | Arrêter Jenkins, relancer |
| DT crash fréquemment | Demander +4 GB RAM au provider |
| PostgreSQL refusé connexions | Augmenter max_connections |
| Frontend instable | Réduire à 256 MB, arrêter SonarQube |

---

## 🚀 COMMANDE DE DÉPLOIEMENT FINALE

```bash
#!/bin/bash
set -e

echo "=== DependencyTrack Emergency Deployment ==="

# 1. ARRÊTER SonarQube (MANDATORY)
echo "Stopping SonarQube to free 2.1 GB RAM..."
sudo systemctl stop sonarqube
sudo systemctl disable sonarqube
sleep 5

# 2. Vérifier RAM
RAM_AVAILABLE=$(free -h | grep Mem | awk '{print $7}')
echo "RAM available: $RAM_AVAILABLE"

# 3. Créer DB PostgreSQL
echo "Creating dependencytrack database..."
sudo -u postgres psql <<EOF
CREATE USER IF NOT EXISTS dependencytrack WITH PASSWORD 'change-me-secure';
CREATE DATABASE IF NOT EXISTS dependencytrack OWNER dependencytrack;
GRANT ALL PRIVILEGES ON DATABASE dependencytrack TO dependencytrack;
ALTER USER dependencytrack SUPERUSER;
EOF

# 4. Déployer DependencyTrack
cd /opt/dependencytrack
docker-compose up -d

# 5. Attendre prêt
echo "Waiting for services..."
sleep 30

# 6. Vérifier
docker-compose ps
docker logs dt-apiserver | tail -20

echo ""
echo "✅ DependencyTrack deployed (SonarQube stopped)"
echo "⚠️  DependencyTrack limited to 1 GB RAM"
echo "✅ Access: https://dependencytrack.oo-medical.local"
```

Sauvegarde et exécution:
```bash
chmod +x /opt/dependencytrack/scripts/emergency-deploy.sh
/opt/dependencytrack/scripts/emergency-deploy.sh
```

