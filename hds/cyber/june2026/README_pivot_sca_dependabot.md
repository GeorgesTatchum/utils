# Choix de Dependabot comme pivot de collecte SCA (ticket R6)

Document à joindre au ticket Jira R6 (rattaché à SEC-THREATINTEL-2026-06 / CICD-170).

## Contexte

Le plan de revue déclare trois canaux SCA au même niveau : Snyk SCA en workflow GitHub Actions (à chaque build), GitHub Dependabot (continu, sur push) et, depuis mai 2026, Dependency-Track (SBOM). En juin, la compilation a été manuelle (45 alertes pour one-platform, 177 CVE distinctes tous repos confondus) et Snyk n'a pas été fourni, ce qui a conditionné la validation du rapport.

Le problème réel n'est pas l'absence d'outil mais la réconciliation : les trois canaux remontent en partie les mêmes vulnérabilités sans les qualifier de la même façon (identifiants propres à l'éditeur côté Snyk, classification de sévérité propre, absence de CVE sur certains advisories). Le coût est un filtrage manuel non soutenable à chaque revue.

État réel de l'outillage au 07/09/2026 : Dependency-Track 4.14.2 est déployé et tous les projets y sont synchronisés, Snyk étant conservé en parallèle. Le retard porte sur la documentation SMQ, qui ne reflète pas encore cette liaison pour tous les projets.

## Comparaison factuelle des deux exports

Comparaison de l'export VEX CycloneDX 1.5 de Dependency-Track (projet `one-plateform`, version `develop`, généré le 07/09/2026) avec `sources/one-platform_dependabot_alerts_june2026.csv` :

| | Dependency-Track (VEX) | Dependabot (CSV) |
|---|---|---|
| CVE distinctes | 96 | 39 |
| Alertes / entrées | 96 | 45 (dont 1 sans CVE) |
| CVE communes | 24 | 24 |
| CVE propres à la source | 72 | 15 |

**Mise en garde méthodologique** : les volumes ne sont pas comparables. Le VEX a été généré le 07/09 sur la branche `develop`, le CSV est l'instantané de juin, et une vingtaine des CVE propres à DT ont été publiées après juin (les CVE-2026-673xx le 01/08, CVE-2026-84292 le 02/09). Ce qui est exploitable, c'est la nature des écarts, pas leur nombre.

## Ce que l'export VEX ne fournit pas

