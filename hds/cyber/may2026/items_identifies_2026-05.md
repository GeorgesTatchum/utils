# §3 Items identifiés — Mai 2026 (mois complet)

Période : 01/05/2026 au 31/05/2026.
Méthode : croisement des items remontés par les sources §2 avec les composants présents dans `saas_local/app/composer.lock` (Symfony), `saas_local/modulesjs/*/package.json` (Angular) et `curent-mariadb-onserver.md` (parc MariaDB).

> Convention : un item = un identifiant unique (CVE ou GHSA). Les items groupés conservent un titre composite listant les identifiants des CVE concernées.

## 3.1 Synthèse chiffrée

| Indicateur | Valeur |
|-----------|--------|
| Total items examinés | 218 |
| Applicables OneOrtho | 10 individuels + 1 groupé Windows Server (62 CVE EoP) + 1 groupé MariaDB (13 CVE) |
| Non applicables | 104 (Symfony mailer/notifier/html-sanitizer/json-path/ux, Angular platform-server/service-worker/HttpTransferCache, PHP SOAP, KEV non stack, CERT-FR non stack, MariaDB CVE-2026-21968 déjà patchée, 55 advisories CISA ICS dont 2 ICSMA, items hors périmètre Docker/Nginx/VS Code) + 2 items levés après investigation (X509 + Twig sandbox 3 CVE) |
| À investiguer | 3 (groupe 4 PHP advisories, Microsoft Defender x2) |
| Priorité P1 | 0 (aucune des CVE applicables n'est en KEV actif sur composant utilisé) |
| Priorité P2 | 9 (6 RCE Critical Windows Server + 2 CVE Symfony 20/05 + 1 Angular XSS Template/Component) |
| Priorité P3 | 7 (PHP-FPM XSS, Angular DoS digitsInfo, MariaDB CVSS ≥ 7 : CVE-2026-49261/48165/48163/44168/32710) + groupage Windows Server EoP/DoS/InfoDisc (62 CVE) |
| Priorité P4 | 1 groupé (8 CVE MariaDB CVSS < 7 : CVE-2026-44173/44172/44171/44170/44169/35549/34303/3494) |

## 3.2 Détail des items applicables

### Item 1 : CVE-2026-46626

| Champ | Valeur |
|-------|--------|
| Titre | SymfonyRuntime CVE-2024-50340 Patch Bypass |
| Source | Symfony Security Advisories |
| Date publication | 20/05/2026 |
| CVSS | Non communiqué à ce stade par Symfony, à compléter via NVD après publication |
| Exploité activement (KEV) | Non |
| Exploit public | Non documenté à ce stade |
| Composant impacté | `symfony/runtime` (présent dans composer.lock, branche 5.4.*) |
| Produit concerné | Portail Symfony OneSoftware |
| Exposition | Internet (portail exposé public) |
| Priorité retenue | P2 (CVSS estimé moyen-haut + non KEV à ce stade + exposition internet) — à requalifier P1 si ajout KEV |
| Action décidée | Patch — montée de version `symfony/runtime` vers la version corrigée (à identifier dans l'advisory) |
| Ticket remédiation | À créer en Jira, lié à CICD-169 |
| Échéance | J+14 ouvrés (matrice §4.4 du plan, P2) |
| Responsable | Tech Lead Symfony |

### Item 2 : CVE-2026-45065

| Champ | Valeur |
|-------|--------|
| Titre | UrlGenerator Route-Requirement Bypass via URL Injection |
| Source | Symfony Security Advisories |
| Date publication | 20/05/2026 |
| CVSS | Non communiqué à ce stade |
| Exploité activement (KEV) | Non |
| Exploit public | Non documenté |
| Composant impacté | `symfony/routing` (présent dans composer.lock) |
| Produit concerné | Portail Symfony OneSoftware |
| Exposition | Internet |
| Priorité retenue | P2 |
| Action décidée | Patch — montée de version `symfony/routing` (version cible à confirmer avec le Responsable) |
| Ticket remédiation | À créer en Jira, lié à CICD-169 |
| Échéance | J+14 |
| Responsable | Tech Lead Symfony |

> Note : l'ex-Item 3 (CVE-2026-45063, X509Authenticator) a été levé après investigation et déplacé en §3.3 « Items levés après investigation ». La numérotation des items suivants est conservée pour traçabilité (pas de renumérotation rétroactive).

### Item 4 : GHSA-7qg2-v9fj-4mwv

| Champ | Valeur |
|-------|--------|
| Titre | XSS within PHP-FPM status endpoint |
| Source | GitHub Advisories `php/php-src` |
| Date publication | 07/05/2026 |
| CVE | À compléter (CVE non communiqué dans l'extrait fetché) |
| Sévérité | Modérée |
| Composant impacté | PHP-FPM (présent dans `docker/php/Dockerfile` et `docker/php-alpine/Dockerfile`) |
| Produit concerné | Portail Symfony OneSoftware |
| Exposition | À investiguer : l'endpoint `/status` PHP-FPM est-il exposé publiquement ? Configuration par défaut : non. À confirmer avec la configuration IIS de production |
| Priorité retenue | P3 par défaut (XSS modéré, exposition probable interne uniquement). Reclassé P2 si endpoint exposé public confirmé |
| Action décidée | Vérifier la configuration de l'endpoint `/status`. Patcher PHP à la prochaine version disponible (à confirmer si correctif inclus dans PHP 8.5.6 ou rétroporté en 8.1.x) |
| Ticket remédiation | À créer en Jira, lié à CICD-169 |
| Échéance | J+30 |
| Responsable | DevSecOps + Tech Lead Symfony |

### Item 5 : CVE-2026-32161 + CVE-2026-35421 + CVE-2026-40402 + CVE-2026-40403 + CVE-2026-41089 + CVE-2026-41096

| Champ | Valeur |
|-------|--------|
| Titre | 6 RCE Critical Windows Server — Patch Tuesday 12/05/2026 |
| Source | Microsoft MSRC Security Update Guide (CSV `Security Updates 2026-06-02-121531pm.csv`) |
| Date publication | 12/05/2026 (Patch Tuesday) |
| Sévérité | Critical (6 CVE) |
| Exploité activement (KEV) | Non (aucune des 6 ne figure dans le KEV au 29/05/2026) |
| Exploit public | Non documenté à ce stade |
| Composant impacté | Windows Server 2016 / 2019 / 2022 / 2025 (parc OneOrtho hétérogène, toutes les versions présentes) |
| Produit concerné | Sous-périmètre Infrastructure d'exécution (OS hôte du portail Symfony + IIS) |
| Exposition | Internet (l'OS porte le portail public OneSoftware via IIS) |
| Priorité retenue | P2 (CVSS Critical + exposition internet + non KEV) |
| Action décidée | Application immédiate du Patch Tuesday sur tous les serveurs Windows Server du parc. Validation post-patch sur staging avant prod |
| Ticket remédiation | À créer en Jira, lié à CICD-169 |
| Échéance | J+14 ouvrés (matrice §4.4 P2) |
| Responsable | DevSecOps + équipe infrastructure |

### Item 6 : MSRC Patch Tuesday 12/05/2026 — 62 CVE Important Windows Server

| Champ | Valeur |
|-------|--------|
| Titre | 62 CVE Important Windows Server — Patch Tuesday 12/05/2026 (EoP / DoS / InfoDisc / Security Feature Bypass) |
| Source | Microsoft MSRC Security Update Guide |
| Date publication | 12/05/2026 |
| Volume | 62 CVE Important sur Windows Server 2016/2019/2022/2025 et composants .NET Framework. Liste détaillée disponible dans le CSV source, conservée en annexe |
| Impact dominant | Elevation of Privilege (majorité), Information Disclosure, Denial of Service, Security Feature Bypass |
| Exploitation | EoP et Security Feature Bypass nécessitent généralement un accès local préalable, ce qui limite l'exposition directe internet |
| Composant impacté | Windows Server 2016 / 2019 / 2022 / 2025 + .NET Framework 3.5 / 4.7.2 / 4.8 / 4.8.1 |
| Produit concerné | Sous-périmètre Infrastructure d'exécution |
| Exposition | Interne (accès local requis pour la plupart) |
| Priorité retenue | P3 par lot (les 62 CVE traitées comme un seul bloc patché ensemble via le rouleau cumulatif mensuel Windows Server) |
| Action décidée | Application du Patch Tuesday cumulé en même temps que l'Item 5. Pas d'action item-par-item, traitement groupé |
| Ticket remédiation | Un seul ticket "Patch Tuesday Windows Server 2026-05" à créer en Jira, lié à CICD-169 |
| Échéance | J+30 (par défaut P3) |
| Responsable | DevSecOps + équipe infrastructure |

### Item 7 : CVE-2026-41091

| Champ | Valeur |
|-------|--------|
| Titre | Microsoft Defender Link Following Vulnerability |
| Source | CISA KEV + Microsoft MSRC |
| Date publication MSRC | 19/05/2026 |
| Date ajout KEV | 20/05/2026 |
| Sévérité | Important (MSRC), Elevation of Privilege |
| Exploité activement (KEV) | **Oui** — ajoutée au catalogue KEV le 20/05/2026 |
| Composant impacté | Microsoft Malware Protection Engine (Microsoft Defender Antivirus) |
| Produit concerné | À investiguer : Defender est-il actif sur les serveurs Windows OneOrtho ? Configuration probable par défaut sur Windows Server récents |
| Exposition | Interne (Defender s'exécute en local, mais traite des fichiers reçus en entrée) |
| Priorité retenue | À investiguer. Si Defender actif sur les serveurs OneOrtho → **P2** (KEV + EoP via Defender). Reclassé en non applicable si Defender n'est pas l'antivirus utilisé |
| Action décidée | Vérifier la configuration antivirus sur les serveurs Windows Server du parc. Si Defender, appliquer le correctif immédiatement (auto-update Defender) |
| Ticket remédiation | À créer en Jira (investigation), lié à CICD-169 |
| Échéance | 11/06/2026 (investigation) |
| Responsable | DevSecOps + équipe infrastructure |

### Item 8 : CVE-2026-45498

| Champ | Valeur |
|-------|--------|
| Titre | Microsoft Defender Denial of Service Vulnerability |
| Source | CISA KEV + Microsoft MSRC |
| Date publication MSRC | 19/05/2026 |
| Date ajout KEV | 20/05/2026 |
| Sévérité | Low (MSRC) mais ajoutée à KEV |
| Exploité activement (KEV) | **Oui** — KEV le 20/05/2026 |
| Composant impacté | Microsoft Defender Antimalware Platform |
| Produit concerné | À investiguer : idem Item 7 |
| Exposition | Interne |
| Priorité retenue | À investiguer comme Item 7. Si Defender actif → P3 (DoS + KEV mais sévérité MSRC Low, exposition interne) |
| Action décidée | Idem Item 7 — traitement groupé |
| Ticket remédiation | À créer en Jira (investigation), lié à CICD-169 |
| Échéance | 11/06/2026 |
| Responsable | DevSecOps + équipe infrastructure |

### Item 9 : CVE MariaDB Community Server 2026 — analyse par version du parc

Source : fichier complet `./wwwroot/community-server.md` + inventaire OneOrtho `curent-mariadb-onserver.md`.

**Parc MariaDB OneOrtho** (16 instances) :

| Branche | Version actuelle | Nb instances |
|---------|------------------|--------------|
| 11.8 LTS | 11.8.5 | 8 |
| 11.4 LTS | 11.4.9 | 2 |
| 10.11 LTS | 10.11.15 | 2 |
| 10.6 LTS | 10.6.24 | 4 |

**Matrice d'applicabilité** mise à jour au 01/06/2026 (✗ = vulnérable / ✓ = fix présent / — = branche non affectée) :

| CVE | CVSS | Fix branche 11.8 | Fix branche 11.4 | Fix branche 10.11 | Fix branche 10.6 | 11.8.5 | 11.4.9 | 10.11.15 | 10.6.24 |
|-----|------|------------------|------------------|-------------------|-------------------|--------|--------|----------|---------|
| **CVE-2026-49261** | **10.0** | 11.8.8 | 11.4.12 | 10.11.18 | 10.6.27 | ✗ | ✗ | ✗ | ✗ |
| **CVE-2026-48165** | 8.0 | 11.8.8 | 11.4.12 | 10.11.18 | 10.6.27 | ✗ | ✗ | ✗ | ✗ |
| **CVE-2026-48163** | 8.0 | 11.8.8 | 11.4.12 | 10.11.18 | 10.6.27 | ✗ | ✗ | ✗ | ✗ |
| CVE-2026-44168 | 8.0 | 11.8.7 | 11.4.11 | 10.11.17 | 10.6.26 | ✗ | ✗ | ✗ | ✗ |
| CVE-2026-32710 | 8.6 | 11.8.6 | 11.4.10 | — | — | ✗ | ✗ | — | — |
| CVE-2026-44173 | 5.0 | 11.8.7 | 11.4.11 | 10.11.17 | 10.6.26 | ✗ | ✗ | ✗ | ✗ |
| CVE-2026-44172 | 5.0 | 11.8.7 | 11.4.11 | 10.11.17 | 10.6.26 | ✗ | ✗ | ✗ | ✗ |
| CVE-2026-44171 | 6.3 | 11.8.7 | 11.4.11 | 10.11.17 | 10.6.26 | ✗ | ✗ | ✗ | ✗ |
| CVE-2026-44170 | 5.0 | 11.8.7 | 11.4.11 | 10.11.17 | 10.6.26 | ✗ | ✗ | ✗ | ✗ |
| CVE-2026-44169 | 4.3 | 11.8.7 | 11.4.11 | — | — | ✗ | ✗ | — | — |
| CVE-2026-35549 | 6.5 | 11.8.6 | 11.4.10 | — | — | ✗ | ✗ | — | — |
| CVE-2026-34303 | 6.5 | 11.8.6 | 11.4.10 | 10.11.16 | — | ✗ | ✗ | ✗ | — |
| CVE-2026-3494 | 4.3 | 11.8.6 | 11.4.10 | 10.11.16 | 10.6.25 | ✗ | ✗ | ✗ | ✗ |
| CVE-2026-21968 | 6.5 | 11.8.4 | 11.4.9 | 10.11.15 | 10.6.24 | ✓ | ✓ | ✓ | ✓ |

**13 CVE applicables sur 14** ; CVE-2026-21968 est non applicable (parc OneOrtho exactement aux versions porteuses du fix sur les 4 branches).

**Plan unique de remédiation** : monter chaque instance vers la dernière LTS de sa branche — **11.8.5 → 11.8.8, 11.4.9 → 11.4.12, 10.11.15 → 10.11.18, 10.6.24 → 10.6.27**. Les versions cibles couvrent rétroactivement toutes les CVE applicables, y compris les anciennes (32710, 35549, 34303, 3494) car les correctifs sont cumulatifs.

#### Item 9a : CVE-2026-49261 (CVSS 10.0) — point d'attention critique

| Champ | Valeur |
|-------|--------|
| Titre | CVE-2026-49261 MariaDB Community Server (CVSS 10.0) |
| Périmètre vulnérable | 16 instances sur 16 (toutes branches du parc) |
| KEV | Non |
| Exposition | Interne (MariaDB derrière le portail Symfony, pas exposé internet directement) |
| Priorité retenue | P3 strictement par la matrice §4.4 (CVSS ≥ 7, exposition interne, non KEV). **Attention** : CVSS 10.0 = sévérité maximale ; même avec exposition interne, recommandation d'accélérer ce patch sans attendre J+30 |
| Action décidée | Patch des 4 branches LTS vers les versions cibles 11.8.8 / 11.4.12 / 10.11.18 / 10.6.27 |
| Ticket remédiation | À créer en Jira, lié à CICD-169 |
| Échéance | J+30 réglementaire, traitement recommandé sous J+14 vu le CVSS 10.0 |
| Responsable | DevSecOps + équipe infrastructure |

#### Item 9b : CVE-2026-48165 + CVE-2026-48163 + CVE-2026-44168 + CVE-2026-32710 (CVSS ≥ 7)

| Champ | Valeur |
|-------|--------|
| Périmètre vulnérable | 16 instances pour 48165, 48163, 44168 ; 10 instances pour 32710 (branches 11.x seulement) |
| KEV | Non |
| Exposition | Interne |
| Priorité retenue | P3 (CVSS ≥ 7, exposition interne, non KEV) |
| Action décidée | Couvertes par la même montée de version que l'Item 9a |
| Ticket remédiation | Couvert par le ticket de l'Item 9a |
| Échéance | J+30 |
| Responsable | DevSecOps + équipe infrastructure |

#### Item 9c : CVE-2026-44173 + CVE-2026-44172 + CVE-2026-44171 + CVE-2026-44170 + CVE-2026-44169 + CVE-2026-35549 + CVE-2026-34303 + CVE-2026-3494 (CVSS < 7)

| Champ | Valeur |
|-------|--------|
| Périmètre vulnérable | Variable selon CVE (cf. matrice ci-dessus). Toutes au moins partiellement applicables au parc |
| KEV | Non |
| Exposition | Interne |
| Priorité retenue | P4 (CVSS < 7, exposition interne, non KEV) |
| Action décidée | Couvertes par la même montée de version unique que les Items 9a et 9b. Aucun patch dédié supplémentaire requis |
| Ticket remédiation | Couvert par le ticket de l'Item 9a |
| Échéance | Prochain cycle de patch trimestriel infrastructure |
| Responsable | DevSecOps + équipe infrastructure |

**Synthèse Item 9** : **un seul plan d'action consolidé** = monter chaque instance vers la dernière LTS de sa branche (11.8.8, 11.4.12, 10.11.18, 10.6.27). Ce plan unique résout les 13 CVE applicables sur les 16 instances, dont 1 CVSS 10.0 (CVE-2026-49261), 1 CVSS 8.6 (CVE-2026-32710) et 3 CVSS 8.0 (CVE-2026-48165, 48163, 44168).

> Note : l'ex-Item 10 (CVE-2026-48805 + CVE-2026-48806 + CVE-2026-46636, Twig sandbox bypass) a été levé après investigation et déplacé en §3.3 « Items levés après investigation ». Numérotation des items suivants conservée.

### Item 11 : GHSA-p3vc-36g9-x9gr

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
| Priorité retenue | P3 (CVSS sévérité élevée mais DoS côté client navigateur, non KEV) |
| Action décidée | Montée de version Angular dans chaque module vers la version corrigée |
| Ticket remédiation | À créer en Jira, lié à CICD-169 |
| Échéance | J+30 |
| Responsable | Tech Lead Angular (4 modules) |

### Item 12 : GHSA-692r-grfm-v8x7

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
| Priorité retenue | P2 (XSS + CVSS ≥ 7 + exposition internet sur composant exécuté navigateur) |
| Action décidée | Montée de version Angular vers la version corrigée. Audit du code pour vérifier les patterns vulnérables avant patch |
| Ticket remédiation | À créer en Jira, lié à CICD-169 |
| Échéance | J+14 |
| Responsable | Tech Lead Angular |

## 3.3 Items non applicables (traçabilité)

### Items levés après investigation

Items initialement classés « à investiguer » ou applicables, reclassés non applicables après retour de l'équipe technique. Aucun ticket de remédiation créé (aucune action corrective requise) ; la trace de l'investigation tient lieu de justificatif pour l'audit.

| ID | Composant | Investigation | Conclusion |
|----|-----------|---------------|------------|
| CVE-2026-45063 (X509Authenticator) | `symfony/security-http` | Tech Lead Symfony (juin 2026) | **Non applicable.** Justification primaire : la brique `X509Authenticator` du bundle Security HTTP n'est pas utilisée par OneSoftware. Justification secondaire : selon le Tech Lead la version déployée (5.4.53) ne contient plus la faille. **Écart à réconcilier** : le composer.lock du repo indique `symfony/security-http` v5.4.47 — probablement un composer.lock local non synchronisé avec la prod. La conclusion « non applicable » repose sur la justification primaire (non-usage), indépendante de la version. |
| CVE-2026-48805 + CVE-2026-48806 + CVE-2026-46636 (Twig sandbox bypass) | `twig/twig` | Tech Lead Symfony (juin 2026) | **Non applicable.** Justification primaire : le sandbox Twig n'est pas utilisé pour exécuter des templates fournis par utilisateur. Justification secondaire : selon le Tech Lead la version déployée (3.27.1) ne contient plus les failles. **Écart à réconcilier** : le composer.lock du repo indique `twig/twig` v3.24.0 — composer.lock local probablement non synchronisé avec la prod. Conclusion fondée sur la justification primaire (non-usage du sandbox), indépendante de la version. |

> Action de fond à porter en §7 : réconcilier le composer.lock du repo avec les versions réellement déployées en production (écart constaté sur `twig/twig` et `symfony/security-http`). Tant que l'écart subsiste, ne s'appuyer que sur les justifications de non-usage, pas sur les numéros de version.


### Symfony Security Advisories — 14 items écartés

| ID | Titre | Raison non applicabilité |
|----|-------|--------------------------|
| CVE-2026-45070 | Email Header Injection via Non-Token Characters in Mime Parameter Names | `symfony/mailer` non présent dans composer.lock |
| CVE-2026-45755 | Mailtrap Mailer Webhook Parser Never Verifies X-Mt-Signature HMAC | `symfony/mailer` non présent |
| CVE-2026-45754 | Mailjet and LOX24 Webhook Parsers Never Verify Configured Secret | `symfony/mailer` non présent |
| CVE-2026-47212 | Twilio Notifier Webhook Parser Never Verifies X-Twilio-Signature HMAC | `symfony/notifier` non présent dans composer.lock |
| CVE-2026-45066 | HtmlSanitizer allowLinkHosts/allowMediaHosts Bypass | `symfony/html-sanitizer` non présent dans composer.lock |
| CVE-2026-45064 | HtmlSanitizer BiDi Override Characters Visual Spoofing | `symfony/html-sanitizer` non présent |
| CVE-2026-45756 | JsonPath ReDoS via Attacker-Controlled Regular Expressions | Composant JsonPath Symfony non utilisé |
| CVE-2026-49216 | XSS dans `symfony/ux-autocomplete` via données AJAX | `symfony/ux-autocomplete` absent du composer.lock |
| CVE-2026-49211 | Exposition informations via wildcards LIKE dans EntitySearchUtil | Composant `symfony/ux-*` absent |
| CVE-2026-49212 | LiveComponentHydrator HMAC sans liaison composant/slot | `symfony/ux-live-component` absent |
| CVE-2026-49215 | Contournement CSRF dans `symfony/ux-live-component` (CORS-Safelisted) | `symfony/ux-live-component` absent |
| CVE-2026-49208 | LiveProps date sans format parsées avec constructeur DateTime permissif | `symfony/ux-live-component` absent |
| CVE-2026-49209 | DoS dans `symfony/ux-live-component` via requêtes batch non bornées | `symfony/ux-live-component` absent |
| CVE-2026-49210 | XSS dans `symfony/ux-live-component` via tag composant enfant | `symfony/ux-live-component` absent |

### Angular Security Advisories — 4 items écartés

| GHSA | Titre | Raison non applicabilité |
|------|-------|--------------------------|
| GHSA-rfh7-fxqc-q52v | SSRF via Hostname Hijacking in @angular/platform-server | Le package `@angular/platform-server` n'est dépendance d'aucun planificateur OneOrtho |
| GHSA-95qp-cmmw-mgqv | Request Credential & Cache Policy Stripping in Angular Service Worker | `@angular/service-worker` non utilisé par les planificateurs |
| GHSA-gv2q-mqqv-365m | Request Redirect Policy Bypass in Angular Service Worker | `@angular/service-worker` non utilisé |
| GHSA-q6f4-qqrg-jv6x | Information Leak via Default Caching of Credentialed Requests in HttpTransferCache | HttpTransferCache lié au SSR Angular ; pas de SSR utilisé par les planificateurs |
| GHSA-xrxm-cp7j-8xf6 | URL Parser Differential in `@angular/platform-server` leading to SSRF Allowlist Bypass | `@angular/platform-server` non utilisé |

### GitHub Advisories `php/php-src` — 8 items

| ID | Titre | Raison non applicabilité ou statut |
|----|-------|------------------------------------|
| GHSA-hmxp-6pc4-f3vv | NULL pointer dereference in SOAP apache:Map decoder | SOAP non utilisé par OneSoftware (`ext-soap` non requis, pas d'instanciation SoapClient/SoapServer) |
| GHSA-m33r-qmcv-p97q | SoapServer session-persisted object use-after-free | SOAP non utilisé |
| GHSA-85c2-q967-79q5 | Use-After-Free in SOAP using Apache map with RCE (Critique) | SOAP non utilisé |
| GHSA-m8rr-4c36-8gq4 | Out-of-bounds read in urldecode() | **À investiguer** — `urldecode` est une fonction PHP standard largement utilisée |
| GHSA-74r9-qxhc-fx53 | Global buffer over-read in mb_convert_encoding() | **À investiguer** — l'extension `mbstring` est généralement chargée par Symfony |
| GHSA-4jhr-8w89-j733 | DoS attack via DOMNode::C14N() (Critique) | **À investiguer** — la canonicalisation XML utilisée si signatures XML, à vérifier |
| GHSA-96wq-48vp-hh57 | Signed integer overflow in metaphone() | Fonction `metaphone` non utilisée par OneSoftware |
| GHSA-wm6j-2649-pv75 | Null pointer dereference in php_mb_check_encoding() | Lié à mbstring, à investiguer avec GHSA-74r9 |

Note : les 4 items "À investiguer" sont reclassés en items applicables P3 par défaut tant que l'investigation n'est pas conclusive.

### MariaDB — 1 item écarté

| CVE | Raison non applicabilité |
|-----|--------------------------|
| CVE-2026-21968 (CVSS 6.5) | Le parc OneOrtho est aux versions exactes porteuses du fix (11.8.4, 11.4.9, 10.11.15, 10.6.24). Vulnérabilité couverte sur les 16 instances |

### CISA KEV du 01/05 au 31/05/2026 — 19 items écartés (sur 21 ajoutés)

| CVE | Date ajout | Vendor / Produit | Raison non applicabilité |
|-----|-----------|------------------|--------------------------|
| CVE-2026-9082 | 22/05/2026 | Drupal Core | Drupal non utilisé |
| CVE-2026-48172 | 26/05/2026 | LiteSpeed cPanel Plugin | LiteSpeed/cPanel non utilisés |
| CVE-2026-48027 | 27/05/2026 | Nx Console | Nx non utilisé |
| CVE-2026-45321 | 27/05/2026 | TanStack | TanStack non utilisé |
| CVE-2026-8398 | 27/05/2026 | Daemon Tools Lite | Outil bureautique non en stack production |
| CVE-2026-0257 | 29/05/2026 | Palo Alto PAN-OS Auth Bypass | Équipement réseau Palo Alto non utilisé (à confirmer infra) |
| CVE-2025-34291 | 21/05/2026 | Langflow | Produit non utilisé |
| CVE-2026-34926 | 21/05/2026 | Trend Micro Apex One | Produit non utilisé |
| CVE-2008-4250 | 20/05/2026 | Microsoft Windows Buffer Overflow | CVE de 2008, Windows Server 2016+ déjà patché depuis longtemps |
| CVE-2009-1537 | 20/05/2026 | Microsoft DirectX | DirectX pas dans le périmètre serveur de production |
| CVE-2009-3459 | 20/05/2026 | Adobe Acrobat | Acrobat non utilisé |
| CVE-2010-0249 | 20/05/2026 | Microsoft Internet Explorer | IE non utilisé |
| CVE-2010-0806 | 20/05/2026 | Microsoft Internet Explorer | IE non utilisé |
| CVE-2026-42897 | 15/05/2026 | Microsoft Exchange Server | Exchange non hébergé par OneOrtho |
| CVE-2026-20182 | 14/05/2026 | Cisco Catalyst SD-WAN | Équipement réseau non utilisé |
| CVE-2026-42208 | 08/05/2026 | BerriAI LiteLLM | Produit non utilisé |
| CVE-2026-6973 | 07/05/2026 | Ivanti Endpoint Manager Mobile | Produit non utilisé |
| CVE-2026-0300 | 06/05/2026 | Palo Alto PAN-OS | À confirmer infra réseau, écarté par défaut |
| CVE-2026-31431 | 01/05/2026 | Linux Kernel | OS hôte = Windows Server, pas Linux en prod |

Les 2 CVE KEV applicables (CVE-2026-41091 et CVE-2026-45498 Microsoft Defender) figurent en §3.2 (Items 7 et 8).

### Items hors périmètre — non comptés en items applicables

Trois catégories d'avis ont été remontées par les sources de veille mais sortent du périmètre opérationnel du présent rapport :

| Avis | Source | Motif d'exclusion du périmètre |
|------|--------|--------------------------------|
| CERTFR-2026-AVI-0620 (Docker, 20/05/2026) | CERT-FR | Composant Docker hors périmètre du présent plan |
| CERTFR-2026-AVI-0643 (Nginx, 26/05/2026) | CERT-FR | Composant Nginx hors périmètre du présent plan |
| GHSA-q94j-3wj3-4xcm (VS Code Angular Language Service, 28/05/2026) | Angular Security Advisories (GitHub) | Extension de poste développeur, hors périmètre runtime du produit OneSoftware |
| GHSA-ccq4-xmxr-8hcq (VS Code Angular Language Service, 23/05/2026) | Angular Security Advisories (GitHub) | Idem |

### FDA Medical Device Safety Communications du 01/05 au 31/05/2026 — 0 communication sur la période

Consultation manuelle via navigateur sur https://www.fda.gov/medical-devices/medical-device-safety/safety-communications le 02/06/2026. **Aucune Safety Communication publiée pendant la période**.

| État | Référence | Date | Sujet | Statut |
|------|-----------|------|-------|--------|
| Pour mémoire (hors période) | TRUE METRIX Blood Glucose Monitoring Systems, Trividia Health | 28/04/2026 | Risks of use | Hors période (avril) et hors stack OneOrtho |
| Pour mémoire (cyber, hors stack) | Patient Monitors Contec/Epsimed | 30/01/2025 (mise à jour 02/07/2025) | Cybersecurity Vulnerabilities | Sujet cyber mais produit patient monitor non utilisé par OneOrtho |

Trace de la lecture conservée comme preuve d'audit (capture manuelle de la page FDA datée 02/06/2026 à annexer au rapport).

### CISA ICS / ICSMA du 01/05 au 31/05/2026 — 55 advisories écartés

Consultés manuellement via navigateur sur https://www.cisa.gov/news-events/ics-advisories le 02/06/2026 (WebFetch toujours bloqué par WAF).

**ICS Medical Advisories (2 items)** — aucun applicable au stack OneOrtho :

| Identifiant | Date | Produit | Raison non applicabilité |
|-------------|------|---------|--------------------------|
| ICSMA-26-148-01 | 28/05/2026 | Fourth Frontier Frontier X Mobile Application, Frontier X2 | Wearable ECG, non utilisé par OneOrtho |
| ICSMA-26-146-01 | 26/05/2026 | Eppendorf BioFlo 320 | Bioréacteur de fermentation, non utilisé par OneOrtho |

**ICS Advisories industriels (53 items)** — aucun applicable au stack OneOrtho. Tous concernent des systèmes industriels, IoT ou scada hors périmètre :

| Date | Volume | Vendors / produits concernés (non utilisés par OneOrtho) |
|------|--------|--------------------------------------------------------|
| 28/05/2026 | 8 ICSA | XCharge, Schneider Electric EcoStruxure Machine Expert HVAC, KMW CCTV, CP Plus NVR, ABB Busch-Welcome 2 Wire Door, ABB EIBPORT, PUSR USR-W610, MacGregor Voyage Data Recorder |
| 26/05/2026 | 6 ICSA | ABB LVS MConfig, ABB Ability Camera Connect, ABB B&R Automation Runtime, ABB Ability Zenon, ABB AC500 V2, ABB Terra AC |
| 21/05/2026 | 5 ICSA | ABB Terra AC Wallbox, ABB B&R Automation Runtime, ABB B&R Automation Studio, ABB B&R PCs, Hitachi Energy GMS600 |
| 19/05/2026 | 5 ICSA | Kieback & Peter DDC Building Controllers, ZKTeco CCTV, ScadaBR, Siemens RUGGEDCOM APE1808, ABB CoreSense HM/M10 |
| 14/05/2026 | 17 ICSA | Universal Robots Polyscope 5, Siemens Ruggedcom Rox (×4), Siemens SIMATIC S7 PLC Web Server, Siemens SENTRON 7KT, Siemens SIPROTEC 5, Siemens SIMATIC (×2), Siemens Opcenter RDnL, Siemens ROS#, Siemens Industrial Devices, Siemens Simcenter Femap, Siemens Teamcenter, Siemens Solid Edge, Siemens gWAP |
| 12/05/2026 | 6 ICSA | ABB WebPro SNMP Card PowerValue, ABB AC500 V3 (×2), ABB Automation Builder, Subnet Solutions PowerSYSTEM Center, Fuji Electric Tellus |
| 07/05/2026 | 1 ICSA | MAXHUB Pivot Client Application |
| 05/05/2026 | 5 ICSA | Johnson Controls CEM AC2000, ABB B&R Automation Studio, ABB B&R Automation Runtime, ABB B&R PVI, Hitachi Energy PCM600 |

Tous écartés. La trace de la lecture est conservée comme preuve d'audit (capture manuelle de la page CISA datée 02/06/2026 à annexer au rapport).

### CERT-FR du 01/05 au 31/05/2026 — items écartés (autres composants hors stack)

Liste résumée (motif systématique : éditeur ou produit non utilisé par OneSoftware) :

Drupal, SPIP, Tenable Sensor Proxy, Linux Debian/Ubuntu/Red Hat/SUSE ×6, Microsoft Edge/Microsoft générique ×2, Mattermost ×2, Trend Micro, Stormshield, CPython, Roundcube, Spring AI, Firefox iOS, Kaspersky, Joomla, Samba, Check Point, Veeam ×2, NetApp, Google Chrome ×2, Apereo CAS, GitLab, Centreon, Elastic Kibana, IBM, Oracle Database, Microsoft Azure ×3, Microsoft Windows, Microsoft Exchange ×2 (dont CERTFR-2026-ALE-005 exploitation active CVE-2026-42897), Shibboleth, Palo Alto Networks, PostgreSQL, MISP, Wireshark, F5 NGINX, Atlassian, ISC BIND ×2, Suricata, Mozilla, Splunk, Cisco Secure Workload, Progress MOVEit, GLPI.

Tous écartés. La trace de leur lecture est conservée comme preuve d'audit.

## Items potentiellement absents de cet exercice (sources non consultables)

Les sources publiques §3.1 + §3.2 + §3.3 ont toutes été consultées, soit par WebFetch automatisé, soit par lecture manuelle de la page web (CISA ICS et FDA). Reste à compiler avant la revue du 04/06/2026 :

- **Console Snyk OneOrtho et GitHub Dependabot** : alertes sur dépendances tierces transitives, à compiler depuis les UI internes (non publiques).

Le rapport est validé sous réserve de la compilation Snyk + Dependabot avant la revue du 04/06/2026.
