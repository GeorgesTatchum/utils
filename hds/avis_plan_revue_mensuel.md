# Avis sur plan_revu_mensuel.md

Document audité : `/plan_revu_mensuel.md` (état au 2026-05-18).
Périmètre couvert par l'avis : structure, conformité réglementaire (MDR 2017/745, IEC 62304, FDA), cohérence stack, opérabilité.

## 1. Points forts

- Structure conforme à ISO 27001 A.5.7 (Threat Intelligence).
- Matrice de priorisation (4.4) claire et opérationnelle, SLA P1/P2/P3 alignés sur pratiques de marché.
- Boucle Jira + Confluence + Slack identifiée, gouvernance désignée (DevSecOps / Responsable Numérique / Tech Leads).
- KPI mesurables.

## 2. Incohérences à corriger avant validation

### 2.1 Stack annoncée vs stack réelle
Le §2.2 cite **Angular** comme framework front. Vérification du code :

- **`saas_local/app/`** (portail Symfony) : **pas d'Angular**. Stack réelle = jQuery 3.5 + Bootstrap 4.6 + Webpack Encore 1.8 + chart.js + datatables.net + tinymce 8 + axios + choices.js.
- **`saas_local/modulesjs/`** (planificateurs 3D) : **Angular bien présent**, mais versions hétérogènes :
  - plannerHip3D : Angular **20.3**, Three.js **0.181**
  - plannerKneeMadison : Angular **20.3**, Three.js **0.179**
  - plannerHip2D : Angular **20.3**, Three.js **0.150** (très ancienne, ~2023)
  - plannerShoulder3D : Angular **21.2**, Three.js **0.182**

Action : §2.2 doit distinguer explicitement les deux couches "portail Symfony" et "modules 3D Angular", avec versions par module. L'hétérogénéité Angular 20 vs 21 et Three.js 0.150 → 0.182 est en soi un risque IEC 62304 §6.1 (maintenance SOUP) et doit faire l'objet d'un item récurrent dans §7 du rapport mensuel jusqu'à convergence.

### 2.1 bis Composants absents du plan
Le §2.2 du plan ne mentionne pas :

- **NIfTI** (`nifti-reader-js` 0.8) — format d'imagerie médicale volumétrique distinct de DICOM, utilisé dans Hip3D / Shoulder3D / KneeMadison. À ajouter aux composants surveillés.
- **Tailwind CSS 4** (plannerShoulder3D).
- **Cypress 15** (Hip3D, Knee) / **Vitest 4** (Shoulder) / **Karma + Jasmine** — chaîne de test à inclure dans le périmètre.
- **Variantes multi-distributeurs OEM** : ds (Dedienne), oo (OneOrtho), serf (Stryker), lepine, evolutis, fh, in2bones, globald, kerimedical, avec scripts `build:prod:*:MDR` explicites. Le plan doit nommer les distributeurs concernés, car la portée d'une vulnérabilité applicable et la cible de notification commerciale peuvent différer par distribution.

**Hors périmètre confirmé** : **Firebase Hosting / firebase-tools** sert uniquement à exposer des liens de test interne et n'est pas le livrable client. À marquer explicitement "hors-périmètre veille produit" dans le plan, avec une ligne dédiée pour éviter ambiguïté. Une surveillance allégée reste pertinente pour l'intégrité des environnements de pré-prod, mais ce n'est pas un objectif MDR/FDA.

### 2.2 Versions runtime non datées
Le plan ne cite pas les versions cibles, or :
- **PHP 8.1** = fin de support communautaire **31 décembre 2025**, hors support depuis cette date.
- **Symfony 5.4 LTS** = fin de support bugs **novembre 2025**, fin de support sécurité **novembre 2026**.
- **MariaDB**, **MongoDB**, **Node.js**, **Nginx 1.23 / nginx-alpine 3.23**, **Alpine 3.21** : versions non précisées dans le plan.

Action : ajouter dans §2.2 une colonne "version courante" + "date EOL" alimentée par SBOM. Sans cela, la revue ne détectera pas la sortie de support qui est elle-même une vulnérabilité au sens IEC 62304 §6.1.

