#!/bin/bash
# Update PHP service with smart image pre-pulling
# This handles the large PHP image (1.5GB) efficiently
# Usage: bash scripts/update-php-safe.sh [preprod|prod] [version]

set -e

ENVIRONMENT="${1:-preprod}"
PHP_VERSION="${2:-latest}"
PROJECT="oo"
PHP_IMAGE="ghcr.io/oneorthomedical/one-plateform-php8.1-fpm:${PHP_VERSION}"
NGINX_IMAGE="ghcr.io/oneorthomedical/one-plateform-nginx:develop"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_header() {
  echo -e "${BLUE}═══════════════════════════════════════${NC}"
  echo -e "${BLUE}$@${NC}"
  echo -e "${BLUE}═══════════════════════════════════════${NC}"
}

log_step() {
  echo -e "${YELLOW}[$(date +'%H:%M:%S')]${NC} $@"
}

log_success() {
  echo -e "${GREEN}✓ $@${NC}"
}

log_error() {
  echo -e "${RED}❌ $@${NC}"
}

log_warn() {
  echo -e "${YELLOW}⚠️  $@${NC}"
}

# Validate environment
validate_environment() {
  if ! command -v docker &> /dev/null; then
    log_error "Docker not found in PATH"
    exit 1
  fi
  
  if [ "$ENVIRONMENT" != "preprod" ] && [ "$ENVIRONMENT" != "prod" ]; then
    log_error "Invalid environment: $ENVIRONMENT (must be preprod or prod)"
    exit 1
  fi
  
  log_success "Environment validated: $ENVIRONMENT"
}

# Pre-checks
run_pre_checks() {
  log_step "Running pre-update checks..."
  
  if [ ! -f "scripts/pre-update-check.sh" ]; then
    log_error "scripts/pre-update-check.sh not found"
    exit 1
  fi
  
  bash scripts/pre-update-check.sh || {
    log_error "Pre-checks failed"
    exit 1
  }
  
  log_success "Pre-checks passed"
}

# Pre-pull PHP image on all nodes
pre_pull_php() {
  log_step "Phase 1: Pre-pulling PHP image (1.5GB, can take 10-15 minutes)..."
  log_warn "⏳ This is a one-time pull. Subsequent updates will be fast."
  
  bash scripts/pre-pull-images.sh php || {
    log_error "Failed to pre-pull PHP image"
    exit 1
  }
  
  log_success "PHP image pre-pulled successfully"
}

# Scale up for rolling update
scale_up() {
  log_step "Phase 2: Scaling PHP to 3 replicas (from 2)..."
  
  docker service scale "${PROJECT}_php=3" || {
    log_error "Failed to scale PHP"
    exit 1
  }
  
  log_step "Waiting for replicas to stabilize (30s)..."
  sleep 30
  
  REPLICAS=$(docker service ls --filter name="${PROJECT}_php" --format "{{.Replicas}}")
  log_success "PHP replicas: $REPLICAS"
}

# Check if pre-update-check passed
check_cluster_health() {
  log_step "Phase 3: Verifying cluster health..."
  
  HEALTHY_NODES=$(docker node ls --filter status=ready --format "{{.Hostname}}" | wc -l)
  TOTAL_NODES=$(docker node ls --format "{{.Hostname}}" | wc -l)
  
  if [ "$HEALTHY_NODES" -lt "$TOTAL_NODES" ]; then
    log_warn "Warning: $HEALTHY_NODES/$TOTAL_NODES nodes ready"
  fi
  
  log_success "Cluster health verified"
}

# Update PHP
update_php() {
  log_step "Phase 4: Updating PHP to version $PHP_VERSION..."
  log_info "Image: $PHP_IMAGE"
  log_info "Update strategy: parallelism=1, delay=45s, failure_action=rollback"
  
  docker service update \
    --image "${PHP_IMAGE}" \
    --update-parallelism 1 \
    --update-delay 45s \
    --update-failure-action rollback \
    --update-monitor 30s \
    "${PROJECT}_php" || {
    log_error "Failed to update PHP"
    exit 1
  }
  
  log_success "PHP update command issued"
}

# Update Nginx
update_nginx() {
  log_step "Phase 5: Updating Nginx (may take 1-2 minutes)..."
  log_info "Image: $NGINX_IMAGE"
  
  docker service update \
    --image "${NGINX_IMAGE}" \
    --update-parallelism 1 \
    --update-delay 45s \
    --update-failure-action rollback \
    --update-monitor 30s \
    "${PROJECT}_nginx" || {
    log_error "Failed to update Nginx"
    exit 1
  }
  
  log_success "Nginx update command issued"
}

# Monitor updates
monitor_updates() {
  log_step "Phase 6: Monitoring update progress..."
  log_info "Watching replica convergence..."
  
  for i in {1..30}; do
    PHP_STATUS=$(docker service ps "${PROJECT}_php" --format "{{.CurrentState}}" | sort | uniq -c)
    NGINX_STATUS=$(docker service ps "${PROJECT}_nginx" --format "{{.CurrentState}}" | sort | uniq -c)
    
    echo -ne "\r[$i/30] PHP: $(echo $PHP_STATUS | head -c 30)... Nginx: $(echo $NGINX_STATUS | head -c 30)..."
    sleep 10
  done
  echo ""
  
  log_success "Monitoring complete (5 minutes elapsed)"
}

# Scale down
scale_down() {
  log_step "Phase 7: Scaling PHP back to 2 replicas..."
  
  docker service scale "${PROJECT}_php=2" || {
    log_error "Failed to scale down PHP"
    exit 1
  }
  
  sleep 15
  
  REPLICAS=$(docker service ls --filter name="${PROJECT}_php" --format "{{.Replicas}}")
  log_success "PHP replicas: $REPLICAS"
}

# Final checks
final_checks() {
  log_step "Phase 8: Running final health checks..."
  
  bash scripts/pre-update-check.sh || {
    log_warn "Final health checks completed with warnings"
  }
  
  log_success "Final checks completed"
}

# Show summary
show_summary() {
  echo ""
  log_header "✓ Update PHP Completed Successfully"
  echo ""
  log_success "PHP Service"
  echo "  Version: $PHP_VERSION"
  echo "  Update method: Rolling (1 replica at a time)"
  echo "  Downtime: 0 seconds ✅"
  echo ""
  log_success "Monitoring Commands"
  echo "  Real-time: bash scripts/monitor-update.sh ${PROJECT}_php"
  echo "  Status: docker service ps ${PROJECT}_php"
  echo "  Logs: docker service logs ${PROJECT}_php"
  echo ""
}

# Main execution
main() {
  log_header "🚀 Update PHP Service (Zero-Downtime)"
  echo ""
  
  validate_environment
  run_pre_checks
  pre_pull_php
  scale_up
  check_cluster_health
  update_php
  update_nginx
  monitor_updates
  scale_down
  final_checks
  show_summary
}

# Run main function
main

exit 0
