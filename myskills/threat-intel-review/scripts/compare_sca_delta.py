#!/usr/bin/env python3
r"""
Contrôle de complétude SCA : compare les exports secondaires (Snyk,
Dependency-Track) au pivot Dependabot du mois et produit la trace mensuelle du
delta exigée par le ticket R6, y compris quand le résultat est vide.

Usage :
    python3 compare_sca_delta.py --month july2026 --dir hds/cyber/july2026/sources \
        --source "dependency-track=sources/vex_july2026.cdx.json" \
        --source "snyk=sources/snyk_july2026.csv"

Le pivot est lu dans dependabot_enrichi_<moisannee>.csv, produit au préalable par
fetch_dependabot_alerts.py. Voir README.md (ce dossier).

Dépendances : bibliothèque standard uniquement (pas de pip install).
"""

import argparse
import csv
import json
import os
import re
import sys
from datetime import date

# Le rapprochement se fait sur l'union CVE + GHSA des deux côtés : un item
# Dependabot sans CVE (16 cas sur le rejeu de juin) est apparié par son GHSA, et
# un advisory Snyk publié avant assignation de CVE par son GHSA également.
CVE_RE = re.compile(r"\bCVE-\d{4}-\d{4,}\b", re.I)
# Alphabet volontairement large : rater un GHSA réel (et le compter en résiduel à
# tort) coûte plus cher qu'une correspondance trop permissive, que le préfixe
# GHSA- rend de toute façon improbable.
GHSA_RE = re.compile(r"\bGHSA-[0-9a-z]{4}-[0-9a-z]{4}-[0-9a-z]{4}\b", re.I)

CLASSES = [
    "hors perimetre Dependabot (composant vendored / fork / ecosysteme non couvert) -> R3",
    "alias manquant (meme vulnerabilite sous un autre identifiant)",
    "bruit de correspondance NVD/CPE (produit non present dans le stack)",
    "a traiter (reellement absent du pivot)",
]


def harvest_ids(path: str):
    """Identifiants CVE/GHSA présents dans un export, quel qu'en soit le format.

    Volontairement agnostique : les exports Snyk (JSON du CLI, CSV de console) et
    Dependency-Track (VEX CycloneDX) n'ont ni le même schéma ni la même stabilité
    de schéma. Balayer le texte pour les identifiants normalisés est plus robuste
    qu'un parseur par outil, et suffit au rapprochement."""
    with open(path, encoding="utf-8", errors="replace") as f:
        blob = f.read()
    # Clé de comparaison en majuscules (les exports ne s'accordent pas sur la
    # casse), mais on garde l'orthographe d'origine pour l'affichage : les GHSA
    # s'écrivent en minuscules et doivent rester lisibles/recherchables tels quels.
    found = {}
    for regex in (CVE_RE, GHSA_RE):
        for m in regex.finditer(blob):
            found.setdefault(m.group(0).upper(), m.group(0))
    return found


def cyclonedx_context(path: str):
    """Contexte par identifiant (sévérité, description) si l'export est un
    CycloneDX/VEX. Renvoie un dict vide pour tout autre format."""
    try:
        with open(path, encoding="utf-8") as f:
            doc = json.load(f)
    except (json.JSONDecodeError, UnicodeDecodeError):
        return {}
    if not isinstance(doc, dict) or "vulnerabilities" not in doc:
        return {}

    ctx = {}
    for vuln in doc.get("vulnerabilities") or []:
        vid = (vuln.get("id") or "").upper()
        if not vid:
            continue
        sev = ""
        for rating in vuln.get("ratings") or []:
            if rating.get("severity"):
                sev = rating["severity"]
                break
        desc = re.sub(r"\s+", " ", (vuln.get("description") or "")).strip()
        ctx[vid] = {"severite": sev, "resume": desc[:120]}
    return ctx


