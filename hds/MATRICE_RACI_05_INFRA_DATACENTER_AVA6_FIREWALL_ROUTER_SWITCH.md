# Matrice RACI — 05 — Infra Datacenter AVA6 — Firewall | Router | Switch
## Infrastructure Interne AVA6 (Mutualisée Clients)

**Date :** 27 avril 2026  
**Classification :** CONFIDENTIEL — Infrastructure AVA6  
**Périmètre :** Firewall, Router, Switch, VPN, Segmentation réseau, MCO infrastructure  
**Contexte :** Infrastructure mutualisée AVA6 (partagée multi-clients + OneOrtho)

---

## 🔑 **CLARIFICATION RÔLES RACI — Infrastructure Interne AVA6**

### Distinction acteurs — Infrastructure Datacenter Mutualisée

| Acteur | Responsabilité | Rôle Type RACI |
|---|---|---|
| **IT Manager OneOrtho** | Responsable numérique OneOrtho (demandes, approbation) | **A/C** (Accountable + Consulté pour changements) |
| **Comité technique OneOrtho** | Ensemble tech leads (validation stratégique) | **C/A** (Consulté + approuve changements importants) |
| **CEO OneOrtho** | Direction exécutive (budgets contrats) | **A** (Approuve budgets multi-année AVA6) |
| **AVA6 Infra/MCO** | Opérateur infrastructure mutualisée | **R** (Réalise + gère infrastructure pour tous clients) |
| **AVA6 SOC (REDSOC)** | Monitoring sécurité réseau 24/7 | **R/C** (Détection + rapporte anomalies) |

### Application Infrastructure Réseau Mutualisée

> **IMPORTANT — Responsabilité partagée datacenter :**
> - **AVA6** = **R** (Opérateur mutualisé, SLA infrastructure, disponibilité)
> - **OneOrtho** = **A/C** (Approuve changements, consulté demandes)
> - **REDSOC** = **R** (Détecte anomalies réseau/flux)
> - **Comité tech** = **C** (Valide changements OneOrtho)

> **HDS Article 2 (Infrastructure Mutualisée) :**
> - AVA6 assure isolement inter-clients (VLAN, firewall, réseau logique)
> - OneOrtho approuve architecture sécurité (qui impacte ses données)
> - Segregation données = responsabilité partagée (AVA6 opère, OneOrtho approuve)

---

## 🔴 **SECTION 1 : FIREWALL — GESTION & FILTRAGE**

### Justification HDS
- **HDS art. 3** = Isolement données (firewall = première défense)
- **HDS art. 9** = Contrôle accès (règles filtrage)
- **HDS art. 2** = Mutualisation sécurisée (clients isolés)

### Domaine 1A — Administration Firewall

| Domaine / Groupe | Processus / Activité | IT Manager | Comité technique | AVA6 Infra/MCO | REDSOC |
|---|---|---|---|---|---|
| **1A. Admin** | **[CRITIQUE HDS] Gestion cluster Firewall mutualisé (HA/failover)** | **C** | **I** | **R** | **C** |
| **1A. Admin** | **[CRITIQUE HDS] Architecture firewall (isolement OneOrtho)** | **A** | **A** | **R** | **C** |
| **1A. Admin** | **Mise à jour firmware firewall (security patches)** | **I** | **I** | **R** | **I** |
| **1A. Admin** | **MCO cluster Firewall (tests failover, HA validation)** | **I** | **I** | **R** | **I** |

### Domaine 1B — Règles & Matrice de Flux

| Domaine / Groupe | Processus / Activité | IT Manager | Comité technique | AVA6 Infra/MCO | REDSOC |
|---|---|---|---|---|---|
| **1B. Règles** | **[CRITIQUE HDS] Demande ouverture/fermeture flux OneOrtho** | **R/A** | **C** | **C** | **C** |
| **1B. Règles** | **[CRITIQUE HDS] Validation + application règles filtrage** | **A** | **C** | **R** | **C** |
| **1B. Règles** | **[CRITIQUE HDS] Documentation matrice flux (entrée/sortie OneOrtho)** | **R/A** | **C** | **C** | |
| **1B. Règles** | **[CRITIQUE HDS] Revue trimestrielle règles firewall (audit conformité)** | **A** | **A** | **C** | **I** |
| **1B. Règles** | **Tests règles firewall (faux services blockés/allowés)** | **I** | **C** | **R** | **C** |

