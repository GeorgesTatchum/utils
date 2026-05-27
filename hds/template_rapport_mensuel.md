# Avis et patch — template_rapport_mensuel_threat_intellingence.md

Document audité : `/template_rapport_mensuel_threat_intellingence.md`.
Périmètre : conformité MDR 2017/745, IEC 62304 §9, FDA Cybersecurity Guidance 2023, ISO 27001 A.5.7, ISO 14971.

> Note de cohérence : le nom de fichier comporte une coquille `intellingence` → renommer en `template_rapport_mensuel_threat_intelligence.md` (mineur mais visible en audit).

## A. Avis sur le template existant

### A.1 Points forts à conserver

- **§3.3 "Items non applicables (traçabilité)"** : indispensable pour audit MDR. À ne pas supprimer.
- **§5 "Suivi des items mois précédents"** : couvre bien la dette de remédiation.
- **§7 "Recommandations mois suivant"** : utile pour boucler le PDCA.
- **§3.1 Synthèse chiffrée** : KPI lisibles d'un coup d'œil.
- **Format tabulaire** unique par item (§3.2) : exploitable pour audit ligne par ligne.

### A.2 Incohérences à corriger immédiatement

| # | Endroit | Problème | Correction |
|---|---------|----------|------------|
| 1 | §2 Sources, ligne "Angular Security" | Source insuffisante : il faut nommer les flux exacts. Stack réel : Angular **20.3** sur 3 modules et **21.2** sur Shoulder3D. | Remplacer par GitHub Advisories `angular/angular` + Blog Angular. Ajouter aussi : Symfony Security, Composer audit, npm/yarn audit, Three.js (0.150 → 0.182 selon module), TinyMCE, axios, MSRC, MariaDB, MongoDB, Nginx, Trivy CI, SonarQube, Dependabot, Firebase Security Bulletins, nifti-reader-js |
| 2 | §3.2 "Produit concerné : PlannerShoulder3D / autre" | Liste trop restreinte — il existe 4 planificateurs Angular + 3 modules Symfony + bundles + portail. | Étendre la liste fermée (cf. §B.3 ci-dessous). |
| 3 | §8 Export | Stocke en SharePoint, alors que le plan §4.6 prévoit Confluence "CyberSécurité > PSSI > Threat Intelligence" | Aligner : Confluence comme source de vérité, SharePoint comme archive PDF figée signée. Citer les deux. |
| 4 | Référentiel pied de page | "ISO 27001 A.5.7" seul | Ajouter MDR Annexe I §17.2, IEC 62304 §9 (SOUP), MDCG 2019-16 rev.1, FDA Cybersecurity Guidance 2023 |
| 5 | Métadonnées | Pas de "Version document" ni "Statut" (DRAFT/VALIDATED/PUBLISHED) | Indispensable pour audit-trail (cf. §B.1 ci-dessous) |
| 6 | §3.2 champ "Action décidée" | Manque la décision "Acceptation du risque" pourtant prévue MDR / ISO 14971 | Ajouter à la liste des valeurs |

### A.3 Manques majeurs (conformité réglementaire)

| # | Manque | Référentiel impacté | Sévérité |
|---|--------|---------------------|----------|
| 1 | Aucun lien vers l'analyse de risque produit (ISO 14971) | MDR Annexe I §3 + ISO 14971 §6.4 | Bloquant audit |
| 2 | Aucune décision de notification (clients / ANSM / FDA / organisme notifié) | MDR §87 (vigilance), 21 CFR 803 | Bloquant audit |
| 3 | Aucune trace du SBOM consulté (version, hash) | FDA Cybersecurity Guidance 2023 §V.B, MDCG 2019-16 §3.4 | Bloquant FDA |
| 4 | Aucune section 0-day / hors-cycle | Pratique standard, exigée si KEV exploité activement | Élevé |
| 5 | Pas de KPI internes au rapport (réalisé vs cible mois) | KPI §6 du plan reste hors rapport | Moyen |
| 6 | Pas d'annexes preuves probantes (exports horodatés) | MDR Annexe IX §8 (documentation 7 ans), 21 CFR Part 11 | Élevé |
| 7 | Pas de mention PRRC (Person Responsible for Regulatory Compliance) | MDR art. 15 | Élevé |
| 8 | Pas de mécanisme erratum / changelog après VALIDATED | 21 CFR Part 11 §11.10(e), MDR Annexe IX | Élevé |
| 9 | Pas de check "revue intermédiaire J+15 réalisée" | Rythme bi-mensuel demandé | Moyen |
| 10 | §3.2 ne distingue pas "Exploit public" et "Date d'exploitation détectée en production" | Critère IEC 62304 §6.1 maintenance | Moyen |

