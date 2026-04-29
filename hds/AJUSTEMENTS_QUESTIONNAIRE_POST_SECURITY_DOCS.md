# ANALYSE DE COHÉRENCE — security_wg.md + security_dc.md vs Questions Q41-Q61

**Date:** 17 avril 2026  
**Status:** Analyse post-ajout documentation WatchGuard & Datacenter  
**Auteur:** Audit HDS OneOrtho

---

## ✅ COHÉRENCE CONFIRMÉE (3 clarifications seulement)

| Question | Sujet | Couverture | Statut |
|---|---|---|---|
| **Q46** | VLAN isolement par client | security_dc ✓ | Confirmé. Ajouter test dépistage isolement |
| **Q52** | Logs SIEM rétention | security_wg ✓ (365j) | Confirmé. Clarifier SLA extraction forensics |
| **Q43** | Personnel baie + external | security_dc ✓ | Confirmé. Détailler formation HDS requis |

---

## 🔴 LACUNES CRITIQUES — Réponses ABSENTES (9 points)

### 1️⃣ **Chiffrement Data au Repos [Q48]**
- **Situation:** security_wg documente Full Encryption **endpoints** (BitLocker/FileVault)  
- **Manque:** Storage encryption chez AVA6 (VM disks, SAN) = SILENCE TOTAL  
- **Impact:** Données patients sur disques AVA6 = lisibles sans chiffrement storage ?  
- **Action prioritaire:** Demander: Chiffrement BitLocker hypervisor ? ou chiffrement SAN ?

---

### 2️⃣ **Tests Pénétration Annuels [Q44]**
- **Situation:** security_wg cite certifications MITRE/NetSecOPEN MAIS ne mentionne PAS pentest AVA6  
- **Manque:** Pentest ANNUEL OneOrtho scope + résultats + SLA remediation  
- **Impact HDS:** Art. 9 = pentest requis annuel minimum = **OBLIGATION LÉGALE NON DOCUMENTÉE**  
- **Action prioritaire:** Demander plan/résultats 2024-2025 pentest

---

### 3️⃣ **SLA Notification Incident Sécurité [Q50]**
- **Situation:** security_wg : "RedSoc < 15 min response" = pour remediation LOCAL  
- **Manque:** SLA notation à OneOrtho quand incident découvert ≠ SLA remediation  
- **Impact RGPD:** CNIL notification = 72h max, nécessite découverte immédiate  
- **Action prioritaire:** Écrire contrat: AVA6 notifie OneOrtho < 4h découverte incident

---

### 4️⃣ **Procédure Destruction Données [Q54]**
- **Situation:** security_dc mentionne backup 14j online + offline 3-month  
- **Manque:** Aucune procédure technique destruction finale (wiping, certificat, signature)  
- **Impact HDS:** Art. 5 = certificat destruction obligatoire (date, volume, method, signature)  
- **Action prioritaire:** Exiger document "destruction policy" signé

---

### 5️⃣ **Chiffrement Transit (RDP) [Q49]**
- **Situation:** security_dc cite "RDP expose IP publique 195.42.148.160"  
- **Manque:** Encryption mandate RDP ou VPN obligatoire ? TLS layer ?  
- **Impact:** RDP sans VPN = trafic potentially unencrypted si client pas TLS  
- **Action prioritaire:** Mandater VPN ou TLS layer obligatoire pour RDP

---

### 6️⃣ **Scan Vulnérabilité Continu [Q45]**
- **Situation:** security_dc : "ANSSI network scans" performed par ANSSI  
- **Manque:** Scan interne AVA6 (Qualys/Nessus) ? Fréquence ? Alertes OneOrtho si CVE ?  
- **Impact HDS:** Art. 9.1 = scan mensuels minimum requis  
- **Action prioritaire:** Confirmer tool + fréquence + alert SOP

---

### 7️⃣ **Audit Rights OneOrtho [Q56]** + **SOC 2 Access [Q57]**
- **Situation:** security_dc/wg = silence total audit rights  
- **Manque:** OneOrtho droit audit site ? Accès SOC 2 Type II report ? HDS audit report ?  
- **Impact HDS:** Art. 6.3 = audit rights obligatoires  
- **Action prioritaire:** Ajouter contrat: audit on-site possible + SOC 2 access

