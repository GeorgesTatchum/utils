---
name: sonar-triage
description: Analyse une issue ou un hotspot SonarQube remonté sur un projet OneOrtho Medical (contexte MDR 2017/745, IEC 62304). Trie entre vrai bug, faux positif et code vendor, propose un fix ou une exclusion, et génère les deux tableaux de traçabilité (suivi décision + registre d'exclusion) prêts à coller dans Confluence. Déclenche dès que l'utilisateur fournit une rule key Sonar (ex Web:S5256, php:S2003, css:S4649, javascript:S5852) et un ou plusieurs fichiers concernés.
---

# Workflow

## 1. Parser l'input
L'utilisateur fournit :
- une rule key Sonar (ex `Web:MouseEventWithoutKeyboardEquivalentCheck`)
- un ou plusieurs chemins de fichiers
- éventuellement le nom du projet Sonar concerné (utile si le repo contient plusieurs `sonar-project*.properties`)

Si la rule key ou les fichiers manquent, demander avant d'aller plus loin.

## 2. Détecter le contexte du repo
Avant l'analyse :
- Identifier le ou les fichiers `sonar-project*.properties` à la racine du repo
- Lire chacun pour connaître son `sonar.projectKey`, son `sonar.sources` et ses exclusions/multicriteria déjà actifs
- Détecter le langage primaire du repo (PHP/Symfony, Node/React, Python, etc.) pour adapter les heuristiques
- Si plusieurs fichiers de config existent, mapper chaque chemin de fichier au bon projet Sonar :
  - les fichiers sous `sonar.sources` du projet backend -> config backend
  - les fichiers sous `sonar.sources` du projet frontend/assets -> config frontend

## 3. Inspecter les fichiers
Pour chaque fichier :
- Lire l'entête (détecter vendor : licence tierce, copyright externe, mention `bootstrap-*`, `jquery`, `ldBar`, etc.)
- Localiser les lignes incriminées via grep ciblé selon la nature de la règle
- Vérifier si le fichier est dans un dossier vendor connu (`assets/ext/`, `vendor/`, `node_modules/`, `third_party/`, `lib/external/`)
- Vérifier si c'est un partial Twig (préfixe `_`, présence de `extends`/`block`/`include` ailleurs)
- Vérifier si c'est un fichier auto-généré framework (Symfony Kernel.php, preload.php, Doctrine migrations, fichiers `*.generated.*`, etc.)

## 4. Catégoriser
Une issue tombe dans l'une de ces catégories :

| Catégorie | Critère | Action par défaut |
|---|---|---|
| Vrai bug | Code maintenu en interne, règle pertinente, fix court | Fixer |
| Faux positif framework | Code généré/imposé par le framework | Exclure règle sur fichier ciblé |
| Faux positif héritage template | Partial sans wrapper visible dans le fichier | Exclure règle sur pattern du dossier templates |
| Faux positif accessibilité | WCAG sur app non destinée aux utilisateurs assistifs | Exclure règle sur pattern templates |
| Vendor / SOUP | Code tiers dans dossier vendor identifié | Couvert par exclusion globale du dossier vendor |
| Mix | Plusieurs cas dans la même issue | Fix les vrais bugs + exclusion ciblée pour le reste |

## 5. Cibler le bon fichier de config
- Vérifier le `sonar.sources` de chaque `sonar-project*.properties` du repo
- Le chemin du fichier impacté détermine quel config modifier
- Si un seul fichier de config existe : pas d'ambiguïté
- Si plusieurs : préciser explicitement à l'utilisateur quel fichier sera modifié

## 6. Numérotation des entrées multicriteria
- Lire la chaîne `sonar.issue.ignore.multicriteria=...` existante avant de proposer un ajout
- Préfixe par défaut : `e<N>` pour les exclusions de règles
- Si le fichier de config est dédié aux assets/frontend, utiliser `ex<N>` pour distinguer (convention OneOrtho)
- Incrémenter à partir du dernier numéro utilisé
- Toujours mettre à jour la liste en tête de la chaîne `multicriteria=`

## 7. Produire la sortie
Toujours dans cet ordre :
1. **Verdict** en une phrase (fix / exclure / hybride)
2. **Analyse technique** de la règle (que vérifie-t-elle, pourquoi elle est pertinente ou pas)
3. **Détail par fichier** sous forme de tableau (ligne, déclaration, diagnostic, action)
4. **Modification proposée** du ou des fichiers `sonar-project*.properties` avec le numéro `e<N>` ou `ex<N>` suivant
5. **Table 1 - Suivi décision** complétée (voir `tables-template.md`)
6. **Table 2 - Registre d'exclusion** complétée ou note "aucune entrée (fix)" si décision = fix
7. **Question finale** : demander confirmation avant d'éditer les fichiers

## 8. Contexte conformité OneOrtho à rappeler quand pertinent
- Aucune donnée patient dans les exemples
- Risque patient à évaluer selon ISO 14971 (lien fonction médicale du dispositif ?)
- Code vendor = SOUP au sens IEC 62304 §8
- Justification d'exclusion documentée pour audit MDR 2017/745

## 9. Garde-fous
- Ne JAMAIS exclure du code maintenu en interne sans justification documentée -> toujours proposer le fix en priorité
- Ne JAMAIS proposer de fix qui altère la sémantique fonctionnelle sans demander confirmation
- Si la règle concerne du Security (pas Reliability/Maintainability), être plus conservateur : la décision par défaut est "à investiguer" plutôt que "exclure"
- Toujours rappeler l'ordre : fixer les vrais bugs AVANT d'ajouter l'exclusion (sinon le bug est masqué)
- Si plusieurs occurrences de la même règle sont sur des fichiers distincts avec contextes différents, traiter chaque contexte séparément
- Adapter le vocabulaire au langage du projet (Twig partial / React component / Jinja template / etc.)

## 10. Format des tables
Voir `tables-template.md` pour les en-têtes exacts à respecter.

## 11. Date et décideur
- Date par défaut : date du jour au format `DD mois YYYY` (ex `13 mai 2026`)
- Décideur par défaut : `@XXX` (à compléter par l'utilisateur)
- Ticket Jira : `<ticket Jira>` placeholder si non fourni

## 12. Si le repo n'est pas un projet Sonar reconnaissable
Si aucun `sonar-project*.properties` n'est trouvé à la racine :
- Signaler à l'utilisateur
- Demander où est configuré Sonar (CI/CD inline, autre fichier, etc.)
- Adapter en conséquence ou s'arrêter si l'info n'est pas fournie