### 2.3 Numérotation
Dans le plan source, la table des matières fait : 1 Objectif, 2 Périmètre, 3 Sources, 4 Processus, 5 Rôles, 6 KPI, puis directement **8 Révision du plan**. Le §7 est absent (ni titre ni contenu). Deux options :
- renuméroter "8 Révision du plan" en "7 Révision du plan",
- ou créer un §7 dédié (proposition : "7 Annexes et preuves probantes" — utile pour l'archivage MDR 7 ans).
Point mineur mais audit MDR remontera l'incohérence.

### 2.4 Fréquence inadaptée pour CISA KEV et CERT-FR
KEV et CERT-FR publient en quotidien. Une "fréquence de vérification mensuelle" expose à un retard de 30 jours sur un actif exploité. La cible KEV remédiation FCEB est **21 jours**.

Action : distinguer
- **monitoring continu automatisé** (alertes push : RSS, mails, webhooks Sonar/Trivy/Dependabot)
- **revue mensuelle** = consolidation, arbitrage, reporting.

### 2.5 Conformité réglementaire incomplète
Le plan référence MDR Annexe I §17.2. Manque :
- **IEC 62304 §6.1** (plan de maintenance logicielle) et **§9** (gestion des SOUP — Software of Unknown Provenance). C'est l'exigence qui rend la veille obligatoire pour chaque dépendance tierce.
- **MDCG 2019-16 rev.1** (cybersécurité MDR) — critère d'audit ON.
- **ISO 14971** : toute vulnérabilité applicable doit alimenter le dossier de gestion des risques, pas seulement le backlog Jira.
- **Couverture US** : la **FDA "Cybersecurity in Medical Devices" guidance (2023, finalisée 27 sept 2023)** impose un SBOM CycloneDX/SPDX et un monitoring post-market — à citer explicitement si OneSoftware est sous 510(k) ou De Novo.
- **PSUR / PMSR** (MDR §86) : le plan doit indiquer où la synthèse threat intel alimente le rapport périodique de sécurité.

### 2.6 SBOM existant mais non référencé dans le plan
SBOM en place mais le plan ne le décrit pas. État réel :
- **Syft** génère un SBOM CycloneDX pour chacun des repos (portail Symfony, 4 planificateurs Angular, bundles).
- **Trivy** génère un SBOM additionnel pour l'image Docker construite de la one-platform Symfony.

Manques à corriger dans le plan :
- §2.2 ne renvoie pas au SBOM Syft (chemin de stockage, nommage, versioning, rétention).
- Pas de procédure de **comparaison N vs N-1** entre deux SBOM successifs (delta dépendances) — utile pour détecter une nouvelle SOUP introduite sans revue.
- Pas de croisement SBOM × CISA KEV documenté.

Action : ajouter §2.3 "SBOM" listant outils (Syft + Trivy), localisation des artefacts (repo + ID build Jenkins), périodicité de génération (à chaque build), rétention (alignée 7 ans MDR). Ajouter §4.2bis "Croisement SBOM × sources" dans le processus.

### 2.7 P4 "prochain cycle" non défini
Ambigu : prochain cycle de release ? Prochaine revue mensuelle ? Définir un SLA explicite (ex : P4 ≤ 90 jours).

### 2.8 Champ "Propriétaire" / "Responsable"
"Responsable numérique - Service Numérique" et "DevSecops ou suppléant" sont des rôles, pas des personnes. Pour la traçabilité MDR, nommer une personne titulaire avec date d'effet (ex : Approuvé par : J. DUPONT, Responsable Numérique, 2026-05-18).

## 3. Manques majeurs

| # | Manque | Impact | Recommandation |
|---|--------|--------|----------------|
| 1 | Pas de lien explicite vers ISO 14971 | Hors-scope du présent plan (cf. décision §6.2) — alimente seulement la transmission §4.8 vers le pôle Affaires Réglementaires, qui pilote ISO 14971 indépendamment |
| 2 | Pas de procédure d'urgence hors-cycle (0-day) | Délai 30 j inacceptable sur 0-day actif | Ajouter §4.0bis "Déclenchement hors-cycle (zero-day / KEV ajout)" avec SLA 24 h |
| 3 | Pas de référence dans le plan au croisement SBOM ↔ vulnérabilité | Trace incomplète pour audit cyber | SBOM Syft + Trivy déjà générés — manque la **procédure de croisement** : à formaliser dans §4.2bis + lien vers SBOM cité dans le rapport mensuel §8 |
| 4 | Pas de communication client / distributeurs | Manque de service commercial OneOrtho | Ajouter §4.9 "Communication commerciale clients/distributeurs" (les notifications autorité ANSM/FDA restent hors-scope, pilotées par le pôle Affaires Réglementaires) |
| 5 | Pas de revue annuelle des sources elles-mêmes | Sources peuvent disparaître ou changer de format | §8 prévoit révision annuelle, étendre aux sources |
| 6 | Pas d'archivage des preuves de revue (screenshots, exports) | Audit-trail cyber insuffisant | Ajouter §7 "Annexes et preuves probantes" — exports horodatés conservés 7 ans |
| 7 | Aucune mention SAST/DAST/SCA déjà en place | Sonar et Trivy existent mais ne sont pas intégrés au flux | Ajouter §3.4 "Sorties outillage interne" |

## 4. Recommandations rédactionnelles

- §1 Objectif : ajouter "et alimenter le dossier de gestion des risques produit conformément à ISO 14971 §6.4".
- §3.1 : URLs en HTTPS uniquement (les liens sont en `http://`).
- §4.1 : préciser que le numéro de ticket Jira parent doit être créé via automation (ex : Jira Automation cron 1er jeudi 06h00 UTC).
- §5 : ajouter le rôle "PRRC / Person Responsible for Regulatory Compliance" (obligatoire MDR art. 15) en information sur tout item P1.
- §6 : ajouter KPI "% items dont l'analyse de risque a été mise à jour" et "délai moyen ajout source manquante".

## 5. Verdict

Plan **utilisable à 70 %**. À reprendre prioritairement : §2.2 (séparer couche portail Symfony et couche modules Angular, avec versions par module et par distributeur), §3.3 (à compléter — voir `sources_stack_technique.md`), ajout monitoring continu vs revue mensuelle, ajout boucle ISO 14971, ajout procédure 0-day hors-cycle, ajout suivi convergence des versions Angular / Three.js / Bootstrap entre modules.

Une fois ces corrections intégrées, le plan est conforme aux exigences combinées MDR + IEC 62304 + FDA Cybersecurity Guidance 2023.

## 6. Décisions arbitrées (2026-05-18)

> **Repositionnement majeur du processus (cf. plan v2.3)** : le plan ne porte plus la dimension réglementaire MDR/FDA, qui reste pilotée indépendamment par le pôle Affaires Réglementaires. Le présent processus est un **processus interne de traçabilité cyber** destiné à alimenter les audits cyber (ISO 27001, audit client, audit assureur, audit interne PSSI). Les décisions ci-dessous sont ajustées en conséquence.

1. **Périmètre US — 510(k) actif** : `plannerHip2D` (dossier déjà soumis). Catégorisé sous-périmètre B dans le plan v2.3 pour **traçabilité audit** uniquement. Les obligations FDA (SBOM CycloneDX exploitable, monitoring post-market, 21 CFR Part 11) restent pilotées par le pôle Affaires Réglementaires hors de ce plan.
2. **Analyse de risque ISO 14971** : **hors-scope du présent plan**. ISO 14971 reste de la responsabilité du pôle Affaires Réglementaires, qui décide indépendamment de la création et de la maintenance des dossiers risque par DM (Hip2D, Hip3D, KneeMadison, et plannerShoulder3D ultérieurement). Le plan se contente d'informer le pôle quand un item cyber affecte un DM (§4.8 transmission informative).
3. **Alignement versions** (Angular 20.3 vs 21.2, Three.js 0.150 → 0.182, Bootstrap 4.6 vs 5.3) : nécessaire pour simplification du suivi de veille. À arbitrer avec l'équipe dev (qui détient la roadmap technique) avant prochaine release. Ouvrir un ticket Jira "ARCH-VERSIONS-CONVERGENCE" et l'inscrire en item récurrent §7 du rapport mensuel jusqu'à clôture.
4. **Distributeurs OEM concernés** : ds (Dedienne), oo (OneOrtho), serf (Stryker), lepine, evolutis, fh, in2bones, globald, kerimedical. Intégrés en §2.1 du plan comme liste fermée.
5. **Communication clients/distributeurs** : OneOrtho assume la communication commerciale vers les 9 distributeurs en cas de vulnérabilité impactant le fonctionnement client. Graduation P1/P2/P3 décrite en §4.9 du plan. **Indépendante** de toute éventuelle notification autorité par le pôle Affaires Réglementaires.
6. **SBOM** : généré par **Syft** (CycloneDX) pour chaque repo et **Trivy** pour l'image one-platform Symfony. Documenté en §2.3 du plan. Utilisé par le présent processus pour croisement avec les sources de veille (§4.2bis). Le pôle Affaires Réglementaires l'utilise séparément pour ses obligations FDA.
7. **Cadence du processus** : suivi **hebdomadaire** des sorties CI/CD (Sonar, Trivy, Syft, Dependabot) assuré en continu par le DevSecOps = **découverte** des vulnérabilités. La revue mensuelle (1er jeudi) + mise à jour mi-mois sert à **établir la traçabilité cyber interne** (décision d'applicabilité, décision de communication, transmission au réglementaire si applicable). Trois niveaux distincts en §4 du plan :
   - §4.0 **Veille continue (hebdo)** = lecture des sorties CI/CD + alertes RSS push, ouverture de tickets SEC-INBOX.
   - §4.1-4.6 **Consolidation mensuelle (1er jeudi)** = arbitrage et production du rapport en DRAFT.
   - §4.7 **Mise à jour traçabilité (J+15)** = ajout des items survenus, bascule VALIDATED → PUBLISHED.
8. **Clauses OEM** : aucune clause cybersécurité particulière côté distributeurs (notamment Stryker/serf). Procédure de communication §4.9 uniforme pour les 9 distributeurs.
9. **Référent Affaires Réglementaires** : **Céline Antoine** (pôle Affaires Réglementaires OneOrtho). Inscrite en §5 du plan comme **destinataire d'information** sur tout item affectant un DM. **Aucun rôle bloquant** dans le présent processus.

## 7. Questions ouvertes restantes

- Format de signature pour la version PUBLISHED du rapport (eIDAS avancée, signature manuscrite scannée, approval Confluence) ? Impacte la recevabilité audit MDR et 21 CFR Part 11 sur le périmètre 510(k) plannerHip2D.
