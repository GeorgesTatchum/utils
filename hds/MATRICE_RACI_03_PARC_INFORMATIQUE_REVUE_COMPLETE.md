# Matrice RACI — 03 — Parc Informatique & Sécurité Endpoints Interne OneOrtho
## Révision complète avec priorités HDS et matériel réseau

**Date :** 22 avril 2026  
**Classification :** CONFIDENTIEL

---

## 🔑 **CLARIFICATION RÔLES RACI (CRITIQUE)**

### Distinction acteurs — Infrastructure IT On-Site OneOrtho

| Acteur | Responsabilité | Rôle Type RACI |
|---|---|---|
| **IT Manager OneOrtho** | Responsable numérique OneOrtho + leader techs | **R/A** (Réalise + Accountable légal) |
| **Comité technique OneOrtho** | Ensemble des techs lead + IT Manager (collectif décision) | **C/A** (Consulté + Approuve décisions strat) |
| **CEO OneOrtho** | Direction exécutive (approbation stratégique) | **A** (Approuve budgets/plans critiques) |
| **AVA6 Infra/MCO** | Prestataire infrastructure externalisée | **C/R** (Consulté + gère solutions centralisées SIEM) |
| **AVA6 SOC (REDSOC)** | Prestataire sécurité/monitoring centralisé | **R/I** (Détection anomalies + Informé incidents) |

### Application Parc IT On-Site

> **Important :**
> - **"Comité technique"** = groupe collectif (CEO + Tech Leads + IT Manager), pas instance unique
> - **IT Manager** = pilote opérationnel + responsable légal MCO parc
> - N'exécute jamais sans IT Manager, seul **IT Manager + équipes spécialisées** exécutent
> - **CEO** approuve plans pluriannuels + changements stratégiques majeurs
> - **REDSOC** détecte via EPDR agent centralisé + alertes SIEM

---

## ⚠️ **NOTE MÉTHODOLOGIQUE : Périmètre HDS vs Infrastructure IT Générale**

### Ce document applique les principes HDS **seulement pour** :
✅ **Données patients** (chiffrement, destruction, traçabilité, incidents)  
✅ **Tests sécurité/Pentest** (scan vulnérabilités)  
✅ **Conformité audit CNIL** (annuelle)  

### Deux catégories dans les activités :
🔴 **CRITIQUE** = Obligations HDS directes (données patients)  
🟡 **RECOMMANDÉ** = Bonne pratique sécurité IT (optionnel mais conseillé)  

### Exclus du périmètre HDS strict :
- ❌ Monitoring performance générique (CPU/RAM/Disque)
- ❌ Gestion failover/redondance réseau purement infrastructurelle
- ✅ **Mais INCLUS** si impacts données patients ou infrastructure critique

---

## 🔴 **SECTION 1 : INVENTAIRE & CYCLE DE VIE — CRITIQUE HDS**

### Domaine 1A — Inventaire & Classification

| Domaine / Groupe | Processus / Activité | IT Manager | Comité technique | AVA6 Infra/MCO | REDSOC | CEO |
|---|---|---|---|---|---|---|
| **1A. Inventaire** | **Tenue à jour CMDB (postes, réseau, périphériques)** | **R/A** | **C** | **C** | | |
| **1A. Inventaire** | **Enregistrement nouveau poste/équipement réseau** | **R/A** | **C** | | | |
| **1A. Inventaire** | **Classification données accessibles par équipement** | **R/A** | **C** | | | |
| **1A. Inventaire** | **Plan de renouvellement pluriannuel (budgétaire)** | **A** | **R** | **I** | | **A** |

### Domaine 1B — Décommissionnement & Destruction Sécurisée **[CRITIQUE HDS]**

| Domaine / Groupe | Processus / Activité | IT Manager | Comité technique | AVA6 Infra/MCO | REDSOC | CEO |
|---|---|---|---|---|---|---|
| **1B. Destruction** | **Procédure destruction poste (wiping/Secure Erase)** | **R/A** | **C** | **I** | | |
| **1B. Destruction** | **Destruction disques/SSD (méthode physique si sensible)** | **R/A** | **C** | **I** | | |
| **1B. Destruction** | **Destruction périphériques (USB, clés SSH, certs)** | **R/A** | **C** | **I** | | |
| **1B. Destruction** | **Destruction équipements réseau (routeur/switch reset conf)** | **R/A** | **C** | **I** | | |
| **1B. Destruction** | **Certificat destruction sécurisée (hashes pré/post)** | **R/A** | **C** | **I** | | |
| **1B. Destruction** | **Audit traces destruction (logs, dates, signataires)** | **R/A** | **C** | **I** | **C** | |

