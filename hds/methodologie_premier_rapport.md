# Méthodologie — Production du premier rapport mensuel Threat Intelligence

Document opérationnel pour produire le rapport mensuel sur la base de `template_rapport_mensuel_threat_intellingence.md`.

Hypothèse retenue : le plan `plan_revu_mensuel.md` est considéré comme **correct et applicable en l'état**, complété en §3.3 par `complement_3_3_sources_stack.md`. Cette méthodologie suit fidèlement la structure des sections du template original.

## 0. Pré-requis (à régler une fois pour toutes)

À effectuer avant le premier exercice. Une seule fois.

| Action | Responsable | Vérification |
|--------|-------------|--------------|
| Créer le sous-ticket parent Jira `SEC-THREATINTEL-{{YYYY-MM}}` sous CICD-161 | DevSecOps | Lien Jira disponible |
| Configurer un agrégateur RSS (FreshRSS ou équivalent) avec tous les flux des §3.1 + §3.2 + §3.3 | DevSecOps | Tous les flux affichent des items |
| S'assurer que les comptes d'accès aux sources sont actifs (GitHub, H-ISAC si applicable) | DevSecOps | Test de connexion |
| Récupérer les SBOM Syft + Trivy de la dernière build GitHub Actions | DevSecOps | Fichiers présents en local |
| Identifier les Tech Leads par produit (portail Symfony et modules 3D Angular) | Responsable Numérique | Liste nominative |
| Préparer l'espace Confluence "CyberSécurité > PSSI > Threat Intelligence" | DevSecOps | Page parent créée |
| Préparer le dossier SharePoint cible (cf. §8 du template) | DevSecOps | Lien SharePoint actif |

## 1. Phase 1 — Préparation (J-7 → J-1)

Le "J" est le 1er jeudi du mois (date de la réunion de revue).

| Jour | Action | Livrable |
|------|--------|----------|
| J-7 | Création (ou vérification) du ticket Jira `SEC-THREATINTEL-{{YYYY-MM}}` | Ticket ouvert |
| J-7 | Ouverture du fichier `template_rapport_mensuel_threat_intellingence.md` dans Confluence, renommage en `{{YYYY-MM}} Revue Threat Intelligence` | Page Confluence en DRAFT |
| J-7 → J-1 | Remplissage des Métadonnées (période couverte, analyste, ticket Jira) | Métadonnées initiales |
| J-7 → J-1 | Listing des items à traiter (cf. Phase 2 ci-dessous) | Liste de candidats |

## 2. Phase 2 — Collecte des items (J-7 → J-1)

Trois sources d'items à agréger :

1. **Veille hebdomadaire CI/CD déjà effectuée pendant le mois** : items déjà identifiés via les workflows GitHub Actions (Snyk SCA sur lockfiles Composer côté PHP/Symfony et npm côté Angular, Trivy sur image conteneur, génération SBOM Syft, analyse statique de code) et via les services GitHub (Dependabot, Secret Scanning). Ce sont les plus nombreux. Récupérer la liste depuis Jira `SEC-INBOX` filtrée sur le mois écoulé.
2. **Parcours systématique des sources §3.1 + §3.2 + §3.3** sur les 30 derniers jours via l'agrégateur RSS. Noter pour chaque source la date de dernière publication lue (utile §2 du template).
3. **Items déjà traités hors-cycle** dans le mois (0-day, KEV) : récupérer la liste depuis Jira filtrée sur le tag dédié.

Pour chaque item candidat, capturer :

- identifiant (CVE ou advisory ID),
- titre,
- source d'origine,
- date de publication,
- score CVSS,
- composant impacté (recherche dans les SBOM Syft et Trivy pour confirmer ou infirmer la présence dans le stack OneSoftware, sur les composants nommés en §2.2 du plan : Angular, Node.js, PHP, Symfony, Composer, MariaDB, Windows Server, DICOM, Three.js, et toute dépendance tierce remontée par les scanners CI),
- statut KEV (présent au catalogue CISA KEV ou non).

Outil pratique : tableur Excel ou Google Sheets intermédiaire avant transfert dans le template.

**Étape de déduplication (obligatoire avant transfert dans le template)** :

Plusieurs canaux du §3.3 peuvent remonter la même CVE (par exemple : une CVE Symfony détectée à la fois par Symfony Security Advisories, par Snyk, et par GitHub Dependabot). Sans déduplication, le rapport surcompte les items.

Procédure :
1. Trier la liste collectée par identifiant CVE.
2. Fusionner les doublons : **un seul item par CVE** dans le rapport.
3. Renseigner le champ "Source d'origine" du template avec la **source primaire** disponible, dans cet ordre de préférence :
   - source éditeur officielle (Angular Security Advisories, Symfony, Three.js, Packagist, MSRC, MariaDB, Node.js, PHP),
   - puis CISA KEV / NVD / CERT-FR / CERT Santé,
   - puis canal scanner (Snyk, Dependabot, Trivy) en dernier recours si aucune source primaire trouvée.
