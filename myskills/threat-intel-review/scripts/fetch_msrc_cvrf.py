#!/usr/bin/env python3
r"""
Collecte l'export MSRC du mois (API CVRF v3.0), filtré sur le périmètre Windows
Server / IIS / .NET, et compare le parc au build cible du mois si un relevé est
fourni. Voir README.md (ce dossier) pour le détail des arguments et des formats.

Usage :
    python3 fetch_msrc_cvrf.py --month <moisannee> --dir <dossier sources/ du mois>

Dépendances : bibliothèque standard uniquement (pas de pip install).
"""

import argparse
import csv
import json
import os
import re
import sys
import urllib.request
import urllib.error
from datetime import datetime, timezone

API_BASE = "https://api.msrc.microsoft.com/cvrf/v3.0"
UPDATE_GUIDE_VULN_URL = "https://msrc.microsoft.com/update-guide/vulnerability/{cve}"
USER_AGENT = "OneOrtho-ThreatIntel-Review/1.0 (+outillage interne, cf. ticket R4)"

MONTH_ABBR = {
    "january": "Jan", "february": "Feb", "march": "Mar", "april": "Apr",
    "may": "May", "june": "Jun", "july": "Jul", "august": "Aug",
    "september": "Sep", "october": "Oct", "november": "Nov", "december": "Dec",
}
ABBR_TO_MONTH = {v.lower(): k for k, v in MONTH_ABBR.items()}

# Périmètre déclaré au plan_revu_mensuel.md : Windows Server + IIS + .NET/ASP.NET
# installés sur Windows. Les variantes Linux/Mac de .NET sont explicitement
# exclues (hors périmètre serveur OneOrtho) mais journalisées pour traçabilité.
INCLUDE_PATTERN = re.compile(
    r"Windows Server|Internet Information Services|\bIIS\b|\.NET|ASP\.NET", re.I
)
EXCLUDE_PATTERN = re.compile(r"\bon Linux\b|\bon Mac OS\b|for Mac\b", re.I)

SEVERITY_RANK = {"critical": 4, "important": 3, "moderate": 2, "low": 1}


def http_get_json(url: str) -> dict:
    req = urllib.request.Request(url, headers={"Accept": "application/json", "User-Agent": USER_AGENT})
    with urllib.request.urlopen(req, timeout=60) as resp:
        return json.loads(resp.read().decode("utf-8"))


def resolve_doc_id(month_arg: str) -> str:
    """'june2026' -> '2026-Jun'. Accepte aussi directement un ID CVRF ('2026-Jun')."""
    if re.match(r"^\d{4}-[A-Za-z]{3}", month_arg):
        return month_arg
    m = re.match(r"^([a-zA-Z]+)(\d{4})$", month_arg.strip())
    if not m:
        raise ValueError(f"Format de mois non reconnu : {month_arg!r} (attendu ex. 'june2026' ou '2026-Jun')")
    month_name, year = m.group(1).lower(), m.group(2)
    abbr = MONTH_ABBR.get(month_name)
    if not abbr:
        raise ValueError(f"Mois non reconnu : {month_name!r}")
    return f"{year}-{abbr}"


def filename_month(month_arg: str) -> str:
    """Forme '<moisannée>' (ex. 'august2026') utilisée dans les noms de fichiers
    sources/, quelle que soit la forme acceptée par --month ('august2026' ou
    directement un ID CVRF '2026-Aug')."""
    if re.match(r"^[A-Za-z]+\d{4}$", month_arg):
        return month_arg.lower()
    m = re.match(r"^(\d{4})-([A-Za-z]{3})", month_arg)
    if m:
        year, abbr = m.groups()
        name = ABBR_TO_MONTH.get(abbr.lower())
        if name:
            return f"{name}{year}"
    return month_arg


