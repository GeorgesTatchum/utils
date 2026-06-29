# Tickets Jira de remédiation — Threat Intelligence mai 2026

Tickets prêts à créer, issus du rapport `utils/hds/cyber/may2026/`. Parent : `SEC-THREATINTEL-2026-05` (CICD-169). Date de revue : 04/06/2026 → J+14 = 22/06/2026, J+30 = 06/07/2026, Spikes = 11/06/2026.

Chaque ticket est présenté selon les 4 champs Jira : **Description**, **Environnement**, **Analyse du bug**, **Raison du blocage/décision**. Le bloc « En-tête » regroupe les champs natifs (résumé, type, priorité, assigné, échéance, étiquettes).

Récapitulatif : 8 tickets de remédiation + 2 Spikes. Les items levés après investigation (X509Authenticator, Twig sandbox) ne génèrent pas de ticket.

---

## Ticket 1 — CVE-2026-46626 (Symfony runtime) — P2

**En-tête**
- Résumé : `[SEC][P2][Symfony] CVE-2026-46626 — montée symfony/runtime (Threat Intel 2026-05)`
- Type : Sous-tâche de CICD-169 · Priorité : High · Assigné : Tech Lead Symfony · Échéance : 22/06/2026
- Étiquettes : threat-intel, sec-2026-05, symfony, onesoftware

**Description**
```
Item issu de la revue mensuelle Threat Intelligence 2026-05 (rapport Confluence : <lien>).
Source : Symfony Security Advisories (20/05/2026).
Vulnérabilité : CVE-2026-46626 — SymfonyRuntime CVE-2024-50340 Patch Bypass. CVSS : non communiqué (à compléter via NVD).

Action attendue : patch — montée de symfony/runtime vers la version corrigée (identifier dans l'advisory, confirmer avec le Responsable).

Critères d'acceptation :
* [ ] Version corrigée déployée (staging puis prod)
* [ ] Tests de non-régression Behat OK
* [ ] SBOM régénéré reflétant la version corrigée
* [ ] Sortie Snyk/Dependabot confirmant la disparition de l'alerte
* [ ] Ticket lié à CICD-169

Traçabilité : rapport mensuel <lien Confluence 2026-05> — décision §6 ligne 1.
```

**Environnement**
```
* Composant impacté : symfony/runtime (branche 5.4.*, présent dans composer.lock)
* Produit concerné : Portail Symfony OneSoftware
* Exposition : Internet (portail public via IIS)
```

**Analyse du bug**
```
1. Que s'est-il passé dans le code ?
Dans le composant tiers symfony/runtime, le correctif de CVE-2024-50340 peut être contourné (patch bypass) : la protection ajoutée en amont est rejouable/contournable, réexposant la faille d'origine sur le point de bootstrap/réinitialisation du runtime. Code du composant amont, non du code OneOrtho.

2. Pourquoi le bug s'est-il produit ?
Vulnérabilité publiée dans symfony/runtime (SOUP au sens IEC 62304 §9), réf. CVE-2026-46626 (Symfony Security Advisory du 20/05/2026). Ni correction ni fonctionnalité OneOrtho : faille amont. OneOrtho est concerné car symfony/runtime est une dépendance du portail.

3. Pourquoi cette cause s'est-elle produite ?
La version déployée (branche 5.4.*) est antérieure à la version corrigée (à identifier dans l'advisory) ; composant utilisé par le portail Symfony, exposition Internet via IIS. Dépendance SOUP non encore mise à jour.

4. Pourquoi la cause profonde s'est-elle produite ? (Facultatif)
Latence de mise à jour des dépendances PHP : montée de version Symfony tributaire de la fenêtre de release et de validation.

5. Pourquoi la cause fondamentale s'est-elle produite ? (Facultatif)
Processus de veille/SBOM récemment formalisé ; détection automatisée (Snyk/Dependabot) en place mais la montée de version n'est pas automatique.

6. Analyse finale
Cause fondamentale : faille amont symfony/runtime + latence de patch. Impact : divulgation d'information ou altération du comportement runtime du portail (effet de bord possible sur les DM hébergés). Recommandations : appliquer la montée de version, automatiser le suivi des advisories Symfony, intégrer la montée dans le cycle de patch mensuel.
```

**Raison du blocage/décision**
```
* Priorité retenue : P2 — matrice §4.4 : KEV non + CVSS ≥ 7 estimé + exposition Internet. SLA J+14 (22/06/2026).
* Décision particulière : requalification P1 (72 h) si la CVE est ajoutée au CISA KEV.
* Dépendances / blocages : version cible exacte à confirmer dans l'advisory et avec le Responsable Numérique.
```

---

## Ticket 2 — CVE-2026-45065 (Symfony routing) — P2

**En-tête**
- Résumé : `[SEC][P2][Symfony] CVE-2026-45065 — montée symfony/routing (Threat Intel 2026-05)`
- Type : Sous-tâche de CICD-169 · Priorité : High · Assigné : Tech Lead Symfony · Échéance : 22/06/2026
- Étiquettes : threat-intel, sec-2026-05, symfony, onesoftware

**Description**
```
Item issu de la revue mensuelle Threat Intelligence 2026-05 (rapport Confluence : <lien>).
Source : Symfony Security Advisories (20/05/2026).
Vulnérabilité : CVE-2026-45065 — UrlGenerator Route-Requirement Bypass via URL Injection. CVSS : non communiqué (à compléter via NVD).

Action attendue : patch — montée de symfony/routing vers la version corrigée (version cible à confirmer avec le Responsable).

Critères d'acceptation :
* [ ] Version corrigée déployée (staging puis prod)
* [ ] Tests de non-régression Behat OK
* [ ] SBOM régénéré reflétant la version corrigée
* [ ] Sortie Snyk/Dependabot confirmant la disparition de l'alerte
* [ ] Ticket lié à CICD-169

Traçabilité : rapport mensuel <lien Confluence 2026-05> — décision §6 ligne 2.
```

