#!/bin/bash
# Script: Setup Request Tracing pour Traçabilité Médicale
# Usage: bash scripts/setup-request-tracing.sh

set -e

COLOR_GREEN='\033[0;32m'
COLOR_YELLOW='\033[1;33m'
COLOR_RED='\033[0;31m'
NC='\033[0m'

log_info() {
  echo -e "${COLOR_YELLOW}ℹ️  $@${NC}"
}

log_success() {
  echo -e "${COLOR_GREEN}✓ $@${NC}"
}

log_error() {
  echo -e "${COLOR_RED}❌ $@${NC}"
}

echo "═══════════════════════════════════════════════"
echo "Setup Request Tracing pour Traçabilité Audit"
echo "═══════════════════════════════════════════════"
echo ""

# Configuration
ENVIRONMENT="${1:-preprod}"
log_info "Environment: $ENVIRONMENT"

# 1. Créer structure de logs
log_info "Creating audit log directories..."
mkdir -p /var/log/audit/{nginx,php,application}
log_success "Log directories created"

# 2. Vérifier Docker est accessible
if ! docker ps > /dev/null 2>&1; then
  log_error "Docker not accessible"
  exit 1
fi
log_success "Docker is accessible"

# 3. Créer config Nginx pour Request Tracing
log_info "Creating Nginx config for Request ID tracking..."
mkdir -p ./config/nginx
cat > ./config/nginx/request-tracing.conf << 'EOF'
# Request ID Tracking Configuration
# Ajouter ceci à votre nginx.conf principal

# Map pour générer Request ID si absent
map $http_x_request_id $request_id_final {
    default $http_x_request_id;
    "" "$request_time-$msec-$remote_addr-$request_length";
}

# Log format avec Request ID et Container
log_format main_audit 
    '[$time_local] '
    'req_id=$request_id_final '
    'container=$hostname '
    'method=$request_method '
    'path=$request_uri '
    'status=$status '
    'bytes_sent=$body_bytes_sent '
    'duration=${request_time}ms '
    'upstream=$upstream_addr '
    'user_agent="$http_user_agent" '
    'remote_ip=$http_x_forwarded_for';

# Access log (audit)
access_log /var/log/audit/nginx/access.log main_audit;

# Passer le Request ID au backend
proxy_set_header X-Request-ID $request_id_final;
proxy_set_header X-Real-IP $remote_addr;
proxy_set_header X-Forwarded-For $http_x_forwarded_for;
proxy_set_header X-Forwarded-Proto $scheme;
EOF

log_success "Nginx config created: ./config/nginx/request-tracing.conf"

# 4. Créer PHP class pour Request Tracking
log_info "Creating PHP Request Tracking class..."
mkdir -p ./app/Middleware
cat > ./app/Middleware/RequestTrackingMiddleware.php << 'EOF'
<?php
namespace App\Middleware;

use Psr\Log\LoggerInterface;

class RequestTrackingMiddleware {
    
    private string $request_id;
    private string $container_id;
    private string $service_name;
    private LoggerInterface $logger;
    private float $request_start_time;
    
    public function __construct(LoggerInterface $logger) {
        $this->logger = $logger;
        $this->request_start_time = microtime(true);
        
        // Initialiser les identifiants
        $this->request_id = $_SERVER['HTTP_X_REQUEST_ID'] ?? $this->generateRequestId();
        $this->container_id = gethostname();
        $this->service_name = getenv('SERVICE_NAME') ?? 'unknown';
        
        // Stocker dans superglobale
        $_SERVER['REQUEST_TRACKING'] = [
            'request_id' => $this->request_id,
            'container_id' => $this->container_id,
            'service_name' => $this->service_name,
            'start_time' => $this->request_start_time,
            'user_id' => $_SESSION['user_id'] ?? null,
            'ip' => $_SERVER['HTTP_X_FORWARDED_FOR'] ?? $_SERVER['REMOTE_ADDR'] ?? 'unknown',
        ];
        
        // Log démarrage
        $this->logAction('REQUEST_START', "Request started", [
            'method' => $_SERVER['REQUEST_METHOD'] ?? 'UNKNOWN',
            'path' => $_SERVER['REQUEST_URI'] ?? '/',
            'ip' => $_SERVER['REMOTE_ADDR'] ?? 'unknown',
        ]);
    }
    
    private function generateRequestId(): string {
        return sprintf(
            'req-%s-%s-%s',
            date('YmdHis'),
            uniqid(),
            bin2hex(random_bytes(4))
        );
    }
    
    public function logAction(
        string $action,
        string $message = '',
        array $context = [],
        string $level = 'info'
    ): void {
        $elapsed = round((microtime(true) - $this->request_start_time) * 1000, 2);
        
        $log_context = array_merge([
            'request_id' => $this->request_id,
            'container_id' => $this->container_id,
            'service_name' => $this->service_name,
            'action' => $action,
            'elapsed_ms' => $elapsed,
            'user_id' => $_SESSION['user_id'] ?? null,
            'ip' => $_SERVER['REMOTE_ADDR'] ?? 'unknown',
        ], $context);
        
        // Log via PSR Logger
        $this->logger->log($level, $message, $log_context);
        
        // Log audit simple aussi
        error_log(sprintf(
            '[%s] [%s] [%s] %s | Container: %s | ElapsedMS: %.2f',
            date('Y-m-d H:i:s'),
            $this->request_id,
            $action,
            $message,
            $this->container_id,
            $elapsed
        ));
    }
    
    public function getRequestContext(): array {
        return $_SERVER['REQUEST_TRACKING'] ?? [];
    }
}
EOF

log_success "PHP Middleware created: ./app/Middleware/RequestTrackingMiddleware.php"

