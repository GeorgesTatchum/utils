#!/usr/bin/env python3
r"""
Collecte les alertes Dependabot des repos oneorthomedical via l'API GitHub, pour
un mois donné, et produit les fichiers de la revue mensuelle : le CSV par repo au
format de juin 2026, un CSV enrichi (portée runtime/build, CVSS, version
corrigée), un fragment de pivot dédupliqué CVE/GHSA, et le JSON brut d'audit.

Usage :
    python3 fetch_dependabot_alerts.py --month july2026 --dir hds/cyber/july2026/sources

Dépendances : bibliothèque standard uniquement (pas de pip install).
Jeton : lu dans GH_TOKEN / GITHUB_TOKEN, sinon `gh auth token`. Jamais journalisé.
Portée du jeton nécessaire : security_events (repos privés : repo).
"""

import argparse
import csv
import json
import os
import re
import subprocess
import sys
import urllib.error
import urllib.request
from datetime import datetime, timezone

API_BASE = "https://api.github.com"
USER_AGENT = "OneOrtho-ThreatIntel-Review/1.0 (+outillage interne, cf. ticket R6)"
API_VERSION = "2022-11-28"

DEFAULT_OWNER = "oneorthomedical"
# Repos exportés manuellement en juin 2026 + plannerHip2D, 4e planificateur du
# périmètre §2.2 du plan mais absent des exports de juin : le script l'interroge
# pour que son absence devienne un constat tracé (alertes désactivées ? repo
# renommé ?) au lieu d'un angle mort silencieux.
DEFAULT_REPOS = [
    "one-platform",
    "plannerHip2D",
    "plannerHip3D",
    "plannerKneeMadison",
    "plannerShoulder3D",
]

MONTH_NUM = {
    "january": 1, "february": 2, "march": 3, "april": 4, "may": 5, "june": 6,
    "july": 7, "august": 8, "september": 9, "october": 10, "november": 11,
    "december": 12,
}
SEVERITY_RANK = {"critical": 4, "high": 3, "medium": 2, "low": 1}
KEV_NON_VERIFIE = "non verifie"
PORTEE_NON_RENSEIGNEE = "non renseignee"


def resolve_month(month_arg: str):
    """'july2026' -> (2026, 7). Accepte aussi '2026-07'."""
    s = month_arg.strip().lower()
    m = re.match(r"^(\d{4})-(\d{1,2})$", s)
    if m:
        year, num = int(m.group(1)), int(m.group(2))
    else:
        m = re.match(r"^([a-z]+)(\d{4})$", s)
        if not m or m.group(1) not in MONTH_NUM:
            raise ValueError(f"Format de mois non reconnu : {month_arg!r} (attendu ex. 'july2026' ou '2026-07')")
        year, num = int(m.group(2)), MONTH_NUM[m.group(1)]
    if not 1 <= num <= 12:
        raise ValueError(f"Mois hors bornes : {month_arg!r}")
    return year, num


def filename_month(month_arg: str) -> str:
    """Forme '<moisannée>' utilisée dans sources/ (ex. 'july2026'), quelle que
    soit la forme acceptée par --month."""
    s = month_arg.strip().lower()
    if re.match(r"^[a-z]+\d{4}$", s):
        return s
    year, num = resolve_month(month_arg)
    name = next(k for k, v in MONTH_NUM.items() if v == num)
    return f"{name}{year}"


def month_bounds(year: int, num: int):
    """Bornes UTC du mois : (début inclus, fin exclue)."""
    start = datetime(year, num, 1, tzinfo=timezone.utc)
    end = datetime(year + (num == 12), (num % 12) + 1, 1, tzinfo=timezone.utc)
    return start, end


def parse_ts(value):
    if not value:
        return None
    try:
        return datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError:
        return None


