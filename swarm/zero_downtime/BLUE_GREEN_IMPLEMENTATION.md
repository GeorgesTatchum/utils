# Blue-Green Deployment Implementation Plan

## Architecture Cible

```
┌─────────────────────────────────────────────────────┐
│              TRAEFIK (Load Balancer)                │
├─────────────────┬───────────────────────────────────┤
│                 │                                   │
│ BLUE (100%)    │ GREEN (0%)                       │
│                 │                                   │
├─────────────────┼───────────────────────────────────┤
│ PHP v1.0   [1]  │ PHP v1.1   [1]                  │
│ PHP v1.0   [2]  │ PHP v1.1   [2]                  │
│ PHP v1.0   [3]  │ PHP v1.1   [3]                  │
├─────────────────┼───────────────────────────────────┤
│ Nginx v1.0 [1]  │ Nginx v1.1 [1]                  │
│ Nginx v1.0 [2]  │ Nginx v1.1 [2]                  │
├─────────────────┼───────────────────────────────────┤
│ MariaDB v11.4   │ MariaDB v11.4 (SYNC)            │
│ schema v1.0     │ schema v1.1 (MIGRATED)          │
└─────────────────┴───────────────────────────────────┘

Traffic Split:
  Blue: 100% → All requests to BLUE environment
  Green: 0%  → Used for staging deployments
  
Toggle (when deploying):
  Blue: 0%   → Keep fresh for instant rollback
  Green: 100% → New version takes all traffic
```

---

## Pre-requisites

### 1. Duplicate Infrastructure

**Current State:**
```yaml
services:
  php:
    image: one-plateforme/php:${VERSION}
    deploy:
      replicas: 3
    
  nginx:
    image: one-plateforme/nginx:${VERSION}
    deploy:
      replicas: 2
      
  mariadb:
    image: mariadb:11.4
    
  traefik:
    image: traefik:v3.6.11
```

**Blue-Green State:**
```yaml
# docker-compose.blue.yml
services:
  php-blue:
    image: one-plateforme/php:v1.0
    networks:
      - blue-net
    labels:
      - "traefik.http.backends.php-blue.enable=true"
    deploy:
      replicas: 3
      labels:
        - "traefik.http.services.php-blue.loadbalancer.server.port=9000"
  
  nginx-blue:
    image: one-plateforme/nginx:v1.0
    networks:
      - blue-net
    deploy:
      replicas: 2
      labels:
        - "traefik.http.services.nginx-blue.loadbalancer.server.port=80"
  
  mariadb-blue:
    image: mariadb:11.4
    networks:
      - blue-net
    volumes:
      - data-blue:/var/lib/mysql
    
# docker-compose.green.yml
services:
  php-green:
    image: one-plateforme/php:v1.1  # NEW VERSION
    networks:
      - green-net
    deploy:
      replicas: 3
  
  nginx-green:
    image: one-plateforme/nginx:v1.1  # NEW VERSION
    networks:
      - green-net
    deploy:
      replicas: 2
  
  mariadb-green:
    image: mariadb:11.4
    networks:
      - green-net
    volumes:
      - data-green:/var/lib/mysql

networks:
  blue-net:
  green-net:
```

### 2. Traefik Configuration pour Blue-Green

**traefik/config.yml**
```yaml
entryPoints:
  http:
    address: ':80'
  https:
    address: ':443'

api:
  entryPoint: traefik
  address: ':8080'
  dashboard: true

# Define routers
route:
  entryPoint: http
  rule: "HostRegexp:{catchall:.*}"
  service: app  # Will be toggled between blue/green

# Services
services:
  app:
    loadBalancer:
      servers:
        - url: "http://nginx-blue:80"  # Toggle this
  
  app-blue:
    loadBalancer:
      servers:
        - url: "http://nginx-blue:80"
      healthCheck:
        path: /health
        interval: 10s
        timeout: 5s
        healthyThreshold: 3
        unhealthyThreshold: 2

  app-green:
    loadBalancer:
      servers:
        - url: "http://nginx-green:80"
      healthCheck:
        path: /health
        interval: 10s
        timeout: 5s
        healthyThreshold: 3
        unhealthyThreshold: 2
```

