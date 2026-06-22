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
* Nature : vulnérabilité tierce de symfony/runtime (SOUP IEC 62304 §9), aucun défaut du code OneOrtho.
* Mécanisme : contournement du correctif de CVE-2024-50340 — la protection précédemment ajoutée peut être contournée, réexposant la faille d'origine du composant runtime.
* Vecteur / conditions : exploitation via le point de bootstrap/réinitialisation du runtime ; conditions précises à confirmer dans l'advisory.
* Applicabilité OneOrtho : symfony/runtime présent dans composer.lock (branche 5.4.*) ; portail exposé sur Internet via IIS → chemin d'exposition direct.
* Impact potentiel : divulgation d'information ou altération du comportement runtime du portail. Portail non-DM mais hébergeur des 3 planificateurs — effet de bord à évaluer si exploitation confirmée.
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
* Nature : vulnérabilité tierce de symfony/routing (SOUP IEC 62304 §9), aucun défaut du code OneOrtho.
* Mécanisme : le générateur d'URL (UrlGenerator) ne valide pas correctement les contraintes de route, permettant d'injecter une URL ne respectant pas le motif attendu.
* Vecteur / conditions : injection d'une valeur forgée dans un paramètre de route ; conditions précises à confirmer dans l'advisory.
* Applicabilité OneOrtho : symfony/routing présent dans composer.lock ; portail exposé sur Internet via IIS → toute génération d'URL côté serveur est un point d'exposition potentiel.
* Impact potentiel : contournement de contrôle d'accès basé sur le motif de route, ou redirection/forge d'URL. Atteinte intégrité possible. Portail non-DM, effet de bord à évaluer.
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