def find_document(doc_id: str) -> dict:
    updates = http_get_json(f"{API_BASE}/updates")
    candidates = [u for u in updates["value"] if u["ID"] == doc_id]
    if not candidates:
        # Patch Tuesday hors-bande possible (ex. '2026-Jun-B') : lister les approchants
        near = [u["ID"] for u in updates["value"] if u["ID"].startswith(doc_id)]
        hint = f" Candidats proches : {near}" if near else ""
        raise LookupError(f"Aucun document CVRF trouvé pour {doc_id!r}.{hint}")
    return candidates[0]


def build_product_map(cvrf: dict):
    """Retourne (included: {id: name}, excluded: {id: name}) sur tout le ProductTree."""
    included, excluded = {}, {}

    def walk(node):
        if "ProductID" in node:
            name = node["Value"]
            if INCLUDE_PATTERN.search(name) and not EXCLUDE_PATTERN.search(name):
                included[node["ProductID"]] = name
            elif INCLUDE_PATTERN.search(name):
                excluded[node["ProductID"]] = name  # matché mais hors plateforme serveur (Linux/Mac)
            return
        for it in node.get("Items", []):
            walk(it)

    for branch in cvrf.get("ProductTree", {}).get("Branch", []):
        walk(branch)
    return included, excluded


def severity_of(vuln: dict, target_ids: set) -> str:
    best = None
    for t in vuln.get("Threats", []):
        if t.get("Type") != 3:
            continue
        if not (set(t.get("ProductID", [])) & target_ids):
            continue
        val = (t.get("Description") or {}).get("Value")
        if not val:
            continue
        rank = SEVERITY_RANK.get(val.lower(), 0)
        if best is None or rank > SEVERITY_RANK.get(best.lower(), 0):
            best = val
    return best or "Non communiqué"


def impacts_of(vuln: dict, target_ids: set):
    seen = []
    for t in vuln.get("Threats", []):
        if t.get("Type") != 0:
            continue
        if not (set(t.get("ProductID", [])) & target_ids):
            continue
        val = (t.get("Description") or {}).get("Value")
        if val and val not in seen:
            seen.append(val)
    return seen


def exploited_status(vuln: dict, target_ids: set):
    for t in vuln.get("Threats", []):
        if t.get("Type") != 1:
            continue
        if target_ids and not (set(t.get("ProductID", [])) & target_ids):
            continue
        val = (t.get("Description") or {}).get("Value")
        if val:
            return val
    return "Non communiqué"


def action_required(vuln: dict) -> str:
    for note in vuln.get("Notes", []):
        if note.get("Title") == "Customer Action Required":
            return note.get("Value", "")
    return ""


def remediations_of(vuln: dict, product_map: dict, target_ids: set):
    """1 entrée '<plateforme>: KB<id> (build <FixedBuild>)' par (plateforme, KB) affectée."""
    out = []
    for rem in vuln.get("Remediations", []):
        if rem.get("Type") != 2:  # 2 = Security Update (contient FixedBuild)
            continue
        ids = set(rem.get("ProductID", [])) & target_ids
        if not ids:
            continue
        kb = (rem.get("Description") or {}).get("Value") or rem.get("SubType") or "?"
        build = rem.get("FixedBuild")
        for pid in ids:
            platform = product_map.get(pid, pid)
            label = f"{platform}: KB{kb}" + (f" (build {build})" if build else "")
            if label not in out:
                out.append(label)
    return out


def base_os_name(platform_name: str) -> str:
    """Normalise vers le nom de plateforme tel qu'utilisé dans le CVRF (build/UBR
    identique quelle que soit l'édition) :
    'Windows Server 2022 (Server Core installation)' -> 'Windows Server 2022'
    'Windows Server 2016 Standard' -> 'Windows Server 2016'
    """
    name = re.sub(r" \(Server Core installation\)$", "", platform_name)
    name = re.sub(r"\s+(Standard|Datacenter|Essentials)$", "", name, flags=re.I)
    return name.strip()


