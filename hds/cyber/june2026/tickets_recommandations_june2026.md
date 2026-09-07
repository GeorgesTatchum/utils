# Tickets de recommandation / amélioration - Threat Intelligence juin 2026

Brouillon à coller dans Jira (pas une création automatique). Dérivé du rapport `rapport_threat_intel_june2026.md` §7 (recommandations) et §5 (suivi). Format : variante « recommandation / amélioration » de `jira-ticket-template.md`.

Rattachés au **même ticket de session** que les remédiations (SEC-THREATINTEL-2026-06 / CICD-170), mais de **nature différente** : tickets **persistants** d'amélioration (Story qui traverse les mois), horizon **trimestriel**, **pas de SLA J+n** ; une recommandation récurrente réutilise son ticket standing (ne pas recréer). But : donner un porteur + une échéance à chaque recommandation pour qu'elle cesse de revenir faute de visibilité.

| Champ | Valeur |
|-------|--------|
| Origine | Revue Threat Intelligence 2026-06 (SEC-THREATINTEL-2026-06 / CICD-170) |
| Rattachement | SEC-THREATINTEL-2026-06 (CICD-170) - même ticket de session que les tickets de remédiation |
| Horizon par défaut | Q3 2026 |

## Sommaire

| # | Recommandation | Thème | Responsable | Horizon | Récurrence | Ticket |
|---|----------------|-------|-------------|---------|------------|--------|
| R1 | Clarifier la matrice §4.4 (XSS internet / DoS client) | process | DevSecOps + Responsable Numérique | Q3 2026 | juin | à créer |
| R2 | Convergence des versions (Angular / Three.js / MariaDB LTS) | architecture | Tech Leads Angular + infra | Q4 2026 | mai + juin | ARCH-VERSIONS-CONVERGENCE (existant) |
| R3 | Veille ciblée DICOM (nanodicom, nifti-reader-js) | veille | DevSecOps | Q3 2026 | juin | à créer |
| R4 | Automatiser l'export MSRC (API CVRF v3.0) | outillage | DevSecOps + infra | Q3 2026 | mai + juin | à créer (script livré 04/09, à valider sur un 2e mois) |
| R5 | Mettre en place FreshRSS (sources RSS) | outillage | DevSecOps | Q3 2026 | mai + juin | à créer (angle mort) |
| R6 | Industrialiser la SCA (Dependabot API + arbitrage Snyk / Dependency-Track) | outillage | DevSecOps | Q3 2026 | mai + juin | à créer |
| R7 | Mettre à jour l'inventaire MariaDB après montée | gouvernance | DevSecOps + infra | Q3 2026 | juin | à créer |
| R8 | Activer ou retirer H-ISAC du plan §3.2 | gouvernance | Responsable Numérique | Q3 2026 | mai + juin | à créer |
| R9 | Mettre en place le relevé mensuel du parc Windows (build/UBR par serveur) | outillage + gouvernance | DevSecOps + infra | Q3 2026 | apparue en septembre | à créer (relevé juin déposé et validé 04/09, à reproduire en conditions réelles) |

