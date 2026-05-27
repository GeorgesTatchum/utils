# Recommandations questionnaire SmartOne — MCO infrastructure VM

**Contexte** : SmartOne (Jerry, Ornella) propose un accompagnement MCO sur l'infrastructure VM OneOrtho, en complément ou en remplacement partiel du périmètre couvert aujourd'hui par AVA6 (datacenter SYNAAPS Lyon).
**Cadre réglementaire** : HDS (référentiel ANS), MDR 2017/745, IEC 62304, RGPD, ANSSI RGS v2.1.
**Auteur** : DSI / Responsable infra OneOrtho.
**Date** : 2026-05-15.

---

## 1. Positionnement avant de répondre

Avant d'envoyer le questionnaire à SmartOne, trois prérequis stratégiques :

1. **Clarifier le périmètre vs AVA6**. SmartOne et AVA6 ne peuvent pas être tous deux RACI "R" sur le même asset. Il faut décider : SmartOne reprend le MCO système (intra-VM) pendant qu'AVA6 reste opérateur infra (hyperviseur, réseau DC, firewall, SIEM REDSOC), ou SmartOne se substitue partiellement. Cf. [MATRICE_RACI_05_INFRA_DATACENTER_AVA6_FIREWALL_ROUTER_SWITCH.md](MATRICE_RACI_05_INFRA_DATACENTER_AVA6_FIREWALL_ROUTER_SWITCH.md).
2. **Statut HDS de SmartOne**. SmartOne doit être déclaré comme sous-traitant ultérieur au sens HDS (art. 6 du référentiel ANS) et figurer dans la liste des sous-traitants notifiés aux patients/clients. Sans agrément ou attestation HDS de SmartOne, on ne peut pas leur confier d'accès aux VMs hébergeant des données de santé identifiantes. À demander en amont : attestation HDS ou ISO 27001 + ISO 27018 + engagement de conformité.
3. **Données traitées par SmartOne**. SmartOne ne doit en aucun cas accéder aux données patients applicatives (DSPROD, GDPROD imagerie). Le périmètre est l'OS et la couche infra, pas les bases de données métier. Ce point conditionne les clauses contractuelles (DPA, engagement de confidentialité renforcé, interdiction d'extraction).

---

## 2. Réponses recommandées, ligne par ligne

### 2.1 Topologie OS

**Windows** : la réponse "20 VMs / Server 2016, 2022, 2024, 2025" est correcte mais incomplète. À enrichir :
- Ventilation par version (Server 2016 = fin de support étendu 12/01/2027 : à isoler, à planifier en migration prioritaire).
- Rôle de chaque VM (AD, RDS, applicatif métier OneSoftware, base de données, build/CI, NAS frontal). Ne pas révéler de noms d'hôtes ni d'IP dans le questionnaire SmartOne.
- Criticité métier (P1 production patient, P2 préprod, P3 outillage interne). Indiquer combien de VMs P1 sans détailler.

