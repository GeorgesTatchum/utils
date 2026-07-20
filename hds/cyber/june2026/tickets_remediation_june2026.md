# Tickets de remédiation - Threat Intelligence juin 2026

Brouillon à coller dans Jira (pas une création automatique). Dérivé du rapport `rapport_threat_intel_june2026.md` (items §3.2 + décisions §6). Format : `jira-ticket-template.md`.

| Champ | Valeur |
|-------|--------|
| Période | 01/06/2026 au 30/06/2026 |
| Ticket parent | SEC-THREATINTEL-2026-06 (CICD-170, sous CICD-161) |
| Date de revue | 06/07/2026 (échéances : P2 = 20/07, P3 = 05/08, P4 = 04/10/2026) |
| Rapport source | Confluence CyberSécurité > PSSI > Threat Intelligence, `2026-06 Revue Threat Intelligence` |

## Sommaire

| # | Résumé | Priorité | Responsable | Échéance |
|---|--------|----------|-------------|----------|
| T1 | Montée Angular Hip3D + KneeMadison (XSS + DoS) | P2 | Tech Lead Angular | 20/07/2026 |
| T2 | Montée tinymce one-platform (3 XSS) | P2 | Tech Lead one-platform | 20/07/2026 |
| T3 | Montée d'hygiène mathjs plannerHip3D (non exploitable) | P4 | Tech Lead Angular | 04/10/2026 |
| T4 | Patch Tuesday Windows Server 09/06 (Critique + Important) | P2 | DevSecOps + infra | 20/07/2026 |
| T5 | Montée Node.js ligne 22 + GLOBALD Node 16 EOL | P4 | DevSecOps + infra | 04/10/2026 |
| T6 | lodash overrides 4.18.1 (3 repos) | P4 | Tech Leads one-platform + Angular | 04/10/2026 |
| T7 | Lot build SCA one-platform | P4 | Tech Lead one-platform | 04/10/2026 |
| T8 | Lot build SCA modules Angular | P4 | Tech Lead Angular | 04/10/2026 |
| T9 (Spike) | Confirmer version PHP déployée (uriparser) | Spike | DevSecOps | 05/08/2026 |

