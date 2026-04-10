# Blue-Green Single Service Deployment - Contexte Médical

## La Question

> "Blue-Green pour UN SEUL service à la fois - c'est adapté domaine médical?"

**Réponse: OUI, probablement MIEUX que whole-stack Blue-Green**

Pourquoi? Parce qu'on maintient la plupart du stack stable tandis qu'on teste UN service à la fois.

---

## Architecture: Blue-Green Single-Service

```
Services Stables (v1.0):          Service en Update (Dual):
┌──────────────────────────────┐  ┌──────────────────────────────┐
│ Nginx (v1.0)      ✓ Stable   │  │ PHP-Blue (v1.0)     ✓ Current│
│ Traefik (v1.0)    ✓ Stable   │  │ PHP-Green (v1.1)    ⚠️ NEW    │
│ MariaDB (v1.0)    ✓ Stable   │  │                               │
│ Workers (v1.0)    ✓ Stable   │  │ Traffic: PHP-Blue = 100%     │
└──────────────────────────────┘  │ Traffic: PHP-Green = 0%      │
                                  └──────────────────────────────┘
        ↓                                      ↓
     No changes during update         Update tested gradually
     Full backward compatibility      Rollback = switch label
```

---

## Comparaison: 3 Approches

### Approche 1: Rolling Updates Simple (Risqué)
```
PHP: v1.0 → v1.1 (rolling, 1 à la fois)
Nginx: v1.0 (unchanged)
DB: v1.0 (unchanged)

Risques résiduels:
⚠️  PHP.1 exécute v1.0, puis bascule à v1.2
⚠️  Nginx reste v1.0, peut pas être compatible v1.1 PHP
⚠️  Requête part de Nginx v1.0 à PHP v1.3 (mismatch!)
```

### Approche 2: Blue-Green Whole Stack (Safe mais Lourd)
```
BLUE env:              GREEN env:
- PHP v1.0             - PHP v1.1
- Nginx v1.0           - Nginx v1.1
- Traefik v1.0         - Traefik v1.1
- DB v1.0              - DB v1.1 (migrated)

Infrastructure: 2x complète! (Coûteux)
Avantages: Parfait isolement
Inconvénients: Overhead énorme
Temps: Long (30-60 min)
```

### Approche 3: Blue-Green Single Service (Pragmatique) ✅
```
PHP: v1.0 (Blue) ↔ v1.1 (Green) - UPDATE THIS
Nginx: v1.0 (unchanged)          - PROVEN STABLE
Traefik: v1.0 (unchanged)        - PROVEN STABLE
DB: v1.0 (unchanged)             - PROVEN STABLE

Infrastructure: 1 seule service dupliquée
Avantages: Safe + léger
Inconvénients: Besoin tested backward compatibility
Temps: Rapide (5-10 min)
```

---

## C'est Safe en Domaine Médical? OUI mais avec Conditions

### Scénario Idéal: Feature PHP Compatible

```
Mise à jour: PHP v1.0 → v1.1
Change: "Ajouter nouvelle colonne patient.insurance_id"

Condition 1: Backward Compatibility
  ✓ PHP v1.1 lit patient.insurance_id si présent
  ✓ PHP v1.1 utilise NULL si colonne absente
  ✓ Nginx v1.0 continue router normalement
  ✓ No breaking changes

Condition 2: Database Safe
  ✓ Migration: ADD COLUMN patient.insurance_id (nullable)
  ✓ Exécutée AVANT traffic switch
  ✓ No table locks (script optimisé)
  ✓ Rollback possible (DROP COLUMN)

Timeline:
T+0:00  | Prépare PHP v1.1 image
T+0:05  | Run DB migration (ADD COLUMN)
T+0:06  | Start PHP-Green v1.1 (3 replicas)
T+0:10  | Health checks
T+0:12  | 10% traffic → PHP-Green
T+0:15  | Monitor (10 min)
T+0:25  | 100% traffic → PHP-Green
T+0:26  | Done!

Downtime: 0 min ✓
Risk: Minimal ✓
Rollback: < 30 seconds ✓
Medical Safe: YES ✓
```