def build_tuple(build_str: str):
    """'10.0.20348.5256' -> (10, 0, 20348, 5256), pour comparaison numérique fiable."""
    try:
        return tuple(int(p) for p in build_str.split("."))
    except (ValueError, AttributeError):
        return None


def expected_builds_by_os(cvrf: dict, product_map: dict, target_ids: set):
    """OS de base -> {'kb': ..., 'build': 'A.B.C.D'} : le build le plus récent trouvé
    dans les Remediations du mois pour cet OS (gère un éventuel correctif hors-bande).
    Restreint à 'Windows Server*' : .NET/ASP.NET ont leur propre versionnage (pas de
    build.UBR par OS), non comparable à un CurrentBuild/UBR de serveur."""
    best = {}
    for vuln in cvrf.get("Vulnerability", []):
        for rem in vuln.get("Remediations", []):
            if rem.get("Type") != 2:
                continue
            build = rem.get("FixedBuild")
            bt = build_tuple(build)
            if not bt:
                continue
            kb = (rem.get("Description") or {}).get("Value") or rem.get("SubType") or "?"
            for pid in set(rem.get("ProductID", [])) & target_ids:
                os_name = base_os_name(product_map.get(pid, pid))
                if not os_name.startswith("Windows Server"):
                    continue
                current = best.get(os_name)
                if current is None or bt > current["build_tuple"]:
                    best[os_name] = {"kb": kb, "build": build, "build_tuple": bt}
    return best


def load_fleet(path: str):
    with open(path, encoding="utf-8") as f:
        data = json.load(f)
    return data.get("date_releve", ""), data.get("serveurs", [])


def classify_server(srv: dict, expected: dict):
    """Retourne ('covered'|'residual'|'unknown', libellé) pour un serveur du relevé."""
    nom = srv.get("nom", "?")
    os_name_raw = srv.get("os", "")
    exp = expected.get(base_os_name(os_name_raw))
    if exp is None:
        return "unknown", (nom, os_name_raw)

    cb, ubr = srv.get("CurrentBuild"), srv.get("UBR")
    # Base majeure.mineure alignée sur celle du build cible (ex. '10.0'), le relevé
    # PowerShell ne remonte que CurrentBuild + UBR.
    major_minor = ".".join(str(x) for x in exp["build_tuple"][:2])
    current_str = f"{major_minor}.{cb}.{ubr}"
    current_tuple = build_tuple(current_str)
    if current_tuple is None:
        return "unknown", (nom, f"CurrentBuild/UBR invalide ({cb}/{ubr})")

    entry = f"{nom} ({os_name_raw}) — build {current_str}"
    if current_tuple >= exp["build_tuple"]:
        return "covered", entry
    return "residual", entry + f" — en retard (cible {exp['build']})"


def compare_fleet(expected: dict, date_releve: str, servers: list) -> str:
    """Construit le fragment Markdown de comparaison parc vs build cible du mois."""
    lines = [
        "## Comparaison parc Windows vs Patch Tuesday du mois",
        "",
        f"Relevé du parc : {date_releve or 'date non renseignée'} ({len(servers)} serveur(s))",
        "",
        "Build cible par OS (issu du CVRF du mois) :",
        "",
    ]
    for os_name, info in sorted(expected.items()):
        lines.append(f"- {os_name} : KB{info['kb']} (build {info['build']})")
    lines.append("")

    buckets = {"covered": [], "residual": [], "unknown": []}
    for srv in servers:
        kind, payload = classify_server(srv, expected)
        buckets[kind].append(payload)

    n = len(buckets["covered"]) + len(buckets["residual"])
    lines.append(f"Couverts ({len(buckets['covered'])}/{n}) :")
    lines += [f"- {e}" for e in buckets["covered"]] or ["- (aucun)"]
    lines.append("")
    lines.append(f"Résiduels ({len(buckets['residual'])}/{n}) :")
    lines += [f"- {e}" for e in buckets["residual"]] or ["- (aucun)"]
    if buckets["unknown"]:
        lines.append("")
        lines.append("Non comparés (OS du relevé non reconnu dans le CVRF du mois, à vérifier manuellement) :")
        lines += [f"- {nom} ({detail})" for nom, detail in buckets["unknown"]]
    return "\n".join(lines) + "\n"