4. Indiquer en colonne Remarques la liste des autres canaux qui ont détecté le même item (utile pour audit : preuve de défense en profondeur).
5. Pour les items remontés uniquement par un canal scanner sans source primaire identifiable, ouvrir la chasse à la source éditeur (l'advisory peut exister sans être indexé immédiatement). Si la source éditeur reste introuvable, conserver le scanner comme source primaire et le marquer en annexe.

## 3. Phase 3 — Analyse (J)

Réunion de 1 h 30 à 2 h (cf. plan §3). Présents : DevSecOps + Responsable Numérique + Tech Leads concernés selon les composants impactés.

Pour chaque item de la liste collectée, trancher les critères du §3.2 du template :

| Critère du template | Comment décider |
|---------------------|-----------------|
| Composant impacté | Vérifié par croisement SBOM (Syft + Trivy). Si le composant n'est pas dans le SBOM, item écarté en §3.3 du rapport ("Items non applicables") avec motif "composant non utilisé". |
| Produit concerné | Mappage SBOM vers produit. Un même composant peut toucher plusieurs produits (ex. composant runtime ou framework backend qui couvre tout le portail) ou un seul (ex. bibliothèque spécifique à un module 3D). |
| Exposition | Internet (portail exposé public) / Interne (bases et services derrière VPN ou réseau privé) / Hors ligne (composants utilisés uniquement en développement ou en build). À trancher avec le Tech Lead. |
| Exploit public | Vérifier Exploit-DB, GitHub PoC, articles techniques. Sinon "Non". |
| Exploité activement (KEV) | Présence catalogue CISA KEV = Oui. |
| Priorité retenue | Application stricte de la matrice §4.4 du plan (Oui KEV + CVSS ≥ 7 + Internet = P1, etc.). |
| Action décidée | Patch (montée de version) / Mitigation (workaround technique) / Monitoring (surveillance sans action immédiate) / Non applicable. |
| Ticket remédiation | Si action ≠ Non applicable, créer un ticket Jira de remédiation dédié, lié au ticket parent. |
| Échéance | Calculée à partir de la priorité : P1 = J+3, P2 = J+14, P3 = J+30, P4 = J+90. |
| Responsable | Tech Lead du produit concerné. |

Décisions hors-cycle (items déjà traités pendant le mois en KEV) : à reporter directement dans le rapport, ne nécessitent pas de nouvelle analyse.

## 4. Phase 4 — Rédaction du rapport (J → J+2)

Remplissage du template section par section. Le texte ci-dessous correspond aux sections du template tel qu'il est aujourd'hui.

### Métadonnées

Période couverte = du 1er au dernier jour du mois calendaire précédent (ou du mois en cours selon convention). Reste à confirmer la convention OneOrtho.

### 1. Résumé exécutif

Trois à cinq lignes structurées :

> Sur la période, N items ont été examinés depuis les sources §3.1 + §3.2 + §3.3.
> M items applicables OneSoftware ont été identifiés (P1 = a, P2 = b, P3 = c, P4 = d).
> Décisions clés : {{lister les 2 ou 3 actions les plus structurantes du mois}}.
> Tendance : {{stable / hausse / baisse}} par rapport au mois précédent.

Pour le premier rapport, l'élément "par rapport au mois précédent" est omis (rien à comparer).

### 2. Sources consultées

Cocher pour chaque ligne du tableau. Renseigner la date de dernière publication lue (issue de l'agrégateur RSS). Si une source n'a pas été consultée, expliquer le motif en colonne Remarques (ex : "Accès H-ISAC non encore activé").

Recommandation : **ne pas supprimer les lignes du template, même si une source n'a remonté aucun item ce mois**. La trace "consultée, 0 item" est elle-même la preuve d'audit que la veille a bien été tenue.

### 3. Items identifiés

#### 3.1 Synthèse chiffrée

Reprise simple des chiffres collectés en Phase 2 et 3. Pour le premier rapport, ces chiffres seront probablement élevés (rattrapage du backlog).

#### 3.2 Détail des items applicables

Un sous-tableau "Item N" par item P1/P2/P3. Pour les items P4, regroupement en liste simple suffit (pas de fiche détaillée nécessaire).

Pour le premier rapport, si la liste P1/P2 est longue (> 10 items), prévoir un découpage en annexe pour ne pas alourdir le rapport principal.

#### 3.3 Items non applicables (traçabilité)

Très important pour audit. Tout item collecté en Phase 2 mais écarté en Phase 3 doit y figurer avec son motif. Le but : démontrer que la veille a bien examiné l'item et que la décision "non applicable" est explicite, pas un oubli.

### 4. Tendances observées

Cinq à dix lignes. Pour le premier rapport, contenu attendu :

> Premier exercice de revue mensuelle Threat Intelligence pour OneOrtho. Constat initial : N composants identifiés par croisement SBOM × sources, dont M nécessitent une attention immédiate (P1/P2). Hétérogénéité de versions constatée sur certains frameworks et bibliothèques principaux (cf. §2.2 du plan), recommandation d'engager une convergence. {{Autres observations issues de la consolidation initiale}}.

### 5. Suivi des items des mois précédents

**Vide pour le premier rapport** (pas d'antériorité). Indiquer explicitement : "Premier exercice — sans objet pour ce mois".

### 6. Décisions et actions

Lister les décisions prises en Phase 3 sous forme actionnable, avec responsable et échéance. Recommandation : grouper par produit concerné pour faciliter le suivi par les Tech Leads.

### 7. Recommandations pour le mois suivant

Trois à cinq points concrets. Pour le premier rapport, recommandations attendues :

- compléter §2.2 du plan pour ajouter PHP et Composer aux composants explicitement nommés (cohérent avec le tableau §3.3),
- documenter les versions courantes et dates EOL des composants nommés en §2.2 (inventaire interne, non exposé dans le plan public),
- mettre en place l'agrégateur RSS si pas déjà fait,
- valider l'accès aux sources optionnelles (H-ISAC),
- ouvrir un ticket d'alignement de versions pour planifier la convergence des frameworks et bibliothèques principaux,
- compléter §3.3 du plan si des sources manquantes ont été identifiées en cours d'exercice,
- **planifier le déploiement de Dependency-Track** (instance self-hosted) en remplacement progressif de Snyk sur le volet SCA, afin de consommer en interne les SBOM CycloneDX déjà produits (souveraineté des données, audit trail contrôlé).

### 8. Export

Une fois le rapport validé, export PDF et dépôt SharePoint à l'URL indiquée dans le template.

## 5. Phase 5 — Validation et archivage (J+2)

| Action | Acteur | Livrable |
|--------|--------|----------|
| Relecture finale du rapport en DRAFT | DevSecOps | Rapport prêt à signer |
| Validation et signature | Responsable Numérique | Statut "Validé" en Confluence |
| Export PDF | DevSecOps | Fichier PDF nommé `Rapport mensuel - Revue Threat Intelligence - {{YYYY-MM}}.pdf` |
| Dépôt SharePoint | DevSecOps | Fichier visible dans le dossier cible |
| Notification équipe sur Slack #comité_technique | DevSecOps | Message diffusé avec lien Confluence |
| Clôture du ticket Jira parent | DevSecOps | Ticket en statut "Fait" |
| Archivage des pièces probantes (exports horodatés des sources, SBOM consultés) | DevSecOps | Sous-dossier `annexes/{{YYYY-MM}}/` |

## 6. Cas particulier du premier rapport

Le premier exercice diffère légèrement des suivants :

- **Backlog plus volumineux** que les mois suivants car premier examen complet du stack. Prévoir une session d'analyse plus longue (3 h au lieu de 1 h 30 à 2 h).
- **Section §5 vide** (pas d'antériorité). Garder la section avec mention explicite "premier exercice".
- **Découverte de sources manquantes ou indisponibles** : possible. Toutes notes à porter en §7 (Recommandations) pour traitement le mois suivant.
- **Calibrage des KPI** : le premier rapport établit la baseline. Les cibles du §6 du plan sont indicatives ; les valeurs réelles serviront de référence pour évaluer les mois suivants.

## 7. Erreurs fréquentes à éviter

| Erreur | Conséquence | Correction |
|--------|-------------|------------|
| Sauter §3.3 "Items non applicables" | Audit interprétera comme oubli de veille | Lister systématiquement les écartés avec motif |
| Cocher une source comme "consultée" sans la lire | Faux positif d'audit | Renseigner la date de dernière publication lue, qui est vérifiable |
| Mettre à jour le rapport après validation sans changelog | Perte de traçabilité | Créer un erratum daté plutôt que modifier en silence |
| Ne pas archiver les exports horodatés des sources | Pas de preuve probante | Sauvegarder systématiquement les exports CSV/JSON au moment de la consultation |
| Confondre "Non applicable" et "P4" | Tracking faussé | P4 = applicable mais faible criticité, traité plus tard. Non applicable = écarté définitivement. |

## 8. Outils recommandés pour faciliter l'exercice

- **Agrégateur RSS** : FreshRSS (auto-hébergé) ou Feedly pour centraliser les sources §3.
- **Snyk CLI** pour relancer un scan ad-hoc sur un lockfile ou un répertoire en dehors de la CI (mêmes résultats que les workflows GitHub Actions de production).
- **Syft** et **Trivy** en CLI pour générer un SBOM ad-hoc ou scanner une image / un répertoire avant la consolidation (mêmes outils que les workflows GitHub Actions, donc résultats reproductibles).
- **jq** pour filtrer rapidement les exports JSON CISA KEV et NVD.
- **Tableur** (Excel / Google Sheets) intermédiaire pour la phase de tri avant transfert dans le template.
