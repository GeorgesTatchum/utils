# Gabarits de tables pour la traçabilité Confluence

## Table 1 - Suivi décision

À produire pour CHAQUE analyse, qu'elle aboutisse à un fix ou à une exclusion.

| Champ | Valeur |
|---|---|
| Titre | <action concise : Fix / Exclure / Hybride - rule key - périmètre> |
| Priorité | Low / Medium / High |
| Quality Gate | Reliability / Security / Security Hotspot / Maintainability |
| Rules | <rule key> |
| Fichier impacté | <liste des fichiers + lignes si pertinent> |
| Analyse | <synthèse technique : que vérifie la règle, ce qu'on a trouvé dans le fichier, pourquoi c'est un vrai bug / faux positif / vendor> |
| Impact | <patient, fonction médicale, UX, MDR> |
| Solution Proposée | <fix précis OU exclusion avec emplacement précis (fichier .properties + numéro e/ex)> |
| Vérification préalable | <ce que le décideur doit vérifier avant merge : vendor confirmé, conformité WCAG non requise, etc.> |
| Critère d'acceptation | <condition mesurable de validation : issues absentes du QG, pas de régression visuelle, etc.> |
| Date enregistrement | <DD mois YYYY> |

## Table 2 - Registre d'exclusion

À produire UNIQUEMENT si la décision aboutit à une exclusion (pas de fix).
Si la décision est "fix", inscrire simplement : "Aucune entrée (décision = fix)".

| Champ | Valeur |
|---|---|
| # | e<N> pour `one-platform` / ex<N> pour `one-platform-js` |
| Rule key | <rule key Sonar> |
| Description | <ce que fait la règle en français, en une phrase> |
| Fichiers exclus | <pattern glob, ex `**/templates/**/*.twig` ou `assets/ext/**/*`> |
| Justification | <pourquoi cette règle est ignorable dans le contexte OneOrtho : raison technique + raison fonctionnelle> |
| Lien fonction médicale | Aucun / <à préciser> |
| Risque patient | Aucun / <à préciser> |
| Décideur | @XXX |
| Date | <DD mois YYYY> |
| Ticket associé | `<ticket Jira>` |

## Cas particulier : extension d'une entrée existante

Si une nouvelle issue tombe sous un pattern d'exclusion DÉJÀ enregistré (ex `assets/ext/**/*` couvre une nouvelle lib tierce), NE PAS créer une nouvelle entrée `ex<N>`. Mettre à jour l'entrée existante :
- Ajouter la nouvelle rule key dans la colonne `Rule key`
- Étendre la description et la justification
- Ajouter une mention "mise à jour DD mois YYYY" dans la colonne Date