Signal de priorisation : R4, R5, R6, R8 (et R2) **reviennent depuis mai** faute de ticket porteur : c'est exactement l'angle mort que ces tickets corrigent. R5 (FreshRSS) et R6 (industrialisation SCA) conditionnent la fiabilité des revues futures → à prioriser. R9 conditionne la partie build de R4 (sans ce relevé, la comparaison automatique du script n'a rien à comparer).

---

## R1 - [SEC][AMELIORATION][process] Clarifier la matrice de priorisation §4.4 (XSS internet / DoS client) (Threat Intel 2026-06)

Type : Story (rattaché à SEC-THREATINTEL-2026-06 / CICD-170) · Priorité : Medium · Horizon : Q3 2026 · Responsable : DevSecOps + Responsable Numérique
Étiquettes : threat-intel, amelioration, sec-2026-06, process

Contexte & objectif :
La matrice §4.4 ne tranche pas deux cas fréquents : XSS applicatif à exposition internet (souvent CVSS modéré mais risque réel) et DoS côté client (CVSS élevé mais impact limité au navigateur). En mai comme en juin, la classification retenue (XSS = P2, DoS client = P3) dévie de la lecture stricte. Objectif : formaliser une règle explicite dans le plan pour lever l'ambiguïté et rendre la priorisation reproductible.

Definition of Done :
* [ ] Règle écrite ajoutée au plan `plan_revu_mensuel.md` §4.4 (traitement XSS internet, DoS client, exposition hors ligne)
* [ ] Rétro-appliquée aux items juin (Angular) pour vérifier la cohérence
* [ ] Plan versionné et validé par le Responsable Numérique

Bénéfice / risque si non traité :
Priorisation non reproductible, écarts d'un mois à l'autre, débat récurrent à chaque XSS/DoS. Sans règle, l'écart matrice/décision se répète.

Récurrence / historique : apparue en juin 2026 (déjà pratiquée implicitement en mai).

---

## R2 - [SEC][AMELIORATION][architecture] Convergence des versions Angular / Three.js / MariaDB (Threat Intel 2026-06)

Type : Epic/Story existant **ARCH-VERSIONS-CONVERGENCE** (ne pas recréer) · Priorité : High · Horizon : Q4 2026 · Responsable : Tech Leads Angular + infra
Étiquettes : threat-intel, amelioration, sec-2026-06, architecture

Contexte & objectif :
Hétérogénéité Angular (20.3 / 21.2 / 22.0), Three.js (0.150 → 0.185) et parc MariaDB à 4 branches LTS : multiplie l'effort de patch et la dette. Juin a montré le bénéfice (Hip2D 21.2.17 et Shoulder3D 22.0.4 hors de portée du batch Angular) et le coût (dette lourde sur Hip3D/KneeMadison). Objectif : aligner Hip3D et KneeMadison, réduire la dette transitive.

Definition of Done :
* [ ] Hip3D et KneeMadison montés sur la ligne Angular cible
* [ ] Réduction mesurable des alertes Dependabot build sur ces 2 modules
* [ ] Trajectoire de convergence documentée (versions cibles par module)

Bénéfice / risque si non traité :
Chaque CVE Angular/Three.js pèse N fois (une par version) ; dette SCA qui s'accumule. Récurrent mai + juin.

Récurrence / historique : mai 2026 + juin 2026. **Mettre à jour le ticket existant**, ne pas en créer un nouveau.

---

## R3 - [SEC][AMELIORATION][veille] Veille ciblée des briques DICOM réelles (nanodicom, nifti-reader-js) (Threat Intel 2026-06)

Type : Task (rattaché à SEC-THREATINTEL-2026-06 / CICD-170) · Priorité : Medium · Horizon : Q3 2026 · Responsable : DevSecOps
Étiquettes : threat-intel, amelioration, sec-2026-06, veille, dicom

Contexte & objectif :
Les 3 advisories DICOM de juin (DCMTK, OHIF, pydicom/pynetdicom) ne concernaient pas OneOrtho, mais la veille DICOM générique n'est pas ciblée. La surface DICOM réelle est `oneortho/nanodicom` (PHP, v1.4.0, fork interne) et `nifti-reader-js` (JS). Objectif : suivre explicitement ces deux composants.

Definition of Done :
* [ ] nanodicom et nifti-reader-js ajoutés aux composants suivis (advisories GitHub / NVD, SBOM)
* [ ] Veille du dépôt amont de nanodicom (fork interne) mise en place
* [ ] Mention ajoutée au périmètre §2.2 du plan

Bénéfice / risque si non traité :
Un advisory visant réellement nanodicom/nifti-reader-js pourrait passer inaperçu (veille orientée sur des implémentations non utilisées).

Récurrence / historique : apparue en juin 2026.

---

## R4 - [SEC][AMELIORATION][outillage] Automatiser l'export MSRC (API CVRF v3.0) (Threat Intel 2026-06)

Type : Task (rattaché à SEC-THREATINTEL-2026-06 / CICD-170) · Priorité : Medium · Horizon : Q3 2026 · Responsable : DevSecOps + infra
Étiquettes : threat-intel, amelioration, sec-2026-06, outillage

Contexte & objectif :
L'export MSRC est fait manuellement (CSV) chaque mois. Objectif : automatiser via l'API CVRF `https://api.msrc.microsoft.com/cvrf/v3.0/` en début de mois post-Patch Tuesday, avec filtre périmètre Windows Server/IIS/.NET + dédup CVE + croisement KEV.

**Avancement (04/09/2026)** : script écrit et validé sur juin 2026 — `myskills/threat-intel-review/scripts/fetch_msrc_cvrf.py`, intégré au skill `threat-intel-review` (§0bis/§5). Le filtre par produit réellement affecté (CVRF) s'est avéré plus fiable que le filtre par balise du CSV manuel : 8 CVE Critiques (dont 7 RCE) touchant le parc Windows Server étaient passées sous le filtre manuel de juin, cf. addendum du 04/09/2026 dans `rapport_threat_intel_june2026.md`. Le script calcule aussi désormais le ratio couvert/résiduel automatiquement à partir d'un relevé du parc (`--fleet`, JSON déposé dans `sources/` chaque mois) : rejoué sur un relevé synthétique reproduisant l'état réel de juin, il retrouve exactement 16/19 couverts et les 3 mêmes résiduels (WEBPRODDEDIENNE, WEBPRODGLOBALD, WEBPRODI2B) que ceux identifiés manuellement dans le rapport. Le relevé du parc lui-même reste une saisie manuelle (`Get-ItemProperty ... CurrentBuild, UBR` sur chaque serveur, aucune collecte centralisée en place) : DoD 2 dépend donc de ce relevé pour être exploitable, pas d'un développement supplémentaire du script.

Definition of Done :
* [x] Script/tâche récupérant le CVRF du mois et produisant le fichier périmètre
* [x] Comparaison automatique build serveurs vs build Patch Tuesday du mois (implémentée et validée par rejeu des chiffres de juin ; nécessite en entrée le relevé du parc du mois, cf. R9)
* [x] Intégré au flux de la revue mensuelle (SKILL.md §0bis/§5)

Bénéfice / risque si non traité :
Effort manuel répété + risque d'erreur (confusion build cible mois précédent/courant, vu en juin) + filtre par balise moins fiable que le filtre par produit (8 CVE Critiques manquées en juin, sans conséquence sur le risque réel mais avec impact sur la traçabilité du rapport). Récurrent mai + juin.

Récurrence / historique : mai 2026 + juin 2026. Script livré le 04/09/2026, à confirmer en conditions réelles sur un 2e mois (juillet ou août, avec un vrai relevé du parc) avant de considérer le ticket clos. Voir R9 (nouveau) pour la mise en place du relevé mensuel du parc lui-même.

---

## R5 - [SEC][AMELIORATION][outillage] Mettre en place FreshRSS pour les sources RSS (Threat Intel 2026-06)

Type : Task (rattaché à SEC-THREATINTEL-2026-06 / CICD-170) · Priorité : High · Horizon : Q3 2026 · Responsable : DevSecOps
Étiquettes : threat-intel, amelioration, sec-2026-06, outillage

Contexte & objectif :
Le flux CERT-FR ne renvoie qu'une fenêtre glissante ; en juin la couverture complète a nécessité de paginer l'archive `/avis/` (17 pages) à la main. Objectif : agréger les sources RSS (self-hosted FreshRSS, cf. `procedure_agregateur_rss.md`) pour limiter les oublis et l'effort manuel.

Definition of Done :
* [ ] Instance FreshRSS opérationnelle avec les flux du plan §3
* [ ] Procédure de consultation mensuelle documentée
* [ ] Couverture full-mois vérifiée sur un cycle

Bénéfice / risque si non traité :
Effort manuel de pagination, risque de lacune de couverture. **Récurrent mai + juin, sans ticket : angle mort typique** que ce suivi corrige.

Récurrence / historique : mai 2026 + juin 2026.

---

## R6 - [SEC][AMELIORATION][outillage] Industrialiser la SCA (Dependabot API + arbitrage Snyk / Dependency-Track) (Threat Intel 2026-06)

Type : Story (rattaché à SEC-THREATINTEL-2026-06 / CICD-170) · Priorité : High · Horizon : Q3 2026 · Responsable : DevSecOps
Étiquettes : threat-intel, amelioration, sec-2026-06, outillage, sca

Contexte & objectif :
La compilation Dependabot (400 alertes en juin) est manuelle et Snyk n'a pas été fourni (source SCA en attente). Objectif : industrialiser la collecte Dependabot (API GitHub) et arbitrer Snyk vs Dependabot vs Dependency-Track pour éviter la duplication non soutenable et fiabiliser le volet SCA (souveraineté SBOM).

Definition of Done :
* [ ] Collecte Dependabot automatisée (API) avec tri runtime/build (flag dev)
* [ ] Décision d'outillage SCA cible arbitrée et documentée
* [ ] Snyk soit intégré au flux, soit remplacé/retiré du plan

Bénéfice / risque si non traité :
Volet SCA fragile (Snyk manquant a conditionné la validation de juin), duplication ingérable manuellement.

Récurrence / historique : mai 2026 (éval Dependency-Track) + juin 2026 (Snyk non fourni, blocage validation).

---

## R7 - [SEC][AMELIORATION][gouvernance] Mettre à jour l'inventaire MariaDB après la montée (Threat Intel 2026-06)

Type : Task (rattaché à SEC-THREATINTEL-2026-06 / CICD-170) · Priorité : Medium · Horizon : Q3 2026 · Responsable : DevSecOps + infra
Étiquettes : threat-intel, amelioration, sec-2026-06, gouvernance, mariadb

Contexte & objectif :
`curent-mariadb-onserver.md` est inchangé depuis mai : la montée (décision mai #7) n'est pas constatée, ce qui fait re-remonter les mêmes 13 CVE. Objectif : mettre à jour l'inventaire dès la montée effectuée, pour que la revue ne re-signale pas des CVE corrigées.

Definition of Done :
* [ ] Inventaire MariaDB reflétant les versions post-montée (11.8.8 / 11.4.12 / 10.11.18 / 10.6.27)
* [ ] Procédure : mise à jour de l'inventaire incluse dans la clôture du ticket de montée MariaDB

Bénéfice / risque si non traité :
Ambiguïté récurrente (parc réel vs inventaire), CVE déjà corrigées re-signalées.

Récurrence / historique : apparue en juin 2026 (conséquence de la montée mai non constatée).

---

## R8 - [SEC][AMELIORATION][gouvernance] Décider du sort de la source H-ISAC dans le plan §3.2 (Threat Intel 2026-06)

Type : Task (rattaché à SEC-THREATINTEL-2026-06 / CICD-170) · Priorité : Low · Horizon : Q3 2026 · Responsable : Responsable Numérique
Étiquettes : threat-intel, amelioration, sec-2026-06, gouvernance, veille

Contexte & objectif :
H-ISAC figure au plan §3.2 mais l'accès membre n'est pas activé ; elle est marquée « non activé » chaque mois. Objectif : décider explicitement d'activer l'accès (si pertinent) ou de retirer la source du plan, pour cesser de la traîner en « non activé ».

Definition of Done :
* [ ] Décision tranchée (activer / retirer) et documentée
* [ ] Plan §3.2 mis à jour en conséquence

Bénéfice / risque si non traité :
Source fantôme dans le plan, statut « non activé » répété sans décision.

Récurrence / historique : mai 2026 + juin 2026.

---

## R9 - [SEC][AMELIORATION][outillage] Mettre en place le relevé mensuel du parc Windows (Threat Intel 2026-06, ajout 04/09/2026)

Type : Task (rattaché à SEC-THREATINTEL-2026-06 / CICD-170) · Priorité : Medium · Horizon : Q3 2026 · Responsable : DevSecOps + infra
Étiquettes : threat-intel, amelioration, outillage, gouvernance, windows

Contexte & objectif :
Le script MSRC (R4) sait comparer automatiquement le build de chaque serveur au build cible du Patch Tuesday du mois, mais n'a rien à comparer : il n'existe aujourd'hui aucun relevé du parc Windows, ni ponctuel ni automatisé (contrairement à `curent-mariadb-onserver.md` pour MariaDB). Le seul moyen actuel est manuel serveur par serveur (`Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' | Select-Object ProductName, CurrentBuild, UBR`). Objectif : déposer chaque mois un relevé structuré dans `sources/parc_windows_<moisannée>.json`, en instantané daté (pas un fichier "current" unique en racine, pour ne pas reproduire le problème de traçabilité de R7).

Definition of Done :
* [x] Relevé du parc (nom, OS, environnement, CurrentBuild, UBR) déposé dans `sources/parc_windows_<moisannée>.json` à chaque revue (fait rétroactivement pour juin 2026, 19 serveurs, le 04/09/2026)
* [x] Format documenté dans le skill (en-tête de `fetch_msrc_cvrf.py`)
* [x] Script `fetch_msrc_cvrf.py --fleet ... --fleet-report ...` exécuté et fragment généré (`sources/comparaison_parc_windows_june2026.md`) : retrouve exactement le 16/19 et les 3 mêmes résiduels (WEBPRODDEDIENNE, WEBPRODGLOBALD, WEBPRODI2B) que le rapport de juin, à partir des vraies données du parc
* [ ] Évaluer à moyen terme une collecte automatisée (Ansible/PowerShell DSC/RMM existant) pour sortir de la saisie manuelle par serveur
* [ ] Reproduire le dépôt du relevé en conditions réelles (au moment de la revue, pas rétroactivement) sur un 2e mois avant de considérer le ticket clos

Bénéfice / risque si non traité :
Sans ce relevé, la partie "comparaison automatique" de R4 reste inexploitable malgré le script prêt ; le calcul du ratio couvert/résiduel et l'identification des serveurs en retard restent manuels, avec le même risque d'erreur que celui documenté au §5 (piège du build cible).

Récurrence / historique : apparue en septembre 2026, en conséquence directe de la livraison du script R4. Relevé de juin déposé et validé le 04/09/2026 (note : rétroactif, à faire au moment de la revue pour les mois suivants).

Point technique corrigé en marge : le relevé réel utilise des noms d'édition absents de la nomenclature MSRC (ex. "Windows Server 2016 Standard" vs "Windows Server 2016" côté CVRF) — normalisation ajoutée au script (`base_os_name`).
