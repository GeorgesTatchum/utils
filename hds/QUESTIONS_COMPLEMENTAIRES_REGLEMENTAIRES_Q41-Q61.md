# QUESTIONS COMPLEMENTAIRES & REGLEMENTAIRES
## Compléments aux 40 questions existantes — Défaillances HDS identifiées

**OneOrtho × AVA6 — Gestion des données de santé (données patients)**  
**Date : 15 avril 2026**  
**Classification : CONFIDENTIEL**

---

## 📋 Correspondance avec les catégories du questionnaire existant

### 1️⃣ **Services facturés** (2 défaillances reclassées)
- **Défaillance #7** → Q50-Q52 : SLA SIEM/SOC absent (service SIEM livré par REDSOC, mais pas de SLA détection/notification)
- **Défaillance #11** → Q55 : SLA récupération données non formalisé (service PRA/PCA inclus, mais RTO/RPO flou)

### 2️⃣ **Responsabilités** (6 défaillances reclassées)
- **Défaillance #2** → Q41-Q43 : Interdiction accès données patients non documentée (accès technique limité vs. consultation données)
- **Défaillance #3** → Q44-Q45 : Tests pénétration non contractualisés (responsabilité sécurité testing)
- **Défaillance #6** → Q50-Q53 : Coupure responsabilité incident (notification CNIL, escalade SOC) ->>> suite dès le 53
- **Défaillance #9** → Q58-Q59 : Sous-traitance en cascade non agréée (REDSOC, WatchGuard responsabilité)
- **Défaillance #10** → Q56-Q57 : Droit audit OneOrtho non reconnu (surveillance & audit rights)
- **Défaillance #12** → Q60-Q61 : Accès données réquisition judiciaire non procéduralisé (procédure légale manquante)

### 3️⃣ **Conformité HDS** (4 défaillances reclassées)
- **Défaillance #1** → Synthèse générale : Responsabilité HDS non explicite (CSP L.1111-8 — contrat HDS formel requis)
- **Défaillance #4** → Q46-Q47 : Isolement inter-clients non garanti (HDS art. 3 obligation)
- **Défaillance #5** → Q48-Q49 : Chiffrement données non clarifié (HDS art. 4 obligation)
- **Défaillance #8** → Q54-Q55 : Destruction données non procéduralisée (HDS art. 5 obligation + certificat)

### 4️⃣ **Commercial & renouvellement**
- *Aucune défaillance spécifiquement commerciale* — Les 12 défaillances sont de nature technique/légale

---

## QUESTIONS ADDITIONNELLES — Par domaine HDS

### ⚠️ BLOC 1 : Traçabilité des données de santé (défaillance #2)

#### Q41 — CRITIQUE
**Clause d'interdiction d'accès applicatif à la base patientes**

> Qu'est-ce que AVA6 contractualise explicitement comme "interdiction d'accès"? 
> - Accès physique/Linux seulement (MCO technique) ? ✓ Acceptable
> - Mais techniquement, un admin AVA6 avec accès RDP DSPROD peut consulter la base patiente ? 
> - Existe-t-il une clause qui défend, même techniquement, la consultation de la base applicatif ?

**Référence légale :**
- **HDS Cahier des charges art. 6 § 2** : "l'hébergeur ne peut accéder aux données de santé que pour l'exercice des activités d'exploitation et de maintenance"
- **RGPD art. 28.3(c)** : "seules les personnes autorisées par le responsable de traitement et liées par confidentialité"
- **CSN Santé 2022** : Bonnes pratiques isolation: "La base applicative ne doit pas être consultable par le support technique"

**Lien documentation AVA6 :**
- Contrat d'hébergement P.2 : "AVA6 s'engage à ne pas manipuler les données" (flou)
- Aucun contrat séparé de confidentialité envers les techniciens AVA6

