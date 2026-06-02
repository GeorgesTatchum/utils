# §3 Items identifiés — Mai 2026 (mois complet)

Période : 01/05/2026 au 31/05/2026.
Méthode : croisement des items remontés par les sources §2 avec les composants présents dans `saas_local/app/composer.lock` (Symfony), `saas_local/modulesjs/*/package.json` (Angular) et `curent-mariadb-onserver.md` (parc MariaDB).

> Convention : un item = un identifiant unique (CVE ou GHSA). Pour un advisory CERT-FR sans CVE individuel, l'item porte le numéro de l'avis ANSSI.

## 3.1 Synthèse chiffrée

| Indicateur | Valeur |
|-----------|--------|
| Total items examinés | 165 |
| Applicables OneOrtho | 17 individuels + 1 groupé Windows Server (62 CVE EoP) + 1 groupé MariaDB (6 CVE) |
| Non applicables | 41 (Symfony mailer/notifier/html-sanitizer/json-path/ux, Angular platform-server/service-worker/HttpTransferCache, PHP SOAP, KEV non stack, CERT-FR non stack, MariaDB CVE-2026-21968 déjà patchée et 4 anciennes hors période) |
| À investiguer | 6 (Symfony X509, PHP urldecode/mb/DOMNode/check_encoding, Docker, Microsoft Defender x2) |
| Priorité P1 | 0 (aucune des CVE applicables n'est en KEV actif sur composant utilisé) |
| Priorité P2 | 9 (6 RCE Critical Windows Server + 2 CVE Symfony 20/05 + 1 Angular XSS Template/Component) |
| Priorité P3 | 9 (PHP-FPM XSS, Docker, Nginx, 3 CVE Twig sandbox, Angular DoS digitsInfo, MariaDB items 10a+10b CVSS ≥ 7 dont CVSS 10.0) + groupage Windows Server EoP/DoS/InfoDisc (62 CVE) |
| Priorité P4 | 1 groupé (6 CVE MariaDB Item 10c, CVSS < 7) |
| Hors périmètre runtime (postes dev) | 2 (GHSA-q94j-3wj3-4xcm + GHSA-ccq4-xmxr-8hcq Critique, extensions VS Code Angular Language Service) |

## 3.2 Détail des items applicables

### Item 1 — CVE-2026-46626

| Champ | Valeur |
|-------|--------|
| Titre | SymfonyRuntime CVE-2024-50340 Patch Bypass |
| Source | Symfony Security Advisories |
| Date publication | 20/05/2026 |
| CVSS | Non communiqué à ce stade par Symfony, à compléter via NVD après publication |
| Exploité activement (KEV) | À confirmer (CISA KEV non consultable lors de l'exercice) |
| Exploit public | Non documenté à ce stade |
| Composant impacté | `symfony/runtime` (présent dans composer.lock, branche 5.4.*) |
| Produit concerné | Portail Symfony OneSoftware |
| Exposition | Internet (portail exposé public) |
| Priorité retenue | P2 (CVSS estimé moyen-haut + non KEV à ce stade + exposition internet) — à requalifier P1 si ajout KEV |
| Action décidée | Patch — montée de version `symfony/runtime` vers la version corrigée (à identifier dans l'advisory) |
| Ticket remédiation | À créer en Jira, lié à CICD-169 |
| Échéance | J+14 ouvrés (matrice §4.4 du plan, P2) |
| Responsable | Tech Lead Symfony |

### Item 2 — CVE-2026-45065

| Champ | Valeur |
|-------|--------|
| Titre | UrlGenerator Route-Requirement Bypass via URL Injection |
| Source | Symfony Security Advisories |
| Date publication | 20/05/2026 |
| CVSS | Non communiqué à ce stade |
| Exploité activement (KEV) | À confirmer |
| Exploit public | Non documenté |
| Composant impacté | `symfony/routing` (présent dans composer.lock, branche 5.4.* — `symfony/routing` est en `^6.0` dans composer.json, à confirmer la version effective installée) |
| Produit concerné | Portail Symfony OneSoftware |
| Exposition | Internet |
| Priorité retenue | P2 |
| Action décidée | Patch — montée de version `symfony/routing` |
| Ticket remédiation | À créer |
| Échéance | J+14 |
| Responsable | Tech Lead Symfony |

### Item 3 — CVE-2026-45063

| Champ | Valeur |
|-------|--------|
| Titre | Identity Spoofing via Unanchored DN Regex in X509Authenticator |
| Source | Symfony Security Advisories |
| Date publication | 20/05/2026 |
| CVSS | Non communiqué |
| Composant impacté | `symfony/security-http` (présent dans composer.lock en transitif via `symfony/security-bundle`) |
| Produit concerné | Portail Symfony OneSoftware |
| Exposition | À investiguer : l'authentificateur X509 est-il utilisé par OneSoftware ? |
| Priorité retenue | **À investiguer** avant priorisation. Si X509Authenticator non utilisé, item reclassé en non applicable. Si utilisé, P3 par défaut (impact identité limité à un canal d'auth spécifique) |
| Action décidée | Investigation d'usage avant décision |
| Responsable | Tech Lead Symfony |

### Item 4 — Multiples vulnérabilités Docker (CERTFR-2026-AVI-0620)

| Champ | Valeur |
|-------|--------|
| Titre | Multiples vulnérabilités dans Docker — Exécution de code arbitraire à distance |
| Source | CERT-FR |
| Date publication | 20/05/2026 |
| CVE associés | À récupérer dans l'avis détaillé (lien CERT-FR) |
| Composant impacté | Docker (images de build et runtime dans `saas_local/app/docker/`) |
| Produit concerné | Infrastructure dev/CI — pas un runtime de production directement, mais utilisé pour produire les images livrées |
| Exposition | Interne (Docker n'est pas exposé internet, mais utilisé dans la chaîne CI/CD GitHub Actions) |
| Priorité retenue | P3 (CVSS estimé haut mais exposition interne, pas de KEV connu) |
| Action décidée | Investiguer les CVE détaillés de l'avis, mettre à jour le moteur Docker si applicable sur les runners GitHub Actions et les postes dev |
| Ticket remédiation | À créer |
| Échéance | J+30 |
| Responsable | DevSecOps |

### Item 5 — PHP-FPM Status Endpoint XSS (GHSA-7qg2-v9fj-4mwv)

| Champ | Valeur |
|-------|--------|
| Titre | XSS within PHP-FPM status endpoint |
| Source | GitHub Advisories `php/php-src` |
| Date publication | 07/05/2026 |
| CVE | À compléter (CVE non communiqué dans l'extrait fetché) |
| Sévérité | Modérée |
| Composant impacté | PHP-FPM (présent dans `docker/php/Dockerfile` et `docker/php-alpine/Dockerfile`) |
| Produit concerné | Portail Symfony OneSoftware |
| Exposition | À investiguer : l'endpoint `/status` PHP-FPM est-il exposé publiquement ? Configuration par défaut : non. À confirmer avec la configuration Nginx/IIS |
| Priorité retenue | P3 par défaut (XSS modéré, exposition probable interne uniquement). Reclassé P2 si endpoint exposé public confirmé |
| Action décidée | Vérifier la configuration de l'endpoint `/status`. Patcher PHP à la prochaine version disponible (à confirmer si correctif inclus dans PHP 8.5.6 ou rétroporté en 8.1.x) |
| Responsable | DevSecOps + Tech Lead Symfony |

### Item 6 — Patch Tuesday Windows Server mai 2026 (6 RCE Critical)

| Champ | Valeur |
|-------|--------|
| Titre | Multiples vulnérabilités d'exécution de code à distance dans Windows Server (Patch Tuesday 12/05/2026) |
| Source | Microsoft MSRC Security Update Guide (CSV `Security Updates 2026-05-22-105057am.csv`) |
| Date publication | 12/05/2026 (Patch Tuesday) |
| CVE Critical RCE | CVE-2026-32161, CVE-2026-35421, CVE-2026-40402 (EoP), CVE-2026-40403, CVE-2026-41089, CVE-2026-41096 |
| Sévérité | Critical |
| Exploité activement (KEV) | Non (aucune des 6 ne figure dans le KEV au 21/05/2026) |
| Exploit public | Non documenté à ce stade |
| Composant impacté | Windows Server 2016 / 2019 / 2022 / 2025 (parc OneOrtho hétérogène — toutes les versions présentes) |
| Produit concerné | Sous-périmètre Infrastructure d'exécution — l'OS hôte sur lequel s'exécutent le portail Symfony et IIS |
| Exposition | Internet (l'OS porte le portail public OneSoftware via IIS) |
| Priorité retenue | **P2** (CVSS Critical + exposition internet + non KEV) |
| Action décidée | Application immédiate du Patch Tuesday sur tous les serveurs Windows Server du parc. Validation post-patch sur staging avant prod |
| Ticket remédiation | À créer en Jira, lié à CICD-169 |
| Échéance | J+14 ouvrés (matrice §4.4 P2) |
| Responsable | DevSecOps + équipe infrastructure |

### Item 7 — Patch Tuesday Windows Server mai 2026 (62 CVE Important — EoP / DoS / InfoDisc / Security Feature Bypass)

| Champ | Valeur |
|-------|--------|
| Titre | Multiples vulnérabilités d'élévation de privilèges, déni de service et divulgation d'information dans Windows Server (Patch Tuesday 12/05/2026) |
| Source | Microsoft MSRC Security Update Guide |
| Date publication | 12/05/2026 |
| Volume | 62 CVE Important sur Windows Server 2016/2019/2022/2025 et composants .NET Framework |
| Impact dominant | Elevation of Privilege (majorité), Information Disclosure, Denial of Service, Security Feature Bypass |
| Exploitation | EoP et Security Feature Bypass nécessitent généralement un accès local préalable, ce qui limite l'exposition directe internet |
| Composant impacté | Windows Server 2016 / 2019 / 2022 / 2025 + .NET Framework 3.5 / 4.7.2 / 4.8 / 4.8.1 |
| Produit concerné | Sous-périmètre Infrastructure d'exécution |
| Exposition | Interne (accès local requis pour la plupart) |
| Priorité retenue | **P3** par lot (les 62 CVE traitées comme un seul bloc patché ensemble via le rouleau cumulatif mensuel Windows Server) |
| Action décidée | Application du Patch Tuesday cumulé en même temps que l'item 6. Pas d'action item-par-item, traitement groupé |
| Ticket remédiation | Un seul ticket "Patch Tuesday Windows Server 2026-05" |
| Échéance | J+30 (par défaut P3) |
| Responsable | DevSecOps + équipe infrastructure |

> Note : la liste complète des 62 CVE Important est disponible dans le fichier CSV source. Si un audit demande la liste détaillée, elle pourra être annexée au rapport.

### Item 8 — CVE-2026-41091 Microsoft Defender Link Following

| Champ | Valeur |
|-------|--------|
| Titre | Microsoft Defender Link Following Vulnerability |
| Source | CISA KEV + Microsoft MSRC |
| Date publication MSRC | 19/05/2026 |
| Date ajout KEV | 20/05/2026 |
| Sévérité | Important (MSRC), Elevation of Privilege |
| Exploité activement (KEV) | **Oui** — ajoutée au catalogue KEV le 20/05/2026 |
| Composant impacté | Microsoft Malware Protection Engine (Microsoft Defender Antivirus) |
| Produit concerné | À investiguer : Defender est-il actif sur les serveurs Windows OneOrtho ? Configuration probable par défaut sur Windows Server récents. |
| Exposition | Interne (Defender s'exécute en local, mais traite des fichiers reçus en entrée) |
| Priorité retenue | **À investiguer**. Si Defender actif sur les serveurs OneOrtho → **P2** (KEV + EoP via Defender). Reclassé en non applicable si Defender n'est pas l'antivirus utilisé. |
| Action décidée | Vérifier la configuration antivirus sur les serveurs Windows Server du parc. Si Defender, appliquer le correctif immédiatement (auto-update Defender) |
| Responsable | DevSecOps + équipe infrastructure |

### Item 9 — CVE-2026-45498 Microsoft Defender Denial of Service

| Champ | Valeur |
|-------|--------|
| Titre | Microsoft Defender Denial of Service Vulnerability |
| Source | CISA KEV + Microsoft MSRC |
| Date publication MSRC | 19/05/2026 |
| Date ajout KEV | 20/05/2026 |
| Sévérité | Low (MSRC) mais ajoutée à KEV |
| Exploité activement (KEV) | **Oui** — KEV le 20/05/2026 |
| Composant impacté | Microsoft Defender Antimalware Platform |
| Produit concerné | À investiguer : idem item 8 |
| Exposition | Interne |
| Priorité retenue | **À investiguer** comme item 8. Si Defender actif → P3 (DoS + KEV mais sévérité MSRC Low, exposition interne) |
| Action décidée | Idem item 8 — traitement groupé |
| Responsable | DevSecOps + équipe infrastructure |

### Item 10 — CVE MariaDB Community Server 2026 (analyse par version du parc)

Source : Documentation officielle MariaDB Corporation (GitHub raw) + inventaire OneOrtho `curent-mariadb-onserver.md`.

**Parc MariaDB OneOrtho** (16 instances) :

| Branche | Version actuelle | Nb instances |
|---------|------------------|--------------|
| 11.8 LTS | 11.8.5 | 8 |
| 11.4 LTS | 11.4.9 | 2 |
| 10.11 LTS | 10.11.15 | 2 |
| 10.6 LTS | 10.6.24 | 4 |

**Matrice d'applicabilité** mise à jour au 01/06/2026 (✗ = vulnérable / ✓ = fix présent / — = branche non affectée) :

| CVE | CVSS | Fix branche 11.8 | Fix branche 11.4 | Fix branche 10.11 | Fix branche 10.6 | 11.8.5 | 11.4.9 | 10.11.15 | 10.6.24 | Période de publication |
|-----|------|------------------|------------------|-------------------|-------------------|--------|--------|----------|---------|-----------------------|
| **CVE-2026-49261** | **10.0** | 11.8.8 | 11.4.12 | 10.11.18 | 10.6.27 | ✗ | ✗ | ✗ | ✗ | Apparue entre 22 et 31/05 |
| **CVE-2026-48165** | 8.0 | 11.8.8 | 11.4.12 | 10.11.18 | 10.6.27 | ✗ | ✗ | ✗ | ✗ | Apparue entre 22 et 31/05 |
| **CVE-2026-48163** | 8.0 | 11.8.8 | 11.4.12 | 10.11.18 | 10.6.27 | ✗ | ✗ | ✗ | ✗ | Apparue entre 22 et 31/05 |
| CVE-2026-44168 | 8.0 | 11.8.7 | 11.4.11 | 10.11.17 | 10.6.26 | ✗ | ✗ | ✗ | ✗ | Au 22/05 |
| CVE-2026-44173 | 5.0 | 11.8.7 | 11.4.11 | 10.11.17 | 10.6.26 | ✗ | ✗ | ✗ | ✗ | Au 22/05 |
| CVE-2026-44172 | 5.0 | 11.8.7 | 11.4.11 | 10.11.17 | 10.6.26 | ✗ | ✗ | ✗ | ✗ | Au 22/05 |
| CVE-2026-44171 | 6.3 | 11.8.7 | 11.4.11 | 10.11.17 | 10.6.26 | ✗ | ✗ | ✗ | ✗ | Au 22/05 |
| CVE-2026-44170 | 5.0 | 11.8.7 | 11.4.11 | 10.11.17 | 10.6.26 | ✗ | ✗ | ✗ | ✗ | Au 22/05 |
| CVE-2026-44169 | 4.3 | 11.8.7 | 11.4.11 | — | — | ✗ | ✗ | — | — | Au 22/05 |

**Évolution depuis le rapport mi-mois (22/05) :**
- **Ajout de 3 nouvelles CVE** dans le document MariaDB officiel entre 22 et 31/05, dont **CVE-2026-49261 CVSS 10.0** (critique) et 2 CVSS 8.0. Toutes les 16 instances OneOrtho sont vulnérables.
- **Retrait de 5 CVE plus anciennes** du document de référence (CVE-2026-21968, 3494, 32710, 34303, 35549) — ces CVE sont vraisemblablement antérieures à mai 2026 et sont reclassées en §3.3 (non applicables pour ce mois car hors période).
- Une nouvelle release MariaDB est disponible : 11.8.8 / 11.4.12 / 10.11.18 / 10.6.27. Le plan de patch unique passe donc des cibles "11.8.7 / 11.4.11 / 10.11.17 / 10.6.26" (rapport mi-mois) à **"11.8.8 / 11.4.12 / 10.11.18 / 10.6.27"** (rapport mois complet) — qui couvrent rétro-activement toutes les CVE.

#### Item 10a — CVE-2026-49261 (CVSS 10.0) — **point d'attention critique**

| Champ | Valeur |
|-------|--------|
| Titre | CVE-2026-49261 MariaDB Community Server (CVSS 10.0) |
| Périmètre vulnérable | 16 instances sur 16 (toutes branches du parc) |
| KEV | Non |
| Exposition | Interne (MariaDB derrière le portail Symfony, pas exposé internet directement) |
| Priorité retenue | **P3** strictement par la matrice §4.4 (CVSS ≥ 7, exposition interne, non KEV). **Attention** : CVSS 10.0 = sévérité maximale ; même avec exposition interne, recommandation d'accélérer ce patch sans attendre J+30 |
| Action décidée | Patch des 4 branches LTS vers les versions cibles : 11.8.5 → 11.8.8, 11.4.9 → 11.4.12, 10.11.15 → 10.11.18, 10.6.24 → 10.6.27 |
| Échéance | J+30 réglementaire, mais traitement recommandé sous J+14 vu le CVSS |
| Responsable | DevSecOps + équipe infrastructure |

#### Item 10b — CVE-2026-48165 et CVE-2026-48163 (CVSS 8.0 chacune)

| Champ | Valeur |
|-------|--------|
| Périmètre vulnérable | 16 instances sur 16 |
| KEV | Non |
| Exposition | Interne |
| Priorité retenue | **P3** (CVSS ≥ 7, exposition interne, non KEV) |
| Action décidée | Couvertes par la même montée de version que l'item 10a (cibles 11.8.8 / 11.4.12 / 10.11.18 / 10.6.27) |
| Échéance | J+30 |
| Responsable | DevSecOps + équipe infrastructure |

#### Item 10c — Groupe CVE 5.0-6.3 (CVE-2026-44173, 44172, 44171, 44170, 44169) et CVE-2026-44168 (8.0)

CVE concernées : CVE-2026-44168 (CVSS 8.0), CVE-2026-44173 (5.0), CVE-2026-44172 (5.0), CVE-2026-44171 (6.3), CVE-2026-44170 (5.0), CVE-2026-44169 (4.3).

| Champ | Valeur |
|-------|--------|
| Périmètre vulnérable | 16 instances pour la plupart, 10 instances pour CVE-2026-44169 (branches 11.x seulement) |
| KEV | Non |
| Exposition | Interne |
| Priorité retenue | **P3** pour CVE-2026-44168 (CVSS 8.0), **P4** pour les 5 autres (CVSS < 7) |
| Action décidée | Couvertes par la même montée de version unique que items 10a-10b (11.8.8 / 11.4.12 / 10.11.18 / 10.6.27 contiennent aussi les fix de 11.8.7 / 11.4.11 / 10.11.17 / 10.6.26) |
| Échéance | J+30 |
| Responsable | DevSecOps + équipe infrastructure |

**Synthèse Item 10** : **un seul plan d'action consolidé** = monter chaque instance vers la dernière LTS de sa branche (11.8.8, 11.4.12, 10.11.18, 10.6.27). Ce plan unique résout les 9 CVE applicables sur les 16 instances, dont 1 CVSS 10.0 (CVE-2026-49261) et 3 CVSS 8.0 (CVE-2026-48165, 48163, 44168).

### Item 11 — Twig sandbox bypass (3 CVE, 27/05/2026)

| Champ | Valeur |
|-------|--------|
| Titre | Vulnérabilités sandbox Twig — CVE-2026-48805, CVE-2026-48806, CVE-2026-46636 |
| Source | Symfony Security Advisories (27/05/2026) |
| Date publication | 27/05/2026 |
| CVE | CVE-2026-48805 (régression état sandbox dans wrappers internes), CVE-2026-48806 (contournement via `__toString()` sur clés mapping dynamiques), CVE-2026-46636 (contournement allowlist sandbox entre rendus de templates cachés) |
| Composant impacté | `twig/twig` (présent dans composer.lock) |
| Produit concerné | Portail Symfony OneSoftware |
| Exposition | Interne / Internet selon contexte. Vulnérabilités exploitables seulement si Twig sandbox est utilisé pour exécuter des templates fournis par utilisateur (peu probable côté OneSoftware mais à confirmer). À investiguer |
| KEV | Non |
| Priorité retenue | **P3** par défaut. Si Twig sandbox non utilisé pour des templates utilisateur → reclassé non applicable |
| Action décidée | Étape 1 : investiguer l'utilisation du sandbox Twig dans OneSoftware (recherche de `\Twig\Sandbox\SecurityPolicy` ou `\Twig\Extension\SandboxExtension`). Étape 2 : si utilisé, patcher Twig vers la version corrigée |
| Échéance | J+30 |
| Responsable | Tech Lead Symfony |

### Item 12 — Angular DoS via OOM in Number Formatting (GHSA-p3vc-36g9-x9gr, 28/05/2026)

| Champ | Valeur |
|-------|--------|
| Titre | Denial of Service (DoS) via OOM in Number Formatting (digitsInfo) |
| Source | Angular Security Advisories (GitHub) |
| Date publication | 28/05/2026 |
| Sévérité | Élevée |
| Composant impacté | `@angular/common` (présent dans tous les `package.json` des planificateurs Hip2D, Hip3D, KneeMadison, Shoulder3D) |
| Produit concerné | Planificateurs Angular (4 modules) |
| Exposition | Internet (modules livrés au navigateur client) |
| KEV | Non |
| Priorité retenue | **P3** (CVSS sévérité élevée mais DoS côté client navigateur, non KEV) |
| Action décidée | Montée de version Angular dans chaque module vers la version corrigée |
| Échéance | J+30 |
| Responsable | Tech Lead Angular (4 modules) |

### Item 13 — Angular XSS Template/Dynamic Component (GHSA-692r-grfm-v8x7, 28/05/2026)

| Champ | Valeur |
|-------|--------|
| Titre | Angular Template and Dynamic Component Namespace Bypass leading to Cross-Site Scripting (XSS) |
| Source | Angular Security Advisories (GitHub) |
| Date publication | 28/05/2026 |
| Sévérité | Modérée |
| Composant impacté | `@angular/core` (templates et composants dynamiques, présent dans tous les modules) |
| Produit concerné | Planificateurs Angular (4 modules) |
| Exposition | Internet (XSS exploitable si données utilisateur passent par certains patterns de rendu) |
| KEV | Non |
| Priorité retenue | **P2** (XSS + CVSS ≥ 7 + exposition internet sur composant exécuté navigateur) |
| Action décidée | Montée de version Angular vers la version corrigée. Audit du code pour vérifier les patterns vulnérables avant patch |
| Échéance | J+14 |
| Responsable | Tech Lead Angular |

### Item 14 — Vulnérabilités Nginx (CERTFR-2026-AVI-0643, 26/05/2026)

| Champ | Valeur |
|-------|--------|
| Titre | Multiples vulnérabilités Nginx — Exécution de code à distance, déni de service |
| Source | CERT-FR |
| Date publication | 26/05/2026 |
| Composant impacté | Nginx — présent dans `saas_local/app/docker/nginx/Dockerfile` (nginx:1.23.3-alpine) et `docker/nginx-alpine/Dockerfile` (nginx:stable-alpine3.23) |
| Produit concerné | Conteneurs de build/CI Docker — pas un runtime de production directement (IIS sert le portail en production) mais utilisé pour les builds livrés |
| Exposition | Hors ligne / Interne (CI seulement) |
| KEV | Non |
| Priorité retenue | **P3** (RCE potentielle mais sur composant CI uniquement, exposition interne) |
| Action décidée | Investiguer les CVE détaillées de l'avis, mettre à jour les images Docker Nginx (alpine 3.23+ ou plus récent selon advisory) |
| Échéance | J+30 |
| Responsable | DevSecOps |

### Item 15 — CVE Symfony additionnelles du 27/05 (référence CERT-FR)

Référence : CERTFR-2026-AVI-0653 mentionne SSRF, XSS, contournement dans Symfony. À l'inspection, les CVE Symfony du 27/05 listées par Symfony Security Advisories sont exclusivement les 3 CVE Twig sandbox déjà traitées en Item 11. Le CERT-FR semble agréger une annonce élargie incluant possiblement les CVE UX du 29/05 (non applicables). À confirmer manuellement lors de la consultation de l'avis détaillé CERT-FR. Pas d'action séparée requise au-delà de l'Item 11.

### Items hors périmètre runtime (postes développeurs) — pour information

Deux advisories Angular du 23 et 28/05 concernent l'extension **VS Code Angular Language Service** :

- **GHSA-ccq4-xmxr-8hcq** (23/05, **Critique**) : Insecure Workspace Configuration and Dynamic Library Loading
- **GHSA-q94j-3wj3-4xcm** (28/05, Élevée) : RCE via JSDoc Hover Command Injection

Ces vulnérabilités touchent les **postes de développement Angular** (extensions VS Code installées par les Tech Leads Angular), pas le runtime produit livré aux clients. Hors périmètre strict du présent rapport mais à signaler dans la PSSI poste dev : recommander la mise à jour immédiate de l'extension VS Code pour les développeurs Angular OneOrtho. Action portée par DevSecOps en parallèle de cette revue.

## 3.3 Items non applicables (traçabilité)

### Symfony Security Advisories du 20/05/2026 — sept items écartés

| ID | Titre | Raison non applicabilité |
|----|-------|--------------------------|
| CVE-2026-45070 | Email Header Injection via Non-Token Characters in Mime Parameter Names | `symfony/mailer` non présent dans composer.lock |
| CVE-2026-45755 | Mailtrap Mailer Webhook Parser Never Verifies X-Mt-Signature HMAC | `symfony/mailer` non présent |
| CVE-2026-45754 | Mailjet and LOX24 Webhook Parsers Never Verify Configured Secret | `symfony/mailer` non présent |
| CVE-2026-47212 | Twilio Notifier Webhook Parser Never Verifies X-Twilio-Signature HMAC | `symfony/notifier` non présent dans composer.lock |
| CVE-2026-45066 | HtmlSanitizer allowLinkHosts/allowMediaHosts Bypass | `symfony/html-sanitizer` non présent dans composer.lock |
| CVE-2026-45064 | HtmlSanitizer BiDi Override Characters Visual Spoofing | `symfony/html-sanitizer` non présent |
| CVE-2026-45756 | JsonPath ReDoS via Attacker-Controlled Regular Expressions | Composant JsonPath Symfony non utilisé |

### Angular Security Advisories du 14/05/2026 — un item écarté

| ID | Titre | Raison non applicabilité |
|----|-------|--------------------------|
| GHSA-rfh7-fxqc-q52v | SSRF via Hostname Hijacking in @angular/platform-server | Le package `@angular/platform-server` n'est dépendance d'aucun planificateur OneOrtho. Les modules utilisent `@angular/platform-browser` et `@angular/platform-browser-dynamic`, qui ne sont pas affectés |

### GitHub Advisories `php/php-src` du 07/05/2026 — six items écartés ou à investiguer

| ID | Titre | Raison non applicabilité ou statut |
|----|-------|------------------------------------|
| GHSA-hmxp-6pc4-f3vv | NULL pointer dereference in SOAP apache:Map decoder | SOAP non utilisé par OneSoftware (`ext-soap` non requis dans composer.json, pas d'instanciation SoapClient/SoapServer dans le code applicatif vérifié) |
| GHSA-m33r-qmcv-p97q | SoapServer session-persisted object use-after-free | SOAP non utilisé |
| GHSA-85c2-q967-79q5 | Use-After-Free in SOAP using Apache map with RCE (Critique) | SOAP non utilisé |
| GHSA-m8rr-4c36-8gq4 | Out-of-bounds read in urldecode() | **À investiguer** — `urldecode` est une fonction PHP standard largement utilisée. Cf. note ci-dessous |
| GHSA-74r9-qxhc-fx53 | Global buffer over-read in mb_convert_encoding() | **À investiguer** — l'extension `mbstring` est généralement chargée par Symfony |
| GHSA-4jhr-8w89-j733 | DoS attack via DOMNode::C14N() (Critique) | **À investiguer** — la canonicalisation XML est utilisée si signatures XML, à vérifier dans les bundles internes |
| GHSA-96wq-48vp-hh57 | Signed integer overflow in metaphone() | Fonction `metaphone` non utilisée par OneSoftware (recherche grep négative à confirmer) |
| GHSA-wm6j-2649-pv75 | Null pointer dereference in php_mb_check_encoding() | Lié à mbstring, à investiguer avec GHSA-74r9 |

Note : les items "À investiguer" sont reclassés en items applicables P3 par défaut tant que l'investigation n'est pas conclusive. Voir aussi item 5 (PHP-FPM XSS) qui est lui applicable.

### MariaDB — 5 items écartés

| CVE | Raison non applicabilité |
|-----|--------------------------|
| CVE-2026-21968 (CVSS 6.5) | Le parc OneOrtho est aux versions exactes porteuses du fix. Vulnérabilité déjà couverte. CVE retirée du document de référence MariaDB entre 22 et 31/05 |
| CVE-2026-3494 (CVSS 4.3) | CVE retirée du document de référence MariaDB entre 22 et 31/05. Antérieure à la période ce rapport |
| CVE-2026-32710 (CVSS 8.6) | Idem, retirée du document de référence. Antérieure à mai 2026 |
| CVE-2026-34303 (CVSS 6.5) | Idem |
| CVE-2026-35549 (CVSS 6.5) | Idem |

Note : ces 5 CVE seront néanmoins couvertes par la montée de version planifiée à l'Item 10 (versions cibles 11.8.8 / 11.4.12 / 10.11.18 / 10.6.27 contiennent tous les fix antérieurs).

### Symfony Security Advisories du 27/05 et 29/05/2026 — 7 items UX écartés

| CVE | Titre | Raison non applicabilité |
|-----|-------|--------------------------|
| CVE-2026-49216 | XSS dans `symfony/ux-autocomplete` via données AJAX | `symfony/ux-autocomplete` absent du composer.lock |
| CVE-2026-49211 | Exposition informations via wildcards LIKE dans EntitySearchUtil | Composant `symfony/ux-*` absent |
| CVE-2026-49212 | LiveComponentHydrator HMAC sans liaison composant/slot | `symfony/ux-live-component` absent |
| CVE-2026-49215 | Contournement CSRF dans `symfony/ux-live-component` (CORS-Safelisted) | `symfony/ux-live-component` absent |
| CVE-2026-49208 | LiveProps date sans format parsées avec constructeur DateTime permissif | `symfony/ux-live-component` absent |
| CVE-2026-49209 | DoS dans `symfony/ux-live-component` via requêtes batch non bornées | `symfony/ux-live-component` absent |
| CVE-2026-49210 | XSS dans `symfony/ux-live-component` via tag composant enfant | `symfony/ux-live-component` absent |

### Angular Security Advisories du 23 et 28/05/2026 — 4 items écartés runtime

| GHSA | Titre | Raison non applicabilité runtime |
|------|-------|----------------------------------|
| GHSA-95qp-cmmw-mgqv | Request Credential & Cache Policy Stripping in Angular Service Worker | `@angular/service-worker` non utilisé par les planificateurs |
| GHSA-gv2q-mqqv-365m | Request Redirect Policy Bypass in Angular Service Worker | `@angular/service-worker` non utilisé |
| GHSA-q6f4-qqrg-jv6x | Information Leak via Default Caching of Credentialed Requests in HttpTransferCache | HttpTransferCache lié au SSR Angular ; pas de SSR utilisé par les planificateurs |
| GHSA-xrxm-cp7j-8xf6 | URL Parser Differential in `@angular/platform-server` leading to SSRF Allowlist Bypass | `@angular/platform-server` non utilisé (déjà écarté pour GHSA-rfh7-fxqc-q52v) |

Note : les 2 GHSA `@angular language service` (extension VS Code) ne sont pas écartés en runtime — ils sont traités séparément en hors périmètre poste dev (Item 14 du §3.2).

### CISA KEV du 01/05 au 31/05/2026 — 19 items écartés (sur 21 ajoutés)

Items écartés du 22 au 31/05 (en complément des 13 du 01-21/05) :

| CVE | Date ajout | Vendor / Produit | Raison non applicabilité |
|-----|-----------|------------------|--------------------------|
| CVE-2026-9082 | 22/05/2026 | Drupal Core | Drupal non utilisé |
| CVE-2026-48172 | 26/05/2026 | LiteSpeed cPanel Plugin | LiteSpeed/cPanel non utilisés |
| CVE-2026-48027 | 27/05/2026 | Nx Console | Nx non utilisé |
| CVE-2026-45321 | 27/05/2026 | TanStack | TanStack non utilisé |
| CVE-2026-8398 | 27/05/2026 | Daemon Tools Lite | Outil bureautique non en stack production |
| CVE-2026-0257 | 29/05/2026 | Palo Alto PAN-OS Auth Bypass | Équipement réseau Palo Alto non utilisé (à confirmer infra) |

### CISA KEV du 01/05 au 22/05/2026 — 13 items écartés (sur 15 ajoutés)

| CVE | Vendor / Produit | Raison non applicabilité |
|-----|------------------|--------------------------|
| CVE-2025-34291 | Langflow | Produit non utilisé par OneOrtho |
| CVE-2026-34926 | Trend Micro Apex One | Produit non utilisé |
| CVE-2008-4250 | Microsoft Windows (Buffer Overflow) | CVE de 2008 ; Windows Server 2016+ déjà patché depuis longtemps |
| CVE-2009-1537 | Microsoft DirectX | DirectX pas dans le périmètre serveur de production |
| CVE-2009-3459 | Adobe Acrobat | Acrobat pas utilisé |
| CVE-2010-0249 | Microsoft Internet Explorer | IE pas utilisé |
| CVE-2010-0806 | Microsoft Internet Explorer | IE pas utilisé |
| CVE-2026-42897 | Microsoft Exchange Server | Exchange non hébergé par OneOrtho |
| CVE-2026-20182 | Cisco Catalyst SD-WAN | Équipement réseau non utilisé |
| CVE-2026-42208 | BerriAI LiteLLM | Produit non utilisé |
| CVE-2026-6973 | Ivanti Endpoint Manager Mobile | Produit non utilisé |
| CVE-2026-0300 | Palo Alto PAN-OS | À confirmer infra réseau — par défaut écarté |
| CVE-2026-31431 | Linux Kernel | OS hôte = Windows Server, pas Linux en prod |

Les 2 CVE KEV applicables (CVE-2026-41091 et CVE-2026-45498) sont en §3.2 (Items 8 et 9).

### CERT-FR du 22/05 au 31/05/2026 — 35 items écartés (complément)

Tous les avis CERT-FR de la fenêtre 22-31/05 ne concernant aucun composant nommé en §2.2 du plan. Liste résumée (motif systématique : éditeur ou produit non utilisé par OneSoftware) :

Drupal, SPIP, Tenable Sensor Proxy, Linux Debian/Ubuntu/Red Hat/SUSE ×6, Microsoft Edge/Microsoft générique ×2, Mattermost ×2, Trend Micro (CVE exploitée activement mais produit non utilisé), Stormshield, CPython, Roundcube, Spring AI, Firefox iOS, Kaspersky, Joomla, Samba, Check Point, Veeam ×2, NetApp, Google Chrome, Apereo CAS, GitLab, Centreon, Elastic Kibana, IBM, Oracle Database.

Tous écartés. Trace conservée pour audit.

### CERT-FR du 01/05 au 22/05/2026 — 36 items écartés

Tous les avis CERT-FR de la période ne concernant aucun composant nommé en §2.2 du plan ou aucun composant transitivement présent dans le stack OneSoftware. Liste résumée (motif systématique : éditeur ou produit non utilisé par OneSoftware) :

Google Chrome ×2, Microsoft Azure ×3, Microsoft Edge, Microsoft Windows, Microsoft Exchange ×2 (dont CERTFR-2026-ALE-005 exploitation active CVE-2026-42897 — exchange non utilisé), produits Microsoft génériques ×3, noyau Linux SUSE / Debian / Ubuntu / Red Hat ×4 (OS hôte Windows, pas Linux en prod actuellement), Shibboleth, Mattermost ×2, Palo Alto Networks, IBM, PostgreSQL, MISP, Wireshark, F5 NGINX, Atlassian, ISC BIND ×2, Suricata, Mozilla, Splunk, Cisco Secure Workload, Apereo, Progress MOVEit, Drupal, GLPI.

Tous écartés. La trace de leur lecture est conservée comme preuve d'audit.

## Items potentiellement absents de cet exercice (sources non consultables)

Les sources suivantes n'ont pas pu être consultées par WebFetch ni par export local ce jour. Les items qu'elles pourraient remonter pour la période sont **non documentés** dans cette mise à jour du rapport. Action de rattrapage à effectuer manuellement avant validation finale (cf. recommandations §7 du fichier sources) :

- **CISA ICS Medical Advisories** : possibles advisories visant des composants tiers d'imagerie médicale (DICOM, etc.) ou des dispositifs orthopédiques.
- **FDA Medical Device Safety Communications** : possibles communications cybersécurité visant des fabricants tiers ou des composants logiciels utilisés en commun.
- **Packagist Security Advisories** : non scrapable en HTML, API JSON à interroger pour récupérer les advisories Composer du mois.
- **Console Snyk OneOrtho et GitHub Dependabot** : alertes sur dépendances tierces transitives, à compiler depuis les UI internes.

Le rapport tel quel est **partiel mais largement plus complet** que la version initiale grâce à l'intégration KEV (via JSON direct) et MSRC (via CSV export). Sa validation en statut DRAFT → VALIDATED est possible avec mention explicite de cette limite ; la bascule VALIDATED → PUBLISHED reste conditionnée au rattrapage des 5 sources ci-dessus.
