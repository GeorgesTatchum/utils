# Rapport mensuel - Revue Threat Intelligence OneOrtho - 2026-06

## Métadonnées

| Champ | Valeur |
|-------|--------|
| Période couverte | 01/06/2026 au 30/06/2026 |
| Date de la revue | 06/07/2026 |
| Analyste | Georges TATCHUM |
| Validé par | Christophe ALAPEE - Responsable numérique |
| Date de validation | 08/07/2026 (revue + J+2 ouvrés) |
| Ticket Jira | CICD-170 - SEC-THREATINTEL-2026-06 (parent CICD-161) |

---

## 1. Résumé exécutif

Environ 545 items examinés sur la période 01/06 au 30/06/2026 (dont 220 CVE MSRC de juin, 177 CVE distinctes Dependabot et 50 advisories CISA ICS/ICSMA). CISA ICS/ICSMA a été consultée (curl) : 0 applicable, mais 3 advisories DICOM (DCMTK, OHIF, pydicom/pynetdicom) ont été vérifiés non applicables car OneOrtho utilise d'autres implémentations DICOM (nanodicom PHP + nifti-reader-js).
Applicables : 3 items Angular (Hip3D + KneeMadison), 2 items SCA runtime (tinymce ; mathjs, requalifié P4 non exploitable après investigation), le batch Node.js du 18/06 (présent sur les serveurs), et 4 groupes (13 CVE Critiques Windows Server, 96 CVE Important Windows Server, 2 lots chaîne de build Dependabot par Tech Lead - one-platform et modules Angular). Les 400 alertes Dependabot ont été triées par portée (runtime livré au navigateur contre build hors ligne) via le flag `dev` des lockfiles : 45 alertes runtime évaluées individuellement, 355 alertes build regroupées ; lodash, d'abord classé runtime, est reclassé build (dev-only, Item 6c). MariaDB : 0 nouvelle CVE en juin ; les 13 CVE de mai restent en remédiation (montée non faite, parc inchangé), suivies au §5 hors décompte des items de juin.
Priorité maximale : P2, aucun P1, car aucune CVE applicable au stack n'est en KEV actif (0 sur 23 KEV de juin, 0 sur 109 CVE MSRC de périmètre, 0 sur 177 CVE Dependabot). La priorité traduit la criticité intrinsèque de chaque item ; le statut de remédiation ci-dessous indique le risque réellement résiduel.
Statut de remédiation au 06/07/2026 : les deux items MSRC (Critique et Important) sont **corrigés sur 16 des 19 serveurs** (au build du Patch Tuesday de juin), et l'item Microsoft Defender de mai (CVE-2026-45498) est clôturé. 3 serveurs résiduels : WEBPRODDEDIENNE (WS2025, resté au build de mai malgré un statut « patché »), WEBPRODGLOBALD et WEBPRODI2B (WS2016, planifiés). La priorité P2 des CVE Windows reflète leur gravité ; le risque résiduel se concentre sur ces 3 serveurs. Restent entièrement à traiter : montées Angular (Hip3D/KneeMadison), tinymce, mathjs, Node.js (14 instances ligne 22 < 22.23.0, plus GLOBALD en Node 16 EOL), MariaDB (report mai) et les deux lots build Dependabot.
Décisions clés : montées Angular / tinymce (P2, échéance 20/07) ; montée d'hygiène mathjs (P4, non exploitable après investigation du chemin de code) ; montée des 3 serveurs Windows résiduels au build de juin pour solder les items MSRC ; campagnes des deux lots build Dependabot (P4, one-platform et modules Angular, Tech Leads distincts) ; montée Node.js ligne 22 vers 22.23.0 et traitement du serveur GLOBALD en Node 16 EOL ; accélération de la montée MariaDB (CVE-2026-49261 CVSS 10.0, toujours applicable sur 16 instances). Point d'attention du mois : CVE-2026-47291 (Windows HTTP.sys, RCE Critique) sur le composant noyau exposé derrière IIS, corrigée sur 16 des 19 serveurs ; et présence d'un runtime Node.js en fin de vie (16.13.2) sur GLOBALD prod.

---

## 2. Sources consultées

> Légende : ✔ consultée et traitée / ✗ non consultable (motif) / ☐ planifiée non consultée (cadence réduite).

| Source | Consultée | Date dernière publication lue | Nb items remontés | Remarques |
|--------|-----------|------------------------------|-------------------|-----------|
| CISA KEV Catalog | ✔ | 01/07/2026 (catalog 2026.07.01) | 23 ajoutées en juin | Récupération curl du JSON officiel. 0 sur le stack OneOrtho. Détail §3.3 |
| NVD / CVE | ☐ | - | - | Consultée indirectement via advisories par composant |
| CERT-FR (ANSSI) | ✔ | 30/06/2026 | 0 nouveau stack | Juin complet consulté via les archives `/avis/` (pages 1 à 17, AVI-0668 à 0819) et `/alerte/`, le flux RSS ne couvrant qu'une fenêtre glissante. Avis : recoupent en canal secondaire le Patch Tuesday MSRC (AVI-0728 Windows, AVI-0729 .NET) et le batch Node.js (AVI-0786). Alertes : 0 nouvelle en juin ; ALE-005 (Exchange, CVE-2026-42897, exploitation active) mise à jour le 11/06, Exchange non hébergé (non applicable). Détail §3.3 |
| GitHub Security Advisories | ✔ | 30/06/2026 | par composant | Angular, php/php-src, Three.js, Symfony |
| CISA ICS Medical Advisories | ✔ | 30/06/2026 | 50 (0 applicable) | Scrapées via curl (pages 2-6 ; WAF bloque WebFetch). 5 ICSMA + 45 ICSA. 3 advisories DICOM vérifiés non applicables (OneOrtho utilise nanodicom + nifti-reader-js, pas DCMTK/OHIF/pydicom). Captures SharePoint + extrait `sources/cisa_ics_june2026.md`. Détail §3.3 |
| FDA Medical Device Safety | ✔ | 03/06/2026 | 1 (hors périmètre) | Fichier `fda_safety_june2026.xlsx`. 1 comm. du 03/06 (implant cheville tiers, clinique non-cyber). Détail §3.3 |
| ENISA Health sector | ☐ | - | - | Cadence trimestrielle, non activée ce mois |
| H-ISAC | ✗ | - | - | Accès membre non activé à ce jour |
| Angular Security Advisories | ✔ | 10/06/2026 | 8 nouveaux GHSA | Batch 02 au 10/06. 3 applicables runtime, 5 non applicables (platform-server/service-worker/SSR). Détail §3 |
| Node.js Security | ✔ | 18/06/2026 | 12 CVE | Batch du 18/06 (WebCrypto/TLS/HTTP2/permission), lignes 22/24/26. **Applicable** : Node présent sur les serveurs, 14 instances ligne 22.x < 22.23.0. Détail Item 7 (§3.2) |
| PHP Security Releases | ✔ | 04/06/2026 | 2 CVE | PHP 8.5.7 + 8.4.22 (CVE-2026-44927/44928 uriparser). Branche 8.1 non concernée (ext URI 8.4+) |
| GitHub Advisories `php/php-src` | ✔ | 04/06/2026 | 0 nouveau juin | Page rolling = batch 07/05 (SOAP, urldecode, mbstring, DOMNode::C14N, PHP-FPM) déjà traité. Suivi §5 |
| Symfony Security Advisories | ✔ | 19/06/2026 | 2 CVE | Batch 19/06 : CVE-2026-55878 (ux-toolkit), CVE-2026-55877 (ux-icons). `symfony/ux-*` absent du composer.lock, non applicables |
| MariaDB Security Releases | ✔ | fichier au 06/07/2026 | 0 nouvelle CVE juin | `mariadb_community-server_june2026.md` (fichier complet). Mêmes 14 CVE-2026 qu'en mai. Parc inchangé : 13 CVE toujours applicables (suivi §5) |
| MSRC Security Update Guide | ✔ | export 06/07/2026 | 220 juin (109 périmètre) | `msrc_june2026.csv`. Patch Tuesday juin = 09/06/2026. 13 Critiques + 96 Important en périmètre Windows Server/IIS/.NET. Détail §3 |
| NEMA DICOM Standard Newsroom | ✔ | - | 0 | Pas d'actualité sécurité sur la période |
| Recherche NVD filtrée DICOM | ☐ | - | - | Cadence trimestrielle, prochaine fin Q2/Q3 2026 |
| Three.js Security Advisories | ✔ | 30/06/2026 | 0 | Page GitHub sans advisory publié |
| Three.js Releases | ✔ | 30/06/2026 | 0 | Aucune release sur la période. Parc : 0.150.1 / 0.181.2 / 0.182.0 / 0.185.0 |
| Dépendances tierces - Snyk SCA | ✗ à rattraper avant validation | - | non consultée | Export console Snyk non fourni. Décision §6. Couverture SCA partielle assurée par Dependabot ce mois |
| Dépendances tierces - GitHub Dependabot | ✔ | export 06/07/2026 | 400 alertes / 177 CVE | 4 repos (one-platform, plannerHip3D, plannerKneeMadison, plannerShoulder3D). 7 critical, 188 high. 0 en KEV. Détail §3 |

