# Matrice RACI — 04 — Couche Sécurité SIEM | WAF | EPDR | Proxy — Datacenter AVA6
## Infrastructure Externalisée Hébergement OneOrtho

**Date :** 27 avril 2026  
**Classification :** CONFIDENTIEL — Infrastructure AVA6  
**Périmètre :** SIEM, WAF, EPDR serveurs applicatifs, Reverse Proxy, Réponse Incidents (datacenter SYNAAPS)

---

## 🔑 **CLARIFICATION RÔLES RACI — Infrastructure Externalisée**

### Distinction acteurs — Infrastructure Datacenter AVA6

| Acteur | Responsabilité | Rôle Type RACI |
|---|---|---|
| **IT Manager OneOrtho** | Responsable numérique OneOrtho (supervise infra externalisée) | **R/A** si contrats ; **C** si opérationnel) |
| **Comité technique OneOrtho** | Ensemble tech leads + IT Manager (approbation stratégique) | **C/A** (Consulté + approuve décisions infra) |
| **CEO OneOrtho** | Direction exécutive (approbation budgets/changements) | **A** (Approuve budgets stratégiques) |
| **AVA6 Infra/MCO (Managed Care Operations)** | Prestataire infrastructure + maintenance datacenter | **R** (Réalise + exécute opérations) |
| **AVA6 SOC (REDSOC)** | Prestataire sécurité monitoring centralisé 24/7 | **R** (Détection + investigation incidents) |

### Application Couche Sécurité Datacenter

> **IMPORTANT — Responsabilité partagée HDS :**
> - **AVA6** = **R** (Opérateur, exécuteur, tenu responsable contrat SLA)
> - **OneOrtho** = **R/A** (Responsable traitement légal, signature contrat, escalade CNIL)
> - **REDSOC** = **R** (Détecteur incidents, SOC 24/7, réponse technique)
> - **Comité tech** = **C/A** (Validation changements infra, escalade stratégique)
> - **CEO** = **A** (Approbation budgets/contrats multi-année)

> **HDS Article 28 (Sous-traitant) :**  
> - AVA6 = sous-traitant HDS (exécute selon contrat)
> - OneOrtho = responsable traitement (approuve, notifie CNIL, responsable légal)
> - REDSOC = prestataire détection (relève de AVA6 contractuellement)

---

## 🔴 **SECTION 1 : SIEM — CENTRALIZED LOGGING & DETECTION**

### Justification HDS
- **HDS art. 6** = Traçabilité obligatoire (tous événements sécurité)
- **HDS art. 9** = Détection anomalies avec SIEM obligatoire
- **HDS art. 10** = Alertes incidents (temps réel)
- **RGPD art. 32** = Enregistrement audit security events

### Domaine 1A — Architecture & Configuration

| Domaine / Groupe | Processus / Activité | IT Manager | Comité technique | AVA6 Infra/MCO | REDSOC |
|---|---|---|---|---|---|
| **1A. Architecture** | **[CRITIQUE HDS] Architecture SIEM (WatchGuard ThreatSync)** | **C** | **A** | **R** | **C** |
| **1A. Architecture** | **Déploiement instances SIEM (redundancy, failover)** | **C** | **C** | **R** | **C** |
| **1A. Architecture** | **[CRITIQUE HDS] Définition politique rétention logs (≥ 1 an)** | **A** | **C** | **R** | **C** |
| **1A. Architecture** | **Dimensionnement stockage SIEM (taille base données)** | **C** | **C** | **R** | **C** |

### Domaine 1B — Sources de Données

| Domaine / Groupe | Processus / Activité | IT Manager | Comité technique | AVA6 Infra/MCO | REDSOC |
|---|---|---|---|---|---|
| **1B. Sources** | **[CRITIQUE HDS] Configuration sources logs (VMs OneOrtho)** | **I** | **C** | **R** | **R** |
| **1B. Sources** | **[CRITIQUE HDS] Configuration logs réseau (firewall, VPN, WiFi)** | **I** | **C** | **R** | **R** |
| **1B. Sources** | **Configuration logs applicatifs (OneSoftware ERP incidents)** | **C** | **C** | **R** | **R** |
| **1B. Sources** | **Intégration logs AD (authentification, changements groups)** | **C** | **C** | **R** | **R** |
| **1B. Sources** | **Intégration WAF logs (tentatives intrusion, blocages)** | **I** | **C** | **R** | **R** |
| **1B. Sources** | **Intégration EPDR logs (détections endpoints/serveurs)** | **I** | **C** | **R** | **R** |