Pas de ticket pour : items non applicables (§3.3), MariaDB (report de mai, ticket déjà ouvert en décision mai #7, suivi §5), rattrapages de sources (CISA ICS fait ; Snyk = action process décision §6 #9, pas un ticket de remédiation).

---

## T1 - [SEC][P2][Angular] CVE-2026-50557 + CVE-2026-54265 + CVE-2026-54268 - montée Hip3D + KneeMadison (Threat Intel 2026-06)

### Description
Items issus de la revue mensuelle Threat Intelligence 2026-06 (rapport Confluence). Source : Angular Security Advisories.
Vulnérabilités (un seul plan de remédiation, montée de version) :
* CVE-2026-50557 (GHSA-f3m7-gqxr-g87x) - Template/Attribute Namespace Sanitization Bypass (XSS), CVSS 5.3, `@angular/compiler` + `@angular/core`.
* CVE-2026-54265 (GHSA-58w9-8g37-x9v5) - Two-Way Property Binding Sanitization Bypass (XSS), CVSS 5.3, `@angular/compiler`.
* CVE-2026-54268 (GHSA-48r7-hpm6-gfxm) - DoS via OOM dans formatDate, CVSS 8.2, `@angular/common`.

Action attendue : monter plannerHip3D de 20.3.16 vers 20.3.25 et plannerKneeMadison de 21.2.5 vers 21.2.17 (correctifs cumulatifs, couvrent les 3 CVE + la dette Angular runtime accumulée : CVE-2026-50170/50171/52725/22610/27970/32635, CVE-2025-66412). plannerHip2D (21.2.17) et plannerShoulder3D (22.0.4) déjà corrigés, hors périmètre de ce ticket.

Critères d'acceptation :
* [ ] Hip3D en 20.3.25, KneeMadison en 21.2.17 (staging puis production)
* [ ] Audit des patterns de liaison bidirectionnelle et de rendu de templates avant/après patch (CVE-2026-54265, 50557)
* [ ] Tests de non-régression OK (Karma / Cypress)
* [ ] Dependabot ne remonte plus ces CVE sur les 2 modules
* [ ] SBOM régénéré, ticket lié à SEC-THREATINTEL-2026-06

Traçabilité : rapport §3.2 Items 1-3, décision §6 ligne 1.

### Environnement
* Composant impacté : `@angular/core` / `@angular/compiler` / `@angular/common` - Hip3D 20.3.16, KneeMadison 21.2.5 (versions installées lockfile)
* Produit(s) concerné(s) : planificateurs Angular Hip3D et KneeMadison
* Exposition : Internet (modules livrés au navigateur client)
* Non affectés : Hip2D (21.2.17), Shoulder3D (22.0.4)

### Analyse du bug
1. Que s'est-il passé dans le code ? Failles dans `@angular/compiler`/`@angular/core`/`@angular/common` : contournement du sanitizer DOM via namespaces de template/attribut (50557) et liaison bidirectionnelle (54265) permettant du XSS ; absence de borne sur le format de `formatDate` permettant un DoS par OOM (54268). Code des composants amont Angular, non du code OneOrtho.
2. Pourquoi le bug s'est-il produit ? Vulnérabilités publiées dans Angular (SOUP, IEC 62304 §9), réf. CVE-2026-50557 / 54265 / 54268. OneOrtho est concerné car Angular est embarqué dans les planificateurs.
3. Pourquoi cette cause s'est-elle produite ? Hip3D (20.3.16) et KneeMadison (21.2.5) sont antérieurs aux versions corrigées (20.3.25 / 21.2.17) ; modules exposés navigateur.
4. Cause profonde (facultatif) : hétérogénéité des versions Angular entre modules (20.3 / 21.2 / 22.0) et montée non encore appliquée sur ces 2 modules.
6. Analyse finale : faille tierce + latence de patch. Impact : XSS (C/I) côté client, DoS (D). Remédiation = montée unique par module ; poursuivre la convergence de versions (ARCH-VERSIONS-CONVERGENCE) et l'automatisation Dependabot.

### Raison du blocage/décision
* Priorité retenue : P2 - matrice §4.4. Les 2 XSS (CVSS 5.3) sont classés P2 par continuité (XSS à exposition internet) ; le DoS formatDate (CVSS 8.2) est P3 (DoS côté client). Le ticket groupé prend le plus haut (P2), SLA J+14.
* Décision particulière : classification XSS = P2 malgré CVSS modéré (voir recommandation §7 de clarification de la matrice).
* Dépendances : montée mineure Angular, à valider sur staging.

---

## T2 - [SEC][P2][one-platform] CVE-2026-47759 + CVE-2026-47761 + CVE-2026-47762 - montée tinymce (Threat Intel 2026-06)

### Description
Item issu de la revue Threat Intelligence 2026-06. Source : GitHub Dependabot (repo one-platform) ; GHSA-q742-qvgc-gc2f, GHSA-vg35-5wq7-3x7w, GHSA-v98h-vmpc-fpqv.
Vulnérabilités : 3 XSS TinyMCE (attributs data-mce-, plugin media, commentaires mce:protected), CVSS ~8.3 (AV:N/AC:L/PR:L/UI:R/S:C/C:H/I:H). Corrigé en 7.9.3 / 8.5.1 (5.11.1 pour CVE-2026-47759).

Action attendue : monter tinymce vers >= 7.9.3 (ou 8.5.1) sur one-platform. Confirmer d'abord la version installée (repo one-platform non disponible localement lors de la revue).

Critères d'acceptation :
* [ ] Version tinymce >= 7.9.3 déployée (staging puis production)
* [ ] Tests de non-régression de l'éditeur riche OK
* [ ] Dependabot ne remonte plus ces 3 GHSA
* [ ] Ticket lié à SEC-THREATINTEL-2026-06

Traçabilité : rapport §3.2 Item 6a, décision §6 ligne 4.

### Environnement
* Composant impacté : tinymce (éditeur riche livré au navigateur), version à confirmer
* Produit(s) concerné(s) : one-platform (frontend portail)
* Exposition : Internet

### Analyse du bug
1. Que s'est-il passé dans le code ? XSS dans TinyMCE via attributs `data-mce-` (src/href/style), plugin media (`data-mce-object`) et commentaires `mce:protected`, permettant l'injection de script. Code du composant amont TinyMCE.
2. Pourquoi le bug s'est-il produit ? Vulnérabilités publiées dans TinyMCE (SOUP), CVE-2026-47759/47761/47762. OneOrtho concerné car TinyMCE embarqué dans one-platform.
3. Pourquoi cette cause s'est-elle produite ? Version TinyMCE déployée antérieure à 7.9.3 ; éditeur exposé sur le portail.
6. Analyse finale : faille tierce + latence de patch. Impact XSS (C/I) sur le portail. Remédiation = montée TinyMCE ; ajouter au suivi SCA.

### Raison du blocage/décision
* Priorité retenue : P2 - XSS à exposition internet, non KEV. SLA J+14.
* Dépendances : confirmer la version installée sur one-platform (repo à récupérer).

---

## T3 - [SEC][P4][Angular] CVE-2026-40897 + CVE-2026-41139 - montée d'hygiène mathjs plannerHip3D (Threat Intel 2026-06)

### Description
Item issu de la revue Threat Intelligence 2026-06, **investigation conclue le 17/07/2026 : non exploitable dans l'usage actuel**. Source : GitHub Dependabot (plannerHip3D) ; GHSA-29qv-4j9f-fjw5, GHSA-jvff-x2qm-6286.
Vulnérabilités : CWE-915 dans le parseur d'expressions mathjs (CVE-2026-40897 setter d'attribut non sûr, CVE-2026-41139 getter d'index non sûr), CVSS ~8.8. Plage affectée 13.1.1 à <15.2.0, corrigé 15.2.0.

Action attendue : `npm install mathjs@^15.2.0` (15.1.1 → >= 15.2.0) dans plannerHip3D pour sortir de la plage affectée et solder le finding SCA. Vérifier présence/version dans KneeMadison et Shoulder3D. **Montée d'hygiène, pas de correction d'un risque exploitable.**

Critères d'acceptation :
* [ ] mathjs >= 15.2.0 dans Hip3D (staging puis production)
* [ ] Vérification de la présence de mathjs dans les autres modules
* [ ] Tests de non-régression du slicing NIfTI (utils-slicer.ts / nifti-slicer.ts) OK
* [ ] Dependabot / SCA ne remontent plus ces GHSA
* [ ] Ticket lié à SEC-THREATINTEL-2026-06

Traçabilité : rapport §3.2 Item 6b, décision §6 ligne 5.

### Environnement
* Composant impacté : mathjs 15.1.1 (dépendance runtime directe, importée dans `nifti-slicer.ts` et `utils-slicer.ts`)
* Produit(s) concerné(s) : plannerHip3D
* Exposition : Internet (module navigateur) mais chemin vulnérable non atteint (voir Analyse). Non exploitable dans l'usage actuel

### Analyse du bug
1. Que s'est-il passé dans le code ? CWE-915 dans le parseur d'expressions mathjs : setter d'attribut d'objet non sûr (40897) et getter d'index de tableau non sûr (41139). Précondition explicite (avis éditeur) : l'application doit évaluer des expressions arbitraires via `math.evaluate/parse/compile/Parser`. Code du composant amont mathjs.
2. Pourquoi le bug s'est-il produit ? Vulnérabilités publiées dans mathjs (SOUP), CVE-2026-40897/41139. mathjs est embarqué dans Hip3D.
3. Pourquoi cette cause s'est-elle produite ? mathjs 15.1.1 dans la plage affectée (13.1.1 à <15.2.0).
4. Cause profonde : investigation dépôt (17/07/2026) : 0 occurrence des API de parseur (`grep evaluate|parse|compile|parser|rationalize|derivative|simplify` hors node_modules) ; mathjs n'est utilisé qu'en algèbre linéaire numérique (subtract, divide, norm, cross, matrix, multiply, transpose, dot). Le flux NIfTI n'atteint mathjs que comme opérandes numériques, jamais comme chaîne d'expression → CWE-915 non déclenchable.
6. Analyse finale : faille tierce présente mais **chemin vulnérable non exercé** → non exploitable dans l'usage actuel. Montée effectuée par hygiène (solder le finding SCA + traçabilité MDR / IEC 62304), pas pour corriger un risque actif. Requalifier vers le haut uniquement si un usage du parseur mathjs est introduit.

### Raison du blocage/décision
* Priorité retenue : P4 - non exploitable (parseur non utilisé), montée d'hygiène. Requalifié de P2 après investigation du chemin de code. SLA J+90.
* Décision particulière : conclusion d'investigation tracée (auteur : investigation dépôt, 17/07/2026). Ne pas bloquer sur ce finding ; le solder au prochain cycle de montée.

---

## T4 - [SEC][P2][Windows Server] Patch Tuesday 09/06/2026 (13 Critiques + 96 Important) - solder les 3 serveurs résiduels (Threat Intel 2026-06)

### Description
Items issus de la revue Threat Intelligence 2026-06. Source : Microsoft MSRC Security Update Guide (`msrc_june2026.csv`).
Vulnérabilités (Patch Tuesday 09/06/2026, périmètre Windows Server/IIS/.NET, remédiation par rouleau cumulatif unique) :
* 13 CVE Critiques (12 RCE + 1 EoP), dont CVE-2026-47291 (Windows HTTP.sys, RCE, composant noyau derrière IIS, exposé internet).
* 96 CVE Important (EoP / InfoDisc / SFB / DoS / RCE).
Aucune en KEV. Builds de référence juin : WS2022 20348.5256, WS2025 26100.32995, WS2016 14393.9234.

Action attendue : porter les 3 serveurs résiduels au build de juin (les 16 autres sont déjà à jour) :
* WEBPRODDEDIENNE (WS2025) : 26100.32860 (build de mai) → 26100.32995
* WEBPRODGLOBALD (WS2016) : 14393.8330 → 14393.9234
* WEBPRODI2B (WS2016) : 14393.3474 → 14393.9234

Critères d'acceptation :
* [ ] 3 serveurs résiduels au build de juin (validation post-patch staging puis prod)
* [ ] Vérification `CurrentBuild.UBR` >= build de juin sur les 19 serveurs
* [ ] Ticket lié à SEC-THREATINTEL-2026-06

Traçabilité : rapport §3.2 Items 4 et 5, décisions §6 lignes 2, 3 et 12 ; §5 (Patch Tuesday mai fait 17/19).

### Environnement
* Composant impacté : Windows Server 2016/2019/2022/2025 + .NET / ASP.NET Core
* Produit(s) concerné(s) : Infrastructure d'exécution (OS hôte du portail Symfony + IIS)
* Exposition : Internet pour le volet Critique (HTTP.sys derrière IIS) ; Interne pour la majorité du volet Important (accès local requis)
* Parc : 19 serveurs (11 WS2022, 4 WS2025, 4 WS2016) ; 16/19 déjà au build de juin au 06/07/2026

### Analyse du bug
1. Que s'est-il passé dans le code ? Ensemble de failles OS Windows Server du Patch Tuesday de juin (RCE HTTP.sys/Win32K/Hyper-V/Kernel/Kerberos..., EoP, etc.). Code Microsoft, non OneOrtho.
2. Pourquoi le bug s'est-il produit ? Vulnérabilités publiées par Microsoft (SOUP infrastructure). OneOrtho concerné car les serveurs hébergent le portail et IIS.
3. Pourquoi cette cause s'est-elle produite ? 3 serveurs sont restés sous le build du Patch Tuesday de juin (l'un au build de mai malgré un statut « patché » dans l'inventaire ; deux planifiés).
4. Cause profonde (facultatif) : le « build cible » de l'inventaire suivait le Patch Tuesday de mai ; risque de confondre « patché (mai) » et « à jour (juin) ».
6. Analyse finale : faille amont OS + latence/cadence de patch. Remédiation = rouleau cumulatif ; clarifier le suivi de conformité par rapport au build du mois courant (recommandation §7).

### Raison du blocage/décision
* Priorité retenue : P2 (volet Critique, exposition internet, non KEV, SLA J+14) ; le volet Important est P3 (SLA J+30) mais soldé par le même rouleau. Ticket groupé : priorité dominante P2.
* Décision particulière : le risque résiduel se limite à 3 serveurs ; prioriser CVE-2026-47291 (HTTP.sys) et WEBPRODDEDIENNE (prod exposée).
* Dépendances : fenêtre de maintenance par serveur.

---

## T5 - [SEC][P4][Node.js] Node.js Security Release 18/06/2026 - montée ligne 22 + GLOBALD Node 16 EOL (Threat Intel 2026-06)

### Description
Item issu de la revue Threat Intelligence 2026-06. Source : Node.js Security ; recoupé CERT-FR AVI-0786 (18/06).
Vulnérabilités : batch du 18/06, 12 CVE (WebCrypto, TLS, HTTP/2, permission model), dont 2 High (CVE-2026-48933 WebCrypto, CVE-2026-48618 TLS hostname). Correctifs : ligne 22 → 22.23.0, ligne 24 → 24.17.0, ligne 26 → 26.3.1.

Action attendue :
* Monter la ligne 22 vers >= 22.23.0 sur les 14 instances concernées (22.13.0 à 22.21.0) - hygiène + déblocage scanners CI.
* Point d'attention hors batch : GLOBALD prod en Node 16.13.2 (EOL, fin de support) à traiter en priorité ; SAAS preprod en Node 20.19.5 à aligner.

Critères d'acceptation :
* [ ] Node ligne 22 >= 22.23.0 sur les 14 instances
* [ ] GLOBALD prod sorti de Node 16 (version supportée)
* [ ] Ticket lié à SEC-THREATINTEL-2026-06

Traçabilité : rapport §3.2 Item 7, décision §6 ligne 7.

### Environnement
* Composant impacté : runtime Node.js présent sur les serveurs (build/déploiement). 14 instances ligne 22.x < 22.23.0 ; 1 instance Node 16.13.2 (GLOBALD, EOL) ; 1 instance Node 20.19.5 (SAAS preprod, hors batch)
* Produit(s) concerné(s) : Infrastructure (serveurs web)
* Exposition : Hors ligne (build). Node ne sert qu'à `npm run build` des modules Angular (bundle ensuite servi par Symfony/IIS) : aucun service réseau, exploitation réelle quasi nulle

### Analyse du bug
1. Que s'est-il passé dans le code ? Failles Node.js (WebCrypto, validation d'hôte TLS, HTTP/2, modèle de permissions). Code amont Node.js.
2. Pourquoi le bug s'est-il produit ? Vulnérabilités publiées par le projet Node.js (SOUP). OneOrtho concerné car Node est installé sur les serveurs (chaîne de build).
3. Pourquoi cette cause s'est-elle produite ? Instances ligne 22 antérieures à 22.23.0 ; un serveur en Node 16 EOL.
6. Analyse finale : faille amont, mais exposition hors ligne (usage build-only) : risque réel faible, priorité P4. Enjeu = hygiène + scanners CI + sortie de Node 16 EOL (supply-chain). Requalifier vers le haut uniquement si un service réseau Node apparaît.

