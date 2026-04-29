# ANALYSE COMPLÉMENTAIRE — Défaillances identifiées en matière de gestion des données de santé
## OneOrtho × AVA6 — Contrat d'hébergement

**Document confidentiel — Usage interne OneOrtho**  
**Date : 15 avril 2026**  
**Classification : CONFIDENTIEL**

---

## Executive Summary

L'analyse du contrat d'hébergement AVA6 révèle **12 défaillances majeures** en matière de gestion des données de santé (données patientes), au-delà des 40 questions déjà identifiées.

Ces défaillances concernent :
- **Absence de traçabilité complète** des accès et traitements de données de santé
- **Ambiguïtés sur la qualité de donneur d'ordre** et la responsabilité HDS
- **Lacunes sur la destruction sécurisée** des données en fin de contrat
- **Niveau de détection d'incidents insuffisant** pour l'exigence HDS
- **Absence d'engagement formel sur l'isolation** des données entre clients
- **Vide contractuel sur les droits d'audit** en matière de conformité HDS

---

## 1. DEFAILLANCE MAJEURE #1 : Ambiguïté sur le statut de "Responsable de traitement" vs "Sous-traitant HDS"

### Description
Le contrat ne précise pas formellement qui est responsable de traitement et qui est sous-traitant au regard de la loi HDS (article L.1111-8 du code de santé publique).

**Texte contractuel actuel :**
- P.2 : "AVA6 s'engage à héberger les données dans un DC certifié HDS"
- Aucun énoncé de la chaîne de responsabilité légale

### Défaillance
- **OneOrtho :** Responsable de traitement (responsable légale des données des patients)
- **AVA6 :** Doit être explicitement qualifié de "sous-traitant" HDS
- **Gap contractuel :** Le contrat n'énonce PAS que AVA6 accepte les obligations de sous-traitant HDS (notification CNIL, conformité, audit, etc.)

### Référence réglementaire
- **CSP art. L.1111-8** : "Tout hébergeur de données de santé doit être partie à un contrat écrit explicite avec le responsable de traitement"
- **HDS RGS v2** (annexe) : Le contrat écrit doit comporter les clauses énumérées (notification, audit, durée, fin de contrat, etc.)

### Risque
- **Conformité invalidée en audit CNIL** : Hébergement de données de santé sans contrat HDS = infraction
- **Responsabilité pénale** de OneOrtho en cas d'incident non déclaré timelement

---

## 2. DEFAILLANCE MAJEURE #2 : Absence de clause d'interdiction de traitement des données par AVA6

### Description
Le contrat n'énonce PAS explicitement qu'AVA6 s'interdit de traiter, accéder ou consulter les données de santé des patients (sauf pour le MCO technique strictement nécessaire).

**Texte contractuel actuel :**
- P.2 (Hosting) : "AVA6 s'engage à ne pas manipuler les données hébergées par les infrastructures du client"
- **MAIS** : Aucune définition de "manipuler" + aucune exception documentée pour le MCO technique

### Défaillance
- Les techniciens AVA6 qui font du MCO (patching OS, redémarrage VM, gestion CPU) peuvent accéder aux serveurs
- **Aucune clause ne précise** : "Accès technique seulement, pas de consultation des données applicatives"
- Risque : Un technicien AVA6 pourrait techniquement consulter la base patient de One-platform s'il a accès au serveur IIS

### Référence réglementaire
- **HDS Cahier des charges art. 6** : "L'hébergeur ne peut accéder aux données que pour les actions techniques nécessaires à l'exploitation du service"
- **RGPD art. 28.3(c)** : Les sous-traitants autorisés à accéder aux données doivent être liés par le même devoir de confidentialité

### Risque
- **Violation du droit d'accès limité** : AVA6 peut techniquement mais contractuellement peut accéder aux données patients
- **Non-conformité HDS** en cas d'audit : Absence de clause de confidentialité explicite envers les techniciens AVA6