**Justification HDS :**
- HDS art. 5 = destruction sécurisée + certificat obligatoires
- Disques postes contiennent données patients en cache/logs
- Équipements réseau contiennent clés WiFi, configs sensibles
- Certificat = preuve destruction pour audit CNIL

### Domaine 1C — Gestion Actifs Mobiles

| Domaine / Groupe | Processus / Activité | IT Manager | Comité technique | AVA6 Infra/MCO | REDSOC | CEO |
|---|---|---|---|---|---|---|
| **1C. Mobiles** | **Gestion inventaire laptops/tablettes (tracking)** | **R/A** | **C** | | | |
| **1C. Mobiles** | **Politique BYOD si applicable (hors périmètre)** | **A** | **R** | | | |

---

## 🔴 **SECTION 2 : CONFIGURATION & DÉPLOIEMENT — CRITIQUE HDS**

| Domaine / Groupe | Processus / Activité | IT Manager | Comité technique | AVA6 Infra/MCO | REDSOC | CEO |
|---|---|---|---|---|---|---|
| **2. Config & Déploiement** | **Maintien image de base sécurisée (golden image)** | **I** | **R** | **I** | **I** | |
| **2. Config & Déploiement** | **Déploiement poste (MDM/GPO avec baseline sécurité)** | **I** | **R** | **I** | **I** | |
| **2. Config & Déploiement** | **Installation logiciels standards approuvés** | **I** | **R** | **I** | **I** | |
| **2. Config & Déploiement** | **Intégration domaine Active Directory (AD01/AD02)** | **I** | **R** | **I** | | |
| **2. Config & Déploiement** | **[CRITIQUE HDS] Chiffrement BitLocker obligatoire tous postes** | **R/A** | **C** | **C** | **C** | |
| **2. Config & Déploiement** | **Audit conformité chiffrement (mensuel, 100% postes)** | **R/A** | **C** | **C** | **C** | |
| **2. Config & Déploiement** | **[CRITIQUE HDS] Gestion clés BitLocker (escrow AD secure)** | **R/A** | **C** | **I** | | |

**Justification HDS :**
- HDS art. 4 = chiffrement données au repos obligatoire
- BitLocker = défense critique pour données patients en cache
- Gestion clés = responsabilité IT Manager (escrow = sauvegarde AD sécurisée)

---

## 🔴 **SECTION 3 : PATCH MANAGEMENT POSTES — CRITIQUE HDS**

| Domaine / Groupe | Processus / Activité | IT Manager | Comité technique | AVA6 Infra/MCO | REDSOC | CEO |
|---|---|---|---|---|---|---|
| **3A. Patching** | **Déploiement correctifs Windows (mensuel)** | **I** | **R** | **I** | **I** | |
| **3A. Patching** | **Déploiement correctifs logiciels tiers** | **I** | **R** | **I** | **I** | |
| **3A. Patching** | **Tests de compatibilité avant déploiement masse** | **I** | **R** | **I** | | |
| **3A. Patching** | **Rapport conformité patch management (mensuel)** | **A** | **R** | **I** | **I** | |
| **3A. Patching** | **Gestion exceptions/dérogations patch (justification)** | **A** | **R** | **C** | | |
| **3B. CVE Management** | **[CRITIQUE HDS] Scan vulnérabilité postes (fréquence SLAisée)** | **R/A** | **C** | **C** | **R** | |
| **3B. CVE Management** | **Suivi CVE critiques (CVSS > 8.0) — alertes** | **A** | **C** | **C** | **R** | |
| **3B. CVE Management** | **SLA remediation CVE critique (patchage < 7j)** | **A** | **C** | **C** | **R** | |
| **3B. CVE Management** | **Rapport mensuel scan + vulnérabilités remédiation** | **A** | **R** | **C** | **C** | |

**Justification HDS :**
- HDS art. 9 = systèmes à jour sécurité (patch mensuel minimum)
- CVE scanning = contrôle conformité continu
- SLA CVE critique = détection + réaction rapide

---

## 🔴 **SECTION 4 : ENDPINT DETECTION & RESPONSE (EPDR) — CRITIQUE HDS**