Synthèse : 16 sources ✔ consultées / 2 ✗ non consultables (Snyk à rattraper avant validation ; H-ISAC accès non activé) / 3 ☐ planifiées (NVD, ENISA, NVD DICOM : cadence réduite ou consultées indirectement).

---

## 3. Items identifiés

### 3.1 Synthèse chiffrée

| Indicateur | Valeur |
|-----------|--------|
| Total items examinés | ≈ 545 (dont 50 advisories CISA ICS/ICSMA) |
| Applicables OneOrtho | 6 individuels (3 Angular Items 1-3, tinymce 6a, mathjs 6b, Node.js 7) + 4 groupes/lots (MSRC Critique 13 CVE, MSRC Important 96 CVE, lot build one-platform 6d-1, lot build modules Angular 6d-2) + lodash dev conclu (6c) |
| MariaDB (report de mai, hors décompte juin) | 0 nouvelle CVE en juin ; 13 CVE de mai toujours en remédiation (montée non faite), suivi §5 |
| Non applicables | ≈ 120 tracés (50 CISA ICS/ICSMA dont 3 DICOM vérifiés, 23 KEV hors stack, ≈ 36 CERT-FR fenêtre RSS, 5 Angular platform-server/service-worker/SSR, 2 Symfony ux-*, 2 PHP uriparser, 1 FDA, MariaDB CVE-2026-21968) |
| À investiguer | 1 (version PHP déployée pour uriparser) |
| Priorité P1 | 0 (aucune CVE applicable en KEV actif sur composant utilisé) |
| Priorité P2 | 2 Angular XSS (CVE-2026-50557, CVE-2026-54265) + MSRC Critique (13 CVE) + tinymce (Item 6a) |
| Priorité P3 | 1 Angular DoS (CVE-2026-54268) + MSRC Important (96 CVE) |
| Priorité P4 | mathjs non exploitable (Item 6b, montée d'hygiène) + Node.js build (Item 7) + lots build Dependabot (6d-1 one-platform 42 alertes, 6d-2 modules Angular 313 alertes) + lodash dev (6c, overrides) |
| Statut de remédiation au 06/07 | MSRC Critique + Important : corrigés 16/19 serveurs (build de juin) ; 3 résiduels (WEBPRODDEDIENNE au build de mai, WEBPRODGLOBALD, WEBPRODI2B). Defender mai : clôturé. À traiter : Angular Hip3D/KneeMadison, tinymce, mathjs, Node.js (ligne 22 → 22.23.0 + GLOBALD Node 16 EOL), lodash (overrides), MariaDB (16 instances), lots build |

### 3.2 Détail des items applicables

#### Item 1 : CVE-2026-50557

| Champ | Valeur |
|-------|--------|
| Titre | Template and Attribute Namespace Sanitization Bypass (XSS) |
| Source | Angular Security Advisories (GHSA-f3m7-gqxr-g87x) |
| Date publication | 05/06/2026 |
| CVSS | 5.3 (Modérée) |
| Exploité activement (KEV) | Non |
| Exploit public | Non documenté |
| Composant impacté | `@angular/compiler` + `@angular/core`. Fix : 20.3.22 / 21.2.15 / 22.0.0-rc.2 |
| Produit concerné | Planificateurs Angular : Hip3D (20.3.16), KneeMadison (21.2.5). Hip2D (21.2.17) et Shoulder3D (22.0.4) déjà corrigés |
| Exposition | Internet (modules livrés au navigateur client) |
| Priorité retenue | P2 (XSS à exposition internet ; continuité de la classification mai pour les XSS applicatifs) |
| Action décidée | Patch : montée Hip3D vers 20.3.25 et KneeMadison vers 21.2.17 (cumulative) |
| Ticket remédiation | À créer en Jira, lié à CICD-170 |
| Échéance | 20/07/2026 (J+14) |
| Responsable | Tech Lead Angular |
| Canaux secondaires | Détecté aussi par GitHub Dependabot sur Hip3D et KneeMadison (défense en profondeur) |

#### Item 2 : CVE-2026-54265

| Champ | Valeur |
|-------|--------|
| Titre | Two-Way Property Binding Sanitization Bypass (XSS) |
| Source | Angular Security Advisories (GHSA-58w9-8g37-x9v5) |
| Date publication | 10/06/2026 |
| CVSS | 5.3 (Modérée) |
| Exploité activement (KEV) | Non |
| Exploit public | Non documenté |
| Composant impacté | `@angular/compiler`. Contournement du sanitizer sur propriétés DOM (innerHTML, src, href, srcdoc) via liaison bidirectionnelle. Fix : 20.3.25 / 21.2.17 / 22.0.1 |
| Produit concerné | Hip3D (20.3.16), KneeMadison (21.2.5). Hip2D et Shoulder3D non affectés |
| Exposition | Internet |
| Priorité retenue | P2 (XSS à exposition internet, continuité mai) |
| Action décidée | Patch : couvert par la même montée que l'Item 1. Audit des patterns de liaison bidirectionnelle avant/après patch |
| Ticket remédiation | À créer en Jira, lié à CICD-170 (peut être groupé avec Item 1) |
| Échéance | 20/07/2026 (J+14) |
| Responsable | Tech Lead Angular |
| Canaux secondaires | GitHub Dependabot (Hip3D, KneeMadison) |

#### Item 3 : CVE-2026-54268

| Champ | Valeur |
|-------|--------|
| Titre | Denial of Service (DoS) via OOM in Date Formatting (formatDate) |
| Source | Angular Security Advisories (GHSA-48r7-hpm6-gfxm) |
| Date publication | 10/06/2026 |
| CVSS | 8.2 (Élevée) |
| Exploité activement (KEV) | Non |
| Exploit public | Non documenté |
| Composant impacté | `@angular/common`. `formatDate` sans borne sur la longueur du format. Fix : 20.3.25 / 21.2.17 / 22.0.1 |
| Produit concerné | Hip3D (20.3.16), KneeMadison (21.2.5). Hip2D et Shoulder3D non affectés |
| Exposition | Internet (client). Exploitation conditionnée à un format de date contrôlable par l'utilisateur (peu probable dans les planificateurs, formats fixés par le développeur) |
| Priorité retenue | P3 (DoS côté client navigateur, CVSS ≥ 7, non KEV ; continuité du traitement mai de la CVE analogue digitsInfo) |
| Action décidée | Patch : couvert par la même montée que les Items 1 et 2 |
| Ticket remédiation | À créer en Jira, lié à CICD-170 (groupé avec Items 1 et 2) |
| Échéance | 05/08/2026 (J+30) |
| Responsable | Tech Lead Angular |
| Canaux secondaires | GitHub Dependabot (Hip3D, KneeMadison) |

> Note remédiation Angular : la montée unique Hip3D 20.3.16 vers 20.3.25 et KneeMadison 21.2.5 vers 21.2.17 résout les Items 1 à 3 et résorbe, de façon cumulative, la dette Angular runtime accumulée révélée par Dependabot sur ces deux modules (CVE-2026-22610, 27970, 32635, 50170, 50171, 52725, 2025-66412). Hip2D et Shoulder3D, déjà montés (21.2.17 et 22.0.4), ne portent aucun de ces items : la convergence de versions engagée au ticket ARCH-VERSIONS-CONVERGENCE produit ses premiers effets.

#### Item 4 : CVE-2026-42987 + CVE-2026-44803 + CVE-2026-44812 + CVE-2026-44815 + CVE-2026-45607 + CVE-2026-45641 + CVE-2026-45648 + CVE-2026-45657 + CVE-2026-47288 + CVE-2026-47291 + CVE-2026-47652 + CVE-2026-48574 (+ CVE-2026-44810)

| Champ | Valeur |
|-------|--------|
| Titre | 13 CVE Critiques Windows Server - Patch Tuesday 09/06/2026 (12 RCE + 1 EoP) |
| Source | Microsoft MSRC Security Update Guide (CSV `msrc_june2026.csv`) |
| Date publication | 09/06/2026 (Patch Tuesday) |
| Sévérité | Critique (13 CVE) |
| Exploité activement (KEV) | Non (0 des 109 CVE de périmètre ne figure au KEV au 01/07/2026) |
| Exploit public | Non documenté à ce stade |
| Composant impacté | Windows Server 2016/2019/2022/2025 : Win32K-GRFX (44803, 44812), Hyper-V (45607, 45641, 47652), Kernel (45657), Kerberos (47288), HTTP.sys (47291), Deployment Services (42987), DHCP Client (44815), Active Directory Domain Services (45648), Media (48574), Cryptographic Services (44810, EoP) |
| Produit concerné | Sous-périmètre Infrastructure d'exécution (OS hôte du portail Symfony + IIS) |
| Exposition | Internet (l'OS porte le portail public via IIS ; CVE-2026-47291 HTTP.sys est le composant noyau directement exposé) |
| Priorité retenue | P2 (Critique + exposition internet + non KEV) |
| Action décidée | Application du rouleau cumulatif Patch Tuesday de juin sur tous les serveurs Windows Server du parc. Validation post-patch sur staging avant prod. Prioriser CVE-2026-47291 (HTTP.sys) |
| Applicabilité | Confirmée par l'écart de build : le parc était plusieurs mois en retard (WS2022 à 20348.2527 à 3807, WS2016 à 14393.3474 à 8330), sous le build du Patch Tuesday de juin. Un serveur est vulnérable aux CVE de juin tant que build < build de juin (WS2022 20348.5256, WS2025 26100.32995, WS2016 14393.9234, sources Microsoft update history) |
| Statut au 06/07/2026 | Remédié sur 16 des 19 serveurs (au build de juin). 3 résiduels : WEBPRODDEDIENNE (WS2025, resté au build de la cible de mai 26100.32860, en deçà du build de juin 26100.32995 ; à noter que son préprod WEBPREPRODDEDIENNE a bien été monté à 26100.32995), WEBPRODGLOBALD (WS2016, 14393.8330, planifié), WEBPRODI2B (WS2016, 14393.3474, planifié). Attention : « Patché » dans l'inventaire infra = « au build de la cible de mai », pas nécessairement « à jour de juin » |
| Ticket remédiation | À créer en Jira, lié à CICD-170 (clôture conditionnée aux 3 serveurs résiduels) |
| Échéance | 20/07/2026 (J+14) |
| Responsable | DevSecOps + équipe infrastructure |
| Canaux secondaires | CERT-FR AVI-0728 (Microsoft Windows) et AVI-0729 (Microsoft .NET) du 10/06 (défense en profondeur) |

#### Item 5 : MSRC Patch Tuesday 09/06/2026 - 96 CVE Important Windows Server

| Champ | Valeur |
|-------|--------|
| Titre | 96 CVE Important Windows Server - Patch Tuesday 09/06/2026 (EoP / InfoDisc / SFB / DoS / RCE) |
| Source | Microsoft MSRC Security Update Guide |
| Date publication | 09/06/2026 |
| Volume | 96 CVE Important en périmètre Windows Server 2016/2019/2022/2025 + .NET / ASP.NET Core. Liste complète dans le CSV source, conservée en annexe |
| Impact dominant | Élévation de privilèges (51), Divulgation d'informations (16), Contournement fonctionnalité de sécurité (14), DoS (7), RCE (5), Falsification (2), Usurpation (1) |
| Exploitation | EoP et SFB nécessitent généralement un accès local préalable, limitant l'exposition internet directe |
| Composant impacté | Windows Server 2016/2019/2022/2025 + .NET / ASP.NET Core |
| Produit concerné | Sous-périmètre Infrastructure d'exécution |
| Exposition | Interne (accès local requis pour la majorité) |
| Priorité retenue | P3 par lot (traitées comme un bloc via le rouleau cumulatif mensuel) |
| Action décidée | Application du Patch Tuesday cumulé en même temps que l'Item 4. Traitement groupé, pas d'action item par item |
| Statut au 06/07/2026 | Remédié sur 16 des 19 serveurs (au build de juin, même rouleau). 3 résiduels : WEBPRODDEDIENNE (WS2025, au build de mai), WEBPRODGLOBALD et WEBPRODI2B (WS2016, planifiés) |
| Ticket remédiation | À créer en Jira, lié à CICD-170 (clôture conditionnée aux 3 serveurs résiduels) |
| Échéance | 05/08/2026 (J+30) |
| Responsable | DevSecOps + équipe infrastructure |

#### Item 6 : Analyse SCA Dependabot juin 2026 (400 alertes / 177 CVE), triée par portée

400 alertes ouvertes (7 critical, 188 high, 172 medium, 33 low), 177 CVE distinctes + 17 alertes sans CVE, 0 en KEV. Chaque paquet est trié par portée à partir du flag `dev` des `package-lock.json` : **runtime** (livré au navigateur de production, exposition internet, applicable, évalué en fiche individuelle) contre **build/dev** (chaîne de build, exposition hors ligne, regroupé car remédiation unique). Résultat : 45 alertes runtime (18 CVE distinctes sur 5 packages : `@angular/*`, tinymce, mathjs) ; 355 alertes build/dev. lodash, d'abord classé runtime par heuristique (lockfile one-platform indisponible), est **reclassé build** après diagnostic (dépendance dev transitive, Item 6c). Liste exhaustive nommée en annexe `annexe_dependabot_june2026.md`. Le regroupement du volet build reste justifié par une exposition hors ligne et une remédiation unique (montée des devDependencies), pas par commodité ; il est **scindé par responsable** (Items 6d-1 one-platform et 6d-2 modules Angular), les repos relevant de deux Tech Leads distincts.

##### Item 6a : CVE-2026-47759 + CVE-2026-47761 + CVE-2026-47762 (tinymce)

| Champ | Valeur |
|-------|--------|
| Titre | 3 XSS TinyMCE (attributs data-mce-, plugin media, commentaires mce:protected) |
| Source | GitHub Dependabot (one-platform) ; GHSA-q742-qvgc-gc2f, GHSA-vg35-5wq7-3x7w, GHSA-v98h-vmpc-fpqv |
| Date publication | Remontée export du 06/07/2026 |
| CVSS | ~8.3 (High) - AV:N/AC:L/PR:L/UI:R/S:C/C:H/I:H |
| Exploité activement (KEV) | Non |
| Composant impacté | tinymce (éditeur riche livré au navigateur). Fix : 7.9.3 / 8.5.1 (5.11.1 pour CVE-2026-47759) |
| Produit concerné | one-platform (frontend portail) |
| Exposition | Internet |
| Priorité retenue | P2 (XSS à exposition internet, continuité mai) |
| Action décidée | Monter tinymce vers >= 7.9.3 (ou 8.5.1). Confirmer la version installée (repo one-platform non disponible localement) |
| Ticket remédiation | À créer en Jira, lié à CICD-170 |
| Échéance | 20/07/2026 (J+14) |
| Responsable | Tech Lead one-platform |

##### Item 6b : CVE-2026-40897 + CVE-2026-41139 (mathjs) - investigation conclue, non exploitable

| Champ | Valeur |
|-------|--------|
| Titre | CWE-915 dans le parseur d'expressions mathjs (setter d'attribut non sûr / getter d'index de tableau non sûr) |
| Source | GitHub Dependabot (plannerHip3D) ; GHSA-29qv-4j9f-fjw5, GHSA-jvff-x2qm-6286 |
| Date publication | Remontée export du 06/07/2026 |
| CVSS | ~8.8 (High) - C:H/I:H/A:H. Plage affectée 13.1.1 à <15.2.0, corrigé 15.2.0 |
| Exploité activement (KEV) | Non |
| Composant impacté | mathjs 15.1.1 installé (dépendance runtime directe, importée dans `nifti-slicer.ts` et `utils-slicer.ts`). Fix : 15.2.0 |
| Produit concerné | plannerHip3D |
| Exposition | Internet (module navigateur) mais **chemin vulnérable non atteint**. Précondition des 2 CVE : évaluation d'expressions arbitraires via le parseur (`math.evaluate/parse/compile/Parser`). Investigation dépôt (17/07/2026) : 0 occurrence de ces API (`grep evaluate|parse|compile|parser|...` hors node_modules) ; mathjs n'est utilisé qu'en algèbre linéaire numérique (subtract, divide, norm, cross, matrix, multiply, transpose, dot). Les données NIfTI n'atteignent mathjs que comme opérandes numériques, jamais comme chaîne d'expression → CWE-915 non déclenchable. **Non exploitable dans l'usage actuel** |
| Priorité retenue | P4 (non exploitable ; montée d'hygiène pour solder le finding SCA et la traçabilité MDR / IEC 62304). Requalifié de P2 après investigation |
| Action décidée | `npm install mathjs@^15.2.0` (15.1.1 → >= 15.2.0) dans Hip3D pour sortir de la plage affectée. Vérifier présence/version dans KneeMadison et Shoulder3D |
| Ticket remédiation | À créer en Jira, lié à CICD-170 |
| Échéance | 04/10/2026 (J+90) |
| Responsable | Tech Lead Angular (Hip3D) |

##### Item 6c : CVE-2026-4800 + CVE-2026-2950 (lodash) - investigation conclue, portée build

| Champ | Valeur |
|-------|--------|
| Titre | Code injection via `_.template` (CVE-2026-4800) + prototype pollution `_.unset`/`_.omit` (CVE-2026-2950) |
| Source | GitHub Dependabot ; GHSA-r5fr-rjxr-66jc, GHSA-f23m-r3pf-42rh |
| CVSS | CVE-2026-4800 8.1 (High) ; CVE-2026-2950 6.5 (Moderate). Affecté 4.0.0 à 4.17.23, corrigé 4.18.0 |
| Exploité activement (KEV) | Non |
| Composant impacté | lodash (version résolue 4.17.23). **Dépendance dev transitive, pas directe** : tirée par jshint (`^2.13.5`) et la chaîne @symfony/webpack-encore (assets-webpack-plugin, pretty-error/renderkid). Toutes les entrées du lock sont `dev:true`. Présent sur one-platform, plannerHip3D, plannerKneeMadison |
| Produit concerné | Chaîne de build uniquement (jamais dans le bundle expédié en production) |
| Exposition | Hors ligne (build). Exploitation réelle faible : aucun appel `_.template`/`_.unset`/`_.omit` du pipeline Webpack/Encore ne reçoit de donnée externe. Enjeu principal : déblocage des scanners CI (Snyk, Trivy, Dependency-Track) |
| Priorité retenue | P4 (portée build, hors ligne, non KEV). Investigation « à investiguer » close : reclassé de runtime (erreur d'heuristique) vers build (dev-only confirmé par lockfile) |
| Action décidée | Forcer lodash 4.18.1 (tag latest) via un bloc `overrides` npm dans chaque repo concerné. **Ne pas** `npm audit fix --force` (rétrograderait jshint en 0.5.9, cassant). CI = npm (`npm install`), pas de yarn.lock : `overrides` est le bon mécanisme |
| Ticket remédiation | À créer en Jira (overrides lodash, par repo), lié à CICD-170 |
| Échéance | 05/08/2026 (J+30) |
| Responsable | Tech Leads one-platform et Angular (selon repo) |

##### @angular/* runtime (Hip3D, KneeMadison) - rattaché aux Items 1 à 3

Les CVE `@angular/*` runtime remontées par Dependabot recouvrent les Items 1 à 3 (CVE-2026-50557, 54265, 54268) plus une dette accumulée sur Hip3D/KneeMadison : CVE-2026-50170, 50171, 52725, 22610, 27970, 32635, CVE-2025-66412, CVE-2021-4231. CVE-2026-54266 (HttpTransferCache) et CVE-2026-54267 (hydration) sont non applicables (features SSR non utilisées). La montée Hip3D vers 20.3.25 et KneeMadison vers 21.2.17 (Items 1 à 3) résorbe ces CVE de façon cumulative là où le correctif est <= version cible. Action : vérifier après montée que Dependabot se vide ; sinon montée mineure complémentaire.

Le lot chaîne de build (exposition hors ligne, 353 alertes build au total) est scindé par responsable, les repos relevant de deux Tech Leads distincts.

##### Item 6d-1 : lot chaîne de build one-platform (42 alertes, Tech Lead one-platform)

| Champ | Valeur |
|-------|--------|
| Titre | Dépendances de chaîne de build one-platform (devDependencies) |
| Source | GitHub Dependabot (repo one-platform) |
| Volume | 42 alertes build (dont lodash, cf. Item 6c) : 1 critical, 21 high, 19 medium, 1 low. 36 CVE distinctes + 1 sans CVE |
| Exploité activement (KEV) | Non (0) |
| Composant impacté | Outillage build npm one-platform. Critical : shell-quote (CVE-2026-9277) |
| Produit concerné | Chaîne de build one-platform |
| Exposition | Hors ligne (non livré au navigateur ; IIS sert le bundle compilé) |
| Priorité retenue | P4 en lot |
| Action décidée | Campagne npm audit / montée des devDependencies one-platform. Traiter d'abord shell-quote (critical) |
| Ticket remédiation | À créer en Jira (lot SCA one-platform), lié à CICD-170 |
| Échéance | 04/10/2026 (J+90) |
| Responsable | Tech Lead one-platform |
| Traçabilité | Annexe `annexe_dependabot_june2026.md` (section build, repo one-platform) |

##### Item 6d-2 : lot chaîne de build modules Angular (313 alertes, Tech Lead Angular)

| Champ | Valeur |
|-------|--------|
| Titre | Dépendances de chaîne de build des planificateurs Angular (devDependencies) |
| Source | GitHub Dependabot (repos plannerHip3D, plannerKneeMadison, plannerShoulder3D) |
| Volume | 313 alertes build (Hip3D 164, KneeMadison 147, Shoulder3D 2) : 6 critical, 139 high, 136 medium, 32 low. 157 CVE distinctes + 16 sans CVE |
| Exploité activement (KEV) | Non (0) |
| Composant impacté | Outillage build npm : webpack, vite, rollup, esbuild, babel, tar, protobufjs, @grpc/grpc-js, sigstore, minimatch, node-forge, undici, ws, etc. Criticals : shell-quote (CVE-2026-9277), handlebars (CVE-2026-33937), protobufjs (CVE-2026-41242), basic-ftp (CVE-2026-27699) |
| Produit concerné | Chaîne de build des planificateurs Angular |
| Exposition | Hors ligne (non livré au navigateur). Profil proche de l'exclusion Docker/Nginx du plan §3, conservé applicable en lot par prudence |
| Priorité retenue | P4 en lot |
| Action décidée | Campagne npm audit / montée des devDependencies. Traiter d'abord les 4 criticals. Charge concentrée sur Hip3D et KneeMadison ; Shoulder3D quasi propre (2 low) |
| Ticket remédiation | À créer en Jira (lot SCA modules Angular), lié à CICD-170 |
| Échéance | 04/10/2026 (J+90) |
| Responsable | Tech Lead Angular |
| Traçabilité | Annexe `annexe_dependabot_june2026.md` (section build), ex. CVE-2026-49356 `@babel/core` (low). Les CVE build sont largement partagées entre repos (union = 157 CVE distinctes tous repos confondus) |

#### MariaDB : pas de nouvel item en juin

MariaDB Community Server : **0 nouvelle CVE publiée en juin** (le document de référence liste les mêmes 14 CVE-2026 qu'en mai). Les 13 CVE applicables de mai restent vives (parc inchangé, montée non faite) mais ne constituent pas une découverte de juin : pour éviter tout doublon, leur suivi, le point d'attention CVE-2026-49261 (CVSS 10.0) et le plan de remédiation sont portés au **§5** (décision mai #7). Matrice d'applicabilité détaillée : rapport de mai. Trace de consultation de la source en §2.

#### Item 7 : Node.js Security Release 18/06/2026 (12 CVE)

| Champ | Valeur |
|-------|--------|
| Titre | Node.js Security Release 18/06/2026 - 12 CVE (WebCrypto, TLS, HTTP/2, permission model) ; principales : CVE-2026-48933 (WebCrypto, High), CVE-2026-48618 (TLS hostname, High) |
| Source | Node.js Security ; recoupé par CERT-FR AVI-0786 (18/06) |
| Date publication | 18/06/2026 |
| CVSS | 2 High (WebCrypto, TLS hostname) + 6 Medium + 4 Low. Score chiffré non communiqué par Node |
| Exploité activement (KEV) | Non |
| Composant impacté | Runtime Node.js **présent sur les serveurs** (correction : Node n'est pas absent de la prod). Correctifs : ligne 22 → 22.23.0, ligne 24 → 24.17.0, ligne 26 → 26.3.1 |
| Produit concerné | Sous-périmètre Infrastructure (serveurs web) |
| Parc Node relevé | 14 instances ligne 22.x (22.13.0 à 22.21.0), **toutes < 22.23.0 → vulnérables** au batch de juin. 1 instance ligne 20 (SAAS preprod 20.19.5) : ligne 20 hors batch de juin. 1 instance Node 16.13.2 (GLOBALD prod) : **EOL**, hors batch mais critique |
| Exposition | Hors ligne (build). Rôle confirmé : Node ne sert qu'à `npm run build` des modules Angular (bundle ensuite servi par l'app Symfony via IIS). Aucun service réseau Node, aucune entrée externe vers les fonctions vulnérables (TLS/HTTP2/WebCrypto/permission) : exploitation réelle quasi nulle |
| Priorité retenue | P4 (exposition hors ligne, non KEV ; aligné sur le traitement du volet build). La matrice donnerait nominalement P3 pour les 2 CVE High, mais l'usage build-only sans entrée externe justifie P4, comme le reste de la chaîne de build |
| Action décidée | 1) Monter la ligne 22 vers >= 22.23.0 sur les 14 instances (hygiène + déblocage scanners CI). 2) **Point d'attention hors batch** : GLOBALD prod (Node 16.13.2, EOL, fin de support) à traiter en priorité ; SAAS preprod (Node 20.19.5) à aligner |
| Ticket remédiation | À créer en Jira, lié à CICD-170 |
| Échéance | 04/10/2026 (J+90) pour la montée ligne 22 ; GLOBALD (Node 16 EOL) à anticiper |
| Responsable | DevSecOps + équipe infrastructure |
| Canaux secondaires | CERT-FR AVI-0786 (18/06) |

### 3.3 Items non applicables (traçabilité)

#### Angular Security Advisories (juin, non applicables)

| GHSA | CVE | Titre | Raison non applicabilité |
|------|-----|-------|--------------------------|
| GHSA-hqr9-c56f-3x7f | CVE-2026-50556 | XSS domino `<noscript>` SSR (platform-server) | `@angular/platform-server` absent des 4 modules + pas de SSR |
| GHSA-gxx4-3xcv-f8qx | CVE-2026-50555 | XSS sérialisation texte SSR (platform-server) | `@angular/platform-server` absent + pas de SSR |
| GHSA-qxh6-94w6-9r5p | CVE-2026-54264 | Fuite d'en-têtes cross-origin (service worker) | `@angular/service-worker` absent des modules |
| GHSA-39pv-4j6c-2g6v | CVE-2026-54266 | Hachage 32 bits faible HttpTransferCache | HttpTransferCache lié au SSR, non utilisé (SPA client) |
| GHSA-rgjc-h3x7-9mwg | CVE-2026-54267 | DOM Clobbering hydration (provideClientHydration) | Hydration SSR non utilisée par les planificateurs (SPA) |

#### Symfony Security Advisories (juin, non applicables)

| CVE | Titre | Raison non applicabilité |
|-----|-------|--------------------------|
| CVE-2026-55878 | Path Traversal dans symfony/ux-toolkit | `symfony/ux-*` absent du composer.lock |
| CVE-2026-55877 | XSS dans symfony/ux-icons (SVG/Iconify) | `symfony/ux-*` absent du composer.lock |

#### PHP (juin, non applicables)

| CVE | Titre | Raison non applicabilité ou statut |
|-----|-------|-----------------------------------|
| CVE-2026-44927 | uriparser : troncature différence de pointeur | Extension URI (uriparser) introduite en PHP 8.4 ; absente de la branche 8.1 (contrainte composer.json `>=8.1`). À investiguer : version PHP réellement déployée en prod |
| CVE-2026-44928 | uriparser : classification incorrecte d'URI | Idem |

#### Node.js (juin) - reclassé applicable

Le batch du 18/06 est **applicable** : Node.js est présent sur les serveurs (prod et préprod) à des versions inférieures au correctif de juin. Traité en Item 7 du §3.2 (et non plus en non applicable : l'hypothèse initiale « pas de Node en production » est corrigée par le relevé des versions serveur).

#### CISA KEV (juin, hors stack)

23 CVE ajoutées au catalogue KEV en juin 2026, **0 sur le stack OneOrtho**.

| CVE | Date d'ajout | Vendor / Produit | Raison non applicabilité |
|-----|--------------|------------------|--------------------------|
| CVE-2024-21182 | 01/06/2026 | Oracle / WebLogic Server | WebLogic non utilisé |
| CVE-2022-0492 | 02/06/2026 | Linux / Kernel | OS de production = Windows Server, pas de Linux en prod |
| CVE-2025-48595 | 02/06/2026 | Android / Framework | Pas de composant mobile Android |
| CVE-2026-45247 | 03/06/2026 | Mirasvit / Full Page Cache Warmer (Magento) | Magento/Mirasvit non utilisés |
| CVE-2026-28318 | 05/06/2026 | SolarWinds / Serv-U | Serv-U non utilisé |
| CVE-2026-42271 | 08/06/2026 | BerriAI / LiteLLM | LiteLLM non utilisé |
| CVE-2026-50751 | 08/06/2026 | Check Point / Security Gateway | Équipement Check Point non utilisé |
| CVE-2026-11645 | 09/06/2026 | Google / Chromium V8 | Moteur navigateur, pas un composant livré du produit OneOrtho |
| CVE-2026-7473 | 09/06/2026 | Arista / EOS | Équipement réseau Arista non utilisé |
| CVE-2026-20245 | 09/06/2026 | Cisco / Catalyst SD-WAN Manager | Équipement réseau Cisco non utilisé |
| CVE-2026-10520 | 11/06/2026 | Ivanti / Sentry | Ivanti Sentry non utilisé |
| CVE-2026-35273 | 12/06/2026 | Oracle / PeopleSoft | PeopleSoft non utilisé |
| CVE-2026-54420 | 15/06/2026 | LiteSpeed / cPanel Plugin | LiteSpeed/cPanel non utilisés |
| CVE-2026-20262 | 15/06/2026 | Cisco / Catalyst SD-WAN Manager | Équipement réseau Cisco non utilisé |
| CVE-2026-48907 | 16/06/2026 | Widget Factory / Joomla Content Editor | Joomla non utilisé |
| CVE-2026-20253 | 18/06/2026 | Splunk / Enterprise | Splunk non utilisé |
| CVE-2025-67038 | 23/06/2026 | Lantronix / EDS5000 | Équipement Lantronix non utilisé |
| CVE-2026-34910 | 23/06/2026 | Ubiquiti / UniFi OS | Équipement réseau Ubiquiti non utilisé |
| CVE-2026-34909 | 23/06/2026 | Ubiquiti / UniFi OS | Équipement réseau Ubiquiti non utilisé |
| CVE-2026-34908 | 23/06/2026 | Ubiquiti / UniFi OS | Équipement réseau Ubiquiti non utilisé |
| CVE-2026-12569 | 25/06/2026 | PTC / Windchill et FlexPLM | PLM PTC non utilisé |
| CVE-2026-20230 | 25/06/2026 | Cisco / Unified Communications Manager | Téléphonie Cisco non utilisée |
| CVE-2026-48558 | 29/06/2026 | SimpleHelp / SimpleHelp | Outil de support à distance non utilisé |

#### MariaDB (non applicable)

| CVE | Raison non applicabilité |
|-----|--------------------------|
| CVE-2026-21968 (CVSS 6.5) | Parc aux versions exactes porteuses du fix (11.8.4/11.4.9/10.11.15/10.6.24). Couverte sur les 16 instances |

#### Items hors périmètre (tracés, non comptés en applicables)

| Avis | Source | Motif d'exclusion du périmètre |
|------|--------|--------------------------------|
| FDA Safety Communication du 03/06/2026 (Hintermann Series H3 Total Ankle Replacement, Joint Replacement) | FDA | Rappel clinique sur un implant tiers (défaillance dispositif), sujet non-cyber et produit non OneOrtho. Hors périmètre threat intel |

#### CERT-FR (ANSSI) - juin complet (01/06 au 30/06), items écartés

Juin 2026 entièrement consulté via l'archive `/avis/` (pages 1 à 17, AVI-0668 daté du 01/06 à AVI-0819 daté du 30/06), le flux RSS ne renvoyant qu'une fenêtre glissante. Trois avis recoupent le stack en canal secondaire (déjà captés par les sources primaires, aucun item nouveau) : CERTFR-2026-AVI-0728 (Microsoft Windows) et AVI-0729 (Microsoft .NET) du 10/06 confirment le Patch Tuesday MSRC (Items 4 et 5) ; CERTFR-2026-AVI-0786 (Node.js, 18/06) confirme le batch Node du 18/06 (§3.3 Node). Aucun avis Angular, Symfony, MariaDB, PHP-core, Three.js ou DICOM (ces composants passent par les advisories éditeurs, source primaire).

Éditeurs écartés (produit non utilisé par OneSoftware) : cURL/libcurl, Tenable, Azure Linux, Google Chrome, GitLab, CPython, noyaux Linux (Debian/SUSE/Red Hat/Ubuntu), IBM, Asterisk, HAProxy, Mattermost, KeyCloak, Microsoft Edge, Stormshield, Apache Tomcat/HTTP Server, Apple, Synology, Mozilla Firefox/Thunderbird, Citrix, Adobe ColdFusion, ClamAV, Cisco, Elastic, Traefik, FreeBSD, Nginx (AVI-0775, hors périmètre), Laravel, Spring, Oracle (MySQL/PeopleSoft/WebLogic), MongoDB, GLPI, Fortinet, Ivanti, NetApp, Mitel, Kaspersky.

**Alertes CERT-FR (`/alerte/`)** : aucune nouvelle alerte publiée en juin (ALE-005 reste la dernière de 2026). Les alertes actives concernent des produits hors stack : CERTFR-2026-ALE-005 (Microsoft Exchange, CVE-2026-42897, exploitation active, mise à jour 11/06) - Exchange non hébergé par OneOrtho, donc non applicable ; CERTFR-2026-ALE-004 (F5 BIG-IP APM) et CERTFR-2026-ALE-001 (Ivanti EPMM) hors stack. Conséquence : aucune menace activement exploitée signalée par CERT-FR ne touche le périmètre, ce qui conforte l'absence de P1. Les actualités (`/actualite/`, ex. ACT-028 du 29/06) sont des bulletins de synthèse non détaillés par CVE, non itemisés.

#### CISA ICS / ICSMA du 01/06 au 30/06/2026 - 50 advisories, 0 applicable

Consultés via `curl` (pages 2 à 6, WebFetch bloqué par WAF) : **50 advisories** (5 ICSMA médical + 45 ICSA industriel), extraction en pièce probante `sources/cisa_ics_june2026.md` (captures d'écran officielles archivées dans le SharePoint entreprise). Aucun applicable, mais **3 advisories DICOM ont fait l'objet d'une vérification** car DICOM est dans le périmètre (§2.2 du plan) :

**ICS Medical Advisories (ICSMA)**

| Identifiant | Date | Produit | Raison non applicabilité |
|-------------|------|---------|--------------------------|
| ICSMA-26-176-01 | 25/06/2026 | pydicom / pynetdicom (bibliothèques Python) | Pas de composant Python DICOM chez OneOrtho. Le parsing DICOM est fait par `oneortho/nanodicom` (PHP, v1.4.0) et `nifti-reader-js` (JS), pas par pydicom/pynetdicom |
| ICSMA-26-176-02 | 25/06/2026 | OHIF Viewers (DICOM) | Viewer OHIF (React) non utilisé ; les planificateurs sont en Angular avec rendu propre (Three.js / nifti-reader-js). Aucune dépendance `@ohif` dans les package.json |
| ICSMA-26-181-01 | 30/06/2026 | OFFIS DCMTK Toolkit (C++) | DCMTK non utilisé ; aucun binaire/wrapper DCMTK dans le stack. DICOM traité via nanodicom (PHP) |
| ICSMA-26-169-01 | 18/06/2026 | Apollo Pharmacy Blood Glucose Monitoring APG-01 BT | Glucomètre, dispositif non OneOrtho |

Vérification menée sur le stack réel : implémentations DICOM d'OneOrtho = `oneortho/nanodicom` v1.4.0 (PHP) + `nifti-reader-js` ^0.8.0 (Hip3D, KneeMadison, Shoulder3D). Aucune des trois implémentations visées (pydicom, OHIF, DCMTK) n'est présente → non applicables, mais tracées comme vérifiées (pas écartées à l'aveugle). Point de vigilance reporté au §7 : surveiller nanodicom et nifti-reader-js, qui sont la vraie surface DICOM.

**ICS Advisories industriels (45 items)** - tous hors périmètre (systèmes industriels / SCADA / IoT non utilisés) : Schneider Electric (×8), Rockwell (×6), Siemens (×5), Hitachi Energy (×3), Mitsubishi Electric (×3), ABB, Delta, Yokogawa, Horner, Daktronics, Hubbell, AzeoTech, Frangoteam, CP Plus, KMW, XCharge, NAVTOR, B&R, Yarbo, Naxclow, Brickcom, AVer, H.VIEW, EVoke, Impact. Liste complète en pièce probante.

---

## 4. Tendances observées

Le mois de juin 2026 confirme la charge élevée sur la stack OneOrtho, avec un basculement du volume vers l'infrastructure et la SCA :

- **Microsoft Patch Tuesday du 09/06** : 220 CVE de juin dans l'export, 109 en périmètre Windows Server/IIS/.NET, dont 13 Critiques (12 RCE) contre 6 en mai. Le parc hétérogène (4 versions Windows Server) reste un multiplicateur d'effort. CVE-2026-47291 (HTTP.sys) est le point le plus sensible car directement exposé derrière IIS.
- **Angular** : batch de 8 GHSA (02 au 10/06). Seuls 3 sont applicables (2 XSS runtime, 1 DoS `formatDate`), et uniquement sur Hip3D et KneeMadison. Hip2D (21.2.17) et Shoulder3D (22.0.4), déjà montés, sont hors de portée : premier bénéfice mesurable de la convergence de versions. Les 5 autres GHSA (platform-server, service-worker, HttpTransferCache, hydration) confirment que les modules utilisent un sous-ensemble Angular sans SSR.
- **Première compilation Dependabot** (décision mai #13 rattrapée) : 400 alertes ouvertes, 177 CVE distinctes, 0 en KEV. Triage par portée (flag `dev` des lockfiles) : 20 CVE runtime livrées au navigateur, traitées en fiches individuelles (tinymce, mathjs, lodash, plus la dette Angular runtime de Hip3D/KneeMadison recouverte par la montée) ; 157 CVE de chaîne de build, exposition hors ligne, regroupées en deux lots P4 par Tech Lead (one-platform, Item 6d-1 ; modules Angular, Item 6d-2). Ce triage remplace l'agrégation initiale : chaque alerte runtime est évaluée comme tout item de la revue, le regroupement ne s'appliquant qu'au volet build (remédiation unique). Contraste net entre Hip3D/KneeMadison (dette lourde) et Shoulder3D (2 alertes low), cohérent avec l'avancement de la convergence de versions.
- **MariaDB** : aucune nouvelle CVE en juin. Les 13 CVE de mai (dont CVE-2026-49261 CVSS 10.0) restent applicables faute de montée constatée : le sujet glisse du statut « découverte » au statut « suivi de remédiation » (§5).
- **Node.js** : le relevé des versions serveur a corrigé une hypothèse initiale erronée (« pas de Node en production »). Node est présent sur les serveurs, mais son rôle est confirmé **build-only** (`npm run build` des modules Angular, bundle servi ensuite par Symfony/IIS) : exposition hors ligne, exploitation réelle quasi nulle, donc P4 malgré 2 CVE High. Le batch du 18/06 est applicable (Item 7). Point saillant du relevé : un runtime **Node 16 EOL sur GLOBALD prod**, à traiter indépendamment du batch (fin de support).
- **Symfony / PHP / Three.js / DICOM** : faible impact. Symfony 19/06 = 2 CVE `ux-*` non applicables. PHP = 2 CVE uriparser hors branche 8.1. Three.js et DICOM = 0 item.
- **Exploitation active** : aucune CVE applicable au stack n'est en KEV actif (0 hit sur 23 ajouts de juin, sur 109 CVE MSRC de périmètre et sur 177 CVE Dependabot), et aucune alerte CERT-FR active (ALE-005 Exchange, ALE-004 F5, ALE-001 Ivanti) ne touche le périmètre. Double confirmation de l'absence de déclencheur P1.
- **DICOM** : premier mois où la veille CISA ICSMA remonte des advisories DICOM (DCMTK, OHIF, pydicom/pynetdicom). Aucun applicable, mais la vérification a confirmé que la surface DICOM réelle d'OneOrtho est `nanodicom` (PHP) et `nifti-reader-js` (JS), à intégrer à la veille ciblée (§7).
- **Sources non couvertes** : seul Snyk reste non fourni ce mois (CISA ICS rattrapée via curl). La mise en service de FreshRSS et l'automatisation MSRC/Dependabot restent prioritaires.

---

## 5. Suivi des items des mois précédents

Renseigné à partir du rapport de mai 2026 (CICD-169) et des statuts de remédiation communiqués par l'équipe le 06/07/2026.

| Item (mois origine) | Ticket / décision mai | Statut | Commentaire |
|---------------------|-----------------------|--------|-------------|
| CVE-2026-46626 symfony/runtime | Décision #1 (30/06) | En cours | Ticket créé, non encore traité |
| CVE-2026-45065 symfony/routing | Décision #2 (30/06) | En cours | Ticket créé, non encore traité |
| Patch Tuesday mai 6 RCE Critical | Décision #4 (30/06) | Fait (17/19 au build de mai) | Build de mai : WS2022 20348.5139, WS2025 26100.32860, WS2016 14393.9140. Résiduels WS2016 : WEBPRODGLOBALD (14393.8330) et WEBPRODI2B (14393.3474), planifiés |
| Patch Tuesday mai 62 Important | Décision #5 (14/07) | Fait (17/19 au build de mai) | Même rouleau. Résiduels : WEBPRODGLOBALD, WEBPRODI2B |
| Microsoft Defender CVE-2026-45498 (Item 7 mai) | Décision #6 | Fait - clôturé | WEBPREPRODI2B et WEBPRODI2B patchés (AMProductVersion 4.18.26050.15) le 01/07/2026. Item mai clos |
| MariaDB montée 16 instances (0 nouvelle CVE en juin) | Décision #7 (14/07) | Non commencé | Ticket créé, non traité. Parc inchangé (8× 11.8.5, 2× 11.4.9, 2× 10.11.15, 4× 10.6.24 = 16 instances). 13 CVE de mai toujours applicables, dont CVE-2026-49261 (CVSS 10.0) sur les 16 instances. Plan : montée vers 11.8.8 / 11.4.12 / 10.11.18 / 10.6.27 (cumulatif, couvre les 13 CVE). Matrice détaillée : rapport de mai. Accélération recommandée (décision §6 #11) |
| 4 fonctions PHP à investiguer (urldecode, mb_convert_encoding, DOMNode::C14N, mb_check_encoding) | Décision #8 (30/06) | Non traité | Investigation non démarrée. Reste P3 par défaut. Version PHP prod non confirmée (impacte aussi uriparser §3.3) |
| Angular XSS Template/Component (GHSA-692r) | Décision #10 (30/06) | En cours | Hip2D (21.2.17) et Shoulder3D (22.0.4) montés (couvrent aussi les CVE de juin) ; Hip3D et KneeMadison montés en code mais pas encore déployés en prod pour tous les modules 2D/3D |
| Angular DoS digitsInfo (GHSA-p3vc) | Décision #11 (14/07) | En cours | Ticket créé ; aligné sur D10 (même montée). Hip3D et KneeMadison en attente |
| Compilation Snyk + Dependabot | Décision #13 (04/06) | Partiellement fait | Dependabot compilé ce mois (Item 6). Snyk toujours en attente (§6) |
| X509Authenticator (CVE-2026-45063) | Décision #3 | Fait - non applicable | Levé après investigation en mai |
| Twig sandbox (3 CVE) | Décision #9 | Fait - non applicable | Levé après investigation en mai |
| CISA ICS / FDA manuels mai | Décision #12 | Fait | Consultés manuellement en mai |

Parc Windows Server (19 serveurs, statut au 06/07/2026) : WS2022 ×11 (WEBPRODSAAS, WEBPREPRODSAAS, WEBTESTSAAS, WEBPRODFH, WEBPREPRODFH, WEBPRODEVOLUTIS, WEBPREPRODEVOLUTIS, WEBPRODKERI, WEBPREPRODKERI, WEBPRODLEPINE, WEBPREPRODLEPIN), WS2025 ×4 (WEBPRODDEDIENNE, WEBPREPRODDEDIENNE, WEBPRODSTRYKER, WEBPREPRODSTRYKER), WS2016 ×4 (SERF-PROD, WEBPREPRODI2B, WEBPRODGLOBALD, WEBPRODI2B). Au build de juin : 16/19. Résiduels juin : WEBPRODDEDIENNE (WS2025, resté au build de mai 26100.32860), WEBPRODGLOBALD et WEBPRODI2B (WS2016, planifiés). « Patché » dans l'inventaire infra signifie « au build de la cible de mai », à ne pas confondre avec « à jour de juin » : c'est ce qui distingue WEBPRODDEDIENNE (conforme mai, résiduel juin).

Items récurrents à re-suivre : convergence des versions (Angular 20.3/21.2/22.0, Three.js 0.150 à 0.185, MariaDB 4 branches LTS) via ARCH-VERSIONS-CONVERGENCE ; cause racine canal de mise à jour (plateforme Defender clôturée en juin, montée à AMProductVersion 4.18.26050.15).

---

## 6. Décisions et actions

Échéances calculées depuis la date de revue (06/07/2026) : P1 J+3 = 09/07, P2 J+14 = 20/07, P3 J+30 = 05/08, P4 J+90 = 04/10.

| # | Décision / Action | Item lié | Responsable | Échéance | Statut |
|---|-------------------|----------|-------------|----------|--------|
| 1 | Monter Hip3D (20.3.16 → 20.3.25) et KneeMadison (21.2.5 → 21.2.17) : couvre les 2 XSS + le DoS de juin et la dette Angular runtime accumulée | Items 1, 2, 3 | Tech Lead Angular | 20/07/2026 | À faire |
| 2 | Appliquer le Patch Tuesday Windows Server du 09/06 sur le parc - volet Critique (13 CVE), prioriser CVE-2026-47291 HTTP.sys | Item 4 | DevSecOps + infrastructure | 20/07/2026 | En cours (16/19 au build de juin ; 3 résiduels) |
| 3 | Appliquer le rouleau cumulatif pour les 96 CVE Important Windows Server (même passage que #2) | Item 5 | DevSecOps + infrastructure | 05/08/2026 | En cours (16/19 au build de juin ; 3 résiduels) |
| 4 | Monter tinymce (>= 7.9.3) sur one-platform : item SCA runtime P2 | Item 6a | Tech Lead one-platform | 20/07/2026 | À faire |
| 5 | Traiter le lot build modules Angular (Item 6d-2, 313 alertes P4), d'abord les 4 criticals (shell-quote, handlebars, protobufjs, basic-ftp) ; montée d'hygiène mathjs vers 15.2.0 (Item 6b) | Items 6b, 6d-2 | Tech Lead Angular | 04/10/2026 | Investigation mathjs conclue le 17/07 (non exploitable : parseur d'expressions non utilisé) ; lot build + montée mathjs à faire |
| 6 | Investiguer la version PHP réellement déployée en prod (applicabilité uriparser CVE-2026-44927/44928 : concernée si 8.4/8.5) | §3.3 PHP | DevSecOps | 05/08/2026 | À faire |
| 7 | Node.js (batch 18/06, Item 7, build-only P4) : monter la ligne 22 vers >= 22.23.0 sur les 14 instances (hygiène + scanners CI) ; traiter en priorité GLOBALD prod (Node 16.13.2 EOL, hors batch) + aligner SAAS preprod (Node 20.19.5) | Item 7 | DevSecOps + infrastructure | 04/10/2026 ; GLOBALD EOL à anticiper | À faire |
| 8 | Consultation CISA ICS / ICSMA de juin | Source §2 | DevSecOps | 08/07/2026 | Fait (scrapé via curl, 50 advisories, 0 applicable ; 3 advisories DICOM vérifiés non applicables ; captures archivées SharePoint) |
| 9 | Rattraper l'export Snyk SCA de juin (console interne) | Source §2 | DevSecOps | 08/07/2026 (avant validation) | À faire |
| 10 | Relancer les décisions mai encore ouvertes : Symfony runtime/routing (tickets créés non traités, D1/D2), 4 fonctions PHP (investigation non démarrée, D8), montée Angular Hip3D/KneeMadison en prod (D10/D11) | §5 | Tech Leads + DevSecOps | 20/07/2026 | À faire |
| 11 | Accélérer la montée MariaDB (13 CVE mai toujours applicables, CVE-2026-49261 CVSS 10.0) : ne pas laisser glisser au-delà de J+30 | §5 (report mai) | DevSecOps + infrastructure | 05/08/2026 | À faire |
| 12 | Monter au build de juin les 3 serveurs résiduels pour clôturer les Items 4 et 5 : WEBPRODDEDIENNE (WS2025, 26100.32860 vers 26100.32995), WEBPRODGLOBALD et WEBPRODI2B (WS2016, vers 14393.9234) | Items 4, 5 / §5 | DevSecOps + infrastructure | 20/07/2026 | À faire |
| 13 | Traiter le lot build one-platform (Item 6d-1, 40 alertes P4), d'abord shell-quote (critical) ; investiguer l'usage de `_.template` lodash (Item 6c) | Items 6c, 6d-1 | Tech Lead one-platform | 04/10/2026 (lot) ; 05/08/2026 (investig.) | À faire |

---

## 7. Recommandations pour le mois suivant

### Côté plan et processus

- **Clarifier la matrice §4.4 pour les cas frontaux** : XSS applicatif à exposition internet (souvent CVSS modéré mais risque réel) et DoS côté client (CVSS élevé mais impact limité au navigateur de la victime). La classification retenue en mai et reconduite en juin (XSS = P2, DoS client = P3) dévie de la lecture stricte de la matrice. Formaliser une règle explicite pour lever l'ambiguïté récurrente.
- **Poursuivre ARCH-VERSIONS-CONVERGENCE** : la convergence porte ses fruits (Hip2D et Shoulder3D hors de portée du batch Angular de juin). Cible : aligner Hip3D et KneeMadison, réduire la dette transitive révélée par Dependabot.
- **Surveiller les vraies briques DICOM du stack** : les 3 advisories DICOM de juin (DCMTK, OHIF, pydicom/pynetdicom) ne concernaient pas OneOrtho, mais ont montré que la veille DICOM générique n'est pas ciblée. Ajouter `oneortho/nanodicom` (PHP, v1.4.0) et `nifti-reader-js` (JS) comme composants explicitement suivis (advisories GitHub / NVD), puisqu'ils constituent la surface DICOM réelle. nanodicom étant un fork interne, prévoir une veille du dépôt amont.

### Côté outillage

- **Automatiser l'export MSRC** via l'API CVRF `https://api.msrc.microsoft.com/cvrf/v3.0/` en début de mois post-Patch Tuesday.
- **Mettre en place FreshRSS** pour les sources RSS. Le flux CERT-FR ne renvoie qu'une fenêtre glissante ; ce mois la couverture complète de juin a été obtenue manuellement via l'archive `/avis/` (17 pages), à automatiser (agrégateur ou script de pagination) pour éviter cet effort récurrent.
- **Industrialiser la compilation Dependabot** (API GitHub) et **arbitrer Snyk vs Dependabot vs Dependency-Track** pour le volet SCA, en cohérence avec la souveraineté SBOM. La duplication Snyk/Dependabot n'est pas soutenable manuellement.

### Côté gouvernance

- **Mettre à jour l'inventaire `curent-mariadb-onserver.md`** après la montée MariaDB, pour éviter de re-remonter des CVE déjà corrigées (le parc est inchangé depuis mai, source d'ambiguïté).
- **Activer ou retirer H-ISAC** du plan §3.2 selon la décision d'accès.

### Sujets à traiter dans le rapport de juillet 2026

- Statut des 11 décisions §6 ci-dessus.
- Rattrapage de l'export Snyk de juin (CISA ICS déjà rattrapée).
- Confirmation des statuts des décisions mai ouvertes (§5).
- Patch Tuesday de juillet 2026 (anticiper le volume).
- Effet de la campagne SCA Dependabot sur le nombre d'alertes ouvertes.

---

## 8. Export

- Pièces probantes archivées avec le rapport : fichiers de `sources/` (KEV, MSRC, MariaDB, FDA, Dependabot x4, `cisa_ics_june2026.md`) + annexe de traçabilité SCA `annexe_dependabot_june2026.md` (177 CVE Dependabot nommées) + captures d'écran CISA ICS/ICSMA dans le SharePoint entreprise.
- Publication Confluence : espace CyberSécurité > PSSI > Threat Intelligence, page `2026-06 Revue Threat Intelligence`.
- Export PDF SharePoint OneOrthoGED : `Rapport mensuel - Revue Threat Intelligence - 2026-06.pdf`.
- Notification Slack #comité_technique avec lien Confluence.

---

## Note de validation

Rapport en statut **DRAFT**. CISA ICS / ICSMA a été rattrapée (décision #8 : 50 advisories, 0 applicable, 3 DICOM vérifiés, captures archivées SharePoint). Il reste **une seule source non fournie** : l'export Snyk SCA de juin (décision #9). Dependabot couvre partiellement le besoin SCA ce mois. La bascule DRAFT → VALIDATED (prévue le 08/07/2026) reste conditionnée à ce rattrapage Snyk, conformément au garde-fou du plan.

*Document généré dans le cadre du processus de revue Threat Intelligence - ISO 27001 A.5.7 / MDR Annexe I §17.2 / IEC 62304.*