### Domaine 1C — Règles Corrélation & Alertes

| Domaine / Groupe | Processus / Activité | IT Manager | Comité technique | AVA6 Infra/MCO | REDSOC |
|---|---|---|---|---|---|
| **1C. Règles** | **[CRITIQUE HDS] Définition règles corrélation (anomalies sécurité)** | **C** | **A** | **I** | **R** |
| **1C. Règles** | **[CRITIQUE HDS] Règles détection accès données patients (traçabilité)** | **C** | **A** | **I** | **R** |
| **1C. Règles** | **[CRITIQUE HDS] Configuration alertes P1/P2 + escalade auto** | **A** | **A** | **I** | **R** |
| **1C. Règles** | **Tuning règles (réduction faux positifs mensuels)** | **I** | **I** | **I** | **R** |
| **1C. Règles** | **Mise à jour règles corrélation (mensuellement)** | **I** | **I** | **I** | **R** |

### Domaine 1D — Monitoring & Rapports

| Domaine / Groupe | Processus / Activité | IT Manager | Comité technique | AVA6 Infra/MCO | REDSOC |
|---|---|---|---|---|---|
| **1D. Monitoring** | **[CRITIQUE HDS] Analyse quotidienne alertes SIEM** | **I** | **I** | **I** | **R** |
| **1D. Monitoring** | **[CRITIQUE HDS] Escalade incidents P1 (SLA < 15 min)** | **A** | **A** | **I** | **R** |
| **1D. Monitoring** | **Monitoring uptime SIEM (alertes disponibilité)** | **I** | **C** | **R** | **R** |
| **1D. Monitoring** | **[CRITIQUE HDS] Rapport mensuel SIEM (KPIs, incidents, trends)** | **A** | **I** | **I** | **R** |
| **1D. Monitoring** | **Revue annuelle couverture SIEM (gaps analysis)** | **A** | **A** | **C** | **R** |

### Domaine 1E — Conservation & Audit

| Domaine / Groupe | Processus / Activité | IT Manager | Comité technique | AVA6 Infra/MCO | REDSOC |
|---|---|---|---|---|---|
| **1E. Rétention** | **[CRITIQUE HDS] Archivage logs (≥ 1 an dans SIEM)** | **A** | **I** | **R** | **I** |
| **1E. Rétention** | **Backup/Restore SIEM configs + bases données** | **I** | **I** | **R** | **I** |
| **1E. Rétention** | **[CRITIQUE HDS] Audit trail SIEM itself (who modified rules)** | **A** | **C** | **R** | **I** |
| **1E. Rétention** | **Conformité taille base SIEM (alertes disque 80%)** | **I** | **C** | **R** | **I** |

---

## 🔴 **SECTION 2 : WAF — WEB APPLICATION FIREWALL**

### Justification HDS
- **HDS recommandé** = Protection applicative OneOrtho (données patients)
- **OWASP Top 10** = Standard industrie attaques Web
- **Détection/Prévention** = Blocking automatique intrusions

### Domaine 2A — Déploiement & Configuration

| Domaine / Groupe | Processus / Activité | IT Manager | Comité technique | AVA6 Infra/MCO | REDSOC |
|---|---|---|---|---|---|
| **2A. Déploiement** | **[RECOMMANDÉ] Déploiement WAF (architecture reverse proxy)** | **C** | **A** | **R** | **C** |
| **2A. Déploiement** | **Configuration WAF mode (detection vs blocking)** | **I** | **A** | **R** | **C** |
| **2A. Déploiement** | **Intégration WAF logs → SIEM** | **I** | **C** | **R** | **R** |

### Domaine 2B — Règles & Maintenancellas