## B. Patch à appliquer (blocs prêts à coller)

### B.1 — Métadonnées (remplace le tableau existant)

```markdown
| Champ | Valeur |
|-------|--------|
| Période couverte | {{JJ/MM/AAAA}} au {{JJ/MM/AAAA}} |
| Date de la revue | {{JJ/MM/AAAA}} |
| Date d'émission | {{JJ/MM/AAAA}} |
| Analyste (DevSecOps) | {{Nom}} |
| Validé par (Responsable Numérique) | {{Nom}} |
| Date de validation | {{JJ/MM/AAAA}} |
| PRRC informé (si P1 applicable) | {{Nom — date}} ou N/A |
| Ticket Jira | CICD-{{XXX}} — SEC-THREATINTEL-{{YYYY-MM}} |
| Version document | v{{n}} |
| Statut | DRAFT / VALIDATED / PUBLISHED |
| SBOM consulté (version / hash) | {{commit sha ou tag}} |
| Périmètre US applicable | Oui (510(k) plannerHip2D) / Non — pour information audit cyber, pas pour déclencher procédure FDA |
| Finalité | Traçabilité interne pour audit cyber (ISO 27001, audit client, audit assureur). Pas de procédure réglementaire portée par ce rapport. |
```

> Champs retirés par rapport aux versions précédentes du patch : `PRRC informé`, `Signature PRRC requise`, `Notification ANSM/FDA/Organisme notifié`. Ces dimensions sont hors-scope du rapport (cf. plan v2.3 §4.8 transmission informative au pôle Affaires Réglementaires).

### B.2 — Sources consultées (remplace le tableau §2)

Liste corrigée alignée sur `sources_stack_technique.md`. Trois cases : ✔ consultée / ✗ non consultée + motif / N/A.

```markdown
| Source | Statut | Date dernière publication lue | Nb items remontés | Remarques |
|--------|--------|------------------------------|-------------------|-----------|
| CISA KEV Catalog | ☐ | | | |
| NVD / CVE | ☐ | | | |
| CERT-FR (ANSSI) | ☐ | | | |
| GitHub Security Advisories (org `oneorthomedical`) | ☐ | | | |
| CISA ICS Medical Advisories | ☐ | | | |
| FDA Medical Device Safety | ☐ | | | |
| HHS HC3 | ☐ | | | si US applicable |
| ENISA Health | ☐ | | | |
| H-ISAC | ☐ | | | si accès |
| Symfony Security Advisories | ☐ | | | |
| Composer audit (CI build #) | ☐ | | | |
| GitHub Dependabot | ☐ | | | tous repos org |
| npm audit / yarn audit / OSV | ☐ | | | |
| Angular Security Advisories (`angular/angular`) | ☐ | | | versions 20.3 + 21.2 |
| Three.js releases | ☐ | | | versions 0.150 / 0.179 / 0.181 / 0.182 |
| RxJS / zone.js / @angular/material / @angular/cdk | ☐ | | | |
| nifti-reader-js (releases + CVE) | ☐ | | | |
| Firebase / firebase-tools / GCP Security Bulletins | ☐ | | | |
| Bootstrap 4 (app) + Bootstrap 5 (modules) | ☐ | | | |
| Tailwind CSS (Shoulder3D) | ☐ | | | |
| TinyMCE / axios / chart.js / datatables (app) | ☐ | | | |
| Cypress / Vitest / Karma / Jasmine | ☐ | | | |
| MSRC Patch Tuesday | ☐ | | | |
| MariaDB / MongoDB / Nginx | ☐ | | | |
| Alpine secdb / Docker Scout | ☐ | | | |
| Trivy CI (build #) | ☐ | | | |
| SonarQube quality.3d4you.org | ☐ | | | nouveaux hotspots |
| Jenkins Security Advisories | ☐ | | | |
```