**Environnement**
```
* Composant impacté : symfony/routing (présent dans composer.lock)
* Produit concerné : Portail Symfony OneSoftware
* Exposition : Internet
```

**Analyse du bug**
```
1. Que s'est-il passé dans le code ?
Dans le composant tiers symfony/routing, le générateur d'URL (UrlGenerator) ne valide pas correctement les contraintes de route (route requirements), permettant de générer/injecter une URL ne respectant pas le motif attendu. Code du composant amont, non du code OneOrtho.

2. Pourquoi le bug s'est-il produit ?
Vulnérabilité publiée dans symfony/routing (SOUP au sens IEC 62304 §9), réf. CVE-2026-45065 (Symfony Security Advisory du 20/05/2026). Ni correction ni fonctionnalité OneOrtho : faille amont. OneOrtho est concerné car symfony/routing est une dépendance du portail.

3. Pourquoi cette cause s'est-elle produite ?
La version déployée est antérieure à la version corrigée (à confirmer avec le Responsable) ; composant utilisé par le portail Symfony, exposition Internet via IIS. Dépendance SOUP non encore mise à jour.

4. Pourquoi la cause profonde s'est-elle produite ? (Facultatif)
Latence de mise à jour des dépendances PHP (cadence de montée Symfony).

5. Pourquoi la cause fondamentale s'est-elle produite ? (Facultatif)
Veille/SBOM récemment formalisés ; montée de version non automatisée.

6. Analyse finale
Cause fondamentale : faille amont symfony/routing + latence de patch. Impact : contournement de contrôle d'accès basé sur le motif de route ou forge/redirection d'URL (atteinte intégrité). Recommandations : montée de version, suivi automatisé des advisories Symfony, intégration au cycle de patch mensuel.
```

**Raison du blocage/décision**
```
* Priorité retenue : P2 — matrice §4.4 : KEV non + CVSS ≥ 7 estimé + exposition Internet. SLA J+14 (22/06/2026).
* Décision particulière : requalification P1 si ajout au CISA KEV.
* Dépendances / blocages : version cible à confirmer avec le Responsable.
```

---

## Ticket 3 — Patch Tuesday Windows Server mai 2026, RCE Critical (6 CVE) — P2

**En-tête**
- Résumé : `[SEC][P2][WindowsServer] Patch Tuesday 2026-05 — 6 RCE Critical (Threat Intel 2026-05)`
- Type : Sous-tâche de CICD-169 · Priorité : High · Assigné : DevSecOps + équipe infrastructure · Échéance : 22/06/2026
- Étiquettes : threat-intel, sec-2026-05, windows-server, infrastructure

**Description**
```
Item issu de la revue mensuelle Threat Intelligence 2026-05.
Source : Microsoft MSRC Security Update Guide (export CSV 02/06/2026), Patch Tuesday du 12/05/2026.
Vulnérabilités : CVE-2026-32161, CVE-2026-35421, CVE-2026-40402, CVE-2026-40403, CVE-2026-41089, CVE-2026-41096 (Critical).

Action attendue : application interne (MCO OS OneOrtho) du Patch Tuesday 12/05/2026 sur les serveurs non patchés, en fenêtre 02h–03h, canary préprod puis prod. Mode opératoire : `procedure_application_patch_ticket3_windows.md`. Validation post-patch (build + portail) avant clôture.

Critères d'acceptation :
* [ ] Correctifs appliqués sur toutes les versions du parc (2016/2019/2022/2025)
* [ ] Validation post-patch sur staging puis prod
* [ ] Disponibilité du portail vérifiée après patch
* [ ] Ticket lié à CICD-169

Traçabilité : rapport mensuel <lien Confluence 2026-05> — décision §6 ligne 5.
```

**Environnement**
```
* Composant impacté : Windows Server 2016 / 2019 / 2022 / 2025 (parc hétérogène, toutes versions présentes)
* Produit concerné : Infrastructure d'exécution (OS hôte du portail + IIS)
* Exposition : Internet (l'OS porte le portail public via IIS)
```

**Analyse du bug**
```
1. Que s'est-il passé dans le code ?
Dans des composants système de Windows Server, 6 failles permettent l'exécution de code à distance (détail par CVE dans le MSRC Security Update Guide). Code de l'OS amont (Microsoft), non du code OneOrtho.

2. Pourquoi le bug s'est-il produit ?
Vulnérabilités publiées par Microsoft (Patch Tuesday du 12/05/2026) dans Windows Server — environnement d'exécution / SOUP au sens IEC 62304 §5.7. Réf. CVE-2026-32161, CVE-2026-35421, CVE-2026-40402, CVE-2026-40403, CVE-2026-41089, CVE-2026-41096. Faille amont, hors code OneOrtho.

3. Pourquoi cette cause s'est-elle produite ?
Le parc n'a pas encore reçu la mise à jour cumulative de mai (build < build cible) ; l'OS porte le portail public via IIS → exposition Internet. Environnement d'exécution non encore patché.

4. Pourquoi la cause profonde s'est-elle produite ? (Facultatif)
Le MCO de l'OS est assuré en interne par OneOrtho (pas par AVA6) ; absence jusqu'ici d'un cycle de patch OS planifié et d'une vérification systématique du niveau de correctif du parc.

5. Pourquoi la cause fondamentale s'est-elle produite ? (Facultatif)
Pas de processus interne formalisé de gestion des Patch Tuesday OS (planification, fenêtre de maintenance, suivi du build) avant la mise en place de la présente revue.

6. Analyse finale
Cause fondamentale : failles OS amont + latence d'application du Patch Tuesday. Impact : compromission de l'hôte → atteinte C/I/D du portail et des données d'intervention hébergées, effet de bord sur les DM hébergés. Recommandations : application interne planifiée (fenêtre 02h–03h, cf. `procedure_application_patch_ticket3_windows.md`), vérification systématique du build, mise en place d'un cycle de patch OS mensuel récurrent.
```

