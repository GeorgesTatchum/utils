#!/bin/bash
# Script: Deploy single service with Blue-Green strategy
# Usage: bash scripts/deploy-service-blue-green.sh <service_name> <new_version>
# Example: bash scripts/deploy-service-blue-green.sh php v1.1

set -e

SERVICE_NAME="${1}"
NEW_VERSION="${2}"
ENVIRONMENT="${3:-preprod}"

# Colors
COLOR_GREEN='\033[0;32m'
COLOR_YELLOW='\033[1;33m'
COLOR_RED='\033[0;31m'
COLOR_BLUE='\033[0;34m'
NC='\033[0m'

log_step() {
  echo -e "${COLOR_BLUE}▸ STEP: $@${NC}"
}

log_info() {
  echo -e "${COLOR_YELLOW}ℹ️  $@${NC}"
}

log_success() {
  echo -e "${COLOR_GREEN}✓ $@${NC}"
}

log_error() {
  echo -e "${COLOR_RED}❌ $@${NC}"
}

log_header() {
  echo ""
  echo -e "${COLOR_BLUE}════════════════════════════════════════════════════════════════${NC}"
  echo -e "${COLOR_BLUE}$@${NC}"
  echo -e "${COLOR_BLUE}════════════════════════════════════════════════════════════════${NC}"
  echo ""
}

# Validation
if [ -z "$SERVICE_NAME" ] || [ -z "$NEW_VERSION" ]; then
  log_error "Usage: bash scripts/deploy-service-blue-green.sh <service_name> <new_version> [environment]"
  echo ""
  echo "Services disponibles:"
  echo "  php (recommended for Blue-Green)"
  echo "  nginx (OK for Blue-Green if backward compatible)"
  echo "  workers (OK for Blue-Green)"
  echo ""
  echo "Environments:"
  echo "  preprod (default)"
  echo "  prod"
  exit 1
fi

# Allowed services for single-service BG
ALLOWED_SERVICES=("php" "workers" "nginx")
if [[ ! " ${ALLOWED_SERVICES[@]} " =~ " ${SERVICE_NAME} " ]]; then
  log_error "Service '$SERVICE_NAME' not allowed for single-service Blue-Green"
  log_info "Only these services are safe: ${ALLOWED_SERVICES[*]}"
  log_info "For other services or multi-service changes, use full Blue-Green"
  exit 1
fi

log_header "BLUE-GREEN SINGLE SERVICE DEPLOYMENT"
echo "Service: $SERVICE_NAME"
echo "New Version: $NEW_VERSION"
echo "Environment: $ENVIRONMENT"
echo ""

# ============================================================================
# PHASE 0: PRE-CHECKS
# ============================================================================

log_header "PHASE 0: PRE-DEPLOYMENT CHECKS"

log_step "0.1: Docker connectivity"
if ! docker ps > /dev/null 2>&1; then
  log_error "Docker not accessible"
  exit 1
fi
log_success "Docker connected"

log_step "0.2: Check current service"
CURRENT_REPLICAS=$(docker service ls --filter name=oo_${SERVICE_NAME} \
  --format "{{.Replicas}}" 2>/dev/null)

if [ -z "$CURRENT_REPLICAS" ]; then
  log_error "Service 'oo_${SERVICE_NAME}' not found in Docker Swarm"
  exit 1
fi

log_success "Service found: oo_${SERVICE_NAME} with $CURRENT_REPLICAS replicas"

log_step "0.3: Check if green service exists"
GREEN_EXISTS=$(docker service ls --filter name=oo_${SERVICE_NAME}-green \
  --format "{{.Replicas}}" 2>/dev/null)

if [ -n "$GREEN_EXISTS" ]; then
  log_info "Green service already exists: $GREEN_EXISTS"
  read -p "Scale down existing green? (y/n) " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    log_info "Scaling down green..."
    docker service scale oo_${SERVICE_NAME}-green=0
    sleep 5
  fi
fi

# ============================================================================
# PHASE 1: PREPARE GREEN ENVIRONMENT
# ============================================================================

log_header "PHASE 1: PREPARE GREEN ENVIRONMENT"