### B.3 — Détail item §3.2 (champs additionnels à ajouter au tableau existant)

À insérer dans le tableau "Item N : ..." après "Action décidée" :

```markdown
| Catégorie de périmètre | A (DM MDR) / A+B (Hip2D MDR+FDA) / C (non-DM, OneSoftware ou Shoulder3D) / D (infra transverse) |
| Effet de bord sur DM | Oui / Non / Non applicable (déjà catégorie A) |
| DM impactés par effet de bord (si applicable) | plannerHip2D / plannerHip3D / plannerKneeMadison / N/A |
| Acceptation du risque (oui/non) | {{Oui / Non}} |
| Justificatif d'acceptation (si Oui) | {{décision Resp. Num.}} |
| Date détection / publication | {{JJ/MM/AAAA}} |
| Date détection en exposition OneSoftware | {{JJ/MM/AAAA ou N/A}} |
| Transmission Affaires Réglementaires (§4.8) | Oui (date + destinataire Céline Antoine) / Non / N/A (item ne touchant pas un DM) |
| Communication clients / distributeurs | Oui / Non — décision motivée : {{...}} |
| Distributeurs ciblés par la communication | Tous / liste filtrée parmi les 9 OEM |
```

> Note : la décision de **mise à jour ISO 14971** et de **notification autorité** (ANSM, FDA MedWatch, organisme notifié) est **hors-scope** du présent rapport. Elle relève du pôle Affaires Réglementaires, informé via §4.8 du plan. Ne pas ajouter ces champs dans le template.

Étendre aussi la valeur du champ "Produit concerné" (liste fermée alignée sur arborescence repo et statut réglementaire) :
> **Sous-périmètre A (DM MDR)** : plannerHip2D (MDR + FDA 510k) / plannerHip3D / plannerKneeMadison
> **Sous-périmètre C (non-DM)** : Portail Symfony (`saas_local/app/`, incl. Module2DHip / Module3DHip / Module3DKnee internes) / plannerShoulder3D (statut DM à venir)
> **Sous-périmètre D (infrastructure)** : Windows Server / IIS / MariaDB / MongoDB / Docker / Jenkins / Ansible / Bundle {{nom}} / Chaîne CI / N/A

Ajouter aussi un champ "Distributeur impacté" (liste fermée 9 OEM) :
> Tous / ds (Dedienne) / oo (OneOrtho) / serf (Stryker) / lepine / evolutis / fh / in2bones / globald / kerimedical / N/A — la valeur conditionne la cible de notification commerciale.

### B.4 — Nouvelle section §3.4 "Items traités hors-cycle (0-day)"

À insérer entre §3.3 et §4.

```markdown
3.4 Items traités hors-cycle (0-day)

| Date détection | CVE / Réf | Source | Délai prise en charge | Décision | Ticket | Notification déclenchée |
|----------------|-----------|--------|----------------------|----------|--------|------------------------|
```

### B.5 — Nouvelle section §6bis "KPI du mois"

À insérer entre §6 et §7.

```markdown
6bis. KPI mois

| KPI | Valeur du mois | Cible | Statut |
|-----|----------------|-------|--------|
| Revue mensuelle réalisée | Oui / Non | Oui | |
| Revue intermédiaire J+15 réalisée | Oui / Non | Oui | |
| Délai moyen remédiation P1 | {{h}} | < 72 h | |
| Délai moyen remédiation P2 | {{j}} | < 14 j | |
| Délai moyen prise en charge 0-day | {{h}} | < 24 h | |
| Taux vulnérabilités > 30 j non remédiées | {{%}} | < 5 % | |
| % items applicables avec analyse de risque mise à jour | {{%}} | 100 % | |
| Nb sources non consultées | {{N}} | 0 | |
```

