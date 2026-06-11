---
name: threat-intel-review
description: Réalise la revue mensuelle Threat Intelligence OneOrtho (processus PSSI, plan plan_revu_mensuel.md, ISO 27001 A.5.7, contexte MDR 2017/745 / IEC 62304). Consulte les sources de veille du mois, croise chaque CVE/GHSA avec le stack réel (composer.lock, modulesjs, parc MariaDB), priorise via la matrice §4.4, et produit un rapport mensuel unique prêt à coller dans le template Confluence. Déclenche quand l'utilisateur demande de faire la revue/veille threat intelligence d'un mois donné, ou de remplir le rapport mensuel de sécurité.
---

# Workflow — Revue mensuelle Threat Intelligence OneOrtho

## 0. Principes

- Le plan de référence est `plan_revu_mensuel.md` (racine du repo). En cas de doute sur le périmètre, les sources ou la matrice, c'est lui qui fait foi — le lire au démarrage.
- Le rapport produit est un **artefact de traçabilité pour audit**. Toute source consultée laisse une trace, même si elle ne remonte aucun item applicable ("consultée, 0 item" est une preuve d'audit valide).
- Sortie attendue : **un seul fichier rapport** couvrant toutes les sections du template (métadonnées + §1 à §8), déposé dans `utils/hds/cyber/<mois>/rapport_threat_intel_<YYYY-MM>.md`. Voir `report-template.md` pour le squelette.
- Ne jamais inventer une CVE, une date, un CVSS ou une version. Si une donnée manque, la marquer "à compléter" ou "non communiqué" et le signaler.

## 1. Collecter les métadonnées (demander si non fournies)

| Champ | Défaut / convention |
|-------|---------------------|
| Période couverte | Mois calendaire complet (01 au dernier jour) |
| Date de la revue | 1er jeudi du mois suivant (à confirmer) |
| Analyste | Georges TATCHUM |
| Validé par | HK — Responsable Numérique |
| Date de validation | Date de revue + 2 jours ouvrés |
| Ticket Jira | `SEC-THREATINTEL-<YYYY-MM>` lié à la tâche parent `CICD-161`. **Demander le numéro CICD du sous-ticket du mois** (varie chaque mois, ex. CICD-169 pour mai 2026) |

Si une consolidation à mi-mois a déjà été faite et qu'on complète en fin de mois, le préciser dans les métadonnées.

## 2. Détecter le stack réel (croisement d'applicabilité)

Avant toute analyse, lire l'état courant du stack pour pouvoir trancher l'applicabilité :

- `saas_local/app/composer.lock` — liste exhaustive des packages PHP/Symfony installés et leurs versions. `grep '"name": "<vendor>/'` pour confirmer présence/absence d'un composant.
- `saas_local/app/composer.json` — extensions PHP requises (`ext-*`), contraintes de version.
- `saas_local/modulesjs/*/package.json` — 4 planificateurs Angular : plannerHip2D, plannerHip3D, plannerKneeMadison, plannerShoulder3D. Versions Angular (20.3 vs 21.2), Three.js (0.150 → 0.182).
- `curent-mariadb-onserver.md` (racine) — parc MariaDB en production (versions par branche LTS + nombre d'instances).
- Le stack peut évoluer : toujours relire ces fichiers, ne pas se fier à une version mémorisée.

## 3. Périmètre (strict)

**Dans le périmètre** (composants §2.2 du plan) :
Angular, Node.js (runtime build), PHP, Composer, Symfony, MariaDB, Windows Server + IIS (via MSRC), DICOM, Three.js, dépendances tierces critiques (via SBOM / Snyk / Dependabot).

**Hors périmètre — ne PAS produire d'item applicable, classer en "Items hors périmètre" du §3.3** :
- Docker, Nginx (composants de la chaîne CI/build, pas le runtime de production qui est IIS)
- Extensions VS Code et autres outils de poste développeur
- Firebase Hosting / firebase-tools (liens de test interne, pas livrable client)

**Source retirée** : Packagist Security Advisories (simple agrégateur de GitHub Advisories + FriendsOfPHP, déjà couvert par les GitHub Advisories par composant + Snyk + Dependabot).

## 4. Consulter les sources sur la période

Pour chaque source, tenter d'abord l'accès automatisé. Si échec (WAF, 403/404, JS), **lister précisément à l'utilisateur ce qu'il doit consulter manuellement et lui demander de coller le contenu ou de déposer un fichier** dans la racine du repo. Ne jamais marquer une source "non consultée" sans avoir proposé le fallback manuel.

### Sources automatisables

| Source | Méthode qui fonctionne | Note |
|--------|------------------------|------|
| CISA KEV Catalog | `curl -s -A "Mozilla/5.0" -o /tmp/kev.json https://www.cisa.gov/sites/default/files/feeds/known_exploited_vulnerabilities.json` puis filtre Python sur `dateAdded` dans la période. La page HTML est bloquée par WAF, mais le JSON passe en curl | Filtrer ensuite par composant du stack |
| CERT-FR (ANSSI) | WebFetch `https://www.cert.ssi.gouv.fr/feed/` | RSS, fonctionne |
| GitHub Advisories Angular | WebFetch `https://github.com/angular/angular/security/advisories` | |
| GitHub Advisories php/php-src | WebFetch `https://github.com/php/php-src/security/advisories` | |
| Symfony Security Advisories | WebFetch `https://symfony.com/blog/category/security-advisories` | |
| Three.js Security Advisories | WebFetch `https://github.com/mrdoob/three.js/security/advisories` | |
| Three.js Releases | WebFetch `https://github.com/mrdoob/three.js/releases` | |
| Node.js Security | WebFetch `https://nodejs.org/en/blog/vulnerability` | Pagination : la 1re page peut s'arrêter avant la période, le signaler |
| PHP Security Releases | WebFetch `https://www.php.net/ChangeLog-8.php` | |
| NEMA DICOM Newsroom | WebFetch `https://www.dicomstandard.org/news` | |

### Sources nécessitant un fallback manuel

| Source | Pourquoi auto échoue | Fallback à demander |
|--------|----------------------|---------------------|
| MSRC (Windows Server, IIS) | Page JS non scrapable | Demander l'export CSV/XLSX du MSRC Security Update Guide (filtre date du mois). Le déposer en racine. Filtrer en Python : Windows Server 2016/2019/2022/2025 + IIS. Voir §5 |
| MariaDB Community Server | GitHub raw tronque la liste via WebFetch | Demander le fichier `community-server.md` complet en racine (export GitHub `mariadb-corporation/mariadb-docs/server/security/cve/community-server.md`). Lire les CVE 2026 et croiser avec le parc. **Ne pas se fier au WebFetch du raw, il tronque** |
| CISA ICS / ICSMA | WAF 403 | Demander à l'utilisateur de coller la liste des advisories du mois depuis `https://www.cisa.gov/news-events/ics-advisories` |
| FDA Medical Device Safety | 404 / WAF | Demander à l'utilisateur de coller la liste depuis `https://www.fda.gov/medical-devices/medical-device-safety/safety-communications` |
| Snyk SCA | Console interne non publique | Demander l'export du mois depuis la console Snyk OneOrtho |
| GitHub Dependabot | Onglet Security privé | Demander la compilation depuis l'onglet Security des repos `oneorthomedical/*` |

### Sources à cadence réduite (ne pas bloquer si non consultées)

- NVD / CVE : consultée indirectement via les advisories par composant.
- ENISA Health, Recherche NVD filtrée DICOM : cadence trimestrielle.
- H-ISAC : accès membre — marquer "non activé" si pas d'accès.

## 5. Traiter l'export MSRC (Windows Server / IIS)

Quand l'utilisateur fournit le CSV/XLSX MSRC :
- Pour XLSX : `pip install --break-system-packages --quiet openpyxl` si nécessaire, ou demander un CSV (plus simple).
- Filtrer les lignes dont Produit/Plateforme contient `windows server 2016/2019/2022/2025` ou `internet information services`.
- Dédupliquer par CVE (colonne Détails), regrouper par gravité.
- Produire 2 items groupés : un pour les **Critical RCE** (titre = liste des CVE), un pour les **Important** (titre = "MSRC Patch Tuesday <date> — N CVE Important Windows Server", volume + impact dominant).
- Si un nouvel export est fourni un autre jour, **comparer** (ajoutées / retirées / reclassées) avant de réécrire ; si identique sur le périmètre, ne mettre à jour que la référence du fichier source.

## 6. Croiser MariaDB par version

À partir de `community-server.md` (CVE 2026 + versions corrigées par branche) et `curent-mariadb-onserver.md` (parc) :
- Construire une matrice CVE × branche (✗ vulnérable / ✓ fix présent / — branche non affectée) en comparant la version du parc à la version corrigée.
- Une CVE est non applicable seulement si le parc est déjà ≥ version corrigée sur toutes ses branches.
- Plan de remédiation = montée unique de chaque branche vers sa dernière LTS (couvre toutes les CVE cumulatives).
- Grouper en sous-items par tranche de CVSS (≥7 = P3, <7 = P4). Signaler tout CVSS ≥ 9 ou 10 comme point d'attention même si la matrice le classe P3 (exposition interne).

## 7. Analyser et prioriser chaque item

Pour chaque item remonté, après déduplication (cf. §8), évaluer les critères du §4.3 du plan :

| Critère | Comment trancher |
|---------|------------------|
| Composant impacté | Confirmé par croisement stack §2. Absent du stack → §3.3 non applicable, motif "composant non utilisé" |
| Produit concerné | Portail Symfony OneSoftware / plannerHip2D/3D/KneeMadison/Shoulder3D / Infrastructure (Windows Server, MariaDB) |
| Exposition | Internet (portail public via IIS, modules livrés navigateur) / Interne (bases, services) / Hors ligne (dev/build only) |
| Exploit public | Vérifier PoC / advisory. Sinon "Non" |
| Exploité activement (KEV) | Présence catalogue CISA KEV = Oui |
| CVSS | Reporter le score source. Si absent (Symfony ne le publie pas toujours), "non communiqué, à compléter via NVD" |
| Priorité | Matrice §4.4 (voir ci-dessous) |

**Matrice de priorisation §4.4 :**

| Exploité activement (KEV) | CVSS ≥ 7 | Exposition internet | Priorité |
|---|---|---|---|
| Oui | Oui | Oui | P1 (72 h) |
| Oui | Oui | Non | P2 (2 semaines) |
| Non | Oui | Oui | P2 (2 semaines) |
| Non | Oui | Non | P3 (1 mois) |
| Non | < 7 | indifférent | P4 (prochain cycle) |

**Statut "à investiguer"** quand l'applicabilité dépend d'un usage interne non vérifiable depuis le code seul :
- X509Authenticator Symfony (l'auth X509 est-elle utilisée ?)
- Fonctions PHP standard (urldecode, mb_convert_encoding, DOMNode::C14N, mb_check_encoding) — confirmer usage
- Microsoft Defender (est-ce l'antivirus actif sur les serveurs ?)
- Twig sandbox (exécute-t-on des templates fournis par utilisateur ?)
- Endpoint PHP-FPM `/status` (exposé public ?)
Ces items restent P3 par défaut jusqu'à conclusion de l'investigation, et génèrent une décision d'investigation au §6.

## 8. Dédupliquer

Une même CVE peut remonter de plusieurs canaux (ex. CVE Symfony vue par Symfony Advisories + CERT-FR + Snyk + Dependabot). Avant rédaction :
- Un seul item par CVE/GHSA.
- Champ "Source" = source primaire éditeur en priorité (Angular/Symfony/PHP/MariaDB advisories, MSRC), puis KEV/NVD/CERT-FR, puis canal scanner (Snyk/Dependabot) en dernier recours.
- Mentionner les canaux secondaires en remarque (preuve de défense en profondeur).

## 9. Conventions de rédaction des items

- **Titre d'item = identifiant(s) CVE-/GHSA-**, jamais un nom descriptif. Pour un item groupé, titre composite listant les identifiants (ou, si trop nombreux, identifiant MSRC + date + volume).
- Chaque item du §3.2 (applicable) doit comporter une ligne **"Ticket remédiation"** (valeur par défaut : "À créer en Jira, lié à CICD-<numéro du mois>").
- Chaque item du §3.3 (non applicable) doit comporter un **motif explicite** de non-applicabilité.
- Items hors périmètre (Docker/Nginx/VS Code) : tracés dans un tableau dédié du §3.3 avec motif "hors périmètre du plan", jamais comptés en applicables.

## 10. Rédiger le rapport unique

Remplir `report-template.md` section par section, dans `utils/hds/cyber/<mois>/rapport_threat_intel_<YYYY-MM>.md` :
- **Métadonnées** (§1)
- **§1 Résumé exécutif** : 3 à 5 lignes — nombre d'items examinés, nombre d'applicables, priorité max, décisions clés. Pas de préambule.
- **§2 Sources consultées** : tableau de TOUTES les sources avec statut (✔/✗/☐), date dernière publication lue, nb items remontés, remarque. Synthèse des statuts en dessous.
- **§3 Items identifiés** : 3.1 synthèse chiffrée, 3.2 détail applicables (fiches), 3.3 non applicables (par source) + items hors périmètre.
- **§4 Tendances observées** : 5 à 10 lignes, batches éditeur du mois, points d'amplification (parc MariaDB, hétérogénéité Angular), sources rattrapées manuellement.
- **§5 Suivi des items des mois précédents** : "Premier exercice — sans objet" au 1er rapport, sinon statut des tickets ouverts les mois précédents.
- **§6 Décisions et actions** : tableau # / décision / item lié / responsable / échéance / statut. Échéances calculées depuis la date de revue (P1 J+3, P2 J+14, P3 J+30, P4 J+90). Inclure les décisions d'investigation et de compilation des sources internes.
- **§7 Recommandations mois suivant** : points concrets (mise en place FreshRSS, ticket convergence versions, sources à corriger dans le plan, etc.).
- **§8 Export** : rappel publication Confluence (CyberSécurité > PSSI > Threat Intelligence) + PDF SharePoint, nommage `Rapport mensuel - Revue Threat Intelligence - <YYYY-MM>.pdf`.

## 11. Note de validation

Terminer le rapport par une note précisant si la validation DRAFT → VALIDATED est conditionnée à un rattrapage (sources internes Snyk/Dependabot non encore compilées, source manuelle non encore fournie). La bascule en VALIDATED se fait à la date de validation (revue + J+2 ouvrés).

## 12. Garde-fous

- Ne jamais classer un composant hors périmètre (Docker/Nginx/VS Code/Firebase) en item applicable.
- Ne jamais conclure "non applicable" sur une CVE sans avoir vérifié la présence/version du composant dans le stack réel.
- Toute CVE applicable ajoutée au KEV pendant la période → recalcul priorité, potentiellement P1 (72 h) : le signaler explicitement.
- Pour MariaDB et MSRC, ne pas se fier aux fetchs partiels : exiger le fichier complet fourni par l'utilisateur.
- Si une source publique reste inaccessible et que l'utilisateur ne peut pas fournir le contenu, marquer la source "✗ à rattraper avant validation" et le porter en décision §6 — ne pas valider le rapport en l'état.
- Respecter les instructions OneOrtho : aucune donnée patient, aucun secret/token, pseudonymiser tout exemple, mesures métriques, pas d'affirmation de sécurité non sourcée.
