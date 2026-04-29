# POINTS MANQUANTS — Matrice RACI Parc Informatique & Sécurité Endpoints
## Analyse basée sur contrat AVA6 + questionnaires HDS + défaillances identifiées

**Date :** 21 avril 2026  
**Classification :** CONFIDENTIEL

---

## 📋 CONTEXTE — Infrastructure IT on-site OneOrtho

> **Parc informatique :**
> - PC/Laptops (15 postes environnement clinique)
> - Serveur Local (si applicable)
> - Box internet / Routeur OneOrtho (connexion ISP)
> - Switch réseau (segmentation VLAN patient vs admin)
> - Périphériques : imprimantes, scanners, etc.
> 
> **Données traitées :** Données patients, imagerie DICOM, données administratives  
> **Contexte HDS** : Infrastructure on-site OneOrtho = Responsabilité IT Manager 100%

---

## 🔑 **CLARIFICATION RÔLES RACI (CRITIQUE)**

### Distinction acteurs — Infrastructure Parc IT On-Site OneOrtho

| Acteur | Responsabilité | Rôle Type RACI |
|---|---|---|
| **IT Manager OneOrtho** | Pilote IT responsable MCO on-site | **R/A** (Réalise + Accountable légal) |
| **Comité technique OneOrtho** | Groupe collectif techs lead on-site | **C/A** (Consulté + Approuve décisions strat) |
| **AVA6 Infra/MCO** | Prestataire infrastructure externalisée | **C/R** (Consulté + gère solutions centralisées) |
| **AVA6 SOC (REDSOC)** | Prestataire sécurité/monitoring | **R/I** (Détection + Informé incidents) |

### Application au Parc Informatique On-Site

> **Responsabilité Parc IT (données patients on-site) :**
> - **IT Manager** = Exécute inventaire, déploiement, patching, destruction
> - **Comité technique** = Groupe de techs lead = Approuve avant action critique (changement OS, destruction)
> - **AVA6 Infra/MCO** = Consulté pour solutions externalisées (SIEM/EPDR si centralisé)
> - **AVA6 SOC (REDSOC)** = Détecte anomalies via agent EPDR + alertes

> **Important:** 
> - **"Comité technique"** = collectif de techs lead OneOrtho (pas une personne unique)
> - N'exécute jamais, seul **IT Manager** + équipes spécialisées exécutent
> - APPROUVE/CONSULTE avant exécution actions sensibles

---

## 🔴 DOMAINE 1 : TESTS SÉCURITÉ & PENTEST PARC (Défaillance #3 + HDS art. 9)

### ⚠️ **À AJOUTER — Nouvelle section 7. Tests Sécurité Endpoints**

| Domaine / Groupe | Processus / Activité | IT Manager OneOrtho | Comité technique | AVA6 Infra/MCO | AVA6 SOC (REDSOC) |
|---|---|---|---|---|---|
| **7. Tests Sécurité** | **Tests pénétration postes annuels (escalade privilèges locaux)** | **R** | **A** | **C** | **C** |
| **7. Tests Sécurité** | **Scan vulnérabilité parc (OS Windows, logiciels tiers)** | **R** | **A** | **C** | **C** |
| **7. Tests Sécurité** | **Tests d'intrusion WiFi/Box internet (sécurité réseau local)** | **R** | **A** | **C** | **C** |
| **7. Tests Sécurité** | **Test isolement VLAN patient vs admin (segmentation réseau)** | **R** | **A** | **C** | **C** |
| **7. Tests Sécurité** | **Audit hardening postes (CIS benchmark Windows)** | **R** | **A** | **C** | **C** |
| **7. Tests Sécurité** | **Rapport pentest annuel communicable audit CNIL** | **R** | **A** | **C** | **I** |

**Justification :**
- Matrice n'inclut PAS tests sécurité / pentest parc
- HDS art. 9 = tests intrusion annuels obligatoires
- Parc accède données patients → tests de compromission critiques
- WiFi/Box internet = points d'accès critiques pour données patients
- VLAN segmentation doit être validée (test isolement)

