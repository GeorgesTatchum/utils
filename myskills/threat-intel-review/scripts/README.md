# fetch_msrc_cvrf.py

Collecte l'export MSRC du mois via l'API CVRF v3.0 (`https://api.msrc.microsoft.com/cvrf/v3.0/`), filtre sur le périmètre Windows Server / IIS / .NET, croise avec le KEV, et compare le parc Windows au build cible du Patch Tuesday du mois.

Remplace l'export CSV manuel de la Security Update Guide utilisé par le skill `threat-intel-review` (§0bis/§5). Origine : ticket R4 (`hds/cyber/june2026/tickets_recommandations_june2026.md`).

## Pourquoi ce script existe

Le filtre manuel (colonne "Balise" du CSV exporté depuis la Security Update Guide) travaille au niveau composant, pas plateforme. Constaté en juin 2026 : 8 CVE Critiques (dont 7 RCE) touchant réellement Windows Server 2016/2019/2022/2025 sont passées sous ce filtre, leur balise ("Remote Desktop Client", "Device Health Attestation Service") n'étant pas dans la liste blanche. Le script filtre directement sur `ProductStatuses` du CVRF (le produit réellement affecté), ce qui élimine cette classe d'erreur.

Dépendances : bibliothèque standard Python 3 uniquement (pas de `pip install`).

## Démarrage rapide

```bash
python3 fetch_msrc_cvrf.py --month august2026 --dir hds/cyber/august2026/sources
```

Un seul chemin à donner : le dossier `sources/` du mois. Tout le reste se déduit de la convention de nommage déjà utilisée dans ce dossier (`kev_<moisannée>.json`, `parc_windows_<moisannée>.json`, `msrc_<moisannée>.csv`, ...). Le script :

- lit `kev_<moisannée>.json` et `parc_windows_<moisannée>.json` s'ils existent déjà dans `--dir` (sinon les ignore, avec un message explicite — aucun des deux n'est obligatoire) ;
- écrit `msrc_<moisannée>.csv`, `msrc_cvrf_raw_<moisannée>.json`, et `comparaison_parc_windows_<moisannée>.md` (ce dernier seulement si un relevé parc a été trouvé).

Peut être lancé depuis n'importe quel répertoire (chemins relatifs ou absolus) ; `--dir` est créé s'il n'existe pas.

## Arguments

| Argument | Obligatoire | Rôle |
|---|---|---|
| `--month` | oui | `<moisannée>` ex. `august2026`, ou directement un ID CVRF ex. `2026-Aug` |
| `--dir` | non* | Dossier `sources/` du mois : dérive tous les chemins ci-dessous par convention |
| `--out` | non* | CSV de sortie (`msrc_<moisannée>.csv`) |
| `--kev` | non | `kev_<moisannée>.json` déjà téléchargé, pour la colonne "Dans KEV" |
| `--raw-out` | non | Dépose le CVRF brut (JSON) ici, pièce probante d'audit |
| `--fleet` | non | Relevé du parc Windows du mois (format ci-dessous) |
| `--fleet-report` | non | Fragment Markdown de comparaison parc/build cible (nécessite `--fleet`) |

*`--out` est requis si `--dir` n'est pas fourni. Chaque flag explicite garde priorité sur ce que `--dir` aurait déduit — utile pour ne surcharger qu'un seul chemin, ou si `sources/` ne suit pas la convention.

## Fichier `msrc_<moisannée>.csv` (sortie)

Une ligne par CVE du périmètre, dédupliquée, colonnes :

