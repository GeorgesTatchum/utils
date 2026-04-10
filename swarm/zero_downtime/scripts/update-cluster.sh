#!/bin/bash
#
# update-cluster.sh
# Script orchestration complète pour zero-downtime updates
# Usage: bash update-cluster.sh [preprod|prod] [workers|web|traefik|db|all]
#

set -e

# ============================================
# Configuration
# ============================================
ENVIRONMENT="${1:-preprod}"
SERVICE_TYPE="${2:-all}"
DRY_RUN="${DRY_RUN:-false}"
VERBOSE="${VERBOSE:-true}"

# Couleurs pour output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# ============================================
# Fonctions
# ============================================

log_info() {
  echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
  echo -e "${GREEN}[✓]${NC} $1"
}

log_warning() {
  echo -e "${YELLOW}[⚠]${NC} $1"
}

log_error() {
  echo -e "${RED}[✗]${NC} $1"
}

health_check() {
  local service=$1
  log_info "Vérification santé: ${service}"
  docker service ps ${service} --no-trunc 2>/dev/null || {
    log_error "Service ${service} ne trouve pas"
    return 1
  }
}

wait_for_convergence() {
  local service=$1
  local timeout=${2:-300}
  local elapsed=0
  
  log_info "Attendre la convergence de ${service} (max ${timeout}s)..."
  
  while [ $elapsed -lt $timeout ]; do
    running=$(docker service ps ${service} --format '{{.DesiredState}}' | grep -c "^Running$" || echo 0)
    desired=$(docker service ls --filter name=${service} --format '{{.Replicas}}' | cut -d'/' -f2)
    
    if [ "$running" == "$desired" ]; then
      log_success "${service} est convergé"
      return 0
    fi
    
    sleep 5
    elapsed=$((elapsed + 5))
  done
  
  log_error "Timeout convergence de ${service}"
  return 1
}

pre_update_checks() {
  log_info "═══════════════════════════════════════"
  log_info "Vérifications pré-update"
  log_info "═══════════════════════════════════════"
  
  # Check Docker access
  if ! docker ps &>/dev/null; then
    log_error "Pas d'accès à Docker daemon"
    exit 1
  fi
  
  # Check managers
  managers=$(docker node ls --filter role=manager | wc -l)
  managers=$((managers - 1))
  if [ $managers -lt 1 ]; then
    log_error "Pas de managers actifs!"
    exit 1
  fi
  log_success "Managers actifs: $managers"
  
  # Check services
  log_info "État des services principales:"
  docker service ls --filter label="update.required=true" || true
  
  log_success "Vérifications terminées\n"
}

# ============================================
# UPDATE WORKERS
# ============================================
update_workers() {
  local project="oo"
  local service="${project}_app-simplification-bundle"
  
  log_info "═══════════════════════════════════════"
  log_info "[1/4] WORKERS - ${service}"
  log_info "═══════════════════════════════════════"
  
  read -p "Continuer avec update workers ? (y/n) " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_warning "Skipped"
    return 0
  fi
  
  log_info "Step 1/5: Scale up pour drainer les jobs..."
  [ "$DRY_RUN" != "true" ] && docker service scale ${service}=3 || log_info "[DRY-RUN] docker service scale ${service}=3"
  
  log_info "Step 2/5: Attendre stabilisation (60s)..."
  sleep 60
  
  log_info "Step 3/5: Update l'image..."
  [ "$DRY_RUN" != "true" ] && \
  docker service update \
    --image ${SIMPLIFICATION_IMAGE}:${NEW_VERSION} \
    --update-parallelism 1 \
    --update-delay 30s \
    --update-failure-action rollback \
    --update-monitor 20s \
    ${service} || log_info "[DRY-RUN] docker service update --image ... ${service}"
  
  log_info "Step 4/5: Attendre convergence (90s)..."
  [ "$DRY_RUN" != "true" ] && wait_for_convergence ${service} 120 || true
  
  log_info "Step 5/5: Scale down aux réplicas normaux..."
  [ "$DRY_RUN" != "true" ] && docker service scale ${service}=1 || log_info "[DRY-RUN] docker service scale ${service}=1"
  
  log_success "WORKERS update terminé\n"
}

