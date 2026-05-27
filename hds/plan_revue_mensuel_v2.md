# Plan de revue mensuelle Threat Intelligence — OneSoftware

Version v2 — date 2026-05-18 — statut DRAFT
Document précédent : `/plan_revu_mensuel.md`

## Informations générales

| Champ | Valeur |
|-------|--------|
| Propriétaire | Service Numérique OneOrtho — Responsable Numérique |
| Responsable opérationnel | DevSecOps (titulaire ou suppléant) |
| Équipe concernée | Service Numérique OneOrtho, Tech Leads |
| Cadence | Veille continue (hebdo CI/CD) + consolidation mensuelle (1er jeudi) + mise à jour traçabilité (J+15) |
| Durée estimée consolidation | 1 h 30 à 2 h |
| Finalité | Traçabilité interne des actions cyber pour audits (ISO 27001, audit client, audit assureur cyber). **Ne se substitue pas** aux processus réglementaires MDR/FDA portés indépendamment par le pôle Affaires Réglementaires. |
| Référentiels primaires | ISO 27001 A.5.7 (threat intelligence), ISO 27002, ISO 27005, PSSI OneOrtho |
| Référentiels subsidiaires (contexte produit) | MDR 2017/745 (3 DM certifiés), FDA Cybersecurity Guidance 2023 (Hip2D 510k), IEC 62304 §9 (SOUP) — cités comme contexte produit, **non comme moteur du processus** |
| Rétention documents | 7 ans (alignement sur exigences audit cyber et délai conservatoire MDR pour les DM hébergés) |
| Version courante | v2.3 |

## 1. Objectif

Identifier, à cadence définie, les menaces, vulnérabilités et techniques d'attaque pouvant impacter les produits et l'infrastructure OneOrtho Medical, afin de :

- déclencher les actions de remédiation cyber appropriées,
- **assurer la traçabilité interne** des décisions prises (analyses, arbitrages, remédiations, communications) en vue d'audits cyber externes ou internes (ISO 27001, audit client, audit assureur cyber, audit interne PSSI),
- alerter à titre informatif le pôle Affaires Réglementaires en cas d'item ayant un effet potentiel sur un DM certifié MDR, charge à ce pôle d'évaluer indépendamment si une procédure réglementaire (vigilance MDR art. 87, FDA MedWatch, mise à jour ISO 14971) doit être déclenchée.

Le rapport mensuel produit (cf. `template_rapport_mensuel_threat_intelligence.md`) est un **artefact de traçabilité interne**, pas un outil de découverte ni un déclencheur de procédure réglementaire. La découverte des vulnérabilités est assurée en continu par la chaîne CI/CD et la veille hebdomadaire (cf. §4.0). Les procédures réglementaires MDR/FDA sont menées indépendamment par le pôle Affaires Réglementaires.

## 2. Périmètre

### 2.1 Produits couverts

Quatre sous-périmètres distincts pour différencier les obligations réglementaires applicables. Le statut "dispositif médical" est attribué uniquement aux produits effectivement certifiés MDR ; les autres composants logiciels sont surveillés au titre d'environnement d'exécution des DM (IEC 62304 §5.7 / MDCG 2019-16 §3.1) ou par hygiène interne.

**Sous-périmètre A — Dispositifs médicaux certifiés MDR 2017/745 (UE)**

Périmètre catégorisé "DM MDR" pour la **traçabilité audit** : un auditeur cyber doit pouvoir identifier les produits sous régulation MDR et constater que les actions cyber ont été tracées en conséquence. **Aucune procédure réglementaire (vigilance MDR art. 87, mise à jour ISO 14971, signature PRRC) n'est déclenchée par le présent plan** — ces procédures sont gérées indépendamment par le pôle Affaires Réglementaires, qui est informé par transmission §4.8.

| Produit | Repo / Chemin | Distribution | Classe MDR |
|---------|---------------|--------------|------------|
| plannerHip2D | `saas_local/modulesjs/plannerHip2D/` | Tous distributeurs | à préciser |
| plannerHip3D | `saas_local/modulesjs/plannerHip3D/` | Tous distributeurs | à préciser |
| plannerKneeMadison | `saas_local/modulesjs/plannerKneeMadison/` | Tous distributeurs | à préciser |

**Sous-périmètre B — Dispositif sous FDA 510(k) (US)**