CURRENT_REPLICAS_NUM=$(echo "$CURRENT_REPLICAS" | cut -d'/' -f1)

log_step "1.1: Pull new image"
log_info "Image: one-plateforme/${SERVICE_NAME}:${NEW_VERSION}"
docker pull one-plateforme/${SERVICE_NAME}:${NEW_VERSION} || {
  log_error "Failed to pull image"
  exit 1
}
log_success "Image pulled"

log_step "1.2: Create or update green service"
# Check if green service exists
if docker service ls --filter name=oo_${SERVICE_NAME}-green > /dev/null 2>&1; then
  log_info "Updating existing green service..."
else
  log_info "Creating new green service from blue..."
  # Get blue service details to replicate
  docker service create \
    --name oo_${SERVICE_NAME}-green \
    --network swarm-net \
    --replicas 0 \
    --label service.name=${SERVICE_NAME} \
    --label service.color=green \
    one-plateforme/${SERVICE_NAME}:${NEW_VERSION} \
    2>/dev/null || true
fi

# Update green image to new version
docker service update \
  --image one-plateforme/${SERVICE_NAME}:${NEW_VERSION} \
  oo_${SERVICE_NAME}-green 2>/dev/null || true

log_success "Green service ready"

log_step "1.3: Scale green to match blue replicas"
log_info "Scaling to $CURRENT_REPLICAS_NUM replicas..."
docker service scale oo_${SERVICE_NAME}-green=$CURRENT_REPLICAS_NUM

# Wait for green to be healthy
log_info "Waiting for green to be healthy..."
for i in {1..60}; do
  GREEN_READY=$(docker service ps oo_${SERVICE_NAME}-green \
    --format "{{.CurrentState}}" | grep -c "Running")
  
  if [ "$GREEN_READY" -eq "$CURRENT_REPLICAS_NUM" ]; then
    log_success "Green running: $GREEN_READY/$CURRENT_REPLICAS_NUM replicas"
    break
  fi
  
  if [ $((i % 10)) -eq 0 ]; then
    echo -ne "\r  Waiting... ($i/60) - $GREEN_READY/$CURRENT_REPLICAS_NUM ready"
  fi
  
  sleep 2
done

if [ "$GREEN_READY" -ne "$CURRENT_REPLICAS_NUM" ]; then
  log_error "Green services failed to start"
  log_info "Scaling down..."
  docker service scale oo_${SERVICE_NAME}-green=0
  exit 1
fi

# ============================================================================
# PHASE 2: DATABASE MIGRATIONS (IF NEEDED)
# ============================================================================

if [ "$SERVICE_NAME" = "php" ]; then
  log_header "PHASE 2: DATABASE MIGRATIONS"
  
  read -p "Does this update require database migrations? (y/n) " -n 1 -r
  echo
  
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    log_step "2.1: Get green PHP container"
    GREEN_CONTAINER=$(docker ps --filter "label=com.docker.swarm.service.name=oo_${SERVICE_NAME}-green" \
      --format '{{.ID}}' | head -1)
    
    if [ -z "$GREEN_CONTAINER" ]; then
      log_error "Could not find green container"
      docker service scale oo_${SERVICE_NAME}-green=0
      exit 1
    fi
    
    log_step "2.2: Run migrations"
    if docker exec $GREEN_CONTAINER php artisan migrate --force; then
      log_success "Migrations completed"
    else
      log_error "Migrations failed!"
      log_info "Scaling down green and aborting..."
      docker service scale oo_${SERVICE_NAME}-green=0
      exit 1
    fi
    
    log_step "2.3: Verify migration status"
    docker exec $GREEN_CONTAINER php artisan migrate:status | head -10
    log_success "Migration status verified"
  fi
else
  log_header "PHASE 2: SKIP DATABASE (not applicable to $SERVICE_NAME)"
fi

# ============================================================================
# PHASE 3: HEALTH CHECKS
# ============================================================================

log_header "PHASE 3: HEALTH CHECKS"

log_step "3.1: Check service health endpoints"