### Raison du blocage/décision
* Priorité retenue : P4 - exposition hors ligne (build), non KEV. La matrice donnerait nominalement P3 pour les 2 CVE High, mais l'usage build-only sans entrée externe justifie P4 (aligné sur le volet build). SLA J+90.
* Décision particulière : GLOBALD (Node 16 EOL) à anticiper hors SLA du batch.

---

## T6 - [SEC][P4][SCA] CVE-2026-4800 + CVE-2026-2950 - lodash overrides 4.18.1 (Threat Intel 2026-06)

### Description
Item issu de la revue Threat Intelligence 2026-06 (investigation conclue). Source : GitHub Dependabot ; GHSA-r5fr-rjxr-66jc, GHSA-f23m-r3pf-42rh.
Vulnérabilités : CVE-2026-4800 (code injection via `_.template`, CVSS 8.1), CVE-2026-2950 (prototype pollution `_.unset`/`_.omit`, CVSS 6.5). Affecté 4.0.0 à 4.17.23 (résolu actuel 4.17.23), corrigé 4.18.0.

Action attendue : forcer lodash 4.18.1 (tag latest) via un bloc `overrides` npm dans chaque repo concerné (one-platform, plannerHip3D, plannerKneeMadison). **Ne pas** `npm audit fix --force` (rétrograderait jshint en 0.5.9, cassant). CI = npm, pas de yarn.lock → `overrides` est le bon mécanisme.

