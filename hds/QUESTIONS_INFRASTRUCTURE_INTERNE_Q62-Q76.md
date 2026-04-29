# QUESTIONS COMPLÉMENTAIRES — INFRASTRUCTURE INTERNE & RÉSEAU SITE
## Architecture réseau OneOrtho, routeur local, VPN & responsabilités

**OneOrtho × AVA6 — Gestion infra interne (site OneOrtho)**  
**Date : 17 avril 2026**  
**Classification : CONFIDENTIEL**

---

## 📋 Contexte

Le contrat AVA6 ne documente **PAS** l'architecture réseau du site OneOrtho (routeur, switch local, connexion internet). Or, cette infrastructure est **critique** car elle :
- **Connecte** les 15 PC/postes OneOrtho au serveur OneOrtho local
- **Transporte** les données de santé via le tunnel VPN vers datacenter AVA6
- **Sécurise** l'accès internet du site (firewall local ?)
- **Isolate** le réseau OneSite des menaces externes

**Enjeu HDS :** Données patients en transit dépendent aussi de la sécurité du routeur OneOrtho, pas seulement AVA6.

---

## ⚠️ BLOC 1 : Architecture Réseau Site OneOrtho (Responsabilité Partagée)

### Q62 — CRITIQUE
**Schéma architecture réseau OneOrtho & responsabilité ownership**

> Existe-t-il une documentation d'architecture complète du site OneOrtho ?
> - Schéma topologie physique/logique (routeur, switch, PC, connexion internet) ?
> - Qui **possède** le routeur local OneOrtho ? (OneOrtho ? AVA6 ? Colocalisé datacenter ?)
> - Qui **gère** le routeur ? (OneOrtho IT ? AVA6 MCO ? Tier local ?)
> - Qui **sécurise** le routeur ? (Firewall ? IDS/IPS ? Qui maintient rules ?)

**Pourquoi c'est Important :**
Sans architecture documentée → responsabilité de sécurité reste floue → gap conformité HDS/RGPD.

**Référence légale :**
- **HDS Cahier des charges art. 6 & 9** : Hébergeur responsable de sécurité infra, MAIS responsabilité partagée si infra client
- **ANSSI Guide 2023** : "Architecture réseau doit être documentée + responsabilités clair"
- **ISO 27001:2022 A.13** : Network topology & responsibility matrix obligatoire

**Gap actuel :**
- Contrat section 2.3.1 : Mentionne "TARGET TOPOLOGY" = Segmentation VLAN S1-S6 MAIS...
- S1-S6 = VLANs **CHEZ AVA6** (datacenter)
- **AUCUNE** documentation reseau **ON-SITE** OneOrtho

**Action :** Demander à AVA6 :
1. Diagram COMPLET architecture OneOrtho site (connexion internet → routeur → switch → PC 1-15 + serveur local)
2. Document responsabilité : qui gère quoi (owner, operator, security)
3. Conformité: Comment infra interne aligne avec politique HDS ?

---

### Q63 — IMPORTANT
**Connexion Internet OneOrtho — Type, Fournisseur, Sécurité**

> Quel est type de connexion internet du site OneOrtho ?
> - Type : ADSL ? Fibre ? 4G ? Liaison louée (Colt, Orange) ?
> - Fournisseur : Qui ? Contrat OneOrtho directe ou via AVA6 ?
> - Bande passante : Débit nominal ? Garantie SLA ?
> - Firewall/Sécurité : Routeur OneOrtho a firewall intégré ? Qui l'administre ?
> - Backup connexion : Connexion internet redundante + failover automatique ?

**Pourquoi c'est Important :**
Données patients transitent par cette connexion internet → rupture internet = production down + patients inaccessibles.

**Référence légale :**
- **HDS Cahier des charges art. 8** : "Disponibilité infra garantie, y compris connectivité"
- **ANSSI Guide 2023** : Connexion internet doit être "haut débit + chiffré"