**Action :** Obtenir de AVA6 :
1. Politique de confidentialité signée par ogni technicien
2. Isolation technique base app (user distinct, pas d'accès direct)
3. Audit trace: logs des tentatives d'accès à la base patient par comptes AVA6

---

#### Q42 — CRITIQUE
**Données de santé identifiées et périmètre de protection**

> Quel est la liste exhaustive des données de santé hébergées chez AVA6 ?
> - Base patientes DSPROD ? ✓ Oui (patients orthopédie)
> - Fichiers Imagerie médicale GDPROD ? ✓ Oui (images IRM, radiographies)
> - Données administratives (ASSURANCE) ? À vérifier
> - Logs applicatif contenant pseudos patients (UI logs) ? À vérifier
> - Dumps backup contenant données réelles vs anonymisées ? À vérifier

**Pourquoi c'est important :**
OneOrtho doit déclarer à la CNIL **chaque flux de données de santé** quittant le datacenter OneOrtho vers AVA6.

**Référence légale :**
- **HDS Cahier des charges art. 1** : "Identification et classification des données de santé"
- **RGPD art. 30** (Registre des traitements) : registre doit identifier "toutes les données personnelles de santé, leur nature, leur destination"
- **CSP art. L.1110-1** : Définition des données de santé = donnée relative à la santé d'une personne

**Lien documentation OneOrtho :**
- Architecture One-platform : DGPROD contient des images IRM (donné psychométrie RADS scores)
- DSPROD contient fiche patient (antécédents, allergies, protocoles chirurgie)
- Backup retention 15j = **données réelles conservées 15 jours chez AVA6**

**Action :** Cartographier et classifier :
1. Liste exhaustive données de santé par serveur AVA6
2. Criticité (patient-identifié vs pseudonymisé vs anonymisé)
3. Vérifier CNIL = déjà déclaré chez AVA6 comme tiers

---

#### Q43 — IMPORTANT
**Accès des techniciens tierces à la baie AVA6 (faits AVA6)**

> Quel personnel accède physiquement à la baie serveurs OneOrtho ?
> - Techniciens AVA6 ? (formés confidentilité HDS ?)
> - Prestataires maintenance réseau ? (Colt, Orange, etc.)
> - Auditeurs de sécurité (pentest) ? 

**Référence légale :**
- **HDS Cahier des charges art. 6** : "L'hébergeur contrôle l'accès physique et limite aux personnes autorisées"
- **ANSSI Guide Sécurité Données Sensibles** : "Personnel technique doit signer accord confidentialité HDS"

**Action :** Demander à AVA6 :
1. Liste nominative personnel accédant aux baies avec données OneOrtho
2. Attestation formation confidentialité HDS pour chaque technicien
3. Contrat de confidentialité signé

---

### ⚠️ BLOC 2 : Tests de sécurité et pénétration (défaillance #3)

#### Q44 — CRITIQUE
**Tests de pénétration annuels sur l'infra hébergeant données de santé**

> AVA6 réalise-t-il des tests de pénétration (pentest) annuels ?
> - Scope : Full pentest de l'infrastructure ? Ou juste audit de conformité ?
> - Périmètre : Inclut-il les VMs OneOrtho ou infrastructure mutualisée seulement ?
> - Résultats communiqués à OneOrtho ? Dans quel délai ?
> - Corrections vulnérabilités : SLA de remediation ?

**Référence légale :**
- **HDS Cahier des charges art. 9** : "Tests d'intrusion au moins annuels" 
- **ISO 27001:2022 A.14.2.3** : Essais vulnérabilité annuels min
- **ANSSI Recommandations 2023** : Pentest scope doit inclure "tous les accès aux données sensibles"

**Lien documentation :**
- Contrat d'hébergement P.1 : "Deux fois par an, le niveau de sécurité du DC est révisé" (≠ pentest)
- CGCLOUD certification HDS nov 2025 : Doit mentionner pentest comme composante

**Action :** Demander à AVA6 :
1. Plan annuel pentest (date, scope, provider)
2. Dernier rapport pentest (date, vulnérabilités trouvées, remediation)
3. Vérification pentest inclut acc VPNs employees (195.42.148.160 RDP publique)

---

#### Q45 — IMPORTANT
**Scan de vulnérabilité continu (CVSS) sur les serveurs** 

> Quel outil AVA6 utilise-t-il pour le scan de vulnérabilité continu ?
> - Qualys, Nessus, Tenable, autre ?
> - Fréquence scans ? (hebdomadaire, mensuel ?)
> - Alertes OneOrtho en cas de nouvelle CVE ? Dans quel délai ?
> - SLA remediation pour vulnérabilités critiques (CVSS > 8.0) ?

**Référence légale :**
- **HDS Cahier des charges art. 9.1** : "Scan de vulnérabilité requis au minimum mensuellement"
- **ANSSI Guide Aladdin 2023** : "Scan continu (< 7 jours) recommandé pour hébergement données sensibles"
- **ISO 27001:2022 A.12.6.1** : Management des vulnérabilités requiert scan régulier

**Lien documentation :**
- Contrat MCO N1 (Q3) : Pas de définition du "scan" inclus
- Article 37 du contrat évoque "supervision" mais pas scan applicatif

**Action :** Demander à AVA6 :
1. Copie derniers scans vulnérabilité (30 jours)
2. Fréquence scans contractualisée
3. Alert SOP en cas CVSS > 7.0

---

### ⚠️ BLOC 3 : Isolation inter-clients & segmentation réseau (défaillance #4)

#### Q46 — CRITIQUE  
**Isolement logique VLAN OneOrtho vs autres clients AVA6**

> Quel est la garantie d'isolement réseau OneOrtho/Autres clients dans le contrat ?
> - VLAN dédié OneOrtho ? Avec quel VLAN ID ?
> - Isolation au niveau firewall aussi ? Quel firewall (AVA6 vs client) ?
> - A-t-il un test d'isolement périodique ? (tentative traversée VLAN)
> - Risque : Si un autre client compromis, peut-il accéder oneortho VLAN ?

**Pourquoi HDS exige ça :**
Données de santé de deux clients OneOrtho et Un-Tiers ne doivent pas polluer l'une l'autre.

**Référence légale :**
- **HDS Cahier des charges art. 3** : "Le responsable de traitement s'assure de la séparation appropriée des données entre clients"
- **ANSSI Recommandations 2023** : "VLAN par client minimum; firewall inter-VLAN + tests d'isolement trimestriel"
- **ISO 27001:2022 A.13.1.3** : "Isolement du réseau pour chaque client en hébergement mutualisé"

**Lien documentation :**
- Contrat P.3 : "VLAN...tous les clients sont partitionnés par VLAN dédié per client" (= OK théoriquement)
- **MAIS** Firewall mutualisé (Q2) = risque règles firewall partagées mal isolantes

**Action :** Demander à AVA6 + tester :
1. Diagramme réseau VLAN OneOrtho (ID VLAN, IPs, serveurs)
2. Règles firewall inter-VLAN OneOrtho ↔ Autres clients (confirmé pas traverse)
3. Dernier test isolement inter-VLAN (date, résultats)
4. Audit périodicité isolement (trimestriel min HDS)

---

#### Q47 — IMPORTANT
**Partage CPU/RAM avec d'autres clients — contention ressources**

> Les serveurs OneOrtho partagent-ils physiquement CPU/RAM avec serveurs d'autres clients AVA6 ?
> - Hyperviseur : VMware/KVM/Hyper-V ? 
> - CPU pinning pour OneOrtho ? Ou "best effort" sharing ?
> - RAM reserved (contrat) ou ballooned (partage dynamique) ?
> - Risk: Autre client CPU-intensif → ralentissement OneOrtho ?

**Pourquoi HDS exige ça :**
Données patient ne doivent pas être dégradées par contention CPU on d'autres clients.

**Référence légale :**
- **HDS Cahier des charges art. 8.2** : "Ressources garanties pour traitement donnees sensibles"
- **ANSSI Guide 2023** : "Recommande réservation garantie CPU/RAM vs sharing best-effort"

**Lien documentation :**
- Contrat : Mentionne "1 vCPU / 1 GB RAM" mais pas CPU pinning / reserved memory guarantee
- GDPROD 96% disque usage = peut avoir contention aussi CPU/RAM

**Action :** Demander à AVA6 :
1. Architecture: CPU pinning vs ballooning pour OneOrtho ?
2. Monitoring ressources contention (CPU wait, memory swapped) — stats 6 derniers mois
3. SLA performance: if autre client cause degradation, AVA6 responsible ?

---

### ⚠️ BLOC 4 : Chiffrement données (défaillance #5)

#### Q48 — CRITIQUE
**Chiffrement données au repos (storage encryption)**

> Les données de santé stockées chez AVA6 sont-elles chiffrées au repos ?
> - Hypervisor storage encryption ? (BitLocker, dm-crypt)
> - SAN storage encryption ? (baie de stockage)
> - Encryption key management : où sont les clés (chez AVA6 chez OneOrtho ?)
> - OneOrtho contrôle les clés ? (required for data residency autonomy)

**Référence légale :**
- **HDS Cahier des charges art. 4** : "Données de santé doivent être chiffrées en transit et au repos, sauf impossible, alors justifier"
- **ANSSI RGS v2.1** : "Chiffrement AES-256 minimum au repos pour données critiques"
- **ISO 27001:2022 A.10.1.1** : "Encryption at-rest for Confidential data (include health data)"

**Lien documentation :**
- Contrat : Silencieux sur chiffrement storage
- Contrat Q11 : "Storage Full Flash" mentionné mais pas tech encryption

**Action :** Demander à AVA6 :
1. Confirmation: Tous serveurs OneOrtho chiffrés AES-256+ at-rest ?
2. Key management: Où sont stockées clés ? (fournisseur d'identité, HSM, OneOrtho?)
3. Impossibilité AVA6 lire données hors clés OneOrtho ?
4. Certificat chiffrement (ex: ISO audit, SOC 2)

---

#### Q49 — IMPORTANT
**Chiffrement données en transit (wire encryption)**

> Les données patient en transit depuis poste OneOrtho → serveurs AVA6 sont-elles chiffrées ?
> - HTTPS/TLS 1.2+ pour Web UI ? ✓ Oui
> - VPN pour RDP admin ? Obligatoire ou optional ?
> - Sauvegarde backup replication entre datacenters : chiffrée ?
> - Transferts fichiers (SCP, SFTP, rsync) : chiffrement requis ?

**Référence légale :**
- **HDS Cahier des charges art. 4** : Chiffrement en transit equally importante
- **ANSSI TLS Guidelines 2023** : TLS 1.2 minimum, TLS 1.3 recommandé

**Lien documentation :**
- Contrat Q13 : RDP exposés directement IP publique 195.42.148.160 port 33900-33906 (=pas VPN forcé)
- Cela signifie RDP traffic could être in clear si client RDP client config pas TLS

**Action :** Demander à AVA6 + implémenter :
1. Force TLS encryption RDP (network layer)
2. Mandatory VPN for RDP access (no direct IP)
3. Backup replication encryption (AES-256) between DCs
4. Audit réseau: capture de quelques packets pour confirmer chiff

---

### ⚠️ BLOC 5 : Détection incident & notification CNIL (défaillance #6)

#### Q50 — CRITIQUE
**SLA de notification incident de sécurité affectant données santé**

> En cas d'incident de sécurité (ransomware, intrusion, data breach), quel est le SLA de notification AVA6 → OneOrtho ?
> - Délai notification : 1h ? 4h ? 24h ?
> - Qui notifie ? Quel canal (email, phone, ticket) ?
> - Notification doit être écrite + phone escalade ?
> - Information minimale dans notification : quoi, quand, impact ?

**Référence légale :**
- **HDS Cahier des charges art. 10** : "Notification inmédiate (= 24h maximum) tout incident accès données"
> - **CSP art. L.1110-4** : Notification CNIL obligatoire "dès confirmation attaque"
> - **RGPD art. 33** : CNIL notification under 72h si personal data breach

**Contexte actuel :**
- Q14 : "Quel est le délai notification par AVA6 ?" CRITIQUE = **PAS REPONDU DANS LE CONTRAT**
- SIEM v1.0 montre detection capabilité MAIS pas SLA to escalate OneOrtho

**Action immédiate :**
1. Demander à AVA6 SLA écrit : notification < 24h de découverte incident
2. Formaliser escalade escalade: SOC REDSOC → AVA6 → OneOrtho dans SLA
3. Contact plan: SMS + email + phone d'emergency

---

#### Q51 — CRITIQUE
**Procédure de déclaration CNIL — responsabilité hébergeur vs client**

> En cas de violation de données de santé chez AVA6, qui déclare à la CNIL ? Quand ?
> - AVA6 responsable de d'alerte OneOrtho immédiatement ?
> - OneOrtho responsable déclarer CNIL sous 72h ?
> - Modèle responsabilité : AVA6 déclare CNIL + informe OneOrtho, OU AVA6 informe OneOrtho qui déclare ?

**Référence légale :**
- **HDS Cahier des charges art. 10.2** : "Hébergeur informe responsable traitement violton de données et éléments factuels pour CNIL notification"
> - **CSP art. L.1110-4** : "Tout hébergeur doit notifier à la CNIL...en cas violation données patients"
> - **RGPD art. 33 & 34** : Notification obligation sous 72h si "high risk to natural persons" (health data = high risk)

**Gap actuel :**
- Contrat ne prévoit RIEN sur procédure CNIL
- Risque: Délai CNIL dépasse car entre OneOrtho/AVA6 hand-off time lost

**Action :**
1. Formaliser dans contrat: AVA6 notifie OneOrtho < 24h + fourni info factuelles pour CNIL déclara
2. Modèle: AVA6 assists OneOrtho dans CNIL notification or déclare de sa propre initiative ?
3. Template notification préformaté entre par contrat

---

#### Q52 — IMPORTANT
**Logs SIEM & incident forensics — rétention & transfert**

> Où sont stockés les logs SIEM OneOrtho ? Comment OneOrtho y a-t-il accès ?
> - Logs stockés chez AVA6 + REDSOC ? (dual location ?)
> - Rétention durée ? (1 month, 3 months, 1 year ?)
> - OneOrtho peut-il extraire logs complets pour forensics interne ?
> - Backup logs: est-ce sauvegardé à long terme (1-2 ans) hors infra AVA6 ?

**Référence légale :**
- **HDS Cahier des charges art. 7** : "Logs d'accès doivent être conservés minimum 1 an hors infra hébergeur si possible"
> - **CSP art. L.1110-5** : "Logs de traitement données santé: rétention min 6 ans ou durée légale"
> - **ISO 27001:2022 A.12.4.1** : Audit logs retention ≥ 1 year typically

**Gap actuel :**
- Q30 : "Logs SIEM sauvegardés hors infra AVA6 ?" → PAS REPONDU
- Contrat ne specific logs rétention contractuell

**Action :**
1. Demander à AVA6 architecture logs: local SIEM + external backup ?
2. Rétention contactuelle: OneOrtho peut récupérer 1 year logs pour forensics ?
3. Transfert format: JSON, syslog, ou proprietrary ?

---

### ⚠️ BLOC 6 : Responsabilité & isolation incident (défaillance #6)

#### Q53 — CRITIQUE
**Confinement/Isolation VM compromisée — procédure & responsabilité**

> Si une VM OneOrtho (ex: DSPROD) est compromisée, comment AVA6 l'isole-t-il ?
> - Isolement réseau automatique par SIEM/SOC ? Ou manuel par OneOrtho request ?
> - Délai isolation maximale avant destruction malware ? 
> - OneOrtho peut-il refuser isolement si impacte production ?
> - Backup VMicronic: est-elle créée avant isolation pour forensics ?

**Référence légale :**
- **HDS Cahier des charges art. 9.3** : "Procédure d'isolement incident doit être prédéfinie & testée"
> - **ANSSI Guide Incident 2022** : "Isolement réseau ≤ 1h après confirmation malware critique"

**Gap actuel :**
> - Q22 : "Isolation d'une VM...nécessite validation OneOrtho ?" → REPONSE: "Procédure...non formalisée"
> - Risque: Délai 4h isolation = malware spread 4 heures = backup also infected

**Action :**
1. Formaliser contrat : SOC REDSOC isole automatiquement VM > CVSS 8 after alerting OneOrtho in realtime
2. OneOrtho SLA respond: 15 min pour validation if needed
3. Backup snapshot BEFORE isol pour forensics

---

### ⚠️ BLOC 7 : Destruction sécurisée données en fin de contrat (défaillance #8)

#### Q54 — CRITIQUE
**Procédure de destruction data — documentation & certificats**

> Comment AVA6 détruit-il les données OneOrtho en fin de contrat ?
> - Standard destruction : wiping (3-pass, 7-pass, Gutmann) ? Ou destruction physique disks ?
> - Outil/Software utilisé : Eraser, BleachBit, proprietrary ?
> - Certificat destruction fourni ? Signé par who ?
> - Certificat mentionne data volume & date destruction ?

**Référence légale :**
- **HDS Cahier des charges art. 5** : "Destruction sécurisée documentée & certificat fourni"
> - **CSP art. L.1111-14** : "Certificat de destruction obligatoire mentionne nature données & date"
> - **ANSSI Guide Encryption 2022** : Si chiffrement, destruction clé = suffisant (pas besoin wiping)
> - **ISO 27001:2022 A.8.3.2** : "Secure disposal procedures documented & verified"

**Gap actuel :**
- Q15 : "Destruction procédure ?documentée ? Certificat ?" → REPONSE: Contrat P.2 mentionne "1 mois sauvegarde avant destruction" MAIS aucune procédure technique
> - Risque: Données patients lisibles sur disque après "destruction"

**Action immediate :**
1. Obtenir de AVA6 : Destruction procedure document (signé, dated)
2. Spécifier sur contrat renouvellement : wiping ≥ 3-pass OU destruction physique disks
3. Certificat destruction template: date, volume, method, responsable

---

#### Q55 — IMPORTANT
**Timeline fin de contrat & reversibilité données**

> Quel est le timeline exact fin de contrat AVA6 ?
> - Contrat stipule "1 month" après fin. Explique: Start date = quand exactement ?
> - OneOrtho peut exporter VMs ? Format (OVA, VMDK, raw) ? Taille export ?
> - Format données applicative (SQL dumps, files exports) ?
> - Reversibilité cost: package 950 € (Q contrat) toujours applicable ?

**Référence légale :**
- **HDS Cahier des charges art. 11** : "Hébergeur doit faciliter réversibilité données (= portabilité)"
> - **RGPD art. 17 & 20** : Droit oubli + droit portabilité données
> - **CSP art. L.1111-14** : "Format données reversibilité doit être standard & accessible"

**Lien contrat :**
- Contrat P.16 : "AVACLOUD reversibilité: 1 mois après date terminaison effective"
> - Package reversibilité extraction removable storage : 950 € excl tax
> - **ABER**: Aucun détail format, pas de SLA export bandwidth

**Action :**
1. Demander reversibilité SLA écrite: data export complet disponible < 7 days
2. Format export: standardized (OVA, SQL dumps) vs proprietrary
3. Confirmé : 950 € reversibility includes ALL OneOrtho data OU per-server/per-TB?

---

### ⚠️ BLOC 8 : Droit d'audit & conformité vérification (défaillance #10)

#### Q56 — IMPORTANT
**Accès audit OneOrtho à l'infra AVA6 — droit & limitation**

> Quel est le droit d'audit OneOrtho chez AVA6 ?
> - OneOrtho peut demander audit interne (visite baie/salle serveur) ?
> - OneOrtho peut demander audit externe (tiers auditeur HDS) ?
> - AVA6 fourni accès logs systems/security pour audit OneOrtho ?
> - Limitation : NonDA (NDA) on audit reports tiers vs partage full OneOrtho ?

**Référence légale :**
- **HDS Cahier des charges art. 6.3** : "Responsable traitement peut auditer hébergeur including on-site"
> - **RGPD art. 28.3(h)** : Sous-traitant must make available info needed for compliance demonstration & audit
> - **ISO 27001:2022 A.6.2** : Access to information needed for audits

**Gap actuel :**
- Q29 : "OneOrtho peut-il auditer AVA6 ?" → Clause non trouvée dans contracts
> - Risque: Audit CNIL impossible prouver conformité hébergeur

**Action :**
1. Ajouter contrat renouvellement: OneOrtho right audit on-site with 30-day notice
2. Communication audit tiers(SOC 2 Type II, HDS audit report): fourni intégrally ou redacted ?
3. SLA réponse audit documentation: < 15 days for requested logs/compliance docs

---

#### Q57 — IMPORTANT
**Rapports SOC 2 Type II & HDS audit tiers — accès OneOrtho**

> AVA6 fourni-il rapports SOC 2 Type II (security, availability, integrity, confidentiality)?
> - Rapport complet fourni OneOrtho ? ou redacted (under NDA avec audit tiers) ?
> - Fréquence rapports: annuels ? Archivés où ? OneOrtho peut y accéder ?
> - HDS audit tiers : rapport conformité HDS = existe ? Date dernier audit ?
> - Period audit : si October 2023, rapport devient « outdated » fin 2024 ?

**Référence légale :**
- **HDS Cahier des charges art. 6.3** : Rapports d'audit tiers doivent âtre consultables par responsable traitement
> - **ANSSI Guide RGPD** : SOC 2 Type II expected for healthcare data hébergement

**Lien documentation :**
- Contrat 2019/2025 : Aucune mention SOC 2 access
> - CGCLOUD Nov 2025 cert HDS: fournisse par AVA6 seulement
> - ISO 27001 Nov 2023 SynAApS : Audit scope unclear (entire DC vs OneOrtho subset)

**Action :**
1. Vérifier: SOC 2 Type II audit existence + date + scope (AVA6 datacenter ou SYNAAPS)
2. Demander accès SOC 2 full report (ou NDA if required)
3. HDS audit report: date + scope + remediation status

---

### ⚠️ BLOC 9 : Sous-traitants & chaîne responsabilité (défaillance #9)

#### Q58 — CRITIQUE
**Liste complète sous-traitants & agrément OneOrtho**

> Qui sont tous les sous-traitants AVA6 ayant accès données OneOrtho ?
> - REDSOC (SOC/SIEM) → accès logs complets → agrément signé ?
> - WatchGuard (EPDR endpoint détection) → accès VMs → agrément signé ?
> - Colt/Orange/SFR (opérateurs Internet) → accès backbone réseau → agrément N/A (infra layer)?
> - Autre : Backup tiers ? Audit tiers ? Managed service provider ?

**Référence légale :**
- **HDS Cahier des charges art. 2.4** : "Responsable traitement doit pre-approve tout sous-traitant"
> - **RGPD art. 28.2 & 28.4** : Sous-traitant ultérieur (sub-processor) prohibited sans écrit authorization du client
> - **CSP art. L.1111-8** : Contrat HDS doit identifier tous intervenants

**Gap actuel :**
- Q24 : "AVA6 peut sous-traiter?" → Réponse: "non mentionné dans contrats"
> - REDSOC & WatchGuard utilisés MAIO = implicit sub-processors
> - OneOrtho JAMAIS formellement agréé REDSOC/WatchGuard accès données

**Action URGENT :**
1. Demander à AVA6: Liste complete sub-processors avec scopes accès
2. OneOrtho signer formal approval letter: REDSOC accès logs OneOrtho, WatchGuard accès EPDR
3. Sub-processor contracts: Include HDS clauses same as AVA6 (confidentialit, notification, audit rights)

---

#### Q59 — IMPORTANT
**Chaîne de responsabilité incident si sous-traitant fait l'erreur**

> Scenario: REDSOC (SOC SIEM) rate incorrect alerte → malware undetected 48h on DSPROD → compromission données patients.
> Who is responsible ?
> - REDSOC (détection failed) ? → mais REDSOC pas contractualized with OneOrtho, pas recours direct
> - AVA6 (failed to manage REDSOC) ? → AVA6 responsible ? Compensation ?
> - OneOrtho (chose AVA6 which chose REDSOC) ? → shared responsibility ?

**Pourquoi important :**
Si chaîne de responsabilité cassée → personne n'a obligations formelles envers OneOrtho.

**Référence légale :**
- **RGPD art. 28.4** : Sub-processors must bind themselves with same obligations to client via contract cascade
> - **HDS Cahier des charges ** : Responsabilité hébergeur inclut supervision sous-traitants
> - **CSP** : If AVA6 sous-traite, AVA6 reste entièrement responsable envers OneOrtho

**Action :**
1. Clarifier contrat: AVA6 responsible for REDSOC performance = AVA6 must guarantee SOC SLA even if REDSOC fails
2. OneOrtho right to audit REDSOC = audit right transitively through AVA6
3. Compensation clause: if incident due to sub-processor, AVA6 liable to OneOrtho

---

### ⚠️ BLOC 10 : Données réquisition judiciaire (défaillance #12)

#### Q60 — IMPORTANT
**Accès gendarmes/police aux données OneOrtho — notification & consentement**

> Scenario: Enquête pénale sur patient → Police demande à AVA6 copie base OneOrtho.
> - Peut-AVA6 donner accès sans notifier OneOrtho ?
> - Notification : trop tard (police disallow) ou OneOrtho prévenu after-fact ?
> - OneOrtho patient confidentiality: protégé contractuellement ?
> - Procédure: ordre judiciaire requis? Ou décision AVA6 unilateral?

**Référence légale :**
- **RGPD art. 28.3(a)** : "Sous-traitant doit inform controller of any legally binding request access data unless legally prohibited"
> - **CSP art. L.1110-4** : Patient medical confidentiality protégé même en enquête criminelle (exceptions très narrow)
> - **CPP art. 81** (Code procédure pénale) : Enquête judiciaire requires mandate préalable

**Gap actuel :**
- Q32 : "Réquisition police?" → not mentionné dans contrat
> - Risque: AVA6 fournit données patients directement police sans alert OneOrtho

**Action :**
1. Ajouter contrat: AVA6 notify OneOrtho = any legal request access OneOrtho data, sauf si interdict legale
2. ProcessProcess: Copie required order => OneOrtho can challenge / provide alternative (anonymized data, ou legal protection)
3. OneOrtho legal right: Assist police inquiry but protect patient anonymity when possible

---

#### Q61 — IMPORTANT
**CNIL / Autorités régulation sanitaires — accès audit données OneOrtho chez AVA6**

> Scenario: CNIL audit (suite plainte) => CNIL demande à AVA6 données OneOrtho = audit OneOrtho infrastructure chez AVA6.
> - AVA6 peut-il autoriser accès CNIL sans OneOrtho explicit? 
> - OneOrtho peut accompagner audit CNIL chez AVA6 ?
> - CNIL report: OneOrtho reçoit copie ou confidential to CNIL only ?

**Référence légale :**
- **RGPD art. 55** : CNIL a authority demander accès any data related investigation
> - **RGPD art. 28.3(a)** : Sous-traitant shall inform controller of request unless prohibited
> - **HDS commissioning** : ARS (Agence Régionale Santé) can audit hebergeur HDS compliance

**Gap :**
- Contrat ne specify CNIL/ARS audit right nor OneOrtho notification

**Action :**
1. Confirm contrat: AVA6 notifie OneOrtho if CNIL/ARS request acces
2. OneOrtho right to accompany audit to confirm compliance
3. OneOrtho receive rapport audit findings (ou redacted if CNIL prohibits)

---

## SUMMARY TABLE — Questions Complémentaires Ajoutées

| Q# | Priorité HDS | Sujet | Référence Légale | Délai Action |
|---|---|---|---|---|
| Q41 | 🔴 CRITICAL | Clause interdiction accès base patiente | HDS art. 6 § 2 | < 30j |
| Q42 | 🔴 CRITICAL | Données santé identifiées & périmètre | HDS art. 1, RGPD art. 30 | < 30j |
| Q43 | 🟠 IMPORTANT | Accès personnel tiers baie serveurs | HDS art. 6 | < 45j |
| Q44 | 🔴 CRITICAL | Tests pénétration annuels | HDS art. 9, ISO 27001 A.14.2.3 | < 30j |
| Q45 | 🟠 IMPORTANT | Scan vulnérabilité continu (CVSS) | HDS art. 9.1, ANSSI | < 45j |
| Q46 | 🔴 CRITICAL | Isolement VLAN OneOrtho vs autres clients | HDS art. 3, ISO 27001 A.13.1.3 | < 30j |
| Q47 | 🟠 IMPORTANT | Contention CPU/RAM multitenancy | HDS art. 8.2 | < 45j |
| Q48 | 🔴 CRITICAL | Chiffrement données au repos (storage) | HDS art. 4, ANSSI RGS v2.1 | < 30j |
| Q49 | 🟠 IMPORTANT | Chiffrement données en transit (wire) | HDS art. 4, ANSSI TLS | < 45j |
| Q50 | 🔴 CRITICAL | SLA notification incident sécurité | HDS art. 10, CSP L.1110-4, RGPD art. 33 | < 30j |
| Q51 | 🔴 CRITICAL | Procédure CNIL déclaration incident | HDS art. 10.2, CSP L.1110-4 | < 30j |
| Q52 | 🟠 IMPORTANT | Logs SIEM rétention & forensics | HDS art. 7, ISO 27001 A.12.4.1 | < 45j |
| Q53 | 🔴 CRITICAL | Confinement VM compromisée | HDS art. 9.3, ANSSI | < 60j |
| Q54 | 🔴 CRITICAL | Destruction données procedure & certificat | HDS art. 5, CSP L.1111-14 | < 30j |
| Q55 | 🟠 IMPORTANT | Timeline reversibilité données fin contrat | RGPD art. 17 & 20, CSP L.1111-14 | < 60j |
| Q56 | 🟠 IMPORTANT | Audit rights OneOrtho chez AVA6 | HDS art. 6.3, RGPD art. 28.3(h) | < 60j |
| Q57 | 🟠 IMPORTANT | SOC 2 Type II & rapports audit tiers | HDS art. 6.3 | < 60j |
| Q58 | 🔴 CRITICAL | Liste & agrément sous-traitants | RGPD art. 28.2 & 28.4, CSP L.1111-8 | < 30j |
| Q59 | 🟠 IMPORTANT | Chaîne responsabilité incident sous-traitant | RGPD art. 28.4, HDS | < 60j |
| Q60 | 🟠 IMPORTANT | Données réquisition gendarmes/police | RGPD art. 28.3(a), CSP L.1110-4 | < 60j |
| Q61 | 🟠 IMPORTANT | CNIL/ARS audit accès données chez AVA6 | RGPD art. 55, HDS | < 60j |

---

## LINKS RÉGLEMENTAIRES POUR JUSTIFICATION AUPRÈS D'AVA6

Utiliser ces références si AVA6 conteste ou ignore les questions:

### 📋 HDS (Hébergement Données Santé)
- **HDS Cahier des charges v1.0** (2023) : www.esante.gouv.fr/hds
  - Article 1-12: Obligations hébergeur
  - Focus: Art. 3 (isolement), Art. 4 (chiffrement), Art. 6 (accès limité), Art. 9 (tests pentest), Art. 10 (notification incident)

### 📋 RGPD (Règlement Général Protection Données)
- **RGPD art. 28** : Traitement par sous-traitant — responsibilities
- **RGPD art. 28.3** : Contrat sous-traitant clauses obligatoires
- **RGPD art. 33** : Notification autorité surveillance < 72h data breach

### 📋 Code Santé Publique (CSP)
- **CSP art. L.1111-8** : Hébergeur données santé = partie contrat explicite
- **CSP art. L.1110-4** : Notification CNIL obligation incident
- **CSP art. L.1111-14** : Certificat destruction données

### 📋 ANSSI (Agence Nationale Sécurité Systèmes Information)
- **ANSSI Recommandations 2023** : guide.cyber.gouv.fr
- **ANSSI Guide RGPD** : Mesures cryptographiques, incident response
- **ANSSI RGS v2.1** : (Référentiel Général Sécurité) — chiffrement AES-256 std

### 📋 ISO Standards
- **ISO 27001:2022** : Information Security Management
  - A.13.1.3 : Isolement networks multi-tenant
  - A.14.2.3 : Penetration testing
  - A.8.3.2 : Secure disposal
  - A.12.4.1 : Audit logs retention

---

## RECOMMENDED NEXT STEPS

1. **< 7 jours** : Submit Q41-Q61 + "ANALYSE_DEFAILLANCES_HDS_COMPLEMENTAIRE.md" to AVA6 with deadline reponse 14 days
2. **< 30 jours** : Formal meeting with AVA6 CTO + Legal to address 🔴 CRITICAL questions (Q1-Q15 existing + Q41-Q61 new)
3. **< 45 jours** : Legal review: AVA6 proposed amendments to contract vs HDS cahier des charges requirements
4. **< 60 jours** : Renouvellement contract terms finalized & signed with all 🔴 CRITICAL clauses included


Services facturés (2 défaillances)
#7 — SLA SIEM/SOC absent (service SIEM livré par REDSOC, mais pas de SLA détection/notification)
#11 — SLA récupération données non formalisé (service PRA/PCA inclus, mais RTO/RPO flou)
2️⃣ Responsabilités (6 défaillances)
#2 — Interdiction accès données patients non documentée (accès technique limité vs. consultation données)
#3 — Tests pénétration non contractualisés (responsabilité sécurité testing)
#6 — Coupure responsabilité incident (notification CNIL, escalade SOC)
#9 — Sous-traitance en cascade non agréée (REDSOC, WatchGuard responsabilité)
#10 — Droit audit OneOrtho non reconnu (surveillance & audit rights)
#12 — Accès données réquisition judiciaire non procéduralisé (procédure légale manquante)
3️⃣ Conformité HDS (4 défaillances)
#1 — Responsabilité HDS non explicite (CSP L.1111-8 — contrat HDS formel requis)
#4 — Isolement inter-clients non garanti (HDS art. 3 obligation)
#5 — Chiffrement données non clarifié (HDS art. 4 obligation)
#8 — Destruction données non procéduralisée (HDS art. 5 obligation + certificat)