**Raison du blocage/décision**
```
* Priorité retenue : P2 — matrice §4.4 : KEV non + gravité Critical (CVSS ≥ 7) + exposition Internet. SLA J+14 (22/06/2026).
* Décision particulière : aucune (priorité standard).
* Dépendances / blocages : à coordonner avec la fenêtre de maintenance du parc ; validation staging obligatoire avant prod.
```

---

## Ticket 4 — Montée Angular, XSS Template/Dynamic Component — P2

**En-tête**
- Résumé : `[SEC][P2][Angular] GHSA-692r-grfm-v8x7 — montée Angular XSS Template/Component (Threat Intel 2026-05)`
- Type : Sous-tâche de CICD-169 · Priorité : High · Assigné : Tech Lead Angular · Échéance : 22/06/2026
- Étiquettes : threat-intel, sec-2026-05, angular, plannerhip2d, plannerhip3d, plannerkneemadison, plannershoulder3d

**Description**
```
Item issu de la revue mensuelle Threat Intelligence 2026-05.
Source : Angular Security Advisories (GitHub, 28/05/2026).
Vulnérabilité : GHSA-692r-grfm-v8x7 — Template and Dynamic Component Namespace Bypass leading to XSS. Sévérité : Modérée à Élevée (à compléter via advisory).

Action attendue : montée d'Angular vers la version corrigée dans chaque module. Audit du code pour repérer les patterns de rendu vulnérables avant patch.

Critères d'acceptation :
* [ ] Version corrigée déployée sur les 4 modules (branches 20.x et 21.x)
* [ ] Audit des patterns de rendu réalisé
* [ ] Tests de non-régression Cypress/Karma OK
* [ ] SBOM régénéré par module
* [ ] Ticket lié à CICD-169

Traçabilité : rapport mensuel <lien Confluence 2026-05> — décision §6 ligne 11.
```

**Environnement**
```
* Composant impacté : @angular/core (présent dans les 4 planificateurs)
* Produit(s) concerné(s) : plannerHip2D, plannerHip3D, plannerKneeMadison, plannerShoulder3D
* Exposition : Internet (modules livrés au navigateur client)
* Branches Angular : 20.3 (Hip2D, Hip3D, KneeMadison) et 21.2 (Shoulder3D)
```

**Analyse du bug**
```
1. Que s'est-il passé dans le code ?
Dans le composant tiers @angular/core, un contournement de l'espace de noms des templates et composants dynamiques permet l'injection de script (XSS) lors du rendu. Code du composant amont, non du code OneOrtho.

2. Pourquoi le bug s'est-il produit ?
Vulnérabilité publiée dans @angular/core (SOUP au sens IEC 62304 §9), réf. GHSA-692r-grfm-v8x7 (Angular Security Advisory du 28/05/2026). Ni correction ni fonctionnalité OneOrtho : faille amont. OneOrtho est concerné car @angular/core est une dépendance des planificateurs.

3. Pourquoi cette cause s'est-elle produite ?
Les versions déployées (20.3 et 21.2) sont antérieures au correctif ; composant présent dans les 4 planificateurs, livrés au navigateur du client → exposition Internet. Dépendance SOUP non encore mise à jour.

4. Pourquoi la cause profonde s'est-elle produite ? (Facultatif)
Latence de montée Angular, aggravée par l'hétérogénéité de versions (2 branches 20.3 / 21.2 à patcher et tester séparément).

5. Pourquoi la cause fondamentale s'est-elle produite ? (Facultatif)
Convergence des versions Angular non encore réalisée (ticket ARCH-VERSIONS-CONVERGENCE en attente) ; veille récemment formalisée.

6. Analyse finale
Cause fondamentale : faille amont @angular/core + latence de patch + hétérogénéité de versions. Impact : exécution de script dans la session utilisateur des planificateurs (périmètre DM), à tracer côté sécurité produit. Recommandations : montée par branche, audit des patterns de rendu vulnérables, convergence des versions Angular, suivi automatisé des advisories Angular.
```

**Raison du blocage/décision**
```
* Priorité retenue : P2 — matrice §4.4 : KEV non + XSS (CVSS ≥ 7) + exposition Internet (composant exécuté navigateur). SLA J+14 (22/06/2026).
* Décision particulière : aucune.
* Dépendances / blocages : 2 branches Angular (20.3 / 21.2) → correctif à appliquer et tester par branche ; audit des patterns vulnérables requis avant patch.
```

---

## Ticket 5 — GHSA-7qg2-v9fj-4mwv (PHP-FPM /status XSS) — P3

**En-tête**
- Résumé : `[SEC][P3][PHP] GHSA-7qg2-v9fj-4mwv — XSS endpoint PHP-FPM /status (Threat Intel 2026-05)`
- Type : Sous-tâche de CICD-169 · Priorité : Medium · Assigné : DevSecOps + Tech Lead Symfony · Échéance : 06/07/2026
- Étiquettes : threat-intel, sec-2026-05, php, onesoftware