**Gap actuel :**
- Contrat mentionne "10 x VPN pour employés" MAIS pas la connexion primaire OneOrtho
- Pas de SLA disponibilité internet

**Action :** Obtenir :
1. Contrat internet OneOrtho (fournisseur, débit, SLA)
2. Diagram flux données : PC → serveur OneOrtho local vs PC → VPN → serveur AVA6
3. Procédure if internet down (failover ? Hotspot 4G ?)

---

### Q64 — IMPORTANT
**Routeur OneOrtho — Spécifications, Maintenance, Mises à Jour**

> Quel est le routeur déployé chez OneOrtho ?
> - Modèle/Marque : Cisco ? Juniper ? Fortinet ? Asus ? Autre ?
> - Version firmware actuelle : Qui maintient les updates ? Fréquence ?
> - Configuration firewall : Enabled/disabled ? Règles customisées ? Logs firewall ?
> - Support technique : Quel SLA support ? Repair time si routeur broken ?
> - Monitoring : AVA6 ou OneOrtho monitor la santé du routeur ? Alertes comment ?

**Référence légale :**
- **HDS Cahier des charges art. 9** : "Equipements réseau doivent être à jour sécurité"
- **ANSSI RGS v2.1** : "Firmware routers doit corresp versioning policy"
- **ISO 27001:2022 A.12.6** : Patch management obligatoire

**Gap actuel :**
- Contrat ne mentionne PAS le routeur
- SLA maintenance = inconnu
- Mises à jour = responsabilité = inconnue

**Action :** Demander :
1. Confirmation modèle routeur + version firmware actuelle
2. Plan maintenance + fréquence updates
3. Qui trigger les updates (automated ou manual) ?
4. Rollback plan si update cassé ?

---

### Q65 — IMPORTANT
**Switch Réseau Local OneOrtho — Configuration, Gestion, VLANs**

> Quel switch réseau local OneOrtho ?
> - Managé ou non-managé ?
> - Support VLAN ? Combien ports ?
> - Qui configure les VLANs locaux ? (OneOrtho, AVA6, tier local ?)
> - Isolation données patient vs réseau administratif (séparation physique/logique) ?
> - Monitoring switch : logs, alertes, utilisation ?

**Pourquoi ça compte :**
VLAN mal configurés = données patients visible sur même réseau que WiFi guest = risque sécurité.

**Référence légale :**
- **HDS Cahier des charges art. 3** : "Isolation données de santé de autres flux réseau"
- **ISO 27001:2022 A.13.1.3** : Network segregation

**Gap actuel :**
- Contrat S3.1 parle de VLAN S1-S6 chez **AVA6** seulement
- **Aucune mention** switch local OneOrtho

**Action :**
1. Schéma VLAN local OneOrtho (production vs admin vs guest WiFi ?)
2. Confirmation isolement données patient au niveau switch local
3. Logs switch disponibles pour audit ?

---

## ⚠️ BLOC 2 : VPN Site-to-Site & Connexion Datacenter (Circuit Critique)

### Q66 — CRITIQUE
**Tunnel VPN Site-to-Site OneOrtho ↔ AVA6 — Configuration, Chiffrement, Resilience**

> Quel est détail du tunnel IPSec VPN OneOrtho → AVA6 DC ?
> - Endpoint OneOrtho : IP publique OneOrtho ? (stable/fixe ou dynamique ?)
> - Endpoint AVA6 : IP fixed AVA6 datacenter ?
> - Chiffrement IPSec : IKEv1 ou IKEv2 ? Phase1/Phase2 algorithms (AES-256 ?) ?
> - Key exchange : Pré-shared keys ? Qui manage les clés ? Retention période ?
> - MTU/Path MTU discovery : Configured correctly pour data patients (Jumbo frames ?) ?
> - Firewall rules: Qui permet traffic VPN through? OneOrtho firewalled ou AVA6 firewalled both sides ?