Action attendue : application du Patch Tuesday 12/05/2026 sur l'ensemble du parc Windows Server. Validation post-patch sur staging avant prod.

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
* Nature : vulnérabilités de l'OS hôte Windows Server, environnement d'exécution / SOUP au sens IEC 62304 §5.7 — hors code OneOrtho.
* Mécanisme : 6 CVE permettant l'exécution de code à distance dans des composants système Windows Server (détail par CVE dans le MSRC Security Update Guide).
* Vecteur / conditions : RCE déclenchable à distance selon le composant visé ; gravité Critical Microsoft.
* Applicabilité OneOrtho : parc Windows Server 2016/2019/2022/2025 hétérogène, OS portant le portail public via IIS → exposition Internet directe.
* Impact potentiel : compromission de l'hôte → atteinte confidentialité/intégrité/disponibilité du portail et des données d'intervention hébergées. Effet de bord sur les DM hébergés à considérer.
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
* Nature : vulnérabilité tierce d'@angular/core (SOUP IEC 62304 §9), aucun défaut du code OneOrtho.
* Mécanisme : contournement de l'espace de noms des templates et composants dynamiques permettant l'injection de script (XSS) lors du rendu.
* Vecteur / conditions : données contrôlées par l'attaquant passant par certains patterns de rendu de template/composant dynamique ; exploitable côté navigateur.
* Applicabilité OneOrtho : @angular/core présent dans les 4 planificateurs ; modules livrés au navigateur du client → exposition Internet.
* Impact potentiel : exécution de script dans le contexte de la session utilisateur (vol de session, actions non sollicitées). Planificateurs sous périmètre DM — impact à tracer côté sécurité produit.
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
* Nature : vulnérabilité tierce de PHP-FPM (SOUP IEC 62304 §9), aucun défaut du code OneOrtho.
* Mécanisme : injection de script (XSS) dans la page de statut exposée par PHP-FPM (endpoint /status).
* Vecteur / conditions : nécessite que l'endpoint /status soit accessible ; non exposé publiquement dans une configuration par défaut.
* Applicabilité OneOrtho : PHP-FPM présent dans les images ; exposition conditionnée à la configuration IIS de production → à vérifier (cf. action).
* Impact potentiel : si endpoint exposé, XSS dans le contexte d'un opérateur consultant le statut. Impact limité tant que l'endpoint reste interne ; nul si non exposé.
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
* Nature : vulnérabilités de l'OS hôte Windows Server + .NET Framework, environnement d'exécution / SOUP au sens IEC 62304 §5.7 — hors code OneOrtho.
* Mécanisme : 62 CVE majoritairement d'élévation de privilèges, plus divulgation d'information, déni de service et contournement de fonction de sécurité (détail par CVE dans le MSRC).
* Vecteur / conditions : la plupart nécessitent un accès local préalable (EoP, Security Feature Bypass) → exploitation directe à distance limitée.
* Applicabilité OneOrtho : parc Windows Server 2016/2019/2022/2025 + .NET 3.5/4.7.2/4.8/4.8.1.
* Impact potentiel : escalade locale ou fuite d'information sur l'hôte ; surface réelle réduite par le prérequis d'accès local.
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
* Nature : vulnérabilités du SGBD MariaDB Community Server (SOUP IEC 62304 §9), hors code OneOrtho.
* Mécanisme : 13 CVE 2026, dont CVE-2026-49261 (CVSS 10.0), CVE-2026-48165/48163/44168 (8.0) et CVE-2026-32710 (8.6) ; détail technique dans community-server.md.
* Vecteur / conditions : à confirmer par CVE dans la doc MariaDB ; le score 10.0 de CVE-2026-49261 suggère une exploitation sans authentification ni interaction.
* Applicabilité OneOrtho : les 16 instances du parc sont en deçà des versions corrigées sur leurs 4 branches.
* Impact potentiel : compromission ou indisponibilité de la base → atteinte intégrité/confidentialité/disponibilité des données applicatives. Facteur atténuant : accès réseau interne requis.
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
* Nature : vulnérabilité tierce d'@angular/common (SOUP IEC 62304 §9), aucun défaut du code OneOrtho.
* Mécanisme : déni de service par épuisement mémoire (OOM) lors du formatage de nombres avec un paramètre digitsInfo malveillant.
* Vecteur / conditions : valeur digitsInfo contrôlée par l'attaquant atteignant un pipe/format de nombre ; effet côté navigateur du client.
* Applicabilité OneOrtho : @angular/common présent dans les 4 planificateurs ; modules livrés au navigateur → exposition Internet.
* Impact potentiel : plantage de l'onglet/module côté client (disponibilité). Pas d'atteinte serveur ni de données. Surface limitée au poste client.
```

**Raison du blocage/décision**
```
* Priorité retenue : P3 — matrice §4.4 : KEV non + sévérité Élevée mais DoS côté client navigateur (impact disponibilité limité au poste). SLA J+30 (06/07/2026).
* Décision particulière : aucune.
* Dépendances / blocages : à mutualiser avec le Ticket 4 (même montée Angular, mêmes branches 20.3 / 21.2).
```

---

## Spike 1 — Microsoft Defender (CVE-2026-41091 + CVE-2026-45498) — Investigation

**En-tête**
- Résumé : `[SEC][Investigation][WindowsServer] CVE-2026-41091 + CVE-2026-45498 — Defender actif ? (Threat Intel 2026-05)`
- Type : Spike / Investigation · Assigné : DevSecOps + équipe infrastructure · Échéance : 11/06/2026
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

**Analyse du bug**
```
* Nature : vulnérabilités du moteur antivirus Microsoft Defender (SOUP / composant système), hors code OneOrtho.
* Mécanisme : CVE-2026-41091 (Link Following → élévation de privilèges) et CVE-2026-45498 (déni de service) dans le Malware Protection Engine / Antimalware Platform.
* Vecteur / conditions : exploitation lors du traitement d'un fichier malveillant par Defender ; les deux CVE sont au CISA KEV (exploitation active confirmée) depuis le 20/05/2026.
* Applicabilité OneOrtho : conditionnée à la présence de Defender comme antivirus actif sur le parc → objet de cette investigation.
* Impact potentiel : si Defender actif, escalade de privilèges (CVE-2026-41091) ou indisponibilité de la protection (CVE-2026-45498) sur l'hôte du portail.
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

**Analyse du bug**
```
* Nature : vulnérabilités du runtime PHP (SOUP IEC 62304 §9), hors code OneOrtho.
* Mécanisme : 4 advisories php-src du 07/05/2026 affectant des fonctions standard (corruption mémoire / lecture hors limites / DoS).
* Vecteur / conditions : exploitable uniquement si la fonction concernée traite une entrée contrôlée par l'attaquant ; dépend de l'usage applicatif réel → objet de cette investigation.
* Applicabilité OneOrtho : PHP présent (runtime backend Symfony). Usage des fonctions impactées à confirmer par recherche de code.
* Impact potentiel : selon la fonction et l'usage, de nul (fonction non utilisée) à corruption mémoire / DoS du worker PHP. DOMNode::C14N() (Critique) à examiner en priorité si signatures XML utilisées.
```

**Raison du blocage/décision**
```
* Applicabilité non confirmée (usage des fonctions impactées) → investigation avant remédiation.
* Décision : priorité de l'éventuel ticket de remédiation = P3 par défaut (KEV non, exposition à qualifier). DOMNode::C14N() (Critique) à examiner en priorité. SLA investigation : 11/06/2026.
```

---

## Items SANS ticket (rappel)

| Item | Raison |
|------|--------|
| CVE-2026-45063 (Symfony X509Authenticator) | Levé après investigation — brique non utilisée + version corrigée. Voir §3.3 du rapport |
| CVE-2026-48805 + 48806 + 46636 (Twig sandbox) | Levé après investigation — sandbox non utilisé + version corrigée. Voir §3.3 du rapport |
