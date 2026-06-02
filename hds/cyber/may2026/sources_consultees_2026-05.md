# §2 Sources consultées — Mai 2026 (mois complet)

Période couverte : 01/05/2026 au 31/05/2026.
Date de consultation initiale (mi-mois) : 22/05/2026.
Date de consultation finale (clôture mois) : 01/06/2026.
Date de revue planifiée : 04/06/2026 (1er jeudi de juin).
Analyste : Georges TATCHUM.

> Légende statut : ✔ consultée et traitée / ✗ non consultable (motif en remarques) / ☐ planifiée mais non encore consultée.

## Tableau (à coller en §2 du template)

| Source | Consultée | Date dernière publication lue | Nb items remontés (période) | Remarques |
|--------|-----------|------------------------------|------------------------------|-----------|
| CISA KEV Catalog | ✔ | 29/05/2026 | 21 items ajoutés sur mai, 2 potentiellement applicables | Récupération via curl direct du flux JSON officiel https://www.cisa.gov/sites/default/files/feeds/known_exploited_vulnerabilities.json (la page HTML reste bloquée par WAF). Items applicables potentiels (inchangés depuis le 22/05) : CVE-2026-41091 et CVE-2026-45498 (Microsoft Defender). Les 6 ajouts entre 22 et 31/05 (Drupal, Nx Console, TanStack, Daemon Tools Lite, LiteSpeed cPanel, Palo Alto PAN-OS) sont tous hors stack |
| NVD / CVE | ☐ | 22/05/2026 | n/a | Non consulté sur cet exercice. Source de référence consultée indirectement via les advisories spécifiques aux composants stack |
| CERT-FR (ANSSI) | ✔ | 29/05/2026 | 74 items lus sur mai, 4 applicables OneOrtho | Items applicables : CERTFR-2026-AVI-0617 (Symfony 20/05), CERTFR-2026-AVI-0620 (Docker 20/05), CERTFR-2026-AVI-0653 (Symfony 27/05), CERTFR-2026-AVI-0643 (Nginx 26/05). Voir §3 |
| GitHub Security Advisories | ✔ | 22/05/2026 | Multiples (voir détail par composant ci-dessous) | Consultation par composant : Angular, Three.js, php/php-src |
| CISA ICS Medical Advisories | ✗ | 22/05/2026 | n/a | Accès WebFetch retourné HTTP 403 sur https://www.cisa.gov/news-events/ics-advisories (WAF anti-bot). Consultation manuelle requise via navigateur avant validation finale |
| FDA Medical Device Safety | ✗ | 22/05/2026 | n/a | Accès WebFetch retourné HTTP 404 sur https://www.fda.gov/medical-devices/medical-device-safety/safety-communications. Consultation manuelle requise via navigateur avant validation finale |
| ENISA Health sector | ☐ | 22/05/2026 | n/a | Non consulté ce mois. Source à cadence trimestrielle |
| H-ISAC | ✗ | 22/05/2026 | n/a | Accès membre non activé à ce jour |
| Angular Security Advisories | ✔ | 28/05/2026 | 9 items sur mai, 2 applicables runtime + 2 sur poste dev | GHSA-rfh7-fxqc-q52v 14/05 (platform-server, non applicable). Batch 28/05 : 7 advisories dont 2 applicables runtime (GHSA-p3vc-36g9-x9gr DoS digitsInfo, GHSA-692r-grfm-v8x7 XSS Template/Component) et 2 sur extension VS Code (GHSA-q94j-3wj3-4xcm RCE, GHSA-ccq4-xmxr-8hcq Critique Workspace Config, 23/05). Détail en §3 |
| Node.js Security | ✔ | 24/03/2026 | 0 item sur la période | Dernier avis visible : 24 mars 2026. Aucun avis publié entre le 01/05 et le 22/05/2026 |
| PHP Security Releases | ✔ | 07/05/2026 | 1 release sécurité | PHP 8.5.6 publiée le 7 mai 2026. La version utilisée par OneOrtho (`>= 8.1`) doit recevoir un correctif équivalent dans la branche 8.1.x à confirmer manuellement sur https://www.php.net/downloads.php#v8.1 |
| GitHub Advisories `php/php-src` | ✔ | 07/05/2026 | 9 advisories | Tous publiés le 07/05/2026. Détail en §3 du rapport |
| Symfony Security Advisories | ✔ | 29/05/2026 | 20 advisories sur mai (3 batches) | Batch 20/05 : 10 CVE (3 applicables : runtime, routing, security-http). Batch 27/05 : 3 CVE Twig sandbox (Twig présent dans composer.lock, applicables). Batch 29/05 : 7 CVE sur symfony/ux-* (UX absent du composer.lock, non applicables). Détail en §3 |
| Packagist Security Advisories | ✗ | 22/05/2026 | n/a | Page Packagist sans rendu HTML exploitable par WebFetch. À consulter via API https://packagist.org/api/security-advisories ou via Snyk/Dependabot qui consomment cette source |
| MariaDB Security Releases | ✔ | 01/06/2026 | 9 CVE groupe 2026 listées (mise à jour entre 22 et 31/05) | Source GitHub raw : https://raw.githubusercontent.com/mariadb-corporation/mariadb-docs/main/server/security/cve/community-server.md. Changements depuis le 22/05 : ajout de 3 CVE (**CVE-2026-49261 CVSS 10.0**, CVE-2026-48165 et CVE-2026-48163 CVSS 8.0) correspondant à une nouvelle release (11.8.8/11.4.12/10.11.18/10.6.27). Retrait du document de 5 CVE plus anciennes (CVE-2026-21968, 3494, 32710, 34303, 35549) — à reclasser comme antérieures à mai 2026 |
| MSRC Security Update Guide (Patch Tuesday) | ✔ | 12/05/2026 | 68 CVE distinctes affectant Windows Server 2016/2019/2022/2025, dont 6 Critiques | Source exploitée via export CSV manuel `Security Updates 2026-05-22-105057am.csv` (déposé en racine `./wwwroot/`). Patch Tuesday de mai = 12/05/2026, pas de nouvel export entre 22 et 31/05. Détail en §3 du rapport |
| NEMA DICOM Standard Newsroom | ✔ | 22/05/2026 | 0 item sur la période | Pas d'actualité sécurité publiée entre le 01/05 et le 22/05/2026 |
| Recherche NVD filtrée DICOM | ☐ | 22/05/2026 | n/a | Cadence trimestrielle au plan, prochaine consultation prévue fin Q2 2026 |
| Three.js Security Advisories | ✔ | 22/05/2026 | 0 item | "There aren't any published security advisories" (page GitHub vide à la date de consultation) |
| Three.js Releases | ☐ | 22/05/2026 | n/a | Non consulté ce mois (sources releases ≠ sources sécurité, à vérifier en complément si advisory) |
| Dépendances tierces — Snyk SCA | ☐ | 22/05/2026 | À consulter dans la console Snyk OneOrtho | Pas d'accès public à la liste, à récupérer via console Snyk + intégration GitHub Actions du mois écoulé |
| Dépendances tierces — GitHub Dependabot | ☐ | 22/05/2026 | À consulter dans GitHub Security tab de l'org | Pas d'accès public, à compiler depuis l'onglet Security de chaque repo `oneorthomedical/*` |