**Référence légale :**
- **HDS Cahier des charges art. 4** : "Chiffrement en transit AES minimum"
- **ANSSI IPSec Guide 2023** : Algorithmes recommandés IKEv2 + AES-256
- **RGPD art. 32** : Encryption in transit for personal data

**Gap actuel :**
- Contrat mentionne "Site-to-site IPSec VPN tunnel" (€190 init + €15/mois)
- **ZÉRO** détail encryption algorithms, key management, monitoring

**Action :** Demander à AVA6 :
1. IPSec configuration document (IKE version, algorithms, lifetime)
2. Key management procedure (who generates, stores, rotates keys ?)
3. Monitoring tunnel stability (uptime %, reconnect events ?)
4. Procedure if VPN key compromised = regen ?

---

### Q67 — IMPORTANT
**Redondance & Failover VPN — Resilience Données Patients**

> En cas de panne VPN OneOrtho → AVA6, que se passe-t-il ?
> - VPN redondant configuré (dual tunnels + automatic failover) ?
> - Scenario A : VPN down → PC OneOrtho lose access serveur applications AVA6 ?
> - Scenario B : VPN down → PC Oneortho can use serveur local OneOrtho (RDS/Citrix ?) ?
> - RTO (Recovery Time Objective) : MAX how long VPN can be down before critiques impact ?
> - Procedure notification si VPN down >10min ? SLA ?

**Pourquoi Important :**
Si VPN down + aucun local fallback = médecins ne peuvent pas accéder dossiers patients = patients non soignés.

**Référence légale :**
- **HDS Cahier des charges art. 8** : "Disponibilité garantie + RTO défini"
- **CSP art. L.1110-5** : Healthcare system must ensure patient safety (ex: access dossier patient obligatoire)

**Gap actuel :**
- Contrat dit "1 site-to-site tunnel" (singular) = NO REDUNDANCY ?
- RTO/RPO = non défini

**Action :**
1. Confirm: Single or dual VPN ? Si single → demander upgrade dual
2. Local application serveur OneOrtho = available offline ou pas ?
3. SLA if VPN down (notification OneOrtho quand ? reparation how fast ?)

---

### Q68 — IMPORTANT
**Data en transit VPN — Monitoring, Logs, Forensics**

> VPN traffic OneOrtho ↔ AVA6 est monitoré comment ?
> - Logs VPN : enabled sur routeur OneOrtho ? Sur gateway AVA6 ?
> - Rétention logs : combien temps ? (minimum HDS = 1 year ?)
> - Anomalies VPN : who detects (SIEM AVA6 ?) ? Alert OneOrtho si suspicious traffic ?
> - Forensics : si data exfiltration suspected, can OneOrtho extract VPN logs pour audit interne ?

**Référence légale :**
- **HDS Cahier des charges art. 7** : "Logs accès données de santé traçables"
- **ISO 27001:2022 A.12.4.1** : Audit logs retention ≥ 1 year

**Gap actuel :**
- Contrat ne mentionne pas logging du tunnel VPN
- SIEM AVA6 couvre firewall MAIS pas tunnel VPN details

**Action :**Quelle
1. Enable VPN logging on both sides (OneOrtho + AVA6)
2. Retention policy = 1 year minimum (align HDS)
3. Format logs: standard (JSON, syslog) for OneOrtho audit import ?

---

## ⚠️ BLOC 3 : Sécurité Internet & Protection contre Menaces Externes

### Q69 — CRITIQUE
**Firewall Routeur OneOrtho — Configuration, Updates, Threat Protection**

> Routeur OneOrtho a-t-il firewall activé ?
> - Firewall mode : Enabled/disabled ? State-full inspection ?
> - Rules : Qui configure ingress/egress rules ? AVA6, OneOrtho, ou tier local ?
> - IPS/IDS : Intrusion detection active sur routeur ? Qui monitor alerts ?
> - Antispam/Webfiltering : Enabled ? Qui maintient signatures ?
> - Firmware updates : How often ? Automatic ou manual ? Risk si mises à jour cassent VPN ?