---

## 🔴 DOMAINE 2 : MONITORING CONTINU & ALERTES PRÉSENCE (EPDR/SIEM)

### ⚠️ **À AJOUTER — Complément section 4. EPDR**

| Domaine / Groupe | Processus / Activité | IT Manager OneOrtho | Comité technique | AVA6 Infra/MCO | AVA6 SOC (REDSOC) |
|---|---|---|---|---|---|
| **4. EPDR & Monitoring** | **Monitoring H24/7 processus suspects sur postes (anomalies)** | **I** | **C** | **C** | **R** |
| **4. EPDR & Monitoring** | **Alertes connexion USB/Bluetooth non-autorisés (vol données)** | **I** | **C** | **C** | **R** |
| **4. EPDR & Monitoring** | **Alertes tentatives escalade privilèges locales** | **I** | **C** | **C** | **R** |
| **4. EPDR & Monitoring** | **Monitoring accès fichiers sensibles (documents patients DICOM)** | **I** | **C** | **I** | **R** |
| **4. EPDR & Monitoring** | **Alertes modifications fichiers système (tampering détection)** | **I** | **C** | **C** | **R** |
| **4. EPDR & Monitoring** | **Alertes déconnexion postes hors-heures (anomalies)** | **I** | **C** | **C** | **R** |
| **4. EPDR & Monitoring** | **Dashboard EPDR avec KPIs détection (MTTD/MTTR)** | **A** | **I** | **C** | **R** |

**Justification :**
- Matrice mentionne "analyse alertes EPDR" mais pas monitoring proactif continu
- EPDR = détection anomalies avant incident nécessite seuils alertes
- Données patients sensibles → monitoring accès fichiers critiques
- USB/Bluetooth = vecteurs accès/exfiltration fréquents
- MTTD/MTTR = KPIs HDS détection (mesurer temps détection)

---

## 🔴 DOMAINE 3 : DESTRUCTION SÉCURISÉE POSTES & PÉRIPHÉRIQUES (Défaillance #8)

### ⚠️ **À AJOUTER — Nouvelle section 8. Destruction Équipements**

| Domaine / Groupe | Processus / Activité | IT Manager OneOrtho | Comité technique | AVA6 Infra/MCO | AVA6 SOC (REDSOC) |
|---|---|---|---|---|---|
| **8. Destruction Équipements** | **Procédure destruction sécurisée disque poste (wiping/ATA Secure Erase)** | **R/A** | **C** | **C** | |
| **8. Destruction Équipements** | **Destruction périphériques (USB, clés SSH, certificats)** | **R/A** | **C** | **C** | |
| **8. Destruction Équipements** | **Certificat destruction avec logs avant/après (hashes)** | **R/A** | **C** | **C** | |
| **8. Destruction Équipements** | **Audit traces destruction équipements (date, responsable, motif)** | **R/A** | **C** | **C** | **C** |
| **8. Destruction Équipements** | **Gestion destruction Box internet (reset factory, clés WiFi)** | **R/A** | **C** | **R** | |
| **8. Destruction Équipements** | **Procédure destruction données résiduelles (RAM effacée)** | **R/A** | **C** | **C** | |

**Justification :**
- Defaillance #8 : Destruction pas procéduralisée
- HDS art. 5 = destruction sécurisée équipements contenant données santé obligatoire
- Disques postes peuvent contenir données patients en cache
- Périphériques (USB) = vecteurs accès données
- Box internet = clés WiFi à déposer d'urgence

---

## 🔴 DOMAINE 4 : CHIFFREMENT DONNÉES POSTES & PÉRIPHÉRIQUES (Défaillance #5)

### ⚠️ **À AJOUTER — Complément section 2. Configuration**