def first_last_dates(vuln: dict):
    hist = vuln.get("RevisionHistory") or []
    if not hist:
        return "", ""
    def fmt(d):
        try:
            return datetime.fromisoformat(d.replace("Z", "+00:00")).strftime("%b %d, %Y")
        except Exception:
            return d
    return fmt(hist[0]["Date"]), fmt(hist[-1]["Date"])


def load_kev_cves(path: str):
    if not path:
        return set()
    with open(path, encoding="utf-8") as f:
        data = json.load(f)
    return {v["cveID"] for v in data.get("vulnerabilities", [])}


def apply_dir_defaults(args):
    """Déduit --out/--raw-out/--kev/--fleet/--fleet-report de --dir + --month selon
    la convention <type>_<moisannee>.<ext> de sources/. Ne touche pas aux flags
    fournis explicitement (priorité à l'explicite)."""
    mm = filename_month(args.month)
    os.makedirs(args.dir, exist_ok=True)
    args.out = args.out or os.path.join(args.dir, f"msrc_{mm}.csv")
    args.raw_out = args.raw_out or os.path.join(args.dir, f"msrc_cvrf_raw_{mm}.json")

    if not args.kev:
        default_kev = os.path.join(args.dir, f"kev_{mm}.json")
        args.kev = default_kev if os.path.isfile(default_kev) else None
        print(f"[fetch_msrc_cvrf] KEV {'trouvé' if args.kev else 'absent'} : {default_kev}", file=sys.stderr)

    if not args.fleet:
        default_fleet = os.path.join(args.dir, f"parc_windows_{mm}.json")
        args.fleet = default_fleet if os.path.isfile(default_fleet) else None
        print(f"[fetch_msrc_cvrf] Relevé parc {'trouvé' if args.fleet else 'absent'} : {default_fleet}",
              file=sys.stderr)

    if args.fleet and not args.fleet_report:
        args.fleet_report = os.path.join(args.dir, f"comparaison_parc_windows_{mm}.md")


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--month", required=True, help="ex. june2026, ou directement un ID CVRF ex. 2026-Jun")
    ap.add_argument("--dir", help="dossier sources/ du mois : dérive --out/--raw-out/--fleet-report, "
                                    "et lit --kev/--fleet automatiquement s'ils y existent sous le nom "
                                    "conventionnel (kev_<moisannee>.json, parc_windows_<moisannee>.json). "
                                    "Chaque flag explicite ci-dessous garde priorité sur ce que --dir déduirait.")
    ap.add_argument("--out", help="CSV de sortie (sources/msrc_<moisannee>.csv) — déduit de --dir si absent")
    ap.add_argument("--kev", help="chemin vers kev_<moisannee>.json déjà téléchargé (croisement KEV) — "
                                    "déduit de --dir si présent sous ce nom")
    ap.add_argument("--raw-out", help="dépose le CVRF brut (JSON) ici, pièce probante pour l'audit — "
                                        "déduit de --dir si absent")
    ap.add_argument("--fleet", help="relevé du parc Windows du mois (JSON, cf. en-tête du script) — "
                                      "déduit de --dir si présent sous ce nom")
    ap.add_argument("--fleet-report", help="fragment Markdown de comparaison parc/build cible en sortie "
                                            "(écrit seulement si un relevé --fleet est trouvé) — déduit de "
                                            "--dir si absent")
    args = ap.parse_args()

    if args.dir:
        apply_dir_defaults(args)
    if not args.out:
        ap.error("--out requis (ou fournir --dir pour le déduire automatiquement, cf. --help)")

    doc_id = resolve_doc_id(args.month)
    print(f"[fetch_msrc_cvrf] Document CVRF ciblé : {doc_id}", file=sys.stderr)

    try:
        doc_meta = find_document(doc_id)
        cvrf = http_get_json(doc_meta["CvrfUrl"])
    except (urllib.error.URLError, LookupError, json.JSONDecodeError) as e:
        print(f"[fetch_msrc_cvrf] ÉCHEC API MSRC ({e}). Revenir au fallback manuel (§0bis/§5 du SKILL.md).",
              file=sys.stderr)
        sys.exit(1)

    if args.raw_out:
        with open(args.raw_out, "w", encoding="utf-8") as f:
            json.dump(cvrf, f, ensure_ascii=False)
        print(f"[fetch_msrc_cvrf] CVRF brut déposé : {args.raw_out}", file=sys.stderr)

    included, excluded = build_product_map(cvrf)
    target_ids = set(included)
    if not target_ids:
        print("[fetch_msrc_cvrf] Aucune plateforme du périmètre trouvée dans ce document CVRF.", file=sys.stderr)
    print(f"[fetch_msrc_cvrf] {len(included)} plateformes retenues, {len(excluded)} exclues "
          f"(hors Windows, ex. .NET Linux/Mac) — cf. journal.", file=sys.stderr)

    kev_cves = load_kev_cves(args.kev) if args.kev else set()

    rows = []
    for vuln in cvrf.get("Vulnerability", []):
        ps_ids = set()
        for ps in vuln.get("ProductStatuses", []):
            ps_ids |= set(ps.get("ProductID", []))
        affected = ps_ids & target_ids
        if not affected:
            continue

        cve = vuln.get("CVE", "")
        pub_date, upd_date = first_last_dates(vuln)
        platforms = sorted({included[pid] for pid in affected})

        rows.append({
            "Date de publication": pub_date,
            "Dernière mise à jour": upd_date,
            "Numéro CVE": cve,
            "Numéro CVE (Link)": UPDATE_GUIDE_VULN_URL.format(cve=cve),
            "Titre CVE": (vuln.get("Title") or {}).get("Value", ""),
            "Impact": "; ".join(impacts_of(vuln, affected)),
            "Gravité max.": severity_of(vuln, affected),
            "Action utilisateur requise": action_required(vuln),
            "Plateformes affectées": "; ".join(platforms),
            "Exploitation": exploited_status(vuln, affected),
            "Dans KEV": "oui" if cve in kev_cves else ("non" if kev_cves else "non vérifié (pas de --kev)"),
            "KB / build correctif": "; ".join(remediations_of(vuln, included, affected)),
        })

    fieldnames = [
        "Date de publication", "Dernière mise à jour", "Numéro CVE", "Numéro CVE (Link)",
        "Titre CVE", "Impact", "Gravité max.", "Action utilisateur requise",
        "Plateformes affectées", "Exploitation", "Dans KEV", "KB / build correctif",
    ]
    with open(args.out, "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=fieldnames)
        w.writeheader()
        w.writerows(rows)

    print(f"[fetch_msrc_cvrf] {len(rows)} CVE écrites dans {args.out}", file=sys.stderr)
    if excluded:
        excl_sample = list(sorted(set(excluded.values())))[:10]
        print(f"[fetch_msrc_cvrf] Exemples de plateformes matchées mais exclues (hors Windows) : {excl_sample}",
              file=sys.stderr)

    if args.fleet:
        expected = expected_builds_by_os(cvrf, included, target_ids)
        date_releve, servers = load_fleet(args.fleet)
        report = compare_fleet(expected, date_releve, servers)
        if args.fleet_report:
            with open(args.fleet_report, "w", encoding="utf-8") as f:
                f.write(report)
            print(f"[fetch_msrc_cvrf] Comparaison parc écrite dans {args.fleet_report}", file=sys.stderr)
        else:
            print(report)


if __name__ == "__main__":
    main()