### B.6 — Nouvelle section §9 "Annexes — preuves probantes"

À insérer après §8.

```markdown
9. Annexes (preuves probantes — conservation 7 ans)

- [ ] Export CSV CISA KEV au {{date}} — `annexes/{{YYYY-MM}}/kev.csv`
- [ ] Recherche NVD filtrée stack — `annexes/{{YYYY-MM}}/nvd.json`
- [ ] composer audit build #{{n}} — `annexes/{{YYYY-MM}}/composer-audit.json`
- [ ] yarn audit build #{{n}} — `annexes/{{YYYY-MM}}/yarn-audit.json`
- [ ] Trivy image dernière release — `annexes/{{YYYY-MM}}/trivy.json`
- [ ] SBOM CycloneDX — `annexes/{{YYYY-MM}}/sbom.cdx.json` (ou N/A si non encore en place)
- [ ] PV réunion signé — `annexes/{{YYYY-MM}}/pv.pdf`
```

### B.7 — Nouvelle section §10 "Validation et changelog"

À insérer en fin de document avant le pied de page.

```markdown
10. Validation et changelog

| Version | Date | Statut | Auteur | Description |
|---------|------|--------|--------|-------------|
| v1 | {{date}} | DRAFT | {{nom}} | Création |
| v1 | {{date}} | VALIDATED | {{nom}} | Validation Responsable Numérique |
| v1 | {{date}} | PUBLISHED | {{nom}} | Publication Confluence + SharePoint |
| v1.1 | {{date}} | ERRATUM | {{nom}} | {{nature de la correction post-publication}} |
```

### B.8 — Pied de page (remplace ligne 299)

```markdown
Document généré dans le cadre du processus de revue Threat Intelligence.
Référentiels : ISO 27001 A.5.7 — MDR 2017/745 Annexe I §17.2 — IEC 62304 §9 (SOUP) — MDCG 2019-16 rev.1 — FDA Cybersecurity in Medical Devices Guidance (2023) — ISO 14971 (gestion des risques).
Conservation : 7 ans minimum (MDR Annexe IX §8).
```

### B.9 — §8 Export (corrige incohérence Confluence vs SharePoint)

```markdown
8. Publication et archivage

- Source de vérité éditable (statut DRAFT/VALIDATED) : Confluence espace "CyberSécurité > PSSI > Threat Intelligence" — page `{{YYYY-MM}} Revue mensuelle`
- Archive PDF figée signée (statut PUBLISHED) : SharePoint https://oomedical.sharepoint.com/:f:/s/OneOrthoGED/IgAVMO9CT5jCRaawIsrbDq3BAYWcGdd0Z4mcHm0YOoQwb0o?e=yaVPFH — nommage : `Rapport mensuel - Revue Threat Intelligence - {{YYYY-MM}} - v{{n}}.pdf`
- Notification : Slack #comité_technique avec lien Confluence
```

## C. Processus de tenue (rythme bi-mensuel)

Le plan en l'état prévoit une **réunion mensuelle (1er jeudi)**. Tu indiques tenir le rapport à jour **deux fois par mois**.

**Hypothèse retenue par défaut** : revue intermédiaire J+15, non formelle, en mise à jour différée du rapport. À arbitrer (voir §D).

### Cycle complet

| Jour | Acteur | Action | Durée |
|------|--------|--------|-------|
| **J-7 (vendredi sem -1)** | Jira Automation | Création auto ticket parent SEC-THREATINTEL-{{YYYY-MM}} | auto |
| **J-7 → J-1** | DevSecOps | Collecte §2 sources et pré-remplissage §3 du rapport (statut DRAFT) | 4-6 h |
| **J (1er jeudi)** | DevSecOps + Resp. Num. + Tech Leads | Réunion formelle : revue items, arbitrage priorités, création tickets | 1h30-2h |
| **J → J+2** | DevSecOps | Finalisation §3.2 (analyse risque + notification), validation, publication Confluence + PDF SharePoint, notif Slack | 2-3 h |
| **J+15 (3e jeudi)** | DevSecOps | **Revue intermédiaire** : §3.4 (hors-cycle), MAJ KPI §6bis, MAJ statuts §5. Pas de réunion. Mail au Resp. Num. avec lien Confluence | 30-45 min |
| **Continu** | Jira Automation + Dependabot + Trivy CI | Push automatique nouvelles vulnérabilités dans backlog "SEC-INBOX" pour triage J-7 suivant | auto |
| **0-day actif (hors-cycle)** | DevSecOps | Ouverture immédiate §3.4, alerte Resp. Num. ≤ 24h, P1 si applicable | dès détection |