### Domaine 1C — Logs & Monitoring

| Domaine / Groupe | Processus / Activité | IT Manager | Comité technique | AVA6 Infra/MCO | REDSOC |
|---|---|---|---|---|---|
| **1C. Logs** | **[CRITIQUE HDS] Logs firewall collectés au SIEM AVA6** | **I** | **I** | **R** | **R** |
| **1C. Logs** | **[CRITIQUE HDS] Monitoring alertes firewall (blocages suspects)** | **I** | **I** | **I** | **R** |
| **1C. Logs** | **Rapport mensuel firewall (connexions, blocages, trends)** | **A** | **I** | **R** | **I** |

---

## 🔴 **SECTION 2 : VPN — ACCÈS DISTANTS SÉCURISÉS**

### Justification HDS
- **HDS art. 4** = Chiffrement données en transit (VPN IPSec OpenVPN)
- **HDS art. 6** = Traçabilité connexions distantes
- **MFA obligatoire** = (HDS fort recommandé pour accès sensibles)

### Domaine 2A — Configuration & Administration

| Domaine / Groupe | Processus / Activité | IT Manager | Comité technique | AVA6 Infra/MCO | REDSOC |
|---|---|---|---|---|---|
| **2A. Config** | **[CRITIQUE HDS] Configuration + administration VPN d'accès** | **A** | **C** | **R** | **I** |
| **2A. Certificats** | **[CRITIQUE HDS] Gestion certificats VPN (clés IKE, renouvellement)** | **A** | **C** | **R** | **I** |
| **2A. Certificats** | **[CRITIQUE HDS] Rotation certificats VPN (annuellement)** | **I** | **I** | **R** | **I** |

### Domaine 2B — Identités & Accès

| Domaine / Groupe | Processus / Activité | IT Manager | Comité technique | AVA6 Infra/MCO | REDSOC |
|---|---|---|---|---|---|
| **2B. Identités** | **Création/révocation compte VPN utilisateurs** | **R/A** | **C** | **C** | **I** |
| **2B. Identités** | **Gestion groupes VPN (accès segmenté par client)** | **R/A** | **C** | **C** | **I** |
| **2B. Auth** | **[CRITIQUE HDS] MFA accès VPN (authentification multifacteur)** | **A** | **A** | **C** | **C** |

### Domaine 2C — Monitoring & Audit

| Domaine / Groupe | Processus / Activité | IT Manager | Comité technique | AVA6 Infra/MCO | REDSOC |
|---|---|---|---|---|---|
| **2C. Monitoring** | **[CRITIQUE HDS] Surveillance sessions VPN actives (temps réel)** | **I** | **I** | **R** | **R** |
| **2C. Audit** | **[CRITIQUE HDS] Audit connexions VPN (mensuel, qui a accédé quand)** | **A** | **C** | **R** | **I** |
| **2C. Alertes** | **Alertes VPN anomalies (connexions après-heures, échuées)** | **I** | **C** | **R** | **R** |

---

## 🔴 **SECTION 3 : SEGMENTATION RÉSEAU (VLAN)**

### Justification HDS
- **HDS art. 3** = Isolement données patients (VLAN mandatory)
- **HDS art. 2** = Mutualisation sécurisée (clients isolés VLAN)
- **Multi-layered defense** = VLAN + firewall rules

### Domaine 3A — Architecture & Conception

| Domaine / Groupe | Processus / Activité | IT Manager | Comité technique | AVA6 Infra/MCO | REDSOC |
|---|---|---|---|---|---|
| **3A. Architecture** | **[CRITIQUE HDS] Conception plan adressage + VLANs OneOrtho** | **A** | **A** | **R** | **C** |
| **3A. Architecture** | **[CRITIQUE HDS] Isolation inter-clients (données OneOrtho vs autres)** | **A** | **A** | **R** | **C** |
| **3A. Architecture** | **[CRITIQUE HDS] Ségrégation prod/préprod/gestion (VLAN dédiée)** | **A** | **A** | **R** | **C** |