Critères d'acceptation :
* [ ] Bloc `overrides` lodash 4.18.1 dans les 3 repos, `npm install` reproductible
* [ ] Dependabot ne remonte plus 4800/2950
* [ ] Build front OK (jshint non rétrogradé)
* [ ] Ticket lié à SEC-THREATINTEL-2026-06

Traçabilité : rapport §3.2 Item 6c, décision §6 ligne 13.

### Environnement
* Composant impacté : lodash 4.17.23 - **dépendance dev transitive** (jshint, chaîne @symfony/webpack-encore), toutes entrées `dev:true`. Repos : one-platform, plannerHip3D, plannerKneeMadison
* Produit(s) concerné(s) : chaîne de build (jamais dans le bundle de production)
* Exposition : Hors ligne (build). Aucun appel `_.template`/`_.unset`/`_.omit` du pipeline sur des données externes

### Analyse du bug
1. Que s'est-il passé dans le code ? Code injection via clés d'imports de `_.template` et prototype pollution via `_.unset`/`_.omit`. Code amont lodash.
2. Pourquoi le bug s'est-il produit ? Vulnérabilités publiées dans lodash (SOUP), tirées transitivement par l'outillage de build.
3. Pourquoi cette cause s'est-elle produite ? Version transitive résolue (4.17.23) antérieure à 4.18.0.
6. Analyse finale : faille amont en dépendance de build ; exposition hors ligne, exploitation réelle quasi nulle. Enjeu = déblocage des scanners CI (Snyk/Trivy/Dependency-Track). Remédiation propre = `overrides`.