| Domaine / Groupe | Processus / Activité | IT Manager | Comité technique | AVA6 Infra/MCO | REDSOC | CEO |
|---|---|---|---|---|---|---|
| **4A. EPDR Deploy** | **Déploiement agent EPDR WatchGuard tous postes** | **R/A** | **C** | **C** | **C** | |
| **4A. EPDR Deploy** | **Vérification agent EPDR actif H24/7 (compliance)** | **I** | **R** | **I** | **R** | |
| **4B. EPDR Admin** | **Administration console EPDR (WatchGuard Cloud)** | **A** | **I** | **I** | **R** | |
| **4B. EPDR Admin** | **Mise à jour signatures + moteur EPDR (fréquence)** | **I** | **I** | **I** | **R** | |
| **4C. EPDR Détection** | **[CRITIQUE HDS] Détection anomalies (processus suspects)** | **I** | **C** | **I** | **R** | |
| **4C. EPDR Détection** | **[CRITIQUE HDS] Alertes accès fichiers sensibles (DICOM, dossiers patients)** | **I** | **C** | **I** | **R** | |
| **4C. EPDR Détection** | **Alertes connexion USB/Bluetooth non-autorisés** | **I** | **C** | **I** | **R** | |
| **4C. EPDR Détection** | **Alertes escalade privilèges locales** | **I** | **C** | **I** | **R** | |
| **4D. Incidents** | **[CRITIQUE HDS] Quarantaine automatique poste alerte P1** | **I** | **R** | **I** | **R** | |
| **4D. Incidents** | **Rapport mensuel EPDR (détections, remédiation, KPIs)** | **A** | **I** | **I** | **R** | |
| **4E. Contract** | **Renouvellement annuel contrat EPDR + REDSOC SOC** | **A** | **C** | **I** | **I** | **A** |

**Justification HDS :**
- HDS art. 9 = détection anomalies obligatoire
- EPDR = détection intrusion postes (ransomware, malware)
- Alertes accès données = traçabilité HDS art. 6
- Quarantaine automatique = containment rapidité incidents

---

## 🔴 **SECTION 5 : INCIDENTS SÉCURITÉ POSTES — CRITIQUE HDS**

| Domaine / Groupe | Processus / Activité | IT Manager | Comité technique | AVA6 Infra/MCO | REDSOC | CEO |
|---|---|---|---|---|---|---|
| **5A. Escalade P1** | **[CRITIQUE HDS] Escalade incidents P1 (SLA < 30min)** | **R** | **A** | **I** | **R** | |
| **5A. Escalade P1** | **Notification incident compromission to Comité (escalade)** | **R** | **A** | **I** | **R** | |
| **5B. Response** | **Forensics post-incident (logs, mémoire, disque)** | **R/A** | **C** | **I** | **R** | |
| **5B. Response** | **Documentation incident + RCA (root cause analysis)** | **R/A** | **C** | **I** | **R** | |
| **5C. Notification** | **[CRITIQUE HDS] Notification CNIL si données patients compromises** | **R/A** | **A** | **I** | **I** | **A** |
| **5D. Test** | **Test drill annuel procédure incident (simulation)** | **R** | **A** | **I** | **R** | |

**Justification HDS :**
- HDS art. 10 = notification CNIL < 24h si compromiasion
- RGPD art. 33 = OneOrtho responsable notification légale
- Forensics = obligatoire pour RCA + preuve au CNIL

---

## 🔴 **SECTION 6 : TRAÇABILITÉ ACCÈS DONNÉES PATIENTS — CRITIQUE HDS**

| Domaine / Groupe | Processus / Activité | IT Manager | Comité technique | AVA6 Infra/MCO | REDSOC | CEO |
|---|---|---|---|---|---|---|
| **6A. Audit Logs** | **[CRITIQUE HDS] Audit logs accès fichiers patients (DICOM, ERP)** | **R/A** | **C** | **I** | **C** | |
| **6A. Audit Logs** | **Monitoring opérations fichiers sensibles (open/write/delete)** | **I** | **C** | **I** | **R** | |
| **6A. Audit Logs** | **Logs impression documents patients (traçabilité)** | **R/A** | **C** | **I** | | |
| **6A. Audit Logs** | **Audit tentatives accès non-autorisés données** | **R/A** | **C** | **I** | **C** | |
| **6B. Rétention** | **[CRITIQUE HDS] Rétention logs accès minimum 1 an** | **R/A** | **C** | **I** | | |
| **6C. Reporting** | **Rapport audit accès données (trimestriel)** | **R/A** | **I** | **I** | **C** | |