| Domaine / Groupe | Processus / Activité | IT Manager | Comité technique | AVA6 Infra/MCO | REDSOC |
|---|---|---|---|---|---|
| **2B. Règles** | **[RECOMMANDÉ] Configuration règles WAF (OWASP Top 10)** | **I** | **A** | **R** | **C** |
| **2B. Règles** | **Mise à jour signatures WAF (monthly + hotfix)** | **I** | **I** | **R** | **C** |
| **2B. Règles** | **Tests WAF (faux négatifs pentest mensuels)** | **R** | **A** | **C** | **C** |
| **2B. Règles** | **Gestion exceptions/whitelist (faux positifs)** | **I** | **A** | **R** | **C** |

### Domaine 2C — Monitoring & Alertes

| Domaine / Groupe | Processus / Activité | IT Manager | Comité technique | AVA6 Infra/MCO | REDSOC |
|---|---|---|---|---|---|
| **2C. Monitoring** | **[RECOMMANDÉ] Surveillance alertes WAF temps réel** | **I** | **I** | **I** | **R** |
| **2C. Monitoring** | **Gestion faux positifs (whitelisting applicatif)** | **I** | **C** | **R** | **C** |
| **2C. Monitoring** | **Rapport mensuel WAF (blocages, patterns attaque, trends)** | **A** | **I** | **R** | **I** |

---

## 🔴 **SECTION 3 : EPDR — ENDPOINT DETECTION & RESPONSE (Serveurs Applicatifs)**

### Distinction vs Endpoints
> **EPDR Endpoints** = Matrice #03 (postes OneOrtho on-site)  
> **EPDR Serveurs** = Cette section (VMs OneOrtho chez AVA6 + serveurs AVA6)

### Justification HDS
- **HDS art. 9** = Détection anomalies obligatoire sur serveurs  
- **Isolation VM compromise** = Containment rapide

### Domaine 3A — Déploiement & Administration

| Domaine / Groupe | Processus / Activité | IT Manager | Comité technique | AVA6 Infra/MCO | REDSOC |
|---|---|---|---|---|---|
| **3A. Déploiement** | **[CRITIQUE HDS] Déploiement agents EPDR sur VM OneOrtho** | **C** | **C** | **R** | **C** |
| **3A. Déploiement** | **Déploiement agents EPDR serveurs infra AVA6** | **I** | **I** | **R** | **I** |
| **3A. Admin** | **Administration console EPDR (WatchGuard Cloud/on-prem)** | **I** | **I** | **R** | **R** |
| **3A. Admin** | **Gestion accès console EPDR (authentification, ACLs)** | **I** | **C** | **R** | **I** |

### Domaine 3B — Détection & Réponse

| Domaine / Groupe | Processus / Activité | IT Manager | Comité technique | AVA6 Infra/MCO | REDSOC |
|---|---|---|---|---|---|
| **3B. Détection** | **[CRITIQUE HDS] Analyse alertes EPDR serveurs quotidien** | **I** | **I** | **I** | **R** |
| **3B. Détection** | **[CRITIQUE HDS] Isolation d'urgence VM compromis (off-network)** | **A** | **C** | **R** | **R** |
| **3B. Détection** | **Mise à jour signatures + moteur EPDR (mensuellement)** | **I** | **I** | **R** | **R** |
| **3B. Response** | **[CRITIQUE HDS] Rapport mensuel EPDR serveurs (KPIs, remédiation)** | **A** | **I** | **I** | **R** |

### Domaine 3C — Hardening & Contrats

| Domaine / Groupe | Processus / Activité | IT Manager | Comité technique | AVA6 Infra/MCO | REDSOC |
|---|---|---|---|---|---|
| **3C. Hardening** | **[CRITIQUE HDS] Hardening OS CIS Benchmarks (Linux/Windows)** | **C** | **A** | **R** | **I** |
| **3C. Hardening** | **Audit hardening mensuels (compliance CIS)** | **I** | **C** | **R** | **I** |
| **3C. Contrats** | **[CRITIQUE HDS] Renouvellement annuel contrat EPDR + REDSOC** | **R/A** | **C** | **I** | **I** |

---

## 🔴 **SECTION 4 : REVERSE PROXY — ACCÈS EXTERN ONÉSOFTWARE**

