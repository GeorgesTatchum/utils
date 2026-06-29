# Bordereau d'archivage — Revue Threat Intelligence mai 2026

> **Document maître.** Une copie existe dans `utils/hds/may2026/index_pieces_probantes_2026-05.md` (à côté des tickets et procédures). En cas de modification, mettre à jour cette version puis recopier — cette version fait foi.

Index des pièces probantes à archiver avec le rapport complet. Sert de preuve d'audit (ISO 27001 A.5.7, traçabilité MDR / IEC 62304).

## Métadonnées d'archivage

| Champ | Valeur |
|-------|--------|
| Période couverte | 01/05/2026 au 31/05/2026 |
| Ticket de revue | SEC-THREATINTEL-2026-05 (CICD-169) |
| Date de revue | 04/06/2026 |
| Auteur | Georges TATCHUM |
| Validé par | HK — Responsable Numérique |
| Emplacements d'archivage | Confluence (CyberSécurité > PSSI > Threat Intelligence) + PDF figé SharePoint OneOrthoGED |
| Rétention | 7 ans |

> Légende statut : **[Présent]** = fichier déjà dans le dossier · **[À joindre]** = à capturer/exporter avant clôture de l'archivage.

## 1. Rapport mensuel (livrable principal)

| Pièce | Emplacement | Statut |
|-------|-------------|--------|
| §2 Sources consultées | `utils/hds/cyber/may2026/sources_consultees_2026-05.md` | [Présent] |
| §3 Items identifiés | `utils/hds/cyber/may2026/items_identifies_2026-05.md` | [Présent] |
| §1, §4, §5, §6, §7, §8 | `utils/hds/cyber/may2026/sections_1_4_5_6_7_2026-05.md` | [Présent] |
| Rapport consolidé PDF signé (statut PUBLISHED) | SharePoint — `Rapport mensuel - Revue Threat Intelligence - 2026-05.pdf` | [À joindre] |

## 2. Pièces probantes — sources consultées (preuve de la veille)

| Pièce | Ce qu'elle prouve | Emplacement / origine | Statut |
|-------|-------------------|-----------------------|--------|
| Snapshot JSON CISA KEV (21/05 et 29/05) | Liste KEV à la date de consultation | `known_exploited_vulnerabilities.json` (curl) — à figer en `annexes/2026-05/kev_2026-05-29.json` | [À joindre] |
| Export MSRC CSV | 68 CVE Windows Server du Patch Tuesday 12/05 | `Security Updates 2026-06-02-121531pm.csv` (racine wwwroot) → copier en annexe | [Présent — à déplacer en annexe] |
| Doc CVE MariaDB | 14 CVE 2026 + versions corrigées | `community-server.md` (racine wwwroot) → copier en annexe | [Présent — à déplacer en annexe] |
| Capture manuelle CISA ICS / ICSMA | 55 advisories lus, 0 applicable | Capture écran page CISA du 02/06 | [À joindre] |
| Capture manuelle FDA Safety Communications | 0 communication sur la période | Capture écran page FDA du 02/06 | [À joindre] |
| Captures / exports advisories éditeurs (CERT-FR, GitHub Angular/PHP, Symfony, Three.js) | Items remontés par chaque source | Captures ou exports RSS à la date de consultation | [À joindre] |
| Sorties Snyk + GitHub Dependabot du mois | Alertes dépendances tierces | Consoles internes (export) | [À joindre] |

## 3. Pièces probantes — croisement stack (preuve d'applicabilité)

| Pièce | Ce qu'elle prouve | Emplacement | Statut |
|-------|-------------------|-------------|--------|
| `composer.lock` (extraits) | Présence/version réelle des composants Symfony, Twig, etc. | `saas_local/app/composer.lock` | [Présent] |
| `package.json` des 4 modules | Versions Angular / Three.js par planificateur | `saas_local/modulesjs/*/package.json` | [Présent] |
| Inventaire parc MariaDB | 16 instances, versions par branche | `curent-mariadb-onserver.md` (racine) → copier en annexe | [Présent — à déplacer en annexe] |

## 4. Pièces probantes — investigations (justification des décisions)