**Pourquoi Important :**
Routeur non-securisé = gateway infections malware → données patients exposed.

**Référence légale :**
- **HDS Cahier des charges art. 9** : "Protection contre menaces externes requise"
- **ANSSI Guide 2023** : Firewall périphérique manadatoire

**Gap actuel :**
- Contrat mention "Firewall partagé" AVA6 side MAIS rien routeur OneOrtho
- Pas de security policy firewall local

**Action :**
1. Audit firewall configuration routeur OneOrtho (ports ouverts ? Rules restrictive ?)
2. Enable IPS/IDS si available
3. Document firewall rules + owner (qui peut modifier ?)

---

### Q70 — IMPORTANT
**DDoS / Botnet Protection — Site OneOrtho**

> Y a-t-il protection DDoS sur connexion internet OneOrtho ?
> - Upstream DDoS mitigation (fournisseur internet ?) ?
> - Routeur OneOrtho peut absorber DDoS attaques ?
> - Rate limiting configuré sur routeur ?
> - Monitoring traffic anomalies (spike détection) ?

**Référence légale :**
- **HDS Cahier des charges art. 9** : "Protection attacks"
- **ANSSI Guide DDoS 2023** : DDoS protection recommended

**Gap actuel :**
- Contrat mentionne anti-DDoS chez AVA6 MAIS rien côté OneOrtho

**Action :** Demander DDoS SOP si detected.

---

### Q71 — IMPORTANT
**Accès Internet Employés — Policy, Filtering, Monitoring**

> Quel contrôle sur accès internet d'employés OneOrtho ?
> - Web filtering : Blocus sites malveillants / NSFW ? Centralisé (routeur) ou client-side (proxy) ?
> - Bandwidth throttling : Limite téléchargement/streaming pour garder bande passante données patients ?
> - Logging : URLs visitées tracked ? Retention ? Compliance RGPD (employé privacy) ?
> - VPN employes : 10x SSL logins (contrat) = pour outside office ? Firewall rules pour VPN employees ?

**Référence légale :**
- **RGPD art. 5.1(a)** : Lawfullness, fairness, transparency (monitoring employés doit être transparent)
- **Code du travail art. L2121-3** : Employé privacy (cannot monitor personal internet use)
- **HDS** : Si employé accès patient data via personal device → logs doivent l'attester

**Gap actuel :**
- Contrat mentionne "10x VPN SSL logins" MAIS pas firewall rules/monitoring

**Action :**
1. Document web filtering policy OneOrtho
2. Ensure monitoring align with employee privacy laws
3. VPN employees = access contrôlé à quoi ? (seulement infra AVA6 ?)

---

## ⚠️ BLOC 4 : Incident Response & SLA Responsabilités

### Q72 — CRITIQUE
**Incident Response Routeur OneOrtho — SLA, Escalation, Responsabilité**

> Si routeur OneOrtho broken/compromised, quel est SLA ?
> - Who notifies ? OneOrtho IT → AVA6 ? AVA6 autodetect ?
> - Response time : ≤ 1h ? ≤ 4h ? Critère "critical = affects users" ?
> - On-site intervention : Technician local response ? ou remote only ?
> - Repair/replacement : Budget include routeur remplacement ? ou OneOrtho pays extra ?

**Référence légale :**
- **HDS Cahier des charges art. 10** : "SLA incident response défini"
- **CSP** : Healthcare system must resume operations quickly

**Gap actuel :**
- Contrat says "MCO N1 support" MAIS SLA spécifique routeur = not mentioned
- On-site vs remote support = not clear

**Action :** Demander :
1. SLA incident routeur (response < 1h ?)
2. Who provides on-site intervention (AVA6 ? ou tier local ?)
3. Cost include remplacement routeur si failure ?