### Règles de modification (alignées 21 CFR Part 11 §11.10(e))

1. **DRAFT** : modifications libres jusqu'à validation J+2.
2. **VALIDATED** : seul l'ajout en §3.4 (hors-cycle) et §5 (suivi mois précédents) autorisé. Toute autre modification → **version n+1** avec ligne changelog §10.
3. **PUBLISHED** : rapport gelé. Correction → **erratum** daté, signé Resp. Num., conservé en §10 et en annexe.

### Stockage et nommage

- Édition vivante : Confluence `CyberSécurité/PSSI/Threat-Intelligence/{{YYYY-MM}}-revue-mensuelle`
- Archive figée signée : SharePoint, fichier PDF `Rapport mensuel - Revue Threat Intelligence - {{YYYY-MM}} - v{{n}}.pdf`
- Annexes : sous-dossier `annexes/{{YYYY-MM}}/` (Confluence pièces jointes + miroir SharePoint)
- Rétention : 7 ans minimum (MDR Annexe IX §8)

### RACI rapide

| Action | RACI |
|--------|------|
| Collecte sources | R = DevSecOps |
| Première analyse applicabilité | R = DevSecOps, C = Tech Lead |
| Arbitrage priorité | A = Resp. Numérique, R = DevSecOps |
| MAJ ISO 14971 | R = Tech Lead, A = Resp. Num., C = PRRC |
| Décision notification (ANSM/FDA) | A = PRRC, R = Resp. Num., I = Direction |
| Publication Confluence + PDF SharePoint | R = DevSecOps |
| Validation finale | A = Resp. Numérique |

## D. Arbitrages à confirmer

1. **"Deux fois par mois"** = revue intermédiaire J+15 décrite ici, ou autre cadence ? Si autre, préciser périodicité et livrable.
2. **Format signature PDF archivé** : signature manuscrite scannée / eIDAS avancée / approval Confluence ? FDA 21 CFR Part 11 accepte signature électronique ; en France, eIDAS avancée recommandée.
3. **PRRC nommé pour OneOrtho Medical** — non trouvé dans le repo. Sans PRRC identifié, les colonnes "Notification" du §3.2 restent non assignables formellement.
4. **Périmètre US confirmé** : si OneSoftware non commercialisé US, ligne "Notification FDA MedWatch" et case "Périmètre US applicable" peuvent être N/A par défaut.
5. **SBOM CycloneDX** non encore généré aujourd'hui (cf. `sources_stack_technique.md` §3.3.7). Tant qu'il n'est pas en place, métadonnée "SBOM consulté" = N/A et une action récurrente "Mettre en place SBOM CycloneDX" doit figurer en §7 jusqu'à clôture.
6. **Renommer le fichier** : `template_rapport_mensuel_threat_intellingence.md` → `template_rapport_mensuel_threat_intelligence.md`.
7. **Granularité par module Angular** : faut-il une analyse §3.2 distincte par module (Hip2D / Hip3D / Knee / Shoulder) quand une CVE Angular touche plusieurs versions différentes, ou un item unique avec colonne "modules impactés" multi-valuée ? Recommandation : un item par CVE avec liste des modules impactés en sous-tableau, pour éviter la duplication.
8. **Distributeur OEM par item** : confirmer si la veille produit un rapport unique OneOrtho ou un rapport déclinable par distributeur (ds, oo, serf, lepine, evolutis, fh).