**Linux** : "1 VM Ubuntu 24.04.3 LTS" : préciser le rôle (probablement runner CI/CD ou conteneurisation). Mentionner que la cible inclut une migration progressive Linux et conteneurisation, ce qui change le périmètre MCO attendu (cf. point 4 de l'échange Jerry).

**Action complémentaire** : produire un inventaire CMDB à transmettre sous NDA, pas dans le questionnaire commercial. La CMDB doit identifier les VMs traitant des données de santé pour appliquer un régime d'accès renforcé.

---

### 2.2 Accès réseau VM (internet vs config spécifique)

Réponse actuelle "VRAI accès internet suffisant" : **à nuancer**.

Recommandation :
- Réponse correcte sur le principe (les VMs sortent via le proxy/firewall AVA6, pas de routage spécifique intra-VM).
- Ajouter : "EPDR WatchGuard peut bloquer certaines installations, escalade fournisseur en place." OK.
- Préciser ce qui n'est PAS dit : les VMs sont derrière un WAF + reverse proxy, les flux sortants passent par un proxy web filtré, le tunnel IPSec site-to-site OneOrtho ↔ AVA6 doit rester transparent côté VM. SmartOne doit en être informé pour ne pas casser la chaîne lors d'une intervention.
- Demander à SmartOne : depuis où interviennent les opérateurs SmartOne ? (bastion ? VPN dédié ? PAM ?). Pas d'accès direct internet → VM sans passer par un point de contrôle journalisé.

---

### 2.3 Monitoring

Réponse "VRAI solution Grafana à mettre en place" : **à réviser**.

Recommandation :
- **Faux** : il existe déjà du Zabbix mis à disposition par AVA6 (alertes espace disque preprod/prod actives). Ne pas dire "à mettre en place" mais "Zabbix existant côté AVA6, à étendre / unifier".
- Décision à arbitrer avant réponse : (a) garder Zabbix AVA6 et y greffer SmartOne en consommateur, (b) déployer Grafana + exporters Prometheus en complément pour la couche système, (c) basculer entièrement sur Grafana opéré par SmartOne. L'option (b) est la plus sûre court terme, l'option (c) crée une dépendance commerciale forte.
- Exiger que la solution permette l'export des métriques et des alertes vers un SIEM tiers (corrélation avec REDSOC). Pas de boîte noire.
- Périmètre métriques minimum requis HDS : CPU, RAM, disque, IO, état services critiques, logs systèmes, échecs d'authentification, état antivirus EPDR, statut sauvegardes. Cf. [MATRICE_RACI_03_PARC_INFORMATIQUE_REVUE_COMPLETE.md](MATRICE_RACI_03_PARC_INFORMATIQUE_REVUE_COMPLETE.md).

---

### 2.4 Chemin d'escalation et SLA

Réponse "VRAI SmartOne n'intervient pas, prévient OneOrtho" : **trop restrictif**.

Recommandation : combiner les deux premières options.
- **Niveau 1 — alerte technique infra non métier** (ex : saturation /tmp, redémarrage agent, mise à jour mineure) : SmartOne intervient en autonomie, rapport d'intervention sous 24h.
- **Niveau 2 — incident impactant un service P1** (indispo VM applicative, base de données, AD) : SmartOne notifie immédiatement OneOrtho, intervention sur infra OS uniquement, jamais sur l'application métier.
- **Niveau 3 — incident de sécurité ou suspicion compromission** : escalade immédiate vers OneOrtho + RSSI, isolation possible de la VM, journalisation forensique préservée, pas de remédiation avant accord OneOrtho. Critique pour la chaîne de preuve HDS et la notification CNIL 72h.

**SLA à exiger** :
- GTI P1 : 30 minutes (24/7 si on prend du 24/7, sinon en HO uniquement).
- GTR P1 : 4 heures sur l'infra, hors application métier.
- GTI P2 : 4 heures HO.
- GTI P3 : jour ouvré suivant.
- Notification incident sécurité : 1 heure max vers OneOrtho RSSI.

À noter : la défaillance HDS n°6 du dossier ([ANALYSE_DEFAILLANCES_HDS_COMPLEMENTAIRE.md](ANALYSE_DEFAILLANCES_HDS_COMPLEMENTAIRE.md)) est précisément l'absence de SLA notification incident. SmartOne est l'occasion de le formaliser.

---

### 2.5 Volumétrie alertes/incidents

Réponse "FAUX, pas de chiffres" : OK, formulation à reprendre.

Recommandation :
- Indiquer factuel : monitoring Zabbix AVA6 en place depuis [date à confirmer], périmètre limité à l'espace disque preprod/prod aujourd'hui. Pas d'historique consolidé exploitable sur 12 mois.
- Engagement de fournir un baseline sur 3 mois après mise en place du monitoring étendu, comme préalable à la définition contractuelle du SLA.
- Ne pas s'engager sur un dimensionnement avant baseline : risque de sous-dimensionner et de payer en heures supplémentaires, ou de sur-dimensionner.

---

### 2.6 Couverture monitoring (horaires)

Réponse "VRAI horaires ouvrés lundi-vendredi" : **incohérent avec HDS et avec l'activité**.

Recommandation :
- **24/7 obligatoire pour la détection** (collecte métriques + alertes), c'est non négociable côté HDS et patient safety.
- **Astreinte humaine** : a minima HO lun-ven sur l'infra OS, **plus astreinte téléphonique soir et week-end pour les incidents P1 sécurité ou indispo**. C'est cohérent avec un éditeur sans usage clinique 24/7 strict, mais qui doit pouvoir réagir si un soignant utilise OneSoftware un samedi.
- Si SmartOne propose du 24/7 humain dédié, c'est cher et probablement disproportionné à ce stade : viser HO + astreinte P1 sur appel.
- Cohérence à vérifier avec REDSOC SOC qui est déjà 24/7 côté SIEM AVA6 : on n'a pas besoin d'un deuxième SOC, on a besoin d'une équipe MCO joignable.

---

### 2.7 Déploiement patchs de sécurité

Réponse actuelle "Autre, contact OneOrtho avant" : bonne intuition, à structurer.

Recommandation à substituer :
- **Critique** (CVSS ≥ 9.0 ou exploit public actif) : déploiement sous 48h après validation OneOrtho, fenêtre de maintenance dédiée hors heures d'usage clinique, rollback documenté.
- **Élevé** (CVSS 7.0-8.9) : déploiement sous 7 jours, fenêtre nocturne ou week-end selon impact.
- **Modéré / faible** : intégrés au cycle mensuel de mise à jour OS.
- **Toujours** : déploiement en préproduction avant production, validation fonctionnelle par OneOrtho avant bascule production, comité de validation hebdomadaire.

C'est l'option recommandée par SmartOne dans la note "patch critique 48h" du questionnaire. À cocher en complément de la case "Autre".

---

### 2.8 Mises à jour OS

Réponse "VRAI uniquement la nuit" : OK mais incomplet.

Recommandation :
- Préciser la fenêtre : par exemple nuit du dimanche au lundi 02:00-05:00 UTC+1.
- Exiger un préavis de 7 jours minimum, et un go/no-go OneOrtho avant exécution.
- Distinguer mises à jour mineures (rolling possible en HO sur une VM non P1) et majeures (saut Windows Server 2016 → 2022 par ex : projet dédié, pas une opération de MCO courante, à sortir du contrat MCO et facturer en mode projet).
- Aucune mise à jour majeure ne doit être exécutée sans test préalable en préprod sur une VM clone, avec exercice de rollback validé.

---

### 2.9 Délais déploiement patchs

Réponse actuelle "FAUX" sur les deux options : **incorrect au regard HDS**.

Recommandation : **VRAI, délais spécifiques** avec la grille de la section 2.7 ci-dessus. C'est une exigence implicite du référentiel HDS art. 9 (maintien en condition de sécurité), de la directive NIS2, et de l'ANSSI. Ne pas déclarer "pas de délais" : ce serait un point d'audit immédiat.

---

### 2.10 Solution PAM

Réponse "vide" : **à compléter, point sensible**.

Recommandation : cocher "Solution PAM à mettre en place" + commentaire :
- Apache Guacamole proposé par SmartOne convient pour la rebond + enregistrement de sessions, mais ne gère pas la rotation de secrets ni la mise à disposition just-in-time des comptes admin.
- Exigences HDS : enregistrement vidéo des sessions admin sur données de santé, rotation des mots de passe admin, comptes nominatifs MFA, traçabilité 1 an minimum (cf. [QUESTIONS_COMPLEMENTAIRES_REGLEMENTAIRES_Q41-Q61.md](QUESTIONS_COMPLEMENTAIRES_REGLEMENTAIRES_Q41-Q61.md)).
- Demander à SmartOne : couplage Guacamole + un coffre-fort de secrets (Vault, Bitwarden enterprise, Teleport), pas Guacamole seul.
- Évaluer en parallèle Teleport (open source, gère PAM + bastion + audit, plus complet que Guacamole).

---

### 2.11 Gestion sauvegardes

Réponse "vide" : **à statuer, critique**.

Recommandation :
- Aujourd'hui : sauvegardes opérées par AVA6 (14j online + 3 mois offline), tests de restauration non documentés. C'est une défaillance majeure (cf. [ANALYSE_DEFAILLANCES_HDS_COMPLEMENTAIRE.md](ANALYSE_DEFAILLANCES_HDS_COMPLEMENTAIRE.md)).
- Position recommandée : cocher "Gestion opérationnelle par SmartOne avec licence fournie par OneOrtho" OU rester chez AVA6 + faire opérer les tests de restauration trimestriels par SmartOne. La deuxième option évite un changement de prestataire de stockage mais introduit SmartOne dans la chaîne de validation.
- Exigences à formaliser dans tous les cas : RPO max 24h pour P1, RTO 4h pour P1, test de restauration mensuel sur au moins une VM tirée au sort, rapport de test conservé 5 ans.

---

### 2.12 Solution de backup

Cohérent avec 2.11. Si AVA6 garde le backup : "solution existante, gérée par AVA6, périmètre à clarifier dans tripartite". Si SmartOne reprend : Veeam Backup & Replication est le standard sur du Windows lourd, Bacula/Restic sur Linux. Exiger chiffrement at-rest des sauvegardes (clé OneOrtho), immutabilité (offline ou WORM), test de restauration documenté.

---

### 2.13 Déploiement nouvelles VMs

Réponse "vide" : **à statuer**.

Recommandation : cocher la première option (déploiement par SmartOne avec outils de monitoring + EPDR par défaut, OneOrtho déploie ensuite l'applicatif).
- Volumétrie : faible, 2 à 5 nouvelles VMs par an typiquement, pic possible sur projet de migration Linux/conteneurisation.
- Exigence : provisionnement via Infrastructure-as-Code (Terraform / Ansible) versionné dans le dépôt OneOrtho, pas via clics manuels. Réutilisable, auditable, conforme IEC 62304 (traçabilité changement infra).

---

### 2.14 Image OS durcie

Réponse "vide" : **à cocher Oui, point structurant**.

Recommandation : "Oui, configuration durcie suivant CIS Benchmark niveau 1 minimum, niveau 2 sur VMs P1 traitant des données de santé." C'est attendu en audit HDS.

---

### 2.15 Maintenance de l'image

Réponse "vide" : **maintenance par SmartOne**.

Justification : OneOrtho doit garder le focus produit (IEC 62304 SOUP, logiciel dispositif médical), SmartOne porte le durcissement et la veille CIS. Mais : la baseline durcie doit être validée par le RSSI OneOrtho avant déploiement, et la documentation de l'image doit être livrée à OneOrtho (clause de réversibilité).

---

### 2.16 Activités complémentaires

Réponse "vide" : **Oui, à compléter**.

Recommandation, périmètre complémentaire à confier :
- Gestion du cycle de vie des certificats TLS internes (Let's Encrypt ou AC privée).
- Maintenance de l'Active Directory (comptes de service, GPO, audit).
- Exercices de PRA / PCA annuels, dont test de bascule sur un site secondaire si applicable.
- Veille CVE ciblée sur le stack (Windows Server, Apache, IIS, MariaDB/MSSQL, runtime applicatifs).
- Revue trimestrielle de la posture sécurité (rapport).
- Accompagnement migration Linux et conteneurisation (point 2 et 3 de l'échange Jerry) : à scoper séparément, hors MCO courant.

Hors périmètre SmartOne explicite à acter :
- Aucun accès aux bases applicatives (DSPROD, GDPROD).
- Aucune intervention sur le code applicatif OneSoftware.
- Aucune extraction de données patient.

---

### 2.17 Ticketing

Réponse "VRAI JIRA existant" : OK. Préciser :
- Projet JIRA dédié à créer pour les tickets SmartOne, séparé du backlog produit.
- Schéma de workflow à co-construire (états, SLA timer, escalade automatique).
- Webhook ou API pour ingestion des alertes monitoring vers tickets.

---

## 3. Questions à reposer à SmartOne en parallèle

Avant signature, exiger les réponses à :

1. SmartOne est-il agréé HDS (hébergeur ou sous-traitant ultérieur d'un hébergeur) ? Si non, sur quelle base contractuelle peut-il opérer sur des VMs traitant des données de santé ?
2. Liste des sous-traitants SmartOne (offshore éventuel ? Magrheb, Europe de l'Est, Asie ?). Le règlement HDS impose la transparence et la localisation UE par défaut.
3. Localisation physique des opérateurs MCO SmartOne (UE only ? télétravail ?).
4. Politique de gestion des comptes admin côté SmartOne (rotation, MFA, isolation par client, durée de conservation des sessions enregistrées).
5. Cyber-assurance SmartOne : plafond, exclusions, couverture en cas d'incident HDS.
6. Référentiels certifiés : ISO 27001 ? SecNumCloud ? HDS ? Date de dernier audit, périmètre.
7. Plan de réversibilité : que se passe-t-il si OneOrtho rompt le contrat ? Délai de transfert, format des livrables (CMDB, images, runbooks).
8. Droit d'audit OneOrtho (clause obligatoire HDS, défaillance n°12 du dossier).
9. Notification d'incident de sécurité : engagement contractuel sous combien d'heures ? Format ? Canal ?
10. Sur Kubernetes : SmartOne ou son partenaire est-il certifié CKA/CKS ? Quelle expérience sur clusters multi-tenants en santé ?

---

## 4. Articulation avec les matrices RACI existantes

Une fois SmartOne intégré, les matrices RACI suivantes devront être révisées :

| Document | Impact |
|---|---|
| [MATRICE_RACI_03_PARC_INFORMATIQUE_REVUE_COMPLETE.md](MATRICE_RACI_03_PARC_INFORMATIQUE_REVUE_COMPLETE.md) | Ajouter SmartOne comme R sur MCO VM, AVA6 reste R sur hyperviseur. |
| [MATRICE_RACI_04_COUCHE_SECURITE_SIEM_WAF_EPDR_PROXY.md](MATRICE_RACI_04_COUCHE_SECURITE_SIEM_WAF_EPDR_PROXY.md) | SmartOne C ou I sur SIEM (consomme les alertes), pas R. REDSOC reste R sur SIEM. |
| [MATRICE_RACI_05_INFRA_DATACENTER_AVA6_FIREWALL_ROUTER_SWITCH.md](MATRICE_RACI_05_INFRA_DATACENTER_AVA6_FIREWALL_ROUTER_SWITCH.md) | Inchangé, périmètre AVA6 préservé. |

Risque : double facturation sur les couches de contact (monitoring, ticketing, EPDR). Cartographier explicitement avant signature.

---

## 5. Synthèse risques / écarts à clore avant signature

| Risque | Mitigation |
|---|---|
| SmartOne non agréé HDS | Bloquant. Attestation à exiger avant tout accès VM. |
| Chevauchement avec AVA6 | Atelier tripartite OneOrtho-AVA6-SmartOne avant signature. |
| Dépendance Grafana opéré par SmartOne | Garder le code IaC du monitoring dans le dépôt OneOrtho. |
| Sessions admin non journalisées | PAM avec enregistrement vidéo, conservation 1 an. |
| Pas de test de restauration | Exercice mensuel contractuel, rapport au RSSI. |
| Données patient exposées à SmartOne | Clause d'interdiction d'accès BDD, contrôle technique via PAM. |
| SLA flous | Grille GTI/GTR par priorité formalisée en annexe contractuelle. |
| Réversibilité | Plan de sortie écrit, livrables techniques cités, délai de transfert. |

---

## 6. Points pour le point Jerry (Directeur de site SmartOne)

À porter à l'ordre du jour, en plus du questionnaire :

1. Statut HDS SmartOne et sous-traitants.
2. Frontière SmartOne / AVA6 / REDSOC.
3. Modèle d'engagement Kubernetes (Rancher proposé) : POC chiffré, pas un engagement immédiat. Comparer avec une offre Kubernetes managée pure (OVH Managed Kubernetes, Scaleway Kapsule, AWS EKS) avant arbitrage.
4. Hébergement HIPAA US : à découpler du sujet MCO France. Si OneOrtho vise le marché US, c'est un projet à part avec un hébergeur US certifié (AWS BAA, Google Cloud HIPAA, Azure).
5. CVs DevOps : critères de recrutement à aligner sur le besoin réel (Linux, conteneurisation, CI/CD GitLab, IEC 62304, anglais technique).
6. Modèle économique : régie, forfait, ou hybride. Pour du MCO, le forfait est plus prévisible mais demande un baseline volumétrique d'abord (cf. 2.5).

---

**Prochaines étapes recommandées** :
1. Valider ce document en interne (RSSI, Direction Technique).
2. Réviser le questionnaire avec les réponses ci-dessus.
3. Envoyer le questionnaire complété + les 10 questions de la section 3.
4. Préparer le point Jerry avec un ordre du jour calé sur la section 6.
