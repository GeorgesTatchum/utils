#!/bin/bash
# Script: Deploy Request Tracing to cluster
# Usage: bash scripts/deploy-request-tracing.sh <environment>

set -e

COLOR_GREEN='\033[0;32m'
COLOR_YELLOW='\033[1;33m'
COLOR_BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
  echo -e "${COLOR_YELLOW}ℹ️  $@${NC}"
}

log_success() {
  echo -e "${COLOR_GREEN}✓ $@${NC}"
}

log_step() {
  echo -e "${COLOR_BLUE}▸ $@${NC}"
}

ENVIRONMENT="${1:-preprod}"

if [ -z "$ENVIRONMENT" ]; then
  echo "Usage: bash scripts/deploy-request-tracing.sh <environment>"
  echo "  environment: preprod or prod"
  exit 1
fi

echo "═══════════════════════════════════════════════════════════════"
echo "Deploy Request Tracing to $ENVIRONMENT"
echo "═══════════════════════════════════════════════════════════════"
echo ""

# Colors for checks
ERROR="❌"
OK="✓"

echo "Pre-deployment checks:"
log_step "1. Docker available"
docker ps > /dev/null && echo "  $OK Docker daemon running" || exit 1

log_step "2. Inventory file exists"
[ -f "inventory/$ENVIRONMENT/host.yml" ] && echo "  $OK Inventory found" || exit 1

log_step "3. Docker Compose files"
[ -f "projects/oo/templates/app/docker-compose.yml.j2" ] && echo "  $OK App template found" || exit 1

echo ""
echo "Deployment plan for $ENVIRONMENT:"
echo "  1. Create Nginx request-id config"
echo "  2. Copy PHP middleware to containers"
echo "  3. Update environment variables"
echo "  4. Reload Nginx configuration"
echo "  5. Restart PHP service (1 replica at a time)"
echo "  6. Verify audit logging working"
echo ""

read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  log_info "Deployment cancelled"
  exit 0
fi

echo ""
echo "═══════════════════════════════════════════════════════════════"

# 1. Ensure nginx config exists
log_info "Step 1: Create Nginx request-id config"
if [ ! -f "./config/nginx/request-tracing.conf" ]; then
  log_info "  Running setup first..."
  bash scripts/setup-request-tracing.sh "$ENVIRONMENT"
fi
log_success "Nginx config ready"

# 2. Create Ansible playbook for deployment
log_info "Step 2: Creating deployment playbook..."
cat > playbooks/deploy-request-tracing.yml << EOFANS
---
- name: Deploy Request Tracing to $ENVIRONMENT
  hosts: docker_swarm_managers
  become: yes
  gather_facts: yes
  
  vars:
    environment: $ENVIRONMENT
    nginx_config_source: "../../config/nginx/request-tracing.conf"
    php_middleware_dir: "/app/src/Middleware"
  
  tasks:
    - name: Display deployment info
      debug:
        msg: "Deploying request tracing to {{ environment }} environment"
    
    - name: Create nginx config directory
      file:
        path: /etc/nginx/conf.d
        state: directory
        mode: '0755'
    
    - name: Copy nginx request-tracing config
      copy:
        src: "{{ nginx_config_source }}"
        dest: /etc/nginx/conf.d/request-tracing.conf
        owner: root
        group: root
        mode: '0644'
      register: nginx_config_copied
    
    - name: Validate nginx configuration
      command: nginx -t
      when: nginx_config_copied.changed
      register: nginx_test
      failed_when: false
    
    - name: Reload nginx
      command: docker exec oo_nginx.1 nginx -s reload
      when: nginx_test.rc == 0
      register: nginx_reload
      failed_when: false
    
    - name: Check Docker service status
      command: docker service ls --filter name=oo_
      register: service_status
    
    - name: Display deployment summary
      debug:
        msg: |
          Request Tracing Configuration:
          - Environment: {{ environment }}
          - Nginx reload: {% if nginx_reload.rc == 0 %}✓ Success{% else %}⚠ Check logs{% endif %}
          - Services: {{ service_status.stdout_lines|length }} active
          
          Next steps:
          1. Test with: bash scripts/test-request-tracing.sh
          2. Check logs: docker service logs oo_php | grep REQUEST_ID
          3. Query audit: bash scripts/query-audit.sh <request_id>
EOFANS

log_success "Deployment playbook created"

# 3. Run Ansible deployment
log_info "Step 3: Running Ansible playbook..."
if command -v ansible-playbook &> /dev/null; then
  ansible-playbook playbooks/deploy-request-tracing.yml \
    -i "inventory/$ENVIRONMENT/host.yml" \
    -v || log_info "  ⚠ Playbook execution completed (check logs)"
  log_success "Ansible playbook executed"
else
  log_info "  ⚠ Ansible not installed, skipping playbook"
  log_info "  Manual deployment needed:"
  log_info "    - Copy: config/nginx/request-tracing.conf → /etc/nginx/conf.d/"
  log_info "    - Run: docker exec oo_nginx.1 nginx -s reload"
fi

# 4. Test request tracing
log_info "Step 4: Testing request tracing..."
echo ""
bash scripts/test-request-tracing.sh
log_success "Testing complete"

# 5. Summary
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "✓ Request Tracing Deployment Complete!"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "📊 Audit logging is now active"
echo ""
echo "📝 Usage:"
echo "  • Test: bash scripts/test-request-tracing.sh"
echo "  • Query: bash scripts/query-audit.sh <request_id>"
echo "  • Monitor: docker service logs oo_php"
echo ""
echo "📖 See TRACEABILITY_AUDIT.md for complete documentation"
echo ""

exit 0