| Colonne | Contenu |
|---|---|
| Date de publication / Dernière mise à jour | Issues de `RevisionHistory` du CVRF |
| Numéro CVE / Numéro CVE (Link) | Identifiant + lien Update Guide |
| Titre CVE | `Title.Value` |
| Impact | Type d'impact (RCE, EoP, ...) sur les plateformes du périmètre |
| Gravité max. | Sévérité la plus haute parmi les plateformes du périmètre affectées |
| Action utilisateur requise | Note "Customer Action Required" du CVRF |
| Plateformes affectées | Liste nominative des plateformes Windows Server/IIS/.NET affectées (remplace la "Balise" du CSV manuel, imprécise) |
| Exploitation | Statut d'exploitation publique/active si documenté |
| Dans KEV | oui / non / "non vérifié" si `--kev` non fourni |
| KB / build correctif | Une entrée par plateforme : `<plateforme>: KB<id> (build <FixedBuild>)` |

Compatible avec le traitement §5 du skill (dédup CVE, regroupement par gravité) : mêmes colonnes de base que l'export manuel, colonnes en plus.

## Comparaison parc (`--fleet` / `--fleet-report`)

### Format du relevé (`parc_windows_<moisannée>.json`)

```json
{
  "date_releve": "2026-07-06",
  "serveurs": [
    {"nom": "WEBPRODDEDIENNE", "os": "Windows Server 2025", "environnement": "prod",
     "CurrentBuild": "26100", "UBR": "32860"}
  ]
}
```

`CurrentBuild`/`UBR` = sortie telle quelle, sur chaque serveur, de :

```powershell
Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' |
  Select-Object ProductName, CurrentBuild, UBR
```

`os` accepte les variantes MSRC (`Windows Server 2022 (Server Core installation)`) et les éditions courantes (`Windows Server 2016 Standard`, `Datacenter`, `Essentials`) : normalisées en interne, aucune transformation à faire à la saisie.

À déposer en **instantané daté par mois** dans `sources/`, jamais en fichier "current" unique en racine — voir le problème de traçabilité que ça a causé pour l'inventaire MariaDB (`curent-mariadb-onserver.md`, ticket R7). Un relevé par mois = une pièce probante par mois, cohérente avec l'état réel au moment de la revue.

### Ce que produit la comparaison

Pour chaque OS présent dans le relevé, le script prend le build le plus élevé trouvé dans les `Remediations` du CVRF du mois (gère un éventuel correctif hors-bande), et classe chaque serveur :

- **Couvert** : `CurrentBuild.UBR` du serveur ≥ build cible du mois pour son OS
- **Résiduel** : en retard, avec le build constaté et le build cible
- **Non comparé** : OS du relevé non reconnu dans le CVRF du mois (à vérifier manuellement)

Le fragment Markdown produit (`comparaison_parc_windows_<moisannée>.md`) est prêt à coller dans le rapport, au §5 / à la décision de remédiation MSRC.

### Limites connues

- Suppose une base `10.0.x.y` (valable Windows Server 2016 et plus récent). Ne couvre pas un éventuel WS2012 en ESU (base `6.2`/`6.3`) — absent du parc actuel, donc sans impact aujourd'hui.
- Restreint volontairement la comparaison aux plateformes `Windows Server*` : .NET/ASP.NET ont leur propre versionnage (pas de build.UBR par OS), non comparable à un `CurrentBuild`/`UBR` de serveur — ils sortent dans `msrc_<moisannée>.csv` mais pas dans la comparaison de parc.
- Le relevé du parc reste une saisie manuelle serveur par serveur (aucune collecte centralisée en place) — cf. ticket R9.

## Comportement en cas d'échec

Si l'API MSRC est injoignable ou renvoie une erreur, le script s'arrête (code de sortie 1) avec un message explicite sur stderr. Revenir alors au fallback manuel décrit au §0bis/§5 du `SKILL.md` (export CSV depuis la Security Update Guide).

## Voir aussi

- `SKILL.md` (§0bis, §5) — intégration au flux de revue mensuelle
- `hds/cyber/june2026/tickets_recommandations_june2026.md` — R4 (ce script) et R9 (relevé du parc)
- `hds/cyber/june2026/rapport_threat_intel_june2026.md` — addendum du 04/09/2026, premier cas d'usage documenté (8 CVE Critiques retrouvées, confirmation indépendante du ratio 16/19)