### Justification Architecture
- **Reverse Proxy** = Frontal sécurité OneOrtho (HTTPS, headers, rate-limiting)
- **SSL/TLS obligatoire** = HDS art. 4 (données en transit)
- **Headers sécurité** = Protection XSS, clickjacking, MIME-sniffing

### Domaine 4A — Déploiement & Configuration

| Domaine / Groupe | Processus / Activité | IT Manager | Comité technique | AVA6 Infra/MCO | REDSOC |
|---|---|---|---|---|---|
| **4A. Déploiement** | **Déploiement Reverse Proxy frontal** | **C** | **A** | **R** | **C** |
| **4A. Config** | **Configuration routage OneOrtho VMs** | **I** | **C** | **R** | **I** |
| **4A. Config** | **Configuration ACLs Proxy (IP whitelist/blacklist)** | **I** | **A** | **R** | **I** |
| **4A. Config** | **Rate limiting (DDoS mitigation)** | **I** | **C** | **R** | **I** |

### Domaine 4B — Certificats SSL/TLS **[CRITIQUE HDS]**

| Domaine / Groupe | Processus / Activité | IT Manager | Comité technique | AVA6 Infra/MCO | REDSOC |
|---|---|---|---|---|---|
| **4B. Certificats** | **[CRITIQUE HDS] Gestion certificats SSL/TLS (acquisition, storage)** | **A** | **C** | **R** | **I** |
| **4B. Certificats** | **[CRITIQUE HDS] Renouvellement automatique certificats (< 30j avant expiration)** | **I** | **I** | **R** | **I** |
| **4B. Certificats** | **[CRITIQUE HDS] Audit trail clés privées (access logs)** | **A** | **C** | **R** | **I** |
| **4B. Certificats** | **Rotation certificats (annuellement minimum)** | **I** | **C** | **R** | **I** |

### Domaine 4C — Headers Sécurité

| Domaine / Groupe | Processus / Activité | IT Manager | Comité technique | AVA6 Infra/MCO | REDSOC |
|---|---|---|---|---|---|
| **4C. Headers** | **Configuration headers de sécurité HTTP (HSTS, CSP, X-Frame-Options)** | **I** | **C** | **R** | **I** |
| **4C. Headers** | **Configuration remove sensitive headers (Server, X-Powered-By)** | **I** | **C** | **R** | **I** |
| **4C. Headers** | **Audit headers sécurité (pentest mensuels)** | **I** | **A** | **C** | **C** |

### Domaine 4D — Maintenance & Monitoring

| Domaine / Groupe | Processus / Activité | IT Manager | Comité technique | AVA6 Infra/MCO | REDSOC |
|---|---|---|---|---|---|
| **4D. MCO** | **Maintenance Reverse Proxy (mises à jour sécurité)** | **I** | **I** | **R** | **I** |
| **4D. MCO** | **Monitoring uptime Proxy (alertes disponibilité)** | **I** | **C** | **R** | **I** |
| **4D. Audit** | **[CRITIQUE HDS] Audit logs Proxy (qui a accédé quand)** | **A** | **C** | **R** | **I** |
| **4D. Audit** | **Rapport accès Proxy (quotidien, anomalies)** | **I** | **I** | **I** | **R** |

---

## 🔴 **SECTION 5 : RÉPONSE AUX INCIDENTS SÉCURITÉ**

### Justification HDS
- **HDS art. 10** = Notification CNIL < 24h si données compromises
- **RGPD art. 33** = OneOrtho responsable légal notification
- **Containment rapide** = Réduire exposition données

### Domaine 5A — Détection & Qualification

| Domaine / Groupe | Processus / Activité | IT Manager | Comité technique | AVA6 Infra/MCO | REDSOC |
|---|---|---|---|---|---|
| **5A. Détection** | **[CRITIQUE HDS] Détection incident sécurité (SIEM/EPDR/WAF)** | **I** | **I** | **C** | **R** |
| **5A. Qualification** | **[CRITIQUE HDS] Qualification incident (P1/P2/P3, scope données)** | **A** | **A** | **I** | **R** |
| **5A. Qualification** | **Classification données compromises (patients, admin, autre)** | **A** | **A** | **I** | **R** |

### Domaine 5B — Escalade & Notification

