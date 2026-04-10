#!/bin/bash
# Pre-pull large Docker images on ALL Swarm nodes
# Runs pulls in parallel to save time
# Usage: bash scripts/pre-pull-images.sh [image_type]
# image_type: php|workers|nginx|traefik|mariadb|all (default: all)

set -e

# Configuration
IMAGE_TYPES="${1:-all}"
REGISTRY_USERNAME="${REGISTRY_USERNAME:-}"
REGISTRY_PASSWORD="${REGISTRY_PASSWORD:-}"
REGISTRY="${REGISTRY:-ghcr.io}"

# Define images by size
declare -A IMAGES_LARGE=(
  [php]="ghcr.io/oneorthomedical/one-plateform-php8.1-fpm:latest"
  [workers]="ghcr.io/oneorthomedical/oo-simplification-bundle-test:latest"
)

declare -A IMAGES_SMALL=(
  [nginx]="ghcr.io/oneorthomedical/one-plateform-nginx:develop"
  [traefik]="traefik:v3.6.11"
  [mariadb]="mariadb:11.4.9"
)

# Helper function
log_info() {
  echo "ℹ️  $@"
}

log_success() {
  echo "✓ $@"
}

log_warn() {
  echo "⚠️  $@"
}

log_error() {
  echo "❌ $@" >&2
}

# Get all Docker Swarm nodes
get_swarm_nodes() {
  docker node ls --format "{{.Hostname}}" 2>/dev/null || echo "localhost"
}

# Pull image on a single node
pull_on_node() {
  local node=$1
  local image=$2
  local is_manager=$3
  
  if [ "$node" == "localhost" ]; then
    # Local node
    log_info "[$node] Pulling ${image}..."
    docker pull "${image}" >/dev/null 2>&1 && \
      log_success "[$node] Pulled ${image}" || \
      log_error "[$node] Failed pulling ${image}"
  else
    # Remote node via SSH (Swarm)
    log_info "[$node] Pulling ${image}..."
    docker -H "ssh://docker@${node}" pull "${image}" >/dev/null 2>&1 && \
      log_success "[$node] Pulled ${image}" || \
      log_error "[$node] Failed pulling ${image}"
  fi
}

# Main pre-pull logic
pre_pull_images() {
  local image_type=$1
  
  case $image_type in
    php)
      images=("${IMAGES_LARGE[php]}")
      ;;
    workers)
      images=("${IMAGES_LARGE[workers]}")
      ;;
    nginx)
      images=("${IMAGES_SMALL[nginx]}")
      ;;
    traefik)
      images=("${IMAGES_SMALL[traefik]}")
      ;;
    mariadb)
      images=("${IMAGES_SMALL[mariadb]}")
      ;;
    all)
      images=("${IMAGES_LARGE[@]}" "${IMAGES_SMALL[@]}")
      ;;
    *)
      log_error "Unknown image type: $image_type"
      exit 1
      ;;
  esac
  
  local nodes=$(get_swarm_nodes)
  local pids=()
  
  echo "═══════════════════════════════════════════════"
  echo "🔄 Pre-pulling Docker images"
  echo "═══════════════════════════════════════════════"
  
  for image in "${images[@]}"; do
    echo ""
    log_info "Image: $image"
    
    for node in $nodes; do
      # Check if node is a manager (only managers matter for some services)
      is_manager=$(docker node ls --filter "id=$node" --format "{{.ManagerStatus}}" 2>/dev/null | grep -c "Leader\|Reachable" || echo 0)
      
      # Pull in background (async)
      pull_on_node "$node" "$image" "$is_manager" &
      pids+=($!)
    done
  done
  
  # Wait for all background jobs
  echo ""
  log_info "Waiting for all pulls to complete..."
  for pid in "${pids[@]}"; do
    wait $pid || log_error "A pull job failed (PID: $pid)"
  done
  
  echo ""
  log_success "All images pre-pulled successfully!"
}

# Verify images are present
verify_images() {
  local image_type=$1
  
  echo ""
  echo "═══════════════════════════════════════════════"
  echo "✓ Verifying images on nodes"
  echo "═══════════════════════════════════════════════"
  
  for node in $(get_swarm_nodes); do
    if [ "$node" == "localhost" ]; then
      docker images --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}" | grep -E "oneorthomedical|traefik|mariadb" || true
    else
      docker -H "ssh://docker@${node}" images --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}" 2>/dev/null | grep -E "oneorthomedical|traefik|mariadb" || true
    fi
  done
}

# Main
case "$IMAGE_TYPES" in
  php|workers|nginx|traefik|mariadb|all)
    pre_pull_images "$IMAGE_TYPES"
    verify_images "$IMAGE_TYPES"
    ;;
  --help|-h)
    cat << EOF
Usage: bash scripts/pre-pull-images.sh [image_type]

Image types:
  php       - Pre-pull PHP image (1.5GB, ~15 min)
  workers   - Pre-pull Workers image (762MB, ~10 min)
  nginx     - Pre-pull Nginx image (126MB, ~1 min)
  traefik   - Pre-pull Traefik image (53MB, ~30s)
  mariadb   - Pre-pull MariaDB image (110MB, ~1 min)
  all       - Pre-pull all images (default)

Examples:
  bash scripts/pre-pull-images.sh php        # Pre-pull PHP only
  bash scripts/pre-pull-images.sh all        # Pre-pull everything
  
Notes:
  - Pulls happen in PARALLEL on all nodes
  - Large images (PHP, Workers) take 10-15 minutes
  - Small images (< 200MB) take 1-2 minutes
  - Must run BEFORE docker service update for optimal performance
EOF
    ;;
  *)
    log_error "Invalid image type: $IMAGE_TYPES"
    echo "Use --help for usage information"
    exit 1
    ;;
esac