---

# fetch_dependabot_alerts.py

Collecte les alertes Dependabot des repos `oneorthomedical/*` via l'API GitHub, pour un mois donné, et produit les fichiers SCA de la revue mensuelle.

Remplace la compilation manuelle depuis l'onglet Security utilisée en juin 2026 (§3.2/§6ter du `SKILL.md`). Origine : ticket R6 (`hds/cyber/june2026/tickets_recommandations_june2026.md`), décision documentée dans `hds/cyber/june2026/README_pivot_sca_dependabot.md`.

Dépendances : bibliothèque standard Python 3 uniquement (pas de `pip install`).

## Pourquoi ce script existe

Dependabot est le **pivot unique de collecte** de la revue depuis l'arbitrage du 07/09/2026 : c'est le seul canal SCA qui fournit simultanément le paquet, la portée runtime/build, la version corrigée, le CVSS et une URL auditable par item. Snyk reste un gate CI (hors collecte mensuelle) et Dependency-Track sert de preuve SBOM/VEX et de contrôle de complétude. La compilation manuelle de juin (45 alertes pour one-platform, 177 CVE tous repos) laissait par ailleurs deux angles morts : la portée runtime/build déterminée par heuristique sur one-platform (lockfile indisponible localement) et l'absence de constat sur un repo dont les alertes seraient désactivées.

## Démarrage rapide

```bash
export GH_TOKEN=...    # portée security_events (repo privé : repo) ; sinon `gh auth login`

# extraction de reference : alertes OUVERTES a la fin du mois (equivaut au is:open de l'interface)
python3 fetch_dependabot_alerts.py --month july2026 --dir hds/cyber/july2026/sources

# meme chose a la date de collecte reelle, si la revue est faite en decale
python3 fetch_dependabot_alerts.py --month july2026 --dir hds/cyber/july2026/sources --as-of 2026-08-04

# complement facultatif : uniquement les alertes APPARUES dans le mois
python3 fetch_dependabot_alerts.py --month july2026 --dir hds/cyber/july2026/sources --mode nouveau
```

Le jeton est lu dans `GH_TOKEN`/`GITHUB_TOKEN`, sinon obtenu via `gh auth token`. Il n'est jamais journalisé ni écrit dans les sorties.

Attention, les deux modes écrivent sous les **mêmes noms de fichiers** : un run en `--mode nouveau` écrase l'extraction de référence du même mois. Lancer le mode de référence en dernier, ou déplacer les sorties du complément.

## Arguments

| Argument | Obligatoire | Rôle |
|---|---|---|
| `--month` | oui | `<moisannée>` ex. `july2026`, `august2026`, ou `2026-07` |
| `--dir` | oui | Dossier `sources/` du mois : reçoit les sorties, fournit `kev_<moisannée>.json` s'il y est déjà |
| `--owner` | non | Organisation GitHub (défaut `oneorthomedical`) |
| `--repos` | non | Liste séparée par des virgules (défaut : `one-platform,plannerHip2D,plannerHip3D,plannerKneeMadison,plannerShoulder3D`) |
| `--mode` | non | `instantane` (défaut) ou `nouveau`, cf. ci-dessous |
| `--kev` | non | `kev_<moisannée>.json` déjà téléchargé — déduit de `--dir` si présent |
| `--as-of` | non | Date de l'instantané (`AAAA-MM-JJ`) au lieu de la fin du mois, quand la collecte est faite en décalé. La date effective est inscrite dans le fragment pivot. |

## `open` n'est pas « apparue ce mois-ci »

Confusion à lever avant toute extraction, parce qu'elle change l'ensemble traité du tout au tout.

* **`open` est un état.** C'est le filtre `is:open` de l'interface GitHub : tout ce qui n'est ni corrigé ni rejeté, **quel que soit l'âge de l'alerte**. Une alerte apparue en mars 2026 et jamais corrigée est toujours `open` en septembre.
* **`created_at` est une date d'apparition.** Deux axes indépendants.