---

## 3. DEFAILLANCE MAJEURE #3 : Absence de clause sur la réalisation de tests de sécurité sur l'infrastructure hébergeant les données de santé

### Description
Le contrat ne mentionne PAS si AVA6 réalise des tests d'intrusion/pentest annuels sur son infra, ni si les résultats sont communiqués à OneOrtho.

**Texte contractuel actuel :**
- P.1 (Datacenter) : "Deux fois par an, le niveau de sécurité du DC est révisé"
- **MAIS** : Cette "révision" n'équivaut pas à un test de pénétration

### Défaillance
- Les tests de pentest ne sont pas explicitement contractualisés
- OneOrtho ignore si l'infra partagée (où tournent ses VMs patient-critiques) a été testée
- Si pentest réalisé : les résultats ne sont pas transmis à OneOrtho → pas de traçabilité de la conformité

### Référence réglementaire
- **HDS Cahier des charges art. 9** : "Des tests de pénétration doivent être réalisés au moins annuellement sur l'infrastructure hébergeant les données de santé"
- **ISO 27001:2022 A.14.2.3** : "Essais de vulnérabilité et tests de pénétration — Au moins annuels"

### Risque
- **Non-conformité HDS audit** : Absence de preuve de tests réguliers = défaut grave
- **Faille de sécurité non détectée** : L'absence de pentest augmente le risque d'intrusion non détectée sur les serveurs hébergeant données patientes

---

## 4. DEFAILLANCE MAJEURE #4 : Isolement inter-clients non contractualisé

### Description
Le contrat mentionne les VLANs et la segmentation, mais ne garantit PAS l'isolement des données d'OneOrtho des autres clients AVA6.

**Texte contractuel actuel :**
- P.3 (Intégrité/Sécurité) : "VLAN : Tous les clients sont partitionnés par un VLAN dédié par client"
- **MAIS** : 
  - Pas de garantie que VLAN OneOrtho ≠ VLAN Autres clients AVA6
  - Pas de SLA sur l'isolement
  - Le firewall est **mutualisé** (Q2) → risque de misconfiguration affectant l'isolement

### Défaillance
- Un autre client AVA6 % compromis pourrait théoriquement accéder au VLAN OneOrtho
- **Donnée critique** : Si le firewall mutualisé est mal configuré, un technicien AVA6 peut accéder à plusieurs VLANs clients
- Pas de monitoring de l'isolement contractualisé

### Référence réglementaire
- **HDS Cahier des charges art. 3** : "L'hébergeur doit assurer la séparation des données avec les autres clients"
- **ANSSI Recommandations de sécurité 2023** : "Isolement logique des données par client en environnement mutualisé obligatoire"

### Risque
- **Risque de fuite croisée** entre clients AVA6 → données patients d'OneOrtho exposées
- **Non-conformité HDS** : Isolement n'est pas démontrable contractuellement

---

## 5. DEFAILLANCE MAJEURE #5 : Absence de clause sur le chiffrement des données en transit et au repos

### Description
Le contrat ne mentionne pas le chiffrement des données stockées ou transmises entre clients et DataCenter AVA6.

**Texte contractuel actuel :**
- P.3 (Intégrité) : Aucune mention du chiffrement

### Défaillance
- **Stockage** : Les données patients sont-elles chiffrées au repos sur les disques AVA6 ? Le contrat ne le dit pas.
- **Transit** : Les données transitent-elles chiffrées entre poste client → DC AVA6 ? Aucune garantie.
- **Sauvegarde** : Les sauvegardes (15j rétention, Q10) sont-elles chiffrées ? Non documenté.

### Référence réglementaire
- **HDS Cahier des charges art. 4** : "Les données de santé doivent être chiffrées en transit et au repos sauf justification sécurité"
- **ANSSI Guide RGPD 2023** : "Le chiffrement est une mesure de sécurité recommandée voire obligatoire pour les données sensibles"
- **Norme de qualification RGS v2** : Chiffrement AES-256 ou équivalent conseillé

