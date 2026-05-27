# Item hors-cycle — définition et mécanisme

Document explicatif rattaché au plan de revue mensuelle Threat Intelligence (`plan_revue_mensuel_v2.md` §4.0bis).

## 1. Définition

"Hors-cycle" = vocabulaire de **cadence**, pas de criticité. Le "cycle" est le rythme normal du plan (consolidation 1er jeudi du mois + mise à jour J+15). Un item hors-cycle est un item qui ne peut **pas attendre la prochaine consolidation mensuelle** pour être traité.

## 2. Différence cycle normal vs hors-cycle

| Aspect | Cycle normal | Hors-cycle |
|--------|--------------|------------|
| Quand l'item arrive ? | À n'importe quel moment du mois | À n'importe quel moment du mois |
| Quand il est traité ? | Versé à `SEC-INBOX`, **examiné à la prochaine consolidation** (1er jeudi suivant) | **Traité immédiatement**, sans attendre la consolidation |
| Délai de prise en charge | Inscription au backlog, analyse à la consolidation (jusqu'à 30 j d'écart possible) | **24 h ouvrées** pour l'analyse d'applicabilité (§4.0bis) |
| Où il apparaît dans le rapport ? | Section §3 "Items identifiés ce mois" du rapport en cours de rédaction | Section dédiée "Items hors-cycle (0-day)" du rapport du mois en cours, **insérée même si le rapport est déjà VALIDATED** (mise à jour J+15) |
| Communication & transmission | Suivent les règles §4.9 et §4.8 normales | Mêmes règles, mais avec délais accélérés (transmission §4.8 vers Affaires Réglementaires ≤ 48 h si DM impacté) |

## 3. Conditions de déclenchement (§4.0bis)

Un item bascule en hors-cycle dès qu'**une seule** des conditions suivantes est remplie :

- ajout d'une CVE applicable au catalogue **CISA KEV** avec exploitation active confirmée,
- publication d'un advisory **CRITIQUE** par CERT-FR / CERT Santé (ANS) / CISA ICS Medical sur un composant présent dans le SBOM,
- alerte Trivy / Syft / Dependabot d'un **CVSS ≥ 9** sur composant en production.

Ces trois critères ont en commun qu'ils signalent une exposition **active** ou **immédiate**. Attendre 30 jours serait imprudent.

## 4. Exemples

| Situation | Hors-cycle ? | Justification |
|-----------|--------------|---------------|
| On est le 8 mai. CVE Symfony 9.1 ajoutée à KEV hier, exploitée. | **Oui** | Trois semaines d'attente jusqu'au 1er jeudi de juin = inacceptable. Déclenchement §4.0bis, SLA analyse 24 h. |
| On est le 28 mai. CVE Three.js 7.8, pas dans KEV, advisory routine. | Non | Sera traitée naturellement à la consolidation du 1er jeudi de juin, dans une semaine. |
| On est le 12 juin. CVE Windows Server 2016 critique KEV, héberge la prod. | **Oui** | Composant en production exposé internet, criticité maximale. Déclenchement §4.0bis. |
| Le rapport de mai est déjà VALIDATED le 8 mai. Le 20 mai, KEV ajoute une CVE Angular 9.0. | **Oui** | Item inscrit en "Items hors-cycle" du rapport de mai, ajouté lors de la mise à jour J+15 (3e jeudi de mai). Rapport bascule de VALIDATED vers PUBLISHED après cette mise à jour. |
| Le 1er juin, CVE TinyMCE 7.5 pas dans KEV, exposée internet via portail. | Non | C'est un P2 par la matrice §4.4 (KEV = Non). Versée à SEC-INBOX, traitée à la prochaine consolidation. |

## 5. Conséquences procédurales du hors-cycle

1. **Ouverture immédiate** d'un ticket Jira P1 (la quasi-totalité des hors-cycle finissent en P1 car KEV + exploitation = P1 par la matrice §4.4).
2. **Analyse d'applicabilité sous 24 h** (croisement SBOM Syft, test sur staging).
3. **Décision de remédiation** dans les 24 h suivantes si applicable.
4. **Communication commerciale** (§4.9) déclenchée selon impact client.
5. **Transmission §4.8** vers le pôle Affaires Réglementaires sous 48 h si l'item affecte un DM (directement ou par effet de bord).
6. **Inscription dans le rapport mensuel en cours** dans une section dédiée "Items hors-cycle", **distincte** de la section §3 des items issus de la cadence normale. Cette distinction sert à l'audit cyber : un auditeur doit pouvoir voir, par mois, combien d'items ont rompu la cadence normale et pourquoi.
7. **KPI dédié** : "Délai moyen prise en charge 0-day" cible < 24 h, suivi dans §6 du plan.

## 6. Synthèse

Hors-cycle ≠ P1. Un item peut être P1 et rester dans le cycle (détecté en début de mois, traité à la consolidation à venir dans quelques jours). Un item peut être hors-cycle et finir P2 (rare mais possible : un advisory critique CERT-FR qui à l'analyse se révèle non exploitable). Le hors-cycle est un **mécanisme de rupture de cadence**, pas une catégorie de criticité.

C'est précisément cette distinction qui justifie le maintien d'un suivi hebdomadaire CI/CD (§4.0) en parallèle de la consolidation mensuelle : sans veille hebdo, on raterait les déclencheurs hors-cycle entre deux consolidations.
