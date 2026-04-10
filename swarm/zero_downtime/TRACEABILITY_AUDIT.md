# 🔍 Traçabilité & Audit: Quel Réplica Traite Quelle Requête?

## Le Problème: Transparence vs Traçabilité

### ❌ Par Défaut dans Docker Swarm

```
Requête utilisateur:
  GET /patients/12345

Traefik (Load Balancer):
  └─ "Je vais distribuer cette requête..."
  
Docker IPVS (IP Virtual Server - transparent):
  └─ Forwarde vers Réplica A (ou B? pas évident!)
  
PHP Réplica A/B:
  └─ Traite la requête
  └─ Envoie réponse
  
PROBLÈME: 🤔 "Quel réplica a traité ma requête?"
```

**Aucun moyen simple de le savoir sans instrumentation!**

---

## ✅ Solutions: 5 Approches pour la Traçabilité

### 1️⃣ **LOGS AVEC CONTAINER ID** (Recommandé pour démarrer)

#### Implementation Simple: Ajouter dans PHP

**Éditer Dockerfile PHP ou Application:**

```php
<?php
// Dans votre app Symfony/PHP
$container_id = gethostname();  // Récupère le hostname du conteneur
$request_id = uniqid('req_');   // ID unique par requête

error_log("[$request_id] Container: $container_id | GET /patients/12345");
// Output: [req_6621b9c05001] Container: php.1.abcd1234xyz | GET /patients/12345
```

**Docker Compose Config:**

```yaml
php:
  image: php:8.1-fpm
  deploy:
    replicas: 2
  environment:
    # Ajouter le container ID aux logs
    - LOG_FORMAT="[%request_id%] [%hostname%] %message%"
```

**Résultat dans les Logs:**
```
[req_6621b9c05001] [php.1.abcd1234xyz] GET /patients/12345
[req_6621b9c05002] [php.2.wxyz5678abc] POST /patients/12345/documents
```

#### Voir les Logs par Réplica:

```bash
# Voir TOUS les logs (mélangé de tous les replicas)
docker service logs oo_php

# Voir les logs d'UN réplica spécific (si vous le trouvez)
docker logs <container_id>

# Voir les logs avec le contexte (montre quel réplica)
docker service logs oo_php --raw

# Filter par timestamp (pour trouver la requête)
docker service logs oo_php --since 2024-01-15T10:30:00Z --until 2024-01-15T10:35:00Z
```

---

### 2️⃣ **HEADERS HTTP TRAEFIK** (Transparent pour Application)

Traefik peut ajouter automatiquement les headers indiquant comment il a routi:

**Configuration Traefik (docker-compose.yml):**

```yaml
traefik:
  command:
    # Ajouter la source du routing dans les réponses
    - "--entryPoints.http.forwardedHeaders.insecure=true"
    - "--entryPoints.http.address=:80"
  labels:
    # Ajouter les headers de routing
    - "traefik.http.middlewares.add-routing-headers.headers.customresponseheaders.X-Served-By=service"
    - "traefik.http.middlewares.add-routing-headers.headers.customresponseheaders.X-Service-Host=@docker"
```

**Application PHP lit les headers:**

```php
<?php
// Dans Symfony/Laravel/Pure PHP
$served_by = $_SERVER['HTTP_X_FORWARDED_SERVER'] ?? 'unknown';
$remote_addr = $_SERVER['HTTP_X_FORWARDED_FOR'] ?? $_SERVER['REMOTE_ADDR'];
$host = gethostname();

error_log("Served by: $served_by | Host: $host | IP: $remote_addr");
```

**Résultat:**
```
Served by: nginx.1.xyz123 | Host: php.1.abcd1234 | IP: 172.17.0.5
Served by: nginx.2.abc456 | Host: php.2.wxyz5678 | IP: 172.17.0.6
```

---

### 3️⃣ **REQUEST ID TRACKING** (Audit Chain Complet - RECOMMANDÉ)

C'est la **meilleure approach pour environnement médical**: Chaque requête reçoit un ID unique tracksable à travers tous les services.

#### Implémentation Complète:

**1. Nginx Config (ajouter X-Request-ID):**