def load_pivot(path: str, repo: str = None, portee: str = None):
    """Ensemble des identifiants du pivot Dependabot (union CVE + GHSA) et
    nombre de lignes retenues, après filtre optionnel par repo et/ou portée.

    Le filtre existe parce qu'une source secondaire ne couvre pas forcément le
    même périmètre que le pivot complet : un SBOM Dependency-Track restreint aux
    dépendances de production ne peut être comparé qu'aux alertes Dependabot de
    portée 'runtime', sous peine de compter en résiduel des centaines d'alertes
    'development' que la source n'a jamais eu vocation à voir (cas constaté sur
    plannerShoulder3D en août 2026 : 33 alertes sur 34 en portée development,
    DT scanné en production seule)."""
    ids, rows = set(), 0
    with open(path, encoding="utf-8", newline="") as f:
        for row in csv.DictReader(f):
            if repo and row.get("repo") != repo:
                continue
            if portee and (row.get("portee") or "").strip().lower() != portee.lower():
                continue
            rows += 1
            for key in ("cve", "ghsa"):
                val = (row.get(key) or "").strip().upper()
                if val:
                    ids.add(val)
    return ids, rows


def parse_source_arg(value: str):
    if "=" not in value:
        raise ValueError(f"--source attend 'nom=chemin', reçu {value!r}")
    name, path = value.split("=", 1)
    name, path = name.strip(), path.strip()
    if not name or not path:
        raise ValueError(f"--source attend 'nom=chemin', reçu {value!r}")
    return name, path


def analyse_source(name: str, path: str, pivot_ids: set):
    found = harvest_ids(path)
    ctx = cyclonedx_context(path)
    couverts = sorted(k for k in found if k in pivot_ids)
    residuels = sorted(k for k in found if k not in pivot_ids)
    return {"nom": name, "chemin": path, "total": len(found), "couverts": couverts,
            "residuels": residuels, "contexte": ctx, "affichage": found}


