#!/bin/bash
#
# monitor-update.sh
# Script pour monitorer un update en cours
# Usage: bash monitor-update.sh <service_name> [interval_seconds]
#

SERVICE_NAME="${1:-traefik}"
INTERVAL="${2:-5}"

GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

if [ -z "${SERVICE_NAME}" ]; then
  echo "Usage: $0 <service_name> [interval_seconds]"
  echo "Example: $0 traefik 5"
  exit 1
fi

# Vérifier que le service existe
if ! docker service ls --filter name=${SERVICE_NAME} --quiet &>/dev/null; then
  echo "Service not found: ${SERVICE_NAME}"
  exit 1
fi

echo -e "${BLUE}Monitoring service: ${SERVICE_NAME}${NC}"
echo "Refreshing every ${INTERVAL}s (Ctrl+C to stop)"
echo ""

counter=0
while true; do
  clear
  
  # Header
  echo "╔════════════════════════════════════════════════════════╗"
  printf "║ Service: %-45s │\n" "${SERVICE_NAME}"
  printf "║ Time: %-48s │\n" "$(date '+%Y-%m-%d %H:%M:%S')"
  printf "║ Refresh: %-47s │\n" "${counter}x (every ${INTERVAL}s)"
  echo "╚════════════════════════════════════════════════════════╝"
  echo ""
  
  # Service info
  echo "📊 Service Info:"
  docker service ls --filter name=${SERVICE_NAME} --format "table {{.Name}}\t{{.Mode}}\t{{.Replicas}}\t{{.Image}}"
  echo ""
  
  # Task status
  echo "📦 Task Status:"
  running=$(docker service ps ${SERVICE_NAME} --format '{{.DesiredState}}' | grep -c "^Running$" || echo 0)
  desired=$(docker service ls --filter name=${SERVICE_NAME} --format '{{.Replicas}}' | cut -d'/' -f2 || echo "N/A")
  desired_count=$(echo "$desired" | tr -cd '0-9' || echo "0")
  
  if [ "$running" == "$desired_count" ] && [ "$desired_count" != "0" ]; then
    echo -e "${GREEN}✓ Converged: $running/$desired_count replicas running${NC}"
  else
    echo -e "${RED}⚠ Updating: $running/$desired_count replicas running${NC}"
  fi
  
  echo ""
  docker service ps ${SERVICE_NAME} --no-trunc --format "table {{.Node}}\t{{.Name}}\t{{.DesiredState}}\t{{.CurrentState}}" | head -10
  
  # Recent logs
  echo ""
  echo "📋 Recent Logs (last 3):"
  docker service logs ${SERVICE_NAME} --tail 3 --timestamps=true 2>/dev/null || echo "  [No logs available]"
  
  echo ""
  echo "Press Ctrl+C to exit (next refresh in ${INTERVAL}s...)"
  
  counter=$((counter + 1))
  sleep ${INTERVAL}
done
