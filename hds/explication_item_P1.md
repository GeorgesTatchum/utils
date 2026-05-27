# Item P1 — définition et exemple concret OneSoftware

Document explicatif rattaché au plan de revue mensuelle Threat Intelligence (`plan_revue_mensuel_v2.md` §4.4 et §4.8).

> **Repositionnement v2.3 du plan** : le présent processus est un **processus interne de traçabilité cyber** pour audit (ISO 27001, audit client, audit assureur). Les procédures réglementaires MDR/FDA (vigilance, ISO 14971, notification autorité) sont hors-scope et pilotées indépendamment par le pôle Affaires Réglementaires. Le PRRC n'a **aucun rôle bloquant** dans ce processus.

## 1. Définition d'un item P1

Selon la matrice de priorisation §4.4 du plan v2 :

| Critère | Valeur P1 |
|---------|-----------|
| Exploité activement (présent CISA KEV) | Oui |
| CVSS ≥ 7 | Oui |
| Exposition internet du composant | Oui |
| SLA de remédiation | 72 h ouvrées |

C'est la criticité maximale du plan. Elle déclenche un workflow cyber prioritaire et, **si l'item affecte un dispositif médical (DM)**, une transmission informative au pôle Affaires Réglementaires.

## 2. Workflow d'un item P1

Le traitement comporte trois volets indépendants :

| Volet | Pilote | Bloquant pour clôture du ticket cyber ? |
|-------|--------|-----------------------------------------|
| 1. Remédiation technique | Tech Lead + DevSecOps | Oui |
| 2. Communication commerciale clients/distributeurs (si impact client) | Responsable Numérique + Direction commerciale | Oui pour le rapport mensuel |
| 3. Transmission informative au pôle Affaires Réglementaires (si DM impacté) | DevSecOps → Céline Antoine | **Non** — le ticket cyber se clôt indépendamment de la réponse du pôle |

Le pôle Affaires Réglementaires reçoit l'information, en fait ce qu'il juge nécessaire (mise à jour ISO 14971, notification ANSM/FDA, PSUR/PMSR) selon ses propres règles, hors de ce plan.

## 3. Exemple concret sur le SI OneOrtho (scénario hypothétique mais réaliste)

### 3.1 Découverte initiale

La veille hebdomadaire CI/CD (§4.0 du plan) remonte une nouvelle entrée au catalogue CISA KEV.

| Champ | Valeur |
|-------|--------|
| CVE | CVE-AAAA-XXXXX (exemple hypothétique) |
| Composant | `symfony/http-foundation` 5.4.x — déserialisation non sécurisée |
| CVSS v3.1 | 9.1 |
| Exploit public | Oui (PoC publié) |
| CISA KEV | Ajouté il y a 3 jours, exploitation active confirmée |
| Composant utilisé par OneOrtho | Oui — portail Symfony `saas_local/app/` |
| Croisement SBOM Syft (§4.2bis) | Confirmé présent dans portail + transitif via `oneortho/one-user-bundle` |
| Exposition | Internet (portail OneSoftware sur Windows Server) |
| Distributeurs impactés (§2.4) | Tous (9 OEM) |
| Catégorie de périmètre d'origine | C — OneSoftware Symfony (non-DM) |
| Effet de bord sur DM | **Oui** — le portail Symfony héberge les 3 DM. Compromission permet exfiltration des plannings cliniques et altération potentielle. |
| Priorité retenue | **P1** |
| SLA remédiation | 72 h ouvrées |

### 3.2 Déroulé sur 72 h

