#!/bin/bash
#
# pre-update-check.sh
# Vérifications pré-update pour validater l'état du cluster
#

BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_section() {
  echo ""
  echo -e "${BLUE}═══════════════════════════════════════${NC}"
  echo -e "${BLUE}$1${NC}"
  echo -e "${BLUE}═══════════════════════════════════════${NC}"
}

log_ok() {
  echo -e "${GREEN}✓${NC} $1"
}

log_warning() {
  echo -e "${YELLOW}⚠${NC} $1"
}

log_error() {
  echo -e "${RED}✗${NC} $1"
}

log_section "Docker Swarm Pre-Update Checks"

# 1. Docker connection
log_section "1. Docker Connection"
if docker info &>/dev/null; then
  log_ok "Docker daemon accessible"
else
  log_error "Cannot connect to Docker daemon"
  exit 1
fi

# 2. Swarm status
log_section "2. Swarm Status"
is_manager=$(docker info --format '{{json .Swarm.ControlAvailable}}')
if [ "$is_manager" == "true" ]; then
  log_ok "Node is swarm manager"
else
  log_warning "Node is swarm worker"
fi

# 3. Nodes
log_section "3. Cluster Nodes"
node_count=$(docker node ls --format '{{.Status}}' | grep -c "Ready" || echo 0)
manager_count=$(docker node ls --filter role=manager --format '{{.Status}}' | grep -c "Ready" || echo 0)

echo "Total nodes: $node_count"
echo "Manager nodes: $manager_count"
echo ""
docker node ls

if [ $manager_count -lt 1 ]; then
  log_error "No manager nodes available!"
  exit 1
fi

if [ $manager_count -lt 2 ]; then
  log_warning "Only 1 manager node - Traefik cannot have HA"
fi

log_ok "Cluster has $node_count nodes ($manager_count managers)"

# 4. Services overview
log_section "4. Services Overview"
docker service ls --format "table {{.Name}}\t{{.Mode}}\t{{.Replicas}}\t{{.Image}}"

service_count=$(docker service ls --quiet | wc -l)
log_ok "Total services: $service_count"

# 5. Service health
log_section "5. Service Health Status"
services=(traefik oo_php oo_nginx oo_mariadb oo_app-simplification-bundle)

for service in "${services[@]}"; do
  if docker service ls --filter name=${service} --quiet &>/dev/null; then
    running=$(docker service ps ${service} --format '{{.DesiredState}}' | grep -c "^Running$" || echo 0)
    desired=$(docker service ls --filter name=${service} --format '{{.Replicas}}' | cut -d'/' -f2 || echo "0")
    desired_count=$(echo "$desired" | tr -cd '0-9' || echo "0")
    
    if [ "$running" == "$desired_count" ] && [ "$desired_count" != "0" ]; then
      log_ok "$service: $running/$desired_count RUNNING"
    else
      log_warning "$service: $running/$desired_count (UPDATING or WAITING)"
    fi
  else
    log_warning "$service: NOT DEPLOYED"
  fi
done

# 6. Disk space
log_section "6. Disk Space"
docker system df

root_used=$(df / --output=pcent | tail -1 | tr -d '% ')
if [ $root_used -gt 90 ]; then
  log_error "Root filesystem $root_used% full!"
elif [ $root_used -gt 80 ]; then
  log_warning "Root filesystem $root_used% full (consider cleanup)"
else
  log_ok "Disk space OK: $root_used% used"
fi

# 7. Recent errors in logs
log_section "7. Recent Service Logs"
for service in "${services[@]}"; do
  if docker service ls --filter name=${service} --quiet &>/dev/null; then
    error_count=$(docker service logs ${service} --tail 100 2>&1 | grep -i "error\|critical\|fatal" | wc -l)
    if [ $error_count -gt 0 ]; then
      log_warning "$service: $error_count errors in recent logs"
      docker service logs ${service} --tail 3 2>/dev/null | grep -i "error\|critical\|fatal" || true
    else
      log_ok "$service: No errors in recent logs"
    fi
  fi
done

# 8. Node resources
log_section "8. Node Resources"
echo "CPU and Memory per node:"
docker node ls --format '{{.Hostname}}\t{{.Status}}\t{{.ManagerStatus}}'
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}" | head -10

# 9. Network status
log_section "9. Network Status"
networks=$(docker network ls --format '{{.Name}}' | grep -E "^(internal|oo_|core_)" | wc -l)
log_ok "Custom networks: $networks"
docker network ls --format "table {{.Name}}\t{{.Driver}}\t{{.Scope}}" | grep -E "^(internal|oo_|core_)"

# 10. Summary
log_section "10. Pre-Update Summary"

all_ok=true

if [ $manager_count -lt 1 ]; then
  log_error "No managers!"
  all_ok=false
fi

if [ $node_count -lt 1 ]; then
  log_error "No nodes!"
  all_ok=false
fi

if [ $root_used -gt 90 ]; then
  log_error "Disk space critical!"
  all_ok=false
fi

if [ "$all_ok" = true ]; then
  echo ""
  echo -e "${GREEN}╔═══════════════════════════════════════╗${NC}"
  echo -e "${GREEN}║  ✓ Cluster is ready for updates       ║${NC}"
  echo -e "${GREEN}╚═══════════════════════════════════════╝${NC}"
  exit 0
else
  echo ""
  echo -e "${RED}╔═══════════════════════════════════════╗${NC}"
  echo -e "${RED}║  ✗ Fix issues before updating         ║${NC}"
  echo -e "${RED}╚═══════════════════════════════════════╝${NC}"
  exit 1
fi
