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

## 1. Configuration DependencyTrack

### ✅ Projets créés automatiquement

Grâce au paramètre `autoCreate=true` dans les workflows, les projets sont **créés automatiquement** au premier upload du SBOM. Pas besoin de les créer manuellement ni de gérer les UUIDs!

**Noms des projets créés automatiquement:**
- `one-plateform` (app) — sera créé avec versions (develop, master, preprod)
- `modulesjs` — sera créé avec versions
- `branch_hardening` — sera créé avec versions

---

## 1.1 Secrets GitHub requis

**Accéder à DependencyTrack et créer manuellement :**

1. Se connecter à https://dependencytrack.3d4you.org
   - Login: `admin`
   - Password: (changé lors du premier accès)

2. Aller à **Administration → Projects**

3. Cliquer sur **Create Project**

4. Remplir les champs pour chaque projet:

#### Projet 1: `app`

```
Name:        app
Description: OO Medical SaaS Platform — Application backend
Version:     1.0.0
Active:      ✅ (coché)
Tags:        saas_local, github, production
```

Cliquer **Create**

#### Projet 2: `modulesjs`

```
Name:        modulesjs
Description: OO Medical SaaS Platform — JavaScript modules library
Version:     1.0.0
Active:      ✅ (coché)
Tags:        saas_local, github, production
```

Cliquer **Create**

#### Projet 3: `branch_hardening`

```
Name:        branch_hardening
Description: OO Medical SaaS Platform — Security hardening rules
Version:     1.0.0
Active:      ✅ (coché)
Tags:        saas_local, github, production
```

Cliquer **Create**

**Récupérer les UUIDs:**

Pour chaque projet créé :

1. Cliquer sur le projet
2. Voir l'UUID dans l'URL ou dans le panneau d'infos
3. Copier l'UUID (format: `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`)
4. Stocker dans un fichier local:

```bash
# Exemple: /tmp/dt-projects.env
app_UUID=12345678-1234-1234-1234-123456789012
modulesjs_UUID=87654321-4321-4321-4321-210987654321
branch_hardening_UUID=abcdefgh-ijkl-mnop-qrst-uvwxyzabcdef
```

### 1.2 Vérifier la création des projets

Les projets sont créés automatiquement au premier upload du SBOM. Vérifier qu'ils apparaissent:

```bash
# Vérifier les projets dans DependencyTrack
curl -s "https://dependencytrack.3d4you.org/api/v1/projects" \
  -H "X-Api-Key: ${DT_API_KEY}" | jq '.[] | {name, version, uuid}'

# Doit afficher:
# {
#   "name": "one-plateform",
#   "version": "master",
#   "uuid": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
# }
# {
#   "name": "modulesjs",
#   "version": "main",
#   "uuid": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
# }
# etc.
```

**Chaque fois qu'on push une nouvelle version, une nouvelle version du projet est créée:**
- Master branch → `isLatest=true`
- Develop/preprod → `isLatest=false`
- Manual trigger → version = commit SHA (12 chars)

Seuls **2 secrets** sont nécessaires pour chaque repo:

```bash
# Pour chaque projet (app, modulesjs, branch_hardening)

# Secret 1: URL de DependencyTrack
gh secret set DT_URL -b "https://dependencytrack.3d4you.org" -R OneOrthoMedical/app

# Secret 2: Clé API de DependencyTrack (récupérer depuis DependencyTrack UI ou Vault)
gh secret set DT_API_KEY -b "odt_..." -R OneOrthoMedical/app

# Répéter pour modulesjs et branch_hardening
gh secret set DT_URL -b "https://dependencytrack.3d4you.org" -R OneOrthoMedical/modulesjs
gh secret set DT_API_KEY -b "odt_..." -R OneOrthoMedical/modulesjs

gh secret set DT_URL -b "https://dependencytrack.3d4you.org" -R OneOrthoMedical/branch_hardening
gh secret set DT_API_KEY -b "odt_..." -R OneOrthoMedical/branch_hardening
```