---

## Quand C'est SAFE (Médical)

### ✅ Safe Si:

1. **Service Update est Isolated**
   - Change PHP code, mais:
     - Nginx pas touché
     - DB schema compatible (backward)
     - API contracts preserved

2. **Backward Compatibility Guarantie**
   - PHP v1.1 parle avec Nginx v1.0
   - PHP v1.1 parle avec DB v1.0 (si migration prior)
   - No breaking changes

3. **Database Migration Préalable**
   - Schema changes AVANT code déploiement
   - Colonne ? ADD COLUMN nullable
   - Tabelle structure ? Expand avec alter-table-safe

4. **Testing Complet**
   - Code review
   - Unit tests
   - Integration tests (PHP ↔ Nginx ↔ DB)
   - Tested in preprod 24h minimum

5. **Service Indépendant**
   - PHP indépendant = OK
   - Nginx change + PHP change = risqué
   - Workers change seul = OK (async)

---

## Quand C'est RISQUÉ (NON Safe)

### ⚠️ Risqué Si:

1. **API Breaking Changes**
   ```
   PHP v1.0: POST /api/patient {"name": "Jean"}
   PHP v1.1: POST /api/patient {"first_name": "Jean", "last_name": "..."}
   
   Nginx v1.0 sends old format → PHP v1.1 error!
   Requête fails, audit error
   ❌ NOT SAFE
   ```

2. **Database Schema Breaking**
   ```
   PHP v1.1 expects: SELECT patient.insurance_id
   DB v1.0: Column doesn't exist yet!
   Error: "Unknown column"
   ❌ NOT SAFE
   ```

3. **Multi-Service Coordinated Changes**
   ```
   "Update PHP et Nginx ensemble"
   
   Why risky:
   - One fails, other is bleeding-edge
   - No rollback atomic
   - Mismatch protocol versions
   ❌ NOT SAFE
   ```

4. **Long-Running Operations**
   ```
   PHP v1.0: Request 120 secondes (rapport,export)
   Update happen at T+60
   Requête migrate mid-execution
   Rapport incomplet
   ❌ NOT SAFE
   ```

5. **State Changes** (sessions, cache)
   ```
   PHP v1.0: Session format = JSON
   PHP v1.1: Session format = Protobuf
   
   User avec PHP v1.0 session → redirect to PHP v1.1
   Session format incompatible!
   Auth fails, user experience broken
   ❌ NOT SAFE
   ```

---

## Matrice de Décision: Service par Service

```
╔════════════════════════════════════════════════════════════════════════════╗
║ SERVICE   │ TYPE CHANGE    │ RISK    │ STRATEGY            │ MEDICAL SAFE ║
╠════════════════════════════════════════════════════════════════════════════╣
║ PHP       │ Bugfix         │ Low     │ Blue-Green single   │ ✅ YES       ║
║           │ Small feature  │ Low     │ Blue-Green single   │ ✅ YES       ║
║           │ API changes    │ High    │ Blue-Green + Nginx  │ ❌ NO        ║
║           │ Database call  │ Medium  │ Blue-Green if safe  │ ⚠️ MAYBE     ║
╠════════════════════════════════════════════════════════════════════════════╣
║ Nginx     │ Config change  │ Low     │ Rolling or BG       │ ✅ YES       ║
║           │ Protocol vers  │ High    │ Blue-Green + PHP    │ ❌ NO        ║
║           │ URL rewrites   │ Medium  │ Blue-Green single   │ ⚠️ MAYBE     ║
╠════════════════════════════════════════════════════════════════════════════╣
║ Traefik   │ Routing rules  │ High    │ Blue-Green whole    │ ⚠️ MAYBE     ║
║           │ TLS cert       │ Low     │ Rolling OK          │ ✅ YES       ║
║           │ Load balance   │ Medium  │ Blue-Green single   │ ⚠️ MAYBE     ║
╠════════════════════════════════════════════════════════════════════════════╣
║ MariaDB   │ Patch vers     │ Low     │ Rolling OK          │ ✅ YES       ║
║           │ Schema change  │ High    │ Scheduled window    │ ✅ YES       ║
║           │ Data migration │ High    │ Scheduled window    │ ✅ YES       ║
╠════════════════════════════════════════════════════════════════════════════╣
║ Workers   │ Code update    │ Low     │ Blue-Green single   │ ✅ YES       ║
║           │ Queue format   │ High    │ Blue-Green + coord  │ ❌ NO        ║
╚════════════════════════════════════════════════════════════════════════════╝
```

