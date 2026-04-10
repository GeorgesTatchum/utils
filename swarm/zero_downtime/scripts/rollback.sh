#!/bin/bash
#
# rollback.sh
# Script pour rollbacker un service en cas de problème
# Usage: bash rollback.sh <service_name>
#

SERVICE_NAME="${1}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

if [ -z "${SERVICE_NAME}" ]; then
  echo "Usage: $0 <service_name>"
  echo "Example: $0 oo_php"
  exit 1
fi

# Vérifier que le service existe
if ! docker service ls --filter name=${SERVICE_NAME} --quiet &>/dev/null; then
  echo -e "${RED}✗ Service not found: ${SERVICE_NAME}${NC}"
  exit 1
fi

echo -e "${YELLOW}⚠  ROLLBACK SERVICE: ${SERVICE_NAME}${NC}"
echo ""

# Get current state
echo -e "${BLUE}État avant rollback:${NC}"
docker service ls --filter name=${SERVICE_NAME} --format "table {{.Name}}\t{{.Mode}}\t{{.Replicas}}\t{{.Image}}"
echo ""

# Confirmation
read -p "Confirm rollback of ${SERVICE_NAME} ? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "Rolled back"
  exit 0
fi

# Perform rollback
echo -e "${YELLOW}Exécution du rollback...${NC}"
if docker service update --rollback ${SERVICE_NAME}; then
  echo -e "${GREEN}✓ Rollback command sent${NC}"
else
  echo -e "${RED}✗ Rollback command failed${NC}"
  exit 1
fi

# Wait for convergence
echo ""
echo "Attendre la convergence (60s)..."
sleep 5

# Monitor rollback
max_attempts=60
attempt=0
while [ $attempt -lt $max_attempts ]; do
  running=$(docker service ps ${SERVICE_NAME} --format '{{.DesiredState}}' | grep -c "^Running$" || echo 0)
  desired=$(docker service ls --filter name=${SERVICE_NAME} --format '{{.Replicas}}' | cut -d'/' -f2 || echo "0")
  desired_count=$(echo "$desired" | tr -cd '0-9' || echo "0")
  
  if [ "$running" == "$desired_count" ] && [ "$desired_count" != "0" ]; then
    echo -e "${GREEN}✓ Rollback complété - Service convergé${NC}"
    break
  fi
  
  printf "  Progress: $running/$desired_count replicas running...\r"
  sleep 1
  attempt=$((attempt + 1))
done

echo ""
echo -e "${BLUE}État après rollback:${NC}"
docker service ps ${SERVICE_NAME} --no-trunc

echo ""
echo -e "${GREEN}✓ Rollback terminé${NC}"
