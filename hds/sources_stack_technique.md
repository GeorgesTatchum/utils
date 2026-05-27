# Section 3.3 — Sources stack technique OneSoftware

Document complétant le §3.3 du plan de revue mensuelle.

Stack identifié à partir du code source :

**Couche portail Symfony (`saas_local/app/`) :**
- `composer.json` — Symfony 5.4 / PHP 8.1+ / Doctrine / MongoDB ODM / TCPDF / FPDI
- `package.json` — Webpack Encore / jQuery / Bootstrap 4.6 / chart.js / tinymce 8 / axios / datatables.net
- `docker/php-alpine/Dockerfile` — PHP-FPM alpine 3.21, Nginx alpine 3.23, Node 23 alpine 3.21, Composer 2
- `Jenkinsfile` — Jenkins agent Windows, intégrations Xray / LambdaTest / JIRA / Slack
- `sonar-project.properties` — SonarQube `quality.3d4you.org`
- `docker/trivy.yaml` — Trivy (image + secret + misconfig + license)
- `ansible/` — Ansible deploy

**Couche modules 3D (`saas_local/modulesjs/`) — 4 planificateurs Angular :**
- `plannerHip3D` — Angular 20.3, Three.js 0.181, three-csg-ts 3.2, mathjs 15, nifti-reader-js 0.8, rxjs 7.8, zone.js 0.15, Firebase 12, Cypress 15, Karma + Jasmine
- `plannerKneeMadison` — Angular 20.3, Three.js 0.179, three-csg-ts 3.2, mathjs 14, ngx-color-picker, angular-shepherd, Cypress 15
- `plannerHip2D` — Angular 20.3, Three.js **0.150** (ancienne), zone.js 0.15, @picoware/*
- `plannerShoulder3D` — Angular **21.2** (divergent), Three.js 0.182, three-bvh-csg 0.0.18, Firebase 12, Vitest 4, Tailwind CSS 4

Variantes de build distributeurs (impact périmètre veille) : `ds` (DePuy Synthes), `oo` (OneOrtho), `serf`, `lepine`, `evolutis`, `fh` — scripts `build:prod:*:MDR` confirment couverture MDR.

Modules métier côté Symfony :
- `Module2DHip`, `Module3DHip`, `Module3DKnee` (dans `saas_local/app/modules/`)
- Bundles internes : `one-user-bundle`, `one-inference-bundle`, `one-intervention-feed`, `one-knee-workflow-bundle`, `one-common-intervention-bundle`, `nanodicom` (fork OneOrtho)

## 3.3.1 Sources backend PHP / Symfony

| Composant | Source | URL | Type | Vérification |
|-----------|--------|-----|------|--------------|
| PHP 8.1+ | PHP Security Releases | https://www.php.net/ChangeLog-8.php | RSS / Web | Continue |
| PHP 8.1+ | GitHub Advisories `php/php-src` | https://github.com/php/php-src/security/advisories | API | Continue |
| Symfony 5.4 LTS | Symfony Security Advisories | https://symfony.com/blog/category/security-advisories | RSS | Continue |
| Symfony 5.4 LTS | `symfony/security-advisories` package | https://github.com/Roave/SecurityAdvisories | Composer audit | À chaque build |
| Doctrine ORM / MongoDB ODM | GitHub Advisories `doctrine/*` | https://github.com/doctrine/orm/security/advisories | API | Mensuelle |
| Twig | GitHub Advisories `twigphp/Twig` | https://github.com/twigphp/Twig/security/advisories | API | Mensuelle |
| TCPDF / FPDI | CVE search "tcpdf" / "fpdi" | https://nvd.nist.gov/vuln/search | Web | Mensuelle |
| PHPSpreadsheet | GitHub Advisories `PHPOffice/PhpSpreadsheet` | https://github.com/PHPOffice/PhpSpreadsheet/security/advisories | API | Mensuelle |
| PHP Composer global | `composer audit` (intégré CI Jenkins) | — | CLI | À chaque build |
| Bundles OneOrtho internes | Repos GitHub `oneorthomedical/*` | https://github.com/oneorthomedical | GH Security | Continue |

## 3.3.2 Sources frontend portail Symfony (couche `app/`)

| Composant | Source | URL | Type | Vérification |
|-----------|--------|-----|------|--------------|
| Node.js 23 (build only) | Node.js Security | https://nodejs.org/en/blog/vulnerability | RSS | Mensuelle |
| jQuery 3.5 / jQuery-UI | GitHub Advisories `jquery/jquery` | https://github.com/jquery/jquery/security/advisories | API | Trimestrielle |
| Bootstrap 4.6 | GitHub Advisories `twbs/bootstrap` | https://github.com/twbs/bootstrap/security/advisories | API | Trimestrielle |
| Axios | GitHub Advisories `axios/axios` | https://github.com/axios/axios/security/advisories | API | Mensuelle |
| TinyMCE 8 | TinyMCE Release Notes Security | https://www.tiny.cloud/docs/tinymce/latest/release-notes/ | Web | Mensuelle |
| Chart.js | GitHub Advisories `chartjs/Chart.js` | https://github.com/chartjs/Chart.js/security/advisories | API | Mensuelle |
| DataTables | DataTables CVE search | https://nvd.nist.gov/vuln/search?query=datatables | Web | Trimestrielle |
| Webpack Encore | GitHub Advisories `symfony/webpack-encore` | https://github.com/symfony/webpack-encore/security/advisories | API | Mensuelle |
| Toutes deps npm | `npm audit` / `yarn audit` (CI) | — | CLI | À chaque build |
| Toutes deps npm | OSV.dev | https://osv.dev | API | Continue (cron) |

## 3.3.2bis Sources frontend modules 3D Angular (couche `modulesjs/`)

| Composant | Source | URL | Type | Vérification |
|-----------|--------|-----|------|--------------|
| Angular 20.x / 21.x (core + CDK + Material + router) | Angular Security Advisories | https://github.com/angular/angular/security/advisories | API | Continue |
| Angular | Blog Angular | https://blog.angular.dev | RSS | Mensuelle |
| Three.js 0.150 → 0.182 | GitHub Advisories `mrdoob/three.js` | https://github.com/mrdoob/three.js/security/advisories | API | Mensuelle |
| Three.js | Three.js release notes (breaking + fixes) | https://github.com/mrdoob/three.js/releases | RSS | Mensuelle |
| three-csg-ts / three-bvh-csg | Repos GitHub upstream | https://github.com/gkjohnson/three-bvh-csg | Releases | Trimestrielle |
| RxJS 7.8 | GitHub Advisories `ReactiveX/rxjs` | https://github.com/ReactiveX/rxjs/security/advisories | API | Trimestrielle |
| zone.js 0.15 | GitHub Advisories `angular/angular` (mono) | https://github.com/angular/angular/security/advisories | API | Trimestrielle |
| Bootstrap 5.3 | GitHub Advisories `twbs/bootstrap` | https://github.com/twbs/bootstrap/security/advisories | API | Mensuelle |
| Tailwind CSS 4 | GitHub Advisories `tailwindlabs/tailwindcss` | https://github.com/tailwindlabs/tailwindcss/security/advisories | API | Trimestrielle |
| Firebase SDK 12 / firebase-tools | Firebase Release Notes Security | https://firebase.google.com/support/release-notes | Web | Mensuelle |
| Firebase Hosting | Firebase Security Bulletins | https://firebase.google.com/support/release-notes/security | Web | Continue |
| mathjs | GitHub Advisories `josdejong/mathjs` | https://github.com/josdejong/mathjs/security/advisories | API | Mensuelle |
| html2canvas / file-saver | GitHub Advisories des repos | https://github.com/niklasvh/html2canvas/security/advisories | API | Trimestrielle |
| ngx-* (color-picker, drop-file, shepherd) | GitHub Advisories par repo | — | API | Trimestrielle |
| @picoware/* | Repo GitHub (à vérifier maintenance) | https://github.com/picoware | Releases | Trimestrielle |
| camera-controls | GitHub Advisories `yomotsu/camera-controls` | https://github.com/yomotsu/camera-controls/security/advisories | API | Trimestrielle |
| Cypress 15 (test) | Cypress Security Advisories | https://github.com/cypress-io/cypress/security/advisories | API | Trimestrielle |
| Vitest 4 (test) | GitHub Advisories `vitest-dev/vitest` | https://github.com/vitest-dev/vitest/security/advisories | API | Trimestrielle |
| Karma + Jasmine | GitHub Advisories | — | API | Annuelle |
| TypeScript 5.x | GitHub Advisories `microsoft/TypeScript` | https://github.com/microsoft/TypeScript/security/advisories | API | Trimestrielle |
| Vite plugin Angular (`@analogjs/vite-plugin-angular`) | GitHub Advisories `analogjs/analog` | https://github.com/analogjs/analog/security/advisories | API | Trimestrielle |
| Toutes deps npm modules | `npm audit` + OSV-Scanner | — | CLI / API | À chaque build |

## 3.3.3 Sources imagerie médicale (DICOM + NIfTI + WebGL)

| Composant | Source | URL | Type | Vérification |
|-----------|--------|-----|------|--------------|
| Standard DICOM | NEMA DICOM Standard Newsroom | https://www.dicomstandard.org/news | RSS | Mensuelle |
| nanodicom (fork OneOrtho — backend) | Repo GitHub privé | https://github.com/oneorthomedical/nanodicom | Audit interne | Mensuelle |
| Implémentations DICOM tierces | CISA ICS Medical "DICOM" filter | https://www.cisa.gov/news-events/cybersecurity-advisories?f%5B0%5D=advisory_type%3A95 | RSS | Mensuelle |
| NIfTI / nifti-reader-js (front modules 3D) | GitHub `rii-mango/NIFTI-Reader-JS` releases + CVE | https://github.com/rii-mango/NIFTI-Reader-JS | Releases | Trimestrielle |
| Format NIfTI (spec) | NITRC / NIfTI-1 spec | https://nifti.nimh.nih.gov | Web | Annuelle |
| Imagerie volumétrique WebGL / WebXR | GitHub Advisories `KhronosGroup/WebGL` + types/webxr | https://github.com/KhronosGroup/WebGL | Web | Annuelle |
| Imagerie volumétrique WebGL | OWASP WebGL Security Cheat Sheet | https://cheatsheetseries.owasp.org/ | Web | Annuelle |

## 3.3.4 Sources infrastructure / conteneurs / hébergement

| Composant | Source | URL | Type | Vérification |
|-----------|--------|-----|------|--------------|
| Firebase Hosting (modules) | Google Cloud Status / Security Bulletins | https://status.firebase.google.com + https://cloud.google.com/support/bulletins | RSS | Continue |
| Google Cloud Platform | GCP Security Bulletins | https://cloud.google.com/support/bulletins | RSS | Mensuelle |
| Docker images base (alpine, php, nginx, node) | Docker Scout | https://hub.docker.com/ (Scout par image) | API | À chaque build |
| Alpine Linux 3.21 / 3.23 | Alpine secdb | https://security.alpinelinux.org/ | JSON | Mensuelle |
| Nginx | Nginx Security Advisories | https://nginx.org/en/security_advisories.html | Web | Mensuelle |
| Windows Server (prod) | MSRC Security Update Guide | https://msrc.microsoft.com/update-guide/ | RSS / API | Mensuelle (Patch Tuesday) |
| MariaDB | MariaDB Security Releases | https://mariadb.org/about/security/ | RSS | Mensuelle |
| MongoDB | MongoDB Security Alerts | https://www.mongodb.com/alerts | RSS | Mensuelle |
| Composer | Composer Security Advisories | https://packagist.org/security-advisories | API | À chaque build |
| Jenkins | Jenkins Security Advisories | https://www.jenkins.io/security/advisories/ | RSS | Mensuelle |
| SonarQube | SonarSource Security Advisories | https://www.sonarsource.com/security/ | Web | Mensuelle |
| Trivy (DB) | aquasecurity/trivy-db release notes | https://github.com/aquasecurity/trivy/releases | API | Continue (auto) |

## 3.3.5 Sources réglementaires complémentaires (couverture UE + US)

| Source | Périmètre | URL | Type | Vérification |
|--------|-----------|-----|------|--------------|
| FDA Cybersecurity Alerts | US — dispositifs médicaux | https://www.fda.gov/medical-devices/digital-health-center-excellence/cybersecurity | RSS | Mensuelle |
| HHS HC3 (Health Sector Cybersecurity Coordination Center) | US — secteur santé | https://www.hhs.gov/about/agencies/asa/ocio/hc3 | Mail / Web | Mensuelle |
| MITRE CVE / CWE | Mondial | https://cve.mitre.org | API | Continue |
| OWASP Top 10 / ASVS update | Mondial | https://owasp.org | Web | Annuelle |
| ENISA Threat Landscape Health | UE | https://www.enisa.europa.eu/topics/cybersecurity-threats | Web | Annuelle |
| CERT-EU | UE institutions | https://cert.europa.eu/publications/security-advisories | RSS | Mensuelle |
| ANSM Cybersécurité DM | FR | https://ansm.sante.fr | Web | Mensuelle |

## 3.3.6 Sources internes (sorties outillage) — à ajouter en §3.4

| Source | Périmètre | Producteur | Cadence |
|--------|-----------|------------|---------|
| Trivy scans image | Toutes images Docker buildées | Jenkins pipeline | À chaque build |
| `composer audit` | Dépendances PHP | Jenkins pipeline | À chaque build |
| `npm audit` / `yarn audit` | Dépendances JS | Jenkins pipeline | À chaque build |
| SonarQube `quality.3d4you.org` | Code source app | Jenkins post-merge | À chaque PR |
| GitHub Dependabot | Tous repos `oneorthomedical/*` | GitHub | Continue |
| GitHub Secret Scanning | Tous repos `oneorthomedical/*` | GitHub | Continue |
| SBOM CycloneDX (à mettre en place) | Image conteneur produit | Trivy `--format cyclonedx` | À chaque release |

## 3.3.7 Synthèse — outillage à mettre en place pour automatiser §3.3

Priorité d'implémentation (recommandation) :

1. **SBOM CycloneDX au build** — exigé par FDA Cybersecurity Guidance 2023 et attendu par MDCG 2019-16. Modifier `docker/trivy.yaml` pour ajouter sortie `cyclonedx`. Effort : ~0.5 j.
2. **Dependabot activé sur tous les repos `oneorthomedical/*`** — alimente §3.3.1 et §3.3.2 sans effort manuel. Effort : ~1 j.
3. **Agrégateur RSS centralisé** (FreshRSS auto-hébergé ou équivalent) — concentre tous les flux RSS listés ci-dessus dans un seul tableau. Effort : ~1 j.
4. **OSV-Scanner en CI** — couvre Composer + npm + alpine simultanément, donne sortie SARIF exploitable par GitHub Code Scanning. Effort : ~0.5 j.
5. **Cron mensuel d'export NVD / CISA KEV filtré sur le SBOM** — script qui croise SBOM × KEV et publie diff dans Jira. Effort : ~2 j (dépend SBOM en place).

## 3.3.8 Points à clarifier avant gel du §3.3

- Quelle URL pour SonarQube exposée en interne ? (`quality.3d4you.org` est dans le repo — confirmer disponibilité et qui a accès)
- Existe-t-il un compte H-ISAC actif ? (mentionné §3.2 du plan, "si accès")
- **Convergence Angular** : plannerShoulder3D est en Angular 21.2, les 3 autres en 20.3. Quel module fait foi de la cible ? Un item récurrent doit suivre la convergence.
- **Convergence Three.js** : versions 0.150 (Hip2D), 0.179 (Knee), 0.181 (Hip3D), 0.182 (Shoulder). L'écart 0.150 → 0.182 couvre ~30 versions mineures et plusieurs CVE (à vérifier en NVD).
- **Convergence Bootstrap** : 4.6 côté portail Symfony, 5.3 côté modules — divergence majeure de surface CSS/JS.
- **@picoware/picoserial** et **@picoware/state** (Hip2D) — éditeur peu connu, vérifier vivacité du repo et statut de maintenance.
- **Cypress vs Vitest** : Shoulder3D utilise Vitest 4 alors que les autres utilisent Cypress 15 + Karma. La couverture sécurité des outils de test diffère.