---

## Implémentation: Blue-Green Single Service (PHP Example)

### Architecture Docker Swarm

```yaml
version: '3.9'

services:
  # Current Production
  php-blue:
    image: one-plateforme/php:v1.0
    networks:
      - swarm-net
    environment:
      - ENVIRONMENT_LABEL=blue
    labels:
      - "traefik.http.services.php.loadbalancer.servers=http://php-blue:9000"
    deploy:
      replicas: 3
      labels:
        - "service.version=v1.0"
        - "service.environment=blue"

  # New Version (Empty Initially)
  php-green:
    image: one-plateforme/php:v1.0  # Same as blue initially
    networks:
      - swarm-net
    environment:
      - ENVIRONMENT_LABEL=green
    labels:
      - "traefik.http.services.php.loadbalancer.servers=http://php-blue:9000"  # Point to blue
    deploy:
      replicas: 0  # Start disabled
      labels:
        - "service.version=v1.0"
        - "service.environment=green"

  nginx:
    image: one-plateforme/nginx:v1.0  # UNCHANGED
    depends_on:
      - php-blue
    networks:
      - swarm-net
    deploy:
      replicas: 2

  # ... autres services unchanged ...
```

### Processus de Déploiement

**Step 1: Préparer Green**

```bash
#!/bin/bash
# Update green to new version

echo "Step 1: Update Green Image"

# Update compose file
sed -i 's/php-green:.*v1.0/php-green:v1.1/g' docker-compose.yml

# Start green with new version
docker service scale oo_php-green=3

# Wait for health
for i in {1..30}; do
  GREEN_HEALTHY=$(docker service ps oo_php-green --format "{{.CurrentState}}" | \
    grep -c "Running" || echo "0")
  
  if [ "$GREEN_HEALTHY" -eq 3 ]; then
    echo "✓ Green v1.1 healthy (3 replicas running)"
    break
  fi
  
  echo "  Waiting... ($i/30)"
  sleep 10
done
```

**Step 2: Run Database Migrations (if needed)**

```bash
#!/bin/bash
# Only if PHP v1.1 needs new schema

echo "Step 2: Database Migrations"

# Get green PHP container
GREEN_CONTAINER=$(docker ps --filter "label=com.docker.swarm.service.name=oo_php-green" \
  --format '{{.ID}}' | head -1)

if [ -n "$GREEN_CONTAINER" ]; then
  # Run migrations
  docker exec $GREEN_CONTAINER php artisan migrate --force
  
  if [ $? -eq 0 ]; then
    echo "✓ Migrations successful"
  else
    echo "❌ Migrations failed!"
    # Rollback: scale down green
    docker service scale oo_php-green=0
    exit 1
  fi
fi
```

**Step 3: Health Checks**

```bash
#!/bin/bash
# Verify green is healthy before switching traffic

echo "Step 3: Health Checks"

# Test health endpoint
for i in {1..10}; do
  HEALTH=$(curl -s -f http://localhost:9001/health 2>/dev/null | grep -q "OK")
  
  if [ $? -eq 0 ]; then
    echo "✓ Health endpoint OK"
    break
  fi
  
  echo "  Retrying... ($i/10)"
  sleep 5
done

# Test critical APIs
echo "  Testing patient API..."
curl -s -f -H "Authorization: Bearer test" \
  http://localhost:9001/api/v1/patients/1 > /dev/null && echo "  ✓ OK" || echo "  ❌ FAIL"

echo "  Testing prescription API..."
curl -s -f -H "Authorization: Bearer test" \
  http://localhost:9001/api/v1/prescriptions > /dev/null && echo "  ✓ OK" || echo "  ❌ FAIL"
```

