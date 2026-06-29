# Template — Ticket Jira de remédiation Threat Intelligence

Modèle à utiliser pour créer les tickets de remédiation issus de la revue mensuelle Threat Intelligence (plan §4.5).

Règles :
- Un ticket par item applicable **P1/P2/P3**.
- Les items **P4** peuvent être regroupés en un seul ticket « lot P4 ».
- Les items **groupés** (MSRC Patch Tuesday, parc MariaDB) = un seul ticket couvrant le lot.
- Les items **non applicables** ne génèrent **pas** de ticket (la trace §3.3 du rapport suffit).
- Les items **à investiguer** = un ticket **Spike** d'investigation ; s'il conclut « non applicable », on clôt le Spike sans créer de ticket de remédiation.

> Le type d'issue et le mapping de priorité ci-dessous sont une proposition par défaut, à ajuster selon la configuration réelle du projet Jira OneOrtho.

## Conventions

| Champ | Convention |
|-------|------------|
| Projet | CICD (ou projet sécurité dédié) |
| Type d'issue | Sous-tâche de `SEC-THREATINTEL-<YYYY-MM>` (ticket de revue mensuelle, sous `CICD-161`). Si Jira impose un type plat : « Task » + lien « relates to » |
| Lien | `is part of` / `relates to` → `SEC-THREATINTEL-<YYYY-MM>` (ex. CICD-169 pour mai 2026) |
| Assigné à | Tech Lead du composant (Symfony / Angular) ou DevSecOps + équipe infrastructure (Windows Server, MariaDB) |
| Priorité Jira | P1 → Highest · P2 → High · P3 → Medium · P4 → Low |
| Échéance (Due date) | SLA matrice §4.4 : P1 = J+3 · P2 = J+14 · P3 = J+30 · P4 = J+90 (J = date de revue) |
| Étiquettes | `threat-intel`, `sec-<YYYY-MM>`, `<composant>` (`symfony`, `angular`, `windows-server`, `mariadb`, `php`), `<produit>` (`onesoftware`, `plannerhip2d`…) |

## Format du résumé (summary)

```
[SEC][P{n}][{Composant}] {CVE/GHSA} — {action courte} (Threat Intel {YYYY-MM})
```

## Champs du ticket (4 champs Jira)

Reporter chaque bloc dans le champ Jira correspondant.

### Description
```
Item issu de la revue mensuelle Threat Intelligence {{YYYY-MM}} (rapport Confluence : {{lien}}).
Source : {{source primaire}}.
Vulnérabilité : {{CVE / GHSA}} — {{intitulé}} ({{lien advisory}}). CVSS : {{score ou "non communiqué"}}.

Action attendue : {{patch — montée de {{composant}} de {{version actuelle}} vers {{version cible}} / mitigation / configuration}}.

Critères d'acceptation (Definition of Done) :
* [ ] Version corrigée déployée (staging puis production)
* [ ] Tests de non-régression OK ({{Behat / Cypress / Karma}})
* [ ] SBOM régénéré reflétant la version corrigée (artefact CI joint)
* [ ] Sortie scanner (Snyk / Trivy / Dependabot) confirmant la disparition de l'alerte
* [ ] Ticket lié à {{SEC-THREATINTEL-YYYY-MM}}

Traçabilité : rapport mensuel {{lien Confluence}} — décision §6 ligne {{#}}.
```

### Environnement
```
* Composant impacté : {{nom + version actuelle (croisement composer.lock / package.json / parc)}}
* Produit(s) concerné(s) : {{Portail Symfony / plannerXxx / Infrastructure}}
* Exposition : {{Internet / Interne / Hors ligne}}
* {{si infra/DB : préciser le parc — versions, nombre d'instances, OS}}
```

### Analyse du bug

Structure imposée par le mode opératoire OneOrtho (méthode des « 5 pourquoi » / analyse de cause racine, 6 points). Adaptation pour une vulnérabilité tierce : « le bug » est la faille du composant amont (SOUP), pas un défaut du code OneOrtho — la chaîne de causes porte sur l'exposition via la dépendance et la latence de mise à jour. Ne pas fabriquer de cause « erreur humaine » interne pour une CVE amont. Points 4 et 5 facultatifs.

```
1. Que s'est-il passé dans le code ?
{{Mécanisme technique de la faille dans le composant tiers {{composant}} {{version}}, d'après l'advisory. Seul champ où le détail technique est exposé. Préciser : code du composant amont, non du code OneOrtho.}}

2. Pourquoi le bug s'est-il produit ?
Vulnérabilité publiée dans le composant tiers {{composant}} (SOUP au sens IEC 62304 §9), réf. {{CVE/GHSA}} ({{advisory}}). Ni correction ni fonctionnalité OneOrtho : faille amont. OneOrtho est concerné car le composant est embarqué comme dépendance.

3. Pourquoi cette cause s'est-elle produite ?
La version déployée ({{version}}) est antérieure à la version corrigée ({{version cible}}) ; composant utilisé par {{produit}}, exposition {{Internet/Interne}}. Dépendance SOUP non encore mise à jour.

4. Pourquoi la cause profonde s'est-elle produite ? (Facultatif)
{{Latence de mise à jour : cadence de patch des dépendances, fenêtre de maintenance, automatisation de montée de version absente/partielle.}}

5. Pourquoi la cause fondamentale s'est-elle produite ? (Facultatif)
{{Facteurs organisationnels : maturité de la gestion des SOUP, veille/SBOM récemment instaurés, priorisation, convergence des versions.}}

6. Analyse finale
{{Cause fondamentale (faille tierce + latence de patch) + impact (C/I/D, effet de bord DM éventuel) + recommandations : montée de version, automatisation Dependabot/Snyk, convergence des versions, SBOM. Si non réalisable, analyse à transférer à l'équipe qualité.}}
```

### Raison du blocage/décision
```
* Priorité retenue : P{{n}} — matrice §4.4 : KEV {{oui/non}} + CVSS {{≥7 / <7}} + exposition {{internet/interne}}. SLA {{J+3 / J+14 / J+30 / J+90}}.
* Décision particulière : {{ex. accélération malgré P3 vu CVSS élevé ; reclassement conditionnel P2 si exposition confirmée ; requalification P1 si ajout KEV}}.
* Dépendances / blocages : {{version cible à confirmer ; correctif par branche ; fenêtre de maintenance ; attente investigation}}.
```

## Variante — ticket d'investigation (Spike)

Mêmes 4 champs. « Analyse du bug » cadre l'incertitude d'applicabilité ; « Raison du blocage/décision » explique pourquoi on investigue avant de remédier.

```
Résumé : [SEC][Investigation][{Composant}] {CVE} — confirmer applicabilité (Threat Intel {YYYY-MM})
Type : Spike / Investigation

Description :
  Question : {{la brique/le composant X est-il utilisé en production ?}}
  Méthode : {{grep code, vérif config, retour Tech Lead}}
  Sortie : applicable (→ créer ticket remédiation P{n}) OU non applicable (→ §3.3, clore sans remédiation)

Raison du blocage/décision :
  Applicabilité non confirmée → investigation bloquante avant tout ticket de remédiation. {{priorité de l'éventuel ticket + facteur d'urgence ex. KEV}}.
```