| Domaine / Groupe | Processus / Activité | IT Manager | Comité technique | AVA6 Infra/MCO | REDSOC |
|---|---|---|---|---|---|
| **5B. Escalade** | **[CRITIQUE HDS] Escalade P1 incident confirmé à OneOrtho (SLA < 30min)** | **R** | **A** | **I** | **R** |
| **5B. Escalade** | **Escalade interne AVA6 (incident lead + CTO AVA6)** | **I** | **I** | **R** | **R** |
| **5B. CNIL** | **[CRITIQUE HDS] Évaluation risque données patients (nécessite notif CNIL?)** | **R/A** | **A** | **C** | **C** |
| **5B. CNIL** | **[CRITIQUE HDS] Notification CNIL (si compromission confirmée, < 24h)** | **R/A** | **C** | **I** | **I** |

### Domaine 5C — Containment & Investigation

| Domaine / Groupe | Processus / Activité | IT Manager | Comité technique | AVA6 Infra/MCO | REDSOC |
|---|---|---|---|---|---|
| **5C. Containment** | **[CRITIQUE HDS] Isolation VM compromise (off-network immédiat)** | **A** | **A** | **R** | **R** |
| **5C. Containment** | **Isolation réseau (VLAN tampon quarantine)** | **A** | **C** | **R** | **R** |
| **5C. Forensics** | **[CRITIQUE HDS] Investigation forensique (snapshot VM, memory dump)** | **I** | **I** | **R** | **R** |
| **5C. Forensics** | **Analyse logs SIEM attack chain reconstruire** | **I** | **I** | **I** | **R** |
| **5C. Forensics** | **Audit AD/authentification (compromis comptes?)** | **I** | **C** | **R** | **R** |

### Domaine 5D — Remediation & Documentation

| Domaine / Groupe | Processus / Activité | IT Manager | Comité technique | AVA6 Infra/MCO | REDSOC |
|---|---|---|---|---|---|
| **5D. Remediation** | **Plan remediation (patch vuln, access reset, MFA reset)** | **A** | **A** | **R** | **C** |
| **5D. Remediation** | **[CRITIQUE HDS] Retour production sécurisé (vérifications)** | **A** | **A** | **R** | **C** |
| **5D. RCA** | **[CRITIQUE HDS] Root Cause Analysis (pourquoi compromis)** | **A** | **A** | **R** | **R** |
| **5D. Prévention** | **Plan prévention (règles SIEM, patch, configs)** | **A** | **A** | **C** | **I** |
| **5D. PIR** | **[CRITIQUE HDS] Rapport post-incident (timeline, causes, leçons)** | **A** | **C** | **R** | **R** |

### Domaine 5E — Communication & Lessons Learned

| Domaine / Groupe | Processus / Activité | IT Manager | Comité technique | AVA6 Infra/MCO | REDSOC |
|---|---|---|---|---|---|
| **5E. Communication** | **Communication CEO OneOrtho (briefing incident)** | **R/A** | **A** | **I** | **I** |
| **5E. Communication** | **Documentation incident (confidential shareholders)** | **A** | **A** | **C** | **I** |
| **5E. Lessons** | **Lessons learned meeting (30j post-incident)** | **A** | **A** | **R** | **R** |

---

## 📊 **RÉSUMÉ ACTIVITÉS PAR CRITICITÉ HDS**