| Investigation | Pièce probante | Ce qu'elle justifie | Statut |
|---------------|----------------|---------------------|--------|
| Spike 1 — Defender | Sortie `Get-MpComputerStatus` (AMRunningMode, AMEngineVersion, AMProductVersion) par serveur, parc complet | Non-applicabilité CVE-2026-41091 (moteur ≥ 1.1.26040.8 partout) + applicabilité CVE-2026-45498 sur 2 serveurs (plateforme 4.18.1911.3 < 4.18.26040.7) | [À joindre — capture du relevé] |
| Procédure Spike 1 | `utils/hds/may2026/procedure_spike1_defender.md` | Méthode de vérification Defender | [Présent] |
| Ex-Item 3 — X509Authenticator | Retour écrit Tech Lead Symfony (brique non utilisée + version corrigée) | Non-applicabilité CVE-2026-45063 | [À joindre — mail/Teams] |
| Ex-Item Twig sandbox | Retour écrit Tech Lead Symfony (sandbox non utilisé + version 3.27.1) | Non-applicabilité CVE-2026-48805/48806/46636 | [À joindre — mail/Teams] |
| Ticket 3 — Windows Server RCE | Relevé des builds (`CurrentBuild.UBR`) par serveur, avant/après patch | État de correctif du parc + résultat de l'application | [À joindre quand réalisé] |
| Procédure Ticket 3 | `utils/hds/may2026/procedure_verification_ticket3_windows.md` | Méthode de vérification build | [Présent] |
| Spike 2 — fonctions PHP | Résultat de la recherche d'usage (grep) des 4 fonctions | Applicabilité ou non des 4 GHSA php-src | [À joindre quand réalisé] |

## 5. Décisions et remédiation

| Pièce | Emplacement | Statut |
|-------|-------------|--------|
| Tickets Jira (8 remédiation + 2 Spikes + Ticket 9 Defender) | `utils/hds/may2026/tickets_jira_2026-05.md` | [Présent] |
| Procédure d'application interne (Ticket 3, MCO OS OneOrtho) | `utils/hds/may2026/procedure_application_patch_ticket3_windows.md` | [Présent] |
| Logs d'application internes `apply-2026-05.log` + relevé build après patch (par serveur) | Serveurs / annexe | [À joindre après application] |
| Modèle mail AVA6 (gabarit générique, OBSOLÈTE pour le patching OS) | `utils/hds/may2026/modele_mail_ava6_ticket3.md` | [Présent — non utilisé pour Ticket 3] |
| Liens Jira des tickets créés | À reporter dans le rapport une fois les tickets ouverts | [À joindre] |

## 6. Checklist avant clôture de l'archivage

- [ ] Figer le snapshot CISA KEV JSON (date de consultation) en annexe
- [ ] Copier en annexe : MSRC CSV, community-server.md, curent-mariadb-onserver.md
- [ ] Joindre les captures CISA ICS et FDA (consultation manuelle du 02/06)
- [ ] Joindre la sortie `Get-MpComputerStatus` du parc (preuve Spike 1)
- [ ] Joindre les retours écrits du Tech Lead Symfony (X509, Twig)
- [ ] Compiler et joindre les exports Snyk + Dependabot du mois
- [ ] Reporter les numéros de tickets Jira créés dans le rapport
- [ ] Générer le PDF consolidé, le faire signer (Responsable Numérique), déposer sur SharePoint
- [ ] Publier le rapport sur Confluence, notifier #comité_technique

## 7. Structure d'archivage recommandée

```
Threat-Intelligence/2026-05/
├── rapport_2026-05.pdf                    (PUBLISHED, signé)
├── sources_consultees_2026-05.md
├── items_identifies_2026-05.md
├── sections_1_4_5_6_7_2026-05.md
├── tickets_jira_2026-05.md
├── index_pieces_probantes_2026-05.md      (ce document)
└── annexes/
    ├── kev_2026-05-29.json
    ├── msrc_2026-06-02.csv
    ├── mariadb_community-server_2026-06-01.md
    ├── mariadb_parc_inventaire.md
    ├── cisa_ics_2026-06-02.png
    ├── fda_safety_2026-06-02.png
    ├── defender_get-mpcomputerstatus_parc.txt
    ├── techlead_symfony_x509_twig.pdf      (retours écrits)
    ├── windows_builds_avant_apres.txt      (Ticket 3)
    ├── apply-2026-05_logs/                  (logs d'application interne par serveur)
    └── snyk_dependabot_2026-05.csv
```

> Note conformité : aucune donnée patient ni secret dans les pièces. Les noms d'hôtes ne sont conservés que là où nécessaire (relevés build/Defender). Le PDF PUBLISHED est la version figée faisant foi ; toute correction ultérieure passe par un erratum daté.
