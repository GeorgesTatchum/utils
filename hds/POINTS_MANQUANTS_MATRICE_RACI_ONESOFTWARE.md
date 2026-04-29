# POINTS MANQUANTS — Matrice RACI Infra Applicatif OneSoftware
## Analyse basée sur contrat AVA6 + questionnaires HDS

**Date :** 20 avril 2026  
**Classification :** CONFIDENTIEL

---

## 🔑 **CLARIFICATION RÔLES RACI (CRITIQUE)**

### Distinction acteurs — Infrastructure Hébergée AVA6 + On-Site OneOrtho

| Acteur | Responsabilité | Rôle Type RACI |
|---|---|---|
| **IT Manager OneOrtho** | Pilote IT responsable OneOrtho | **R/A** (Réalise + Accountable légal) |
| **Comité technique OneOrtho** | Groupe collectif techs lead on-site | **C/A** (Consulté + Approuve décisions strat) |
| **Équipe Dev OneOrtho** | Développement applicatif | **R** (Déploie appli) |
| **AVA6 Infra/MCO** | Prestataire infrastructure hébergée | **R/C** (Exécute + Consulté) |
| **AVA6 SOC (REDSOC)** | Prestataire sécurité/monitoring | **R/I** (Détection + Informé incidents) |

### Application à OneSoftware Hébergé

> **Responsabilité Infrastructure Applicative (données patients chez AVA6):**
> - **IT Manager** = Pilote global, approuve, valide conformité
> - **Comité technique** = Groupe de techs lead = Approuve avant action critique
> - **Équipe Dev** = Exécute déploiements applicatifs  
> - **AVA6 Infra/MCO** = Exécute MCO infrastructure (backups, patching, monitoring)
> - **AVA6 SOC** = Détecte anomalies (SIEM, alertes)

> **Important:** 
> - **"Comité technique"** = collectif de techs lead OneOrtho (pas une personne unique)
> - N'exécute jamais, seul **IT Manager** / **équipes spécialisées** exécutent
> - APPROUVE/CONSULTE avant exécution actions sensibles

---

## 📋 DOMAINE 1 : SÉCURITÉ & DÉTECTION (Défaillances #3, #6, #7)

### ⚠️ **À AJOUTER — Section 2. MCO**

| Domaine / Groupe | Processus / Activité | IT Manager OneOrtho | Comité technique | AVA6 Infra/MCO | AVA6 SOC (REDSOC) | Équipe Dev OneOrtho |
|---|---|---|---|---|---|---|
| **2. MCO** | **Tests de pénétration annuels (infra hébergeant données)** | **A** | **C** | **R** | **C** | |
| **2. MCO** | **Gestion des alertes SIEM/SOC (détection incidents)** | **R/A** | **I** | **C** | **R** | **I** |
| **2. MCO** | **Escalade incidents critiques SIEM → OneOrtho (SLA notif)** | **A** | **I** | **I** | **R** | |
| **2. MCO** | **Scan de vulnérabilité continu (fréquence SLAisée)** | **A** | **C** | **R** | **C** | |
| **2. MCO** | **Gestion CVE critiques (CVSS > 7.0) — remediation SLA** | **A** | **C** | **R** | **I** | **C** |

**Justification :**
- Contrat mentionne SIEM REDSOC mais **aucun SLA de détection/notification**
- Tests pentest = obligatoire HDS art. 9 mais pas contractualisé
- Scan vulnérabilité = besoin HDS art. 9.1 (minimum mensuel)

---

## 📋 DOMAINE 2 : CHIFFREMENT & INTÉGRITÉ DONNÉES (Défaillance #5) X

### ⚠️ **À AJOUTER — Nouvelle section 8. Chiffrement & Intégrité**

| Domaine / Groupe | Processus / Activité | IT Manager OneOrtho | Comité technique | AVA6 Infra/MCO | AVA6 SOC (REDSOC) | Équipe Dev OneOrtho |
|---|---|---|---|---|---|---|
| **8. Chiffrement & Intégrité** | **Chiffrement données au repos (VM, backups)** | **A** | **C** | **R** | | |
| **8. Chiffrement & Intégrité** | **Chiffrement données en transit (VPN IPSec, HTTPS)** | **A** | **C** | **R** | | |
| **8. Chiffrement & Intégrité** | **Gestion des clés de chiffrement (rotation, stockage)** | **A** | **C** | **R** | | |
| **8. Chiffrement & Intégrité** | **Validation chiffrement (audit technique semestriel)** | **A** | **C** | **R** | **C** | |