**Description**
```
Item issu de la revue mensuelle Threat Intelligence 2026-05.
Source : GitHub Advisories php/php-src (07/05/2026).
Vulnérabilité : GHSA-7qg2-v9fj-4mwv — XSS within PHP-FPM status endpoint (CVE à compléter). Sévérité : Modérée.

Action attendue :
Étape 1 — vérifier la configuration de l'endpoint /status PHP-FPM (exposition publique via IIS ?).
Étape 2 — patcher PHP à la version disponible (confirmer si correctif inclus dans 8.5.6 ou rétroporté en 8.1.x).

Critères d'acceptation :
* [ ] Exposition de /status vérifiée et documentée
* [ ] PHP patché si nécessaire
* [ ] SBOM régénéré
* [ ] Ticket lié à CICD-169

Traçabilité : rapport mensuel <lien Confluence 2026-05> — décision §6 ligne 4.
```

**Environnement**
```
* Composant impacté : PHP-FPM (docker/php/Dockerfile, docker/php-alpine/Dockerfile)
* Produit concerné : Portail Symfony OneSoftware
* Exposition : à vérifier — endpoint /status exposé public ? (par défaut non)
```

**Analyse du bug**
```
1. Que s'est-il passé dans le code ?
Dans le composant tiers PHP-FPM, une injection de script (XSS) est possible dans la page de statut exposée par l'endpoint /status. Code du composant amont (PHP), non du code OneOrtho.

2. Pourquoi le bug s'est-il produit ?
Vulnérabilité publiée dans php-src (SOUP au sens IEC 62304 §9), réf. GHSA-7qg2-v9fj-4mwv (GitHub Advisory php/php-src du 07/05/2026). Faille amont, hors code OneOrtho.

3. Pourquoi cette cause s'est-elle produite ?
PHP-FPM est présent dans les images (docker/php) ; la version déployée est antérieure au correctif. L'exposition dépend de l'accessibilité de l'endpoint /status (non exposé en configuration par défaut) → à vérifier sur la config IIS de production.

4. Pourquoi la cause profonde s'est-elle produite ? (Facultatif)
Latence de montée PHP ; PHP 8.1 proche/hors support communautaire → la cadence de migration PHP conditionne la disponibilité du correctif.

5. Pourquoi la cause fondamentale s'est-elle produite ? (Facultatif)
Migration PHP hors 8.1 non encore planifiée ; veille récemment formalisée.

6. Analyse finale
Cause fondamentale : faille amont PHP-FPM + exposition conditionnelle de l'endpoint /status. Impact : XSS dans le contexte d'un opérateur si l'endpoint est exposé, nul sinon. Recommandations : vérifier/durcir la config /status (ne pas l'exposer), monter PHP, planifier la migration hors 8.1.
```

**Raison du blocage/décision**
```
* Priorité retenue : P3 par défaut — matrice §4.4 : KEV non + sévérité modérée + exposition probable interne. SLA J+30 (06/07/2026).
* Décision particulière : reclassement P2 (SLA J+14) si l'étape 1 confirme que l'endpoint /status est exposé publiquement.
* Dépendances / blocages : conclusion de l'étape 1 (vérification config IIS) avant décision de patch.
```

---

## Ticket 6 — Patch Tuesday Windows Server mai 2026, 62 CVE Important — P3

**En-tête**
- Résumé : `[SEC][P3][WindowsServer] Patch Tuesday 2026-05 — 62 CVE Important (Threat Intel 2026-05)`
- Type : Sous-tâche de CICD-169 · Priorité : Medium · Assigné : DevSecOps + équipe infrastructure · Échéance : 06/07/2026
- Étiquettes : threat-intel, sec-2026-05, windows-server, infrastructure

**Description**
```
Item issu de la revue mensuelle Threat Intelligence 2026-05.
Source : Microsoft MSRC (export CSV 02/06/2026), Patch Tuesday 12/05/2026.
Vulnérabilités : 62 CVE Important sur Windows Server 2016/2019/2022/2025 + .NET Framework (liste complète dans le CSV source, annexe rapport).

Action attendue : application du rouleau cumulatif Patch Tuesday, en même temps que le Ticket 3 (RCE Critical). Pas d'action item-par-item.

Critères d'acceptation :
* [ ] Rouleau cumulatif appliqué sur tout le parc
* [ ] Validation post-patch staging puis prod
* [ ] Ticket lié à CICD-169

Traçabilité : rapport mensuel <lien Confluence 2026-05> — décision §6 ligne 6.
```

**Environnement**
```
* Composant impacté : Windows Server 2016/2019/2022/2025 + .NET Framework 3.5/4.7.2/4.8/4.8.1
* Produit concerné : Infrastructure d'exécution
* Exposition : Interne (accès local requis pour la plupart)
```

**Analyse du bug**
```
1. Que s'est-il passé dans le code ?
Dans Windows Server et .NET Framework, 62 failles majoritairement d'élévation de privilèges, plus divulgation d'information, déni de service et contournement de fonction de sécurité (détail par CVE dans le MSRC). Code de l'OS / du framework amont (Microsoft), non du code OneOrtho.

2. Pourquoi le bug s'est-il produit ?
Vulnérabilités publiées par Microsoft (Patch Tuesday du 12/05/2026) — environnement d'exécution / SOUP au sens IEC 62304 §5.7. Faille amont, hors code OneOrtho.

3. Pourquoi cette cause s'est-elle produite ?
Le parc n'a pas encore reçu la cumulative de mai (build < build cible) ; exposition interne (accès local requis pour la plupart des CVE).

4. Pourquoi la cause profonde s'est-elle produite ? (Facultatif)
MCO OS interne OneOrtho ; fenêtre de maintenance commune avec le Ticket 3 (application groupée).

5. Pourquoi la cause fondamentale s'est-elle produite ? (Facultatif)
Pas encore de cycle de patch OS interne formalisé ni de vérification systématique du niveau de correctif.

6. Analyse finale
Cause fondamentale : failles OS/.NET amont + latence d'application du Patch Tuesday. Impact : escalade locale ou fuite d'information sur l'hôte, surface réelle réduite par le prérequis d'accès local. Recommandations : application groupée avec les RCE Critical (Ticket 3), suivi systématique du niveau de correctif.
```