```nginx
# Dans nginx.conf ou via label Traefik
server {
  location / {
    # Générer Request ID unique si pas présent
    map $http_x_request_id $request_id_generated {
      default $http_x_request_id;
      "" $request_time-$msec-$remote_addr;
    }
    
    # Passer au backend + logger
    proxy_set_header X-Request-ID $request_id_generated;
    proxy_pass http://php-backend;
    
    # Log avec request ID
    access_log /var/log/nginx/access.log main_with_request_id;
  }
}

# Format log personnalisé
log_format main_with_request_id 
  '$remote_addr - $remote_user [$time_local] "$request" '
  '$status $body_bytes_sent "$http_referer" '
  '"$http_user_agent" "$http_x_forwarded_for" '
  'req_id=$http_x_request_id container=$hostname';
```

**2. PHP Application (Logger Request ID + Container):**

```php
<?php
// Middleware: Capturer Request ID au démarrage
function setup_request_tracking() {
    $request_id = $_SERVER['HTTP_X_REQUEST_ID'] ?? 'no-id-' . uniqid();
    $container_id = gethostname();
    $service_name = getenv('SERVICE_NAME') ?? 'php-unknown';
    
    // Stocker dans une variable globale ou contexte (Symfony, Laravel)
    define('REQUEST_ID', $request_id);
    define('CONTAINER_ID', $container_id);
    define('SERVICE_NAME', $service_name);
    
    // Logger au démarrage
    error_log("[REQUEST] ID=$request_id | Container=$container_id | Service=$service_name | Path={$_SERVER['REQUEST_URI']}");
}

// Utiliser partout dans l'app:
function log_action($action, $details) {
    $timestamp = date('Y-m-d H:i:s.u');
    $entry = "[{$timestamp}] [REQUEST_ID=" . REQUEST_ID . "] [CONTAINER=" . CONTAINER_ID . "] [$action] $details";
    error_log($entry);
    
    // Envoyer aussi à ELK/Datadog si centralisé
    send_to_log_aggregator($entry);
}

// Exemple usage:
log_action('PATIENT_FETCH', "Fetching patient#12345");
log_action('DATABASE_QUERY', "SELECT * FROM patients WHERE id=12345");
log_action('AUTH_CHECK', "Session validation passed");
```

**3. Docker Compose - Set Environment Variables:**

```yaml
php:
  environment:
    - SERVICE_NAME=one-platform-php
    - LOG_REQUEST_ID=true
    - CONTAINER_HOSTNAME=replacement  # Force use gethostname()
    
nginx:
  environment:
    - SERVICE_NAME=one-platform-nginx
```

**Résultat: Chaîne Complète de Traçabilité**

```
REQUEST FLOW:
------ 10:30:45.123 ------
[REQUEST] ID=req-abc123-xyz789 | Container=php.1.abcd1234 | Service=one-platform-php | Path=/patients/12345/documents

[10:30:45.124] [REQUEST_ID=req-abc123-xyz789] [CONTAINER=php.1.abcd1234] [AUTH_CHECK] Session validation passed
[10:30:45.130] [REQUEST_ID=req-abc123-xyz789] [CONTAINER=php.1.abcd1234] [PATIENT_FETCH] Fetching patient#12345
[10:30:45.145] [REQUEST_ID=req-abc123-xyz789] [CONTAINER=php.1.abcd1234] [DATABASE_QUERY] SELECT * FROM patients WHERE id=12345
[10:30:45.250] [REQUEST_ID=req-abc123-xyz789] [CONTAINER=php.1.abcd1234] [DOCUMENT_UPLOAD] Processing document_uuid=doc-xyz

STORED IN DATABASE:
- request_id: req-abc123-xyz789
- container_id: php.1.abcd1234
- service_name: one-platform-php
- timestamp: 2024-01-15 10:30:45.123
- action: PATIENT_DOCUMENT_UPLOAD
- patient_id: 12345
- user_id: 998
- status: SUCCESS
```

**AUDIT TRAIL: Complètement traceable! ✅**

---

### 4️⃣ **DOCKER SERVICE PS** (En Temps Réel)

Pour voir **maintenant** quel réplica est actif/sain:

```bash
# Voir l'état current de chaque réplica
docker service ps oo_php --no-trunc

# Output: 
# ID              NAME        IMAGE           NODE        DESIRED STATE  CURRENT STATE
# abcd1234xyz     oo_php.1    php:8.1-fpm     node1       Running        Running 2h ago
# wxyz5678abc     oo_php.2    php:8.1-fpm     node2       Running        Running 1h 30m ago

# Voir avec plus de détails
docker service ps oo_php --no-trunc --format "{{.ID}}\t{{.Name}}\t{{.Node}}\t{{.CurrentState}}"
```

**Combiner avec LOGS:**

```bash
# 1. Trouver le container ID du réplica
SERVICE_REPLICA=$(docker service ps oo_php --format "{{.ID}}" | head -1)

# 2. Voir les logs spécifiques du réplica
docker logs $SERVICE_REPLICA --follow
```

---

### 5️⃣ **PROMETHEUS METRICS** (Pour Monitoring Avancé)

Si vous avez déjà Prometheus/Grafana:

**PHP Application - Exporter Metrics:**

```php
<?php
// Prometheus metrics
function track_request_metrics() {
    $container = gethostname();
    $endpoint = $_SERVER['REQUEST_URI'];
    $method = $_SERVER['REQUEST_METHOD'];
    
    // Envoyer à Prometheus pushgateway
    $metric_data = [
        'requests_total' => [
            'labels' => [
                'container' => $container,
                'endpoint' => $endpoint,
                'method' => $method,
            ],
            'value' => 1,
        ],
    ];
    
    // Envoyer à Prometheus (ou middleware)
    record_prometheus_metric($metric_data);
}
```

**Puis Query dans Grafana:**

```
# Voir combien de requêtes par container
increase(requests_total[5m]) by (container)

# Résultat:
# php.1.abcd1234  → 245 requêtes/5min
# php.2.wxyz5678  → 248 requêtes/5min
```

---

## 🏥 Configuration COMPLÈTE pour Environnement Médical

Voici la **meilleure config pour audit/traçabilité médicale**:

### Architecture:

```
Requête Utilisateur
    ↓
Traefik (Log + X-Request-ID)
    ↓
Nginx (Log X-Request-ID + Container ID)
    ↓
PHP (LOG + REQUEST_ID + CONTAINER_ID dans chaque action)
    ↓
Database (Audit logs avec request_id)
    ↓
Log Aggregator (ELK/Datadog) - Centralisé
    ↓
AUDIT TRAIL: Complètement traceable ✅
```

### Docker Compose (complet):

```yaml
services:
  nginx:
    image: nginx:alpine
    environment:
      - SERVICE_NAME=one-platform-nginx
      - CONTAINER_HOSTNAME=yes
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
    logging:
      driver: "json-file"
      options:
        labels: "service=nginx,env=prod"
        max-size: "10m"
        max-file: "3"
    deploy:
      replicas: 2

  php:
    image: custom-php:latest
    environment:
      - SERVICE_NAME=one-platform-php
      - LOG_REQUEST_ID=true  # Active Request ID tracking
      - DATABASE_AUDIT_TABLE=audit_logs  # Où logguer les actions
    logging:
      driver: "json-file"
      options:
        labels: "service=php,env=prod"
        max-size: "10m"
        max-file: "3"
    deploy:
      replicas: 2

  # Optional: Log Aggregator (Elasticsearch + Kibana)
  elasticsearch:
    image: elasticsearch:latest
    environment:
      - discovery.type=single-node
    ports:
      - "9200:9200"

  kibana:
    image: kibana:latest
    ports:
      - "5601:5601"
    depends_on:
      - elasticsearch
```

### PHP Résilience (Code Complet):