| T+ | Acteur | Action |
|----|--------|--------|
| 0 h | DevSecOps | Détection par alerte CISA KEV + Dependabot. Bascule §4.0bis. Ouverture Jira P1 avec tags `SCOPE-NONDM-SYMFONY` + `SCOPE-MDR-HIP2D` + `SCOPE-MDR-HIP3D` + `SCOPE-MDR-KNEE`. |
| 0 h | DevSecOps | Notification immédiate Responsable Numérique. |
| 4 h | DevSecOps + Tech Lead Symfony | Croisement SBOM Syft confirmé. Test d'exploitabilité sur staging. |
| 8 h | Responsable Numérique | Confirmation P1, décision : montée `symfony/http-foundation` vers 5.4.X+1. |
| 24 h | Tech Lead | Patch déployé en staging, tests Behat + Cypress de non-régression. |
| 36 h | Tech Lead + DevSecOps | Déploiement production via Jenkins + Ansible. |
| 48 h | Responsable Numérique + Direction commerciale | Décision §4.9 : communication ciblée aux 9 distributeurs OEM (faille corrigée, version livrée, mesures transitoires sur la fenêtre d'exposition). |
| 48 h | DevSecOps | **Transmission §4.8 vers Céline Antoine** : mail récapitulatif avec lien Jira, extrait SBOM, et indication des 3 DM impactés par effet de bord. Pas d'attente de retour pour clôturer le ticket. |
| 72 h | DevSecOps | Clôture Jira. Inscription dans la section "Items hors-cycle" du rapport mensuel. KPI "Délai prise en charge 0-day" = 36 h (cible < 24 h non tenue, à inscrire en §7 recommandations). KPI "Délai transmission §4.8" = 48 h (cible respectée). |

### 3.3 Contre-exemple : item P1 sur Symfony **sans** effet de bord sur DM

Exemple hypothétique pour illustrer un P1 qui ne déclenche **pas** de transmission §4.8.

| Champ | Valeur |
|-------|--------|
| CVE | CVE-BBBB-YYYYY (exemple hypothétique) |
| Composant | `symfony/web-profiler-bundle` (utilisé uniquement en environnement de développement) |
| CVSS v3.1 | 8.6 |
| CISA KEV | Oui |
| Exposition | Interne (jamais déployé en production grâce à `APP_ENV=prod`) |
| Catégorie de périmètre | C (OneSoftware Symfony, composant de dev) |
| Effet de bord sur DM | **Non** — composant désactivé en production, isolé du chemin d'exécution des DM hébergés |
| Priorité retenue | P1 (par application stricte de la matrice §4.4) |

Déroulé :
- T+0 : ouverture Jira P1, notification Responsable Numérique uniquement.
- T+4 : Tech Lead Symfony confirme l'isolation prod (`composer.json` `require-dev`, vérification Ansible deploy).
- T+24 : remédiation par montée de version côté dev.
- T+48 : **pas de communication clients** (composant non livré), **pas de transmission §4.8 vers Céline Antoine** (pas d'effet de bord DM).
- Trace finale : item dans rapport §3.2 avec champs "Catégorie = C", "Effet de bord sur DM = Non", "Transmission Affaires Réglementaires = N/A".

## 4. Tableau comparatif P1 / P2 / P3 / P4 sur le SI

| Scénario | Catégorie | Effet de bord DM | Priorité | Transmission §4.8 vers Affaires Réglementaires ? |
|----------|-----------|------------------|----------|--------------------------------------------------|
| CVE TinyMCE XSS, CVSS 6.1, pas dans KEV, exposé internet via portail | C (Symfony) | À évaluer | P3 (1 mois) | Non (P3) |
| CVE jQuery 3.5 prototype pollution, CVSS 7.5, pas dans KEV, exposé internet | C (Symfony) | Non (côté admin) | P2 | Non (P2) |
| CVE Three.js dans plannerHip3D, CVSS 8.0, KEV oui, module servi en mode authentifié | A | N/A (déjà A) | P2 | Non (P2, mais déclenchera transmission si répété — KPI tendance) |
| CVE Symfony HttpFoundation (cas §3.1) | C → effet de bord A | **Oui** | **P1** | **Oui** |
| CVE 0-day TinyMCE permettant exfiltration de session côté plannerHip2D, KEV oui, CVSS 9 | A + B | N/A (déjà A+B) | **P1** | **Oui** (info Affaires Réglementaires sur volet FDA potentiel) |
| CVE PHP 8.1 buffer overflow, CVSS 8.6, KEV ajouté, Symfony exposé internet | C → effet de bord A (3 DM) | **Oui** | **P1** | **Oui** |
| CVE MariaDB auth bypass, CVSS 9.8, pas dans KEV, MariaDB derrière VPN | D | Oui si DM lit la base | P2 | Non (P2) |
| CVE Angular core, CVSS 7.2, KEV oui, touche Hip2D+Hip3D+Knee | A (direct) | N/A | **P1** | **Oui** |
| CVE Angular core CVSS 9, KEV oui, touche **uniquement** plannerShoulder3D | C (Shoulder3D seul) | Non (Shoulder isolé, autres modules en Angular 20.3) | P1 | Non (pas de DM impacté) |
| CVE web-profiler-bundle (cf. §3.3) | C, dev only | Non | P1 | Non |
| CVE Windows Server 2016 critique KEV, héberge prod portail + 3 DM | D → effet de bord A | **Oui** | **P1** | **Oui** |

## 5. Synthèse

P1 = "feu rouge cyber" — traitement sous 72 h, communication clients si impact, traçabilité audit.

P1 + impact DM (direct ou par effet de bord) déclenche en plus une **transmission informative** au pôle Affaires Réglementaires (Céline Antoine) dans les 48 h. La transmission est tracée dans le rapport mensuel comme preuve d'audit, mais elle **ne bloque pas** la clôture du ticket cyber. Le pôle décide ensuite indépendamment d'éventuelles procédures réglementaires (mise à jour ISO 14971, notification ANSM/FDA, PSUR/PMSR).

P1 sur sous-périmètre C ou D sans effet de bord = traitement cyber uniquement, pas de transmission §4.8, pas de signature PRRC, pas d'engagement réglementaire.

P2 / P3 / P4 = traitement opérationnel, pas de transmission §4.8 sauf cas tendance (P2 répété sur même composant utilisé par un DM, transmis en consolidation mensuelle).

Deux critères discriminants à surveiller :
- l'ajout au catalogue CISA KEV (peut faire basculer un P2 en P1),
- l'apparition d'un **effet de bord** d'un item C ou D vers un DM (déclenche la transmission §4.8 vers le pôle Affaires Réglementaires).

La veille continue §4.0 et le mécanisme hors-cycle §4.0bis du plan v2.3 sont conçus pour détecter ces deux bascules au plus tôt.