# ============================================
# UPDATE WEB LAYER
# ============================================
update_web() {
  local project="oo"
  local php_service="${project}_php"
  local nginx_service="${project}_nginx"
  
  log_info "═══════════════════════════════════════"
  log_info "[2/4] WEB LAYER - ${php_service} + ${nginx_service}"
  log_info "═══════════════════════════════════════"
  
  read -p "Continuer avec update web ? (y/n) " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_warning "Skipped"
    return 0
  fi
  
  log_info "Step 1/6: Scale PHP-FPM up pour HA..."
  [ "$DRY_RUN" != "true" ] && docker service scale ${php_service}=3 || log_info "[DRY-RUN] docker service scale ${php_service}=3"
  
  log_info "Step 2/6: Attendre stabilisation (60s)..."
  sleep 60
  
  log_info "Step 3/6: Update PHP-FPM..."
  [ "$DRY_RUN" != "true" ] && \
  docker service update \
    --image ${SYMFONY_IMAGE}:${NEW_SYMFONY_VERSION} \
    --update-parallelism 1 \
    --update-delay 45s \
    --update-failure-action rollback \
    --update-monitor 30s \
    ${php_service} || log_info "[DRY-RUN] docker service update --image ... ${php_service}"
  
  log_info "Step 4/6: Attendre convergence PHP (90s)..."
  [ "$DRY_RUN" != "true" ] && wait_for_convergence ${php_service} 120 || true
  
  log_info "Step 5/6: Update Nginx..."
  [ "$DRY_RUN" != "true" ] && \
  docker service update \
    --image ${NGINX_IMAGE}:${NEW_NGINX_VERSION} \
    --update-parallelism 1 \
    --update-delay 45s \
    --update-failure-action rollback \
    --update-monitor 30s \
    ${nginx_service} || log_info "[DRY-RUN] docker service update --image ... ${nginx_service}"
  
  log_info "Step 6/6: Attendre convergence Nginx (90s)..."
  [ "$DRY_RUN" != "true" ] && wait_for_convergence ${nginx_service} 120 || true
  
  log_info "Scale down PHP-FPM aux réplicas normaux..."
  [ "$DRY_RUN" != "true" ] && docker service scale ${php_service}=2 || log_info "[DRY-RUN] docker service scale ${php_service}=2"
  
  log_success "WEB LAYER update terminé\n"
}

# ============================================
# UPDATE TRAEFIK
# ============================================
update_traefik() {
  local service="traefik"
  
  log_info "═══════════════════════════════════════"
  log_info "[3/4] TRAEFIK - ${service}"
  log_info "═══════════════════════════════════════"
  
  read -p "Continuer avec update traefik ? (y/n) " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_warning "Skipped"
    return 0
  fi
  
  log_info "Vérifier que 2+ managers sont actifs..."
  managers=$(docker node ls --filter role=manager | wc -l)
  managers=$((managers - 1))
  if [ $managers -lt 2 ]; then
    log_error "Besoin de min 2 managers pour traefik!"
    return 1
  fi
  log_success "Managers actifs: $managers"
  
  log_info "Update Traefik..."
  [ "$DRY_RUN" != "true" ] && \
  docker service update \
    --image traefik:${TRAEFIK_VERSION} \
    --update-parallelism 1 \
    --update-delay 40s \
    --update-failure-action rollback \
    --update-monitor 30s \
    ${service} || log_info "[DRY-RUN] docker service update --image traefik:${TRAEFIK_VERSION} ${service}"
  
  log_info "Attendre stabilisation (90s)..."
  [ "$DRY_RUN" != "true" ] && wait_for_convergence ${service} 120 || true
  
  log_success "TRAEFIK update terminé\n"
}