**Justification :**
- Contrat ne précise PAS algorithme chiffrement (AES-256 ?)
- HDS art. 4 = chiffrement obligatoire données santé en transit/repos
- Gestion clés = responsabilité critique manquante

---

## 📋 DOMAINE 3 : RÉSEAU & CONNECTIVITÉ (Q62-Q68)

### ⚠️ **À AJOUTER — Nouvelle section 9. Infrastructure Réseau**

| Domaine / Groupe | Processus / Activité | IT Manager OneOrtho | Comité technique | AVA6 Infra/MCO | AVA6 SOC (REDSOC) | Équipe Dev OneOrtho |
|---|---|---|---|---|---|---|
| **9. Infrastructure Réseau** | **Configuration & maintenance VPN site-to-site (IPSec)** | **A** | **C** | **R** | | |
| **9. Infrastructure Réseau** | **Monitoring tunnel VPN (uptime, connexions/déconnexions)** | **I** | **I** | **R** | **C** | |
| **9. Infrastructure Réseau** | **Gestion redondance VPN (failover automatique, SLA RTO)** | **A** | **C** | **R** | | |
| **9. Infrastructure Réseau** | **Gestion clés IPSec VPN (rotation semestrielle)** | **A** | **C** | **R** | | |
| **9. Infrastructure Réseau** | **Documentation architecture réseau VLAN OneOrtho** | **A** | **R** | **C** | | |
| **9. Infrastructure Réseau** | **Configuration & audit firewall rules OneOrtho** | **A** | **C** | **R** | **C** | |
| **9. Infrastructure Réseau** | **Gestion connexion Internet OneOrtho (SLA fournisseur)** | **R/A** | **C** | **I** | | |

**Justification :**
- Q62-Q68 = architecture réseau site OneOrtho entièrement absente du contrat
- VPN site-to-site critique non documenté (chiffrement, failover, monitoring)
- VLAN segmentation = besoin HDS art. 3 mais pas documenté localement

---

## 📋 DOMAINE 4 : ISOLEMENT & MULTITENANCY (Défaillances #4, #6)

### ⚠️ **À AJOUTER — Section 7. Gouvernance (complément)**

| Domaine / Groupe | Processus / Activité | IT Manager OneOrtho | Comité technique | AVA6 Infra/MCO | AVA6 SOC (REDSOC) | Équipe Dev OneOrtho |
|---|---|---|---|---|---|---|
| **7. Gouvernance & Conformité HDS** | **Test isolement inter-VLAN OneOrtho ↔ autres clients (trimestriel)** | **A** | **C** | **R** | **C** | |
| **7. Gouvernance & Conformité HDS** | **Audit isolement CPU/RAM avec autres clients (contrainte ressources)** | **A** | **C** | **R** | | |
| **7. Gouvernance & Conformité HDS** | **Vérification configuration firewall inter-clients (review SLA)** | **A** | **C** | **R** | **C** | |

**Justification :**
- Isolement inter-client = besoin HDS art. 3 mais pas de test contractualisé
- Defaillance #4 : "VLAN dédié par client" ne suffit pas → test isolement obligatoire
- Monitoring contention CPU/RAM = besoin SLA garantie ressources

---

## 📋 DOMAINE 5 : TRAÇABILITÉ & ACCÈS DONNÉES (Défaillances #2, #10)

### ⚠️ **À AJOUTER — Section 10. Accès & Traçabilité Données Patient**