| Domaine / Groupe | Processus / Activité | IT Manager OneOrtho | Comité technique | AVA6 Infra/MCO | AVA6 SOC (REDSOC) |
|---|---|---|---|---|---|
| **2. Configuration & Chiffrement** | **Audit conformité BitLocker tous postes (vérification activé)** | **R/A** | **C** | **C** | **C** |
| **2. Configuration & Chiffrement** | **Gestion clés BitLocker (stockage, rotation, escrow AD)** | **R/A** | **C** | **C** | |
| **2. Configuration & Chiffrement** | **Chiffrement stockage USB (périphériques autorisés)** | **R/A** | **C** | **C** | |
| **2. Configuration & Chiffrement** | **Validation chiffrement données en transit (HTTPS/TLS)** | **R/A** | **C** | **C** | **C** |
| **2. Configuration & Chiffrement** | **Audit chiffrement (validation mensuelle conformité)** | **R/A** | **C** | **C** | **C** |

**Justification :**
- Matrice mentionne "chiffrement disque obligatoire" mais pas audit conformité
- HDS art. 4 = données patients chiffrées au repos obligatoire
- Gestion clés BitLocker = responsabilité IT Manager (escrow AD)
- USB chiffrement = postes accédant données patients doivent isoler USB
- Audit conformité mensuel = vérifier BitLocker toujours activé

---

## 🔴 DOMAINE 5 : GESTION VULNÉRABILITÉS POSTES (CVE & Scanning)

### ⚠️ **À AJOUTER — Complément section 3. Patch Management**

| Domaine / Groupe | Processus / Activité | IT Manager OneOrtho | Comité technique | AVA6 Infra/MCO | AVA6 SOC (REDSOC) |
|---|---|---|---|---|---|
| **3. Patch Management** | **Scan vulnérabilité continu postes (fréquence SLAisée)** | **R/A** | **C** | **C** | **C** |
| **3. Patch Management** | **Suivi CVE critiques (CVSS > 8.0) sur postes** | **R/A** | **C** | **C** | **C** |
| **3. Patch Management** | **SLA remediation CVE critique (patchage < 7 jours)** | **R/A** | **C** | **C** | **C** |
| **3. Patch Management** | **Alertes automatiques CVE exploitées in-the-wild** | **I** | **C** | **C** | **R** |
| **3. Patch Management** | **Rapport mensuellement scan + remédiation vulnérabilités** | **R/A** | **I** | **C** | **C** |
| **3. Patch Management** | **Plan de patching et test avant déploiement masse** | **R/A** | **C** | **C** | |

**Justification :**
- Matrice mentionne patch mensuel mais pas gestion CVE structurée
- HDS art. 9 = systèmes doivent être à jour sécurité (scan + SLA)
- CVE exploitées in-the-wild = criticité maximale
- Postes accédant données patients → criticité élevée
- Rapport mensuel = traçabilité conformité audit

---

## 🔴 DOMAINE 6 : INCIDENTS SÉCURITÉ POSTES & ESCALADE (Défaillance #6)

### ⚠️ **À AJOUTER — Complément section 6. Gouvernance + nouvelle section**

| Domaine / Groupe | Processus / Activité | IT Manager OneOrtho | Comité technique | AVA6 Infra/MCO | AVA6 SOC (REDSOC) |
|---|---|---|---|---|---|
| **6. Incidents Sécurité** | **Escalade incidents P1 (malware, ransomware) → comité crises (SLA < 30min)** | **R** | **A** | **I** | **R** |
| **6. Incidents Sécurité** | **Notification incident compromission poste accédant données patients** | **R** | **A** | **I** | **R** |
| **6. Incidents Sécurité** | **Quarantaine automatique poste suite alerte EPDR critique** | **R** | **C** | **I** | **R** |
| **6. Incidents Sécurité** | **Forensics post-incident (analyse disque, logs, mémoire)** | **R/A** | **C** | **I** | **R** |
| **6. Incidents Sécurité** | **Documentation incident & RCA (root cause analysis)** | **R/A** | **C** | **I** | **R** |
| **6. Incidents Sécurité** | **Notification CNIL si données patients compromises via poste** | **R/A** | **A** | **I** | **I** |
| **6. Incidents Sécurité** | **Test procédure incident (simulation drill annuelle)** | **R** | **A** | **C** | **R** |

