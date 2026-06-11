# Rapport mensuel — Revue Threat Intelligence OneOrtho — {{YYYY-MM}}

Squelette à remplir. Remplacer tous les {{...}}. Conserver l'ordre des sections (aligné sur le template Confluence `template_rapport_mensuel_threat_intelligence.md`).

---

## Métadonnées

| Champ | Valeur |
|-------|--------|
| Période couverte | 01/{{MM}}/{{YYYY}} au {{dernier jour}}/{{MM}}/{{YYYY}} |
| Date de la revue | {{JJ/MM/AAAA — 1er jeudi du mois suivant}} |
| Analyste | Georges TATCHUM |
| Validé par | HK — Responsable Numérique |
| Date de validation | {{JJ/MM/AAAA — revue + J+2 ouvrés}} |
| Ticket Jira | CICD-{{XXX}} — SEC-THREATINTEL-{{YYYY-MM}} |

---

## 1. Résumé exécutif

{{3 à 5 lignes : nombre d'items examinés, nombre d'applicables, priorité maximale, décisions clés. Pas de préambule.}}

---

## 2. Sources consultées

> Légende : ✔ consultée et traitée / ✗ non consultable (motif) / ☐ planifiée non consultée (cadence réduite).

| Source | Consultée | Date dernière publication lue | Nb items remontés | Remarques |
|--------|-----------|------------------------------|-------------------|-----------|
| CISA KEV Catalog | | | | |
| NVD / CVE | | | | |
| CERT-FR (ANSSI) | | | | |
| GitHub Security Advisories | | | | |
| CISA ICS Medical Advisories | | | | |
| FDA Medical Device Safety | | | | |
| ENISA Health sector | | | | |
| H-ISAC | | | | |
| Angular Security Advisories | | | | |
| Node.js Security | | | | |
| PHP Security Releases | | | | |
| GitHub Advisories php/php-src | | | | |
| Symfony Security Advisories | | | | |
| MariaDB Security Releases | | | | |
| MSRC Security Update Guide | | | | |
| NEMA DICOM Standard Newsroom | | | | |
| Recherche NVD filtrée DICOM | | | | |
| Three.js Security Advisories | | | | |
| Three.js Releases | | | | |
| Dépendances tierces — Snyk SCA | | | | |
| Dépendances tierces — GitHub Dependabot | | | | |

Synthèse : {{N}} sources ✔ consultées / {{N}} ✗ non consultables / {{N}} ☐ planifiées.

---

## 3. Items identifiés

### 3.1 Synthèse chiffrée

| Indicateur | Valeur |
|-----------|--------|
| Total items examinés | {{N}} |
| Applicables OneOrtho | {{N}} individuels + {{groupes éventuels}} |
| Non applicables | {{N}} |
| À investiguer | {{N}} |
| Priorité P1 | {{N}} |
| Priorité P2 | {{N}} |
| Priorité P3 | {{N}} |
| Priorité P4 | {{N}} |

### 3.2 Détail des items applicables

Une fiche par item P1/P2/P3 (P4 regroupables en liste). Titre = CVE-/GHSA-.

#### Item {{N}} : {{CVE-AAAA-XXXXX ou GHSA-xxxx}}

| Champ | Valeur |
|-------|--------|
| Titre | {{intitulé technique}} |
| Source | {{source primaire}} |
| Date publication | {{JJ/MM/AAAA}} |
| CVSS | {{score ou "non communiqué, à compléter via NVD"}} |
| Exploité activement (KEV) | Oui / Non |
| Exploit public | Oui / Non |
| Composant impacté | {{nom + version, confirmé par croisement stack}} |
| Produit concerné | {{Portail Symfony / plannerXxx / Infrastructure}} |
| Exposition | Internet / Interne / Hors ligne |
| Priorité retenue | P{{1-4}} |
| Action décidée | {{patch / mitigation / monitoring / investigation}} |
| Ticket remédiation | À créer en Jira, lié à CICD-{{XXX}} |
| Échéance | {{date selon priorité}} |
| Responsable | {{Tech Lead concerné / DevSecOps + infra}} |

### 3.3 Items non applicables (traçabilité)

Regrouper par source. Chaque ligne : identifiant / titre / motif de non-applicabilité.

**{{Source}}**

| ID | Titre | Raison non applicabilité |
|----|-------|--------------------------|
| | | |

**Items hors périmètre** (tracés, non comptés en applicables) :

| Avis | Source | Motif d'exclusion du périmètre |
|------|--------|--------------------------------|
| | | hors périmètre du plan (Docker / Nginx / poste dev / Firebase) |

---

## 4. Tendances observées

{{5 à 10 lignes : batches éditeur du mois, points d'amplification (parc MariaDB, hétérogénéité Angular/Three.js), sources rattrapées manuellement, présence/absence de KEV sur le stack.}}

---

## 5. Suivi des items des mois précédents

{{Premier exercice : "Premier exercice — sans objet pour ce mois." Sinon : tableau statut des tickets ouverts les mois précédents.}}

| Item (mois origine) | Ticket | Statut | Commentaire |
|---------------------|--------|--------|-------------|
| | | Ouvert / En cours / Fermé | |

---

## 6. Décisions et actions

| # | Décision / Action | Item lié | Responsable | Échéance | Statut |
|---|-------------------|----------|-------------|----------|--------|
| 1 | | | | | À faire |

---

## 7. Recommandations pour le mois suivant

- {{point concret 1}}
- {{point concret 2}}
- {{...}}

### Sujets à traiter dans le rapport du mois suivant

- Statut des décisions §6 ci-dessus.
- Suivi §5 des items ouverts ce mois.
- {{Patch Tuesday du mois suivant, etc.}}

---

## 8. Export

- Publication Confluence : espace CyberSécurité > PSSI > Threat Intelligence, page `{{YYYY-MM}} Revue Threat Intelligence`.
- Export PDF SharePoint OneOrthoGED : `Rapport mensuel - Revue Threat Intelligence - {{YYYY-MM}}.pdf`.
- Notification Slack #comité_technique avec lien Confluence.

---

## Note de validation

{{Préciser si la validation DRAFT → VALIDATED est conditionnée à un rattrapage (sources internes Snyk/Dependabot, source manuelle non fournie). Bascule VALIDATED à la date de validation.}}