* **Aucune attribution au composant** : tous les `affects[].ref` pointent vers l'unique bom-ref du projet (`type: file`), pas vers le paquet vulnérable. L'annexe de juin, organisée par paquet et par portée, n'est pas reproductible depuis ce fichier.
* **Aucun bloc `analysis`** : ni state, ni justification, ni response sur aucune entrée. Ce n'est pas un VEX porteur de décisions mais une liste de vulnérabilités au format VEX ; il ne peut pas servir de registre d'exclusion.
* Pas de portée runtime/build, pas de champ version corrigée (l'information n'est qu'en texte libre dans la description), pas d'URL par item.
* Version suivie : `develop`, pas une version livrée.

## Ce que l'export VEX fournit de mieux

Vecteur et score CVSS v3.1 et v4 quand ils existent (le CSV Dependabot ne porte qu'un mot de sévérité), CWE, description complète, dates de publication et de mise à jour, format normalisé CycloneDX. C'est la matière d'une preuve SBOM/VEX pour le dossier, pas celle d'un triage mensuel.

## Écart de contenu à vérifier (action ouverte)

Les 15 CVE vues seulement par Dependabot portent presque toutes sur des dépendances directes : tinymce (3 high), webpack-dev-server (4), @babel/core, @babel/plugin-transform-modules-systemjs, postcss, qs, form-data, launch-editor, shell-quote (critical). Les 24 communes sont au contraire toutes des transitives profondes (brace-expansion, minimatch, picomatch, node-forge, lodash, fast-uri, ws, yaml, tmp, uuid). À l'inverse, le VEX contient une trentaine de CVE axios dont Dependabot ne signale aucune sur ce repo.

Ce profil suggère que le SBOM chargé dans DT ne correspond pas à l'arbre de dépendances que voit Dependabot. Trois points à contrôler avant de s'appuyer sur DT pour quoi que ce soit de quantitatif :

1. Le projet est nommé `one-plateform` côté DT alors que le repo est `one-platform` : entrée dupliquée, ou SBOM d'une autre origine ?
2. La version suivie est `develop` et non une version livrée.
3. Date de génération du SBOM par rapport au lockfile courant.

Signal de bruit propre au matching NVD de DT, à titre d'illustration : CVE-2022-38778 figure dans le VEX avec une description portant sur Kibana. C'est une correspondance CPE sans rapport avec le périmètre, que la base GHSA de Dependabot ne produit pas.

## Décision retenue

**Dependabot par API est le pivot unique de collecte de la revue mensuelle.** C'est le seul des trois canaux qui fournit simultanément le paquet, la portée runtime/build (`dependency.scope`), la version corrigée, le CVSS et une URL auditable par item.

Rôles des trois outils, à reporter au plan §3 :

| Outil | Rôle | Fréquence |
|-------|------|-----------|
| Snyk SCA | Gate de prévention en CI (GitHub Actions), inchangé | À chaque build |
| GitHub Dependabot | **Pivot de collecte** de la revue mensuelle | Continu, extrait par API à la revue |
| Dependency-Track | Preuve SBOM/VEX au dossier + contrôle de complétude sur le delta | Mensuel (contrôle), trimestriel (preuve) |

Règles associées :

* **Identifiant pivot** : CVE si assignée, sinon GHSA, sinon l'identifiant d'alerte. Sans cet ordre, les advisories sans CVE sont perdues au dédoublonnage (1 cas en juin : serialize-javascript, sévérité high).
* **Sévérité normative** pour la matrice §4.4 : CVSS issu de l'advisory. La sévérité Snyk est une classification propre à l'éditeur, non reproductible par un tiers : signal secondaire, jamais entrée de la matrice. Cohérent avec l'objectif de reproductibilité du ticket R1.
* **Snyk et Dependency-Track ne sont plus traités comme deux listes à réconcilier**, seulement comme un contrôle de complétude sur le résiduel : les findings sans équivalent CVE/GHSA dans le pivot.

## Contours et limites de la décision

**Périmètre de Dependabot, à écrire au plan.** Trois trous structurels, indépendants de la configuration :

* Il ne voit que ce qui est déclaré dans un manifeste ou un lockfile. Un composant vendored ou un fork interne lui échappe : c'est le cas de `oneortho/nanodicom` (fork interne PHP) et potentiellement de `nifti-reader-js`. Ces composants relèvent du ticket R3, pas du pivot. Sans cette mention, « Dependabot n'a rien remonté » sera lu à tort comme « rien à signaler ».
* Un repo dont les alertes ou le dependency graph sont désactivés ne produit aucune alerte, silencieusement, ce qui est indiscernable d'un repo sain. Le script interroge les 4 planificateurs plus one-platform et trace explicitement tout repo inaccessible ; à noter que `plannerHip2D` n'avait pas d'export en juin, à confirmer.
* Il ne couvre pas la couche système (Windows, IIS/.NET, MariaDB), traitée par le flux MSRC du ticket R4.

**Le contrôle de delta doit produire une trace mensuelle, même vide.** Snyk publie des advisories avant ou sans assignation de CVE : le delta n'est pas vide par construction. Un contrôle non consigné est un écart, exactement le motif du retrait de H-ISAC (ticket R8, source documentée au plan sans preuve tracée). Une ligne par mois suffit : sources Snyk et Dependency-Track consultées le JJ/MM, N findings hors périmètre Dependabot, dont X retenus.

**Formulation à respecter côté dossier.** Snyk n'est pas déclassé en outil d'audit : il garde sa fonction active de gate CI à chaque build, qui est ce que le plan et le dossier de soumission décrivent. Seul son rôle dans la collecte mensuelle change. Formulée ainsi, la décision ne touche pas le dossier 510(k) validé qui cite Snyk et ne nécessite pas d'instruction RA préalable.

**Non vérifié dans ce repo** : la lecture ci-dessus suppose que le dossier 510(k) décrit Snyk comme scanner CI et non comme source de la revue de vulnérabilités post-market. À faire confirmer par les Affaires Réglementaires, la formulation exacte du dossier n'étant pas présente dans ce repo.

**Si Dependency-Track devait devenir le pivot** (hors décision actuelle) : l'export VEX est le mauvais endpoint, il faudrait l'API des findings, qui renvoie le couple composant/vulnérabilité avec l'analyse associée. Format de sortie à vérifier sur l'instance 4.14.2 avant de bâtir une procédure dessus.

## Constat de traçabilité relevé au passage

Le rejeu de juin par API (instantané au 01/07) reproduit les exports manuels sans inventer aucune CVE, mais les CSV classés `june2026` contiennent quelques alertes dont la date de création est **postérieure au 30/06** : 2 et 3 juillet, et surtout fast-uri CVE-2026-6321 / CVE-2026-6322 créées les 11 et 12 août 2026. Les exports manuels de juin ne sont donc pas un instantané de juin mais une compilation faite (ou rafraîchie) plus tard, sans date de collecte inscrite.

Même classe de problème que celle traitée par R7 (inventaire MariaDB non daté) et R9 (instantané daté plutôt que fichier « current »). Le script y répond par l'option `--as-of` et par l'inscription de la date d'instantané en tête du fragment pivot.

Autre constat : `plannerHip2D` et `plannerShoulder3D` n'ont aucune alerte Dependabot antérieure au 03/07/2026 (la plus ancienne des deux repos porte la même minute), ce qui explique l'absence d'export juin pour Hip2D et le fichier quasi vide pour Shoulder3D. Vraisemblablement la date d'activation de Dependabot sur ces deux repos, à confirmer côté paramétrage GitHub.

## Outillage livré

`myskills/threat-intel-review/scripts/fetch_dependabot_alerts.py` (07/09/2026) : collecte par API GitHub pour un mois donné, produit le CSV par repo au format de juin (writer validé par rejeu octet à octet du fichier de juin), un CSV enrichi (portée, relation directe/transitive, CVSS, GHSA, version corrigée, croisement KEV), un fragment de pivot dédupliqué groupé par portée, le JSON brut d'audit, et un tableau de couverture par repo. Voir `scripts/README.md`.

`myskills/threat-intel-review/scripts/compare_sca_delta.py` (07/09/2026) : contrôle de complétude. Compare un ou plusieurs exports secondaires (Snyk, Dependency-Track) au pivot du mois sur l'**union CVE + GHSA des deux côtés**, et produit `delta_sca_<moisannée>.md` : ligne de trace du mois, récapitulatif par source, tableau des résiduels à classer en 4 cas (hors périmètre Dependabot → R3 ; alias manquant ; bruit NVD/CPE ; à traiter). Sans source fournie, le fragment écrit explicitement « contrôle non fait, à porter en rattrapage §6 » au lieu de rester muet.

Le rapprochement par CVE seule serait faux : sur le rejeu de juin, 16 alertes Dependabot n'ont pas de CVE et ne sont appariables que par leur GHSA.

Validation sur juin 2026 (instantané au 01/07, comparé aux exports manuels) : 37/39 CVE retrouvées sur one-platform, 135/138 sur plannerHip3D, 118/123 sur plannerKneeMadison, et **zéro CVE ajoutée à tort** sur les 4 repos. Les écarts résiduels sont les entrées postérieures au mois décrites ci-dessus.

Le champ `dependency.scope` de l'API est bien renseigné en pratique (vérifié : l'alerte one-platform #125, http-proxy-middleware, sort en `development` / `transitive`), ce qui lève l'heuristique de portée signalée « à confirmer » dans `annexe_dependabot_june2026.md`. Un reliquat sans portée renseignée reste possible selon l'écosystème : ces items sont listés à part dans le fragment pivot et tranchés à la main via le flag `dev` du lockfile, sans présomption.

## Actions associées

* Ticket Jira R6 : DoD mis à jour dans `tickets_recommandations_june2026.md`
* Plan §3 : rôles des trois outils + limites de périmètre de Dependabot à écrire (non fait à ce stade)
* Plan §4.4 : règle d'identifiant pivot et de sévérité de référence, à coordonner avec R1
* Template de rapport : ligne de trace du contrôle de delta Snyk / Dependency-Track
* Vérification des 3 points d'écart DT ci-dessus, avant tout usage quantitatif de DT
* Documentation SMQ : refléter la liaison Dependency-Track à tous les projets
* Confirmation RA sur la formulation Snyk au dossier 510(k)

## Traçabilité

Origine : Revue Threat Intelligence 2026-06 (SEC-THREATINTEL-2026-06 / CICD-170), ticket de recommandation R6 (`tickets_recommandations_june2026.md`). Sources de la comparaison : `sources/one-platform_dependabot_alerts_june2026.csv`, `annexe_dependabot_june2026.md`, export VEX DT `one-plateform/develop` du 07/09/2026 (fourni hors repo).