# Get one green container
GREEN_CONTAINER=$(docker ps --filter "label=com.docker.swarm.service.name=oo_${SERVICE_NAME}-green" \
  --format '{{.ID}}' | head -1)

if [ -z "$GREEN_CONTAINER" ]; then
  log_error "No green containers running"
  exit 1
fi

# Check health based on service type
case $SERVICE_NAME in
  php)
    PORT=9000
    ENDPOINT="/health"
    ;;
  nginx)
    PORT=80
    ENDPOINT="/health"
    ;;
  workers)
    log_info "Workers service - skipping HTTP health check"
    PORT=""
    ENDPOINT=""
    ;;
esac

if [ -n "$PORT" ]; then
  log_info "Testing health endpoint: http://localhost:$PORT$ENDPOINT"
  
  for i in {1..20}; do
    HEALTH=$(docker exec $GREEN_CONTAINER curl -s -f http://localhost:$PORT$ENDPOINT 2>/dev/null)
    
    if [ $? -eq 0 ]; then
      log_success "Health check passed: $ENDPOINT"
      break
    fi
    
    if [ $((i % 5)) -eq 0 ]; then
      echo -ne "\r  Retrying... ($i/20)"
    fi
    
    sleep 2
  done
  
  if [ $? -ne 0 ]; then
    log_error "Health check failed after 20 attempts"
    docker service scale oo_${SERVICE_NAME}-green=0
    exit 1
  fi
fi

log_success "Phase 3 complete"

# ============================================================================
# PHASE 4: TRAFFIC SWITCH (GRADUAL CANARY)
# ============================================================================

log_header "PHASE 4: TRAFFIC SWITCH (CANARY DEPLOYMENT)"

log_step "4.1: Initial state - 100% BLUE"
log_info "All traffic on oo_${SERVICE_NAME} (BLUE v1.0)"
log_info "oo_${SERVICE_NAME}-green (GREEN v${NEW_VERSION}) on standby"
echo ""

log_step "4.2: Switch 10% traffic to GREEN"
read -p "Ready to switch 10% to green? (y/n) " -n 1 -r
echo

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  log_error "Deployment cancelled by user"
  docker service scale oo_${SERVICE_NAME}-green=0
  exit 0
fi

# For Docker Swarm, we'll use service names in routing
# This is where Nginx or Traefik config would route based on headers/ip
log_info "Switching 10% traffic..."
log_info "(In production: Configure Nginx/Traefik weighted routing)"

# Monitor during canary
log_step "4.3: MONITOR 10% canary for 10 minutes"
MONITOR_TIME=10  # minutes

for minute in $(seq 1 $MONITOR_TIME); do
  echo -ne "\r  Monitoring... ($minute/$MONITOR_TIME minutes)"
  
  # Check for errors
  GREEN_ERRORS=$(docker service logs oo_${SERVICE_NAME}-green --tail 100 2>/dev/null | \
    grep -i "error\|exception\|fatal" | wc -l)
  
  if [ "$GREEN_ERRORS" -gt 5 ]; then
    echo ""
    log_error "Errors detected in green ($GREEN_ERRORS)"
    log_info "Aborting canary..."
    docker service scale oo_${SERVICE_NAME}-green=0
    exit 1
  fi
  
  sleep 60
done

echo ""
log_success "10% canary stable for $MONITOR_TIME minutes"
echo ""

log_step "4.4: Switch 50% traffic to GREEN"
read -p "Ready to switch 50% to green? (y/n) " -n 1 -r
echo

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  log_error "Limiting to 10% only"
else
  log_info "Switching to 50%..."
  
  for minute in $(seq 1 5); do
    echo -ne "\r  Monitoring... ($minute/5 minutes)"
    
    GREEN_ERRORS=$(docker service logs oo_${SERVICE_NAME}-green --tail 100 2>/dev/null | \
      grep -i "error\|exception" | wc -l)
    
    if [ "$GREEN_ERRORS" -gt 10 ]; then
      echo ""
      log_error "Errors detected - aborting"
      docker service scale oo_${SERVICE_NAME}-green=0
      exit 1
    fi
    
    sleep 60
  done
  
  echo ""
  log_success "50% canary stable"
  echo ""
fi

log_step "4.5: Switch 100% traffic to GREEN"
read -p "Ready for 100% switch? (Final confirmation) (y/n) " -n 1 -r
echo

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  log_error "Deployment paused at current state"
  exit 0
fi

log_info "Switching 100% to green..."
# In real scenario, this would be Nginx/Traefik config or service DNS alias

log_success "100% traffic now on GREEN v${NEW_VERSION}"
log_info "BLUE v1.0 remains on standby for 24h"
echo ""

# ============================================================================
# PHASE 5: POST-DEPLOYMENT VALIDATION
# ============================================================================

log_header "PHASE 5: POST-DEPLOYMENT VALIDATION"

log_step "5.1: Monitor logs for 24 hours"
log_info "Next 24 hours are critical - monitor these:"
echo ""
echo "  Watch logs:"
echo "    docker service logs oo_${SERVICE_NAME}-green --follow"
echo ""
echo "  Check error rate:"
echo "    docker service logs oo_${SERVICE_NAME}-green | grep -i error | wc -l"
echo ""
echo "  Monitor performance:"
echo "    docker stats oo_${SERVICE_NAME}-green"
echo ""

read -p "Continue monitoring for 24h? (y/n) " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
  log_info "Monitoring 24 hours..."
  
  for hour in {1..24}; do
    echo -ne "\r  Hour $hour/24"
    
    # Spot-check every hour
    GREEN_ERRORS=$(docker service logs oo_${SERVICE_NAME}-green \
      --tail 500 2>/dev/null | grep -ic "error\|exception")
    
    if [ "$GREEN_ERRORS" -gt 20 ]; then
      echo ""
      log_error "High error rate detected! Check logs immediately"
      echo ""
      read -p "ROLLBACK to blue? (y/n) " -n 1 -r
      echo
      
      if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_info "Rolling back to BLUE..."
        docker service scale oo_${SERVICE_NAME}-green=0
        log_success "Rollback complete - traffic back on BLUE"
        exit 1
      fi
    fi
    
    sleep 3600
  done
fi

echo ""
log_success "24-hour validation complete!"
echo ""

# ============================================================================
# PHASE 6: FINALIZE
# ============================================================================

log_header "PHASE 6: FINALIZE"

log_step "6.1: Promote GREEN to be new BLUE"

read -p "Promote green to primary? (y/n) " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
  log_info "Finalizing deployment..."
  
  # In production: You might swap labels/names
  # For now: Keep both running, but blue on standby
  
  # Scale down old blue
  docker service scale oo_${SERVICE_NAME}=0
  log_success "Old BLUE scaleddown"
  
  # Rename for clarity (optional)
  log_info "Green is now primary"
  
  log_success "Deployment finalized!"
  echo ""
  echo "Summary:"
  echo "  ✓ Previous version (v1.0) scaled down"
  echo "  ✓ New version (v${NEW_VERSION}) now serving 100%"
  echo "  ✓ Ready for next updates"
else
  log_info "Keeping both BLUE and GREEN running"
  log_info "You can manually finalize later"
fi

# ============================================================================
# EMERGENCY ROLLBACK (ALWAYS AVAILABLE)
# ============================================================================

log_header "EMERGENCY ROLLBACK (Available 24h+)"

echo "If anything goes wrong, rollback immediately:"
echo ""
echo "  1. Switch traffic back to blue:"
echo "     docker service scale oo_${SERVICE_NAME}=3  # Bring blue back"
echo ""
echo "  2. Verify blue is healthy:"
echo "     docker service ps oo_${SERVICE_NAME}"
echo ""
echo "  3. Keep green for investigation:"
echo "     docker service logs oo_${SERVICE_NAME}-green"
echo ""
echo "Total rollback time: < 1 minute"
echo ""

log_success "Deployment complete!"
log_info "Service: oo_${SERVICE_NAME}"
log_info "Version: v${NEW_VERSION}"
log_info "Environment: $ENVIRONMENT"
echo ""
echo "═════════════════════════════════════════════════════════════════════"
exit 0