**Raison du blocage/décision**
```
* Priorité retenue : P3 — matrice §4.4 : KEV non + gravité Important + exposition interne (accès local requis). SLA J+30 (06/07/2026).
* Décision particulière : traitement groupé en un seul lot (rouleau cumulatif), conjointement avec le Ticket 3.
* Dépendances / blocages : même fenêtre de maintenance que le Ticket 3.
```

---

## Ticket 7 — Montée parc MariaDB (4 branches LTS, 13 CVE) — P3 (accélération recommandée J+14)

**En-tête**
- Résumé : `[SEC][P3][MariaDB] Montée parc 4 branches LTS — 13 CVE dont CVE-2026-49261 CVSS 10.0 (Threat Intel 2026-05)`
- Type : Sous-tâche de CICD-169 · Priorité : Medium (traiter en priorité haute vu CVSS 10.0) · Assigné : DevSecOps + équipe infrastructure · Échéance : 06/07/2026 (recommandation 22/06/2026)
- Étiquettes : threat-intel, sec-2026-05, mariadb, infrastructure

**Description**
```
Item issu de la revue mensuelle Threat Intelligence 2026-05.
Source : documentation officielle MariaDB (community-server.md) croisée avec le parc (curent-mariadb-onserver.md).
Vulnérabilités : 13 CVE 2026 applicables, dont CVE-2026-49261 (CVSS 10.0), CVE-2026-48165/48163/44168 (8.0), CVE-2026-32710 (8.6) et 8 CVE CVSS < 7.

Action attendue : montée unique de chaque branche vers sa dernière LTS :
* 11.8.5 → 11.8.8
* 11.4.9 → 11.4.12
* 10.11.15 → 10.11.18
* 10.6.24 → 10.6.27
Ces cibles couvrent rétroactivement les 13 CVE (correctifs cumulatifs).

Critères d'acceptation :
* [ ] Les 16 instances montées vers la LTS de tête de leur branche
* [ ] Sauvegarde préalable et validation d'intégrité post-montée
* [ ] Tests applicatifs portail OK après montée
* [ ] Ticket lié à CICD-169

Traçabilité : rapport mensuel <lien Confluence 2026-05> — décision §6 ligne 8.
```

**Environnement**
```
* Composant impacté : MariaDB Community Server
* Parc : 16 instances — 11.8.5 (×8), 11.4.9 (×2), 10.11.15 (×2), 10.6.24 (×4)
* Produit concerné : Portail Symfony OneSoftware (base de données)
* Exposition : Interne (MariaDB derrière le portail, non exposé Internet directement)
```

**Analyse du bug**
```
1. Que s'est-il passé dans le code ?
Dans le SGBD tiers MariaDB Community Server, 13 failles 2026 dont CVE-2026-49261 (CVSS 10.0), CVE-2026-48165/48163/44168 (8.0) et CVE-2026-32710 (8.6) ; détail technique par CVE dans community-server.md. Code du composant amont, non du code OneOrtho.

2. Pourquoi le bug s'est-il produit ?
Vulnérabilités publiées par MariaDB (SOUP au sens IEC 62304 §9). Faille amont, hors code OneOrtho. OneOrtho est concerné car MariaDB est le SGBD du portail.

3. Pourquoi cette cause s'est-elle produite ?
Les 16 instances du parc sont en deçà des versions corrigées sur leurs 4 branches LTS ; exposition interne (MariaDB derrière le portail, non exposé Internet directement). Dépendance SOUP non encore mise à jour.

4. Pourquoi la cause profonde s'est-elle produite ? (Facultatif)
Cadence de montée des instances MariaDB ; parc à 4 branches LTS multipliant l'effort de patch ; fenêtre de maintenance et sauvegarde préalable requises.

5. Pourquoi la cause fondamentale s'est-elle produite ? (Facultatif)
Stratégie de versionnement du parc (4 branches) non encore convergée ; suivi du fichier de référence MariaDB récemment intégré à la veille.

6. Analyse finale
Cause fondamentale : failles amont MariaDB + latence de patch + parc multi-branches. Impact : atteinte C/I/D des données applicatives (atténuée par l'accès réseau interne). Recommandations : montée unique de chaque branche vers la LTS de tête, accélération vu CVE-2026-49261 (CVSS 10.0), suivi automatisé du fichier MariaDB, réflexion sur la convergence des branches.
```

**Raison du blocage/décision**
```
* Priorité retenue : P3 — matrice §4.4 : KEV non + CVSS ≥ 7 MAIS exposition interne. SLA J+30 (06/07/2026).
* Décision particulière : accélération recommandée à J+14 (22/06/2026) au regard de CVE-2026-49261 (CVSS 10.0), malgré le classement matriciel P3.
* Dépendances / blocages : fenêtre de maintenance des 16 instances + sauvegarde préalable obligatoire avant montée.
```

---

## Ticket 8 — GHSA-p3vc-36g9-x9gr (Angular DoS digitsInfo) — P3