| Domaine / Groupe | Processus / Activité | IT Manager OneOrtho | Comité technique | AVA6 Infra/MCO | AVA6 SOC (REDSOC) | Équipe Dev OneOrtho |
|---|---|---|---|---|---|---|
| **10. Accès & Traçabilité** | **Audit trails : logs accès base applicative par techs AVA6** | **A** | **C** | **R** | **C** | |
| **10. Accès & Traçabilité** | **Contrôle technique : interdiction consultation données patients** | **A** | **C** | **R** | **C** | |
| **10. Accès & Traçabilité** | **Formation confidentialité HDS pour personnel AVA6 (annuelle)** | **A** | **C** | **R** | | |
| **10. Accès & Traçabilité** | **Signature clauses confidentialité techniciens AVA6 (avant accès)** | **A** | **C** | **R** | | |
| **10. Accès & Traçabilité** | **Audit d'accès RDP par techniciens (identification non-autorisés)** | **A** | **R** | **C** | **C** | |
| **10. Accès & Traçabilité** | **Audit MFA logs (tentatives connexion bruteforce, géolocalisation)** | **A** | **I** | **C** | **R** | |

**Justification :**
- Defaillance #2 : absence clause "interdit consultation données" 
- HDS art. 6 = accès technique seulement (exploit monitoring obligatoire)
- Defaillance #10 : droit d'audit OneOrtho non documenté
- Q41-Q43 = traçabilité accès techniciens manquante

---

## 📋 DOMAINE 6 : CONFORMITÉ & NOTIFICATION (Défaillance #6, #12)

### ⚠️ **À AJOUTER — Section 7. Gouvernance (complément)**

| Domaine / Groupe | Processus / Activité | IT Manager OneOrtho | Comité technique | AVA6 Infra/MCO | AVA6 SOC (REDSOC) | Équipe Dev OneOrtho |
|---|---|---|---|---|---|---|
| **7. Gouvernance & Conformité HDS** | **Notification incident de sécurité CNIL (< 24h AVA6 → OneOrtho)** | **A** | **I** | **R** | **I** | **I** |
| **7. Gouvernance & Conformité HDS** | **Gestion déclaration CNIL violations données (OneOrtho responsable)** | **R/A** | **C** | **I** | **I** | |
| **7. Gouvernance & Conformité HDS** | **Procédure escalade incident P1 vers comité crises OneOrtho** | **R/A** | **C** | **I** | **R** | |
| **7. Gouvernance & Conformité HDS** | **Forensics post-incident : logs OneOrtho + SIEM AVA6** | **A** | **R** | **C** | **R** | |
| **7. Gouvernance & Conformité HDS** | **Procédure accès données sur réquisition judiciaire** | **R/A** | **C** | **C** | **C** | |

**Justification :**
- Defaillance #6 : pas de SLA notification incidents
- HDS art. 10 = notification OneOrtho < 24h (pas contractualisée)
- Q60-Q61 = procédure réquisition judiciaire absente

---

## 📋 DOMAINE 7 : DESTRUCTION & FIN DE CONTRAT (Défaillance #8)

### ⚠️ **À AJOUTER — Section 4. Sauvegarde & Restauration (complément)**

| Domaine / Groupe | Processus / Activité | IT Manager OneOrtho | Comité technique | AVA6 Infra/MCO | AVA6 SOC (REDSOC) | Équipe Dev OneOrtho |
|---|---|---|---|---|---|---|
| **4. Sauvegarde & Restauration (HDS)** | **Destruction sécurisée données OneOrtho (procédure formelle)** | **A** | **C** | **R** | | |
| **4. Sauvegarde & Restauration (HDS)** | **Certificat destruction données (avec hashes avant suppression)** | **A** | **R** | **C** | | |
| **4. Sauvegarde & Restauration (HDS)** | **Audit traces destruction données (logs suppression, dates)** | **A** | **R** | **C** | **C** | |

**Justification :**
- Defaillance #8 : pas de procédure destruction contractualisée
- HDS art. 5 = destruction sécurisée obligatoire + certificat
- Q10 : rétention = 15j mais destruction = non documentée

---

## 📋 DOMAINE 8 : QUALITY & REPORTING (Service Continuity)

### ⚠️ **À AJOUTER — Nouvelle section 11. Suivi de Qualité de Service**

