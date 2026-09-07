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