### Raison du blocage/décision
* Priorité retenue : P4 - dépendance dev, exposition hors ligne, non KEV. SLA J+90.
* Décision particulière : investigation « à investiguer » close (dev-only confirmé par lockfile) ; correctif par `overrides`, surtout pas `audit fix --force`.

---

## T7 - [SEC][P4][SCA one-platform] Lot chaîne de build one-platform (42 alertes) (Threat Intel 2026-06)

### Description
Item issu de la revue Threat Intelligence 2026-06. Source : GitHub Dependabot (repo one-platform).
Lot : 42 alertes de portée build (1 critical, 21 high, 19 medium, 1 low ; 36 CVE distinctes + 1 sans CVE). Critical : shell-quote (CVE-2026-9277). Aucune en KEV.

Action attendue : campagne `npm audit` / montée des devDependencies de one-platform, en commençant par shell-quote (critical). Exposition hors ligne (outillage de build, non livré au navigateur).

Critères d'acceptation :
* [ ] shell-quote (CVE-2026-9277) corrigé
* [ ] Réduction du nombre d'alertes build one-platform (objectif : criticals et high à 0)
* [ ] Build front OK
* [ ] Ticket lié à SEC-THREATINTEL-2026-06

Traçabilité : rapport §3.2 Item 6d-1, décision §6 ligne 13. Liste exhaustive : annexe `annexe_dependabot_june2026.md`.