**En-tête**
- Résumé : `[SEC][P3][Angular] GHSA-p3vc-36g9-x9gr — montée Angular DoS digitsInfo (Threat Intel 2026-05)`
- Type : Sous-tâche de CICD-169 · Priorité : Medium · Assigné : Tech Lead Angular · Échéance : 06/07/2026
- Étiquettes : threat-intel, sec-2026-05, angular, plannerhip2d, plannerhip3d, plannerkneemadison, plannershoulder3d

**Description**
```
Item issu de la revue mensuelle Threat Intelligence 2026-05.
Source : Angular Security Advisories (GitHub, 28/05/2026).
Vulnérabilité : GHSA-p3vc-36g9-x9gr — Denial of Service (DoS) via OOM in Number Formatting (digitsInfo). Sévérité : Élevée.

Action attendue : montée d'Angular vers la version corrigée dans chaque module (peut être traité en même temps que le Ticket 4 — XSS Template/Component).

Critères d'acceptation :
* [ ] Version corrigée déployée sur les 4 modules
* [ ] Tests de non-régression Cypress/Karma OK
* [ ] SBOM régénéré par module
* [ ] Ticket lié à CICD-169

Traçabilité : rapport mensuel <lien Confluence 2026-05> — décision §6 ligne 12.
```

**Environnement**
```
* Composant impacté : @angular/common (présent dans les 4 planificateurs)
* Produit(s) concerné(s) : plannerHip2D, plannerHip3D, plannerKneeMadison, plannerShoulder3D
* Exposition : Internet (modules livrés navigateur, DoS côté client)
* Branches Angular : 20.3 et 21.2
```

**Analyse du bug**
```
1. Que s'est-il passé dans le code ?
Dans le composant tiers @angular/common, un déni de service par épuisement mémoire (OOM) se produit lors du formatage de nombres avec un paramètre digitsInfo malveillant. Code du composant amont, non du code OneOrtho.

2. Pourquoi le bug s'est-il produit ?
Vulnérabilité publiée dans @angular/common (SOUP au sens IEC 62304 §9), réf. GHSA-p3vc-36g9-x9gr (Angular Security Advisory du 28/05/2026). Faille amont, hors code OneOrtho.

3. Pourquoi cette cause s'est-elle produite ?
Les versions déployées (20.3 et 21.2) sont antérieures au correctif ; composant présent dans les 4 planificateurs, livrés au navigateur → exposition Internet (DoS côté client). Dépendance SOUP non encore mise à jour.

4. Pourquoi la cause profonde s'est-elle produite ? (Facultatif)
Latence de montée Angular ; 2 branches (20.3 / 21.2) à patcher.

5. Pourquoi la cause fondamentale s'est-elle produite ? (Facultatif)
Convergence des versions Angular non encore réalisée ; veille récemment formalisée.

6. Analyse finale
Cause fondamentale : faille amont @angular/common + latence de patch. Impact : plantage de l'onglet/module côté client (disponibilité), pas d'atteinte serveur ni de données. Recommandations : montée mutualisée avec le Ticket 4 (XSS Template/Component), convergence des versions Angular.
```

**Raison du blocage/décision**
```
* Priorité retenue : P3 — matrice §4.4 : KEV non + sévérité Élevée mais DoS côté client navigateur (impact disponibilité limité au poste). SLA J+30 (06/07/2026).
* Décision particulière : aucune.
* Dépendances / blocages : à mutualiser avec le Ticket 4 (même montée Angular, mêmes branches 20.3 / 21.2).
```

---

## Spike 1 — Microsoft Defender (CVE-2026-41091 + CVE-2026-45498) — Investigation [TERMINÉ]

> **Résultat (juin 2026)** : investigation menée (`Get-MpComputerStatus`, parc complet). Defender actif sur tout le parc.
> - **CVE-2026-41091 (moteur)** : `AMEngineVersion` 1.1.26050.11 ≥ 1.1.26040.8 sur tous les serveurs → **non applicable** (corrigée par auto-update). Pas de ticket de remédiation. Tracé en §3.3 du rapport.
> - **CVE-2026-45498 (plateforme)** : `AMProductVersion` 4.18.1911.3 < 4.18.26040.7 sur **2 serveurs** ({{SRV-A}}, {{SRV-B}}) → **applicable** → ticket de remédiation **Ticket 9** ci-dessous. Reste du parc ≥ cible.
> Clore le Spike avec ce résultat.

**En-tête**
- Résumé : `[SEC][Investigation][WindowsServer] CVE-2026-41091 + CVE-2026-45498 — Defender actif ? (Threat Intel 2026-05)`
- Type : Spike / Investigation · Assigné : DevSecOps + équipe infrastructure · Échéance : 11/06/2026 · Statut : **Terminé**
- Étiquettes : threat-intel, sec-2026-05, windows-server, investigation

**Description**
```
Item issu de la revue mensuelle Threat Intelligence 2026-05.
Question : Microsoft Defender (Malware Protection Engine / Antimalware Platform) est-il l'antivirus actif sur les serveurs Windows OneOrtho ?
Contexte : CVE-2026-41091 (Link Following, EoP) et CVE-2026-45498 (DoS) ajoutées au CISA KEV le 20/05/2026 — exploitées activement.
Méthode : vérifier la configuration antivirus du parc Windows Server (Defender vs solution tierce).
Sortie attendue :
* Defender actif → créer tickets remédiation : CVE-2026-41091 P2 (KEV + EoP), CVE-2026-45498 P3 (KEV + DoS, sévérité MSRC Low). Patch via auto-update Defender.
* Defender non utilisé → reclasser non applicable en §3.3, clore le Spike.

Traçabilité : rapport mensuel <lien Confluence 2026-05> — décision §6 ligne 7.
```