**Justification :**
- Matrice mentionne "gestion incidents" mais pas procédure P1/escalade SLAisée
- Defaillance #6 : SLA escalade / notification absent
- Ransomware/Malware sur parc = risque critique accès données patients
- HDS art. 10 = notification CNIL < 24h si données compromises
- Quarantaine automatique = capacité EPDR + orchestration SIEM
- Forensics + RCA = obligatoire post-incident HDS

---

## 🔴 DOMAINE 7 : ACCÈS DONNÉES PATIENTS VIA POSTES (Traçabilité + Audit)

### ⚠️ **À AJOUTER — Nouvelle section 9. Traçabilité Accès Données**

| Domaine / Groupe | Processus / Activité | IT Manager OneOrtho | Comité technique | AVA6 Infra/MCO | AVA6 SOC (REDSOC) |
|---|---|---|---|---|---|
| **9. Traçabilité Données** | **Audit logs accès fichiers patients (DICOM, dossiers ERP)** | **R/A** | **C** | **I** | **C** |
| **9. Traçabilité Données** | **Monitoring opérations fichiers sensibles (open/read/write/delete)** | **I** | **C** | **I** | **R** |
| **9. Traçabilité Données** | **Logs impression documents patients (qui imprime quoi)** | **R/A** | **C** | **I** | |
| **9. Traçabilité Données** | **Audit tentatives accès non-autorisés données patients** | **R/A** | **C** | **I** | **C** |
| **9. Traçabilité Données** | **Rétention logs accès données minimum 1 an (exigence HDS)** | **R/A** | **C** | **I** | |
| **9. Traçabilité Données** | **Rapport audit accès données (trimestriel)** | **R/A** | **I** | **I** | **C** |

**Justification :**
- Matrice n'inclut PAS traçabilité accès données patients via postes
- HDS art. 6 = logs obligatoires qui accède quoi
- RGPD art. 32 = audit piste tracabilité
- DICOM/ERP sur postes → données identifiées
- Impressions = vecteur fuites données patients
- Rétention 1 an minimum = audit CNIL

---

## 🔴 DOMAINE 8 : RÉSEAU LOCAL (WiFi, Box Internet, Switch)

### ⚠️ **À AJOUTER — Nouvelle section 10. Sécurité Réseau Local**

| Domaine / Groupe | Processus / Activité | IT Manager OneOrtho | Comité technique | AVA6 Infra/MCO | AVA6 SOC (REDSOC) |
|---|---|---|---|---|---|
| **10. Sécurité Réseau** | **Configuration WiFi sécurisée (WPA3, clés fortes)** | **R/A** | **C** | **C** | |
| **10. Sécurité Réseau** | **Audit WiFi (scan réseaux voisins, rogue AP détection)** | **R/A** | **C** | **C** | **C** |
| **10. Sécurité Réseau** | **Monitoring WiFi accès (logs connexion/déconnexion)** | **I** | **C** | **I** | **R** |
| **10. Sécurité Réseau** | **Segmentation VLAN patient vs admin vs guest (vérification)** | **R/A** | **C** | **C** | **C** |
| **10. Sécurité Réseau** | **Monitoring Switch (détection ARP spoofing, STP anomalies)** | **I** | **C** | **C** | **R** |
| **10. Sécurité Réseau** | **Configuration Box internet (firewall, rules, logs)** | **R/A** | **C** | **C** | |
| **10. Sécurité Réseau** | **Monitoring Box internet (connexion internet uptime, anomalies)** | **I** | **C** | **C** | **R** |
| **10. Sécurité Réseau** | **Audit logs Box internet (connexions bloquées, tentatives brutes)** | **R/A** | **C** | **C** | **C** |
| **10. Sécurité Réseau** | **SLA Box internet failover (redondance connexion internet ?)** | **R/A** | **A** | **C** | |

**Justification :**
- Matrice n'inclut PAS sécurité réseau local
- Q62-Q63 : Architecture réseau + WiFi + Box internet critiques
- WiFi = point d'accès données patients (postes mobiles)
- VLAN segmentation = besoin HDS art. 3 (isolation données)
- Firewall Box internet = première défense contre internet
- Logs réseau = forensics incident obligatoires

