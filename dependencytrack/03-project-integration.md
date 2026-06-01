# Intégration des projets Git avec DependencyTrack

## Vue d'ensemble

Intégration des trois projets `saas_local/` (app, modulesjs, branch_hardening) avec DependencyTrack. Génération automatique de SBOM en CycloneDX via GitHub Actions et upload sur chaque commit.

---

## Architecture du flux SBOM

```
┌──────────────────────────────────────────────────────────┐
│  Push Code → GitHub                                      │
├──────────────────────────────────────────────────────────┤
│                                                          │
│  ↓                                                       │
│  GitHub Actions Workflow (dépendencytrack.yml)          │
│  ├─ Checkout code                                       │
│  ├─ Générer SBOM CycloneDX                              │
│  │  ├─ PHP (app): composer install → cyclonedx          │
│  │  └─ Node (modulesjs): npm install → cyclonedx        │
│  ├─ Valider SBOM (XSD schema)                           │
│  └─ Upload vers DependencyTrack API                     │
│                                                          │
│  ↓                                                       │
│  DependencyTrack ingère SBOM                            │
│  ├─ Parse composants et dépendances                     │
│  ├─ Croise avec NVD/CVE database                        │
│  ├─ Identifie vulnérabilités                           │
│  └─ Déclenche webhooks Slack (voir 02-slack-alerts)    │
│                                                          │
└──────────────────────────────────────────────────────────┘
```

---

## 1. Créer les projets dans DependencyTrack

### 1.1 Via l'API

Script d'initialisation (à exécuter une fois) :

**File: `scripts/init-dependencytrack-projects.sh`**

```bash
#!/bin/bash

set -e

DT_URL="${DT_URL:-https://dependencytrack.oo-medical.local}"
DT_API_KEY="${DT_API_KEY}"
GITHUB_ORG="OneOrthoMedical"

if [ -z "${DT_API_KEY}" ]; then
  echo "Error: DT_API_KEY not set"
  exit 1
fi

# Projets à créer
declare -A PROJECTS=(
  [app]="OO Medical SaaS Platform — Application backend"
  [modulesjs]="OO Medical SaaS Platform — JavaScript modules library"
  [branch_hardening]="OO Medical SaaS Platform — Security hardening rules"
)

for PROJECT_NAME in "${!PROJECTS[@]}"; do
  PROJECT_DESC="${PROJECTS[$PROJECT_NAME]}"
  REPO_URL="https://github.com/${GITHUB_ORG}/${PROJECT_NAME}"

  echo "Creating project: ${PROJECT_NAME}..."

  RESPONSE=$(curl -s -X POST "${DT_URL}/api/v1/project" \
    -H "X-API-Key: ${DT_API_KEY}" \
    -H "Content-Type: application/json" \
    -d "{
      \"name\": \"${PROJECT_NAME}\",
      \"description\": \"${PROJECT_DESC}\",
      \"version\": \"1.0.0\",
      \"active\": true,
      \"tags\": [
        {\"name\": \"saas_local\"},
        {\"name\": \"github\"},
        {\"name\": \"production\"}
      ]
    }")

  PROJECT_UUID=$(echo "${RESPONSE}" | jq -r '.uuid // empty')

  if [ -z "${PROJECT_UUID}" ]; then
    echo "❌ Failed to create project ${PROJECT_NAME}"
    echo "Response: ${RESPONSE}"
    exit 1
  fi

  echo "✅ Project created: ${PROJECT_NAME} (UUID: ${PROJECT_UUID})"

  # Stocker UUID pour GitHub Actions
  echo "${PROJECT_NAME}_UUID=${PROJECT_UUID}" >> /tmp/dt-projects.env
done

echo ""
echo "All projects created successfully"
echo "Store these UUIDs in your GitHub repository secrets"
```

Exécution :

