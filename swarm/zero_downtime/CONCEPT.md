# 🎯 Le Concept - Zero-Downtime Expliqué en 2 pages

## Ce que vous CHERCHEZ

**Mettre à jour UN SERVICE sans jamais couper l'accès à ce service pendant la mise à jour.**

Les opérations utilisateur **en cours** sur ce service doivent **continuer jusqu'à leur fin**, puis basculement gracieux vers la nouvelle version. Zéro interruption.

---

## L'Exemple: Update PHP

### Avant l'update
```
Utilisateur fait une requête: GET /home
                              ↓
                        Traefik (routes)
                        ↓
                   2 replicas PHP disponibles
                   ├─ Réplica A (PHP v8.2) - Active
                   └─ Réplica B (PHP v8.2) - Active
                        ↓
                   Traefik envoie à Réplica A
                        ↓
                   PHP process : execution
                        ↓
                   Response sent to user
```

### Pendant l'update (Réplica A)
```
⚠️  UPDATE LANCÉE: "Réplica A va être UPDATÉE"

-- Utilisateur dans requête active --
GET /home (EN COURS depuis 1s)
  ↓
Traefik: "Réplica A est marquée pour DRAIN"
  ├─ New requests: ↓ Réplica B
  └─ Active request: CONTINUE sur Réplica A
  ↓
Réplica A (DRAINING):
  └─ "Je termine la requête en cours"
  ├─ Reçoit pas de NEW requêtes
  ├─ La requête GET /home: CONTINUE
  └─ Userland code: Execute until end
  ↓
Response sent to user: ✅ RECEIVED (pas d'interruption!)
  ↓
Réplica A (now empty):
  √ Shutdown graceful (30-60s period)
  √ Arrêt propre du conteneur
  ↓
Réplica A: RESTART avec PHP v8.3
  √ Health checks: "OK? YES!"
  √ Traefik: "Back in load balancer"
  ↓
New requests: Équilibrées entre A (v8.3) et B (v8.2)
```

### Puis Réplica B
```
(Same process as Réplica A)

Réplica B (DRAINING):
  └─ Active requests: FINISH
  
Réplica B: Restart avec v8.3
```

### Après l'update
```
Utilisateur: "Je n'ai RIEN vu!"

Service PHP:
  ├─ Réplica A (v8.3) - Active
  ├─ Réplica B (v8.3) - Active
  └─ ZéRO downtime experienced! ✅
```

---

## Les Éléments Magiques qui font ça marcher 🪄

### 1. **Multiple Replicas** (minimum 2)
- Pendant qu'on updater Réplica A → Réplica B sert le trafic
- Pendant qu'on updater Réplica B → Réplica A (updatée) sert le trafic
- Résultat: Toujours au moins 1 réplica active

### 2. **Rolling Update** (update parallelism: 1)
```yaml
update_config:
  parallelism: 1  # ← CRUCIAL: Max 1 réplica à la fois
```
- Si `parallelism: 2` → Les 2 s'arrêtent ensemble = DOWNTIME!
- If `parallelism: 1` → 1 seule à la fois = L'autre continue = NO DOWNTIME!

### 3. **Connection Draining** (Grace Period)
```yaml
restart_policy:
  delay: 30s  # ← CRUCIAL: Laisser finir les requêtes
```
- Réplica reçoit "SIGTERM" (shutdown signal)
- Elle dit au serveur: "Stop accepting NEW connections"
- Elle FINIT les requêtes déjà en cours
- Après `delay` secondes → Force arrêt si pas fini
- Result: Requêtes JAMAIS interrompues à mi-chemin

### 4. **Health Checks** ✅
```yaml
healthcheck:
  test: ["CMD", "php-fpm", "-v"]
  start_period: 30s  # Grace avant checks
  interval: 10s       # Check every 10s
  retries: 3          # 3 failures = unhealthy
```
- Nouveau conteneur doit prouver qu'il fonctionne
- Pas de trafic vers un conteneur cassé
- Protège les utilisateurs

### 5. **Update Delays**
```yaml
update_config:
  delay: 45s  # Attendre avant Réplica B
```
- Valide que Réplica A fonctionne bien
- Si elle crash → Arrête la mise à jour
- Protège contre les mises à jour vers du code cassé

---

## Timeline Réel: 2 replicas

### ⚠️ IMPORTANT: Dépend de la TAILLE de l'image!

**Cas 1: Image DÉJÀ présente sur les nœuds (petites images < 200MB)**
```
00:00 - Start update Réplica A
00:00 - Réplica A: Marked for drain (Réplica B handles all traffic)
00:30 - Réplica A: Shutdown complete
00:30 - Réplica A: Restart with new version
01:00 - Réplica A: start_period (grace period = 30s)
01:30 - Réplica A: Health check passes
01:35 - Réplica A: Back in rotation (now serving traffic)

01:35 - Start update Réplica B
01:35 - Réplica B: Marked for drain (Réplica A handles all traffic)
02:05 - Réplica B: Shutdown complete
02:05 - Réplica B: Restart with new version
02:35 - Réplica B: start_period (grace period)
03:05 - Réplica B: Health check passes
03:10 - Réplica B: Back in rotation

TOTAL TIME: ~3 minutes
USER DOWNTIME: 0 SECONDS ✅
```