**Justification HDS :**
- HDS art. 6 = traçabilité obligatoire accès données
- RGPD art. 32 = information sécurité audit piste
- Rétention 1 an = démonstration conformité audit CNIL

---

## 🔴 **SECTION 7 : TESTS SÉCURITÉ & PENTEST — CRITIQUE HDS**

| Domaine / Groupe | Processus / Activité | IT Manager | Comité technique | AVA6 Infra/MCO | REDSOC | CEO |
|---|---|---|---|---|---|---|
| **7A. Pentest** | **[CRITIQUE HDS] Tests pénétration postes annuels** | **R** | **A** | **C** | **C** | **A** |
| **7A. Pentest** | **[CRITIQUE HDS] Scan vulnérabilité parc (OS + logiciels)** | **R** | **A** | **C** | **C** | |
| **7A. Pentest** | **[CRITIQUE HDS] Audit hardening postes (CIS baseline)** | **R** | **A** | **C** | **C** | |
| **7B. Réseau** | **[RECOMMANDÉ] Tests WiFi sécurité (WPA3, rogue AP)** | **R** | **A** | **C** | **C** | |
| **7B. Réseau** | **[RECOMMANDÉ] Tests isolement VLAN patient vs admin** | **R** | **A** | **C** | **C** | |
| **7C. Report** | **Rapport pentest annuel (communicable audit CNIL)** | **R** | **A** | **C** | **I** | |

**Justification HDS :**
- HDS art. 9 = tests intrusion annuels obligatoires
- HDS recommande pentest scope parc + réseau

---

## 🔴 **SECTION 8 : GESTION IDENTITÉS & ACCÈS — CRITIQUE HDS**

| Domaine / Groupe | Processus / Activité | IT Manager | Comité technique | AVA6 Infra/MCO | REDSOC | CEO |
|---|---|---|---|---|---|---|
| **8A. Identités** | **Création compte utilisateur (AD + applications)** | **I** | **R** | **I** | | |
| **8A. Identités** | **Révocation compte (départ collaborateur, exigence HDS)** | **I** | **R** | **I** | | |
| **8A. Identités** | **Gestion droits d'accès applicatifs (moindre privilège)** | **I** | **R** | **I** | | |
| **8B. Auth** | **[CRITIQUE HDS] Politique MFA (authentification multifacteur)** | **A** | **R** | **C** | **C** | |
| **8C. Review** | **[CRITIQUE HDS] Revue trimestrielle accès (HDS art. 6)** | **A** | **R** | **C** | **I** | |
| **8D. Privilèges** | **[RECOMMANDÉ] Gestion comptes privilégiés (PAM/break-glass)** | **A** | **R** | **I** | **C** | |

**Justification HDS :**
- HDS art. 6 = accès limité + audit trimestriel
- MFA = défense contr3 compromission identité
- Revue trimestrielle = obligatoire conformité

---

## 🔴 **SECTION 9 : MATÉRIEL RÉSEAU — CRITIQUE HDS**

### Domaine 9A — Configuration & Sécurité

| Domaine / Groupe | Processus / Activité | IT Manager | Comité technique | AVA6 Infra/MCO | REDSOC | CEO |
|---|---|---|---|---|---|---|
| **9A. Réseau Config** | **[RECOMMANDÉ] Configuration WiFi sécurisée (WPA3)** | **R/A** | **C** | **C** | | |
| **9A. Réseau Config** | **[RECOMMANDÉ] Configuration Box Internet (firewall rules)** | **R/A** | **C** | **C** | | |
| **9A. Réseau Config** | **[RECOMMANDÉ] Segmentation VLAN patient vs admin vs guest** | **R/A** | **C** | **C** | **C** | |
| **9A. Réseau Config** | **[RECOMMANDÉ] Audit isolement VLAN (test pénétration)** | **R** | **A** | **C** | **C** | |
| **9B. Monitoring** | **Monitoring WiFi accès (logs connexion/déconnexion)** | **I** | **C** | **C** | **R** | |
| **9B. Monitoring** | **Monitoring Switch anomalies (ARP spoofing, STP)** | **I** | **C** | **C** | **R** | |
| **9B. Monitoring** | **Monitoring Box Internet uptime (alertes déconnexion)** | **I** | **C** | **C** | **R** | |
| **9C. Logs** | **[RECOMMANDÉ] Audit logs Box Internet (tentatives brutes)** | **R/A** | **C** | **C** | **C** | |
| **9D. Destruction** | **Destruction équipements réseau (reset config, clés WiFi)** | **R/A** | **C** | **I** | | |