---

## 🟠 DOMAINE 9 : GESTION PÉRIPHÉRIQUES (USB, Imprimantes, Scanners)

### ⚠️ **À AJOUTER — Nouvelle section 11. Gestion Périphériques**

| Domaine / Groupe | Processus / Activité | IT Manager OneOrtho | Comité technique | AVA6 Infra/MCO | AVA6 SOC (REDSOC) |
|---|---|---|---|---|---|
| **11. Périphériques** | **Politique contrôle USB (blocage/autorisation selective)** | **R/A** | **C** | **C** | |
| **11. Périphériques** | **Audit accès USB via EPDR (logs connexion USB)** | **R/A** | **C** | **I** | **R** |
| **11. Périphériques** | **Destruction données USB avant déploiement utilisateur** | **R/A** | **C** | **I** | |
| **11. Périphériques** | **Chiffrement données transférées USB (BitLockering)** | **R/A** | **C** | **C** | |
| **11. Périphériques** | **Configuration imprimantes réseau (authentification, logs)** | **R/A** | **C** | **I** | |
| **11. Périphériques** | **Audit logs imprimantes (fichiers imprimés, qui imprime)** | **R/A** | **C** | **I** | **C** |
| **11. Périphériques** | **Destruction données résiduelles imprimantes (toner, cache disque)** | **R/A** | **C** | **I** | |
| **11. Périphériques** | **Politique scanneurs (accès autorisés, destination fichiers)** | **R/A** | **C** | **I** | |

**Justification :**
- Matrice n'inclut PAS gestion périphériques
- USB = vecteur exfiltration données patients critiques
- Imprimantes = données patients en clair (cache disque)
- Destruction données résiduelles = HDS art. 5 obligation
- Logs imprimantes/scanneurs = traçabilité données patients
- Politique contrôle = éviter fuites intentionnelles

---

## 🟠 DOMAINE 10 : CONFORMITÉ RGPD & HDS POSTES

### ⚠️ **À AJOUTER — Section 6. Conformité (compléments)**

| Domaine / Groupe | Processus / Activité | IT Manager OneOrtho | Comité technique | AVA6 Infra/MCO | AVA6 SOC (REDSOC) |
|---|---|---|---|---|---|
| **6. Conformité Parc** | **Classification données stockées postes (patient-ID vs pseudonymisée)** | **R/A** | **A** | **I** | |
| **6. Conformité Parc** | **Audit piste tracabilité données patients (qui accède)** | **R/A** | **C** | **I** | **C** |
| **6. Conformité Parc** | **Procédure droit d'accès patient (données stockées postes)** | **R/A** | **A** | **I** | |
| **6. Conformité Parc** | **Procédure rectification données patients via postes (audit trails)** | **R/A** | **C** | **I** | |
| **6. Conformité Parc** | **Procédure droit à l'oubli (suppression données patients)** | **R/A** | **C** | **I** | |
| **6. Conformité Parc** | **Audit annuel conformité RGPD/HDS parc informatique** | **R/A** | **A** | **C** | **I** |
| **6. Conformité Parc** | **Mise à jour politique de confidentialité postes** | **R/A** | **A** | **I** | |

**Justification :**
- Matrice mentionne "politique sécurité" mais pas droits d'accès RGPD
- RGPD art. 12-22 = droits patient (accès, rectification, oubli)
- Postes stockent données patients indirectes
- Audit piste = traçabilité accès obligatoire HDS
- Conformité annuelle = audit CNIL démontrable

---

## 🟡 DOMAINE 11 : MONITORING PERFORMANCE & DISPONIBILITÉ PARC

### ⚠️ **À AJOUTER — Nouvelle section 12. Monitoring Performance**