**Step 4: Traffic Switch (Canary)**

```bash
#!/bin/bash
# Switch traffic gradually: 10% → 50% → 100%

echo "Step 4: Traffic Switch"

# Current: 100% blue, 0% green
# Target: Gradually shift to green

# 10% to green
echo "Switching 10% traffic to green..."
docker service update \
  --label-add "traffic-split=10-green-90-blue" \
  oo_nginx

# Monitor 5 min
for i in {1..5}; do
  echo "  Monitoring... ($i/5 min)"
  docker service logs oo_php-green --tail 50 | grep -i error && echo "  ⚠️ Errors detected!" && exit 1
  sleep 60
done
echo "  ✓ 10% canary stable"

# 50% to green
echo "Switching 50% traffic to green..."
docker service update \
  --label-add "traffic-split=50-green-50-blue" \
  oo_nginx

for i in {1..5}; do
  echo "  Monitoring... ($i/5 min)"
  docker service logs oo_php-green --tail 50 | grep -i error && echo "  ⚠️ Errors detected!" && exit 1
  sleep 60
done
echo "  ✓ 50% canary stable"

# 100% to green
echo "Switching 100% traffic to green..."
docker service update \
  --label-add "traffic-split=0-green-100-blue" \
  oo_nginx

echo "✓ Traffic switch complete"
echo "  PHP-Green v1.1 now serving 100%"
echo "  PHP-Blue v1.0 on standby for rollback"
```

**Step 5: Finalize (Make Green the New Blue)**

```bash
#!/bin/bash
# After 24h validation, promote green → blue

echo "Step 5: Finalize"

# After 24h+ observation
read -p "Ready to promote green to blue? (y/n) " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
  # Blue can be scaled down
  docker service scale oo_php-blue=0
  
  # Green becomes the new blue (optional rename)
  echo "✓ Green promoted to primary"
  echo "✓ Old blue can be decommissioned"
fi
```

---

## Rollback Process (Emergency)

```bash
#!/bin/bash
# If green fails, revert immediately

echo "🚨 EMERGENCY ROLLBACK"

# Switch all traffic back to blue
docker service update \
  --label-add "traffic-split=0-green-100-blue" \
  oo_nginx

echo "✓ [T+5s] Traffic back to blue v1.0"

# Verify blue is handling traffic
curl -f http://localhost:9000/health > /dev/null && \
  echo "✓ [T+10s] Blue healthy, requests flowing" || \
  echo "❌ Blue unhealthy!"

# Green stays running for investigation
echo ""
echo "Green v1.1 still running - do NOT delete"
echo "Proceed to investigation:"
echo "  docker service logs oo_php-green --tail 100"
echo "  docker service ps oo_php-green"
```

---

## Risques Résiduels: Blue-Green Single Service

### Risk Level: LOW (compared to rolling updates)

| Risk | Mitigated? | How |
|------|-----------|-----|
| API Breaking | ✅ YES | Tested in preprod |
| DB Schema | ✅ YES | Migration prior to traffic |
| Inter-service mismatch | ⚠️ PARTIAL | Backward compatibility required |
| Transaction cut-off | ✅ YES | Both versions available 24h |
| Audit trail | ✅ YES | Both containers labeled clearly |

### Residual Risks to Accept

```
1. Version Mismatch Mini
   - PHP v1.1 + Nginx v1.0 = OK if tested
   - Risk: API slight variation
   - Mitigation: Comprehensive testing

2. Session State Incompatibility
   - If PHP changes session format
   - Risk: User session invalid
   - Mitigation: Session coexistence or migration

3. Cache Invalidation
   - PHP v1.1 uses different cache keys
   - Risk: Cache miss → slow response
   - Mitigation: Accept brief slowdown

4. Async Jobs Queue Format
   - If workers queue format changes
   - Risk: Old jobs fail in new code
   - Mitigation: Drain queue before deploy

5. Monitoring/Logging Changes
   - New version might log differently
   - Risk: Missing data in observability
   - Mitigation: Configure before deploy
```