### Environnement
* Composant impacté : outillage build npm de one-platform (webpack, babel, etc.), devDependencies
* Produit(s) concerné(s) : chaîne de build one-platform
* Exposition : Hors ligne (IIS sert le bundle compilé, pas ces paquets)

### Analyse du bug
1. Que s'est-il passé dans le code ? Failles diverses dans des paquets d'outillage de build (dont shell-quote). Code amont des dépendances.
2. Pourquoi le bug s'est-il produit ? Vulnérabilités publiées dans des SOUP de build tirées transitivement.
3. Pourquoi cette cause s'est-elle produite ? devDependencies non montées ; cadence de mise à jour de la chaîne de build.
6. Analyse finale : exposition hors ligne, risque réel faible ; enjeu hygiène + scanners CI. Remédiation groupée par `npm audit` / montées.

### Raison du blocage/décision
* Priorité retenue : P4 (lot) - exposition hors ligne, non KEV. SLA J+90.
* Décision particulière : regroupement justifié par exposition hors ligne + remédiation unique. Scindé par responsable (T8 = modules Angular).

---

## T8 - [SEC][P4][SCA Angular] Lot chaîne de build modules Angular (313 alertes) (Threat Intel 2026-06)

### Description
Item issu de la revue Threat Intelligence 2026-06. Source : GitHub Dependabot (plannerHip3D, plannerKneeMadison, plannerShoulder3D).
Lot : 313 alertes de portée build (6 critical, 139 high, 136 medium, 32 low ; 157 CVE distinctes + 16 sans CVE). Criticals : shell-quote (CVE-2026-9277), handlebars (CVE-2026-33937), protobufjs (CVE-2026-41242), basic-ftp (CVE-2026-27699). Aucune en KEV.