def build_report(month_label: str, pivot_rows: int, pivot_ids: set, analyses: list,
                 consulted_on: str, missing: list, pivot_filtre: str = "") -> str:
    total_res = sum(len(a["residuels"]) for a in analyses)
    filtre_txt = f" **Pivot restreint : {pivot_filtre}.**" if pivot_filtre else ""
    lines = [
        f"# Contrôle de delta SCA - {month_label}",
        "",
        f"Généré par `compare_sca_delta.py` le {consulted_on}. Pivot : Dependabot "
        f"({pivot_rows} alertes, {len(pivot_ids)} identifiants CVE/GHSA distincts). "
        f"Rapprochement sur l'union CVE + GHSA des deux côtés.{filtre_txt}",
        "",
        "## Ligne de trace du mois",
        "",
    ]

    if analyses:
        noms = ", ".join(a["nom"] for a in analyses)
        lines += [
            f"> Sources secondaires **{noms}** consultées le {consulted_on} ; "
            f"{total_res} identifiant(s) hors périmètre du pivot Dependabot, dont X retenu(s) "
            "après classement (à compléter ci-dessous).",
            "",
        ]
    else:
        lines += [
            f"> Aucune source secondaire fournie au {consulted_on} : **contrôle de delta non fait "
            "ce mois-ci**. À porter en rattrapage §6, comme une source non fournie.",
            "",
        ]

    if missing:
        lines += ["## Sources annoncées mais introuvables", ""]
        lines += [f"* `{p}` ({n}) : fichier absent, contrôle impossible sur cette source" for n, p in missing]
        lines.append("")

    lines += ["## Récapitulatif", "",
              "| Source | Identifiants | Couverts par le pivot | Résiduels |",
              "|--------|--------------|-----------------------|-----------|"]
    for a in analyses:
        lines.append(f"| {a['nom']} | {a['total']} | {len(a['couverts'])} | {len(a['residuels'])} |")
    lines.append("")

    for a in analyses:
        lines += [f"## Résiduels - {a['nom']}", ""]
        if not a["residuels"]:
            lines += ["Aucun résiduel : tous les identifiants de cette source sont couverts par le pivot. "
                      "Résultat vide, mais consigné : c'est la preuve que le contrôle a eu lieu.", ""]
            continue
        lines += [
            "Classement à renseigner à la main, un résiduel n'étant pas un manque par défaut :",
            "",
        ] + [f"{i + 1}. {c}" for i, c in enumerate(CLASSES)] + [
            "",
            "| Identifiant | Sévérité | Résumé | Classement (1-4) | Décision |",
            "|-------------|----------|--------|------------------|----------|",
        ]
        for vid in a["residuels"]:
            c = a["contexte"].get(vid, {})
            affiche = a["affichage"].get(vid, vid)
            lines.append(f"| {affiche} | {c.get('severite', '')} | {c.get('resume', '')} |  |  |")
        lines.append("")

    return "\n".join(lines) + "\n"


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--month", required=True, help="ex. july2026, august2026")
    ap.add_argument("--dir", required=True, help="dossier sources/ du mois (contient le CSV enrichi du pivot)")
    ap.add_argument("--source", action="append", default=[], metavar="NOM=CHEMIN",
                    help="export secondaire à comparer, répétable : "
                         "--source \"snyk=...\" --source \"dependency-track=...\"")
    ap.add_argument("--pivot", help="CSV enrichi du pivot — déduit de --dir/--month si absent")
    ap.add_argument("--out", help="fragment Markdown de sortie — déduit de --dir/--month si absent")
    ap.add_argument("--repo", help="restreint le pivot à ce repo avant comparaison — nécessaire pour "
                                    "une source secondaire scopée à un seul repo (ex. export "
                                    "Dependency-Track d'un seul projet)")
    ap.add_argument("--portee", choices=["runtime", "development"],
                    help="restreint le pivot à cette portée avant comparaison. À utiliser quand la "
                         "source secondaire ne couvre qu'un sous-ensemble structurel du repo, ex. un "
                         "SBOM Dependency-Track scanné en production seule (portee runtime) : sans ce "
                         "filtre, les alertes development du pivot gonflent artificiellement le "
                         "résiduel. Cas constaté : plannerShoulder3D, 33/34 alertes en development, "
                         "DT scanné en runtime seul (cf. README_pivot_sca_dependabot.md)")
    args = ap.parse_args()

    mm = args.month.strip().lower()
    pivot_path = args.pivot or os.path.join(args.dir, f"dependabot_enrichi_{mm}.csv")
    out_path = args.out or os.path.join(args.dir, f"delta_sca_{mm}.md")

    if not os.path.isfile(pivot_path):
        raise SystemExit(f"[compare_sca_delta] Pivot introuvable : {pivot_path}\n"
                         f"Lancer d'abord : python3 fetch_dependabot_alerts.py --month {mm} --dir {args.dir}")

    pivot_ids, pivot_rows = load_pivot(pivot_path, repo=args.repo, portee=args.portee)
    filtre = ", ".join(f"{k}={v}" for k, v in (("repo", args.repo), ("portee", args.portee)) if v)
    print(f"[compare_sca_delta] Pivot : {pivot_rows} alertes, {len(pivot_ids)} identifiants "
          f"({pivot_path}{f', filtré {filtre}' if filtre else ''})", file=sys.stderr)

    analyses, missing = [], []
    for raw in args.source:
        try:
            name, path = parse_source_arg(raw)
        except ValueError as exc:
            ap.error(str(exc))
        if not os.path.isfile(path):
            print(f"[compare_sca_delta] {name} : fichier introuvable ({path})", file=sys.stderr)
            missing.append((name, path))
            continue
        a = analyse_source(name, path, pivot_ids)
        analyses.append(a)
        print(f"[compare_sca_delta] {name} : {a['total']} identifiants, {len(a['couverts'])} couverts, "
              f"{len(a['residuels'])} résiduels", file=sys.stderr)

    if not args.source:
        print("[compare_sca_delta] Aucune --source fournie : le fragment tracera un contrôle NON FAIT.",
              file=sys.stderr)

    report = build_report(mm, pivot_rows, pivot_ids, analyses, date.today().isoformat(), missing, filtre)
    with open(out_path, "w", encoding="utf-8") as f:
        f.write(report)
    print(f"[compare_sca_delta] Fragment écrit : {out_path}", file=sys.stderr)


if __name__ == "__main__":
    main()