| Domaine / Groupe | Processus / Activité | IT Manager OneOrtho | Comité technique | AVA6 Infra/MCO | AVA6 SOC (REDSOC) |
|---|---|---|---|---|---|
| **12. Monitoring** | **Monitoring CPU/RAM/Disque postes (alertes si > 85%)** | **I** | **C** | **I** | |
| **12. Monitoring** | **Alertes connectivité réseau postes (latence, déconnexions)** | **I** | **C** | **C** | **R** |
| **12. Monitoring** | **Monitoring santé EPDR agent (absent/offline postes)** | **I** | **C** | **I** | **R** |
| **12. Monitoring** | **Dashboard inventaire postes (online/offline status)** | **I** | **C** | **I** | |
| **12. Monitoring** | **Alertes postes non-conformes (patch missing, EPDR disabled)** | **I** | **C** | **I** | **R** |

**Justification :**
- Matrice n'inclut PAS monitoring proactif parc
- Détection postes offline = criticité pour données patients
- EPDR agent offline = perte détection anomalies
- Non-conformité patch = risque sécurité augmenté
- Dashboard = visibility opérationnelle gestion parc

---

## 📊 RÉSUMÉ — Points manquants complète

**Nombre d'activités manquantes : 61 nouvelles lignes**

| Domaine | Nb Activités Manquantes | Impact HDS |
|---|---|---|
| 1. Tests Sécurité & Pentest | 6 | **CRITIQUE** |
| 2. Monitoring EPDR & Alertes | 7 | **CRITIQUE** |
| 3. Destruction Équipements | 6 | **CRITIQUE** |
| 4. Chiffrement Postes & USB | 5 | **CRITIQUE** |
| 5. CVE & Patch Management | 6 | **CRITIQUE** |
| 6. Incidents P1 & Escalade | 7 | **CRITIQUE** |
| 7. Traçabilité Accès Données | 6 | **CRITIQUE** |
| 8. Sécurité Réseau Local (WiFi/Box/Switch) | 9 | **CRITIQUE** |
| 9. Gestion Périphériques (USB/Imprimantes) | 8 | **MAJEURE** |
| 10. Conformité RGPD & HDS Postes | 7 | **MAJEURE** |
| 11. Monitoring Performance & Disponibilité | 5 | **MAJEURE** |
| **TOTAL** | **61** | — |

---

## 📌 **Recommandations prioritaires (Parc IT OneOrtho On-Site)**

### **P0 — AVANT mise en production accès données patients via parc :**
1. **Chiffrement BitLocker** (Défaillance #5) : Vérifier activé 100% des postes
2. **Audit CVE** : Identifier vulnérabilités critiques exploitables
3. **Segmentation VLAN** : Valider isolation VLAN patient vs admin
4. **Destruction sécurisée** : Procéduriser destruction postes (Défaillance #8)
5. **Tests sécurité** : Pentest parc + WiFi robustesse

### **P1 — 30 jours après deployment postes :**
1. Implémenter monitoring EPDR alertes (brutes force, anomalies)
2. Configurer escalade incidents P1 (SLA < 30 min)
3. Audit accès données patients via postes (qui accède quoi)
4. Tests pentest parc (escalade privilèges)

### **P2 — Avant audit CNIL/HDS :**
1. Rapport audit annuel conformité parc
2. Traçabilité complète accès données patients
3. Certificat destruction de postes anciens
4. Procédures RGPD (droits d'accès, rectification, oubli)

---

## 📎 **Références croisées**

> **Liens avec Matrice #02 (AD/Filer) :**
> - Authentification postes → AD (logs authentification obligatoires)
> - Accès données Filer → contrôlé via postes
> - Traçabilité accès → combinaison postes + AD + Filer

> **Liens avec Matrice #01 (OneSoftware) :**
> - Accès application One-platform → via postes locales ou VPN
> - Données patients ERP → transitent via parc informatique
> - EPDR postes ← connecté SIEM AVA6 (alertes corrélées)

> **Exigences HDS directes :**
> - Art. 3 : Isolement données (VLAN segmentation)
> - Art. 4 : Chiffrement (BitLocker, USB)
> - Art. 5 : Destruction (procéduralisée)
> - Art. 6 : Accès limité + traçabilité (logs, audit)
> - Art. 9 : Pentest annuels
> - Art. 10 : Notification incidents (SLA < 24h)