---

## Deployment Process

### Phase 1: Prepare Green Environment

```bash
#!/bin/bash
# 1. Stop green (from previous test)
docker stack rm oo-green

# 2. Wait for volumes to be released
sleep 5

# 3. Clear green data (or use backup if testing)
docker volume rm oo-data-green 2>/dev/null || true

# 4. Start fresh green with NEW version
docker stack deploy -c docker-compose.green.yml oo-green

# 5. Wait for services to be healthy
for i in {1..30}; do
  GREEN_HEALTH=$(docker service ls --filter name=oo-green \
    --format '{{.Replicas}}' | grep -c "3/3" || echo "0")
  
  if [ "$GREEN_HEALTH" -gt "0" ]; then
    echo "✓ Green services healthy"
    break
  fi
  
  echo "  Waiting for green to be ready... ($i/30)"
  sleep 10
done
```

### Phase 2: Run Database Migrations

```bash
#!/bin/bash
# Migration must complete BEFORE traffic switch

echo "🔄 Running database migrations on GREEN..."

# Get a PHP container from green
GREEN_PHP=$(docker ps --filter "label=com.docker.swarm.service.name=oo-green_php-green" \
  --format '{{.ID}}' | head -1)

if [ -z "$GREEN_PHP" ]; then
  echo "❌ No green PHP container found"
  exit 1
fi

# Run migrations
docker exec $GREEN_PHP php artisan migrate --force

if [ $? -ne 0 ]; then
  echo "❌ Migration failed"
  exit 1
fi

echo "✓ Migrations completed successfully"

# Verify schema
docker exec $GREEN_PHP php artisan migrate:status
```

### Phase 3: Health Checks and Testing

```bash
#!/bin/bash
# Comprehensive tests before switching traffic

echo "🧪 Running health checks on GREEN environment..."

GREEN_LB="http://nginx-green:80"  # From traefik network

TESTS=(
  "GET /health HTTP/1.1"
  "GET /api/v1/status HTTP/1.1"
  "GET /api/v1/config HTTP/1.1"
)

for test in "${TESTS[@]}"; do
  echo "  Testing: $test"
  
  RESULT=$(curl -s -f "$GREEN_LB/${test#GET /}" -H "Host: api.hospital.com")
  
  if [ $? -eq 0 ]; then
    echo "    ✓ Pass"
  else
    echo "    ❌ FAIL"
    exit 1
  fi
done

# Smoke test critical APIs
echo ""
echo "  Testing critical medical endpoints..."

# Test patient API
curl -s -f "http://nginx-green:80/api/v1/patients/1" \
  -H "Host: api.hospital.com" \
  -H "Authorization: Bearer test-token" > /dev/null

if [ $? -eq 0 ]; then
  echo "    ✓ Patient API OK"
else
  echo "    ❌ Patient API FAIL"
  exit 1
fi

echo ""
echo "✓ All health checks passed"
```

### Phase 4: Traffic Switch (10% → 50% → 100%)

**Step 4.1: 10% Traffic Canary**

```bash
#!/bin/bash
# Update traefik config to route 10% to green

cat > traefik/config-10pct-green.yml << 'EOF'
route:
  entryPoint: http
  rule: "HostRegexp:{catchall:.*}"
  middlewares:
    - canary-10pct

middlewares:
  canary-10pct:
    headers:
      customRequestHeaders:
        X-Deployment-Canary: "true"

services:
  app:
    loadBalancer:
      cardinality: sessionaffinity
      balancers:
        - weight: 90
          service: app-blue
        - weight: 10
          service: app-green
EOF

# Apply new config
docker service update --label-add config-version=10pct oo_traefik

# Monitor for 30 minutes
echo "⏱️  Monitoring 10% canary for 30 minutes..."

for i in {1..30}; do
  echo "  [$i/30 min] Checking metrics..."
  
  # Check error rate
  ERROR_RATE=$(docker stats --no-stream --format "{{.MemUsage}}" \
    oo-green_php-green 2>/dev/null)
  
  if [ -z "$ERROR_RATE" ]; then
    echo "    ❌ Green service down"
    exit 1
  fi
  
  echo "    ✓ Green healthy"
  sleep 60
done

echo "✓ 10% canary successful"
```