---

### Q73 — IMPORTANT
**Cyberattack Scenario — Ransomware, Malware Propagation**

> Si routeur OneOrtho compromis par malware/ransomware :
> - Isolation automatique VPN → datacenter AVA6 (containment) ?
> - Alert SIEM AVA6 : Détect lateral movement via VPN bridge ?
> - Communication : OneOrtho notifié immédiatement si trafic suspect ?
> - Recovery : Peut-on isoler routeur sans couper accès urgent patients ?

**Référence légale :**
- **HDS Cahier des charges art. 9.3** : "Incident isolation procedure prédéfini"

**Gap actuel :**
- No documented procedure

**Action :**
1. Define isolation procedure (if VPN traffic malicious → auto-disconnect ?)
2. Recovery plan (hardening routeur after compromise)

---

### Q74 — IMPORTANT
**Support Technique Tier Local — Training, Availability, Expertise**

> Qui fournit support technique ON-SITE pour routeur/réseau OneOrtho ?
> - AVA6 send technician on-site ? Frequency ? Cost ?
> - Tier local partner (Colt, Orange ?) ?
> - OneOrtho IT intern (formé ?) ?
> - SLA response time : ≤ 4h or ≤ 24h ?

**Référence légale :**
- **HDS** : Personnel technique doit être formé HDS

**Gap actuel :**
- Contrat says "UTS credits" (on-site time) PUIS MCO but not specific "réseau support"

**Action :**
1. Clarify: Who handles on-site network incidents
2. Training: Are on-site techs HDS-compliant trained ?

---

## ⚠️ BLOC 5 : Administration & Change Management Routeur

### Q75 — IMPORTANT
**Change Management Routeur — Who Decides, Approval, Testing**

> Si changement routeur (firmware, config, rules) DOIT être appliqué :
> - Approval process : OneOrtho IT approves ? ou AVA6 decides ?
> - Testing : Changement testé on test environment or direct production ?
> - Rollback plan : Si changement cassé → who reverts + SLA ?
> - Audit trail : Tous changements loggés (who, what, when) ?

**Référence légale :**
- **ISO 27001:2022 A.12.1.2** : Change management mandatory for critical equipment
- **HDS Cahier des charges art. 9** : Changements infra doivent être tracés

**Gap actuel :**
- Contrat "change management" mentionné chez AVA6 MAIS rien sur routeur OneOrtho

**Action :**
1. Document change management procedure routeur
2. Approval rights : who has authority
3. Audit logs : all changes traceable

---

### Q76 — IMPORTANT
**Access Control Routeur Admin — Credentials, MFA, Audit Logs**

> Qui peut administrer le routeur OneOrtho ?
> - Admin credentials : Who has ? Password policy ? MFA enabled ?
> - Access method : SSH ? Console port ? Web UI ? VPN tunneled ?
> - Audit logs : Admin access logged ? Rétention ?
> - Segregation : Admin accès séparé des autres VLANs ?

**Référence légale :**
- **ISO 27001:2022 A.9.1** : Access control admin accounts
- **ANSSI Guide 2023** : Admin accounts doivent avoir MFA

**Gap actuel :**
- No documented admin access policy

**Action :**
1. Enable MFA on admin access
2. Implement SSH (not telnet)
3. Log and monitor all admin actions

---

## 📊 SUMMARY TABLE — Questions Infrastructure Interne (Q62-Q76)