**Environnement**
```
* Composant potentiellement impacté : Microsoft Defender (Malware Protection Engine / Antimalware Platform)
* Produit concerné : Infrastructure d'exécution (serveurs Windows Server du parc)
* Exposition : Interne (Defender s'exécute en local, traite des fichiers en entrée)
```

**Analyse du bug** (préliminaire — points 4 à 6 à finaliser après investigation)
```
1. Que s'est-il passé dans le code ?
Dans le moteur antivirus Microsoft Defender (Malware Protection Engine / Antimalware Platform), CVE-2026-41091 (Link Following → élévation de privilèges) et CVE-2026-45498 (déni de service) lors du traitement d'un fichier. Code du composant amont (Microsoft), non du code OneOrtho.

2. Pourquoi le bug s'est-il produit ?
Vulnérabilités publiées par Microsoft, ajoutées au CISA KEV le 20/05/2026 (exploitation active). SOUP / composant système. Faille amont, hors code OneOrtho.

3. Pourquoi cette cause s'est-elle produite ?
Exposition conditionnée à la présence de Defender comme antivirus actif sur le parc Windows Server → objet de cette investigation. Si actif et non patché, dépendance SOUP exposée.

4. Pourquoi la cause profonde s'est-elle produite ? (Facultatif)
À compléter après investigation (selon que Defender est l'AV actif et son niveau de mise à jour).

5. Pourquoi la cause fondamentale s'est-elle produite ? (Facultatif)
À compléter après investigation.

6. Analyse finale
À finaliser après investigation. Si Defender actif → faille amont AV exploitée activement (KEV) → remédiation prioritaire (auto-update Defender). Sinon → non applicable, documenter en §3.3 et clore.
```

**Raison du blocage/décision**
```
* Applicabilité non confirmée (Defender actif ou non) → investigation bloquante avant tout ticket de remédiation.
* Facteur d'urgence : les 2 CVE sont au CISA KEV (exploitation active). Si applicable, CVE-2026-41091 = P2 (potentiellement P1 si exposition aggravée). SLA investigation : 11/06/2026.
```

---

## Spike 2 — Fonctions PHP standard (4 GHSA php-src) — Investigation

**En-tête**
- Résumé : `[SEC][Investigation][PHP] 4 GHSA php-src — usage des fonctions impactées ? (Threat Intel 2026-05)`
- Type : Spike / Investigation · Assigné : DevSecOps + Tech Lead Symfony · Échéance : 11/06/2026
- Étiquettes : threat-intel, sec-2026-05, php, onesoftware, investigation

**Description**
```
Item issu de la revue mensuelle Threat Intelligence 2026-05.
Question : les fonctions PHP impactées par les advisories du 07/05/2026 sont-elles utilisées dans un contexte exploitable par OneSoftware ?
* GHSA-m8rr-4c36-8gq4 — urldecode()
* GHSA-74r9-qxhc-fx53 — mb_convert_encoding()
* GHSA-4jhr-8w89-j733 — DOMNode::C14N() (Critique, canonicalisation XML / signatures)
* GHSA-wm6j-2649-pv75 — php_mb_check_encoding()
Méthode : recherche d'usage dans le code applicatif et les bundles internes. Vérifier en particulier l'usage de la canonicalisation XML (signatures) pour DOMNode::C14N().
Sortie attendue :
* Fonction utilisée dans un contexte exploitable → créer ticket remédiation (montée PHP) P3 par défaut.
* Sinon → reclasser non applicable en §3.3, clore.

Traçabilité : rapport mensuel <lien Confluence 2026-05> — décision §6 ligne 9.
```

**Environnement**
```
* Composant potentiellement impacté : runtime PHP (8.1+), fonctions urldecode / mb_convert_encoding / DOMNode::C14N / php_mb_check_encoding
* Produit concerné : Portail Symfony OneSoftware
* Exposition : dépend du contexte d'appel des fonctions (à déterminer)
```

**Analyse du bug** (préliminaire — points 4 à 6 à finaliser après investigation)
```
1. Que s'est-il passé dans le code ?
Dans le runtime PHP, 4 failles affectant des fonctions standard : urldecode (GHSA-m8rr-4c36-8gq4), mb_convert_encoding (GHSA-74r9-qxhc-fx53), DOMNode::C14N (GHSA-4jhr-8w89-j733, Critique), php_mb_check_encoding (GHSA-wm6j-2649-pv75) — corruption mémoire / lecture hors limites / DoS. Code du composant amont (PHP), non du code OneOrtho.

2. Pourquoi le bug s'est-il produit ?
Vulnérabilités publiées dans php-src (SOUP au sens IEC 62304 §9), GitHub Advisories du 07/05/2026. Faille amont, hors code OneOrtho.

3. Pourquoi cette cause s'est-elle produite ?
Exposition conditionnée à l'usage effectif des fonctions dans un contexte attaquable (entrée contrôlée) → objet de cette investigation. PHP présent comme runtime backend Symfony.

4. Pourquoi la cause profonde s'est-elle produite ? (Facultatif)
À compléter après investigation (selon usage des fonctions et niveau de version PHP).

5. Pourquoi la cause fondamentale s'est-elle produite ? (Facultatif)
À compléter après investigation.

6. Analyse finale
À finaliser après investigation. Selon usage : si une fonction est utilisée dans un contexte attaquable → remédiation (montée PHP) P3 par défaut ; sinon → non applicable, documenter en §3.3 et clore. DOMNode::C14N (Critique) à examiner en priorité si signatures XML utilisées.
```