---

### 8️⃣ **Sous-traitants Agrément [Q58-Q59]**
- **Situation:** security_wg identifie REDSOC (SOC) + WatchGuard (EPDR)  
- **Manque:** Aucun agrément signé OneOrtho pour ces sub-processors  
- **Impact RGPD:** Art. 28.4 = tous sous-traitants doivent être pré-approuvés  
- **Action prioritaire:** Signature OneOrtho: approval REDSOC + WatchGuard access

---

### 9️⃣ **Réquisition Judiciaire/CNIL [Q60-Q61]**
- **Situation:** security_wg/dc = SILENCE COMPLET  
- **Manque:** Procédure si police/CNIL demande données OneOrtho ?  
- **Impact HDS:** CSP L.1110-4 = notification OneOrtho obligatoire  
- **Action prioritaire:** Ajouter contrat: procédure réquisition avec notification

---

## 🟠 CLARIFICATIONS NÉCESSAIRES (5 points)

| Sujet | Situation | Action |
|---|---|---|
| **CPU/RAM Guarantee** [Q47] | Silence sur CPU pinning vs sharing | Demander: reserved vs best-effort ? |
| **Isolation VM** [Q53] | RedSoc peut isoler auto/manual ? | Clarifier: auto-isolation post-detection ? |
| **Reversibilité SLA** [Q55] | "1 month après fin" vague | Préciser: full export < 7 days ? Format standard ? |
| **Destruction Offline Backup** | Copy chez OneOrtho + AVA6 | Clarifier: OneOrtho destruction ? AVA6 destruction quand ? |
| **Internal vs External Audit** | Rapports tiers (SOC 2, HDS) | OneOrtho reçoit complet ou redacted NDA ? |

---

## 📊 VERDICT DE COHÉRENCE

| Catégorie | % Cohérent | Statut |
|---|---|---|
| **Infra Datacenter** | 85% ✓ | security_dc complète, détail bon |
| **Sécurité Opérationnelle** | 60% ⚠️ | security_wg couvre monitoring mais SLA manque |
| **Conformité HDS/Légale** | 35% 🔴 | Très peu d'éléments contractualisés/documentés |
| **GLOBAL** | **60%** | **Lacunes critiques doivent êtrecomblées** |

---

## 📋 ACTIONS IMMÉDIATES (Priorité)

### 🔴 **SEMAINE 1 — CRITIQUE**
1. Q48 : Confirmation chiffrement storage layer (BitLocker hypervisor OU SAN encryption ?)
2. Q44 : Résultats pentest 2024-2025 (dates, scope, vulnérabilités, remediation SLA)
3. Q50 : Écrire SLA notification incident (< 4h découverte)
4. Q54 : Obtenir destruction policy document signé

### 🟠 **SEMAINE 2 — HAUTE PRIORITÉ**
5. Q58-Q59 : Signature OneOrtho approval REDSOC + WatchGuard sub-processors
6. Q56-Q57 : Audit rights clause + SOC 2 access formalisé
7. Q49 : Mandater VPN + TLS pour RDP
8. Q60-Q61 : Procédure réquisition judiciaire/CNIL

### 🟡 **SEMAINE 3 — MOYEN TERME**
9. Q45 : Confirmer scan vulnérabilité + alert process
10. Q47 : Détailler CPU/RAM reservation hypervisor
11. Q55 : Reversibilité SLA + format standard
12. Q46 : Ajouter test isolement VLAN (trimestriel)

---

## 💼 CONCLUSION

**Résumé:** security_wg.md + security_dc.md fournissent une **base solide d'infra** mais **manquent grièvement sur légal**, **SLA**, **et procédures HDS**. La cohérence est de **~60%** — **acceptable pour infra technique, inacceptable pour conformité**.

**Recommandation:** Ne pas accepter renouvellement contrat AVA6 sans résoudre les 9 lacunes critiques. Placer deadline 30 jours clarification.