## Synthèse statuts

- **Sources ✔ consultées** : 12 (CERT-FR, GitHub Advisories, Angular, Node.js, PHP Releases, PHP GitHub Advisories, Symfony, NEMA DICOM, Three.js, CISA KEV, MSRC, MariaDB)
- **Sources ✗ non consultables techniquement** : 3 (CISA ICS, FDA, Packagist)
- **Sources ☐ planifiées / à consulter** : 6 (NVD, ENISA, NVD DICOM, Three.js Releases, Snyk, Dependabot)

## Recommandations à porter en §7 du rapport

1. Mettre en place FreshRSS pour automatiser la consultation des sources accessibles uniquement par RSS (cf. `procedure_agregateur_rss.md`).
2. Mettre à jour la source MariaDB dans le §3.3 du plan : remplacer l'URL `https://mariadb.org/about/security/` par l'URL GitHub raw `https://raw.githubusercontent.com/mariadb-corporation/mariadb-docs/main/server/security/cve/community-server.md`. Compléter le mécanisme de veille par un suivi git du fichier (notifications GitHub si modifié) car les dates par CVE ne sont pas dans le document.
3. Confirmer l'URL FDA Safety Communications (HTTP 404 sur la version inscrite au plan) — accès manuel via navigateur préservé, mais l'URL exacte à inscrire au plan doit être validée.
4. Réaliser les **consultations manuelles** des 3 sources encore non scrapables (CISA ICS, FDA, Packagist) **avant validation finale du rapport** (deadline : 26/05/2026 selon métadonnées).
5. Activer l'accès H-ISAC si pertinent, ou décider explicitement de retirer cette source du §3.2.
6. Compiler les sorties Snyk et Dependabot du mois (consoles internes) et reporter les items en complément du §3 du rapport.
7. Industrialiser l'export MSRC : la méthode CSV manuelle fonctionne mais demande un effort mensuel. Étudier l'API MSRC https://api.msrc.microsoft.com/cvrf/v3.0/ pour automatiser.