```php
<?php
namespace App\Middleware;

class RequestTrackingMiddleware {
    
    private string $request_id;
    private string $container_id;
    private string $service_name;
    private array $audit_log = [];
    
    public function __construct() {
        // Initialiser le tracking
        $this->request_id = $_SERVER['HTTP_X_REQUEST_ID'] ?? $this->generate_request_id();
        $this->container_id = gethostname();
        $this->service_name = getenv('SERVICE_NAME') ?? 'unknown';
        
        // Stocker dans superglobale pour accès partout
        $GLOBALS['REQUEST_CONTEXT'] = [
            'request_id' => $this->request_id,
            'container_id' => $this->container_id,
            'service_name' => $this->service_name,
            'timestamp' => microtime(true),
            'user_id' => $_SESSION['user_id'] ?? null,
            'ip' => $_SERVER['HTTP_X_FORWARDED_FOR'] ?? $_SERVER['REMOTE_ADDR'],
        ];
        
        // Logger démarrage
        $this->log_action('REQUEST_START', "Starting request");
    }
    
    private function generate_request_id(): string {
        return sprintf(
            '%s-%s-%s',
            date('YmdHis'),
            uniqid(),
            substr(bin2hex(random_bytes(4)), 0, 8)
        );
    }
    
    public function log_action(string $action, string $details, array $extra = []): void {
        $log_entry = [
            'timestamp' => date('Y-m-d H:i:s.u'),
            'request_id' => $this->request_id,
            'container_id' => $this->container_id,
            'service_name' => $this->service_name,
            'action' => $action,
            'details' => $details,
            'user_id' => $_SESSION['user_id'] ?? null,
            'ip' => $_SERVER['REMOTE_ADDR'],
            'extra' => $extra,
        ];
        
        // Log local
        error_log(json_encode($log_entry));
        
        // Envoyer à base de données (audit table)
        if (getenv('DATABASE_AUDIT_TABLE')) {
            $this->save_to_audit_db($log_entry);
        }
        
        // Envoyer à Log Aggregator
        $this->send_to_aggregator($log_entry);
    }
    
    private function save_to_audit_db(array $entry): void {
        // Implémenter sauvegarde en DB
        // INSERT INTO audit_logs (request_id, container_id, action, details, timestamp, user_id)
    }
    
    private function send_to_aggregator(array $entry): void {
        // Envoyer à ELK/Datadog/CloudWatch
        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL, 'http://elasticsearch:9200/audit-logs/_doc');
        curl_setopt($ch, CURLOPT_POST, true);
        curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($entry));
        curl_setopt($ch, CURLOPT_TIMEOUT, 2);
        @curl_exec($ch);
        curl_close($ch);
    }
}

// Utiliser dans Symfony:
// Add to config/services.yaml:
// App\Middleware\RequestTrackingMiddleware:
//   arguments: []
//   tags:
//     - { name: 'kernel.event_listener', event: 'kernel.request', priority: 255 }
```

---

## 🎯 Résumé: Solutions par Cas d'Usage

| Cas d'Usage | Solution | Complexity | Cout |
|-------------|----------|-----------|------|
| **Juste savoir quel réplica traite** | Logs + gethostname() | ⭐ Facile | 0€ |
| **Audit simple** | Request ID + Container ID | ⭐⭐ Moyen | 0€ |
| **Audit complet (RCPD médical)** | Request ID + DB Audit + Aggregator | ⭐⭐⭐ Complexe | ELK/Datadog |
| **Monitoring Temps Réel** | Prometheus + Grafana | ⭐⭐⭐ Complexe | 0€ (open-source) |

---

## 📋 Checklist pour Environnement Médical

- [ ] Chaque requête a un REQUEST_ID unique
- [ ] Chaque log inclut le CONTAINER_ID
- [ ] Audit trail stocké en DB (legalement exigé)
- [ ] Timestamps précis (UTC)
- [ ] User ID tracé pour chaque action
- [ ] IP Source loggée
- [ ] Logs centralisés (Elasticsearch/ELK)
- [ ] Retention conforme (RGPD: 7 ans minimum pour données médicales)
- [ ] Alertes si UPDATE sur donnée patient
- [ ] Alertes si DELETE on audit logs

---

## Commandes Utiles pour Investigation

```bash
# 1. Trouver les logs d'un Request ID spécifique
docker service logs oo_php | grep "req-abc123-xyz789"

# 2. Voir les logs d'un déploiement spécifique
docker service logs oo_php --follow --timestamps

# 3. Exporter les logs pour analyse
docker service logs oo_php > /tmp/logs_export.txt

# 4. Monitorer en real-time quel réplica traite
watch -n 1 'docker service ps oo_php'

# 5. Vérifier que Request ID est passé
curl -v http://app.test/patients/12345 2>&1 | grep "X-Request-ID"
```