### **🔴 CRITIQUE HDS (35 activités)** = Obligations légales directes
✅ Architecture SIEM + déploiement → HDS art. 6  
✅ Rétention logs ≥ 1 an → HDS art. 6  
✅ Sources logs (VMs, réseau, AD, WAF, EPDR) → HDS art. 6  
✅ Règles corrélation + alertes → HDS art. 9  
✅ Règles détection accès patients → HDS art. 6  
✅ Alertes P1/P2 + escalade auto → HDS art. 10  
✅ Analyse quotidienne alertes SIEM → HDS art. 9  
✅ Escalade P1 < 15 min → HDS art. 10  
✅ Rapport mensuel SIEM → conformité CNIL  
✅ Revue annuelle couverture SIEM → conformité  
✅ Audit trail SIEM (who modified) → HDS art. 6  
✅ Déploiement agents EPDR serveurs → HDS art. 9  
✅ Isolation VM compromise → HDS art. 9  
✅ Analyse alertes EPDR → HDS art. 9  
✅ Hardening CIS Benchmarks → HDS art. 9  
✅ Contrat EPDR + REDSOC → HDS service provider  
✅ Gestion certificats SSL/TLS → HDS art. 4  
✅ Renouvellement certs < 30j → HDS art. 4  
✅ Audit clés privées (access logs) → HDS art. 6  
✅ Audit logs Proxy → HDS art. 6  
✅ Détection incidents (SIEM/EPDR/WAF) → HDS art. 9  
✅ Qualification incidents P1/P2 → HDS art. 10  
✅ Escalade P1 < 30min → HDS art. 10  
✅ Évaluation risque données patients → RGPD risks  
✅ Notification CNIL < 24h → RGPD art. 33  
✅ Isolation VM compromise → HDS art. 9  
✅ Investigation forensique → HDS art. 10  
✅ Audit AD (compromis comptes?) → HDS art. 6  
✅ RCA (root cause analysis) → RGPD compliance  
✅ Rapport post-incident → HDS documentation  
✅ Règles WAF OWASP Top 10 → protection applicative  
✅ Mise à jour signatures WAF → mensuellement  

### **🟡 RECOMMANDÉ (15 activités)** = Bonne pratique sécurité
⚠️ Tests WAF faux négatifs  
⚠️ Gestion exceptions/whitelist WAF  
⚠️ Tuning règles SIEM faux positifs  
⚠️ Monitoring uptime SIEM  
⚠️ Déploiement WAF  
⚠️ Configuration WAF mode  
⚠️ Surveillance alertes WAF  
⚠️ Audit hardening CIS  
⚠️ Monitoring uptime Proxy  
⚠️ Rapport accès Proxy  
⚠️ Plan remediation generic  
⚠️ Et autres monitoring/ops

---

## 📝 **REMARQUES ARCHITECTURALES**

### **SIEM Centralisé (WatchGuard ThreatSync)**
- Collecte toutes sources (VMs, réseau, AD, endpoints, applicatifs)
- Datacenter AVA6 (SYNAAPS Lyon)
- Corrélation règles temps réel
- Conservation logs ≥ 1 an (HDS requirement)
- Alertes P1/P2 escalade automatique REDSOC

### **WAF (Web Application Firewall)**
- Frontal OneSoftware applicatifs (reverse proxy)
- OWASP Top 10 rules + custom OneOrtho
- Logging intégré SIEM
- Mode blocking (après tunning)
- Certificats SSL/TLS gérés AVA6

### **EPDR Serveurs vs Endpoints**
- **EPDR Serveurs** = VMs OneOrtho + infra AVA6 (cette matrice #04)
- **EPDR Endpoints** = Postes OneOrtho on-site (matrice #03)
- Deux consoles WatchGuard synchronisées
- REDSOC gère alertes les deux

### **Reverse Proxy**
- Point d'entrée unique OneOrtho
- Headers sécurité (HSTS, CSP, X-Frame)
- Rate limiting DDoS
- Audit logs traçabilité accès
- Certificats SSL/TLS auto-renewel

### **Réponse Incidents**
- **OneOrtho** = Responsable légal (notification CNIL, RCA)
- **AVA6/REDSOC** = Opérateurs techniques (isolation, forensics)
- SLA P1 < 30min escalade OneOrtho
- SLA CNIL notification < 24h si compromission

---

## 🔄 **RÉFÉRENCES CROISÉES MATRICES**

| Matrice | Interaction | Description |
|---|---|---|
| #01 OneSoftware | SIEM reçoit logs applicatifs | Traçabilité accès patients OneOrtho |
| #02 AD/Filer/NAS | SIEM collecte logs AD + Filer | Audit authentification + accès fichiers |
| #03 Endpoints | EPDR endpoints + logs au SIEM | Détection intrusions postes |
| **#04 Couche Sécurité** | **← VOUS ÊTES ICI** | Infrastructure AVA6 cœur sécurité |
| #05 AVA6 Infrastructure | Firewall/Router logs au SIEM | Monitoring réseau AVA6 |