### Domaine 3B — Configuration & Validation

| Domaine / Groupe | Processus / Activité | IT Manager | Comité technique | AVA6 Infra/MCO | REDSOC |
|---|---|---|---|---|---|
| **3B. Config** | **Configuration VLANs sur switches AVA6** | **I** | **C** | **R** | **I** |
| **3B. Test** | **[CRITIQUE HDS] Test isolement VLAN (pentest segmentation)** | **I** | **A** | **C** | **C** |
| **3B. Test** | **[CRITIQUE HDS] Test ping cross-VLAN (unauthorized should fail)** | **I** | **I** | **R** | **C** |

### Domaine 3C — Documentation & Maintenance

| Domaine / Groupe | Processus / Activité | IT Manager | Comité technique | AVA6 Infra/MCO | REDSOC |
|---|---|---|---|---|---|
| **3C. Doc** | **[CRITIQUE HDS] Mise à jour cartographie réseau (OneOrtho VLAN)** | **A** | **C** | **R** | **I** |
| **3C. Doc** | **Documentation isolement réseau (pour audit CNIL)** | **A** | **C** | **R** | **I** |

---

## 🔴 **SECTION 4 : ROUTER & SWITCH — MAINTENANCE OPÉRATIONNELLE**

### Justification HDS
- **HDS art. 3** = Infrastructure disponibilité (SLA 99.98%)
- **Uptime critique** = MCO firmware + tests failover

### Domaine 4A — Maintenance Fichier & Firmware

| Domaine / Groupe | Processus / Activité | IT Manager | Comité technique | AVA6 Infra/MCO | REDSOC |
|---|---|---|---|---|---|
| **4A. MCO** | **MCO routeurs (firmware sécurité, disponibilité)** | **I** | **I** | **R** | **I** |
| **4A. MCO** | **MCO switches (firmware, STP, liaisons redondance)** | **I** | **I** | **R** | **I** |
| **4A. Tests** | **Tests redondance (failover liaison fiber, wan backup)** | **I** | **I** | **R** | **I** |

### Domaine 4B — Supervision & Incidents

| Domaine / Groupe | Processus / Activité | IT Manager | Comité technique | AVA6 Infra/MCO | REDSOC |
|---|---|---|---|---|---|
| **4B. Supervision** | **Supervision réseau (latence, pertes paquets, saturation)** | **I** | **I** | **R** | **I** |
| **4B. Alertes** | **Alertes seuils (CPU/RAM equipment, bandwidth utilization)** | **I** | **I** | **R** | **I** |
| **4B. Incidents** | **Gestion incidents réseau P1/P2 (SLA < 4h P1)** | **I** | **C** | **R** | **C** |
| **4B. RCA** | **Root Cause Analysis incidents réseau** | **I** | **C** | **R** | **C** |

### Domaine 4C — Rapports SLA

| Domaine / Groupe | Processus / Activité | IT Manager | Comité technique | AVA6 Infra/MCO | REDSOC |
|---|---|---|---|---|---|
| **4C. SLA** | **[CRITIQUE HDS] Rapport mensuel disponibilité réseau (SLA tracking)** | **A** | **I** | **R** | **I** |
| **4C. SLA** | **Attestation SLA 99.98% (communiqué client mensuellement)** | **A** | **I** | **R** | **I** |

---

## 🔴 **SECTION 5 : SÉCURITÉ RÉSEAU**

### Justification HDS
- **HDS art. 9** = Détection anomalies (IDS/IPS)
- **HDS art. 3** = Blocage menaces (threat intelligence)
- **Threat hunting** = Proactif vs réactif

### Domaine 5A — Détection & Threat Intelligence

| Domaine / Groupe | Processus / Activité | IT Manager | Comité technique | AVA6 Infra/MCO | REDSOC |
|---|---|---|---|---|---|
| **5A. Détection** | **[CRITIQUE HDS] Détection intrusion réseau (IDS/IPS REDSOC)** | **I** | **I** | **C** | **R** |
| **5A. Analyse** | **[CRITIQUE HDS] Analyse logs réseau au SIEM (anomalies décorrelées)** | **I** | **I** | **C** | **R** |
| **5A. TI** | **[CRITIQUE HDS] Blocage IPs malveillantes (threat intelligence feeds)** | **I** | **I** | **C** | **R** |
| **5A. TI** | **Mise à jour listes noires (weekly basis minimum)** | **I** | **I** | **I** | **R** |