**Justification :**
- VLAN segmentation = HDS art. 3 (isolement données)
- WiFi = point accès données patients (sécurité prioritaire)
- Box internet = première défense contre internet
- Monitoring = détection anomalies (confié REDSOC)

---

## 🔴 **SECTION 10 : CONFORMITÉ & GOUVERNANCE — CRITIQUE HDS**

| Domaine / Groupe | Processus / Activité | IT Manager | Comité technique | AVA6 Infra/MCO | REDSOC | CEO |
|---|---|---|---|---|---|---|
| **10A. Politique** | **Politique de Sécurité des Postes (PSP OneOrtho)** | **A** | **R** | **I** | **C** | **A** |
| **10B. Sensibilisation** | **Sensibilisation utilisateurs (phishing, sécurité, HDS)** | **A** | **R** | **I** | **C** | |
| **10C. Classification** | **[CRITIQUE HDS] Classification données accessibles parc** | **R/A** | **C** | **I** | | |
| **10D. RGPD** | **[CRITIQUE HDS] Procédure RGPD droits d'accès/rectification/oubli** | **R/A** | **A** | **I** | | **A** |
| **10E. Audit** | **[CRITIQUE HDS] Audit conformité parc (semestriel)** | **R/A** | **A** | **C** | **I** | |
| **10E. Audit** | **Audit annuel conformité RGPD/HDS global** | **A** | **A** | **C** | **I** | **A** |

**Justification HDS :**
- PSP = politique cadre sécurité 
- Classification données = base audit traçabilité
- Audit semestriel = conformité démontrable CNIL
- RGPD procedures = OneOrtho responsable légal

---

## 📊 **RÉSUMÉ PRIORITÉS — Matrice Révisée**

### **🔴 CRITIQUE HDS (18 activités)** = Obligations légales directes
✅ Destruction sécurisée → HDS art. 5  
✅ Chiffrement BitLocker → HDS art. 4  
✅ Gestion clés BitLocker → HDS art. 4  
✅ Scan vulnérabilité + CVE SLA → HDS art. 9  
✅ EPDR détection + alertes → HDS art. 9  
✅ Incidents P1 escalade (SLA) → HDS art. 10  
✅ Notification CNIL → RGPD art. 33  
✅ Traçabilité accès données → HDS art. 6  
✅ Rétention logs 1 an → HDS art. 6  
✅ Tests pentest annuels → HDS art. 9  
✅ Revue trimestrielle accès → HDS art. 6  
✅ MFA → recommandation forte HDS  
✅ Classification données → HDS art. 1  
✅ Procédures RGPD → RGPD art. 12-22  
✅ Audit semestriel → conformité CNIL  
✅ Audit annuel RGPD/HDS → conformité globale  

### **🟡 RECOMMANDÉ (18 activités)** = Bonne pratique sécurité
⚠️ Tests WiFi/VLAN isolement  
⚠️ Audit hardening CIS  
⚠️ Gestion PAM/break-glass  
⚠️ Audit logs Box internet  
⚠️ Alertes USB/Bluetooth  
⚠️ Et autres sécurité complémentaires  

### **❌ EXCLUS** = Hors périmètre HDS strict
- ~~Monitoring CPU/RAM/disque (maintenance IT)~~
- ~~Dashboard inventaire online/offline (ops IT)~~
- ~~Failover/redondance générique (infra IT)~~

---

## 📎 **CHANGEMENTS APPLIQUÉS**

| Ancien | Nouveau | Raison |
|---|---|---|
| Section unique "EPDR" | Split EPDR + Incidents P1 | Clarifier détection vs réponse |
| "Rapport mensuel EPDR" | Spécifier KPIs (MTTD/MTTR) | Mesure conformité |
| "Gestion incidents" flou | Escalade P1 + SLA 30min formalisé | HDS art. 10 = notification rapide |
| "Audit semestriel" seul | + Audit annuel RGPD/HDS | Conformité globale |
| Aucune traçabilité données | Section 6 complète (logs accès DICOM) | HDS art. 6 = foundational |
| Aucun pentest | Section 7 formalisée | HDS art. 9 = mandatory |
| Réseau absent | Section 9 (WiFi/Box/Switch) | VLAN segmentation = HDS art. 3 |
| Rôles flous | CEO approuve stratégiques | Clarifier hiérarchie décision |