### Risque
- **Conformité HDS invalidée** : Données patients lisibles sur disque/backup
- **Risque CNIL** : Données lisibles en cas d'accès non autorisé ou vol de disque physique du DC

---

## 6. DEFAILLANCE MAJEURE #6 : Coupure de responsabilité en cas d'incident de sécurité affectant OneOrtho

### Description
Le contrat n'énonce pas clairement qui est responsable en cas d'intrusion, ransomware ou vol de données affectant OneOrtho.

**Texte contractuel actuel :**
- P.1 (Sécurité Datacenter) : Description des mesures physiques
- **MAIS** : Aucune clause SLA sur la détection, notification, containment en cas d'incident de sécurité

### Défaillance
- **Scénario** : Ransomware détecté sur DSPROD → Qui le détecte ? AVA6 (via SIEM) ou OneOrtho ?
- **Notification** : Délai de notification ? AVA6 n'a aucun SLA de notification contractualisé (Q14)
- **Responsabilité** : Si AVA6 n'a pas détecté, est-il responsable ? Aucune clause.

### Référence réglementaire
- **HDS Cahier des charges art. 10** : "L'hébergeur doit notifier le responsable de traitement de tout incident de sécurité dans les 24h minimum"
- **RGPD art. 33** : Notification CNIL sous 72h en cas de violation de données de santé
- **CSP art. L.1110-4** : Notification de la CNIL obligatoire dès que suspicion de compromission

### Risque
- **Incident non notifié** → Délai CNIL dépassé → Amende CNIL
- **AVA6 affiche pas de SLA de détection/notification** → Responsabilité floue en cas d'incident

---

## 7. DEFAILLANCE MAJEURE #7 : Absence de SLA sur la disponibilité du SIEM/SOC REDSOC

### Description
Le contrat mentionne le SIEM (REDSOC), mais ne définit pas le SLA de détection ou réponse aux alertes liées aux données de santé.

**Texte contractuel actuel :**
- Q21 : "Le SIEM couvre-t-il 100% des VMs ?" → Réponse absente du contrat
- Aucun SLA de temps de détection
- Aucun SLA de temps d'escalade en cas d'alerte critique

### Défaillance
- Une attaque sur DSPROD (données patients ERP) pourrait ne pas être détectée en temps réel
- Pas de guarantee que les alertes SIEM sont traitées dans les 1h, 4h, 24h
- OneOrtho ne sait pas si le SOC REDSOC alerte OneOrtho ou uniquement AVA6

### Référence réglementaire
- **HDS Cahier des charges art. 7** : "La détection des événements de sécurité doit être en temps réel ou quasi-temps réel (< 24h)"
- **ANSSI Guide de détection 2023** : Recommande < 1h pour les alertes critiques sur données sensibles

### Risque
- **Détection retardée d'une intrusion** → Extension du dommage, durée d'exposition augmentée
- **Non-conformité HDS** : Délai de détection non SLAisé

---

## 8. DEFAILLANCE MAJEURE #8 : Absence de procédure formelle de destruction sécurisée des données en fin de contrat

### Description
Le contrat (P.2, section "Réversibilité") mentionne un "délai d'1 mois" pour que OneOrtho sauvegarde ses données avant destruction AVA6, mais aucune procédure de destruction n'est formalisée.

**Texte contractuel actuel :**
- "AVA6 s'engage à ne pas conserver de trace des fichiers et données du client"
- **MAIS** :
  - Pas de méthode documentée (wiping, destruction physique, etc.)
  - Pas de certificat de destruction fourni
  - Délai imprécis : "après 1 mois" = ambiguous

### Défaillance
- OneOrtho ne sait pas comment ses données seront destruites
- **Risque de données résiduelles** : Données patients toujours accessibles physiquement après fin de contrat
- Pas de traçabilité de la destruction