### Domaine 5B — Tests Sécurité

| Domaine / Groupe | Processus / Activité | IT Manager | Comité technique | AVA6 Infra/MCO | REDSOC |
|---|---|---|---|---|---|
| **5B. Tests** | **[CRITIQUE HDS] Test de pénétration réseau (annuels)** | **A** | **A** | **C** | **C** |
| **5B. Tests** | **[CRITIQUE HDS] Audit trafic inter-VLAN cross-check** | **I** | **A** | **R** | **C** |
| **5B. NDR** | **Network Detection & Response (anomalies trafic)** | **I** | **I** | **C** | **R** |

### Domaine 5C — Incidents Réseau Sécurité

| Domaine / Groupe | Processus / Activité | IT Manager | Comité technique | AVA6 Infra/MCO | REDSOC |
|---|---|---|---|---|---|
| **5C. Incidents** | **[CRITIQUE HDS] Gestion incidents sécurité réseau (P1/P2)** | **A** | **A** | **C** | **R** |
| **5C. Escalade** | **Escalade P1 réseau sécurité (SLA < 15min REDSOC)** | **I** | **A** | **I** | **R** |
| **5C. Containment** | **Blocage trafic malveillant (ACL d'urgence, IPS rules)** | **I** | **C** | **R** | **R** |

---

## 🔴 **SECTION 6 : GOUVERNANCE & DOCUMENTATION RÉSEAU**

### Justification HDS
- **HDS** = Documentation architecture (audit readiness)
- **Change management** = Traçabilité modifications crit infrastructure
- **Business continuity** = Tests failover reguliers

### Domaine 6A — Documentation Architecture

| Domaine / Groupe | Processus / Activité | IT Manager | Comité technique | AVA6 Infra/MCO | REDSOC |
|---|---|---|---|---|---|
| **6A. Docs** | **[CRITIQUE HDS] Documentation architecture réseau (schémas)** | **A** | **C** | **R** | **I** |
| **6A. Docs** | **[CRITIQUE HDS] Plan isolement OneOrtho (inter-client segregation)** | **A** | **C** | **R** | **I** |
| **6A. Docs** | **Mise à jour topologie réseau (trimestrielle)** | **I** | **C** | **R** | **I** |

### Domaine 6B — Change Management

| Domaine / Groupe | Processus / Activité | IT Manager | Comité technique | AVA6 Infra/MCO | REDSOC |
|---|---|---|---|---|---|
| **6B. CAB** | **[CRITIQUE HDS] Gestion changements réseau (Change Advisory Board)** | **R/A** | **A** | **R** | **C** |
| **6B. Planning** | **Planning fenêtres maintenance réseau (hors-heures)** | **I** | **C** | **R** | **I** |
| **6B. Testing** | **Teste changements réseau (prevalidation en préprod)** | **I** | **C** | **R** | **C** |
| **6B. Rollback** | **Plan rollback changements (rapidité restauration)** | **I** | **A** | **R** | **I** |

### Domaine 6C — Politique & Conformité

| Domaine / Groupe | Processus / Activité | IT Manager | Comité technique | AVA6 Infra/MCO | REDSOC |
|---|---|---|---|---|---|
| **6C. Politique** | **[CRITIQUE HDS] Revue annuelle politique réseau (HDS compliance)** | **A** | **A** | **R** | **C** |
| **6C. Continuité** | **[CRITIQUE HDS] Exercice continuité réseau (bascule HA annuels)** | **A** | **A** | **R** | **C** |
| **6C. Audit** | **Audit conformité réseau (access segregation, SLA compliance)** | **A** | **A** | **R** | **I** |

---

## 📊 **RÉSUMÉ ACTIVITÉS PAR CRITICITÉ HDS**

### **🔴 CRITIQUE HDS (32 activités)** = Obligations légales directes

✅ Architecture firewall (isolement OneOrtho) → HDS art. 3  
✅ Gestion cluster Firewall (HA) → HDS art. 3  
✅ Demande ouverture/fermeture flux → HDS art. 9 (contrôle accès)  
✅ Validation + application règles filtrage → HDS art. 9  
✅ Documentation matrice flux → HDS art. 6 (traçabilité)  
✅ Revue trimestrielle firewall → HDS conformité  
✅ Logs firewall au SIEM → HDS art. 6  
✅ Monitoring alertes firewall → HDS art. 9  

✅ Configuration VPN + certificats → HDS art. 4 (chiffrement)  
✅ MFA accès VPN → HDS recommandation forte  
✅ Surveillance sessions VPN → HDS art. 6 (traçabilité)  
✅ Audit connexions VPN mensuel → HDS art. 6  

✅ Architecture plan adressage VLAN → HDS art. 2 (mutualisation sécurisée)  
✅ Isolation inter-clients → HDS art. 2  
✅ Ségrégation prod/préprod/gestion → HDS art. 3 (isolement)  
✅ Test isolement VLAN (pentest) → HDS art. 3 validation  
✅ Test ping cross-VLAN → HDS art. 3  
✅ Cartographie réseau mise à jour → HDS art. 6  
✅ Documentation isolement réseau → HDS audit readiness  

✅ Rapport SLA 99.98% mensuel → HDS contrat disponibilité  

✅ Détection intrusion réseau (IDS/IPS) → HDS art. 9  
✅ Analyse logs réseau au SIEM → HDS art. 6  
✅ Blocage IPs malveillantes → HDS art. 3 (prévention)  
✅ Test pentest réseau annuels → HDS art. 9  
✅ Audit isolement trafic cross-VLAN → HDS art. 3  
✅ Gestion incidents sécurité réseau → HDS art. 10  

✅ Documentation architecture réseau → HDS audit  
✅ Plan isolement OneOrtho → HDS art. 2  
✅ Gestion changements réseau (CAB) → HDS traçabilité  
✅ Revue annuelle politique réseau → HDS conformité  
✅ Exercice continuité/failover annuel → HDS art. 1 (continuité)  
✅ Audit conformité réseau → HDS compliance  

### **🟡 RECOMMANDÉ (12 activités)** = Bonne pratique sécurité
⚠️ Mise à jour firmware firewall/router  
⚠️ MCO cluster failover tests  
⚠️ Rotation certificats VPN  
⚠️ Gestion groupes VPN  
⚠️ Configuration VLANs switches  
⚠️ MCO equipment (firmware, STP)  
⚠️ Tests redondance liaisons  
⚠️ Supervision latence/perte  
⚠️ Alerts seuils equipment  
⚠️ RCA incidents réseau  
⚠️ NDR anomalies trafic  
⚠️ Planning/testing changements  

---

## 📎 **ARCHITECTURE RÉSEAU MUTUALISÉE AVA6**

### **Topology**
```
Internet (Box Firewall OneOrtho) 
    ↓ (IPSec VPN Site-to-Site)
Firewall Cluster AVA6 (Palo Alto / WatchGuard)
    ├─ Router Core (failover pair)
    ├─ Switch Core (redundant)
    ├─ VLAN OneOrtho-PROD (données patients)
    ├─ VLAN OneOrtho-MGMT (gestion)
    ├─ VLAN OneOrtho-BACKUP
    ├─ VLAN Autres Clients (ségrégation)
    └─ VLAN Infra AVA6 (management, SOC)
```

### **Isolement Inter-Clients**
- **VLAN d'isolement** = OneOrtho données vs autres clients
- **Firewall rules** = Blocage trafic cross-client
- **Pentest annual** = Vérification isolement maintained
- **REDSOC monitoring** = Détection anomalies trafic

### **Certificats VPN**
- **Site-to-Site** = IPSec OneOrtho ↔ AVA6 (clés pré-partagées ou certificats)
- **Client VPN** = WatchGuard AuthPoint MFA (accès techs OneOrtho)
- **Renouvellement** = Auto 30j avant expiration

### **Disponibilité Réseau**
- **SLA 99.98%** = (52 minutes downtime/an max)
- **Failover routeurs** = Active-Passive ou Active-Active
- **Redundance liens** = Fiber primary + WAN backup
- **Tests mensuels** = Simulated failover (non-production)

---

## 📝 **DISTINCTIONS IMPORTANTES**

### **Infra AVA6 (#05) vs Couche Sécurité (#04)**

| Aspect | Matrice #04 Couche Sécurité | Matrice #05 Infra Réseau |
|---|---|---|
| **SIEM/WAF/EPDR** | Détection + prévention applicative | Monitoring infra (latence, pertes) |
| **Firewall** | Règles spécifiques OneOrtho | Cluster partagé tous clients |
| **VPN** | Données transit chiffrement | Connectivity management |
| **Incidents** | Security incidents (malware, intrusion) | Network incidents (outage, latence) |
| **Focus** | Security controls | Availability/reliability |

### **OneOrtho Responsabilités (On-Site) vs AVA6 (Datacenter)**

| Aspect | On-Site OneOrtho (#03) | Datacenter AVA6 (#05) |
|---|---|---|
| **Firewall** | Box Internet propre OneOrtho | Cluster mutualisé AVA6 |
| **VPN** | Client OneOrtho (WatchGuard) | Infrastructure AVA6 |
| **Réseau** | LAN on-site (postes, serveurs) | Réseau datacenter (VMs, services) |
| **WiFi** | Box WiFi OneOrtho | N/A datacenter |
| **Monit** | Endpoints EPDR + logs | SIEM centralisé REDSOC |

---

## 🔄 **RÉFÉRENCES CROISÉES MATRICES**

| Matrice | Interaction | Description |
|---|---|---|
| #01 OneSoftware | Applications accédées via Reverse Proxy + Firewall | Donnees patients transit HTTPS |
| #02 AD/Filer | AD logs collectes au SIEM via infra réseau | Traçabilité authentification |
| #03 Endpoints | VPN accès postes OneOrtho → datacenter | Mobile/remote access |
| #04 Couche Sécurité | Logs firewall/VPN au SIEM AVA6 | Détection anomalies réseau |
| **#05 Infra Réseau** | **← VOUS ÊTES ICI** | Fondation physique AVA6 |

---

## ⚠️ **CHANGEMENTS APPLIQUÉS vs VERSION INITIALE**

| Ancien | Nouveau | Raison |
|---|---|---|
| "CTO OneOrtho" | "IT Manager OneOrtho" | Alignement terminologie matrices précédentes |
| Aucune criticité marquée | 🔴 32 CRITIQUES vs 🟡 12 RECOMMANDÉS | Clarifier obligations HDS vs bonnes pratiques |
| "Incidents réseau P1/P2" flou | SLA < 4h P1 formalisé + RCA | HDS art. 10 notification rapide |
| Aucune activité destruction | Aucun équipement (infrastructure mutualisée) | N/A pour infra AVA6 (pas destruction OneOrtho) |
| "Tests isolement" absent | 🔴 SECTION 3C "Test isolement VLAN" + pentest | HDS art. 2 validation mutualisation |
| "Audit conformité" flou | 🔴 Audit trail HDS + compliance check | Documentation audit-ready |
| Rôles OneOrtho mal définis | IT Manager = A/C, Comité = C/A, CEO = A | Alignement hiérarchie décision |
| CAB ("Change Advisory Board") flou | 🔴 "Gestion changements réseau (CAB)" formalisé | Traçabilité modifications critique infra |
| Aucun exercice continuité | 🔴 "Exercice failover annuels" mandaté | Test réaliste RTO/RPO |

---

## 📊 **MATRICE RÉSUMÉE — RACI FINAL**

### Légende Codes
- **R** = Responsible (exécute)
- **A** = Accountable (approuve final)
- **C** = Consulted (avis demandé)
- **I** = Informed (notification)
- **R/A** = Responsable + Accountable dual

### Modèle Distribution Rôles Type
- **IT Manager** = A ou R/A (demandes OneOrtho) / C si opérationnel
- **Comité tech** = C ou A (approbation changements importants)
- **AVA6 Infra** = R majoritaire (opérateur)
- **REDSOC** = R pour détection / C pour security reviews
- **CEO** = A pour budgets/contrats stratégiques

