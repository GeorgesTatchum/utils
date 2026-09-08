---
name: threat-intel-review
description: Réalise la revue mensuelle Threat Intelligence OneOrtho (processus PSSI, plan plan_revu_mensuel.md, ISO 27001 A.5.7, contexte MDR 2017/745 / IEC 62304). Consulte les sources de veille du mois, croise chaque CVE/GHSA avec le stack réel (composer.lock, modulesjs, parc MariaDB), priorise via la matrice §4.4, et produit un rapport mensuel unique prêt à coller dans le template Confluence. Déclenche quand l'utilisateur demande de faire la revue/veille threat intelligence d'un mois donné, ou de remplir le rapport mensuel de sécurité. Deux modes (cf. §0-router) : « revue complète » (produit le rapport) et « tickets seuls » (génère uniquement le fichier de tickets de remédiation à partir d'un rapport du mois déjà produit par ce skill) — déclenche aussi sur « génère/prépare les tickets de remédiation du mois X ».
---

# Workflow — Revue mensuelle Threat Intelligence OneOrtho

## 0-router. Modes d'invocation (choisir AVANT toute action)

Ce skill a deux points d'entrée. Déterminer le mode dès l'invocation, à partir de la demande de l'utilisateur :

- **Mode « revue complète »** (défaut) : produire le rapport mensuel. Dérouler §0bis → §11. L'argument éventuel = chemin du rapport du **mois précédent** (continuité §5). La génération des tickets (§11bis) est proposée en fin de parcours, en option.

- **Mode « tickets seuls »** : déclenché quand l'utilisateur demande **uniquement** de générer/préparer les tickets d'un mois **dont le rapport a déjà été produit par ce skill** (ex. « génère les tickets de juin », « prépare les tickets de remédiation », « /threat-intel-review tickets june2026 »). Dans ce mode :
  - **Ne PAS relancer** la collecte des sources (§4), ni le croisement stack, ni la rédaction du rapport.
  - **Entrée** = le rapport du mois déjà produit : `utils/hds/cyber/<moisannée>/rapport_threat_intel_<moisannée>.md` (mois ou chemin passé en argument ; si absent, le demander). Lire aussi `jira-ticket-template.md`.
  - **Exécuter uniquement §11bis** : dériver les tickets des items applicables (§3.2) et décisions (§6) du rapport, écrire `utils/hds/cyber/<moisannée>/tickets_remediation_<moisannée>.md`.
  - Si le rapport du mois **n'existe pas** → ne pas fabriquer les tickets : rediriger vers la revue complète (les tickets dérivent du rapport).
  - Relire le stack (composer.lock / package.json) seulement si une version manque dans le rapport ; sinon réutiliser les valeurs déjà croisées.

En cas d'ambiguïté sur le mode voulu, demander (revue complète vs tickets seuls). L'argument passé au skill n'a donc pas le même sens selon le mode : rapport du **mois précédent** (revue complète) vs rapport du **mois courant** à convertir en tickets (tickets seuls).

## 0. Principes

- Le plan de référence est `plan_revu_mensuel.md` (racine du repo). En cas de doute sur le périmètre, les sources ou la matrice, c'est lui qui fait foi — le lire au démarrage.
- Le rapport produit est un **artefact de traçabilité pour audit**. Toute source consultée laisse une trace, même si elle ne remonte aucun item applicable ("consultée, 0 item" est une preuve d'audit valide).
- Sortie attendue : **un seul fichier rapport** couvrant toutes les sections du template (métadonnées + §1 à §8), déposé dans `utils/hds/cyber/<moisannée>/rapport_threat_intel_<moisannée>.md`. Le dossier du mois suit le format **`moisannée`** (ex. `may2026/`, `june2026/`) sous `utils/hds/cyber/`. Voir `report-template.md` pour le squelette.
- Ne jamais inventer une CVE, une date, un CVSS ou une version. Si une donnée manque, la marquer "à compléter" ou "non communiqué" et le signaler.

## 0bis. Intrants et contexte (à préparer au démarrage)

### Arborescence du mois
Travailler dans `utils/hds/cyber/<moisannée>/`, où `<moisannée>` = **nom du mois en anglais, en minuscules, + année** (january2026, february2026, march2026, april2026, may2026, june2026, july2026, august2026, september2026, october2026, november2026, december2026). Confirmer ce nom de dossier avec l'utilisateur (le dériver de la période, ne pas l'imposer). Y créer un sous-dossier **`sources/`** qui reçoit les fichiers à télécharger manuellement. Le skill lit ses intrants **depuis `sources/`**, jamais depuis la racine du repo.

### Orienter l'utilisateur : ressources à déposer dans `sources/`
Au démarrage, **afficher la liste précise des fichiers à télécharger, où les obtenir, et le nom attendu** dans `utils/hds/cyber/<moisannée>/sources/`. Attendre qu'ils soient déposés (ou que l'utilisateur signale ceux qu'il ne peut pas fournir) avant la collecte §4.

| Source (fallback manuel) | Où l'obtenir | Fichier attendu dans `sources/` |
|--------------------------|--------------|--------------------------------|
| MSRC (Windows Server / IIS / .NET) | Semi-auto : `scripts/fetch_msrc_cvrf.py --month <moisannée> --dir .../sources` (un seul chemin ; KEV et relevé parc lus automatiquement s'ils sont déjà dans `sources/` sous leur nom conventionnel). Si l'API échoue : export CSV manuel depuis la Security Update Guide (mêmes colonnes de base) | `msrc_<moisannée>.csv` + `msrc_cvrf_raw_<moisannée>.json` (pièce probante) + `comparaison_parc_windows_<moisannée>.md` si un relevé parc est présent |
| MariaDB Community Server | GitHub `mariadb-corporation/mariadb-docs` → `server/security/cve/community-server.md` (fichier complet, pas le WebFetch qui tronque) | `mariadb_community-server_<moisannée>.md` |
| CISA KEV | `curl` du JSON officiel (`known_exploited_vulnerabilities.json`) — semi-auto | `kev_<moisannée>.json` |
| CISA ICS / ICSMA | Page CISA ICS advisories (WAF bloque WebFetch) → copier la liste du mois | `cisa_ics_<moisannée>.md` |
| FDA Medical Device Safety | Page FDA Safety Communications (WAF) → copier la liste | `fda_safety_<moisannée>.md` |
| Snyk SCA | Console Snyk OneOrtho → export du mois | `snyk_<moisannée>.csv` |
| GitHub Dependabot (pivot SCA, cf. R6) | Semi-auto : `scripts/fetch_dependabot_alerts.py --month <moisannée> --dir .../sources` (jeton `GH_TOKEN`/`GITHUB_TOKEN` ou `gh auth login`). Si l'API échoue (jeton absent, HTTP 403/404) : export manuel depuis l'onglet Security de chaque repo `oneorthomedical/*` | `<repo>_dependabot_alerts_<moisannée>.csv` (par repo, format historique) + `dependabot_enrichi_<moisannée>.csv` + `dependabot_pivot_<moisannée>.md` (lanes de traitement, voir §6ter) |
| Inventaire parc MariaDB (si mis à jour) | Inventaire infra interne | `curent-mariadb-onserver.md` (ou racine) |
| Relevé parc Windows (build/UBR par serveur, si disponible) | Relevé manuel serveur par serveur (`Get-ItemProperty ... CurrentBuild, UBR`), cf. R9 | `parc_windows_<moisannée>.json` — instantané daté du mois, ne pas mutualiser en fichier racine unique. Traité au §5 (`--fleet` du script MSRC) |

Adapter la liste au périmètre réel du mois (une source peut être sans objet). Ces fichiers deviennent aussi des **pièces probantes** (bordereau d'archivage).

### Rapport du mois précédent (contexte / continuité) — fourni en ARGUMENT
Le chemin du rapport du mois précédent est **passé en argument** à l'invocation du skill (le dossier change chaque mois et n'est pas auto-localisable de façon fiable). L'argument peut être un fichier (`rapport_threat_intel_*.md`) ou un dossier de mois (ex. `utils/hds/cyber/may2026/`).
- **Si l'argument est fourni** : lire ce rapport (ou les fichiers `items_identifies_*` / `sections_*` du dossier) et en extraire :
  - les **items ouverts** (tickets P1/P2/P3 non clôturés) → alimentent le §5 « Suivi des items des mois précédents » ;
  - les **items récurrents** (ex. convergence Angular/Three.js, cause racine WSUS/canal de mise à jour) → à re-suivre ;
  - les **décisions/recommandations §6/§7** dont il faut vérifier l'avancement.
- **Si aucun argument n'est fourni** : demander le chemin à l'utilisateur. Ne pas deviner l'emplacement.
- **S'il n'existe pas de rapport précédent** (premier exercice) : le noter et laisser le §5 « Premier exercice — sans objet ».

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
- `saas_local/modulesjs/*/package.json` **et `package-lock.json`** — 4 planificateurs Angular : plannerHip2D, plannerHip3D, plannerKneeMadison, plannerShoulder3D. Les versions divergent entre modules et évoluent vite (Angular 20.3 / 21.2 / 22.0, Three.js 0.150 → 0.185 selon le module). Toujours lire la **version réellement installée dans `package-lock.json`** de chaque module (`packages["node_modules/<pkg>"].version`), pas seulement la contrainte `^x.y` du package.json : `^21.2.5` peut résoudre au-dessus ou en dessous d'un correctif. Le lockfile porte aussi le flag `dev` de chaque paquet (essentiel pour le tri runtime/build de la SCA, cf. §6ter).
- `curent-mariadb-onserver.md` (racine) — parc MariaDB en production (versions par branche LTS + nombre d'instances).
- **Implémentations DICOM réelles** (le mot « DICOM » seul ne suffit pas à trancher) : côté PHP `oneortho/nanodicom` (composer.lock, fork interne), côté JS `nifti-reader-js` (package.json des planners 3D). Un advisory DICOM (DCMTK/OFFIS, OHIF, pydicom/pynetdicom, dcm4che, etc.) n'est applicable que s'il vise **l'une de ces implémentations** : croiser le produit exact, ne pas conclure applicable sur la seule mention « DICOM », ni écarter sans vérifier. Vérifié juin 2026 : DCMTK/OHIF/pydicom non utilisés → non applicables.
- Le stack peut évoluer : toujours relire ces fichiers, ne pas se fier à une version mémorisée. Confirmer un usage runtime en cherchant l'import réel dans le code (`grep -r "from 'mathjs'" src`) quand le flag `dev` ne suffit pas à trancher.

## 3. Périmètre (strict)

**Dans le périmètre** (composants §2.2 du plan) :
Angular, Node.js (runtime build), PHP, Composer, Symfony, MariaDB, Windows Server + IIS (via MSRC), DICOM, Three.js, dépendances tierces critiques (via SBOM / Snyk / Dependabot).

**Hors périmètre — ne PAS produire d'item applicable, classer en "Items hors périmètre" du §3.3** :
- Docker, Nginx (composants de la chaîne CI/build, pas le runtime de production qui est IIS)
- Extensions VS Code et autres outils de poste développeur
- Firebase Hosting / firebase-tools (liens de test interne, pas livrable client)

**Node.js — ne PAS présumer « build only »** : le bundle applicatif est servi par IIS, mais Node.js peut être **installé sur les serveurs Windows** (prod et préprod) pour le build/déploiement ou des services. Vérifié en juin 2026 : Node est présent sur les serveurs, à des versions inférieures au correctif du mois (14 instances ligne 22.x < 22.23.0, plus un Node 16 EOL sur un serveur). Donc : **demander le relevé des versions Node par serveur**, croiser avec le build de correction Node du mois (ligne 22/24/26), et traiter le batch Node comme **applicable** (Item §3.2) si des instances sont en retard. L'exposition dépend du rôle de Node : **si Node ne sert qu'au build** (`npm run build` des modules, bundle ensuite servi par IIS/Symfony), exposition = **hors ligne → P4** (comme la chaîne de build), même avec des CVE High, car aucune fonction réseau vulnérable n'est exercée sur des entrées externes ; ne requalifier vers le haut (P3/P2) que si Node opère un **service réseau**. Un **runtime Node EOL** sur un serveur (ex. Node 16) est un point d'attention supply-chain à traiter hors batch. Les dépendances **transitives** de la chaîne de build npm restent hors ligne (cf. §6ter, tri runtime/build par flag `dev`).

**Source retirée** : Packagist Security Advisories (simple agrégateur de GitHub Advisories + FriendsOfPHP, déjà couvert par les GitHub Advisories par composant + Snyk + Dependabot).

## 4. Consulter les sources sur la période

Pour chaque source, tenter d'abord l'accès automatisé. Si échec (WAF, 403/404, JS), utiliser le **fichier déposé par l'utilisateur dans `utils/hds/cyber/<moisannée>/sources/`** (cf. §0bis). Si le fichier manque, le redemander en rappelant le nom attendu. Ne jamais marquer une source "non consultée" sans avoir proposé le fallback manuel.

### Sources automatisables

| Source | Méthode qui fonctionne | Note |
|--------|------------------------|------|
| CISA KEV Catalog | `curl -s -A "Mozilla/5.0" -o /tmp/kev.json https://www.cisa.gov/sites/default/files/feeds/known_exploited_vulnerabilities.json` puis filtre Python sur `dateAdded` dans la période. La page HTML est bloquée par WAF, mais le JSON passe en curl | Filtrer ensuite par composant du stack |
| CERT-FR (ANSSI) — avis | WebFetch `https://www.cert.ssi.gouv.fr/avis/` puis `/avis/page/2/`, `/page/3/`... | **Le flux `/feed/` n'est qu'une fenêtre glissante (~40 derniers avis)** : il ne couvre PAS tout le mois. Paginer l'archive `/avis/` (≈10 avis/page, ≈5 jours/page) jusqu'à atteindre le 01 du mois. Ne jamais marquer "partiel" pour cause de RSS : le site est accessible, donc combler la fenêtre par pagination. Croiser chaque avis avec le stack |
| CERT-FR (ANSSI) — alertes | WebFetch `https://www.cert.ssi.gouv.fr/alerte/` | **À NE PAS OUBLIER** : les alertes (préfixe ALE) signalent les menaces critiques / activement exploitées (équivalent d'un signal KEV, alimente la décision P1). Lister les ALE actives/mises à jour dans le mois, croiser avec le stack. Une ALE active sur un composant du stack = potentiel P1. Les actualités (`/actualite/`, préfixe ACT) sont des digests non détaillés par CVE, non itemisés |
| GitHub Advisories Angular | WebFetch `https://github.com/angular/angular/security/advisories` | |
| GitHub Advisories php/php-src | WebFetch `https://github.com/php/php-src/security/advisories` | |
| Symfony Security Advisories | WebFetch `https://symfony.com/blog/category/security-advisories` | |
| Three.js Security Advisories | WebFetch `https://github.com/mrdoob/three.js/security/advisories` | |
| Three.js Releases | WebFetch `https://github.com/mrdoob/three.js/releases` | |
| Node.js Security | WebFetch `https://nodejs.org/en/blog/vulnerability` | Pagination : la 1re page peut s'arrêter avant la période, le signaler |
| PHP Security Releases | WebFetch `https://www.php.net/ChangeLog-8.php` | |
| NEMA DICOM Newsroom | WebFetch `https://www.dicomstandard.org/news` | |

### Sources semi-automatisées

| Source | Méthode | Fichier dans `sources/` + traitement |
|--------|---------|--------------------------------------|
| MSRC (Windows Server, IIS, .NET) | `python3 myskills/threat-intel-review/scripts/fetch_msrc_cvrf.py --month <moisannée> --dir utils/hds/cyber/<moisannée>/sources` (API CVRF v3.0, filtre par **produit réellement affecté**, pas par balise/composant — voir §5 ; `--dir` déduit tous les chemins de la convention de nommage, y compris KEV et relevé parc s'ils existent déjà dans ce dossier — pas besoin de les repasser en argument). Lancer début de mois post-Patch Tuesday. Échec API → fallback manuel : export CSV depuis la Security Update Guide | `msrc_<moisannée>.csv` (colonnes enrichies : Plateformes affectées, Exploitation, Dans KEV, KB / build correctif) |
| GitHub Dependabot (pivot SCA) | `python3 myskills/threat-intel-review/scripts/fetch_dependabot_alerts.py --month <moisannée> --dir utils/hds/cyber/<moisannée>/sources` (API REST, mode `instantane` par défaut = alertes ouvertes à la fin du mois ; `--dir` lit `kev_<moisannée>.json` automatiquement s'il existe déjà). Nécessite `GH_TOKEN`/`GITHUB_TOKEN` ou `gh auth login`. Échec API (jeton absent, HTTP 403/404) → fallback manuel : export CSV depuis l'onglet Security de chaque repo | `<repo>_dependabot_alerts_<moisannée>.csv` + `dependabot_enrichi_<moisannée>.csv` + `dependabot_pivot_<moisannée>.md` (lanes de traitement + lot P4 + garde-fou KEV déjà calculés, voir §6ter) |

### Sources nécessitant un fallback manuel

Ces sources sont lues depuis `utils/hds/cyber/<moisannée>/sources/` (fichiers déposés au §0bis).

| Source | Pourquoi auto échoue | Fichier dans `sources/` + traitement |
|--------|----------------------|--------------------------------------|
| MariaDB Community Server | GitHub raw tronque via WebFetch | `mariadb_community-server_<moisannée>.md` (fichier complet) → lire les CVE de l'année et croiser avec le parc. **Ne pas se fier au WebFetch du raw, il tronque** |
| CISA ICS / ICSMA | WebFetch 403 (WAF) | **`curl` fonctionne** avec un User-Agent navigateur : `curl -s -A "Mozilla/5.0 ... Chrome/126 ..." "https://www.cisa.gov/news-events/ics-advisories?page=N"` (paginer N=1,2,3... pour couvrir le mois, ~10 advisories/page). Parser les liens `icsa-YY-DDD-NN` / `icsma-YY-DDD-NN` (l'ID encode l'année YY et le jour de l'année DDD → convertir en date). À défaut : `cisa_ics_<moisannée>.md` collé. **Croiser surtout les ICSMA (médical) et les advisories DICOM** |
| FDA Medical Device Safety | 404 / WAF | `fda_safety_<moisannée>.md` (liste collée) |
| Snyk SCA | Console interne non publique — cf. §6ter, rôle recentré sur le gate CI (contrôle de delta seulement, plus la collecte pivot) | `snyk_<moisannée>.csv` |

Le CISA KEV (`kev_<moisannée>.json`, récupéré par curl) est traité comme source semi-auto : filtre Python sur `dateAdded` dans la période.

### Sources à cadence réduite (ne pas bloquer si non consultées)

- NVD / CVE : consultée indirectement via les advisories par composant.
- ENISA Health, Recherche NVD filtrée DICOM : cadence trimestrielle.
- H-ISAC : accès membre — marquer "non activé" si pas d'accès.

## 5. Traiter l'export MSRC (Windows Server / IIS / .NET)

**Voie normale (script, `sources/msrc_<moisannée>.csv` produit par `fetch_msrc_cvrf.py`)** :
- Le script filtre déjà par **produit réellement affecté** (`ProductStatuses` du CVRF, ex. "Windows Server 2022") plutôt que par balise/composant : périmètre fiable de fait, colonne "Plateformes affectées" nominative. Pas de liste blanche de composants à maintenir.
- Il filtre déjà par mois de publication ("Date de publication" dans la période) et déduplique par CVE.
- Colonne "KB / build correctif" = build cible par OS extrait directement du CVRF (`FixedBuild` des Remediations) : **c'est la source du build du Patch Tuesday du mois**, à comparer telle quelle au build courant du parc (pas de recherche manuelle sur `support.microsoft.com`, plus de risque de confondre avec le build du mois précédent).
- KEV : déjà croisé si `--kev` a été fourni au script (colonne "Dans KEV").

**Fallback manuel (CSV brut exporté depuis la Security Update Guide, si l'API MSRC est indisponible)** :
- Pour XLSX : `pip install --break-system-packages --quiet openpyxl` si nécessaire, ou demander un CSV (plus simple).
- **La colonne "Balise" du CSV est au niveau composant** (ex. "Windows Kernel", "Windows HTTP.sys", "Windows DWM Core Library"), **pas plateforme** : il n'y a pas de colonne "Windows Server 2016/2019/...". Filtrer donc le périmètre = balise contenant `Windows` + composants OS sans préfixe Windows (`.NET`, `ASP.NET Core`, `HTTP/2`, `Winlogon`, `Servicing Stack Updates`, `Active Directory Domain Services`, `Microsoft Graphics Component`, `Microsoft Defender`, `Remote Desktop Client`, `Device Health Attestation Service`...). **Exclure** Edge, Office, SharePoint, Exchange, Visual Studio, Azure*, Dynamics, Copilot, M365, Teams, Android, "Window PC Manager" (produits non installés sur le serveur de prod). **Limite connue (constatée juin 2026)** : cette liste blanche par balise a laissé passer 8 CVE Critiques (dont 7 RCE, balise "Remote Desktop Client") réellement affectées sur le parc Windows Server — la balise ne dit pas quelle plateforme est touchée. En cas de doute sur une balise non listée, ne pas l'exclure sans vérifier son `ProductStatuses` (ou repasser par le script dès que l'API est de nouveau accessible).
- **Filtrer par mois de publication** : l'export contient souvent les mois adjacents (mai + juin + juillet). Ne garder que les CVE dont "Date de publication" tombe dans la période (`datetime.strptime(s,"%b %d, %Y")`).
- Dédupliquer par CVE, regrouper par gravité (colonne "Gravité max." : Critique / Important) et impact ("Exécution de code à distance" = RCE, "Élévation de privilèges" = EoP...).
- **Croiser les CVE de périmètre avec le KEV complet** (pas seulement les ajouts du mois) : garde-fou P1.

**Dans les deux cas** :
- Produire 2 items groupés : un pour les **Critiques** (titre = liste des CVE ; distinguer les RCE de l'éventuel EoP Critique), un pour les **Important** (titre = "MSRC Patch Tuesday <date> — N CVE Important Windows Server", volume + impact dominant). Signaler nommément les CVE RCE Critiques sur composants exposés internet (ex. HTTP.sys derrière IIS).
- **Applicabilité MSRC = par écart de build**, pas en bloc. Une CVE de juin affecte un serveur tant que son build OS < build du Patch Tuesday de juin de son OS. L'applicabilité se démontre par l'écart de build (parc en retard = vulnérable) ; l'intérêt de la revue est de débusquer les serveurs en retard.
- **Statut de remédiation par serveur, attention au piège du "build cible"** : quand l'utilisateur fournit l'état de patch du parc, comparer au **numéro de build du Patch Tuesday DU MOIS COURANT par OS**. Si le CSV vient du script, le prendre directement dans la colonne "KB / build correctif" (une entrée par plateforme, ex. "Windows Server 2022: KB5094128 (build 10.0.20348.5256)") — **ne pas le présumer et ne pas le rechercher à la main dans ce cas**. Sinon (fallback manuel), le récupérer depuis l'historique officiel Microsoft (WebFetch `support.microsoft.com/.../<os>-update-history`, ou recherche `<OS> <mois> <année> patch tuesday KB build`), **ne jamais le présumer**. Points de vigilance validés en juin 2026 :
  - Le **« build cible » d'un inventaire infra correspond souvent au Patch Tuesday du mois PRÉCÉDENT** (l'inventaire suit les items du mois d'avant). Ex. juin 2026 : cible WS2022 = 20348.5139 = **mai** ; le build de **juin** = 20348.5256.
  - **« Patché » dans l'inventaire = "au build de la cible" (mois précédent), PAS "à jour du mois courant"**. Un serveur marqué « Patché » peut être un **résiduel** du mois courant (ex. juin 2026 : WEBPRODDEDIENNE marqué patché mais resté au build de mai 26100.32860, donc non couvert pour juin 26100.32995).
  - Les updates Windows sont cumulatifs, mais cela ne rend « couvert » qu'un serveur dont le build atteint **le build du mois courant** : comparer chiffre à chiffre `CurrentBuild.UBR` au build de juin par OS.
  - Builds Patch Tuesday juin 2026 (référence) : WS2022 20348.5256 (KB5094128), WS2025 26100.32995 (KB5094125), WS2016 14393.9234 (KB5094122).
  Reporter le ratio réel (ex. 16/19), nommer chaque serveur résiduel avec son build et son OS → décision §6 dédiée. Vérifier aussi la **taille réelle du parc** (l'inventaire peut être plus complet que le tableau d'un mois donné).
  **Si un relevé du parc est déposé** dans `sources/parc_windows_<moisannée>.json` (nom, OS, environnement, CurrentBuild, UBR par serveur — cf. R9) **avant** de lancer le script avec `--dir`, il est détecté et traité automatiquement (pas de flag `--fleet` à ajouter à la main) : le script calcule le ratio couvert/résiduel et nomme les serveurs en retard, à coller tel quel depuis `comparaison_parc_windows_<moisannée>.md` dans le rapport (remplace le calcul manuel ci-dessus).
- Si un nouvel export est fourni un autre jour, **comparer** (ajoutées / retirées / reclassées) avant de réécrire ; si identique sur le périmètre, ne mettre à jour que la référence du fichier source.

## 6. Croiser MariaDB par version

À partir de `community-server.md` (CVE 2026 + versions corrigées par branche) et `curent-mariadb-onserver.md` (parc) :
- Construire une matrice CVE × branche (✗ vulnérable / ✓ fix présent / — branche non affectée) en comparant la version du parc à la version corrigée.
- Une CVE est non applicable seulement si le parc est déjà ≥ version corrigée sur toutes ses branches.
- Plan de remédiation = montée unique de chaque branche vers sa dernière LTS (couvre toutes les CVE cumulatives).
- Grouper en sous-items par tranche de CVSS (≥7 = P3, <7 = P4). Signaler tout CVSS ≥ 9 ou 10 comme point d'attention même si la matrice le classe P3 (exposition interne).
- **Pas de doublon §3.2 / §5** : si **aucune nouvelle CVE MariaDB n'est publiée dans le mois** et que la montée décidée un mois précédent n'est pas faite (parc inchangé), ne PAS recréer une fiche §3.2 pour les mêmes CVE. Ce sont un report : suivi au **§5** uniquement (statut de la décision + CVE toujours applicables + point CVSS 10 + plan), avec une simple trace « 0 nouvelle CVE, N CVE de <mois> toujours applicables, voir §5 » en §2 et §3.1. La matrice détaillée reste dans le rapport d'origine (référencer, ne pas la recopier). Ne pas recompter ces CVE dans les priorités P1-P4 du mois courant.

## 6ter. Traiter le pivot SCA Dependabot (arbitrage R6, 07/09/2026)

Dependabot est le **pivot unique de collecte SCA** de la revue mensuelle (ticket R6). Snyk est un gate de prévention en CI, hors collecte mensuelle. Dependency-Track sert de preuve SBOM/VEX et de contrôle de complétude sur le résiduel. Justification complète et contours de la décision : `hds/cyber/june2026/README_pivot_sca_dependabot.md`. Ne pas revenir à la compilation manuelle par portée que ce paragraphe décrivait avant le 07/09/2026 (archivée dans l'historique git) : `fetch_dependabot_alerts.py` fait maintenant le tri, le lot et le garde-fou automatiquement.

**Lire `dependabot_pivot_<moisannée>.md`** (produit par le script au §4) plutôt que de retrier les CSV à la main. Il contient déjà, groupés par identifiant pivot (CVE si assigné, sinon GHSA) :

- **Section « Portée runtime »** : un item par identifiant, à évaluer individuellement via la matrice §4.4 après récupération du CVSS (déjà dans le CSV enrichi) et de la version corrigée. Les CVE `@angular/*` runtime sont rattachées à l'item de montée Angular du mois.
  - **Exposition conditionnée à une API / feature précise** : quand l'avis (GHSA) indique une précondition d'exploitation (ex. `math.evaluate/parse` pour mathjs CWE-915, `_.template` pour lodash, une feature SSR pour Angular), **tracer le chemin de code** avant de prioriser : `grep` des API vulnérables (hors node_modules) + suivre le flux de données. Si la feature vulnérable n'est **pas utilisée**, l'item est **non exploitable dans l'usage actuel** → requalifier en **P4 « montée d'hygiène »**, pas à la priorité nominale du CVSS. Documenter la conclusion (auteur + date + preuve : grep, flux). Requalifier vers le haut seulement si la feature vulnérable est introduite. Exemple juin 2026 : mathjs 15.1.1 (Hip3D) requalifié P2 → P4.
- **Section « Lot P4 hygiène — portée build/dev »** : déjà compilé par le script en un item unique, prêt à coller (nombre d'identifiants, de paquets, de repos concernés). **Scinder le lot par responsable** quand les repos relèvent de Tech Leads différents (ex. `one-platform` vs les planificateurs Angular) : un sous-item + un ticket par Tech Lead, en reprenant le volume par repo depuis le tableau de détail du fragment.
- **Section « Garde-fou KEV »** (si non vide) : items build/dev retirés du lot parce que présents au KEV — traiter chacun individuellement en P1, jamais dans le lot d'hygiène.
- **Section « Portée mixte / non renseignée »** : `dependency.scope` absent côté API pour ces items — trancher runtime/build à la main via le flag `dev` du `package-lock.json` du module avant de les classer dans l'une des deux lanes ci-dessus.

**Contrôle de complétude Snyk / Dependency-Track (mensuel, pas de collecte)** : `compare_sca_delta.py --month <moisannée> --dir .../sources --source "snyk=..." --source "dependency-track=..."` produit `delta_sca_<moisannée>.md` : ligne de trace à coller au rapport (sources consultées, date, N résiduels), et le classement des résiduels en 4 cas (hors périmètre Dependabot → R3 ; alias manquant ; bruit NVD/CPE ; réellement à traiter). Si l'export Dependency-Track d'un projet est scopé production seule (signe : son tableau de composants n'a aucune devDependency), passer `--repo <repo> --portee runtime` pour ne pas comparer des périmètres différents (cas constaté sur plannerShoulder3D : 33/34 alertes Dependabot en portée build, DT scanné en runtime seul). Sans source fournie, le fragment consigne explicitement « contrôle non fait » plutôt que de rester muet — ne jamais l'omettre en silence.

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
- **Tickets Jira** : si l'utilisateur demande de préparer les tickets de remédiation, utiliser `jira-ticket-template.md` (et, pour un export groupé en fichier `.md`, voir l'option §11bis). Les tickets suivent **4 champs Jira** : Description, Environnement, Analyse du bug, Raison du blocage/décision. Un ticket par item P1/P2/P3, un ticket lot pour les P4, un ticket par groupe (MSRC, MariaDB). Pas de ticket pour les items non applicables.
  - Le champ **« Analyse du bug »** suit le mode opératoire OneOrtho : méthode des **« 5 pourquoi » en 6 points** (1. Que s'est-il passé dans le code ? · 2. Pourquoi le bug s'est-il produit ? · 3. Pourquoi cette cause ? · 4-5. causes profonde/fondamentale, facultatives · 6. Analyse finale). Adaptation vulnérabilité tierce : « le bug » est la faille du composant amont (SOUP), la chaîne de causes porte sur l'exposition via la dépendance + la latence de patch. Ne jamais fabriquer de cause « erreur humaine » interne pour une CVE amont. Pour un Spike, points 4-6 à finaliser après investigation.
- **Items levés après investigation** : un item « à investiguer » qui revient non applicable (composant/brique non utilisé, ou version déjà corrigée) va en §3.3 dans une sous-section dédiée « Items levés après investigation » avec auteur + date + justification, **sans ticket de remédiation**. La décision d'investigation correspondante au §6 passe au statut « Fait — non applicable ». Si la justification invoque un numéro de version, **le recouper avec composer.lock / package.json** : en cas d'écart (repo non synchronisé avec la prod), conserver la justification de non-usage comme primaire et signaler l'écart en §7.
- **Applicabilité ≠ statut de remédiation** : un item peut être **applicable** (donc gardé au registre §3.2 avec sa priorité, qui traduit la gravité intrinsèque) **et déjà remédié** (au moment de la revue). Ne pas le supprimer sous prétexte qu'il est patché ; ajouter une ligne **« Statut au <date> »** (remédié / en cours N/M serveurs / à faire). La priorité reste celle de la matrice ; le statut porte le risque réellement résiduel. Ne jamais présenter les deux de façon contradictoire (ex. mentionner une CVE en P2 puis « non applicable car patché » : c'est « applicable P2, remédié »).

## 10. Rédiger le rapport unique

Remplir `report-template.md` section par section, dans `utils/hds/cyber/<moisannée>/rapport_threat_intel_<moisannée>.md` :
- **Métadonnées** (§1)
- **§1 Résumé exécutif** : nombre d'items examinés, nombre d'applicables, priorité max, décisions clés. Pas de préambule. Ajouter une phrase **« Statut de remédiation au <date> »** quand des items sont déjà (partiellement) corrigés, pour ne pas laisser croire à une contradiction avec les priorités. Étayer le « 0 P1 » par la double absence KEV **et** alerte CERT-FR active sur le stack.
- **§2 Sources consultées** : tableau de TOUTES les sources avec statut (✔/✗/☐), date dernière publication lue, nb items remontés, remarque. Synthèse des statuts en dessous.
- **§3 Items identifiés** : 3.1 synthèse chiffrée, 3.2 détail applicables (fiches), 3.3 non applicables (par source) + items hors périmètre. **§3.2 = découvertes de la période** : une source sans nouvelle CVE dans le mois, dont la remédiation d'un item antérieur est encore ouverte, ne génère PAS de fiche §3.2 (ce serait un doublon du §5) ; la tracer « 0 nouvelle CVE, voir §5 » et la suivre au §5. Ne pas recompter ces reports dans les P1-P4 du mois.
- **§4 Tendances observées** : 5 à 10 lignes, batches éditeur du mois, points d'amplification (parc MariaDB, hétérogénéité Angular), sources rattrapées manuellement.
- **§5 Suivi des items des mois précédents** : renseigné à partir du rapport du mois précédent lu au §0bis (tickets P1/P2/P3 ouverts + items récurrents + décisions §6/§7 à suivre). **Suivre aussi les tickets d'amélioration (§7)** ouverts les mois précédents avec leur statut : c'est ce qui empêche une recommandation de « revenir » indéfiniment. Une reco qui réapparaît alors que son ticket est ouvert = signal d'escalade (porteur/horizon à revoir), pas une nouvelle ligne. "Premier exercice — sans objet" seulement si aucun rapport précédent n'existe.
- **§6 Décisions et actions** : tableau # / décision / item lié / responsable / échéance / statut. Échéances calculées depuis la date de revue (P1 J+3, P2 J+14, P3 J+30, P4 J+90). Inclure les décisions d'investigation et de compilation des sources internes.
- **§7 Recommandations mois suivant** : points concrets (mise en place FreshRSS, ticket convergence versions, sources à corriger dans le plan, etc.). **Chaque recommandation porte un ticket de suivi** (ID existant ou « à créer »), un **responsable** et un **horizon** (trimestre). Distinguer des tickets de remédiation : ce sont des tickets d'**amélioration** persistants sous un Epic dédié (cf. variante `jira-ticket-template.md`). Une recommandation **récurrente** ne se re-décrit pas : référencer son ticket standing et reporter son statut. Une recommandation qui revient **sans** ticket est un angle mort → lui créer un ticket. Éviter les doublons (vérifier l'existant, ex. `ARCH-VERSIONS-CONVERGENCE`).
- **§8 Export** : rappel publication Confluence (CyberSécurité > PSSI > Threat Intelligence) + PDF SharePoint, nommage `Rapport mensuel - Revue Threat Intelligence - <YYYY-MM>.pdf`.

## 11. Note de validation

Terminer le rapport par une note précisant si la validation DRAFT → VALIDATED est conditionnée à un rattrapage (sources internes Snyk/Dependabot non encore compilées, source manuelle non encore fournie). La bascule en VALIDATED se fait à la date de validation (revue + J+2 ouvrés).

## 11bis. Option — générer les tickets de remédiation dans un fichier .md

Cette section est **la routine exécutée en Mode « tickets seuls » (§0-router)** ; elle peut aussi être lancée en fin de revue complète. Elle est **indépendante de la collecte** : elle ne consomme que le rapport du mois déjà produit. Le rapport (§10) reste le livrable par défaut. Elle produit deux fichiers distincts du rapport (ne pas fusionner) : `tickets_remediation_<moisannée>.md` (items §3.2/§6) et `tickets_recommandations_<moisannée>.md` (recommandations §7). **En fin de revue complète, proposer automatiquement de générer ces deux fichiers** (sans les créer d'office : attendre le feu vert). En Mode « tickets seuls », générer selon la demande (remédiation, recommandations, ou les deux).

Mode opératoire :
- **Source** = les items applicables du rapport du mois (fiches §3.2 + décisions §6). Ne rien réinventer : reprendre CVE/GHSA, composant + version (croisement stack), produit, exposition, priorité, échéance, responsable déjà établis.
- **Un bloc ticket par item**, au format `jira-ticket-template.md` (résumé `[SEC][P{n}][{Composant}] {CVE} - {action} (Threat Intel {YYYY-MM})` + les 4 champs Jira : Description, Environnement, Analyse du bug en 5 pourquoi/6 points, Raison du blocage/décision). Un `##` par ticket avec la ligne de résumé.
- **Portée des tickets** (règles §9 + template) :
  - 1 ticket par item **P1/P2/P3** ; items partageant une remédiation unique (ex. montée Angular couvrant plusieurs CVE, MSRC Patch Tuesday, montée MariaDB, lots build par Tech Lead) = **1 ticket groupé**.
  - **P4** = 1 ticket « lot P4 » (ou 1 par lot déjà constitué, ex. build one-platform vs modules Angular).
  - **À investiguer** = 1 ticket **Spike** (variante du template) ; pas de ticket de remédiation tant que non conclu.
  - **Non applicables** et **reports §5 dont le ticket existe déjà** (ex. MariaDB monté en décision d'un mois précédent) : **pas de nouveau ticket** ; le noter en tête de fichier.
- **En-tête du fichier** : rappeler la période, le ticket parent `SEC-THREATINTEL-<YYYY-MM>` / CICD du mois, la date de revue (pour les échéances J+n), et un sommaire des tickets (résumé + priorité + responsable).
- **Regrouper par responsable** quand utile (Tech Lead Symfony / Angular / one-platform / DevSecOps+infra), pour faciliter l'assignation.
- Rappeler que le fichier est un **brouillon à coller dans Jira**, pas une création automatique de tickets.

**Tickets de recommandation (§7)** — produire un fichier **distinct** `utils/hds/cyber/<moisannée>/tickets_recommandations_<moisannée>.md`, à partir des recommandations §7 (et des tickets d'amélioration suivis au §5) :
- Un bloc par recommandation, au format **variante « recommandation / amélioration »** de `jira-ticket-template.md` (pas de 5 pourquoi ; champs Contexte & objectif, Definition of Done, Bénéfice/risque si non traité, Horizon+responsable, Récurrence).
- **Réutiliser le ticket standing** d'une recommandation récurrente (ne pas en créer un nouveau) : reprendre son ID et mettre à jour statut/récurrence. N'émettre de nouveau ticket que pour une recommandation **sans** ticket existant.
- Type Story/Task (persistante) rattaché au **ticket de session du mois `SEC-THREATINTEL-<YYYY-MM>`** (même clé que les tickets de remédiation, ex. CICD-170), horizon trimestriel (pas de SLA J+n). En-tête = période, ticket de session de rattachement, sommaire (titre + thème + owner + horizon + récurrence + statut).
- But explicite : donner à chaque recommandation un porteur et une échéance pour qu'elle cesse de revenir faute de visibilité (cf. §7).

## 12. Garde-fous

- Ne jamais classer un composant hors périmètre (Docker/Nginx/VS Code/Firebase) en item applicable.
- Ne jamais conclure "non applicable" sur une CVE sans avoir vérifié la présence/version du composant dans le stack réel.
- Toute CVE applicable ajoutée au KEV pendant la période → recalcul priorité, potentiellement P1 (72 h) : le signaler explicitement.
- Pour MariaDB et MSRC, ne pas se fier aux fetchs partiels : exiger le fichier complet fourni par l'utilisateur.
- Si une source publique reste inaccessible et que l'utilisateur ne peut pas fournir le contenu, marquer la source "✗ à rattraper avant validation" et le porter en décision §6 — ne pas valider le rapport en l'état.
- **Couverture complète sur fenêtre glissante** : quand une source (RSS, page paginée) ne renvoie qu'une fenêtre récente, paginer l'archive jusqu'à couvrir tout le mois avant de conclure. Ne jamais marquer "partiel" si le site est accessible : la lacune se comble, elle ne se subit pas. Pour CERT-FR, couvrir `/avis/` ET `/alerte/` (les alertes = exploitation active, alimentent le P1).
- **Passe de cohérence finale** : après toute mise à jour (statuts, nouveaux items, retrait), relire section par section et vérifier que les décomptes concordent — synthèse des sources §2 (nb ✔/✗/☐ = lignes du tableau), tallies §3.1 (applicables / non applicables / à investiguer / P1-P4), et que le résumé §1 raconte la même histoire que le détail. Un chiffre affiché dans une section doit être recalculé, pas recopié d'une version antérieure.
- **Respecter le style OneOrtho** : aucune donnée patient, aucun secret/token, pseudonymiser tout exemple, mesures métriques, **pas de tiret cadratin (—)**, pas d'affirmation de sécurité non sourcée.