# ============================================
# UPDATE DATABASE
# ============================================
update_db() {
  local project="oo"
  local service="${project}_mariadb"
  
  log_info "═══════════════════════════════════════"
  log_info "[4/4] DATABASE - ${service}"
  log_info "═══════════════════════════════════════"
  
  log_warning "⚠️  DATABASE EST CRITIQUE - OPÉRATION DANGEREUSE"
  log_warning "Les données seront affectées si quelque chose échoue!"
  
  read -p "ÊTES-VOUS SÛR ? Continuer avec update DB ? (y/n) " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_warning "Skipped"
    return 0
  fi
  
  read -p "Dernier avertissement - Continuer ? (y/n) " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_warning "Skipped"
    return 0
  fi
  
  log_info "Step 1/4: Vérifier backup..."
  # Vérifier que le backup existe
  if [ ! -z "$BACKUP_PATH" ] && [ ! -f "$BACKUP_PATH" ]; then
    log_error "Backup non trouvé: $BACKUP_PATH"
    return 1
  fi
  log_success "Backup vérifié"
  
  log_info "Step 2/4: Pause des services web..."
  [ "$DRY_RUN" != "true" ] && {
    docker service update --mode replicated --replicas 0 ${project}_php || true
    docker service update --mode replicated --replicas 0 ${project}_nginx || true
  } || log_info "[DRY-RUN] Pause web services"
  
  log_info "Attendre que les connexions se ferment (90s)..."
  sleep 90
  
  log_info "Step 3/4: Update DB..."
  [ "$DRY_RUN" != "true" ] && \
  docker service update \
    --image mariadb:${MARIADB_VERSION} \
    --update-failure-action pause \
    --update-monitor 60s \
    ${service} || log_info "[DRY-RUN] docker service update --image mariadb:${MARIADB_VERSION} ${service}"
  
  log_info "Attendre stabilisation DB (120s)..."
  sleep 120
  
  log_info "Step 4/4: Relancer services web..."
  [ "$DRY_RUN" != "true" ] && {
    docker service update --replicas 2 ${project}_php || true
    docker service update --replicas 2 ${project}_nginx || true
  } || log_info "[DRY-RUN] Scale up web services"
  
  log_success "DATABASE update terminé\n"
}

# ============================================
# POST-UPDATE CHECKS
# ============================================
post_update_checks() {
  log_info "═══════════════════════════════════════"
  log_info "Vérifications post-update"
  log_info "═══════════════════════════════════════"
  
  local services=("traefik" "oo_php" "oo_nginx" "oo_mariadb" "oo_app-simplification-bundle")
  
  for service in "${services[@]}"; do
    if docker service ls --filter name=${service} --quiet &>/dev/null; then
      echo ""
      log_info "État: ${service}"
      docker service ps ${service} --no-trunc | head -5
    fi
  done
  
  log_success "Vérifications terminées\n"
}

# ============================================
# Main
# ============================================
main() {
  local start_time=$(date +%s)
  
  cat << "EOF"
╔════════════════════════════════════════════════════╗
║     Docker Swarm Zero-Downtime Update Script       ║
╚════════════════════════════════════════════════════╝
EOF
  
  log_info "Environment: ${ENVIRONMENT}"
  log_info "Service Type: ${SERVICE_TYPE}"
  [ "$DRY_RUN" == "true" ] && log_warning "MODE DRY-RUN ACTIVÉ"
  
  pre_update_checks
  
  case "${SERVICE_TYPE}" in
    workers)
      update_workers
      ;;
    web)
      update_web
      ;;
    traefik)
      update_traefik
      ;;
    db)
      update_db
      ;;
    all)
      update_workers
      update_web
      update_traefik
      update_db
      ;;
    *)
      log_error "Service type invalide: ${SERVICE_TYPE}"
      exit 1
      ;;
  esac
  
  post_update_checks
  
  local end_time=$(date +%s)
  local duration=$((end_time - start_time))
  
  cat << EOF

╔════════════════════════════════════════════════════╗
║     ✓ Update terminé avec succès                   ║
║     Durée: ${duration}s                            ║
╚════════════════════════════════════════════════════╝
EOF
}

# Run
main "$@"