def read_token(env_names=("GH_TOKEN", "GITHUB_TOKEN")) -> str:
    for name in env_names:
        tok = os.environ.get(name)
        if tok:
            print(f"[fetch_dependabot] Jeton lu depuis ${name}", file=sys.stderr)
            return tok.strip()
    try:
        out = subprocess.run(["gh", "auth", "token"], capture_output=True, text=True, timeout=20)
    except (FileNotFoundError, subprocess.SubprocessError):
        out = None
    if out and out.returncode == 0 and out.stdout.strip():
        print("[fetch_dependabot] Jeton obtenu via `gh auth token`", file=sys.stderr)
        return out.stdout.strip()
    raise SystemExit(
        "[fetch_dependabot] Aucun jeton disponible. Définir GH_TOKEN (portée security_events, "
        "ou repo pour un dépôt privé) ou s'authentifier avec `gh auth login`."
    )


def fetch_alerts(owner: str, repo: str, token: str):
    """Toutes les alertes du repo, tous états confondus. L'état complet est
    nécessaire pour reconstituer l'instantané d'un mois passé : une alerte
    aujourd'hui 'fixed' était ouverte au 30 juin si son fixed_at est postérieur.

    Ne pas passer `state` : ce filtre n'accepte que open/fixed/dismissed/
    auto_dismissed, et une valeur hors liste (`state=all`) renvoie 200 avec une
    liste vide, indiscernable d'un repo sain. Sans le paramètre, l'API renvoie
    bien tous les états."""
    url = f"{API_BASE}/repos/{owner}/{repo}/dependabot/alerts?per_page=100"
    alerts = []
    while url:
        req = urllib.request.Request(url, headers={
            "Accept": "application/vnd.github+json",
            "Authorization": f"Bearer {token}",
            "X-GitHub-Api-Version": API_VERSION,
            "User-Agent": USER_AGENT,
        })
        with urllib.request.urlopen(req, timeout=60) as resp:
            alerts.extend(json.loads(resp.read().decode("utf-8")))
            link = resp.headers.get("Link", "")
        m = re.search(r'<([^>]+)>;\s*rel="next"', link)
        url = m.group(1) if m else None
    return alerts


def closed_before(alert: dict, moment: datetime) -> bool:
    """Alerte soldée (corrigée, rejetée à la main ou automatiquement) avant cet
    instant. Sert autant à l'état ouvert qu'au décompte des mouvements."""
    for field in ("fixed_at", "dismissed_at", "auto_dismissed_at"):
        closed = parse_ts(alert.get(field))
        if closed and closed < moment:
            return True
    return False


def was_open_at(alert: dict, moment: datetime) -> bool:
    """L'alerte était-elle ouverte à cet instant ? C'est un état, pas une date
    d'apparition : une alerte créée en mars et jamais corrigée est ouverte en
    septembre. Reproduit le filtre `is:open` de l'interface GitHub, et le contenu
    des CSV de juin (uniquement des lignes 'open')."""
    created = parse_ts(alert.get("created_at"))
    if not created or created >= moment:
        return False
    return not closed_before(alert, moment)


def created_during(alert: dict, start: datetime, end: datetime) -> bool:
    created = parse_ts(alert.get("created_at"))
    return bool(created and start <= created < end)


def flatten(alert: dict, repo: str) -> dict:
    dep = alert.get("dependency") or {}
    pkg = dep.get("package") or {}
    adv = alert.get("security_advisory") or {}
    vuln = alert.get("security_vulnerability") or {}
    cvss = adv.get("cvss") or {}
    patched = (vuln.get("first_patched_version") or {}).get("identifier", "")
    return {
        "repo": repo,
        "numero": alert.get("number"),
        "etat_actuel": alert.get("state", ""),
        "paquet": pkg.get("name", ""),
        "ecosysteme": pkg.get("ecosystem", ""),
        "manifeste": dep.get("manifest_path", ""),
        # runtime = livré au navigateur de production ; development = chaîne de
        # build (exposition hors ligne). Champ absent = portée non renseignée par
        # GitHub, à trancher à la main (ne pas présumer runtime ni build).
        "portee": dep.get("scope") or PORTEE_NON_RENSEIGNEE,
        # direct / transitive : la comparaison de juin avec l'export Dependency-Track
        # a montré que l'écart portait justement sur les dépendances directes.
        "relation": dep.get("relationship") or PORTEE_NON_RENSEIGNEE,
        "severite": adv.get("severity", ""),
        "cvss_score": cvss.get("score", ""),
        "cvss_vecteur": cvss.get("vector_string", ""),
        "ghsa": adv.get("ghsa_id", ""),
        "cve": adv.get("cve_id") or "",
        "version_corrigee": patched,
        "cree_le": alert.get("created_at", ""),
        "url": alert.get("html_url", ""),
    }