**Raison du blocage/décision**
```
* Applicabilité non confirmée (usage des fonctions impactées) → investigation avant remédiation.
* Décision : priorité de l'éventuel ticket de remédiation = P3 par défaut (KEV non, exposition à qualifier). DOMNode::C14N() (Critique) à examiner en priorité. SLA investigation : 11/06/2026.
```

---

## Ticket 9 — CVE-2026-45498 (plateforme Defender, 2 serveurs) — P3

> Issu de la conclusion du Spike 1.

**En-tête**
- Résumé : `[SEC][P3][WindowsServer] CVE-2026-45498 — montée plateforme Defender sur 2 serveurs (Threat Intel 2026-05)`
- Type : Sous-tâche de CICD-169 · Priorité : Medium · Assigné : DevSecOps + équipe infrastructure (MCO OS interne OneOrtho) · Échéance : 06/07/2026
- Étiquettes : threat-intel, sec-2026-05, windows-server, defender, infrastructure

**Description**
```
Item issu de la revue mensuelle Threat Intelligence 2026-05, confirmé par le Spike 1.
Source : CISA KEV + Microsoft MSRC.
Vulnérabilité : CVE-2026-45498 — Microsoft Defender Antimalware Platform Denial of Service. Au CISA KEV (exploitation active).

Action attendue : mettre à jour la plateforme antimalware Defender (AMProductVersion ≥ 4.18.26040.7) sur les 2 serveurs concernés, ET corriger le mécanisme d'auto-update plateforme défaillant (plateforme figée à 4.18.1911.3 = nov. 2019). Update-MpSignature ne met pas à jour la plateforme → application interne via Windows Update / package plateforme (MCO OS OneOrtho), en réparant le canal de mise à jour bloqué.

Critères d'acceptation :
* [ ] AMProductVersion ≥ 4.18.26040.7 sur les 2 serveurs (relevé Get-MpComputerStatus après MAJ)
* [ ] Mécanisme d'auto-update plateforme rétabli et vérifié sur les 2 serveurs
* [ ] Supervision de AMProductVersion ajoutée (Zabbix) pour détecter toute future dérive
* [ ] Ticket lié à CICD-169

Traçabilité : rapport mensuel <lien Confluence 2026-05> — décision §6 ligne 7. Issu du Spike 1.
```

**Environnement**
```
* Composant impacté : Microsoft Defender Antimalware Platform (AMProductVersion)
* Serveurs concernés : {{SRV-A}}, {{SRV-B}} — AMProductVersion actuelle 4.18.1911.3 (< cible 4.18.26040.7)
* Reste du parc : AMProductVersion ≥ cible (non concerné)
* Exposition : Interne (Defender s'exécute en local)
```

**Analyse du bug**
```
1. Que s'est-il passé dans le code ?
Dans la plateforme antimalware Microsoft Defender (4.18.x), une faille permet un déni de service (CVE-2026-45498). Code du composant amont (Microsoft), non du code OneOrtho.

2. Pourquoi le bug s'est-il produit ?
Vulnérabilité publiée par Microsoft, ajoutée au CISA KEV le 20/05/2026 (exploitation active). SOUP / composant système. Faille amont.

3. Pourquoi cette cause s'est-elle produite ?
2 serveurs ont une plateforme Defender figée à 4.18.1911.3 (novembre 2019), antérieure à la version corrigée 4.18.26040.7, alors que le moteur (1.1.x) et les signatures, eux, sont à jour.

4. Pourquoi la cause profonde s'est-elle produite ? (Facultatif)
Le mécanisme de mise à jour de la PLATEFORME Defender (distinct du moteur/signatures, livré via Windows Update) est défaillant ou désactivé sur ces 2 serveurs : la plateforme n'a pas été mise à jour depuis ~6 ans.

5. Pourquoi la cause fondamentale s'est-elle produite ? (Facultatif)
Absence de supervision du niveau de plateforme Defender (AMProductVersion) sur le parc : ces 2 serveurs sont sortis du cycle de mise à jour plateforme sans détection.

6. Analyse finale
Cause fondamentale : auto-update de la plateforme Defender cassé sur 2 serveurs (plateforme figée 2019). Au-delà de CVE-2026-45498, ces 2 serveurs accumulent ~6 ans de CVE plateforme Defender non corrigées. Recommandations : mettre à jour la plateforme, RÉPARER le mécanisme d'auto-update (cause racine), superviser AMProductVersion dans Zabbix pour détecter toute dérive future, étendre le contrôle à l'ensemble du parc.
```

**Raison du blocage/décision**
```
* Priorité retenue : P3 — la CVE est au KEV mais de type DoS / sévérité MSRC Low, exposition interne. Le KEV justifie de ne pas reléguer en P4. SLA J+30 (06/07/2026).
* Décision particulière : la remédiation va au-delà de la CVE — réparer l'auto-update plateforme (cause racine) qui expose les 2 serveurs à un backlog de CVE plateforme.
* Dépendances / blocages : Update-MpSignature insuffisant (ne touche pas la plateforme) → application interne via le canal Windows Update à rétablir ; fenêtre de maintenance des 2 serveurs (02h–03h).
```

---

## Items SANS ticket (rappel)

| Item | Raison |
|------|--------|
| CVE-2026-45063 (Symfony X509Authenticator) | Levé après investigation — brique non utilisée + version corrigée. Voir §3.3 du rapport |
| CVE-2026-48805 + 48806 + 46636 (Twig sandbox) | Levé après investigation — sandbox non utilisé + version corrigée. Voir §3.3 du rapport |
| CVE-2026-41091 (Defender moteur, Link Following) | Levé après investigation (Spike 1) — moteur ≥ 1.1.26040.8 sur tout le parc. Voir §3.3 du rapport |