**Cas 2: GROSSE image (1.5GB) Sans pré-pull - ⚠️ À ÉVITER**
```
00:00 - Start update Réplica A
00:00 - Docker: "Image not found locally, pulling from registry..."
00:00→15:00 - IMAGE DOWNLOAD (15 minutes!) ⏳ ← PROBLÈME!
15:00 - Réplica A: Restart with new version
15:00→15:30 - start_period (grace period = 30s)
15:30 - Health check passes
15:35 - Réplica A: Back in rotation

... (repeat for Réplica B)

TOTAL TIME: ~30 minutes! 😱 (au lieu de 3!)
USER DOWNTIME: 0 SECONDS (mais très LENT)
```

**Cas 3: GROSSE image (1.5GB) AVEC pré-pull - ✅ RECOMMANDÉ**
```
PHASE 0 (PRÉ-PULL - fait AVANT l'update):
-15:00→00:00 - Télécharger image sur TOUS les nœuds en parallèle (Ansible)
00:00 - Image présente sur tous les nœuds

PHASE 1 (UPDATE - maintenant rapide):
00:00 - Start update Réplica A
00:00 - Réplica A: Marked for drain (Réplica B handles all traffic)
00:30 - Réplica A: Shutdown complete
00:30 - Réplica A: Restart with new version (image déjà là!)
01:00 - Réplica A: start_period (grace period = 30s)
01:30 - Réplica A: Health check passes
01:35 - Réplica A: Back in rotation

01:35 - Start update Réplica B
... (same as above)

TOTAL TIME: ~3 minutes (image déjà présente!)
USER DOWNTIME: 0 SECONDS ✅
```

---

## C'est la clé !

| Element | Rôle | Si Missing |
|---------|------|-----------|
| **2+ Replicas** | 1 sert pendant que 1 updater | = Downtime (aucune backup) |
| **parallelism: 1** | 1 seule à la fois | = Downtime (tout s'arrête) |
| **Connection Draining** | Finir les requêtes en cours | = Requêtes cassées |
| **Health Checks** | Valider new conteneur OK | = Trafic vers un conteneur cassé |
| **Update Delays** | Valider avant Réplica suivante | = Update vers du code cassé |

---

## Pour TOUS les services

### PHP
```
Avant:  2x PHP v8.2
Update: 1 réplica à la fois → V8.3
Après:  2x PHP v8.3
Zéro downtime? ✅ OUI
```

### Nginx
```
Avant:  2x Nginx 1.25
Update: 1 réplica à la fois → 1.26
Après:  2x Nginx 1.26
Zéro downtime? ✅ OUI
```

### Traefik
```
Avant:  2x Traefik 3.6
Update: 1 réplica à la fois → 3.7
Après:  2x Traefik 3.7
Zéro downtime? ✅ OUI
```

### Database
```
Avant:  1x DB 11.4 (unique but with graceful drain)
Update: Pause services < 5s, update, resume
Après:  1x DB 11.5
Zéro downtime? ✅ OUI (pour le service DB)
```

### Workers
```
Avant:  1x Workers + scale up to 3
Update: 1 réplica à la fois
Après:  1x Workers v8.3
Zéro downtime? ✅ OUI (jobs drainés gracefully)
```

---

## Résumé

**Le secret:** Avoir TOUJOURS au moins 1 réplica saine pendant que les autres s'updater, avec connection draining pour laisser finir les requêtes actives.

**Result:** Les utilisateurs NE VOIENT PAS L'UPDATE! 🎉

**Pour Chaque Service:** Independant, à votre rythme, zéro downtime GARANTI.

---

## ⚠️ Attention IMPORTANTE: Stratégie selon la TAILLE de l'image

### Images PETITES (< 200MB) - Nginx, Traefik, MariaDB
- **Pull pendant update:** ✅ OK
- **Timing:** 1-2 minutes de téléchargement max
- **Stratégie:** Pas de pré-pull nécessaire
- **Commande:** `docker service update --image <image>`

### Images GRANDES (> 1GB) - PHP (1.5GB), Workers (762MB)
- **Pull pendant update:** ❌ Problème! 10-15 minutes d'attente
- **Solution:** ✅ Pré-pull l'image AVANT l'update via Ansible
- **Timing:**
  - Pré-pull (Ansible, parallèle, 1x): 15 minutes
  - Update (rapide, image déjà là): 3 minutes
  - **Total: 18 minutes au lieu de 30+**
- **Commandes:**
  ```bash
  # Phase 0: Pré-pull (fait AVANT l'update)
  ansible-playbook pre-pull-images.yml
  
  # Phase 1: Update (rapide, image déjà présente)
  docker service update --image <image> <service>
  ```