Action attendue : campagne `npm audit` / montée des devDependencies, d'abord les 4 criticals. Charge concentrée sur Hip3D (164) et KneeMadison (147) ; Shoulder3D quasi propre (2 low).

Critères d'acceptation :
* [ ] 4 criticals corrigés sur les modules concernés
* [ ] Réduction des alertes build (criticals et high à 0)
* [ ] Build front OK sur les 3 modules
* [ ] Ticket lié à SEC-THREATINTEL-2026-06

Traçabilité : rapport §3.2 Item 6d-2, décision §6 ligne 5. Liste exhaustive : annexe `annexe_dependabot_june2026.md`.

### Environnement
* Composant impacté : outillage build npm des planificateurs (webpack, vite, rollup, esbuild, babel, tar, protobufjs, @grpc/grpc-js, etc.), devDependencies
* Produit(s) concerné(s) : chaîne de build Hip3D / KneeMadison / Shoulder3D
* Exposition : Hors ligne

### Analyse du bug
1. Que s'est-il passé dans le code ? Failles dans des paquets d'outillage de build (shell-quote, handlebars, protobufjs, basic-ftp, etc.). Code amont.
2. Pourquoi le bug s'est-il produit ? SOUP de build tirées transitivement, vulnérabilités publiées.
3. Pourquoi cette cause s'est-elle produite ? devDependencies non montées ; dette accumulée sur Hip3D/KneeMadison (cohérent avec le retard Angular de ces modules).
6. Analyse finale : exposition hors ligne, risque réel faible ; enjeu hygiène + scanners CI + convergence des versions. Remédiation groupée.

### Raison du blocage/décision
* Priorité retenue : P4 (lot) - exposition hors ligne, non KEV. SLA J+90.
* Décision particulière : regroupement justifié (exposition + remédiation unique). Contraste Hip3D/KneeMadison (dette lourde) vs Shoulder3D (propre) à corréler avec ARCH-VERSIONS-CONVERGENCE.

---

## T9 (Spike) - [SEC][Investigation][PHP] CVE-2026-44927 + CVE-2026-44928 - confirmer la version PHP déployée (Threat Intel 2026-06)

### Description
Item « à investiguer » de la revue Threat Intelligence 2026-06. Source : PHP ChangeLog (8.5.7 / 8.4.22 du 04/06) ; CVE-2026-44927, CVE-2026-44928 (uriparser, extension URI).
Question : quelle version PHP est réellement déployée en production ?
* L'extension URI (uriparser) a été introduite en PHP 8.4. La contrainte composer.json est `>=8.1`.
* Si prod = 8.1 à 8.3 → non applicable (ext URI absente). Si prod = 8.4 / 8.5 → applicable, créer un ticket de remédiation P{n} (montée vers la version corrigée).

Méthode : relever la version PHP des serveurs (phpinfo / CLI), confirmer la présence de l'extension URI.
Sortie : applicable (→ ticket remédiation) OU non applicable (→ §3.3, clore le Spike).

Traçabilité : rapport §3.3 PHP, décision §6 ligne 6.

### Environnement
* Composant impacté : PHP (runtime backend Symfony), version déployée à confirmer
* Produit(s) concerné(s) : Portail Symfony OneSoftware
* Exposition : à déterminer selon usage de l'extension URI

### Analyse du bug (cadrage d'incertitude)
1. Que s'est-il passé dans le code ? Failles dans la bibliothèque uriparser embarquée par l'extension URI de PHP (troncature de différence de pointeur, classification incorrecte d'URI). Code amont PHP/uriparser.
2. Pourquoi le bug s'est-il produit ? Vulnérabilités publiées dans PHP (SOUP).
3. Pourquoi cette cause s'est-elle produite ? Applicabilité dépendante de la branche PHP déployée (l'ext URI n'existe qu'en 8.4+).
4-6. À finaliser après investigation (version PHP prod confirmée).

### Raison du blocage/décision
* Applicabilité non confirmée → investigation bloquante avant tout ticket de remédiation.
* Priorité de l'éventuel ticket : à établir via la matrice §4.4 une fois la version et l'exposition connues. Non KEV.