def pivot_id(row: dict) -> str:
    """Identifiant pivot : CVE si assignée, sinon GHSA. Sans cet ordre, les
    advisories sans CVE (1 cas en juin : serialize-javascript) sont perdues au
    dédoublonnage."""
    return row["cve"] or row["ghsa"] or f"{row['repo']}#{row['numero']}"


def write_legacy_csv(path: str, rows: list):
    """Format exact des CSV de juin 2026 : pas d'en-tête, 7 colonnes, numéro non
    quoté, état forcé à 'open' (l'alerte était ouverte à la date de l'instantané)."""
    def field(value):
        # Numéro non quoté, champ vide non quoté (advisories sans CVE, ex.
        # serialize-javascript en juin), reste quoté : le module csv ne sait pas
        # produire ce mélange, d'où le formatage manuel.
        if value is None or value == "":
            return ""
        if isinstance(value, int):
            return str(value)
        return '"' + str(value).replace('"', '""') + '"'

    with open(path, "w", newline="", encoding="utf-8") as f:
        for r in sorted(rows, key=lambda r: -(r["numero"] or 0)):
            cells = [r["numero"], "open", r["paquet"], r["ecosysteme"],
                     r["severite"], r["cve"], r["url"]]
            f.write(",".join(field(c) for c in cells) + "\n")