```bash
export DT_URL="https://dependencytrack.oo-medical.local"
export DT_API_KEY="$(vault kv get -field=api_key secret/dependencytrack)"

chmod +x scripts/init-dependencytrack-projects.sh
./scripts/init-dependencytrack-projects.sh

# Récupérer les UUIDs
cat /tmp/dt-projects.env
```

### 1.2 Stocker les UUIDs dans les secrets GitHub

Pour chaque projet (app, modulesjs, branch_hardening) :

1. Aller à **Settings → Secrets and variables → Actions**
2. Ajouter secrets :
   - `DT_PROJECT_UUID` (UUID unique du projet)
   - `DT_API_KEY` (clé API commune)
   - `DT_URL` (URL de l'instance DependencyTrack)

```bash
# Exemple pour le projet 'app'
gh secret set DT_PROJECT_UUID -b "12345678-1234-1234-1234-123456789012" -R OneOrthoMedical/app
gh secret set DT_API_KEY -b "$(vault kv get -field=api_key secret/dependencytrack)" -R OneOrthoMedical/app
gh secret set DT_URL -b "https://dependencytrack.oo-medical.local" -R OneOrthoMedical/app
```

---

## 2. Générateurs SBOM par type de projet

### 2.1 App (PHP Composer)

**File: `app/.github/workflows/dependencytrack.yml`**

```yaml
name: DependencyTrack - SBOM Generation

on:
  push:
    branches:
      - main
      - develop
    paths:
      - 'composer.json'
      - 'composer.lock'
  schedule:
    - cron: '0 2 * * *'  # Daily 2 AM

jobs:
  generate-sbom:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup PHP
        uses: shivammathur/setup-php@v2
        with:
          php-version: '8.2'
          tools: composer:latest

      - name: Cache composer dependencies
        uses: actions/cache@v3
        with:
          path: vendor
          key: ${{ runner.os }}-composer-${{ hashFiles('**/composer.lock') }}
          restore-keys: |
            ${{ runner.os }}-composer-

      - name: Install dependencies
        run: composer install --no-interaction --prefer-dist

      - name: Install CycloneDX
        run: |
          composer require --dev cyclonedx/composer-plugin:latest || \
          composer global require cyclonedx/composer-plugin:latest

      - name: Generate CycloneDX SBOM
        run: |
          composer CycloneDX:make-sbom \
            --output sbom.xml \
            --format xml \
            --spec-version 1.4 || \
          cyclonedx composer . --output sbom.xml --spec 1.4

      - name: Validate SBOM
        run: |
          curl -s https://raw.githubusercontent.com/CycloneDX/specification/master/schema/bom-1.4.xsd \
            > /tmp/bom-1.4.xsd
          
          # Optionnel : valider avec xmllint
          xmllint --noout --schema /tmp/bom-1.4.xsd sbom.xml || true
          
          # Vérifier qu'il n'est pas vide
          [ -s sbom.xml ] && wc -l sbom.xml

      - name: Upload SBOM to DependencyTrack
        env:
          DT_URL: ${{ secrets.DT_URL }}
          DT_API_KEY: ${{ secrets.DT_API_KEY }}
          DT_PROJECT_UUID: ${{ secrets.DT_PROJECT_UUID }}
        run: |
          curl -s -X POST "${DT_URL}/api/v1/bom" \
            -H "X-API-Key: ${DT_API_KEY}" \
            -H "Content-Type: application/json" \
            -d @- <<EOF
          {
            "projectUuid": "${DT_PROJECT_UUID}",
            "bom": "$(base64 -w 0 sbom.xml)"
          }
          EOF
          
          echo "✅ SBOM uploaded successfully"

      - name: Post SBOM to pull request
        if: github.event_name == 'push'
        uses: actions/github-script@v7
        with:
          script: |
            const fs = require('fs');
            const sbom = fs.readFileSync('sbom.xml', 'utf8');
            const lines = sbom.split('\n').length;
            
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: `📦 **SBOM Generated**\n\n- Format: CycloneDX 1.4\n- Components: ${lines - 10} (approx)\n- Uploaded to DependencyTrack\n\n[View in DependencyTrack](${process.env.DT_URL}/project/${process.env.DT_PROJECT_UUID})`
            });
```

### 2.2 Modulesjs (Node/npm)

**File: `modulesjs/.github/workflows/dependencytrack.yml`**

```yaml
name: DependencyTrack - SBOM Generation

on:
  push:
    branches:
      - main
      - develop
    paths:
      - 'package.json'
      - 'package-lock.json'
  schedule:
    - cron: '0 2 * * *'  # Daily 2 AM

jobs:
  generate-sbom:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Install CycloneDX CLI
        run: npm install -g @cyclonedx/npm

      - name: Generate CycloneDX SBOM
        run: |
          cyclonedx-npm \
            --output-file sbom.json \
            --output-format json \
            --spec-version 1.4 \
            --include-dev

      - name: Validate SBOM
        run: |
          # Vérifier format JSON valide
          jq '.' sbom.xml > /dev/null && echo "✅ Valid JSON"
          
          # Extraire composants
          COMPONENT_COUNT=$(jq '.components | length' sbom.json)
          echo "📦 Total components: ${COMPONENT_COUNT}"

      - name: Upload SBOM to DependencyTrack
        env:
          DT_URL: ${{ secrets.DT_URL }}
          DT_API_KEY: ${{ secrets.DT_API_KEY }}
          DT_PROJECT_UUID: ${{ secrets.DT_PROJECT_UUID }}
        run: |
          # Encoder SBOM en base64
          SBOM_B64=$(base64 -w 0 sbom.json)
          
          # Upload
          curl -s -X POST "${DT_URL}/api/v1/bom" \
            -H "X-API-Key: ${DT_API_KEY}" \
            -H "Content-Type: application/json" \
            -d @- <<EOF
          {
            "projectUuid": "${DT_PROJECT_UUID}",
            "bom": "${SBOM_B64}"
          }
          EOF
          
          echo "✅ SBOM uploaded successfully"

      - name: Check scan results
        env:
          DT_URL: ${{ secrets.DT_URL }}
          DT_API_KEY: ${{ secrets.DT_API_KEY }}
          DT_PROJECT_UUID: ${{ secrets.DT_PROJECT_UUID }}
        run: |
          # Attendre que le scan soit traité (max 60 secondes)
          for i in {1..12}; do
            VULNS=$(curl -s \
              "${DT_URL}/api/v1/vulnerabilities" \
              -H "X-API-Key: ${DT_API_KEY}" \
              -H "Accept: application/json" \
              | jq "[.[] | select(.project.uuid == \"${DT_PROJECT_UUID}\")] | length")
            
            if [ "${VULNS}" -gt 0 ]; then
              echo "✅ Vulnerabilities detected: ${VULNS}"
              break
            fi
            
            sleep 5
          done
```

### 2.3 Branch Hardening (Mixed — docs + rules)

**File: `branch_hardening/.github/workflows/dependencytrack.yml`**

```yaml
name: DependencyTrack - SBOM Generation

on:
  push:
    branches:
      - main
  schedule:
    - cron: '0 2 * * *'

jobs:
  generate-sbom:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Install CycloneDX CLI
        run: npm install -g @cyclonedx/cyclonedx-npm

      - name: Generate minimal SBOM
        run: |
          cat > sbom.json <<'EOF'
          {
            "bomFormat": "CycloneDX",
            "specVersion": "1.4",
            "serialNumber": "urn:uuid:$(uuidgen)",
            "version": 1,
            "metadata": {
              "timestamp": "$(date -u +'%Y-%m-%dT%H:%M:%SZ')",
              "tools": [
                {
                  "vendor": "OneOrtho",
                  "name": "branch_hardening-generator",
                  "version": "1.0.0"
                }
              ],
              "component": {
                "type": "application",
                "name": "branch_hardening",
                "version": "$(cat VERSION || echo '1.0.0')"
              }
            },
            "components": [
              {
                "type": "library",
                "name": "git-hardening-rules",
                "version": "$(cat VERSION || echo '1.0.0')",
                "description": "Git branch protection and enforcement rules"
              }
            ]
          }
          EOF

      - name: Upload SBOM to DependencyTrack
        env:
          DT_URL: ${{ secrets.DT_URL }}
          DT_API_KEY: ${{ secrets.DT_API_KEY }}
          DT_PROJECT_UUID: ${{ secrets.DT_PROJECT_UUID }}
        run: |
          SBOM_B64=$(base64 -w 0 sbom.json)
          
          curl -s -X POST "${DT_URL}/api/v1/bom" \
            -H "X-API-Key: ${DT_API_KEY}" \
            -H "Content-Type: application/json" \
            -d "{
              \"projectUuid\": \"${DT_PROJECT_UUID}\",
              \"bom\": \"${SBOM_B64}\"
            }"
          
          echo "✅ SBOM uploaded"
```

---

## 3. Structure des projets

### 3.1 Arborescence de chaque dépôt

```
saas_local/
├── app/
│   ├── .github/
│   │   └── workflows/
│   │       └── dependencytrack.yml          ← Workflow SBOM
│   ├── composer.json                        ← Dépendances PHP
│   ├── composer.lock
│   └── [code application]
│
├── modulesjs/
│   ├── .github/
│   │   └── workflows/
│   │       └── dependencytrack.yml          ← Workflow SBOM
│   ├── package.json                         ← Dépendances Node
│   ├── package-lock.json
│   └── [code modules]
│
└── branch_hardening/
    ├── .github/
    │   └── workflows/
    │       └── dependencytrack.yml          ← Workflow SBOM
    ├── VERSION                              ← Pour tracking versions
    └── [règles Git]
```

### 3.2 Configuration GitHub à ajouter

Pour chaque dépôt :

```bash
# 1. Créer les secrets
gh secret set DT_URL -b "https://dependencytrack.oo-medical.local" \
  -R OneOrthoMedical/app

gh secret set DT_API_KEY -b "$(vault kv get -field=api_key secret/dependencytrack)" \
  -R OneOrthoMedical/app

gh secret set DT_PROJECT_UUID -b "[uuid-du-projet]" \
  -R OneOrthoMedical/app

# 2. Protéger la branche main
gh api repos/OneOrthoMedical/app/branches/main/protection \
  --input - <<'EOF'
{
  "required_status_checks": {
    "strict": true,
    "contexts": ["DependencyTrack - SBOM Generation"]
  },
  "enforce_admins": true,
  "required_pull_request_reviews": {
    "dismiss_stale_reviews": true,
    "require_code_owner_reviews": true,
    "required_approving_review_count": 2
  }
}
EOF
```

---

## 4. Tableau récapitulatif des projets

| Projet | Type | Outil SBOM | Fréquence | UUID | Statut |
|--------|------|-----------|-----------|------|--------|
| **app** | PHP 8.2 | cyclonedx-composer | À chaque push | TBD | 🔧 Config |
| **modulesjs** | Node 18 | @cyclonedx/npm | À chaque push | TBD | 🔧 Config |
| **branch_hardening** | Rules/Docs | Manuel | Daily 2 AM | TBD | 🔧 Config |

---

## 5. Workflow d'intégration continue

### 5.1 Trigger points

Les workflows se déclenchent sur :

1. **Push sur branches protégées** (main, develop)
2. **Modifications des fichiers de dépendances** (composer.json, package.json)
3. **Schedule quotidienne** (2 AM UTC)
4. **Pull Requests** (optionnel — voir section 5.3)

### 5.2 Logs et monitoring

Afficher les exécutions :

```bash
# Lister les runs
gh run list -R OneOrthoMedical/app --workflow=dependencytrack.yml

# Afficher logs détaillés
gh run view -R OneOrthoMedical/app [run-id] --log

# Logs en temps réel
gh run watch -R OneOrthoMedical/app --interval=5
```

### 5.3 Intégration PR (optionnel)

Ajouter vérification SBOM sur les PRs :

```yaml
on:
  pull_request:
    paths:
      - 'composer.json'
      - 'composer.lock'

jobs:
  verify-sbom:
    runs-on: ubuntu-latest
    steps:
      # ... générer SBOM ...
      - name: Comment PR with SBOM summary
        uses: actions/github-script@v7
        with:
          script: |
            const fs = require('fs');
            const sbom = JSON.parse(fs.readFileSync('sbom.json', 'utf8'));
            
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: `📦 **Dependency Update**\n\n- Components: ${sbom.components.length}\n- [View full SBOM](artifact-url)`
            });
```

---

## 6. Versioning et tags

### 6.1 Tagging dans DependencyTrack

Ajouter des tags pour faciliter le filtering :

```bash
# Via l'API
curl -X PATCH "https://dependencytrack.oo-medical.local/api/v1/project/${UUID}" \
  -H "X-API-Key: ${API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "tags": [
      {"name": "saas_local"},
      {"name": "github"},
      {"name": "production"},
      {"name": "php-backend"}
    ]
  }'
```

### 6.2 Version tracking

Pour chaque projet, maintenir une version dans le SBOM :

```bash
# app : depuis package.json ou VERSION
# modulesjs : depuis package.json
# branch_hardening : depuis fichier VERSION

# Exemple : Version 2.3.1
git tag -a v2.3.1 -m "Release 2.3.1 — Dependency updates"
```

---

## 7. Troubleshooting

### Issue : SBOM non uploadé

```bash
# Vérifier que DT_API_KEY est correct
curl -s "https://dependencytrack.oo-medical.local/api/v1/version" \
  -H "X-API-Key: ${DT_API_KEY}"

# Vérifier que DT_PROJECT_UUID existe
curl -s "https://dependencytrack.oo-medical.local/api/v1/project/${DT_PROJECT_UUID}" \
  -H "X-API-Key: ${DT_API_KEY}"
```

### Issue : Composants non détectés

```bash
# Vérifier que l'SBOM est valide JSON
jq '.' sbom.json

# Vérifier le format CycloneDX
jq '.bomFormat' sbom.json
# Doit retourner: "CycloneDX"

# Vérifier que components n'est pas vide
jq '.components | length' sbom.json
# Doit retourner un nombre > 0
```

### Issue : Workflow GitHub Actions échoue

```bash
# Afficher les erreurs
gh run view [run-id] -R OneOrthoMedical/app --log

# Relancer un workflow
gh run rerun [run-id] -R OneOrthoMedical/app
```

---

## 8. Checklist d'intégration

- [ ] Projets créés dans DependencyTrack via init script
- [ ] UUIDs stockés en secrets GitHub pour chaque dépôt
- [ ] DT_URL et DT_API_KEY configurés en GitHub secrets (organization level)
- [ ] Workflows SBOM committés et poussés sur chaque dépôt
- [ ] Premier run manuel déclenché (`gh workflow run dependencytrack.yml`)
- [ ] SBOM reçu et traité dans DependencyTrack
- [ ] Webhooks Slack actifs et testés
- [ ] Tags appliqués aux projets (saas_local, github, production)
- [ ] Branches main/develop protégées (require status check)
- [ ] Documentation mise à jour dans CODEOWNERS
- [ ] Tests de failover et rollback documentés

---

## 9. Références

- [CycloneDX Spec 1.4](https://cyclonedx.org/docs/1.4/)
- [CycloneDX Composer Plugin](https://github.com/CycloneDX/cyclonedx-composer-plugin)
- [CycloneDX npm](https://github.com/CycloneDX/cyclonedx-npm)
- [DependencyTrack API Docs](https://docs.dependencytrack.org/api/)
- [GitHub Actions Secrets](https://docs.github.com/en/actions/security-guides/using-secrets-in-github-actions)