Périmètre catégorisé "FDA 510k" pour la **traçabilité audit**. Le pôle Affaires Réglementaires reste responsable des obligations FDA (MedWatch, monitoring post-market, 21 CFR Part 11). Le présent plan se contente de produire la trace cyber utile à ces processus, qui restent menés indépendamment.

| Produit | Repo / Chemin | Distribution | Statut |
|---------|---------------|--------------|--------|
| plannerHip2D | `saas_local/modulesjs/plannerHip2D/` | Tous distributeurs | Dossier 510(k) soumis (intersection avec sous-périmètre A) |

**Sous-périmètre C — Composants logiciels non-DM mais hébergeurs ou intégrés**

OneSoftware (app Symfony) et plannerShoulder3D ne sont **pas certifiés MDR** et ne sont donc pas traités comme dispositifs médicaux. Ils restent dans le périmètre de veille pour deux raisons :

- OneSoftware héberge les trois DM du sous-périmètre A → toute vulnérabilité sur ce composant qui compromet la sécurité ou la performance d'un DM hébergé est requalifiée comme item MDR par effet d'environnement (cf. §4.3 et §4.8).
- plannerShoulder3D partage des dépendances communes (Angular, Three.js) avec les DM → utilisé comme indicateur précoce de vulnérabilité avant qu'elle ne touche les DM.

| Composant | Repo / Chemin | Statut DM | Finalité de surveillance |
|-----------|---------------|-----------|--------------------------|
| OneSoftware (portail Symfony, incl. Module2DHip + Module3DHip + Module3DKnee internes au Symfony) | `saas_local/app/` | Non-DM | Environnement d'exécution des 3 DM hébergés (IEC 62304 §5.7) |
| plannerShoulder3D | `saas_local/modulesjs/plannerShoulder3D/` | Non-DM aujourd'hui — dossier MDR à ouvrir ultérieurement (date à arbitrer côté Affaires Réglementaires) | Hygiène interne, indicateur précoce. Migration future vers sous-périmètre A : préparer la création du dossier ISO 14971 et l'inscription dans la procédure §4.8 dès lancement du dossier MDR |

Sur ce sous-périmètre :
- pas de dossier ISO 14971 propre,
- pas de notification ANSM/FDA en propre,
- signature DRAFT → VALIDATED par Responsable Numérique uniquement (pas PRRC),
- mais toute vulnérabilité applicable est tracée et peut basculer en sous-périmètre A si effet de bord démontré sur un DM (§4.8).

**Sous-périmètre D — Infrastructure d'exécution** (transverse, sous IEC 62304 §5.7 pour la part qui héberge les DM du sous-périmètre A)

L'OS hôte et le middleware sont des SOUP au sens IEC 62304 §9.

| Composant | Type | État actuel | Cible / évolution |
|-----------|------|-------------|-------------------|
| Windows Server | OS hôte production | Versions 2016, 2022, 2024, 2025 cohabitent (parc hétérogène) | Migration future vers Linux (distribution et version à arbitrer) |
| IIS | Serveur web en production | Actif (héberge le portail Symfony + modules) | À statuer post-migration Linux (probablement remplacement par Nginx/Apache) |
| MariaDB | SGBD relationnel principal | Version à préciser auprès équipe infra | inchangé |
| MongoDB | SGBD documentaire (en complément de MariaDB) | Version à préciser auprès équipe infra | inchangé |
| Conteneurs Docker (dev/CI) | Runtime build et tests | Alpine 3.21 / 3.23, PHP-FPM, Nginx, Node 23 | inchangé |
| Jenkins | Chaîne CI | Agent Windows | À statuer post-migration Linux |
| Ansible | Orchestration déploiement | Actif | inchangé |

Points d'attention :
- **Windows Server 2016** : fin de support étendu **janvier 2027** — anticiper sortie du parc avant cette date sous peine de classification "EOL en production" interdite par IEC 62304 §6.1.
- **Windows Server 2022/2024/2025** : versions à harmoniser (un parc à quatre versions concurrentes augmente la surface d'attaque et complique le suivi des CVE MSRC).
- **Migration Windows → Linux** : à traiter comme change request au sens IEC 62304 §6 et MDR art. 10 §9 — déclenche une révision du plan de veille (sources MSRC à remplacer par tracker de la distribution Linux retenue), du SBOM, et de l'analyse de risque ISO 14971 des 3 DM hébergés (cf. §8).
- **IIS** : à suivre via MSRC au même titre que Windows Server (les CVE IIS sont incluses dans le Patch Tuesday).
- **Toute vulnérabilité infra qui compromet un DM hébergé est tracée dans les dossiers ISO 14971 des DM concernés** (cf. §4.8).

**Sous-périmètre Infrastructure d'exécution** (transverse UE et US — l'OS hôte et le middleware sont des SOUP au sens IEC 62304 §9 et MDCG 2019-16 §3.1, donc indissociables du périmètre produit) :

