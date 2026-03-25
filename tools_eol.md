# Spécifications Techniques - Cycle de Vie des Technologies

## 1. Objectif & Périmètre

Registre centralisé et détaillé du cycle de vie (release, LTS, EOL) de la stack ops/dev avec traçabilité exhaustive pour profils techniques.

**Environnements couverts :**
- Prod : Debian 12 (Bookworm)
- Tests/Dev : Vagrant box `debian/bookworm64` (v12.20250126.1)

---

## 2. Stack Ops - Registre détaillé

### A. Conteneurisation

#### Docker (moteur)
| Attribut | Valeur |
|----------|--------|
| **Version actuelle** | 27.x (compatible Debian 12) |
| **LTS** | ❌ Non (cycle variable 4-6 mois) |
| **Date Release (27.0)** | 2024-06-12 |
| **Date EOL (27.x)** | 2025-12-31 (~18 mois) |
| **Durée de support** | 6 mois (standard) ; 12 mois (extended) avec support payant |
| **Versions stables recommandées** | 27.x (actuelle) ; 26.x (maintenance) |
| **Cycle majeur** | Variable ~4-6 mois entre releases (non-régulier) |
| **Historique releases** | v27.0 (2024-06-12) ; v26.0 (2024-01-10, +5m) ; v25.0 (2023-10-30, +2.3m) ; v24.0 (2023-06-07, +4.7m) |
| **Channel** | Stable (par défaut) |
| **Source** | [Docker Releases](https://docs.docker.com/release-notes/docker-engine/) ; [Support lifecycle](https://docs.docker.com/release-notes/docker-engine/support-lifecycle/) ; [Vérification continu]((https://github.com/moby/moby/releases) |
| **Dépendances système** | linux-headers, containerd (inclus) |
| **Compatibilité Debian 12** | ✅ Officiel support (glibc 2.36+) |
| **Notes** | EOL dates précises par version (6 mois depuis release) ; cycle imprévisible : adapter planning migrations |

**Alternatives stables si dépréciation :**
- Docker 26.x : Release 2024-01-10 ; EOL 2025-06-30 (6 mois support standard)
- Docker 25.x : Release 2023-10-30 ; EOL ~2024-04-30 ❌ (EXPIRED)

#### Docker Compose
| Attribut | Valeur |
|----------|--------|
| **Version actuelle** | v2.29+ (compatible Docker 27.x) |
| **LTS** | ❌ Non (pas de LTS défini) |
| **Date Release (v2.0.0)** | 2022-03-29 |
| **Date Release (v2.25.0)** | 2024-03-21 |
| **Date EOL (v2.x)** | Suivi Docker Engine (~24 mois support glissant) |
| **Durée de support** | ~24 mois après release |
| **Versions stables recommandées** | v2.29+ (actuelle) ; v2.27+ (stable antérieure) |
| **Type** | V2 (réécrit en Go depuis 2022) |
| **Source** | [Docker Compose Releases](https://github.com/docker/compose/releases) |
| **Installation** | Plugin Docker : `docker compose` (intégré) |
| **Compatibilité** | Requiert Docker Engine 20.10+ |
| **Notes** | V1 entièrement déprecié ; compose spec v3.9 supportée |

**Alternatives stables si dépréciation :**
- Docker Compose v2.27.0 : Release 2024-07-15
- Docker Compose v2.25.0 : Release 2024-03-21

#### Docker Swarm
| Attribut | Valeur |
|----------|--------|
| **Version actuelle** | Intégré à Docker Engine 27.x |
| **LTS** | ❌ Non (suit Docker Engine) |
| **Date Release (v27.0)** | 2024-06-12 |
| **Date EOL (v27.x)** | 2025-12-31 (suit Docker) |
| **Durée de support** | 6 mois standard ; 12 mois extended payant |
| **Versions stables recommandées** | Docker 27.x ; Docker 26.x (si stabilité prioritaire) |
| **Type** | Orchestration lightweight (built-in Docker Engine) |
| **Statut production** | ✅ Maintenu mais << Kubernetes (uptake limité) |
| **Source** | [Docker Swarm Docs](https://docs.docker.com/engine/swarm/) ; [Roadmap GitHub](https://github.com/docker/swarmkit) |
| **Cas d'usage** | Petites flottes (< 100 nœuds), dev/staging |
| **Notes** | Pas de migration prévue ; pas de breaking changes majeures annoncées |

#### Dive (Image inspection)
| Attribut | Valeur |
|----------|--------|
| **Version actuelle** | latest (rolling releases) |
| **LTS** | ❌ Non (outil communautaire) |
| **Dernière release** | v0.12.0 (2024-08-15) |
| **Date Release (v0.12.0)** | 2024-08-15 |
| **Support / EOL** | ❌ Aucun SLA officiel (community-driven) |
| **Durée de support** | Non définie |
| **Versions stables recommandées** | v0.12.0 (latest) ; v0.11.x (antérieure stable) |
| **Source** | [wagoodman/dive GitHub](https://github.com/wagoodman/dive) ; [Releases](https://github.com/wagoodman/dive/releases) |
| **Build** | `docker run wagoodman/dive:latest <image>` |
| **Cas d'usage** | Analyse couches Docker (optimisation taille image) ; déjà fournie dans CI via action |
| **Notes** | Outil FOSS ; maintenance active ; pas de versioning SLA |

**Alternatives si abandon :**
- `docker inspect` (built-in, basique)
- `container-diff` (Google Cloud) ; `Skaffold` (si K8s)

---

### B. Orchestration & Configuration

#### Ansible-core
| Attribut | Valeur |
|----------|--------|
| **Version actuelle** | 2.18.7 |
| **LTS** | ❌ Non (maintenance-only jusqu'à EOL) |
| **Date Release (2.18.0)** | 2024-10-31 |
| **Date Release (2.18.7 patch)** | 2025-02-28 |
| **Durée de support** | 6 mois à partir release majeure |
| **Date EOL (2.18.x)** | 2025-04-30 (~6 mois maintenance-only) |
| **Versions stables recommandées** | 2.18.7 (actuelle) ; 2.17.x (stable antérieure avec support étendu) |
| **Cycle release** | Nouvelle majeure tous les 6 mois (avril/octobre) |
| **Source** | [Ansible Releases](https://docs.ansible.com/ansible/latest/reference_appendices/release_and_maintenance.html) ; [EOL dates](https://docs.ansible.com/ansible/devel/release_and_maintenance.html) |
| **Python dépendance** | Python 3.9+ (3.11+ recommandé) ; Debian 12 inclut 3.11 ✅ |
| **Dépendances critiques** | Jinja2 3.0+, PyYAML 5.3+, paramiko, passlib |
| **Notes** | Remplace `ansible` (legacy, EOL 2024) ; core optimisé performante |

**Alternatives stables si dépréciation :**
- Ansible-core 2.17.x : Release 2024-04-23 ; support jusqu'2025-10-31 (9 mois restants) ⚠️
- Ansible-core 2.16.x : Release 2023-10-23 ; EOL 2024-06-15 ❌ (EXPIRED)

**Migration path :**
- De 2.18.x → 2.19.0 (avril 2025) ; 2.20.0 (octobre 2025)

#### Ansible-lint
| Attribut | Valeur |
|----------|--------|
| **Version actuelle** | 25.6.1 |
| **LTS** | ❌ Non (suit versioning calendaire) |
| **Date Release (25.0.0)** | 2025-01-XX |
| **Date Release (25.6.1)** | 2025-02-XX |
| **Durée de support** | Suivi Ansible-core (6 mois glissants) |
| **Versions stables recommandées** | 25.6.1 (actuelle) ; 24.9.x (antérieure stable) |
| **Type** | Linter pour playbooks Ansible |
| **Dépend de** | Ansible-core 2.17+ (obligatoire) |
| **Source** | [ansible-lint GitHub Releases](https://github.com/ansible/ansible-lint/releases) |
| **Règles incluses** | 80+ règles par défaut ; extensible via config |
| **Intégration CI/CD** | GitHub Actions intégré ; pre-commit hooks |
| **Notes** | Versioning annuel (YY.N.P) depuis v6.0 ; breaking changes à chaque majeure |

**Alternatives si problème :**
- `yamllint` (syntaxe YAML seule) + `ansible-playbook --syntax-check`
- Proprietary : SonarQube Ansible plugin

#### Molecule
| Attribut | Valeur |
|----------|--------|
| **Version actuelle** | 25.6.0 |
| **LTS** | ❌ Non (même versioning que ansible-lint) |
| **Date Release (25.0.0)** | 2025-01-XX |
| **Date Release (25.6.0)** | 2025-02-XX |
| **Durée de support** | 6 mois glissants |
| **Versions stables recommandées** | 25.6.0 (actuelle) ; 24.9.x (antérieure) |
| **Type** | Test framework pour rôles Ansible |
| **Dépend de** | Ansible-core 2.17+ |
| **Drivers supportés** | Docker (principal) ; Podman ; Vagrant ; Libvirt ; EC2 |
| **Source** | [Molecule GitHub Releases](https://github.com/ansible/molecule/releases) |
| **Cycle de test** | lint → create → converge → idempotence → verify → destroy |
| **Notes** | Remplace pytest-ansible (legacy) ; Jinja2 templating complet |

#### Molecule-plugins (Podman)
| Attribut | Valeur |
|----------|--------|
| **Version actuelle** | 23.7.0 |
| **LTS** | ❌ Non (suivi independant) |
| **Date Release (23.0.0)** | 2023-XX-XX |
| **Date Release (23.7.0)** | 2024-XX-XX |
| **Durée de support** | Aucun SLA officiel (community plugin) |
| **Versions stables recommandées** | 23.7.0 (actuelle) ; 23.6.x (antérieure) |
| **Type** | Driver Podman pour Molecule |
| **Dépend de** | Molecule 25.6+ ; Podman runtime 4.0+ |
| **Avantage vs Docker** | Rootless par défaut ; OCI compliant ; pas de daemon système |
| **Source** | [ansible-community/molecule-plugins GitHub](https://github.com/ansible-community/molecule-plugins) |
| **Intégration** | `molecule.yml` : `scenario.driver.name: podman` |
| **Notes** | Plugin communautaire ; maintenance active ; Debian 12 inclut Podman ✅ |

#### Traefik
| Attribut | Valeur |
|----------|--------|
| **Version actuelle** | v3.4.1 |
| **LTS** | ❌ Non (support standard ~24 mois) |
| **Date Release (v3.4.0)** | 2025-03-12 |
| **Date Release (v3.4.1 patch)** | 2025-03-19 |
| **Durée de support** | ~24 mois à partir majeure (v3.x : juin 2023 → décembre 2025) |
| **Date EOL (v3.x)** | 2025-12-31 (~30 mois total) |
| **Versions stables recommandées** | v3.4.1 (actuelle LTS-like) ; v3.2.x (stable antérieure) |
| **Cycle release** | Nouvelle release toutes les 4 semaines |
| **Type** | Reverse proxy / Edge router cloud-native |
| **Source** | [Traefik GitHub Releases](https://github.com/traefik/traefik/releases) ; [Support policy](https://doc.traefik.io/traefik/contributing/maintainers/) |
| **Dépendances** | Go 1.22+ (compilé) ; Docker/K8s provider optionnel |
| **Fonctionnalités clés** | SSL/TLS automatique (Let's Encrypt), middleware, services virtuels, gRPC |
| **Intégration** | Docker labels ; Kubernetes CRDs ; file provider ; Consul/Etcd |
| **Notes** | v2.x legacy fin support 2024-12-31 ; v3 breaking changes significatives |

**Alternatives stables si dépréciation :**
- Traefik v3.2.x : Release 2024-10-XX ; support jusqu'2025-12-31
- Traefik v2.11.x : Release 2024-10-XX ; EOL 2024-12-31 ❌ (expiration imminente)
- Alternatives : Nginx Ingress Controller, HAProxy, Caddy

---

### C. Sécurité & Analyse

#### Trivy (Aqua Security)
| Attribut | Valeur |
|----------|--------|
| **Version actuelle** | v0.34.1 (Action GitHub) |
| **LTS** | ❌ Non (release cycle rapide) |
| **Date Release (v0.34.0)** | 2025-03-10 |
| **Date Release (v0.34.1)** | 2025-03-17 |
| **Durée de support** | Maintenance 3 versions mineures (~3-4 mois) |
| **Versions stables recommandées** | v0.34.1 (latest) ; v0.33.x (antérieure stable) |
| **Cycle release** | ~1 release toutes les 2 semaines |
| **Type** | Vulnerability scanner (images, configs, dépendances) |
| **Source** | [aquasecurity/trivy GitHub](https://github.com/aquasecurity/trivy) ; [Releases](https://github.com/aquasecurity/trivy/releases) |
| **Scanner modes** | image, filesystem, git, config, sbom, license |
| **Dépendances DB** | Base CVE téléchargée à chaque exécution (source publique NVD) |
| **Intégration CI** | GitHub Actions : `aquasecurity/trivy-action@0.34.1` |
| **Output formats** | SARIF (GitHub Security tab), JSON, table, cyclonedx, spdx |
| **Notes** | ✅ FOSS (Apache 2.0) ; supporte SBOM (Software Bill of Materials) ; MAJ DB automatique |

**Alternatives stables si dépréciation :**
- Trivy v0.33.x : Release 2025-01-XX
- Proprietary : Snyk, Grype, Dependabot

#### Hadolint
| Attribut | Valeur |
|----------|--------|
| **Version actuelle** | v3.1.0 (Action) |
| **LTS** | ❌ Non (maintenance standard) |
| **Date Release (v3.1.0)** | 2024-12-15 |
| **Date Release (v3.0.0)** | 2024-XX-XX |
| **Durée de support** | 12+ mois à partir release majeure |
| **Versions stables recommandées** | v3.1.0 (actuelle) ; v2.12.x (stable antérieure legacy) |
| **Cycle release** | ~1 release par mois |
| **Type** | Linter pour Dockerfile |
| **Source** | [hadolint/hadolint GitHub](https://github.com/hadolint/hadolint) ; [Releases](https://github.com/hadolint/hadolint/releases) |
| **Règles incluses** | 100+ best practices Docker ; DL (Docker Linting rules) |
| **Language** | Haskell (rapide, binary performant) |
| **Intégration CI** | GitHub Actions : `hadolint/hadolint-action@v3.1.0` |
| **Config** | `.hadolintrc` ou `hadolint.yaml` ; règles strictes/relaxed |
| **Notes** | Détecte anti-patterns (couches fréquentes, users, cves) ; breaking changes minimes |

**Alternatives si nécessaire :**
- `docker build --check` (built-in v1.42+, basique)
- Proprietary : SonarQube, Trustwave

#### Cosign (Sigstore)
| Attribut | Valeur |
|----------|--------|
| **Version actuelle** | v3.9.1 (Installer action) |
| **LTS** | ❌ Non (upstream sigstore project) |
| **Date Release (v3.9.0)** | 2025-02-15 |
| **Date Release (v3.9.1)** | 2025-03-10 |
| **Support policy** | Maintenance 12 mois ; CNCF incubation project |
| **Versions stables recommandées** | v3.9.1 (actuelle) ; v3.8.x (stable antérieure) |
| **Cycle release** | ~1 release par mois |
| **Type** | Container image signing & verification (OCI compliant) |
| **Source** | [sigstore/cosign GitHub](https://github.com/sigstore/cosign) ; [CNCF](https://www.cncf.io/projects/sigstore/) |
| **Dépend de** | Sigstore public infrastructure (keyless signing) ; OIDC provider |
| **Intégration CI** | GitHub Actions : `sigstore/cosign-installer@v3.9.1` |
| **Workflow** | `cosign sign <image>` ; `cosign verify <image>` (OIDC keyless) |
| **Signature format** | Cosign signature (attestation) ; SLSA provenance |
| **Notes** | Remplace GPG pour conteneurs ; CNCF sandbox ; clés ephémères recommandées |

#### Lynis
| Attribut | Valeur |
|----------|--------|
| **Version actuelle** | 3.1.x (à spécifier en prod) |
| **LTS** | ❌ Non (maintenance annuelle) |
| **Date Release (3.1.0)** | 2024-XX-XX |
| **Durée de support** | 12+ mois de maintenance |
| **Versions stables recommandées** | 3.1.x (actuelle) ; 3.0.x (stable antérieure) |
| **Cycle release** | ~1-2 releases par an |
| **Type** | Security audit tool (OS hardening assessment) |
| **Source** | [Lynis GitHub](https://github.com/CISOfy/lynis) ; [Releases](https://github.com/CISOfy/lynis/releases) |
| **Cas d'usage** | CIS benchmarks audit ; compliance (PCI-DSS, HIPAA, SOC2) |
| **Intégration** | CLI : `lynis audit system` ; rapport JSON/HTML |
| **Database** | CycloneDX DB mises à jour régulièrement |
| **Notes** | ✅ FOSS (GPL 3.0) ; active community ; installation simple (bash script) |

**Alternatives si scan OS différent :**
- OpenSCAP (SCAP official)
- Tenable Nessus, Qualys (proprietary)

---

### D. Gestion des dépendances

#### CycloneDX
| Attribut | Valeur |
|----------|--------|
| **Version actuelle (spéc)** | 1.5 |
| **LTS** | ❌ Non (standard OWASP ouvert) |
| **Date Release (1.5)** | 2023-05-10 |
| **Date Release (1.6-draft)** | 2025-01-XX (en cours) |
| **Durée de support** | Spécification stable ; backward compat garantie |
| **Versions stables recommandées** | 1.5 (produit LTS-like) ; 1.4.x (legacy) |
| **Type** | Format de spécification SBOM (Software Bill of Materials) |
| **Source** | [CycloneDX.org](https://cyclonedx.org) ; [GitHub Spec](https://github.com/CycloneDX/specification) |
| **Formats** | XML, JSON, Protobuf |
| **Parseurs** | Trivy (generate cyclonedx) ; OWASP Dependency-Check ; syft |
| **Cas d'usage** | Inventaire dépendances ; analyse vulnérabilités transitive ; compliance |
| **Notes** | Standard OWASP ; supporté dans DependencyTrack ; ISO/IEC 5962:2023 |

#### DependencyTrack
| Attribut | Valeur |
|----------|--------|
| **Version actuelle** | 4.11.x (à spécifier) |
| **LTS** | ❌ Non (releases regulières) |
| **Date Release (4.11.0)** | 2024-XX-XX |
| **Durée de support** | Maintenance 12+ mois à partir majeure |
| **Versions stables recommandées** | 4.11.x (actuelle) ; 4.10.x (stable antérieure) |
| **Cycle release** | ~1 release tous les 3 mois |
| **Type** | Platform d'analyse continue SBOM & dépendances |
| **Source** | [DependencyTrack GitHub](https://github.com/DependencyTrack/dependency-track) ; [Releases](https://github.com/DependencyTrack/dependency-track/releases) |
| **Déploiement** | Docker images : `dependencytrack/apiserver` + `dependencytrack/frontend` |
| **Intégration** | Ingère SBOMs CycloneDX ; détecte vulnérabilités NVD ; license scanning |
| **Cas d'usage** | Risk assessment ; compliance (license, CVE audit trail) |
| **Database** | NVD feeds mises à jour automatiquement |
| **Notes** | ✅ FOSS ; self-hosted ; alternative gratuite à Snyk/Dependabot |

**Alternatives si déploiement alternatif :**
- Snyk (SaaS proprietary, plus rapide)
- Dependabot (GitHub intégré)
- Trivy alone (CLI-only lightweight)

---

### E. CI/CD

#### GitHub Actions
| Attribut | Valeur |
|----------|--------|
| **Version actuelle** | SaaS (continu) |
| **LTS** | N/A (SaaS cloud-hosted) |
| **Date de lancement** | 2018-XX-XX |
| **Support** | SLA 99.95% (Microsoft) |
| **Durée de support** | Windows Server 2019 + abandonnés 2024-12-29 ⚠️ |
| **Versions recommandées** | runners Ubuntu-latest (24.04) ; Windows-latest (2022) ; macOS-latest (14) |
| **Type** | CI/CD orchestration (platform GitHub) |
| **Source** | [GitHub Actions Docs](https://docs.github.com/en/actions) ; [Runners](https://docs.github.com/en/actions/hosting-your-own-runners/about-self-hosted-runners) |
| **Intégrations utilisées** | trivy-action, cosign-installer, hadolint-action |
| **Rétention logs** | 90j par défaut (configurable) |
| **Minutes incluses** | 2000 min/mois public repos (gratuit) |
| **Notes** | Gratuit pour public ; payant pour private repos (~$0.25/min) |

**Alternatives si migration :**
- GitLab CI/CD (self-hosted ou .com)
- Jenkins (on-premise legacy)
- Tekton (K8s native, CNCF)

#### GitHub Registry (GHCR)
| Attribut | Valeur |
|----------|--------|
| **Version actuelle** | SaaS (API v2 OCI) |
| **LTS** | N/A (SaaS intégré GitHub) |
| **Support** | SLA 99.95% (Microsoft) |
| **Durée de support** | Illimitée (tant que GitHub existe) |
| **Type** | Container registry (OCI-compliant) |
| **Endpoint** | `ghcr.io/<owner>/<repo>:<tag>` |
| **Auth** | GitHub PAT ou GITHUB_TOKEN (actions) |
| **Retention** | Deletes oldest si > 30j inactif (configurable) |
| **Source** | [GHCR Docs](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry) |
| **Pricing** | Gratuit ; 5GB storage inclus |
| **Notes** | Inclus GitHub Packages ; push depuis Actions gratuit ; auth simple |

**Alternatives stables :**
- DockerHub (public/private payant)
- Quay.io (RedHat)
- Self-hosted : Harbor, Nexus, Registry (OSS)

---

### F. Monitoring & Stockage

#### Datadog
| Attribut | Valeur |
|----------|--------|
| **Version actuelle** | SaaS (auto-updates hebdo) |
| **LTS** | N/A (SaaS proprietary) |
| **Support** | Premium support available ; SLA 99.95% |
| **Durée de support** | Agent v6+ supporté ; v5 EOL 2020-12-31 |
| **Agent version recommandée** | 7.x (latest) |
| **Cycle release** | Minor updates toutes les 2-4 semaines ; majeur annuel |
| **Type** | Cloud monitoring & observability SaaS |
| **Source** | [Datadog Docs](https://docs.datadoghq.com) ; [Agent Releases](https://github.com/DataDog/datadog-agent/releases) |
| **Intégrations** | Docker, Kubernetes, Ansible, Traefik, MinIO exporters, Linux |
| **Rétention** | 15m haute-résolution (configurable) ; archivage long-terme optionnel |
| **Pricing** | Pay-as-you-go ; custom SLA available |
| **Notes** | Proprietary SaaS ; coûteux au scale ; alternative gratuite : Prometheus + Grafana |

**Alternatives si coût concern :**
- Prometheus + Grafana (FOSS, self-hosted)
- New Relic (SaaS concurrent)
- ELK Stack (Elasticsearch, Logstash, Kibana)

#### MinIO
| Attribut | Valeur |
|----------|--------|
| **Version actuelle** | latest (rolling releases) |
| **LTS** | ❌ Non (release continu, stable backward-compatible) |
| **Dernière stable** | 2025-03-XX (March release) |
| **Durée de support** | Maintenance 12 mois à partir majeure |
| **Versions stables recommandées** | latest stable (recommandé) ; release-antérieure-1 pour conservatisme |
| **Cycle release** | ~1 release par mois (monthly minor releases) |
| **Type** | S3-compatible object storage (self-hosted) |
| **Image Docker** | `minio/minio:latest` (recommandé) ; `minio/minio:RELEASE.YYYY-MM-DD` (pinned) |
| **Source** | [MinIO GitHub](https://github.com/minio/minio) ; [Releases](https://github.com/minio/minio/releases) ; [Docs](https://docs.min.io) |
| **Déploiement** | Standalone (single disk/node) ; Distributed (HA multi-node) |
| **Cas d'usage** | Backup storage (TDE MariaDB), logs centralisés, artifact repository |
| **Dépendances** | ❌ Aucune (binary statique Go) |
| **License** | AGPL v3 (commercial license available) |
| **Notes** | ✅ FOSS ; production-ready ; API S3-compliant ; backward compat/releases |

**Alternatives stables si auto-hébergement non-viable :**
- AWS S3 (SaaS cloud)
- Backblaze B2 (SaaS low-cost)
- DigitalOcean Spaces (S3-compatible SaaS)

---

### G. Linting & QA

#### Yamllint
| Attribut | Valeur |
|----------|--------|
| **Version actuelle** | 1.37.1 |
| **LTS** | ❌ Non (maintenance standard) |
| **Date Release (1.37.0)** | 2024-XX-XX |
| **Date Release (1.37.1)** | 2025-XX-XX |
| **Durée de support** | 12+ mois per minor version |
| **Versions stables recommandées** | 1.37.1 (actuelle) ; 1.36.x (stable antérieure) |
| **Cycle release** | ~1-2 releases par an |
| **Type** | YAML linter (syntax & style validation) |
| **Source** | [yamllint PyPI](https://pypi.org/project/yamllint/) ; [GitHub](https://github.com/adrienverge/yamllint) |
| **Language** | Python |
| **Cas d'usage** | Valide playbooks Ansible, docker-compose, kubernetes, configs YAML |
| **Rules** | 20+ rules ; `.yamllintrc` config (custom severity) |
| **Intégration** | CLI ; pre-commit hooks ; CI/CD integration triviale |
| **Output** | Parsable (JSON, quiet) ; sûr pour automation |
| **Notes** | ✅ FOSS ; léger ; zero-dependency outside Python stdlib |

#### Ansible-doctor
| Attribut | Valeur |
|----------|--------|
| **Installation** | Package PyPI : `ansible-doctor[ansible-core]` |
| **LTS** | ❌ Non (community project) |
| **Dernière release** | 2.2.x (2024-XX-XX) |
| **Durée de support** | Aucun SLA ; maintenance active |
| **Versions stables recommandées** | Latest (2.2.x+) ; compatible Ansible 2.17+ |
| **Type** | Doc generator automatique pour rôles Ansible |
| **Source** | [ansible-doctor GitHub](https://github.com/ansible-community/ansible-doctor) ; [PyPI](https://pypi.org/project/ansible-doctor/) |
| **Output** | README.md généré automatiquement en Markdown |
| **Cas d'usage** | Documente rôles (variables, handlers, tasks, templates) |
| **Dépend de** | Ansible-core (spécifié) ; Jinja2 |
| **Notes** | ✅ FOSS ; réduit maintenance doc ; template personnalisable |

---

## 3. Matrice de dépendances critiques

```
┌─────────────────────┬───────────────────────────────────┐
│ Technologie         │ Dépend de                         │
├─────────────────────┼───────────────────────────────────┤
│ Molecule 25.6.0     │ Ansible-core 2.17+                │
│ Molecule-podman     │ Molecule ; Podman runtime         │
│ Ansible-lint 25.6.1 │ Ansible-core 2.17+                │
│ Ansible-doctor      │ Ansible-core (spécifié)          │
│ Docker Compose v2   │ Docker Engine 20.10+              │
│ Docker Swarm        │ Docker Engine (27.x)              │
│ Traefik v3.4.1      │ Docker ou K8s provider            │
│ Trivy v0.34.1       │ ❌ Aucune (scanner standalone)   │
│ Hadolint v3.1.0     │ ❌ Aucune (standalone)           │
│ Cosign v3.9.1       │ Sigstore infra (keyless)         │
│ CycloneDX + Trivy   │ Trivy outputs cyclonedx           │
│ DependencyTrack     │ CycloneDX SBOMs                   │
│ Datadog Agent       │ Dépend intégration cible         │
│ MinIO               │ ❌ Aucune (standalone)           │
└─────────────────────┴───────────────────────────────────┘
```

---

## 4. Matrice synthétique EOL (Status @ 2026-03-20)

⚠️ **Légende :** 🔴 = Critique (EOL < 1 mois) | 🟡 = Attention (EOL 1-3 mois) | 🟢 = Stable (EOL > 3 mois)

| Technologie | Version actuelle | Date EOL | Durée restante | État | Action |
|---|---|---|---|---|---|
| **Docker** | 27.x | 2025-12-31 | ~9 mois | 🟢 | Suivi ; préparer Docker 28.x |
| **Docker Compose** | v2.29+ | ~2026-03-XX | ~6 jours | 🔴 | **URGENT** : Vérifier version exacte |
| **Docker Swarm** | 27.x | 2025-12-31 | ~9 mois | 🟢 | Suivi (intégré Docker) |
| **Ansible-core** | 2.18.7 | 2025-04-30 | ~41 jours | 🔴 | **URGENT** : Migrer 2.19.x ou 2.20.x **ASAP** |
| **Ansible-lint** | 25.6.1 | ~2025-08-XX | ~5 mois | 🟢 | Suivi |
| **Molecule** | 25.6.0 | ~2025-08-XX | ~5 mois | 🟢 | Suivi |
| **Molecule-podman** | 23.7.0 | Non défini | N/A | 🟡 | Pas de SLA ; vérifier compat Molecule |
| **Traefik** | v3.4.1 | 2025-12-31 | ~9 mois | 🟢 | Suivi ; préparer v4.x |
| **Dive** | latest | Non défini | N/A | 🟡 | Communautaire ; pas de SLA |
| **Trivy** | v0.34.1 | ~2025-06-XX | ~3 mois | 🟡 | Vérifier EOL exact ; préparer v0.36.x |
| **Hadolint** | v3.1.0 | 2025-12-15 | ~9 mois | 🟢 | Suivi |
| **Cosign** | v3.9.1 | ~2026-03-XX | ~0-7 jours | 🔴 | **URGENT** : Vérifier EOL exact ; v3.10.x soon |
| **Lynis** | 3.1.x | Non précisé | N/A | 🟡 | À spécifier version exacte en prod |
| **CycloneDX** | 1.5 | Non EOL (spec stable) | N/A | 🟢 | ISO standard (1.6 en draft) |
| **DependencyTrack** | 4.11.x | Non précisé | N/A | 🟡 | À spécifier version exacte |
| **GitHub Actions** | SaaS | N/A | ∞ | 🟢 | SLA 99.95% Microsoft |
| **GHCR** | SaaS | N/A | ∞ | 🟢 | Inclus GitHub |
| **Datadog Agent** | v7.x | Non défini | N/A | 🟢 | v6+ EOL → v7+ obligatoire |
| **MinIO** | latest | dernière-1 | Roulant | 🟢 | Latest recommendé ; backward-compat |
| **Yamllint** | 1.37.1 | ~2026-06-XX | ~3 mois | 🟡 | Suivi ; maintenance léger |

---

## 5. Actions critiques requises (priorité)

### 🔴 **P0 - IMMÉDIAT (< 1 mois)**

| Outil | Action | Délai | Notes |
|-------|--------|-------|-------|
| **Ansible-core 2.18.x** | Migrer vers 2.19.x ou 2.20.x | ✅ EOL 30-04-2025 | Évaluer compat Molecule, Ansible-lint |
| **Docker Compose v2.x** | Vérifier version exacte (peut être > EOL) | ASAP | Drift possible entre déclaration et prod |
| **Cosign v3.9.1** | Mettre à jour v3.10+ ou v4.x | ASAP | Vérifier breaking changes OIDC |

### 🟡 **P1 - COURT TERME (1-3 mois)**

| Outil | Action | Délai | Notes |
|-------|--------|-------|-------|
| **Trivy v0.34.x** | Migrer v0.36.x | Avant 2025-06-XX | Trivy DB mises à jour ; v0.34 supporté |
| **Yamllint 1.37.x** | Évaluer 1.38.x ou 1.39.x | Avant 2026-06-XX | Léger ; pas d'urgence |

### 🟢 **P2 - MOYEN TERME (3-12 mois)**

| Outil | Action | Délai | Notes |
|-------|--------|-------|-------|
| **Docker 27.x** | Préparer Docker 28.x (cycle imprévisible 4-6m) | Avant 2025-12-31 | Vérifier [releases GitHub](https://github.com/moby/moby/releases) régulièrement |
| **Traefik v3.4.1** | Préparer v4.x (date TBD) | Avant 2025-12-31 | Breaking changes probables |
| **Hadolint v3.1.0** | Suivi ; pas d'urgence | Avant 2025-12-15 | Stable ; maintenance prévisible |

---

## 6. Calendrier de maintenance (2025-2026)

| Date | Événement | Action requise |
|------|-----------|----------------|
| **Maintenant (2026-03-20)** | Ansible-core 2.18.x → 41 jours avant EOL | 🔴 URGENT : Commencer migration |
| **2025-04-30** | **Ansible-core 2.18.x EOL** | Déployer 2.19.x ou 2.20.x en prod |
| **2025-05-15** | Cosign v3.9.x probablement proche EOL | Vérifier ; préparer v4.x (CNCF) |
| **2025-06-XX** | Docker 26.x EOL (fin support 6mois) | Migration Docker 27.x continuée |
| **2025-06-XX** | Trivy v0.34.x EOL (3-4 mois maintenance) | Mettre à jour v0.36.x |
| **2025-12-31** | Docker 27.x EOL (6 mois standard) | Préparer Docker 28.x (release juin) |
| **2025-12-31** | Traefik v3.x EOL (fin de cycle ~30 mois) | Migrer v4.x si disponible |
| **2026-06-XX** | Docker 28.x release (cycle continu 6mois) | Planifier migration |

---

## 7. Processus de mise à jour

### Phase 1 : Détection (Mensuel)
- Vérifier releases officielles (GitHub, PyPI, DockerHub)
- Croiser avec CVE (NVD, Trivy database)
- Documenter changelog breaking changes

### Phase 2 : Validation (Dev)
- Test Molecule + Ansible-lint
- Scan Trivy (new versions)
- Vérifier compatibilité transitive

### Phase 3 : Déploiement (Staging → Prod)
- Hadolint images
- Cosign sign & verify
- Datadog monitoring

### Phase 4 : Documentation
- Mettre à jour ce registre
- Commit + tag git

---

## 8. Sources officielles & liens

| Outil | Release page | CVE tracking |
|-------|--------------|--------------|
| Docker | [releases.docker.com](https://docs.docker.com/release-notes/docker-engine/) | Docker security advisories |
| Ansible | [ansible.com/releases](https://docs.ansible.com/ansible/latest/reference_appendices/release_and_maintenance.html) | [CVE MITRE](https://cve.mitre.org/) |
| Traefik | [GitHub](https://github.com/traefik/traefik/releases) | Security advisories |
| Trivy | [GitHub](https://github.com/aquasecurity/trivy/releases) | Aqua Security |
| MinIO | [GitHub](https://github.com/minio/minio/releases) | MinIO security |

---

## 9. Notes légales & compliance

- ✅ FOSS : Ansible, Trivy, Hadolint, Cosign, Lynis, MinIO, DependencyTrack, CycloneDX
- 🔵 Propriétaire : Docker (Docker Desktop), Traefik (Entreprise), Datadog
- 📜 Licenses détaillées : Voir `LICENSES.md`

---

## 10. Méthodologie de vérification des données

Ce document doit rester **à jour** et **vérifiable**. Voici comment croiser les informations :

### Docker (exemple)
```
# Vérifier cycle release (non-régulier 4-6 mois)
## Source officielle
https://github.com/moby/moby/releases

## Vérification empirique
- Docker 27.0 : 2024-06-12
- Docker 26.0 : 2024-01-10 (écart + 5 mois)
- Docker 25.0 : 2023-10-30 (écart + 2.3 mois)
- Docker 24.0 : 2023-06-07 (écart + 4.7 mois)
→ Conclusion: Cycle variable 4-6 mois, non régulier

## EOL dates
[Docker support lifecycle docs](https://docs.docker.com/release-notes/docker-engine/support-lifecycle/)
→ 6 mois support standard + 6 mois extended (payant)
```

### Processus de validation (Mensuel)

1. **Vérifier sources officielles** de chaque outil
   - GitHub releases / tags
   - PyPI version history
   - DockerHub image tags
   - Documentation officielle EOL

2. **Documenter empiriquement**
   - Dates réelles (pas estimées)
   - Écarts entre releases
   - Pattern cycles (régulier vs imprévisible)

3. **Croiser avec CVE**
   - NVD database (cves.org)
   - Trivy vulnerability feed
   - Security advisories officielles

4. **Commit avec source**
   ```git
   git commit -m "Update Docker 28.x release - source: moby/moby#12345"
   ```