**Avantages:**
- ✅ Pas besoin de créer les projets avant (auto-création)
- ✅ Pas besoin de gérer les UUIDs des projets
- ✅ Nombre de secrets réduit (2 au lieu de 3)

---

## 2. Génération SBOM avec Syft

**Approche unifiée:** Utiliser [Syft](https://github.com/anchore/syft) pour générer les SBOMs indépendamment de la stack technique (PHP Symfony, Node Angular, Dockerfiles, etc.).

### Dépendances multi-stack (comme Snyk)

Les workflows installent **toutes les dépendances** du projet avant de scanner avec Syft:

| Stack | Installation | Détection | Exemple |
|-------|---|---|---|
| **PHP (Composer)** | `Setup PHP + composer install` | ✅ composer.lock | Symfony, Laravel |
| **Node (npm)** | `Setup Node.js + npm ci` | ✅ package-lock.json | Angular, Vue, React |
| **Dockerfiles** | Aucune (scan statique) | ✅ Dépendances de base | Alpine, Debian, Ubuntu |

Résultat: Syft détecte **toutes les dépendances** exactement comme Snyk (Composer + npm + OS packages).

### Versioning intelligent

```bash
if [ "${GITHUB_EVENT_NAME}" = "workflow_dispatch" ]; then
  PROJECT_VERSION="${GITHUB_SHA:0:12}"        # Manual: version = commit SHA (12 chars)
  IS_LATEST="false"
else
  PROJECT_VERSION="${GITHUB_REF_NAME}"        # Auto: version = branch name (master/develop/preprod)
  [ "${GITHUB_REF_NAME}" = "master" ] && IS_LATEST="true" || IS_LATEST="false"
fi
```

**Résultat dans DependencyTrack:**
- Branch `master` → version `master` avec `isLatest=true` (version principale)
- Branch `develop` → version `develop` avec `isLatest=false`
- Branch `preprod` → version `preprod` avec `isLatest=false`
- Manual trigger → version `abc123def456` avec `isLatest=false` (commit SHA)

### Méthode d'upload: multipart/form-data avec auto-création

```bash
curl -X POST "${DT_URL}/api/v1/bom" \
  -H "X-Api-Key: ${DT_API_KEY}" \
  -F "autoCreate=true" \
  -F "projectName=one-plateform" \
  -F "projectVersion=${VERSION}" \
  -F "isLatest=${IS_LATEST}" \
  -F "bom=@sbom.json"
```

**Avantages:**
- ✅ Les projets sont créés automatiquement par `autoCreate=true`
- ✅ Versioning intelligent (branch name ou commit SHA)
- ✅ Marque la version `master` comme `isLatest=true`
- ✅ Interface mise à jour immédiatement après l'upload

Syft avantages:
- ✅ Détecte automatiquement toutes les dépendances (Composer, npm, pip, etc.)
- ✅ Format CycloneDX standardisé et compatible DependencyTrack
- ✅ Même workflow pour tous les projets
- ✅ Plus robuste que les outils spécifiques au langage

---

### 2.1 App (Symfony + PHP + Node)

**File: `app/.github/workflows/dependencytrack.yml`**

```yaml
name: DependencyTrack - SBOM Generation

on:
  # Lancement manuel
  workflow_dispatch: ~

  # Push sur branches protégées
  push:
    branches:
      - master
      - develop
      - preprod
    paths:
      - 'composer.json'
      - 'composer.lock'
      - 'package.json'
      - 'package-lock.json'
      - 'src/**'
      - 'docker/**'

  # Pull Request vers branches protégées
  pull_request:
    branches:
      - master
      - develop
      - preprod
    paths:
      - 'composer.json'
      - 'composer.lock'
      - 'package.json'
      - 'package-lock.json'
      - 'src/**'
      - 'docker/**'

  # Scan quotidien (2 AM UTC)
  schedule:
    - cron: '0 2 * * *'

jobs:
  generate-sbom:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '18'
          cache: 'npm'

      - name: Install Node dependencies
        run: npm ci --legacy-peer-deps || npm ci

      - name: Setup PHP
        uses: shivammathur/setup-php@v2
        with:
          php-version: '8.2'
          tools: composer:latest

      - name: Install PHP dependencies
        run: composer install --no-interaction --prefer-dist

      - name: Install Syft
        run: |
          curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sh -s -- -b /usr/local/bin
          syft --version

      - name: Generate SBOM with Syft (CycloneDX JSON format)
        run: |
          syft . \
            --config .syft.yaml \
            --output cyclonedx-json \
            --file sbom.json

          [ -s sbom.json ] && echo "✅ SBOM généré ($(wc -c < sbom.json) bytes, $(jq '.components | length' sbom.json) composants)"

      - name: Validate SBOM
        run: |
          jq '.' sbom.json > /dev/null && echo "✅ JSON valide"
          
          COMPONENTS=$(jq '.components | length' sbom.json)
          echo "📦 Composants détectés: ${COMPONENTS}"

      - name: Upload SBOM as workflow artifact
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: sbom
          path: sbom.json
          retention-days: 30

      - name: Upload SBOM to DependencyTrack
        env:
          DT_URL: ${{ secrets.DT_URL }}
          DT_API_KEY: ${{ secrets.DT_API_KEY }}
          DT_PROJECT_NAME: one-plateform
        run: |
          if [ "${GITHUB_EVENT_NAME}" = "workflow_dispatch" ]; then
            PROJECT_VERSION="${GITHUB_SHA:0:12}"
            IS_LATEST="false"
          else
            PROJECT_VERSION="${GITHUB_REF_NAME}"
            [ "${GITHUB_REF_NAME}" = "master" ] && IS_LATEST="true" || IS_LATEST="false"
          fi

          HTTP_CODE=$(curl -sS -w "%{http_code}" -o response.json \
            -X POST "${DT_URL}/api/v1/bom" \
            -H "X-Api-Key: ${DT_API_KEY}" \
            -F "autoCreate=true" \
            -F "projectName=${DT_PROJECT_NAME}" \
            -F "projectVersion=${PROJECT_VERSION}" \
            -F "isLatest=${IS_LATEST}" \
            -F "bom=@sbom.json")

          echo "✅ Upload BOM (version=${PROJECT_VERSION}, latest=${IS_LATEST}): HTTP ${HTTP_CODE}"
          cat response.json; echo
          [ "${HTTP_CODE}" = "200" ] || { echo "❌ Échec upload"; exit 1; }
```

### 2.2 Modulesjs (Angular/Node)

**File: `modulesjs/.github/workflows/dependencytrack.yml`**

```yaml
name: DependencyTrack - SBOM Generation

on:
  # Lancement manuel
  workflow_dispatch:

  # Push sur branches protégées
  push:
    branches:
      - main
      - develop
      - preprod
    paths:
      - 'package.json'
      - 'package-lock.json'
      - 'src/**'

  # Pull Request vers branches protégées
  pull_request:
    branches:
      - main
      - develop
      - preprod
    paths:
      - 'package.json'
      - 'package-lock.json'
      - 'src/**'

  # Scan quotidien (2 AM UTC)
  schedule:
    - cron: '0 2 * * *'

jobs:
  generate-sbom:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Setup Node.js (for dependency resolution)
        uses: actions/setup-node@v3
        with:
          node-version: '18'
          cache: 'npm'

      - name: Install dependencies
        run: npm ci --legacy-peer-deps || npm ci

      - name: Install Syft
        run: |
          curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sh -s -- -b /usr/local/bin
          syft --version

      - name: Generate SBOM with Syft (CycloneDX JSON format)
        run: |
          syft . \
            --config .syft.yaml \
            --output cyclonedx-json \
            --file sbom.json
          
          [ -s sbom.json ] && echo "✅ SBOM généré ($(wc -c < sbom.json) bytes)"

      - name: Validate SBOM
        run: |
          jq '.' sbom.json > /dev/null && echo "✅ JSON valide"
          
          COMPONENTS=$(jq '.components | length' sbom.json)
          echo "📦 Composants détectés: ${COMPONENTS}"

      - name: Upload SBOM as workflow artifact
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: sbom
          path: sbom.json
          retention-days: 30

      - name: Upload SBOM to DependencyTrack
        if: github.event_name == 'push'
        env:
          DT_URL: ${{ secrets.DT_URL }}
          DT_API_KEY: ${{ secrets.DT_API_KEY }}
        run: |
          curl -s -X POST "${DT_URL}/api/v1/bom" \
            -H "X-Api-Key: ${DT_API_KEY}" \
            -F "autoCreate=true" \
            -F "projectName=modulesjs" \
            -F "projectVersion=$(git describe --tags --always 2>/dev/null || echo '1.0.0')" \
            -F "bom=@sbom.json"
          
          echo "✅ SBOM uploadé vers DependencyTrack"
```

### 2.3 Branch Hardening (Règles + Documentation)

**File: `branch_hardening/.github/workflows/dependencytrack.yml`**

```yaml
name: DependencyTrack - SBOM Generation

on:
  # Lancement manuel
  workflow_dispatch:

  # Push sur branches protégées
  push:
    branches:
      - main
      - develop
      - preprod

  # Pull Request vers branches protégées
  pull_request:
    branches:
      - main
      - develop
      - preprod

  # Scan quotidien (2 AM UTC)
  schedule:
    - cron: '0 2 * * *'

jobs:
  generate-sbom:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Install Syft
        run: |
          curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sh -s -- -b /usr/local/bin
          syft --version

      - name: Generate SBOM with Syft (CycloneDX JSON format)
        run: |
          syft . \
            --config .syft.yaml \
            --output cyclonedx-json \
            --file sbom.json
          
          [ -s sbom.json ] && echo "✅ SBOM généré ($(wc -c < sbom.json) bytes)"

      - name: Enhance SBOM metadata
        run: |
          VERSION=$(cat VERSION 2>/dev/null || git describe --tags --always 2>/dev/null || echo "1.0.0")
          
          jq --arg version "$VERSION" '.metadata.component.version = $version' sbom.json > sbom.tmp && mv sbom.tmp sbom.json
          jq '.metadata.component.name = "branch_hardening" | .metadata.component.description = "Git branch protection and security hardening rules"' sbom.json > sbom.tmp && mv sbom.tmp sbom.json
          
          echo "✅ Métadonnées enrichies"

      - name: Validate SBOM
        run: |
          jq '.' sbom.json > /dev/null && echo "✅ JSON valide"
          
          COMPONENTS=$(jq '.components | length' sbom.json)
          echo "📦 Composants détectés: ${COMPONENTS}"

      - name: Upload SBOM as workflow artifact
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: sbom
          path: sbom.json
          retention-days: 30

      - name: Upload SBOM to DependencyTrack
        if: github.event_name == 'push'
        env:
          DT_URL: ${{ secrets.DT_URL }}
          DT_API_KEY: ${{ secrets.DT_API_KEY }}
        run: |
          curl -s -X POST "${DT_URL}/api/v1/bom" \
            -H "X-Api-Key: ${DT_API_KEY}" \
            -F "autoCreate=true" \
            -F "projectName=branch_hardening" \
            -F "projectVersion=$(cat VERSION 2>/dev/null || git describe --tags --always 2>/dev/null || echo '1.0.0')" \
            -F "bom=@sbom.json"
          
          echo "✅ SBOM uploadé vers DependencyTrack"
```

---

## 2.4 Configuration Syft par projet (`.syft.yaml`)

Créer un fichier `.syft.yaml` **à la racine de chaque repo** pour personnaliser le scan Syft.

### App (Symfony + PHP)

**File: `app/.syft.yaml`**

```yaml
log:
  level: "warn"
  quiet: false

format:
  json:
    pretty: true
  
  cyclonedx-json:
    pretty: true

# Scan le répertoire source complet
source:
  base-path: "."

# Configuration PHP/Composer
package:
  search-indexed-archives: true
  exclude-binary-overlap-by-ownership: true

# Inclure les fichiers possédés par les packages
relationships:
  package-file-ownership: true
  package-file-ownership-overlap: true

# Respect des licences
license:
  content: "none"
  coverage: 75

# Exclusions
exclude:
  - "node_modules/**"
  - ".git/**"
  - "tests/**"
  - "var/**"
```

### Modulesjs (Angular + Node)

**File: `modulesjs/.syft.yaml`**

```yaml
log:
  level: "warn"
  quiet: false

format:
  json:
    pretty: true
  
  cyclonedx-json:
    pretty: true

source:
  base-path: "."

package:
  search-indexed-archives: true
  exclude-binary-overlap-by-ownership: true

# Inclure les dépendances développement pour Angular
javascript:
  search-remote-licenses: false
  npm-base-url: "https://registry.npmjs.org"
  include-dev-dependencies: true

relationships:
  package-file-ownership: true
  package-file-ownership-overlap: true

license:
  content: "none"
  coverage: 75

exclude:
  - ".git/**"
  - "dist/**"
  - "coverage/**"
  - ".angular/**"
```

### Branch Hardening (Règles + Docs)

**File: `branch_hardening/.syft.yaml`**

```yaml
log:
  level: "warn"
  quiet: false

format:
  json:
    pretty: true
  
  cyclonedx-json:
    pretty: true

source:
  base-path: "."
  name: "branch_hardening"
  supplier: "OneOrtho Medical"

package:
  search-indexed-archives: true
  exclude-binary-overlap-by-ownership: true

relationships:
  package-file-ownership: false

license:
  content: "none"

exclude:
  - ".git/**"
  - ".github/**"
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
│   ├── .syft.yaml                           ← Config Syft (racine du repo)
│   ├── composer.json                        ← Dépendances PHP
│   ├── composer.lock
│   └── [code application]
│
├── modulesjs/
│   ├── .github/
│   │   └── workflows/
│   │       └── dependencytrack.yml          ← Workflow SBOM
│   ├── .syft.yaml                           ← Config Syft (racine du repo)
│   ├── package.json                         ← Dépendances Node
│   ├── package-lock.json
│   └── [code modules Angular]
│
└── branch_hardening/
    ├── .github/
    │   └── workflows/
    │       └── dependencytrack.yml          ← Workflow SBOM
    ├── .syft.yaml                           ← Config Syft (racine du repo)
    ├── VERSION                              ← Pour tracking versions
    └── [règles Git + docs]
```

### 3.2 Configuration GitHub à ajouter

Pour chaque dépôt :

```bash
# 1. Créer les secrets
gh secret set DT_URL -b "https://dependencytrack.3d4you.org" \
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

### 5.2 Lancer les workflows manuellement

**Via GitHub UI:**

1. Aller sur le repo (e.g., `OneOrthoMedical/app`)
2. **Actions** → sélectionner `DependencyTrack - SBOM Generation`
3. Cliquer **Run workflow**
4. Sélectionner la branche (main, develop, ou preprod)
5. Cliquer **Run workflow**

**Via CLI (gh):**

```bash
# Lancer le workflow pour le projet 'app' sur la branche 'main'
gh workflow run dependencytrack.yml \
  -R OneOrthoMedical/app \
  --ref main

# Lancer sur develop
gh workflow run dependencytrack.yml \
  -R OneOrthoMedical/app \
  --ref develop

# Lancer tous les workflows des 3 projets
for REPO in app modulesjs branch_hardening; do
  gh workflow run dependencytrack.yml -R OneOrthoMedical/$REPO
done
```

**Vérifier l'exécution:**

```bash
# Afficher le dernier run
gh run list -R OneOrthoMedical/app --workflow=dependencytrack.yml -L 1

# Attendre la fin et afficher les logs
gh run watch -R OneOrthoMedical/app --interval=5
```

---

### 5.3 Logs et monitoring

Afficher les exécutions :

```bash
# Lister les runs
gh run list -R OneOrthoMedical/app --workflow=dependencytrack.yml

# Afficher logs détaillés
gh run view -R OneOrthoMedical/app [run-id] --log

# Logs en temps réel
gh run watch -R OneOrthoMedical/app --interval=5
```

### 5.4 Intégration PR avancée (optionnel)

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
curl -X PATCH "https://dependencytrack.3d4you.org/api/v1/project/${UUID}" \
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

## 7. Accès aux artefacts SBOM

Les SBOM générés sont automatiquement uploadés comme artefacts GitHub Actions et conservés **30 jours**.

### Récupérer les SBOM

**Via UI GitHub:**

1. Aller sur le repo (e.g., `OneOrthoMedical/app`)
2. **Actions** → sélectionner le workflow run
3. **Artifacts** → télécharger `sbom.json`

**Via CLI:**

```bash
# Lister les artifacts d'un run
gh run view [run-id] -R OneOrthoMedical/app

# Télécharger l'artifact SBOM
gh run download [run-id] -R OneOrthoMedical/app -n sbom

# Archiver les SBOM localement
mkdir -p sbom-archive
cd sbom-archive
gh run download [run-id] -R OneOrthoMedical/app -n sbom
mv sbom/sbom.json sbom-$(date +%Y%m%d-%H%M%S).json
```

### Archivage long-terme

Pour conserver les SBOM au-delà de 30 jours:

```bash
# Script d'archivage (à exécuter régulièrement)
#!/bin/bash
PROJECTS=("app" "modulesjs" "branch_hardening")

for PROJ in "${PROJECTS[@]}"; do
  mkdir -p sbom-archive/$PROJ
  
  # Récupérer les 10 derniers runs
  gh run list -R OneOrthoMedical/$PROJ \
    --workflow=dependencytrack.yml \
    -L 10 --json databaseId \
    | jq -r '.[].databaseId' | while read RUN_ID; do
    
    gh run download $RUN_ID -R OneOrthoMedical/$PROJ -n sbom 2>/dev/null && \
    mv sbom/sbom.json sbom-archive/$PROJ/sbom-$RUN_ID.json && \
    rm -rf sbom
  done
done

# Compresser l'archive
tar czf sbom-archive-$(date +%Y%m%d).tar.gz sbom-archive/
```

---

## 8. Troubleshooting

### Test local : Upload manuel d'un SBOM

Pour tester rapidement l'upload avant de commiter le workflow:

```bash
# 1. Générer le SBOM localement
syft . \
  --config .syft.yaml \
  --output cyclonedx-json \
  --file sbom.json

# 2. Upload multipart (méthode qui fonctionne)
curl -X POST "https://dependencytrack.3d4you.org/api/v1/bom" \
  -H "X-Api-Key: ${DT_API_KEY}" \
  -F "autoCreate=true" \
  -F "projectName=test-local" \
  -F "projectVersion=1.0.0" \
  -F "bom=@sbom.json"

# 3. Vérifier dans l'interface
# https://dependencytrack.3d4you.org/projects
# Le projet 'test-local' devrait apparaître avec les composants
```

### Issue : SBOM non uploadé ou interface ne se met pas à jour

**Raison principale:** Utilisation de l'API JSON au lieu de multipart/form-data

```bash
# ❌ Ne fonctionne PAS (ancien format)
curl -X POST "${DT_URL}/api/v1/bom" \
  -H "X-Api-Key: ${DT_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{"projectUuid": "...", "bom": "base64..."}'

# ✅ Fonctionne (format utilisé par les workflows)
curl -X POST "${DT_URL}/api/v1/bom" \
  -H "X-Api-Key: ${DT_API_KEY}" \
  -F "autoCreate=true" \
  -F "projectName=app" \
  -F "projectVersion=1.0.0" \
  -F "bom=@sbom.json"
```

**Vérifier la clé API:**

```bash
curl -s "https://dependencytrack.3d4you.org/api/v1/version" \
  -H "X-Api-Key: ${DT_API_KEY}"
# Doit retourner: {"version":"4.14.2"}
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

### Issue : Upload vers DependencyTrack échoue sur les PRs

**Raison:** Les secrets GitHub ne sont pas disponibles dans les PRs par défaut (pour sécurité).

**Comportement attendu:**
- ✅ SBOM généré et uploadé en artefact (visible dans le workflow)
- ❌ SBOM NON uploadé vers DependencyTrack (secrets indisponibles)

**Solution 1: Ignorer les PRs (recommandé)**

Modifier le workflow pour uploader seulement sur push:

```yaml
- name: Upload SBOM to DependencyTrack
  if: github.event_name == 'push'
  env:
    DT_URL: ${{ secrets.DT_URL }}
    DT_API_KEY: ${{ secrets.DT_API_KEY }}
    DT_PROJECT_UUID: ${{ secrets.DT_PROJECT_UUID }}
  run: |
    curl -s -X POST "${DT_URL}/api/v1/bom" ...
```

**Solution 2: Autoriser les secrets dans les PRs**

⚠️ À utiliser avec prudence (risque de fuite de secrets)

Repo Settings → Actions → General → Workflow permissions → ✅ Allow GitHub Actions to create and approve pull requests

---

## 9. Checklist d'intégration

**Phase 1: Setup**
- [ ] `.syft.yaml` créé à la racine de chaque repo (app, modulesjs, branch_hardening)
- [ ] Workflows `.github/workflows/dependencytrack.yml` committés dans chaque repo
  - [ ] App: installe Node.js + PHP + composer + npm ci
  - [ ] Modulesjs: installe Node.js + npm ci
  - [ ] Branch_hardening: scan des règles uniquement
- [ ] Secrets GitHub configurés par repo:
  - [ ] `DT_URL` = https://dependencytrack.3d4you.org
  - [ ] `DT_API_KEY` (depuis Vault ou DependencyTrack UI)

**Phase 2: Déploiement**
- [ ] Premier run manuel déclenché (`gh workflow run dependencytrack.yml -R OneOrthoMedical/app`)
- [ ] Vérifier création automatique des projets dans DependencyTrack (Administration → Projects):
  - [ ] `one-plateform` (app, versions: master/develop/preprod)
  - [ ] `modulesjs` (versions: main/develop/preprod)
  - [ ] `branch_hardening`
- [ ] SBOM générés avec tous les composants (Composer + npm)
- [ ] Interface mise à jour avec composants détectés
- [ ] HTTP 200 confirmation sur l'upload

**Phase 3: Monitoring**
- [ ] Webhooks Slack actifs et testés (voir 02-slack-alerts-strategy.md)
- [ ] Tags appliqués aux projets (saas_local, github, production)
- [ ] Vérification: `isLatest=true` uniquement pour master
- [ ] Artefacts SBOM accessibles sur GitHub (30 jours)

---

## 10. Références

- [Syft GitHub](https://github.com/anchore/syft) — SBOM generator
- [Syft Configuration](https://github.com/anchore/syft#configuration) — .syft.yaml options
- [CycloneDX Spec 1.4](https://cyclonedx.org/docs/1.4/)
- [DependencyTrack API Docs](https://docs.dependencytrack.org/api/)
- [GitHub Actions Artifacts](https://docs.github.com/en/actions/managing-workflow-runs/downloading-workflow-artifacts)
- [GitHub Actions Secrets](https://docs.github.com/en/actions/security-guides/using-secrets-in-github-actions)