| Composant | Type | État actuel | Cible / évolution |
|-----------|------|-------------|-------------------|
| Windows Server | OS hôte production | Versions 2016, 2022, 2024, 2025 cohabitent (parc hétérogène) | Migration future vers Linux (distribution et version à arbitrer) |
| IIS | Serveur web en production | Actif (héberge le portail Symfony + modules) | À statuer post-migration Linux (probablement remplacement par Nginx/Apache) |
| MariaDB | SGBD relationnel principal | Version à préciser auprès équipe infra | inchangé |
| MongoDB | SGBD documentaire (en complément de MariaDB) | Version à préciser auprès équipe infra | inchangé |
| Conteneurs Docker (dev/CI) | Runtime build et tests | Alpine 3.21 / 3.23, PHP-FPM, Nginx, Node 23 | inchangé |
| Jenkins | Chaîne CI | Agent Windows | À statuer post-migration Linux |
| Ansible | Orchestration déploiement | Actif | inchangé |

Points d'attention :
- **Windows Server 2016** : fin de support étendu **janvier 2027** — anticiper sortie du parc avant cette date sous peine de classification "EOL en production" interdite par IEC 62304 §6.1.
- **Windows Server 2022/2024/2025** : versions à harmoniser (un parc à quatre versions concurrentes augmente la surface d'attaque et complique le suivi des CVE MSRC).
- **Migration Windows → Linux** : à traiter comme change request au sens IEC 62304 §6 et MDR art. 10 §9 — déclenche une révision du plan de veille (sources MSRC à remplacer par tracker de la distribution Linux retenue), du SBOM, et de l'analyse de risque ISO 14971 (cf. §8).
- **IIS** : à suivre via MSRC au même titre que Windows Server (les CVE IIS sont incluses dans le Patch Tuesday).

### 2.2 Composants techniques surveillés

**Couche portail Symfony (`saas_local/app/`)** :

| Composant | Version courante | EOL connu |
|-----------|------------------|-----------|
| PHP | 8.1+ | 8.1 hors support depuis 31/12/2025 — migration à planifier |
| Symfony | 5.4 LTS | bugs 11/2025, sécurité 11/2026 |
| Doctrine ORM / MongoDB ODM | dernières 2.x / 4.x | actif |
| MariaDB | à préciser | à préciser |
| MongoDB (ext-mongodb) | à préciser | à préciser |
| Nginx (alpine 3.23) | 1.x | actif |
| jQuery | 3.5 | actif |
| Bootstrap | 4.6 | bugfixes uniquement |
| TinyMCE | 8 | actif |
| chart.js, datatables, axios, choices.js | dernières stables | actif |
| Webpack Encore | 1.8 | actif |
| Node.js (build only) | 23 alpine 3.21 | actif |
| Composer | 2 | actif |

**Couche modules 3D Angular (`saas_local/modulesjs/`)** :

| Module | Angular | Three.js | Bootstrap | Test runner | Statut réglementaire |
|--------|---------|----------|-----------|-------------|---------------------|
| plannerHip2D | 20.3 | 0.150 (ancienne) | 5.2 | Karma + Jasmine | MDR (sous-périmètre A) + FDA 510(k) (sous-périmètre B) |
| plannerHip3D | 20.3 | 0.181 | 5.3 | Cypress 15 + Karma | MDR (sous-périmètre A) |
| plannerKneeMadison | 20.3 | 0.179 | 5.3 | Cypress 15 + Karma | MDR (sous-périmètre A) |
| plannerShoulder3D | **21.2** (divergent) | 0.182 | n/a (Tailwind 4) | Vitest 4 | Non-DM (sous-périmètre C) |

L'hétérogénéité des versions Angular et Three.js est un risque IEC 62304 §6.1. Item récurrent ARCH-VERSIONS-CONVERGENCE à suivre en §7 du rapport mensuel jusqu'à clôture.

**Imagerie médicale** : DICOM (nanodicom côté backend), NIfTI (`nifti-reader-js` côté modules 3D), WebGL/WebXR.

**Infrastructure** : voir sous-périmètre dédié §2.1 "Infrastructure d'exécution" pour le détail OS hôte + IIS + bases. Composants chaîne d'outils : SonarQube `quality.3d4you.org`, GitHub (org `oneorthomedical`).

**Hors périmètre de veille produit** : Firebase Hosting et `firebase-tools` (utilisés uniquement pour publier des liens de test interne, pas livrables client). Surveillance d'intégrité pré-prod assurée à part par DevSecOps mais non incluse dans le présent plan.

### 2.3 SBOM

| Outil | Format | Périmètre | Localisation | Fréquence | Rétention |
|-------|--------|-----------|--------------|-----------|-----------|
| Syft | CycloneDX | Chaque repo (portail + 4 planificateurs + bundles) | Artefact Jenkins build, repo dédié `oneorthomedical/sbom-archive` (à confirmer) | À chaque build | 7 ans |
| Trivy | CycloneDX (image) | Image Docker construite de one-platform Symfony | Artefact Jenkins build de l'image | À chaque build image | 7 ans |
| Inventaire infra (à mettre en place) | Tableau Confluence ou export Ansible facts | OS hôtes (WS 2016/2022/2024/2025), IIS, MariaDB, MongoDB par environnement | Confluence "Inventaire Infra" + miroir SharePoint | Trimestriel + à chaque changement | 7 ans |

Procédure de croisement SBOM × sources de veille décrite en §4.2bis.

### 2.4 Distributeurs OEM concernés

Liste fermée des distributions surveillées (champ "Distributeur impacté" du rapport mensuel) :

| Code build | Distributeur |
|-----------|--------------|
| ds | Dedienne |
| oo | OneOrtho (auto-distribution) |
| serf | Stryker |
| lepine | Groupe Lépine |
| evolutis | Evolutis |
| fh | FH Orthopedics |
| in2bones | In2Bones |
| globald | Global D |
| kerimedical | Kerimedical |

Aucune clause contractuelle de cybersécurité spécifique connue à ce jour (notamment côté Stryker). La procédure de notification §4.9 s'applique uniformément à tous les distributeurs, graduée par criticité.

## 3. Sources de renseignement

### 3.1 Sources génériques (obligatoires)

| Source | URL | Type | Fréquence vérif |
|--------|-----|------|-----------------|
| CISA KEV Catalog | https://www.cisa.gov/known-exploited-vulnerabilities-catalog | API / RSS | Continue (push) — consolidation mensuelle |
| NVD / CVE | https://nvd.nist.gov | API | Continue — consolidation mensuelle |
| CERT-FR (ANSSI) | https://cert.ssi.gouv.fr | RSS | Continue (push) — consolidation mensuelle |
| GitHub Security Advisories (org `oneorthomedical`) | https://github.com/advisories | API | Continue (Dependabot push) |

### 3.2 Sources secteur santé (obligatoires)

| Source | URL | Type | Fréquence vérif |
|--------|-----|------|-----------------|
| CISA ICS Medical Advisories | https://www.cisa.gov/news-events/ics-medical-advisories | RSS | Continue (push) |
| FDA Medical Device Safety | https://www.fda.gov/medical-devices/safety-communications | RSS | Mensuelle |
| FDA Cybersecurity Alerts | https://www.fda.gov/medical-devices/digital-health-center-excellence/cybersecurity | RSS | Mensuelle |
| HHS HC3 (Health Sector Cybersecurity Coordination Center) | https://www.hhs.gov/about/agencies/asa/ocio/hc3 | Web / Mail | Mensuelle (sur sous-périmètre US) |
| ENISA Health sector | https://www.enisa.europa.eu | Web | Mensuelle |
| H-ISAC | https://h-isac.org | Membre (si accès) | Continue (si accès) |
| ANSM Cybersécurité DM | https://ansm.sante.fr | Web | Mensuelle |

### 3.3 Sources stack technique

Tableau détaillé en fichier séparé : `./utils/hds/sources_stack_technique.md` (couches portail Symfony, modules Angular, imagerie DICOM/NIfTI, infrastructure, sources internes).

À intégrer dans la version v3 du présent plan après relecture.

### 3.4 Sorties outillage interne (sources internes)

| Source | Producteur | Cadence |
|--------|-----------|---------|
| Trivy scans image | Jenkins pipeline `one-platform` | À chaque build |
| Syft SBOM CycloneDX | Jenkins pipelines (tous repos) | À chaque build |
| `composer audit` | Jenkins pipeline | À chaque build |
| `npm audit` / `yarn audit` | Jenkins pipelines modules | À chaque build |
| SonarQube `quality.3d4you.org` | Jenkins post-merge | À chaque PR |
| GitHub Dependabot | GitHub (org `oneorthomedical`) | Continue |
| GitHub Secret Scanning | GitHub (org `oneorthomedical`) | Continue |

Toute alerte issue de §3.4 est versée dans le backlog Jira `SEC-INBOX` pour triage lors de la consolidation mensuelle (§4.1).

## 4. Processus

### 4.0 Veille continue (hebdomadaire)

Niveau opérationnel — assure la **découverte** des vulnérabilités. Pas de livrable documentaire formel.

- Lecture hebdomadaire des sorties CI/CD (§3.4) par le DevSecOps.
- Traitement des alertes push des sources §3.1, §3.2, §3.3.
- Ouverture systématique d'un ticket Jira `SEC-INBOX-{{ID}}` pour chaque item potentiellement applicable.
- Aucune décision d'applicabilité formelle à ce stade — pré-triage uniquement (à investiguer / à écarter en consolidation mensuelle).

### 4.0bis Déclenchement hors-cycle (0-day / KEV ajout)

Activé dès qu'une des conditions est remplie :

- ajout d'une CVE applicable au catalogue CISA KEV avec exploitation active,
- publication d'un advisory CRITIQUE par CERT-FR / CERT Santé (ANS) / CISA ICS Medical sur un composant utilisé,
- alerte Trivy / Syft / Dependabot d'un CVSS ≥ 9 sur composant en production.

SLA prise en charge : **≤ 24 h ouvrées**. Workflow :

1. DevSecOps ouvre un item de criticité P1 dans Jira.
2. Notification immédiate Responsable Numérique.
3. Analyse d'applicabilité menée dans la journée (croisement SBOM Syft).
4. Décision de remédiation et de communication (§4.9) sous 24 h supplémentaires si applicable.
5. Inscription dans la section "Items hors-cycle" du rapport mensuel en cours.
6. **Si l'item affecte un DM MDR (sous-périmètre A) ou Hip2D FDA (sous-périmètre B), transmission informative au pôle Affaires Réglementaires** (cf. §4.8). Le pôle décide indépendamment de l'opportunité d'une procédure réglementaire.

### 4.1 Préparation de la consolidation mensuelle (J-7 → J-1)

- Création automatique (Jira Automation, cron 1er jeudi 06h00 UTC) du ticket parent `SEC-THREATINTEL-{{YYYY-MM}}` sous la tâche https://oneortho.atlassian.net/browse/CICD-161
- Vérification des accès aux sources §3.1 à §3.4
- Ouverture du template de rapport en statut DRAFT
- Pré-remplissage des sections §2 (sources consultées) et §3 (items issus de `SEC-INBOX` accumulés sur le mois)

### 4.2 Collecte

- Parcours de chaque source sur les 30 derniers jours
- Extraction des items potentiellement applicables (ceux non encore versés à `SEC-INBOX` par la veille continue)
- Consignation dans la section "Items identifiés" du rapport

### 4.2bis Croisement SBOM × sources

Étape obligatoire avant l'analyse :

1. Récupérer le SBOM Syft le plus récent de chaque repo + SBOM Trivy de l'image one-platform.
2. Croiser les composants listés avec la liste d'items §4.2 (script de matching CVE × package).
3. Tout composant présent dans le SBOM et apparaissant dans une source §3 est marqué "À analyser" (statut par défaut : Applicable, à confirmer en §4.3).
4. Comparaison SBOM N vs N-1 (mois précédent) — toute nouvelle dépendance introduite sans revue est tracée en §7 du rapport.
5. Conserver le résultat du croisement comme pièce probante (annexe rapport mensuel).

### 4.3 Analyse

Pour chaque item, évaluer :

| Critère | Valeurs |
|---------|---------|
| Applicabilité | Applicable / Non applicable / À investiguer |
| Criticité CVSS v3.1 | 0 à 10 + vecteur |
| Exploit public | Oui / Non |
| Exploitation active | Oui (KEV) / Non |
| Exposition OneOrtho | Internet / Interne / Hors ligne |
| Composant impacté | nom + version |
| Produit concerné | Portail Symfony / Module2DHip / Module3DHip / Module3DKnee / plannerHip2D / plannerHip3D / plannerKneeMadison / plannerShoulder3D / Bundle X / Infra (Windows Server / IIS / MariaDB / MongoDB / Docker / Jenkins / Ansible) |
| Distributeur impacté | Tous / liste filtrée §2.4 |
| Catégorie de périmètre | A (DM MDR seul) / A+B (MDR + FDA 510k Hip2D) / C (hors-DM hébergeur ou intégré) / D (infrastructure transverse) |
| Effet de bord sur DM | Oui / Non — si "Oui" sur item C ou D, l'item est marqué comme déclenchant une transmission informative au pôle Affaires Réglementaires (cf. §4.8) |
| Priorité résultante | P1 / P2 / P3 / P4 |

### 4.4 Matrice de priorisation

| Exploité activement | CVSS ≥ 7 | Exposition internet | Priorité |
|---------------------|----------|---------------------|----------|
| Oui | Oui | Oui | P1 (72 h) |
| Oui | Oui | Non | P2 (2 semaines) |
| Non | Oui | Oui | P2 (2 semaines) |
| Non | Oui | Non | P3 (1 mois) |
| Non | < 7 | indifférent | P4 (≤ 90 jours) |

### 4.5 Décision et création des tickets

- Création d'un ticket Jira de remédiation par item P1/P2/P3 avec Responsable du pôle et chef de projet
- Lien au ticket de revue mensuelle
- Assignation au Tech Lead concerné
- Tag Jira par sous-périmètre pour faciliter les recherches d'audit : `SCOPE-MDR-HIP2D`, `SCOPE-MDR-HIP3D`, `SCOPE-MDR-KNEE`, `SCOPE-FDA-510K-HIP2D`, `SCOPE-NONDM-SYMFONY`, `SCOPE-NONDM-SHOULDER`, `SCOPE-INFRA`

### 4.6 Validation de la consolidation (J → J+2)

- Compléter le rapport mensuel (cf. `template_rapport_mensuel_threat_intelligence.md`)
- Bascule du statut DRAFT → VALIDATED par signature du Responsable Numérique
- Publication Confluence (espace CyberSécurité > PSSI > Threat Intelligence)
- Notification équipe sur Slack #comité_technique

### 4.7 Mise à jour traçabilité (J+15)

Pas de réunion. Mise à jour différée du rapport mensuel :

- Ajout en section "Items hors-cycle (0-day)" des items §4.0bis survenus depuis la consolidation
- Mise à jour du statut des items §3 (suivi reliquat)
- Recalcul des KPI mois (§6)
- Mail au Responsable Numérique avec lien Confluence
- Bascule du statut VALIDATED → PUBLISHED par export PDF signé et archivage SharePoint (cf. §7 Annexes)

### 4.8 Transmission informative au pôle Affaires Réglementaires

La mise à jour des dossiers ISO 14971 et les procédures réglementaires associées (vigilance MDR art. 87, FDA MedWatch, PSUR/PMSR) sont **hors-scope du présent plan**. Elles sont pilotées indépendamment par le pôle Affaires Réglementaires.

Le DevSecOps assure une **transmission informative** vers le pôle Affaires Réglementaires (contact : Céline Antoine) dès qu'un item répond à au moins un des critères suivants :

| Condition de transmission | Délai |
|---------------------------|-------|
| Item P1 affectant directement un DM (sous-périmètre A ou A+B) | Sous 48 h ouvrées après confirmation d'applicabilité |
| Item P1 sur sous-périmètre C ou D **avec effet de bord avéré** sur un DM | Sous 48 h ouvrées |
| Item P2 répété sur un même composant utilisé par un DM (tendance) | À la consolidation mensuelle |
| Tout item entrant dans la section "Items hors-cycle" et affectant un DM | À la mise à jour J+15 |

Forme de la transmission : mail récapitulatif au pôle Affaires Réglementaires avec lien vers l'item Jira, le rapport mensuel en cours et l'extrait SBOM concerné. Pas de décision réglementaire prise par le présent processus. Le pôle reste libre d'évaluer l'opportunité d'une procédure (mise à jour dossier risque, notification autorité, etc.) selon ses propres règles.

La transmission est **tracée dans le rapport mensuel §3.2** (champ "Transmission Affaires Réglementaires : date + destinataire"), uniquement à des fins d'audit cyber (preuve que la veille cyber a alimenté le réglementaire le moment venu). La réponse du pôle réglementaire n'est pas requise pour clôturer un item du présent processus.

### 4.9 Communication commerciale clients et distributeurs

Décisions de communication portées par OneOrtho à titre commercial et de service support. Les notifications réglementaires aux autorités (ANSM, FDA, BfArM, organisme notifié) sont **hors-scope** et restent pilotées par le pôle Affaires Réglementaires.

Décision graduée par criticité :

| Priorité | Communication clients / distributeurs |
|----------|--------------------------------------|
| P1 avec impact fonctionnel ou sécurité côté client | Communication ciblée sous 48 h ouvrées |
| P1 sans impact fonctionnel client (remédiation transparente) | Mention dans le rapport mensuel diffusé, sans alerte dédiée |
| P2 | Information dans newsletter sécurité trimestrielle |
| P3 / P4 | Pas de communication individuelle |

Décision portée par : Responsable Numérique (R), Direction commerciale (C), Direction (I).

Contenu de toute communication : description impact, produit ou composant concerné, version corrigée, date de mise à disposition du correctif, mesures de mitigation transitoires. Trace écrite obligatoire dans le rapport mensuel §3.2 pour chaque item P1/P2.

**Si un item P1 affecte un DM (sous-périmètre A ou A+B, ou C/D par effet de bord)**, la transmission au pôle Affaires Réglementaires §4.8 est déclenchée en parallèle. La communication commerciale et la procédure réglementaire éventuelle sont **deux flux distincts** : OneOrtho informe ses clients du correctif applicatif, le pôle Affaires Réglementaires décide ou non d'une notification autorité.

## 5. Rôles et responsabilités

| Rôle | Titulaire / Entité | Responsabilité |
|------|--------------------|----------------|
| Responsable Numérique | Service Numérique OneOrtho | Validation rapport, arbitrage priorités, signature DRAFT → VALIDATED → PUBLISHED, décision de communication commerciale |
| DevSecOps | Service Numérique OneOrtho | Veille continue, collecte, première analyse, rédaction rapport, publication, transmission §4.8 vers Affaires Réglementaires |
| Tech Leads | Par produit | Évaluation technique d'applicabilité, exécution remédiations |
| Pôle Affaires Réglementaires (référent : Céline Antoine) | OneOrtho | **Destinataire d'information** sur tout item affectant un DM (cf. §4.8). **Aucun rôle bloquant** dans le présent processus. Le pôle pilote indépendamment ses propres procédures (vigilance MDR, FDA MedWatch, mise à jour ISO 14971, PSUR/PMSR) hors de ce plan. |
| Direction commerciale | OneOrtho | Validation des communications clients/distributeurs en §4.9 |
| Comité de direction | Direction OneOrtho | Information sur menaces secteur santé majeures |
| Communication OEM | Responsable Numérique (point de contact unique OneOrtho) | Diffusion vers les 9 distributeurs §2.4 selon procédure §4.9 |

## 6. Indicateurs de suivi (KPI)

| Indicateur | Cible |
|-----------|-------|
| Consolidations mensuelles réalisées | 12/12 par an |
| Mises à jour traçabilité J+15 réalisées | 12/12 par an |
| Délai moyen remédiation P1 | < 72 h |
| Délai moyen remédiation P2 | < 14 j |
| Délai moyen remédiation P3 | < 30 j |
| Délai moyen remédiation P4 | ≤ 90 j |
| Délai moyen prise en charge 0-day (§4.0bis) | < 24 h |
| Taux de vulnérabilités non remédiées > 30 j | < 5 % |
| % items affectant un DM tracés en transmission Affaires Réglementaires (§4.8) | 100 % |
| Délai moyen de transmission §4.8 sur item P1 affectant un DM | ≤ 48 h ouvrées |
| Délai moyen de communication clients pour P1 avec impact fonctionnel | ≤ 48 h ouvrées |
| Nb sources §3 non consultées sur le mois | 0 |
| Délai moyen ajout source manquante (post-incident) | ≤ 30 j |

## 7. Annexes et preuves probantes

Tout rapport mensuel s'accompagne des pièces probantes suivantes, conservées 7 ans (rétention alignée audit cyber et délai conservatoire DM hébergés) :

- export CSV CISA KEV à la date de consolidation,
- export NVD filtré stack OneOrtho,
- résultats `composer audit`, `npm audit`/`yarn audit`, Trivy de la dernière build,
- SBOM Syft CycloneDX (par repo) et SBOM Trivy (image one-platform) figés à la date de revue,
- résultat du croisement SBOM × sources (§4.2bis),
- PV signé de la réunion mensuelle (1er jeudi),
- export PDF du rapport en statut PUBLISHED avec signature électronique du Responsable Numérique (format à arbitrer : approval Confluence, signature manuscrite scannée, ou eIDAS avancée si l'audit cyber l'exige).
- copies des mails de transmission §4.8 vers le pôle Affaires Réglementaires (preuve d'audit que le flux d'information a été tenu).

Stockage :

- édition vivante : Confluence `CyberSécurité/PSSI/Threat-Intelligence/{{YYYY-MM}}-revue-mensuelle`,
- archive figée signée : SharePoint `OneOrthoGED` — dossier `Rapport mensuel - Revue Threat Intelligence`,
- annexes : sous-dossier `annexes/{{YYYY-MM}}/` (Confluence + miroir SharePoint).

## 8. Révision du plan

Ce document est révisé :

- annuellement,
- ou lors de tout changement majeur du portefeuille produit (ajout/retrait planificateur, ajout/retrait distributeur OEM),
- ou lors de tout changement majeur du référentiel cyber primaire (nouvelle version ISO 27001, ISO 27005, nouvelle PSSI OneOrtho),
- ou lors de l'évolution du portefeuille DM (ex. : ouverture du dossier MDR plannerShoulder3D, nouveau dossier 510(k) US), pour ajuster la classification §2.1 et les règles de transmission §4.8,
- ou lors de tout **changement majeur d'environnement d'exécution** (migration Windows Server → Linux, sortie de support d'une version WS du parc, changement de serveur web IIS → autre, changement de SGBD, conteneurisation/déconteneurisation de la prod). Ces changements sont à coordonner avec le pôle Affaires Réglementaires si DM hébergés impactés, sans que le présent plan en pilote la dimension réglementaire.

Les sources §3 elles-mêmes font l'objet d'une revue annuelle pour vérifier leur disponibilité, leur format et leur pertinence.

## 9. Historique des versions

| Version | Date | Auteur | Description |
|---------|------|--------|-------------|
| v1 | initiale | DevSecOps | Première version du plan |
| v2 | 2026-05-18 | DevSecOps | Refonte intégrant : séparation périmètre UE/US (510k plannerHip2D), liste fermée distributeurs OEM, SBOM Syft+Trivy, séparation veille continue/consolidation mensuelle/traçabilité J+15, ajout 0-day SLA 24h, boucle ISO 14971, procédure de notification graduée, KPI étendus, PRRC nommé (Céline Antoine), §7 Annexes ajouté |
| v2.1 | 2026-05-18 | DevSecOps | Ajout sous-périmètre "Infrastructure d'exécution" §2.1 : Windows Server 2016/2022/2024/2025, IIS, MariaDB, MongoDB. Anticipation migration Linux. Impact transverse ISO 14971 §4.8. Déclencheur supplémentaire §8. Inventaire infra ajouté en §2.3 |
| v2.2 | 2026-05-18 | DevSecOps | Refonte §2.1 en 4 sous-périmètres distincts : A (DM MDR : Hip2D + Hip3D + KneeMadison), B (FDA 510k : Hip2D), C (non-DM hébergeurs ou intégrés : OneSoftware Symfony + plannerShoulder3D), D (infrastructure transverse). Refonte §4.8 (3 dossiers ISO 14971 seulement, mécanisme d'effet de bord C/D → A). Refonte §4.9 (notification graduée par sous-périmètre, PRRC engagé uniquement sur items affectant un DM). Statut réglementaire ajouté en §2.2 par module. |
| v2.3 | 2026-05-18 | DevSecOps | **Repositionnement majeur** : le plan devient un processus interne de traçabilité cyber pour audit (ISO 27001, audit client, audit assureur). Découplage des procédures réglementaires MDR/FDA, désormais hors-scope et pilotées indépendamment par le pôle Affaires Réglementaires. PRRC retiré du rôle bloquant, devient destinataire d'information (§4.8). §4.8 transformé en "transmission informative" non bloquante. §4.9 recentré sur communication commerciale clients/distributeurs (notifications autorité retirées). §5 rôles ajusté. KPI ISO 14971 remplacés par KPI de transmission. Références réglementaires conservées comme contexte produit, plus comme moteur du processus. |

## Décisions arbitrées et restant ouvertes

Voir `./utils/hds/avis_plan_revue_mensuel.md` §6 et §7 pour la traçabilité complète des arbitrages 2026-05-18.

Question restant ouverte à la date de v2.3 :

- format de signature électronique pour la version PUBLISHED du rapport (approval Confluence / signature manuscrite scannée / eIDAS avancée si exigé par l'auditeur cyber).
