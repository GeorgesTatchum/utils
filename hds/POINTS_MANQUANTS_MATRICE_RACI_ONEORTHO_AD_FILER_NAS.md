# POINTS MANQUANTS — Matrice RACI Infra OneOrtho AD, Filer, NAS
## Analyse basée sur contrat AVA6 + questionnaires HDS + défaillances identifiées

**Date :** 20 avril 2026  
**Classification :** CONFIDENTIEL

---

## 📋 CONTEXTE — Composants critiques infrastructure OneOrtho on-site

> **AD01 / AD02** : Contrôleurs de domaine (cœur d'accès infrastructure)  
> **Filer (ONEORTHO-FILER, WS 2016)** : Stockage partagé 3950 Go (données partagées + archiv)  
> **Serveur CALCUL (Ubuntu)** : Modèles IA segmentation médicale DICOM  
> **Contexte HDS** : Ces données ne sont PAS hébergées chez AVA6 → Responsabilité OneOrtho 100%

---

## 🔑 **CLARIFICATION RÔLES RACI (CRITIQUE)**

### Distinction acteurs — Infrastructure On-Site OneOrtho

| Acteur | Responsabilité | Rôle Type RACI |
|---|---|---|
| **IT Manager OneOrtho** | Pilote IT responsable MCO on-site | **R/A** (Réalise + Accountable légal) |
| **Comité technique OneOrtho** | Groupe collectif techs lead on-site | **C/A** (Consulté + Approuve décisions strat) |
| **AVA6 Infra/MCO** | Prestataire infrastructure externalisée | **C/R** (Consulté + gère backups externalisés) |
| **AVA6 SOC (REDSOC)** | Prestataire sécurité/monitoring | **R/I** (Détection + informé incidents) |

### Application au Filer & AD On-Site

> **Responsabilité Filer (données on-site OneOrtho):**
> - **IT Manager** = Exécute les opérations techniques (backup, restauration, destruction)
> - **Comité technique** = Groupe de techs lead = Approuve avant action (destruction, changements majeurs)
> - **AVA6 Infra/MCO** = Gère les **backups externalisés** (Backup As a Service chez AVA6)
> - **AVA6 SOC** = Détecte anomalies Filer (alertes SIEM)

> **Important:** 
> - **"Comité technique"** = pas une personne unique, mais collectif de techs lead OneOrtho
> - Ne RÉALISE jamais, seul le **IT Manager** exécute
> - APPROUVE/CONSULTE avant exécution actions sensibles

### Correction des activités "Destruction"

**Incohérence identifiée :** Activité "Certificat destruction Filer avec hashes pré/post destruction" avait R sur Comité technique (INCORRECT).

**Correction appliquée :**
- **R/A** = IT Manager OneOrtho (exécute + responsable légal + audit)
- **R** = AVA6 Infra/MCO (destruction backups externalisés)
- **C** = Comité technique OneOrtho (approuve avant destruction)
- **I** = AVA6 SOC (informé après destruction)

---

## 🔴 DOMAINE 1 : TRAÇABILITÉ & AUDIT ACCÈS AD (Défaillance #2 + Q41-Q43)

### ⚠️ **À AJOUTER — Nouvelle section 7. Audit & Traçabilité AD**

| Domaine / Groupe | Processus / Activité | IT Manager OneOrtho | Comité technique | AVA6 Infra/MCO | AVA6 SOC (REDSOC) |
|---|---|---|---|---|---|
| **7. Audit & Traçabilité AD** | **Audit logs d'authentification AD (tentatives brutes, MFA bypass)** | **A** | **I** | **C** | **R** |
| **7. Audit & Traçabilité AD** | **Monitoring accès admin AD (connexions RDP comptes privilégiés)** | **R/A** | **C** | **C** | **R** |
| **7. Audit & Traçabilité AD** | **Audit logs modification GPO (qui change quoi, quand, pourquoi)** | **R/A** | **C** | **C** | **C** |
| **7. Audit & Traçabilité AD** | **Audit logs suppression / déverrouillage comptes (traçabilité)** | **R/A** | **C** | **C** | **I** |
| **7. Audit & Traçabilité AD** | **Audit logs modification appartenances groupes sécurité** | **R/A** | **C** | **C** | **I** |
| **7. Audit & Traçabilité AD** | **Rétention logs AD minimum 1 an (exigence HDS art. 6)** | **R/A** | **C** | **R** | |
| **7. Audit & Traçabilité AD** | **Transmission logs authentification AD vers SIEM AVA6 (enrichissement détection)** | **R/A** | **C** | **R** | **R** |

**Justification :**
- Matrice omet monitoring continu authentification AD
- HDS art. 6 = traçabilité obligatoire accès administrateur
- Q41-Q43 : Accès données patient via AD → logs obligatoires
- Logs AD doivent alimenter SIEM pour corrélation anomalies (défaillance #7)
- Absence rétention officialisée = audit imprécis

---

## 🔴 DOMAINE 2 : TESTS SÉCURITÉ & PENTEST AD/FILER (Défaillance #3 + HDS art. 9)

### ⚠️ **À AJOUTER — Nouvelle section 8. Tests Sécurité AD/Filer**

| Domaine / Groupe | Processus / Activité | IT Manager OneOrtho | Comité technique | AVA6 Infra/MCO | AVA6 SOC (REDSOC) |
|---|---|---|---|---|---|
| **8. Tests Sécurité** | **Tests pénétration AD annuels (escalade privilèges, Golden Ticket)** | **R** | **A** | **C** | **C** |
| **8. Tests Sécurité** | **Scan vulnérabilité AD controllers (CVE-2023-28XXX, défaillances Kerberos)** | **R** | **A** | **C** | **C** |
| **8. Tests Sécurité** | **Audit hardening AD (MIERCOM/Microsoft baseline CIS)** | **R** | **A** | **C** | **C** |
| **8. Tests Sécurité** | **Test isolement Filer vs PC OneOrtho (segmentation réseau)** | **R** | **A** | **C** | **C** |
| **8. Tests Sécurité** | **Scan vulnérabilité Filer (OS WS 2016 EOL 2027)** | **R** | **A** | **C** | **C** |
| **8. Tests Sécurité** | **Test restrictivité permissions NTFS Filer (moindre privilège)** | **R** | **A** | **C** | **I** |
| **8. Tests Sécurité** | **Rapport pentest annuel communicable audit CNIL** | **R** | **A** | **C** | **I** |

**Justification :**
- Defaillance #3 : Pentest pas contractualisé (inclus dans MCO d'AVA6 mais pas OneOrtho on-site)
- HDS art. 9 = tests intrusion annuels obligatoires
- AD = cœur accès données patient → cible prioritaire pentest
- Filer Windows 2016 = version old (EOL 2027) → risques sécurité élevés
- Tests doivent être formalisés avec reporting

---

## 🔴 DOMAINE 3 : CHIFFREMENT DONNÉES FILER & AD (Défaillance #5)

### ⚠️ **À AJOUTER — Nouvelle section 9. Chiffrement Données On-Site**

| Domaine / Groupe | Processus / Activité | IT Manager OneOrtho | Comité technique | AVA6 Infra/MCO | AVA6 SOC (REDSOC) |
|---|---|---|---|---|---|
| **9. Chiffrement** | **Chiffrement partages Filer contenant données sensibles (BitLocker ?)** | **R/A** | **C** | **C** | |
| **9. Chiffrement** | **Chiffrement disque OS Filer (WS 2016)** | **R/A** | **C** | **C** | |
| **9. Chiffrement** | **Gestion clés chiffrement Filer (stockage, rotation)** | **R/A** | **C** | **C** | |
| **9. Chiffrement** | **Chiffrement AD database NTDS.dit (données sensibles, hashs)** | **R/A** | **C** | **C** | |
| **9. Chiffrement** | **Audit chiffrement (validation périodique mensuelle)** | **R/A** | **C** | **C** | **C** |
| **9. Chiffrement** | **Plan migration Filer WS 2016 → WS 2022/2025 avec chiffrement renforcé** | **R/A** | **C** | **C** | |

**Justification :**
- Matrice ne mentionne PAS chiffrement Filer/AD
- HDS art. 4 = données sensibles chiffrées en repos
- Filer stocke données partagées OneOrtho (certaines patients indirectes)
- AD = base critères chiffrement mdp + hashs sensibles
- Absence politique chiffrement = données lisibles en cas d'accès physique

---

## 🔴 DOMAINE 4 : INCIDENTS AD/FILER & NOTIFICATION CNIL (Défaillance #6)

### ⚠️ **À AJOUTER — Nouvelle section 10. Gestion Incidents Sécurité**

| Domaine / Groupe | Processus / Activité | IT Manager OneOrtho | Comité technique | AVA6 Infra/MCO | AVA6 SOC (REDSOC) |
|---|---|---|---|---|---|
| **10. Incidents Sécurité** | **Escalade incidents P1 AD/Filer → comité crises OneOrtho (SLA < 1h)** | **R** | **A** | **I** | **R** |
| **10. Incidents Sécurité** | **Notification Comité technique incident compromission AD (escalade CNIL)** | **R** | **A** | **C** | **C** |
| **10. Incidents Sécurité** | **Notification incident Filer accès non-autorisé (logs, forensics)** | **R/A** | **C** | **C** | **R** |
| **10. Incidents Sécurité** | **Forensics AD post-incident (recovery account, token analysis)** | **R/A** | **C** | **C** | **R** |
| **10. Incidents Sécurité** | **Incident ransomware Filer : procédure isolement + snapshot recovery** | **R/A** | **C** | **C** | **C** |
| **10. Incidents Sécurité** | **Documentation incident & RCA (root cause analysis) Filer/AD** | **R/A** | **C** | **C** | **C** |
| **10. Incidents Sécurité** | **Notification CNIL si données patients compromises via AD/Filer** | **R/A** | **A** | **I** | **I** |

**Justification :**
- Matrice mentionne "gestion incidents authentification" mais pas procédure complète
- HDS art. 10 = notification CNIL < 24h si données (indirectement via AD)
- AD compromise = pire scénario → accès à tous les partages Filer
- Pas d'escalade SLAisée vers comité crises
- Forensics obligatoire post-incident

---

## 🟠 DOMAINE 5 : DESTRUCTION SÉCURISÉE DONNÉES AD/FILER (Défaillance #8)

### ⚠️ **À AJOUTER — Nouvelle section 4. Destruction Données (complément)**

| Domaine / Groupe | Processus / Activité | CTO OneOrtho | Comité technique | AVA6 Infra/MCO | AVA6 SOC (REDSOC) |
|---|---|---|---|---|---|
| **4. Destruction Données** | **Procédure destruction sécurisée Filer (wiping/cryptographic erase)** | **R/A** | **C** | **R** | |
| **4. Destruction Données** | **Procédure destruction disques AD01/AD02 (AD database NTDS + SYSVOL)** | **R/A** | **C** | **C** | |
| **4. Destruction Données** | **Certificat destruction Filer avec hashes pré/post destruction** | **R/A** | **C** | **R** | |
| **4. Destruction Données** | **Procédure purge données obsolètes Filer (respect rétention légale)** | **R/A** | **C** | **I** | |
| **4. Destruction Données** | **Audit traces destruction données (logs, dates, signataires)** | **R/A** | **C** | **C** | **C** |

**Justification :**
- Defaillance #8 : Destruction pas procéduralisée (s'applique aussi on-site)
- HDS art. 5 = destruction sécurisée + certificat obligatoires
- **IT Manager = Responsible/Accountable** : Réalise ET valide légalement la destruction
- **Comité technique = Consulted** : Groupe de techs lead approuve avant exécution (pas exécution)
- **AVA6 = Responsible** : Gère destruction des backups externalisés
- Filer = données critiques : destruction doit être formalisée
- AD database = données sensibles (hashs, tokens) → destruction sécurisée obligatoire

---

## 🟠 DOMAINE 6 : SAUVEGARDE & RESTAURATION AD/FILER (TESTS & RTO/RPO)

### ⚠️ **À AJOUTER — Sections 2 & 4 (compléments)**

| Domaine / Groupe | Processus / Activité | IT Manager OneOrtho | Comité technique | AVA6 Infra/MCO | AVA6 SOC (REDSOC) |
|---|---|---|---|---|---|
| **2. AD MCO & MCS** | **Processus gestion AD snapshot (sauvegarde avant changements critiques)** | **R/A** | **C** | **C** | |
| **2. AD MCO & MCS** | **Test restauration AD complet (DC01+DC02 simultanés, RTO < 2h)** | **R/A** | **C** | **C** | |
| **2. AD MCO & MCS** | **Gestion rétention AD backups (minimum 1 mois complets, 1 an archiv)** | **R/A** | **C** | **C** | |
| **2. AD MCO & MCS** | **Notification perte DC soudaine → test failover DC02 (procédure SLA)** | **R/A** | **C** | **C** | |
| **4. Filer Sauvegarde** | **Fréquence sauvegarde Filer SLAisée (quotidienne / hebdomadaire ?)** | **R/A** | **C** | **C** | |
| **4. Filer Sauvegarde** | **Test restauration fichier unique Filer (RTO < 30min)** | **R/A** | **C** | **C** | |
| **4. Filer Sauvegarde** | **Test restauration complet Filer (RTO < 4h)** | **R/A** | **C** | **C** | |
| **4. Filer Sauvegarde** | **SLA RPO Filer (perte données acceptée maximum 24h ?)** | **R/A** | **C** | **C** | |
| **4. Filer Sauvegarde** | **Procédure backup on-site vs off-site (sauvegarde géographique ?)** | **R/A** | **C** | **C** | |
| **4. Filer Sauvegarde** | **Validation chiffrement backups Filer (AES-256)** | **R/A** | **C** | **C** | |

**Justification :**
- Defaillance #11 : RTO/RPO pas formalisés pour données on-site
- Matrice mentionne "tests trimestriels" mais pas RTO/RPO précis
- AD = criticité maximale → RTO < 2h recommandée
- Filer = données partagées → RPO maximum 24h ? À définir
- Backups non chiffrés = risque données patients accessibles

---

## 🟠 DOMAINE 7 : DURÉE DE VIE COMPTES AD & DROITS (CVE/Audits)

### ⚠️ **À AJOUTER — Section 1. Active Directory (compléments)**

| Domaine / Groupe | Processus / Activité | IT Manager OneOrtho | Comité technique | AVA6 Infra/MCO | AVA6 SOC (REDSOC) |
|---|---|---|---|---|---|
| **1. AD Administration** | **Audit comptes AD orphelins (sans owner identifié)** | **R/A** | **C** | **C** | **I** |
| **1. AD Administration** | **Audit comptes inactifs > 90j (déactivation automatique)** | **R/A** | **C** | **C** | **I** |
| **1. AD Administration** | **Audit comptes administrateur (principes moindre privilège)** | **R/A** | **C** | **C** | **I** |
| **1. AD Administration** | **Gestion durée de vie mots de passe comptes service (audit hébdo)** | **R/A** | **C** | **C** | **C** |
| **1. AD Administration** | **Rotation comptes break-glass (restauration urgence AD)** | **R/A** | **C** | **C** | |
| **1. AD Administration** | **Audit groupes escalade de privilèges (nested groups complexity)** | **R/A** | **C** | **C** | **I** |
| **1. AD Administration** | **Signalement anomalies AD via SIEM (brutes force détectées)** | **R/A** | **C** | **C** | **R** |

**Justification :**
- Matrice présente "revue semestrielle" mais pas audit continu
- HDS art. 6 = accès admin à revoir régulièrement
- Comptes inactifs = vecteur accès post-incident
- Comptes service sans rotation = risques sécurité élevés
- Break-glass accounts = criticité maximale en récupération sinistre

---

## 🟠 DOMAINE 8 : GESTION VULNÉRABILITÉS SYSTÈMES (AD/Filer WS 2016)

### ⚠️ **À AJOUTER — Sections 2 & 3 (compléments)**

| Domaine / Groupe | Processus / Activité | IT Manager OneOrtho | Comité technique | AVA6 Infra/MCO | AVA6 SOC (REDSOC) |
|---|---|---|---|---|---|
| **2. AD MCO & MCS** | **Suivi CVE AD controllers (Microsoft Security Updates monthly)** | **R/A** | **C** | **C** | **I** |
| **2. AD MCO & MCS** | **Plan patching AD02 (Windows Server 2016 → 2022/2025, EOL 2027)** | **R/A** | **A** | **C** | |
| **2. AD MCO & MCS** | **SLA remediation CVE critique AD (CVSS > 8.0, patchage < 7j)** | **R/A** | **C** | **C** | **C** |
| **3. Filer MCO** | **Suivi CVE Filer (Windows Server 2016 EOL 2027 → plan migration)** | **R/A** | **A** | **C** | **I** |
| **3. Filer MCO** | **Patching mensuel OS Filer (planification fenêtre maintenance)** | **R/A** | **C** | **C** | |
| **3. Filer MCO** | **SLA remediation CVE Filer (CVSS > 7.0, patchage < 14j)** | **R/A** | **C** | **C** | **C** |
| **3. Filer MCO** | **Notification changement Filer impactant backup (test restauration)** | **R/A** | **C** | **C** | |

**Justification :**
- Matrice mentionne "patching mensuel" mais pas gestion CVE structurée
- WS 2016 = version ancienne, criticité sécurité élevée
- SLA remediation = absent → impact temps réaction vulnérabilités
- HDS art. 9 = systèmes doivent être à jour sécurité
- Windows 2016 EOL = plan migration obligatoire

---

## 🟠 DOMAINE 9 : SERVEUR CALCUL (Ubuntu/IA/DICOM) — SÉCURITÉ & CONFORMITÉ

### ⚠️ **À AJOUTER — Section 5. Serveur CALCUL (compléments)**

| Domaine / Groupe | Processus / Activité | IT Manager OneOrtho | Comité technique | AVA6 Infra/MCO | AVA6 SOC (REDSOC) |
|---|---|---|---|---|---|
| **5. Serveur CALCUL** | **Audit accès SSH serveur CALCUL (logs, clés SSH, tentatives brutes)** | **R/A** | **C** | **C** | **R** |
| **5. Serveur CALCUL** | **Chiffrement données DICOM au repos (images segmentation)** | **R/A** | **C** | **C** | |
| **5. Serveur CALCUL** | **Chiffrement données DICOM en transit (réseau)** | **R/A** | **C** | **C** | |
| **5. Serveur CALCUL** | **Gestion droits accès fichiers DICOM (RBAC)** | **R/A** | **C** | | |
| **5. Serveur CALCUL** | **Scanning vulnérabilités Ubuntu (OS, pilotes GPU RTX A6000)** | **R/A** | **A** | **C** | **C** |
| **5. Serveur CALCUL** | **Patching Ubuntu mensuel (kernel, security updates)** | **R/A** | **C** | **C** | **C** |
| **5. Serveur CALCUL** | **Audit logs GPU RTX A6000 (monitoring utilisation, anomalies)** | **R/A** | **C** | **C** | |
| **5. Serveur CALCUL** | **Isolation réseau serveur CALCUL vs Filer (segmentation)** | **R/A** | **C** | **C** | |
| **5. Serveur CALCUL** | **Backup données modèles IA (versioning, rétention)** | **R/A** | **C** | **C** | |
| **5. Serveur CALCUL** | **Notification incident données DICOM compromises** | **R/A** | **C** | **C** | **R** |

**Justification :**
- Matrice mentionne CALCUL mais section très incomplète (seulement 3-4 lignes)
- DICOM = données de santé sensibles (images IRM, radiographies annotées)
- Données DICOM transitent vers serveur calcul → chiffrement obligatoire
- Serveur Ubuntu = infrastructure on-site non hébergée
- Isolation réseau CALCUL vs Filer = besoin segmentation
- Pas d'alertes sécurité = gap détection anomalies

---

## 🟡 DOMAINE 10 : MONITORING CONTINU & ALERTES INFRASTRUCTURE

### ⚠️ **À AJOUTER — Nouvelle section 11. Monitoring & Alertes**

| Domaine / Groupe | Processus / Activité | IT Manager OneOrtho | Comité technique | AVA6 Infra/MCO | AVA6 SOC (REDSOC) |
|---|---|---|---|---|---|
| **11. Monitoring** | **Monitoring AD CPU/RAM/Disque (alertes si > 85%)** | **R/A** | **C** | **C** | **C** |
| **11. Monitoring** | **Monitoring Filer utilisation disque (alertes si > 90%, quota)** | **R/A** | **C** | **C** | **C** |
| **11. Monitoring** | **Alertes connexions RDP anormales AD controllers** | **R/A** | **C** | **C** | **R** |
| **11. Monitoring** | **Alertes modifications SYSVOL (GPO changes)** | **R/A** | **C** | **C** | **C** |
| **11. Monitoring** | **Alertes tentatives brutes force AD (MFA bypass ?)** | **R/A** | **C** | **C** | **R** |
| **11. Monitoring** | **Monitoring disponibilité AD (heartbeat DC01 ↔ DC02)** | **R/A** | **C** | **C** | |
| **11. Monitoring** | **Monitoring santé synchronisation AD (replication lag)** | **R/A** | **C** | **C** | |
| **11. Monitoring** | **Alertes accès Filer utilisateurs hors-heures (anomalies)** | **R/A** | **C** | **C** | **R** |

**Justification :**
- Matrice mentionne "surveillance réplication AD" mais pas monitoring complet
- AD = ressource critique → monitoring H24/7 obligatoire
- Defaillance #7 : SIEM doit alimenter alertes
- Monitoring proactif = détection anomalies avant incident
- Aucune alerte contractualisée = gaps détection

---

## 🟡 DOMAINE 11 : CONFORMITÉ RGPD & HDS FOR DONNÉES ON-SITE

### ⚠️ **À AJOUTER — Section 6. Sécurité & Conformité (compléments)**

| Domaine / Groupe | Processus / Activité | IT Manager OneOrtho | Comité technique | AVA6 Infra/MCO | AVA6 SOC (REDSOC) |
|---|---|---|---|---|---|
| **6. Conformité RGPD/HDS** | **Audit piste tracabilité données patients via AD (authentification)** | **R/A** | **C** | **C** | **I** |
| **6. Conformité RGPD/HDS** | **Audit piste tracabilité accès données DICOM (who, when, why)** | **R/A** | **C** | **C** | **I** |
| **6. Conformité RGPD/HDS** | **Classification données Filer (patiente-identifiée vs pseudonymisée)** | **R/A** | **A** | | |
| **6. Conformité RGPD/HDS** | **Audit segmentation AD <-> Filer (données cliniques vs admin)** | **R/A** | **C** | **C** | **I** |
| **6. Conformité RGPD/HDS** | **Procédure droit d'accès patient (accès données OneOrtho DICOM/AD/Filer)** | **R/A** | **A** | **C** | |
| **6. Conformité RGPD/HDS** | **Procédure rectification données patients Filer (audit trails)** | **R/A** | **C** | **C** | |
| **6. Conformité RGPD/HDS** | **Procédure oubli données patients (suppression complète)** | **R/A** | **C** | **C** | |
| **6. Conformité RGPD/HDS** | **Audit annuel conformité RGPD/HDS (rapport audit)** | **R/A** | **A** | **C** | **I** |

**Justification :**
- Matrice mentionne "notification incident" mais pas droits d'accès RGPD
- RGPD art. 12-22 = droits patient (accès, rectification, oubli)
- OneOrtho = responsable traitement → obligations direct en audit
- AD + Filer = supports traitement données patients indirect
- Audit annuel = obligatoire pour conformité démontrable

---

## 📊 RÉSUMÉ — Points manquants complète

**Nombre d'activités manquantes : 67 nouvelles lignes**

| Domaine | Nb Activités Manquantes | Impact HDS |
|---|---|---|
| 1. Traçabilité & Audit Accès AD | 7 | **CRITIQUE** |
| 2. Tests Sécurité & Pentest AD/Filer | 7 | **CRITIQUE** |
| 3. Chiffrement Données On-Site | 6 | **CRITIQUE** |
| 4. Incidents AD/Filer & Notification | 7 | **CRITIQUE** |
| 5. Destruction Données AD/Filer | 5 | **CRITIQUE** |
| 6. Sauvegarde & Restauration (RTO/RPO) | 10 | **CRITIQUE** |
| 7. Durée de vie Comptes AD & Droits | 7 | **MAJEURE** |
| 8. Gestion Vulnérabilités Systèmes | 7 | **MAJEURE** |
| 9. Sécurité Serveur CALCUL (DICOM) | 10 | **MAJEURE** |
| 10. Monitoring Continu & Alertes | 8 | **MAJEURE** |
| 11. Conformité RGPD & HDS On-Site | 8 | **MAJEURE** |
| **TOTAL** | **67** | — |

---

## 📌 **Recommandations prioritaires (OneOrtho On-Site)**

### **P0 — AVANT mise en production données patients :**
1. **Chiffrement Filer** (Defaillance #5) : Implémenter BitLocker ou équivalent
2. **Audit AD** → **SIEM** (Defaillance #7) : Intégrer logs authentification dans WatchGuard SIEM
3. **Tests pentest AD** : Valider architecture AD sécurisée (Golden Ticket, Kerberos roasting)
4. **Isolation CALCUL**: Vérifier segmentation réseau serveur DICOM

### **P1 — 30 jours après activation Filer/AD :**
1. Formaliser RTO/RPO AD et Filer
2. Documenter test restauration AD complet (failover DC02)
3. Audit comptes AD orphelins / inactifs
4. Implémenter monitoring alertes AD anomalies

### **P2 — Avant audit CNIL/HDS :**
1. Certificat destruction Filer formalisé
2. Audit traçabilité données patients (AD + Filer + DICOM)
3. Rapport pentest annuel
4. Classification données Filer

---

## 📎 **Références croisées Matrice #01 (OneSoftware) vs Matrice #02 (AD/Filer)**

> **Éléments reproduits dans AD/Filer :**
> - Traçabilité accès (Q41-Q43) → Audit AD logs
> - Tests sécurité (Défaillance #3) → Pentest AD/Filer
> - Chiffrement (Défaillance #5) → Chiffrement Filer/AD database
> - Incidents & notification (Défaillance #6) → Escalade incidents AD/Filer
> - Destruction (Défaillance #8) → Destruction données AD/Filer
> - Monitoring SIEM (Défaillance #7) → Alertes SIEM issus logs AD

> **Différences contexte on-site :**
> - OneOrtho Responsable traitement 100% (pas AVA6 MCO infrastructure locale)
> - Données plus sensibles (AD = clé maître, DICOM = images patients)
> - RTO/RPO différents (AD < 2h vs Filer < 4h)
> - Audit local vs hébérgé (responsabilités OneOrtho + CTO distinctes)