Mesuré sur août 2026 :

| | Alertes |
|---|---|
| Ouvertes au 01/09 (état open, ce que montre l'interface) | 699 |
| Créées en août | 155 |
| **Ouvertes au 01/09 mais apparues avant août** | **547** dont 15 critical et 244 high |

Les 699 alertes ouvertes se répartissent par mois d'apparition : 2023-10 (1), 2024-10 (2), 2025 (4), 2026-01 (13), 02 (41), 03 (97), 04 (35), 05 (66), 06 (90), 07 (198), 08 (152). Assimiler `open` à « apparue ce mois » écarterait 78 % de la dette réelle, et en priorité les items les plus anciens.

L'inverse est vrai aussi : « créée en août » inclut 3 alertes Angular apparues le 03/08 et corrigées le 05/08 (CVE-2026-69151 sur @angular/core et @angular/compiler, CVE-2026-68945 sur @angular/common), qui ne sont pas `open`. Aucun des deux ensembles ne contient l'autre.

## Les deux modes

| Mode | Ce qui est extrait | Usage |
|---|---|---|
| `instantane` (défaut) | Alertes **ouvertes** à la date de référence | **Extraction de référence** : porte les items à traiter, équivaut au `is:open` de l'interface, et reproduit le contenu des CSV de juin |
| `nouveau` | Alertes **créées** dans la fenêtre | Complément : alimente la section « mouvements du mois » du §5, ne remplace pas l'extraction de référence |

**Ne pas mélanger les deux d'un mois sur l'autre**, sinon le §5 compare des ensembles différents.

### Ce que `--as-of` fait dans chaque mode

Son rôle diffère, et c'est la seconde source de confusion :

| Commande | Ce qui est extrait |
|---|---|
| `--month august2026` | Ouvertes au 01/09 (fin du mois) |
| `--month august2026 --as-of 2026-09-07` | Ouvertes au 07/09, **y compris celles apparues en septembre** |
| `--month august2026 --mode nouveau` | Créées du 01/08 au 01/09 |
| `--month august2026 --mode nouveau --as-of 2026-08-15` | Créées du 01/08 au 15/08 (mois partiel) |
| `--month august2026 --mode nouveau --as-of 2026-09-07` | Créées du 01/08 au 01/09 : la date **ne déborde jamais** du mois en mode nouveau, et le script le signale |

En `instantane`, `--as-of` est la date à laquelle on regarde l'état ouvert : une date postérieure au mois est légitime (collecte décalée) et fait entrer les alertes apparues depuis. En `nouveau`, elle ne peut que **rabaisser** la borne haute de la fenêtre de création, jamais l'étendre ; au-delà du mois elle n'a aucun effet et le script l'écrit explicitement au lieu de l'ignorer en silence.

Dans les deux cas la fenêtre effective est inscrite en tête du fragment pivot (« Instantané des alertes ouvertes au … » ou « Alertes créées entre … et … ») : une extraction datée reste rejouable, une extraction implicite ne l'est pas.

### Pourquoi l'API est interrogée sans filtre `state`

Reconstituer l'état ouvert à une date passée exige de connaître les alertes aujourd'hui corrigées ou rejetées : une alerte aujourd'hui `fixed` était ouverte au 30 juin si son `fixed_at` est postérieur. Le script récupère donc tous les états et filtre lui-même.

Piège vérifié au premier essai : `state=all` n'est pas une valeur valide de ce filtre (seules `open`, `fixed`, `dismissed`, `auto_dismissed` le sont) et renvoie **200 avec une liste vide**, indiscernable d'un repo sain. Ne pas réintroduire ce paramètre.

Limite de la reconstitution rétroactive : elle s'appuie sur les alertes encore présentes dans l'API. Une alerte purgée (manifeste ou repo supprimé) est invisible après coup. L'extraction faite au moment de la revue vaut mieux qu'une reconstitution tardive, même argument que le ticket R9 sur le relevé du parc.

## Sorties (dans `--dir`)

| Fichier | Contenu |
|---|---|
| `<repo>_dependabot_alerts_<moisannée>.csv` | Format **identique** aux CSV de juin : pas d'en-tête, 7 colonnes (numéro, état, paquet, écosystème, sévérité, CVE, URL). Le writer a été validé par rejeu octet à octet du CSV one-platform de juin. |
| `dependabot_enrichi_<moisannée>.csv` | Tous repos : + manifeste, portée (`runtime`/`development`), relation (`direct`/`transitive`), score et vecteur CVSS, GHSA, version corrigée, croisement KEV, date de création |
| `dependabot_pivot_<moisannée>.md` | Fragment prêt à coller : fenêtre effective, tableau de couverture par repo, **mouvements de la fenêtre** (apparues / corrigées / rejetées / ouvertes en fin, + ratio corrections sur apparitions pour R2), puis dédup par identifiant pivot **groupé par portée et par lane de traitement** (voir ci-dessous) |
| `dependabot_raw_<moisannée>.json` | Réponses brutes de l'API, pièce probante d'audit |

## Les deux lanes de traitement (SKILL.md §6ter)

Le fragment pivot ne se contente pas de séparer runtime/build : il produit directement les deux lanes de traitement du §6ter, pour que la définition des items du rapport n'ait plus à re-dériver le partage à la main chaque mois.

- **Runtime et mixte/non renseignée** : itemisés un par un (tableau `Identifiant/Paquet/Sévérité/Repos/Version corrigée/KEV`), destinés à une évaluation individuelle (Item 6 du rapport).
- **Build/dev** : compilés en un **lot P4 hygiène** unique, prêt à coller comme un seul ticket (« N identifiants distincts, N paquets, N repos concernés, aucun en KEV »), avec le détail complet en annexe de traçabilité en dessous — remplace la compilation manuelle de `annexe_dependabot_<moisannée>.md`.

**Garde-fou KEV (SKILL.md §6ter)** : un item de portée build/dev présent dans le KEV est **retiré du lot** et sorti dans une section à part, « Garde-fou KEV — retirés du lot P4, traitement individuel P1 ». Une exploitation active documentée ne doit jamais se retrouver noyée dans une compilation d'hygiène groupée, même si son classement runtime/build dirait le contraire. Ce garde-fou ne se déclenche que si `--kev`/`kev_<moisannée>.json` est fourni ; sans lui, le lot est calculé sans cette vérification et le fragment ne le signale pas autrement qu'en listant `dans_kev: non verifie`.

## Validation sur juin 2026

Rejeu du mois de juin (instantané au 2026-07-01) contre les exports manuels de `hds/cyber/june2026/sources/` :

| Repo | CVE communes | Manuel seul | Script seul |
|---|---|---|---|
| one-platform | 37 | 2 | 0 |
| plannerHip3D | 135 | 3 | 0 |
| plannerKneeMadison | 118 | 5 | 0 |
| plannerShoulder3D | 0 | 1 | 0 |

Aucune CVE inventée par le script (colonne « script seul » à 0 partout). Les entrées « manuel seul » ont toutes une `created_at` **postérieure au 30/06** (2 juillet, 3 juillet, 11 et 12 août pour fast-uri CVE-2026-6321/6322) : les CSV classés `june2026` contiennent donc des alertes apparues après la clôture du mois. C'est ce que `--as-of` rend désormais explicite.

`plannerHip2D` et `plannerShoulder3D` n'ont aucune alerte antérieure au 2026-07-03 (la plus ancienne des deux repos est datée du 03/07 à la même minute), ce qui explique l'absence d'export juin pour Hip2D et le fichier quasi vide pour Shoulder3D. Vraisemblablement la date d'activation de Dependabot sur ces deux repos, à confirmer.

## Vérification de couverture

Chaque repo interrogé produit une ligne du tableau de couverture. Un repo en `INACCESSIBLE` (HTTP 404 : repo absent **ou** alertes Dependabot désactivées, GitHub ne distingue pas les deux) ou `REFUSE` (HTTP 403 : portée du jeton insuffisante) est tracé sans interrompre la collecte. C'est le point important : un repo dont les alertes sont désactivées ne renvoie aucune alerte, ce qui est indiscernable d'un repo sain si on ne le constate pas explicitement. `plannerHip2D` n'avait pas d'export en juin : à vérifier au premier passage.

## Limites connues

- Ne voit que ce qui est déclaré dans un manifeste ou un lockfile : un composant vendored ou un fork interne lui échappe (`oneortho/nanodicom`, potentiellement `nifti-reader-js`) — ces composants relèvent du ticket R3.
- Ne couvre pas la couche système (Windows, IIS/.NET, MariaDB) : flux MSRC, cf. `fetch_msrc_cvrf.py` (R4).
- `dependency.scope` peut être absent selon l'écosystème : les items concernés sortent en portée « non renseignée » et sont listés à part dans le fragment pivot, à trancher via le flag `dev` du `package-lock.json` du module. Ne pas présumer runtime ni build.
- Le contrôle de delta Snyk / Dependency-Track reste manuel et doit produire une trace mensuelle même vide (cf. `README_pivot_sca_dependabot.md`).

## Voir aussi

- `hds/cyber/june2026/README_pivot_sca_dependabot.md` — arbitrage, comparaison chiffrée DT/Dependabot, contours de la décision
- `SKILL.md` (§3.2, §6ter) — intégration au flux de revue mensuelle
- `hds/cyber/june2026/annexe_dependabot_june2026.md` — annexe de juin, produite manuellement, que le fragment pivot remplace

---

# compare_sca_delta.py

Contrôle de complétude SCA : compare les exports secondaires (Snyk, Dependency-Track) au pivot Dependabot du mois et produit la trace mensuelle du delta, y compris quand le résultat est vide.

Origine : ticket R6, DoD « trace mensuelle du contrôle de delta ». Le pivot est lu dans `dependabot_enrichi_<moisannée>.csv`, produit au préalable par `fetch_dependabot_alerts.py`.

## Démarrage rapide

```bash
python3 compare_sca_delta.py --month july2026 --dir hds/cyber/july2026/sources \
    --source "dependency-track=hds/cyber/july2026/sources/vex_july2026.cdx.json" \
    --source "snyk=hds/cyber/july2026/sources/snyk_july2026.csv"
```

Produit `delta_sca_<moisannée>.md` dans `--dir`. `--source` est répétable, sous la forme `nom=chemin`.

## Arguments

| Argument | Obligatoire | Rôle |
|---|---|---|
| `--month` | oui | `<moisannée>` ex. `july2026`, `august2026` |
| `--dir` | oui | Dossier `sources/` du mois (contient le CSV enrichi du pivot) |
| `--source` | non, répétable | Export secondaire à comparer, `nom=chemin` (ex. `snyk=...`, `dependency-track=...`) |
| `--pivot` | non | CSV enrichi du pivot — déduit de `--dir`/`--month` si absent |
| `--out` | non | Fragment Markdown de sortie — déduit de `--dir`/`--month` si absent |
| `--repo` | non | Restreint le pivot à ce repo avant comparaison |
| `--portee` | non | `runtime` ou `development` — restreint le pivot à cette portée avant comparaison |

## Restreindre le pivot avant comparaison (`--repo` / `--portee`)

Un export secondaire ne couvre pas forcément le même périmètre que le pivot complet. Cas constaté sur plannerShoulder3D en août 2026 : le SBOM Dependency-Track du projet ne scanne que les dépendances de production (aucune devDependency dans son tableau de composants), alors que le pivot Dependabot par défaut mélange les 5 repos et les deux portées. Comparer 3 CVE DT à 699 identifiants pivot globaux donne un taux de couverture qui ne veut rien dire.

```bash
python3 compare_sca_delta.py --month august2026 --dir hds/cyber/august2026/sources \
    --repo plannerShoulder3D --portee runtime \
    --source "dependency-track=hds/cyber/august2026/sources/vdr_plannerShoulder3D_august2026.cdx.json"
```

La ligne de trace en tête du fragment (« Pivot : N alertes, N identifiants … filtré repo=…, portee=… ») rend le filtre appliqué explicite, pour qu'un lecteur ne prenne pas un taux de couverture calculé sur un périmètre restreint pour un taux global. Sans ce filtre pour ce cas précis, le rapprochement lui-même reste correct (l'union CVE/GHSA n'est pas faussée), c'est l'affichage du dénominateur — et donc l'interprétation du taux de couverture — qui l'est.

## Clé de rapprochement

**Union CVE + GHSA des deux côtés.** C'est le point à ne pas simplifier : sur le rejeu de juin, 16 alertes Dependabot n'ont pas de CVE et ne sont appariables que par leur GHSA ; symétriquement, un advisory Snyk publié avant assignation de CVE ne porte qu'un GHSA. Un rapprochement par CVE seule les compte en résiduels à tort.

Les identifiants sont extraits par balayage du texte de l'export, sans parseur dédié par outil : les exports Snyk (JSON du CLI, CSV de console) et Dependency-Track (VEX CycloneDX) n'ont ni le même schéma ni la même stabilité de schéma, alors que `CVE-…` et `GHSA-…` sont normalisés. Si l'export est un CycloneDX, la sévérité et le début de la description sont récupérés en plus, pour faciliter le classement.

## Sortie

`delta_sca_<moisannée>.md` contient :

1. **La ligne de trace du mois**, à coller au rapport : sources consultées, date, nombre de résiduels. Si aucune `--source` n'est fournie, le fragment écrit explicitement « contrôle de delta non fait ce mois-ci, à porter en rattrapage §6 » plutôt que de ne rien dire. Une source annoncée mais dont le fichier est absent est également listée.
2. Un récapitulatif par source (identifiants, couverts par le pivot, résiduels).
3. Un tableau des résiduels par source, avec deux colonnes à remplir à la main.

## Classement des résiduels

Un résiduel n'est pas un manque par défaut. Quatre cas, à trancher item par item :

1. **Hors périmètre Dependabot** — composant vendored, fork interne, écosystème non couvert. Relève de R3, pas du pivot.
2. **Alias manquant** — même vulnérabilité sous un autre identifiant, non encore aliasé côté source.
3. **Bruit de correspondance NVD/CPE** — produit absent du stack. Cas constaté sur l'export DT de juin : CVE-2022-38778, dont la description porte sur Kibana.
4. **À traiter** — réellement absent du pivot, à intégrer aux items du mois.

C'est le classement qui constitue la preuve, pas le décompte : un résiduel non classé laisse le contrôle incomplet.

## Limites connues

- Le rapprochement est identitaire, pas sémantique : deux advisories décrivant la même faille sous deux identifiants sans alias croisé ressortent en résiduel (cas 2 ci-dessus), c'est attendu et c'est le rôle du classement manuel.
- Un export secondaire couvrant un périmètre plus large que les repos du pivot (autres projets dans la même instance Dependency-Track) produit des résiduels légitimes relevant du cas 1 : filtrer l'export par projet avant comparaison, ou l'assumer au classement.
- Le script ne juge pas la fraîcheur des exports : un VEX généré à une autre date que l'instantané du pivot fausse la comparaison. Vérifié en juin sur l'export DT `one-plateform/develop`, cf. `README_pivot_sca_dependabot.md`.

## Voir aussi

- `fetch_dependabot_alerts.py` (ci-dessus) — produit le pivot comparé ici
- `hds/cyber/june2026/README_pivot_sca_dependabot.md` — pourquoi Dependabot est le pivot et Snyk/DT le contrôle