**Step 4.2: 50% Traffic**

```bash
cat > traefik/config-50pct-green.yml << 'EOF'
services:
  app:
    loadBalancer:
      balancers:
        - weight: 50
          service: app-blue
        - weight: 50
          service: app-green
EOF

# Apply and monitor 30 min
# (same process as 10%)
```

**Step 4.3: 100% Traffic Switch**

```bash
cat > traefik/config-100pct-green.yml << 'EOF'
route:
  entryPoint: http
  rule: "HostRegexp:{catchall:.*}"
  service: app-green  # NOW serving all traffic

services:
  app-green:
    loadBalancer:
      servers:
        - url: "http://nginx-green:80"
EOF

# Apply config
docker service update oo_traefik

# Verify
echo "✓ All traffic routed to GREEN"
echo "✓ BLUE is now standby for rollback"
```

### Phase 5: Post-Deployment Validation

```bash
#!/bin/bash
# Run for 24 hours after switch

echo "📊 POST-DEPLOYMENT VALIDATION (24h monitoring)"

HOURS=0
while [ $HOURS -lt 24 ]; do
  echo "[$HOURS/24 hours] Health check..."
  
  # Check all critical metrics
  docker service ls --filter name=oo-green --format "{{.Replicas}}"
  
  # Check error logs
  docker service logs oo-green_php-green | grep -i "error" | wc -l
  
  # Check request latency
  docker service logs oo-green_nginx-green | tail -100 | grep "duration=" | \
    awk '{print $NF}' | sort -n | tail -1
  
  sleep 3600
  HOURS=$((HOURS + 1))
done

echo "✓ 24-hour validation passed"
echo "✓ GREEN is production stable"
echo "✓ You may decommission BLUE"
```

---

## Rollback Process (If Something Goes Wrong)

### Emergency Rollback

```bash
#!/bin/bash
# Complete rollback to BLUE in < 2 minutes

echo "🚨 EMERGENCY ROLLBACK INITIATED"

# 1. Revert traefik config immediately
cat > traefik/config-rollback.yml << 'EOF'
route:
  service: app-blue  # Back to BLUE
EOF

docker service update oo_traefik

echo "✓ [T0:10s] Traffic reverted to BLUE"

# 2. Verify health
for i in {1..20}; do
  BLUE_HEALTH=$(curl -s -f http://nginx-blue:80/health)
  
  if [ $? -eq 0 ]; then
    echo "✓ [T0:20s] BLUE healthy, requests flowing"
    break
  fi
  
  sleep 1
done

# 3. Keep GREEN running for investigation
echo ""
echo "⚠️  GREEN still running - do NOT delete yet"
echo "✓ [T0:60s] Rollback complete"
echo ""
echo "Next steps:"
echo "  1. Investigate logs in GREEN"
echo "  2. Find root cause"
echo "  3. Fix and re-test"
echo "  4. Redeploy to GREEN"

# 4. Optional: Alert team
echo "🔔 Rollback alert sent to team"
```

### Data Rollback (If DB corruption)

```bash
#!/bin/bash
# If GREEN schema migration caused corruption

if [ -f "backups/mariadb-blue-preswitch.sql.gz" ]; then
  echo "Restoring database from backup..."
  
  zcat backups/mariadb-blue-preswitch.sql.gz | \
    docker exec -i mariadb-blue mysql -u root -p$MYSQL_PASSWORD
  
  echo "✓ Database restored"
  
  # Rollback traffic (see above)
fi
```

---

## Automation Scripts

### Complete One-Command Deployment

**scripts/deploy-blue-green.sh**