| Q# | Priorité | Sujet | Référence Légale | Responsable Reponse |
|---|---|---|---|---|
| **Q62** | 🔴 CRITICAL | Schéma architecture OneOrtho | HDS art. 6, ISO 27001 A.13 | AVA6 + OneOrtho IT |
| **Q63** | 🟠 IMPORTANT | Internet connection OneOrtho | HDS art. 8 | OneOrtho + ISP |
| **Q64** | 🟠 IMPORTANT | Routeur specs & maintenance | HDS art. 9, ISO 27001 A.12.6 | AVA6 MCO |
| **Q65** | 🟠 IMPORTANT | Switch réseau local | HDS art. 3, ISO 27001 A.13.1.3 | OneOrtho IT |
| **Q66** | 🔴 CRITICAL | VPN chiffrement & config | HDS art. 4, ANSSI RGS | AVA6 |
| **Q67** | 🟠 IMPORTANT | Redondance VPN failover | HDS art. 8 | AVA6 + OneOrtho |
| **Q68** | 🟠 IMPORTANT | VPN logs & forensics | HDS art. 7, ISO 27001 A.12.4.1 | AVA6 |
| **Q69** | 🔴 CRITICAL | Firewall routeur OneOrtho | HDS art. 9, ANSSI | AVA6 MCO |
| **Q70** | 🟠 IMPORTANT | DDoS protection | ANSSI Guide | ISP + routeur |
| **Q71** | 🟠 IMPORTANT | Web filtering employees | RGPD + Code travail | OneOrtho IT |
| **Q72** | 🔴 CRITICAL | Incident response routeur SLA | HDS art. 10 | AVA6 MCO |
| **Q73** | 🟠 IMPORTANT | Cyberattack containment | HDS art. 9.3 | AVA6 SIEM + routeur |
| **Q74** | 🟠 IMPORTANT | Support technique on-site | HDS training | AVA6 ou tier local |
| **Q75** | 🟠 IMPORTANT | Change management routeur | ISO 27001 A.12.1.2 | AVA6 + OneOrtho |
| **Q76** | 🟠 IMPORTANT | Admin access control | ISO 27001 A.9.1 | AVA6 MCO |

---

## 🔍 INTEGRATION AVEC QUESTIONS EXISTANTES (Q41-Q61)

| Domaine | Q41-Q61 Couverture | Q62-Q76 Découle |
|---|---|---|
| **Données en transit** | Q49 (chiffrement TLS RDP) | Q66 (VPN encryption IPSec) |
| **Isolement réseau** | Q46 (VLAN AVA6) | Q65 (VLAN OneOrtho local) |
| **Incident Response** | Q50-Q53 (datacenter) | Q72-Q73 (routeur OneOrtho) |
| **Access Control** | Q41-Q43, Q56 (audit rights) | Q76 (admin routeur) |
| **Monitoring/Logs** | Q52 (SIEM logs) | Q68 (VPN logs) |

---

## 📋 RECOMMENDED ACTIONS — Timeline

### 🔴 **SEMAINE 1 — CRITICAL**
1. **Q62** : Obtenir architecture réseau complète OneOrtho (diagram)
2. **Q66** : Validation IPSec encryption parameters (AES-256 ?)
3. **Q69** : Audit firewall routeur OneOrtho (rules, IPS status)
4. **Q72** : Define SLA incident routeur (response time)

### 🟠 **SEMAINE 2 — HIGH**
5. **Q63** : Internet connection contract review (backup failover ?)
6. **Q64** : Routeur specs + versioning procedure
7. **Q67** : Confirm VPN redundancy (or upgrade to dual tunnels)
8. **Q76** : Enable MFA admin routeur access

### 🟡 **SEMAINE 3 — MEDIUM**
9. **Q65** : Valider VLAN segmentation OneOrtho local
10. **Q68** : Enable VPN logging + retention 1 year
11. **Q73** : Cyberattack containment procedure
12. **Q75** : Formaliser change management routeur

---

## 💼 NEXT STEPS

1. **Merge Q62-Q76** avec documents existants (Q41-Q61)
2. **Envoyer** à AVA6 avec deadline 14 jours pour clarifier
3. **Audit infrastructure** OneOrtho site with external auditor si required
4. **Document** architecture finalised dans dossier conformité HDS