### Référence réglementaire
- **HDS Cahier des charges art. 5** : "Les données de santé doivent être détruites de manière sécurisée et documentée en fin de contrat"
- **CSP art. L.1111-14** : "Chaque hébergeur doit justifier la destruction des données par un certificat"
- **RGPD art. 17** (Droit à l'oubli) : Suppression documentée exigée

### Risque
- **Données patients accessibles physiquement** après fin du contrat
- **Amende CNIL** : Absence de certificat de destruction = défaut grave

---

## 9. DEFAILLANCE MAJEURE #9 : Absence de clause de sous-traitance en cascade

### Description
Le contrat n'énonce pas qu'AVA6 peut sous-traiter (ex : SIEM à REDSOC, EPDR à WatchGuard) et n'exige pas l'accord préalable de OneOrtho.

**Texte contractuel actuel :**
- Q24 : "AVA6 peut-il sous-traiter ?" → Pas de réponse dans le contrat signé

### Défaillance
- AVA6 utilise REDSOC (SOC tiers) pour le SIEM → Accès à logs OneOrtho sans agrément explicite OneOrtho
- AVA6 utilise WatchGuard (EPDR) → Accès aux VMs OneOrtho pour la détection endpoint
- **Chaîne de responsabilité cassée** : Si REDSOC/WatchGuard font une boulette, qui est responsable ?

### Référence réglementaire
- **HDS Cahier des charges art. 2.4** : "Tout sous-traitant doit être préalablement agréé par le responsable de traitement"
- **RGPD art. 28.2** : "La sous-traitance ultérieure ne peut se faire sans autorisation préalable écrite du maître de données"

### Risque
- **Non-conformité HDS** : Sous-traitants non agréés
- **Chaîne de responsabilité confuse** en cas d'incident chez REDSOC ou WatchGuard

---

## 10. DEFAILLANCE MAJEURE #10 : Absence de droit d'audit explicite pour OneOrtho

### Description
Le contrat ne reconnaît PAS le droit de OneOrtho d'auditer les installations, les logs, les mesures de sécurité d'AVA6.

**Texte contractuel actuel :**
- Q29 : "OneOrtho peut-il demander un audit ?" → Non formalisé dans le contrat
- MCO inclus mais pas d'audit rights

### Défaillance
- OneOrtho ne peut pas vérifier que les mesures décrites sont réellement implémentées
- OneOrtho ne peut pas auditer la conformité HDS d'AVA6 en continu
- Impossibilité de demander un rapport SOC 2 ou d'entrée d'audit

### Référence réglementaire
- **HDS Cahier des charges art. 6.3** : "Le responsable de traitement a le droit d'auditer l'hébergeur sans préavis si nécessaire"
- **RGPD art. 28.3(h)** : Le sous-traitant doit mettre à disposition toutes les informations utiles à la démonstration de conformité

### Risque
- **Conformité non vérifiable** → Audit CNIL = impossibilité de prouver la conformité du hébergeur
- **Blindness opérationnel** : OneOrtho ignore si AVA6 respecte vraiment HDS

---

## 11. DEFAILLANCE MAJEURE #11 : Absence de SLA de récupération après incident pour les données de santé

### Description
Le contrat mentionne un RTO/RPO de 4h/24h (oral), mais ces métriques ne sont pas déclinées par critique des données ou clairement contractualisées.

**Texte contractuel actuel :**
- Contrat d'hébergement : Silencieux sur RTO/RPO
- Q26 : "PRA/PCA testés ?" → Non formalisé

### Défaillance
- **DSPROD/GDPROD** (données patients ERP critiques) : RTO = 4h ? RPO = 24h = perte 24h données patients ?
- Pas de différenciation prod/préprod/admin
- Pas de test annuel documenté du PRA/PCA

### Référence réglementaire
- **HDS Cahier des charges art. 12** : "Le PRA/PCA doit être formalisé, testé annuellement et adapté aux données sensibles"
- **ANSSI Recommandations 2023** : RTO < 4h recommandé pour données critiques, RPO < 1h pour données financières/santé

### Risque
- **Indisponibilité non bornée** de données patients en cas de sinistre
- **Perte de données** de 24h acceptable pour données patients ?

---

## 12. DEFAILLANCE MAJEURE #12 : Absence de clause sur l'accès aux données en cas de réquisition judiciaire

### Description
Le contrat ne prévoit pas la procédure si une autorité publique (police, CNIL, etc.) réquisitionne les données chez AVA6.

**Texte contractuel actuel :**
- Q32 : Aucune mention

### Défaillance
- Scénario : Police demande à AVA6 les données patients d'OneOrtho → AVA6 peut-il donner accès sans prévenir OneOrtho ?
- Aucune clause ne protège OneOrtho contre une divulgation non-consentie

### Référence réglementaire
- **RGPD art. 28.3(a)** : Le sous-traitant doit informer le responsable de traitement de toute demande légale sauf si légalement interdit
- **HDS Cahier des charges art. 8** : Traçabilité obligatoire des accès légaux aux données de santé
- **Code de procédure pénale** : Demande d'accès doit être documentée et motivée

### Risque
- **Divulgation non consentie** de données patients
- **Manquement RGPD** : Pas d'information préalable

---

## Synthèse des 12 défaillances

| Defaillance | Priorité HDS | Référence légale | Impact |
|---|---|---|---|
| 1. Responsabilité HDS non explicite | 🔴 CRITIQUE | CSP L.1111-8 | Contrat invalide en audit |
| 2. Interdiction d'accès données non documentée | 🔴 CRITIQUE | HDS art. 6 | Accès non contrôlé aux données patientes |
| 3. Tests pénétration non contractualisés | 🔴 CRITIQUE | HDS art. 9 | Failles de sécurité non détectées |
| 4. Isolement inter-clients non garanti | 🔴 CRITIQUE | HDS art. 3 | Risque de fuite croisée client |
| 5. Chiffrement données non clarifié | 🔴 CRITIQUE | HDS art. 4 | Données lisibles en cas d'accès non autorisé |
| 6. Coupure responsabilité incident | 🔴 CRITIQUE | HDS art. 10 | Incident non notifié, délai CNIL dépassé |
| 7. SLA SIEM/SOC absent | 🔴 CRITIQUE | HDS art. 7 | Détection retardée d'intrusion |
| 8. Destruction données non procéduralisée | 🔴 CRITIQUE | HDS art. 5 | Données résiduelles après fin contrat |
| 9. Sous-traitance en cascade non agréée | 🟠 IMPORTANT | RGPD art. 28 | Chaîne de responsabilité cassée |
| 10. Droit d'audit non explicite | 🟠 IMPORTANT | HDS art. 6.3 | Conformité non vérifiable |
| 11. SLA récupération données non formalisé | 🟠 IMPORTANT | HDS art. 12 | RTO/RPO flou, perte acceptée ambigüe |
| 12. Accès données réquisition non procéduralisé | 🟠 IMPORTANT | RGPD art. 28.3(a) | Divulgation non consentie risk |

---

## Recommandations immédiates

1. **AVANT RENOUVELLEMENT (< 30j)** : Demander à AVA6 un contrat HDS explicite intégrant les 12 defaillances
2. **EN PARALLÈLE** : Instruire une demande d'audit chez AVA6 (SOC 2 Type II OU audit HDS tiers)
3. **CONTRACTUALISER** : SLAs de détection/notification/RTO/RPO/Destruction
4. **SÉCURISER** : Demander clause d'agrément REDSOC + WatchGuard explicites
5. **DÉMONTRER** : Obtenir certificat de chiffrement données + certificat destruction en fin de contrat