# 5. Créer config Docker Compose snippet
log_info "Creating Docker Compose configuration..."
mkdir -p ./docker-compose
cat > ./docker-compose/request-tracing.yml << 'EOF'
# Add this to your docker-compose.yml

services:
  php:
    environment:
      - SERVICE_NAME=one-plateform-php
      - LOG_REQUEST_ID=true
      - LOG_LEVEL=info
    logging:
      driver: "json-file"
      options:
        labels: "service=php,env=production"
        max-size: "100m"
        max-file: "5"
        tag: "{{.ImageName}}-{{.Name}}-{{.ID}}"

  nginx:
    environment:
      - SERVICE_NAME=one-plateform-nginx
    volumes:
      - ./config/nginx/request-tracing.conf:/etc/nginx/conf.d/request-tracing.conf:ro
    logging:
      driver: "json-file"
      options:
        labels: "service=nginx,env=production"
        max-size: "100m"
        max-file: "5"
        tag: "{{.ImageName}}-{{.Name}}-{{.ID}}"
EOF

log_success "Docker Compose config created: ./docker-compose/request-tracing.yml"

# 6. Créer script de Query Audit
log_info "Creating audit query script..."
cat > ./scripts/query-audit.sh << 'EOF'
#!/bin/bash
# Query audit logs for a specific request

REQUEST_ID="${1}"
CONTAINER="${2:-all}"

if [ -z "$REQUEST_ID" ]; then
  echo "Usage: bash scripts/query-audit.sh <request_id> [container]"
  echo ""
  echo "Examples:"
  echo "  bash scripts/query-audit.sh req-20240115-xyz"
  echo "  bash scripts/query-audit.sh req-20240115-xyz php.1"
  exit 1
fi

echo "Searching audit logs for Request ID: $REQUEST_ID"
echo "═══════════════════════════════════════════════════════════"

# Search in service logs
if [ "$CONTAINER" = "all" ] || [ "$CONTAINER" = "php" ]; then
  echo ""
  echo "📝 PHP Logs:"
  docker service logs oo_php 2>/dev/null | grep "$REQUEST_ID" | head -20
fi

if [ "$CONTAINER" = "all" ] || [ "$CONTAINER" = "nginx" ]; then
  echo ""
  echo "🌐 Nginx Logs:"
  docker service logs oo_nginx 2>/dev/null | grep "$REQUEST_ID" | head -20
fi

# If not found in service logs, try Docker logs directly
if [ "$CONTAINER" = "all" ]; then
  echo ""
  echo "📦 Docker Logs:"
  docker ps -a --format "table {{.ID}}\t{{.Names}}\t{{.Status}}" | grep -E "oo_php|oo_nginx" | while read line; do
    CONTAINER_ID=$(echo $line | awk '{print $1}')
    docker logs $CONTAINER_ID 2>/dev/null | grep "$REQUEST_ID" | head -5
  done || true
fi

echo ""
echo "═══════════════════════════════════════════════════════════"
EOF

chmod +x ./scripts/query-audit.sh
log_success "Audit query script created: ./scripts/query-audit.sh"

# 7. Créer script de verification
log_info "Creating verification script..."
cat > ./scripts/test-request-tracing.sh << 'EOF'
#!/bin/bash
# Test Request Tracing setup

echo "Testing Request Tracing..."
echo "═══════════════════════════════════════════════════════════"

# 1. Test HTTP Request
echo "[1/3] Making test HTTP request..."
REQUEST_ID="test-$(date +%s)"
echo "  Using Request ID: $REQUEST_ID"

RESPONSE=$(curl -s -H "X-Request-ID: $REQUEST_ID" http://app.test/health 2>/dev/null || echo "FAILED")

if [ "$RESPONSE" != "FAILED" ]; then
  echo "  ✓ Request successful"
else
  echo "  ⚠ Could not reach app.test (normal if not configured)"
fi

# 2. Test logging
echo ""
echo "[2/3] Checking logs for Request ID..."
docker service logs oo_php 2>/dev/null | grep -c "$REQUEST_ID" > /dev/null && {
  echo "  ✓ Request ID found in PHP logs"
} || echo "  ⚠ Request ID not in logs (may need to wait)"

# 3. Check containers
echo ""
echo "[3/3] Active containers:"
docker service ps oo_php --format "table {{.Name}}\t{{.CurrentState}}\t{{.Node}}"

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "Test complete!"
EOF

chmod +x ./scripts/test-request-tracing.sh
log_success "Test script created: ./scripts/test-request-tracing.sh"

# Summary
echo ""
echo "═══════════════════════════════════════════════════════════"
echo "✓ Request Tracing Setup Complete!"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "📋 Files created:"
echo "  • ./config/nginx/request-tracing.conf"
echo "  • ./app/Middleware/RequestTrackingMiddleware.php"
echo "  • ./docker-compose/request-tracing.yml"
echo "  • ./scripts/query-audit.sh"
echo "  • ./scripts/test-request-tracing.sh"
echo ""
echo "🚀 Next steps:"
echo "  1. Include nginx config: in nginx.conf add: include /etc/nginx/conf.d/request-tracing.conf;"
echo "  2. Add to docker-compose.yml: '    - ./docker-compose/request-tracing.yml'"
echo "  3. Initialize RequestTrackingMiddleware in your PHP app (Symfony/Laravel)"
echo "  4. Test: bash scripts/test-request-tracing.sh"
echo "  5. Query audit: bash scripts/query-audit.sh <request_id>"
echo ""
echo "📖 Documentation: TRACEABILITY_AUDIT.md"
echo ""

exit 0
EOF

log_success "Setup script created: ./scripts/setup-request-tracing.sh"

echo ""
echo "Done! All files created successfully ✓"