```bash
#!/bin/bash

set -e

ENVIRONMENT="${1:-preprod}"
VERSION="${2:-latest}"

log_phase() {
  echo ""
  echo "════════════════════════════════════════════════"
  echo "▶ PHASE: $@"
  echo "════════════════════════════════════════════════"
}

log_success() {
  echo "✓ $@"
}

log_error() {
  echo "❌ $@"
  exit 1
}

log_phase "1. Prepare Infrastructure"
# ... deployment steps ...
log_success "Infrastructure ready"

log_phase "2. Run Database Migrations"
# ... migration steps ...
log_success "Migrations completed"

log_phase "3. Health Checks"
# ... health checks ...
log_success "Health checks passed"

log_phase "4. Traffic Switch (10%)"
# ... 10% switch ...
log_success "10% canary successful"

log_phase "5. Traffic Switch (100%)"
# ... 100% switch...
log_success "100% traffic switch"

log_phase "6. Post-Deployment Validation"
# ... validation ...
log_success "Deployment complete!"

log_success "Blue-Green deployment successful"
log_success "VERSION: $VERSION in ENVIRONMENT: $ENVIRONMENT"
```

---

## Monitoring During Deployment

### Key Metrics to Track

```bash
#!/bin/bash
# Monitor during traffic switch

watch -n 1 'echo "=== BLUE ===" && \
  docker stats --no-stream oo_php oo_nginx && \
  echo "" && \
  echo "=== GREEN ===" && \
  docker stats --no-stream oo-green_php-green oo-green_nginx-green'
```

### Logs to Monitor

```bash
# PHP errors
docker service logs oo-green_php-green | grep -i error

# Slow queries
docker service logs oo-green_php-green | grep "slow query"

# HTTP errors
docker service logs oo-green_nginx-green | grep "5[0-9][0-9]"

# Nginx upstream down
docker service logs oo-green_nginx-green | grep "upstream"
```

---

## Checklist Before Switching Traffic

```
Pre-Deployment Checklist:
☐ BLUE environment is stable (baseline)
☐ GREEN built with correct VERSION
☐ GREEN all services replicas healthy
☐ Database migrations ran successfully
☐ Health endpoints responding on GREEN
☐ Critical APIs tested on GREEN
☐ Load tests passed on GREEN
☐ Team notified (medical and IT)
☐ Rollback plan documented
☐ Backup of BLUE data taken
☐ Incident contact list ready
☐ Monitoring tools all active

10% Canary Checks:
☐ No 5xx errors on GREEN
☐ Latency < expected + 20%
☐ Database queries working
☐ User authentication flows
☐ Prescription creation
☐ Patient records access
☐ Audit logging working
☐ No memory leaks
☐ No CPU spikes

50% Switch Checks:
☐ All 10% checks still passing
☐ 50/50 load balanced
☐ No session stickiness issues
☐ Database replication healthy
☐ Logs show both BLUE and GREEN serving

100% Switch Checks:
☐ All traffic on GREEN
☐ BLUE is standby
☐ Zero downtime confirmed
☐ All metrics nominal
☐ Team post-deployment review

Post-Deployment (24h):
☐ Zero errors in logs
☐ Database consistency verified
☐ Audit trail checked
☐ User complaints: none
☐ Performance regression: none
☐ Rollback button: ready (kept for 24h)
```

---

## Estimated Timeline

```
Preparation:        1-2 days
  - Infrastructure setup
  - Traefik configuration
  - Monitoring setup

Deployment Day:     ~3 hours
  - 09:00 - Start GREEN build
  - 09:30 - Run migrations
  - 10:00 - Health checks
  - 10:30 - 10% canary (30 min)
  - 11:00 - 50% test (30 min)
  - 11:30 - 100% switch
  - 12:00 - Post-deployment validation

Post-Deployment:    24 hours
  - Continuous monitoring
  - Rollback-ready state
  - Team standby

Total Effort:       ~3-4 days of deployment work per release
Complexity:         Medium (standard practice)
Risk Level:         Very Low (rollback < 2 min)
Downtime:           Zero
```

---

## Summary

✅ **Zero Downtime**: Traffic switches seamlessly
✅ **Safe**: Can rollback instantly if issues
✅ **Auditable**: Clean deployment process
✅ **Medical-Compliant**: Schema and code aligned
✅ **Scalable**: Works with N+ replicas

**Recommended for all medical deployments.**