---

## Checklist: Blue-Green Single Service (Medical)

```
PRE-DEPLOYMENT:
☐ Change analysis: Is it isolated to PHP only?
☐ Backward compatibility: Will v1.1 work with nginx v1.0?
☐ Database: Any schema changes? Run migrations prior.
☐ Testing: Code Review + Unit Tests + Integration Tests
☐ Preprod: Deployed and validated 24h minimum
☐ Team: Medical + DevOps approved
☐ Rollback: Plan documented
☐ Monitoring: Logs + metrics active

DEPLOYMENT:
☐ Scale PHP-Green to same as PHP-Blue
☐ Wait for health checks 100%
☐ If DB migration: Run and verify
☐ Test critical APIs on Green
☐ Switch 10% traffic, monitor 5-10 min
☐ Switch 50% traffic, monitor 5-10 min
☐ Switch 100% traffic
☐ Validate 24h before finalizing

FINALIZE:
☐ Blue v1.0 kept for 24h+ (rollback)
☐ Monitoring confirms stable
☐ No errors in logs
☐ Performance metrics normal
☐ Blue can be scaled down
```

---

## Timeline Comparison

### Rolling Updates Simple (Risqué)
```
Total time: 5-10 minutes
Risk: HIGH
Downtime: 0
Rollback: ❌ Impossible
Medical Safe: ❌ NO
```

### Blue-Green Single Service (Recommandé)
```
Prépare Green:    5 min
DB Migration:     5 min (si needed)
Health Tests:     5 min
Traffic switch:   10 min (10% → 50% → 100%)
Post-validation:  24h monitoring
Total: 30 minutes + 24h observation
Risk: LOW
Downtime: 0
Rollback: ✅ 30 seconds
Medical Safe: ✅ YES (if backward compatible)
```

### Blue-Green Whole Stack (Safest)
```
Total time: 45-60 minutes
Risk: VERY LOW
Downtime: 0
Rollback: ✅ 1 minute
Medical Safe: ✅ YES (definitely)
Infrastructure: 2x costly
When to use: Major versions, DB changes, uncertainty
```

---

## Recommandation Finale: Contexte Médical

### Pour Mise à Jour Service Unique:

**✅ UTILISEZ: Blue-Green Single Service**

**SI:**
- Change est isolated (PHP code seulement)
- Backward compatibility garantie
- Database safe migrations (nullable columns, etc)
- Testing complet avant deployment
- APIs unchanged (or compatible)

**QUAND:**
- PHP bugfix/feature
- Workers update (async, independent)
- Nginx config change (non-breaking)

**NE UTILISEZ PAS (use whole-stack Blue-Green instead):**
- Changes multiples services
- API breaking changes
- Major database refactoring
- Protocol changes
- Uncertain backward compatibility

---

## Conclusion

**La stratégie Blue-Green Single Service est TRÈS ADAPTÉE au contexte médical pour mises à jour individuelles.**

### Avantages vs Rolling Updates:
- ✅ Version cohérente = No hybrid execution
- ✅ Backward compatible = Tested properly
- ✅ Rollback rapide = Safety net
- ✅ Audit trail pur = Each replica labeled
- ✅ Zero downtime = Medical requirement met

### Avantages vs Whole-Stack Blue-Green:
- ✅ Moins d'infrastructure
- ✅ Déploiement plus rapide (20 min vs 60 min)
- ✅ Plus simples à opérer
- ✅ Coûts réduits

### C'est le "sweet spot" pour domaine médical:
✅ Safe (low risk residual)
✅ Fast (20-30 min total)
✅ Simple (one service at a time)
✅ Scalable (repeat for each service)

**Recommandation: Implémenter cette stratégie pour service individual updates en production médicale.**