def write_enriched_csv(path: str, rows: list, kev: set):
    fieldnames = ["repo", "numero", "paquet", "ecosysteme", "manifeste", "portee",
                  "relation", "severite", "cvss_score", "cvss_vecteur", "ghsa", "cve",
                  "version_corrigee", "dans_kev", "cree_le", "url"]
    with open(path, "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=fieldnames, extrasaction="ignore")
        w.writeheader()
        for r in sorted(rows, key=lambda r: (r["repo"], -SEVERITY_RANK.get(r["severite"], 0), r["paquet"])):
            out = dict(r)
            if not kev:
                out["dans_kev"] = KEV_NON_VERIFIE
            else:
                out["dans_kev"] = "oui" if r["cve"] in kev else "non"
            w.writerow(out)


def month_movements(raw: dict, start: datetime, end: datetime) -> list:
    """Mouvements de la fenêtre : apparitions, corrections, rejets, et état ouvert
    en fin de fenêtre. Calculé sur l'intégralité des alertes de l'API, pas sur les
    seules lignes retenues, pour alimenter le §5 (suivi d'un mois sur l'autre).

    Ce n'est pas le même axe que l'état ouvert : une alerte apparue avant la
    fenêtre et toujours ouverte compte dans « ouvertes en fin » sans compter dans
    « apparues »."""
    def during(value):
        ts = parse_ts(value)
        return bool(ts and start <= ts < end)

    lignes = []
    for repo, alerts in raw.items():
        apparues = sum(1 for a in alerts if during(a.get("created_at")))
        corrigees = sum(1 for a in alerts if during(a.get("fixed_at")))
        rejetees = sum(1 for a in alerts
                       if during(a.get("dismissed_at")) or during(a.get("auto_dismissed_at")))
        ouvertes = sum(1 for a in alerts if was_open_at(a, end))
        lignes.append({"repo": repo, "apparues": apparues, "corrigees": corrigees,
                       "rejetees": rejetees, "ouvertes": ouvertes})
    return lignes


def movements_table(lignes: list, start: datetime, end: datetime) -> list:
    if not lignes:
        return []
    out = [
        f"## Mouvements du {start:%Y-%m-%d} au {end:%Y-%m-%d}",
        "",
        "Alimente le §5 (suivi d'un mois sur l'autre). « Ouvertes en fin de fenêtre » est un état, "
        "pas un flux : une alerte apparue avant la fenêtre et non corrigée y compte sans compter "
        "dans « apparues ».",
        "",
        "| Repo | Apparues | Corrigées | Rejetées | Ouvertes en fin de fenêtre |",
        "|------|----------|-----------|----------|----------------------------|",
    ]
    totaux = {k: sum(l[k] for l in lignes) for k in ("apparues", "corrigees", "rejetees", "ouvertes")}
    for l in lignes:
        out.append(f"| {l['repo']} | {l['apparues']} | {l['corrigees']} | {l['rejetees']} | {l['ouvertes']} |")
    out += [f"| **Total** | **{totaux['apparues']}** | **{totaux['corrigees']}** | "
            f"**{totaux['rejetees']}** | **{totaux['ouvertes']}** |", ""]
    if totaux["apparues"] > 0:
        ratio = totaux["corrigees"] / totaux["apparues"]
        out += [f"Ratio corrections / apparitions sur la fenêtre : {totaux['corrigees']}/"
                f"{totaux['apparues']} ({ratio:.0%}). Mesure directe de l'évolution de la dette SCA "
                "(cf. ticket R2).", ""]
    return out


def group_by_pivot(rows: list) -> dict:
    """Regroupe les alertes par identifiant pivot, en retenant la sévérité la
    plus haute et l'union des paquets, repos, portées et versions corrigées."""
    groups = {}
    for r in rows:
        key = pivot_id(r)
        g = groups.setdefault(key, {"paquets": set(), "repos": set(), "severite": r["severite"],
                                    "portees": set(), "corrigee": set(), "url": r["url"]})
        g["paquets"].add(r["paquet"])
        g["repos"].add(r["repo"])
        g["portees"].add(r["portee"])
        if r["version_corrigee"]:
            g["corrigee"].add(r["version_corrigee"])
        if SEVERITY_RANK.get(r["severite"], 0) > SEVERITY_RANK.get(g["severite"], 0):
            g["severite"] = r["severite"]
    return groups


def scope_of(group: dict) -> str:
    if group["portees"] == {"runtime"}:
        return "runtime"
    if group["portees"] == {"development"}:
        return "build"
    return "mixte / non renseignee"


def scope_table(subset: dict, scope: str, kev: set, title: str = None) -> list:
    lines = [f"### {title or f'Portée {scope}'} ({len(subset)})", "",
             "| Identifiant | Paquet(s) | Sévérité | Repos | Version corrigée | KEV |",
             "|-------------|-----------|----------|-------|------------------|-----|"]
    for key, g in sorted(subset.items(), key=lambda kv: (-SEVERITY_RANK.get(kv[1]["severite"], 0), kv[0])):
        if not kev:
            in_kev = KEV_NON_VERIFIE
        else:
            in_kev = "oui" if key in kev else "non"
        lines.append(
            f"| {key} | {', '.join(sorted(g['paquets']))} | {g['severite']} | "
            f"{', '.join(sorted(g['repos']))} | {', '.join(sorted(g['corrigee'])) or '-'} | {in_kev} |"
        )
    lines.append("")
    return lines


def split_build_kev_guardrail(subset: dict, kev: set):
    """Garde-fou du SKILL.md §6ter : un item de portée build/dev qui est
    dans le KEV n'a pas vocation à rejoindre le lot P4 « hygiène », il doit être
    traité individuellement en P1 comme n'importe quel item exploité activement.
    Sans cette séparation, la compilation en lot masquerait une exploitation
    active derrière un simple bump de version groupé."""
    if not kev:
        return subset, {}
    lot = {k: v for k, v in subset.items() if k not in kev}
    garde_fou = {k: v for k, v in subset.items() if k in kev}
    return lot, garde_fou


def build_pivot_report(rows: list, kev: set, month_label: str, coverage: list, mode: str,
                       fenetre: str, mouvements: list, start: datetime, borne: datetime) -> str:
    """Fragment Markdown dédupliqué par identifiant pivot et groupé par portée :
    remplace la compilation manuelle de l'annexe (§6ter étape 4 du SKILL.md)."""
    groups = group_by_pivot(rows)

    lines = [
        f"# Pivot SCA Dependabot - {month_label}",
        "",
        f"Généré par `fetch_dependabot_alerts.py` (mode `{mode}`). **{fenetre}** "
        "Source pivot de la revue mensuelle : identifiant CVE si assigné, sinon GHSA. "
        "Dependency-Track et Snyk ne sont consultés qu'en contrôle de delta "
        "(cf. `README_pivot_sca_dependabot.md`).",
        "",
        f"{len(rows)} alertes, {len(groups)} identifiants pivot distincts.",
        "",
        "## Couverture des repos",
        "",
        "| Repo | Alertes API | Retenues | Statut |",
        "|------|-------------|----------|--------|",
    ]
    for c in coverage:
        lines.append(f"| {c['repo']} | {c['total']} | {c['retenues']} | {c['statut']} |")
    lines.append("")
    lines += movements_table(mouvements, start, borne)
    lines += ["## Identifiants pivot par portée", ""]

    for scope in ("runtime", "build", "mixte / non renseignee"):
        subset = {k: v for k, v in groups.items() if scope_of(v) == scope}
        if not subset:
            continue
        if scope != "build":
            # runtime et mixte : évalués individuellement (Item 6 du rapport,
            # cf. SKILL.md §6ter), pas de traitement en lot.
            lines += scope_table(subset, scope, kev)
            continue

        lot, garde_fou = split_build_kev_guardrail(subset, kev)
        if garde_fou:
            lines += [
                "### Garde-fou KEV — retirés du lot P4, traitement individuel P1 "
                f"({len(garde_fou)})",
                "",
                "Portée build/dev, mais présents dans le KEV : exploitation active documentée. "
                "Un lot d'hygiène ne doit jamais absorber un item déjà exploité, cf. SKILL.md §6ter "
                "étape 4. À traiter comme n'importe quel item P1, indépendamment de sa portée.",
                "",
            ]
            lines += scope_table(garde_fou, scope, kev, title="Détail")
        if lot:
            paquets = {p for g in lot.values() for p in g["paquets"]}
            repos = {r for g in lot.values() for r in g["repos"]}
            lines += [
                f"### Lot P4 hygiène — portée build/dev ({len(lot)})",
                "",
                f"Prêt à coller comme ticket unique (remédiation = une seule action, cf. SKILL.md "
                f"§6ter) : **{len(lot)} identifiants distincts, {len(paquets)} paquets, "
                f"{len(repos)} repos concernés**, aucun en KEV" + (
                    f" (voir garde-fou ci-dessus pour les {len(garde_fou)} exceptions)" if garde_fou else ""
                ) + ".",
                "",
            ]
            lines += scope_table(lot, scope, kev, title="Détail (annexe de traçabilité)")

    unknown = [k for k, v in groups.items() if PORTEE_NON_RENSEIGNEE in v["portees"]]
    if unknown:
        lines += [
            "## Portée non renseignée par l'API",
            "",
            "GitHub n'a pas fourni de `dependency.scope` pour ces items : trancher runtime/build "
            "à la main via le `package-lock.json` du module (flag `dev`) avant priorisation.",
            "",
            ", ".join(sorted(unknown)),
            "",
        ]
    return "\n".join(lines) + "\n"


def load_kev_cves(path: str):
    if not path:
        return set()
    with open(path, encoding="utf-8") as f:
        data = json.load(f)
    return {v["cveID"] for v in data.get("vulnerabilities", [])}


def resolve_moment(as_of: str, end: datetime, mm: str, mode: str) -> datetime:
    """Date de référence : --as-of si fourni, sinon la fin du mois (ou maintenant
    si le mois n'est pas terminé). Lève ValueError sur un format invalide, laissé
    à l'appelant pour le rendre en erreur d'argument.

    Son rôle diffère selon le mode : en `instantane` c'est la date à laquelle on
    regarde l'état ouvert ; en `nouveau` elle ne fait que rabaisser la borne haute
    de la fenêtre de création (une date au-delà du mois n'y change donc rien)."""
    now = datetime.now(timezone.utc)
    if not as_of:
        if end > now and mode == "instantane":
            print(f"[fetch_dependabot] Mois non terminé : instantané pris à maintenant ({now:%Y-%m-%d}) "
                  f"et non à la fin du mois.", file=sys.stderr)
        return min(end, now)

    moment = datetime.strptime(as_of, "%Y-%m-%d").replace(tzinfo=timezone.utc)
    if moment > end:
        if mode == "instantane":
            print(f"[fetch_dependabot] --as-of {as_of} est postérieur au mois demandé : l'instantané "
                  f"inclura des alertes apparues après {mm}. Volontaire ? La date est tracée dans le "
                  f"fragment pivot.", file=sys.stderr)
        else:
            print(f"[fetch_dependabot] --as-of {as_of} est postérieur à {mm} : SANS EFFET en mode "
                  f"nouveau, qui reste borné à la fenêtre du mois. Utiliser une date dans le mois pour "
                  f"un mois partiel, ou --mode instantane pour un état à cette date.", file=sys.stderr)
    return moment


def collect_repo(owner: str, repo: str, token: str, mode: str, moment: datetime,
                 start: datetime, end: datetime, out_dir: str, mm: str):
    """Collecte un repo : renvoie (lignes, ligne de couverture, alertes brutes)."""
    try:
        alerts = fetch_alerts(owner, repo, token)
    except urllib.error.HTTPError as exc:
        # 404 = repo inexistant OU alertes Dependabot désactivées (GitHub ne
        # distingue pas les deux) ; 403 = jeton sans la portée nécessaire.
        # Constat tracé, pas d'arrêt : c'est la vérification de couverture.
        statut = {404: "INACCESSIBLE (repo absent ou alertes desactivees)",
                  403: "REFUSE (portee du jeton insuffisante)"}.get(exc.code, f"ERREUR HTTP {exc.code}")
        print(f"[fetch_dependabot] {repo} : {statut}", file=sys.stderr)
        return [], {"repo": repo, "total": 0, "retenues": 0, "statut": statut}, None

    if mode == "instantane":
        kept = [a for a in alerts if was_open_at(a, moment)]
    else:
        kept = [a for a in alerts if created_during(a, start, end)]
    rows = [flatten(a, repo) for a in kept]

    legacy = os.path.join(out_dir, f"{repo}_dependabot_alerts_{mm}.csv")
    write_legacy_csv(legacy, rows)
    print(f"[fetch_dependabot] {repo} : {len(rows)}/{len(alerts)} alertes retenues -> {legacy}",
          file=sys.stderr)
    return rows, {"repo": repo, "total": len(alerts), "retenues": len(rows), "statut": "ok"}, alerts


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--month", required=True, help="ex. july2026, august2026, ou 2026-07")
    ap.add_argument("--dir", required=True, help="dossier sources/ du mois : reçoit les fichiers produits "
                                                "et fournit kev_<moisannee>.json s'il y est déjà")
    ap.add_argument("--owner", default=DEFAULT_OWNER, help=f"organisation GitHub (défaut {DEFAULT_OWNER})")
    ap.add_argument("--repos", help="liste de repos séparés par des virgules (défaut : "
                                    + ",".join(DEFAULT_REPOS) + ")")
    ap.add_argument("--mode", choices=["instantane", "nouveau"], default="instantane",
                    help="instantane (défaut) = alertes ouvertes à la fin du mois, reproduit les CSV de "
                         "juin 2026 ; nouveau = seulement les alertes créées pendant le mois")
    ap.add_argument("--kev", help="kev_<moisannee>.json déjà téléchargé — déduit de --dir si présent")
    ap.add_argument("--as-of", help="date de l'instantané (AAAA-MM-JJ) au lieu de la fin du mois. À utiliser "
                                    "quand la collecte est faite en décalé : la date effective est inscrite "
                                    "dans le fragment pivot, pour que l'instantané reste daté et rejouable")
    args = ap.parse_args()

    year, num = resolve_month(args.month)
    mm = filename_month(args.month)
    start, end = month_bounds(year, num)
    repos = [r.strip() for r in args.repos.split(",")] if args.repos else list(DEFAULT_REPOS)
    os.makedirs(args.dir, exist_ok=True)

    if not args.kev:
        default_kev = os.path.join(args.dir, f"kev_{mm}.json")
        args.kev = default_kev if os.path.isfile(default_kev) else None
        print(f"[fetch_dependabot] KEV {'trouvé' if args.kev else 'absent'} : {default_kev}", file=sys.stderr)
    kev = load_kev_cves(args.kev) if args.kev else set()

    try:
        moment = resolve_moment(args.as_of, end, mm, args.mode)
    except ValueError:
        ap.error(f"--as-of attend une date AAAA-MM-JJ, reçu {args.as_of!r}")

    # En mode nouveau, --as-of rabaisse la borne haute de la fenêtre de création
    # (mois partiel) sans jamais l'étendre au-delà du mois demandé. En mode
    # instantané, `moment` est utilisé tel quel : un --as-of postérieur au mois
    # est alors légitime (état du parc d'alertes à une date de collecte décalée).
    borne_haute = min(end, moment)
    fenetre = (f"Instantané des alertes ouvertes au {moment:%Y-%m-%d}."
               if args.mode == "instantane"
               else f"Alertes créées entre {start:%Y-%m-%d} et {borne_haute:%Y-%m-%d}.")
    print(f"[fetch_dependabot] {fenetre}", file=sys.stderr)

    token = read_token()
    all_rows, coverage, raw = [], [], {}

    for repo in repos:
        rows, cov, alerts = collect_repo(args.owner, repo, token, args.mode, moment,
                                         start, borne_haute, args.dir, mm)
        all_rows.extend(rows)
        coverage.append(cov)
        if alerts is not None:
            raw[repo] = alerts

    raw_path = os.path.join(args.dir, f"dependabot_raw_{mm}.json")
    with open(raw_path, "w", encoding="utf-8") as f:
        json.dump(raw, f, indent=2, ensure_ascii=False)
    print(f"[fetch_dependabot] Réponses brutes déposées : {raw_path}", file=sys.stderr)

    enriched = os.path.join(args.dir, f"dependabot_enrichi_{mm}.csv")
    write_enriched_csv(enriched, all_rows, kev)
    print(f"[fetch_dependabot] CSV enrichi : {enriched}", file=sys.stderr)

    mouvements = month_movements(raw, start, borne_haute)
    pivot = os.path.join(args.dir, f"dependabot_pivot_{mm}.md")
    with open(pivot, "w", encoding="utf-8") as f:
        f.write(build_pivot_report(all_rows, kev, mm, coverage, args.mode, fenetre,
                                   mouvements, start, borne_haute))
    print(f"[fetch_dependabot] Fragment pivot : {pivot}", file=sys.stderr)

    sans_cve = [r for r in all_rows if not r["cve"]]
    if sans_cve:
        print(f"[fetch_dependabot] {len(sans_cve)} alertes sans CVE (pivot GHSA) : "
              + ", ".join(sorted({r['ghsa'] for r in sans_cve})), file=sys.stderr)
    if not kev:
        print("[fetch_dependabot] Croisement KEV non fait (pas de kev_<moisannee>.json) : "
              "colonne 'dans_kev' à 'non verifie'.", file=sys.stderr)


if __name__ == "__main__":
    main()
