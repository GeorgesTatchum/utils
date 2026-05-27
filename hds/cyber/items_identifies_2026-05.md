# §3 Items identifiés — Mai 2026

Période : 01/05/2026 au 22/05/2026.
Méthode : croisement des items remontés par les sources §2 avec les composants présents dans `saas_local/app/composer.lock` (Symfony) et `saas_local/modulesjs/*/package.json` (Angular).

> Convention : un item = un identifiant unique (CVE ou GHSA). Pour un advisory CERT-FR sans CVE individuel, l'item porte le numéro de l'avis ANSSI.

## 3.1 Synthèse chiffrée

| Indicateur | Valeur |
|-----------|--------|
| Total items examinés | 116 |
| Applicables OneOrtho | 12 individuels + 1 groupé Windows Server (62 CVE EoP) + 1 groupé MariaDB (8 CVE) |
| Non applicables | 28 (Symfony mailer/notifier/html-sanitizer/json-path, Angular, PHP SOAP, KEV non stack, CERT-FR non stack, MariaDB CVE-2026-21968 déjà patchée) |
| À investiguer | 6 (Symfony X509, PHP urldecode/mb/DOMNode/check_encoding, Docker, Microsoft Defender x2) |
| Priorité P1 | 0 (aucune des CVE applicables n'est en KEV actif sur composant utilisé) |
| Priorité P2 | 8 (6 RCE Critical Windows Server + 2 CVE Symfony) |
| Priorité P3 | 5 (PHP-FPM XSS, Docker, MariaDB items 10a et 10b CVSS ≥ 7) + groupage Windows Server EoP/DoS/InfoDisc (62 CVE) |
| Priorité P4 | 1 groupé (8 CVE MariaDB Item 10c, CVSS < 7) |

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

**Matrice d'applicabilité** (✗ = vulnérable / ✓ = fix présent / — = branche non affectée) :

| CVE | CVSS | Fix branche 11.8 | Fix branche 11.4 | Fix branche 10.11 | Fix branche 10.6 | 11.8.5 | 11.4.9 | 10.11.15 | 10.6.24 |
|-----|------|------------------|------------------|-------------------|-------------------|--------|--------|----------|---------|
| CVE-2026-44168 | 8.0 | 11.8.7 | 11.4.11 | 10.11.17 | 10.6.26 | ✗ | ✗ | ✗ | ✗ |
| CVE-2026-32710 | 8.6 | 11.8.6 | 11.4.10 | — | — | ✗ | ✗ | — | — |
| CVE-2026-35549 | 6.5 | 11.8.6 | 11.4.10 | — | — | ✗ | ✗ | — | — |
| CVE-2026-34303 | 6.5 | 11.8.6 | 11.4.10 | 10.11.16 | — | ✗ | ✗ | ✗ | — |
| CVE-2026-3494 | 4.3 | 11.8.6 | 11.4.10 | 10.11.16 | 10.6.25 | ✗ | ✗ | ✗ | ✗ |
| CVE-2026-44173 | 5.0 | 11.8.7 | 11.4.11 | 10.11.17 | 10.6.26 | ✗ | ✗ | ✗ | ✗ |
| CVE-2026-44172 | 5.0 | 11.8.7 | 11.4.11 | 10.11.17 | 10.6.26 | ✗ | ✗ | ✗ | ✗ |
| CVE-2026-44170 | 5.0 | 11.8.7 | 11.4.11 | 10.11.17 | 10.6.26 | ✗ | ✗ | ✗ | ✗ |
| CVE-2026-44171 | 6.3 | 11.8.7 | 11.4.11 | — | — | ✗ | ✗ | — | — |
| CVE-2026-44169 | 4.3 | 11.8.7 | 11.4.11 | — | — | ✗ | ✗ | — | — |
| CVE-2026-21968 | 6.5 | 11.8.4 | 11.4.9 | 10.11.15 | 10.6.24 | ✓ | ✓ | ✓ | ✓ |

**CVE-2026-21968** est l'unique CVE non applicable : le parc OneOrtho est exactement aux versions porteuses du fix sur les 4 branches utilisées. Toutes les autres CVE sont applicables sur au moins une partie du parc.

**Hypothèse de datation** (le document MariaDB ne contient pas de dates) :
- Les CVE de numéro élevé (CVE-2026-44168 à 44173) correspondent à la release la plus récente listée (12.3.2 / 11.8.7 / 11.4.11 / 10.11.17 / 10.6.26) et tombent vraisemblablement dans la période 01/05–22/05/2026 ou immédiatement antérieure.
- Les CVE de numéro intermédiaire (CVE-2026-32710, 34303, 35549, 3494) correspondent à la release intermédiaire (11.8.6 / 11.4.10 / 10.11.16 / 10.6.25) et sont antérieures à mai 2026.
- Les CVE de numéro bas (CVE-2026-21968) sont plus anciennes encore.

Conséquence pratique : ce premier rapport rattrape l'ensemble des CVE 2026 toutes périodes confondues, ce qui est cohérent avec un exercice initial. Les rapports mensuels suivants ne devront plus reporter que les CVE nouvelles du mois (numérotation à surveiller).

#### Item 10a — CVE-2026-44168 (CVSS 8.0)

| Champ | Valeur |
|-------|--------|
| Périmètre vulnérable | 16 instances sur 16 (toutes branches du parc) |
| KEV | Non |
| Exposition | Interne (MariaDB derrière le portail Symfony) |
| Priorité retenue | **P3** (CVSS ≥ 7, exposition interne, non KEV) |
| Action décidée | Patch des 4 branches LTS vers les versions corrigées : 11.8.5 → 11.8.7, 11.4.9 → 11.4.11, 10.11.15 → 10.11.17, 10.6.24 → 10.6.26 |
| Échéance | J+30 (matrice §4.4 P3) |
| Responsable | DevSecOps + équipe infrastructure |

#### Item 10b — CVE-2026-32710 (CVSS 8.6)

| Champ | Valeur |
|-------|--------|
| Périmètre vulnérable | 10 instances (11.8.5 ×8 + 11.4.9 ×2) — branches 10.11 et 10.6 non affectées |
| KEV | Non |
| Exposition | Interne |
| Priorité retenue | **P3** (CVSS ≥ 7, exposition interne, non KEV) |
| Action décidée | Patch couvert par la même montée de version que l'item 10a (versions cibles 11.8.7 et 11.4.11 contiennent aussi le fix de 11.8.6 et 11.4.10) |
| Échéance | J+30 |
| Responsable | DevSecOps + équipe infrastructure |

#### Item 10c — Groupe CVE moyennes (CVSS 4.3 à 6.5)

CVE concernées : CVE-2026-44173, 44172, 44170, 44171, 44169, 34303, 35549, 3494.

| Champ | Valeur |
|-------|--------|
| Périmètre vulnérable | Variable selon CVE (voir matrice ci-dessus). Toutes au moins partiellement applicables |
| KEV | Non |
| Exposition | Interne |
| Priorité retenue | **P4** (CVSS < 7, exposition interne, non KEV) — matrice §4.4 |
| Action décidée | Traitement groupé : la montée de version unique vers 11.8.7 / 11.4.11 / 10.11.17 / 10.6.26 décidée en items 10a-10b couvre simultanément l'ensemble de ces CVE. Aucun patch dédié supplémentaire requis |
| Échéance | Prochain cycle de patch trimestriel infrastructure |
| Responsable | DevSecOps + équipe infrastructure |

**Synthèse Item 10** : un seul plan d'action consolidé = monter chaque instance vers la dernière LTS de sa branche (11.8.7, 11.4.11, 10.11.17, 10.6.26). Ce plan unique résout 10 CVE sur les 16 instances, dont 2 sévérité élevée (CVE-2026-32710 et CVE-2026-44168).

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

### MariaDB CVE-2026-21968 — 1 item écarté

| CVE | Raison non applicabilité |
|-----|--------------------------|
| CVE-2026-21968 (CVSS 6.5) | Le parc OneOrtho est aux versions exactes porteuses du fix (11.4.9, 11.8.4+, 10.11.15, 10.6.24). Vulnérabilité couverte sur les 16 instances |

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