| Domaine / Groupe | Processus / Activité | IT Manager OneOrtho | Comité technique | AVA6 Infra/MCO | AVA6 SOC (REDSOC) | Équipe Dev OneOrtho |
|---|---|---|---|---|---|---|
| **11. Suivi QoS** | **Rapport mensuel activité MCO (incidents, changements)** | **A** | **I** | **R** | **I** | |
| **11. Suivi QoS** | **Analyse trimestrielle incidents SLA (trending, RCA)** | **R/A** | **R** | **C** | **I** | |
| **11. Suivi QoS** | **Métrique MTTD/MTTR (Mean Time To Detect/Respond)** | **A** | **I** | **C** | **R** | |
| **11. Suivi QoS** | **Revue semestrielle sécurité datacenter AVA6 (rapports audit)** | **A** | **C** | **R** | **C** | |

**Justification :**
- Contrat mentionne "rapport mensuel" mais pas responsabilité claire
- MTTD/MTTR = KPIs HDS recommandés pour détection
- Q14 = SLA notification manquante

---

## 📋 DOMAINE 9 : GESTION DES ACCÈS À DISTANCE (MFA & VPN Employés)

### ⚠️ **À AJOUTER — Section 1. Provisioning (complément)**

| Domaine / Groupe | Processus / Activité | IT Manager OneOrtho | Comité technique | AVA6 Infra/MCO | AVA6 SOC (REDSOC) | Équipe Dev OneOrtho |
|---|---|---|---|---|---|---|
| **1. Provisioning & Configuration** | **Déploiement & gestion MFA (WatchGuard AuthPoint)** | **R** | **C** | **C** | | |
| **1. Provisioning & Configuration** | **Audit logs MFA (tentatives brutes, bypasss, géolocalisation)** | **A** | **I** | **C** | **R** | |
| **1. Provisioning & Configuration** | **Monitoring VPN salariés (10x VPN + fallback 4G ?)** | **A** | **I** | **R** | **C** | |

**Justification :**
- Contrat mentionne "10 x VPN pour employés" mais pas gestion formalisée
- MFA = élément clé détection incidents (logs MFA dans SIEM)
- Question Q63 : connexion internet OneOrtho et redondance absent

---

## 🎯 **RÉSUMÉ — Points manquants complète**

**Nombre d'activités manquantes : 32 nouvelles lignes**

| Domaine | Nb Activités Manquantes | Impact HDS |
|---|---|---|
| 1. Sécurité & Détection SIEM | 5 | **CRITIQUE** |
| 2. Chiffrement & Intégrité | 4 | **CRITIQUE** |
| 3. Infrastructure Réseau | 7 | **CRITIQUE** |
| 4. Isolement & Multitenancy | 3 | **CRITIQUE** |
| 5. Accès & Traçabilité Données | 6 | **CRITIQUE** |
| 6. Conformité & Notification | 5 | **CRITIQUE** |
| 7. Destruction & Fin de Contrat | 3 | **MAJEURE** |
| 8. Qualité de Service | 4 | **MAJEURE** |
| 9. Gestion Accès Distants (MFA/VPN) | 3 | **MAJEURE** |
| **TOTAL** | **40** | — |

---

## 📌 **Recommandations prioritaires**

### **P0 — Avant signature accord final :**
1. **Défaillance #6** : Ajouter SLA notification incidents SIEM (< 24h pour P1)
2. **Défaillance #3** : Contractualiser tests pentest annuels (scope, dates)
3. **Défaillance #5** : Clarifier chiffrement AES-256 en transit/repos
4. **Défaillance #4** : Demander diagramme isolement VLAN + test isolement trimestriel

### **P1 — 30 jours après signature :**
1. Récupérer architecture complète réseau OneOrtho (Q62-Q65)
2. Obtenir plan gestion clés chiffrement (rotation, stockage)
3. Audit baselines sécurité infrastructure OneOrtho

### **P2 — Avant mise en production donnée patient :**
1. Validation test isolement inter-client
2. Test PRA/PCA restauration données
3. Audit accès techniciens (interdiction consultation base patient)

---

## 📎 **Références**

- **Contrat AVA6** sections : P.1 (DC), P.2 (HDS), P.3 (VLAN)
- **Defaillances identifiées** : #2, #3, #4, #5, #6, #8, #10, #12
- **Questions Q41-Q76** : Toutes les lacunes architecture réseau site
- **HDS art. 3, 4, 6, 9, 10** : Fondamentales manquantes

