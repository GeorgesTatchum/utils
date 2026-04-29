# SYNTHESE EXECUTIVE — Analyse Complète Contrat AVA6 & Défaillances HDS
## OneOrtho — Gestion Données Patients Hébergées AVA6

**Document confidentiel - Comité technique OneOrtho**  
**Date : 15 avril 2026**  
**Classification : CONFIDENTIEL — Usage interne**

---

## 📌 EXECUTIVE SUMMARY

### État des lieux :
- ✅ **40 questions existantes** identifiées dans `questions_point_ombre.md`
- ✅ **12 défaillances majeures** identifiées en matière de protection données de santé (`ANALYSE_DEFAILLANCES_HDS_COMPLEMENTAIRE.md`)
- ✅ **21 questions complémentaires** avec références légales (`QUESTIONS_COMPLEMENTAIRES_REGLEMENTAIRES_Q41-Q61.md`)

### Risque global : 
**CRITIQUE** — Le contrat AVA6 existant présente des lacunes substantielles en conformité HDS qui pourraient engager la responsabilité pénale de OneOrtho en audit CNIL ou en cas d'incident de sécurité affectant les données patients.

### Réaction urgente requise :
- Réunion avec AVA6 < 30 jours avec toutes les questions CRITIQUE
- Intégration des clauses HDS manquantes avant renouvellement contrat (prévu ?)
- Audit interne de la conformité HDS OneOrtho chez AVA6

---

## 🔴 LES 12 DEFAILLANCES MAJEURES

### Bloc 1 : Traçabilité & Accès aux données patients

| # | Défaillance | Impact | Référence légale |
|---|---|---|---|
| 1 | Responsabilité HDS de AVA6 non explicite dans contrat | Hébergement invalide en audit CNIL | **CSP L.1111-8** |
| 2 | Interdiction accès base patients par techniciens AVA6 non documentée | Risque consultation données patients par admin AVA6 | **HDS art. 6** |
| 3 | Données santé périmètre non cartographiées formellement | CNIL = impossible déclarer hébergeur | **RGPD art. 30** |

### Bloc 2 : Tests sécurité & détection

| # | Défaillance | Impact | Référence légale |
|---|---|---|---|
| 4 | Tests pénétration annuels non contractualisés | Failles de sécurité non détectées | **HDS art. 9, ISO 27001 A.14.2.3** |
| 5 | SLA détection malware/intrusion absent | Incident détecté en retard (> 24h) | **HDS art. 7, ANSSI** |
| 6 | SLA notification incident OneOrtho absent | Délai CNIL (72h) potentiellement dépassé | **RGPD art. 33, CSP L.1110-4** |

### Bloc 3 : Isolement données

| # | Défaillance | Impact | Référence légale |
|---|---|---|---|
| 7 | Isolement inter-clients (VLAN) non contractualisé | Risque fuite données patients vers autre client | **HDS art. 3, ISO 27001 A.13.1.3** |
| 8 | Chiffrement données au repos non spécifié | Données patients lisibles en cas accès non autorisé | **HDS art. 4, ANSSI RGS v2.1** |
| 9 | Chiffrement données transit non documenté | Données en clair sur réseau public si VPN non obligatoire | **HDS art. 4** |

### Bloc 4 : Gouvernance & responsabilité

| # | Défaillance | Impact | Référence légale |
|---|---|---|---|
| 10 | Sous-traitants (REDSOC, WatchGuard) non agréés OneOrtho | Chaîne responsabilité cassée en incident | **RGPD art. 28.2 & 28.4** |
| 11 | Destruction données fin contrat non procéduralisée | Données résiduel accessibles après fin contrat | **HDS art. 5, CSP L.1111-14** |
| 12 | Droit audit OneOrtho chez AVA6 non reconnu | Conformité HDS non vérifiable par OneOrtho | **RGPD art. 28.3(h)** |

---

## 📊 ANALYSE RISQUE PAR DONNEE CRITIQUE

### 🏥 Données Patients — Critiques hébergées chez AVA6 :

**DSPROD (Production)** — Base patientes ERP
- Données : Fiche patient (identité, antécédents, allergies, protocoles chirurgie)
- Volumétrie : ~2 TB + 1 TB backup  
- Criticité : 🔴 TRÈS CRITIQUE (données identifiées patients)
- Risque actuels :
  - Pas de test pentest annuel formalicé → faille possible inexplorée
  - No chiff at-rest → lisible si vol disque ou accès non-autorisé
  - Isolement inter-client non garantie → fuite possible vers autre client AVA6
  - Notification incident « possible » mais délai flou → CNIL deadline risque

**GDPROD (Production)** — Images IRM + Radiographies patients
- Données : Images médicales patients (très sensibles, HIPAA-Equivalente)
- Volumétrie : ~2.6 TB à 96% disque capacity (ALERTE saturation Q35)
- Criticité : 🔴 TRÈS CRITIQUE
- Risque actuels :
  - Quasi-saturation disque (96%) → perte données imminente si pas alerte contractuelle
  - Aucune SLA alerte saturation → OneOrtho discover too-late
  - Chiffrement : unclear

**BACKUP 15j retention** — Copies données patients
- Stockate : ~3-4 TB backups réplication AVA6
- Criticité : 🔴 TRÈS CRITIQUE (données accessibles si loss prod servers)
- Risque actuels :
  - Destruction sécurisée NO procédure → données patient copiées possiblement readable after retention
  - Chiffrement backups : not specified
  - Remplacement automatique after 72h ? Non spécifié

---

## 🚨 SCÉNARIOS DE RISQUE — Impact OneOrtho

### Scénario 1 : Intrusion sur DSPROD (données patients) — délai notification CNIL dépassé

1. **Jour 1 8h** : Ransomware détecti sur DSPROD par SIEM REDSOC
2. **Jour 1 ?** : REDSOC alert AVA6? Dans quel délai? (SLA = absent)
3. **Jour 1 ?** : AVA6 alert OneOrtho? Dans quel délai? (SLA = absent, contrat dit rien)
4. **Jour 2/3** : OneOrtho découvre l'incident = DATA BREACH confirm
5. **Jour 3 72h** : OneOrtho doit déclarer CNIL (CSP L.1110-4, RGPD art. 33)
6. **MAIS** : Délai hand-off entre REDSOC → AVA6 → OneOrtho = possible > 48h = CNIL délai risque

**Impact :**
- ❌ Amende CNIL si notification > 72h
- ❌ Données patients compromise : notification patients obligatoire
- ❌ Audit CNIL likelihood high

**Mitigation :** Contrat SLA < 24h notification AVA6 → OneOrtho + escalade phone

---

### Scénario 2 : "Autre client AVA6" compromis → fuite vers OneOrtho VLAN

1. **Jour X** : Autre client AVA6 hacker → son serveurs compromis
2. **Jour X+?** : Attaquant scanne réseau AVA6 → trouve OneOrtho VLAN
3. **Jour X+?** : Firewall mutualisé (Q2) = misconfiguration possible → traversée inter-VLAN
4. **Jour X+?** : Attaquant accès données OneOrtho patients (no chiffrement = readable)
5. **Jour X+** : OneOrtho unaware (fuite croisée client → pas alerte SIEM)

**Impact :**
- ❌ Données patients exposées par erreur AVA6
- ❌ Deux clients sanctionnés CNIL (OneOrtho + autre client)
- ❌ Confiance patient damaged

**Mitigation :** 
- Test isolement inter-VLAN trimestriel
- Chiffrement at-rest so même si compromis = données non-readable

---

### Scénario 3: Audit CNIL => OneOrtho = pas preuve conformité hébergeur AVA6

1. **Jour X** : CNIL audit suite plainte → demande rapport conformité AVA6 chez OneOrtho
2. **Jour X** : OneOrtho cherche AVA6 audit SOC 2, pentest reports, logs destructionn etc
3. **Jour X+?** : AVA6 refuse partage "confidential" OR `n'existe pas` rapports = CNIL find no evidencing
4. **Audit result** : CNIL = OneOrtho non-conforme HDS (hébergeur compliance non démontrée)

**Impact** :
- ❌ OneOrtho labelled "non-conforme HDS" par CNIL
- ❌ Amende possible si violations trouvées
- ❌ Patient trust lost

**Mitigation :**
- Audit rights OneOrtho chez AVA6 contractualisées
- SOC 2 Type II reports partagées annuels

---

### Scénario 4 : Fin contrat — destruction données patients ne pas documentée

1. **Fin contrat** : OneOrtho exporte données, AVA6 "détruit" après 1 mois
2. **3 mois après** : Police enquête sur patient → va demander à AVA6 données archivées
3. **AVA6 response** : "Données toujours sur baie de secours, pas vraiment destroyed" — patient data readable
4. **OneOrtho problem** : Pas de certificat destruction = pas preuve = données résiduel potential

**Impact :**
- ❌ Données patients accessible sans consentement
- ❌ CNIL violation (droit oubli non-respected)
- ❌ CSP L.1111-14 violation

**Mitigation :**
- Procédure destruction signée (wiping 3-pass ou destruction physique)
- Certificat destruction signé par AVA6

---

## 🔗 CARTOGRAPHIE — Données Patients vs Défaillances HDS

```
┌──────────────────────────────────────────────────────────────────┐
│                         DSPROD (ERP Patients)                      │
│  Données: Fiche patient identifiée + protocoles chirurgie          │
├──────────────────────────────────────────────────────────────────┤
│  Propriété:       OneOrtho (responsable de traitement)            │
│  Hébergeur:       AVA6 (sous-traitant = MAIS pas formalisé #1)   │
│  Volumétrie:      2 TB + 1 TB backup                             │
│  Chiffrement:     ❌ NON SPECIFIE (#5, #8)                        │
│  Isolement:       ❌ Non testé (#4, #7)                           │
│  Accès AVA6:      ❌ Non interdiction doc (#2)                    │
│  Détection:       ⚠️  SIEM REDSOC sans SLA (#6)                   │
│  Notification:    ❌ Absence SLA incident (#6, #50)               │
│  Destruction:     ❌ Pas procédure (#8, #54)                      │
│  Audit OneOrtho:  ❌ Pas droit (#10, #56)                         │
└──────────────────────────────────────────────────────────────────┘

         ⬇  RESULTAT: Données patients peu protégées
```

---

## 📋 PLAN D'ACTION — Immédiate

### PHASE 1 : Préparation (< 7 jours)

```
☐ Relayer à CTO OneOrtho : 2 documents complémentaires + cette synthèse
☐ Préparer slide deck : 12 défaillances + 21 questions complémentaires
☐ Legal review interne : confirmer priorités & stratégie négociation AVA6
☐ Constituer équipe réunion : CTO, Legal, IT Security, Comité technique
```

### PHASE 2 : Communication AVA6 (< 14 jours)

```
☐ Email formel à AVA6 (CTO + Legal) : "Clarification nécessaire avant renouvellement"
  - Joindre : ANALYSE_DEFAILLANCES_HDS_COMPLEMENTAIRE.md
  - Joindre : QUESTIONS_COMPLEMENTAIRES_REGLEMENTAIRES_Q41-Q61.md
  - Demander : Réponses écrites dans 14 jours
☐ Proposer : Réunion technique 21 jours pour explorer solutions

☐ Highlight 🔴 CRITICAL issues:
  RQ1: Responsabilité HDS contrat explicite
  Q3: MCO N1 périmètre définition
  Q12: CNIL notification procédure
  Q13: RDP exposé sécurité
  Q25: Contrat HDS signé
  Q26: PRA/PCA formalisé
  Q41: Interdiction accès données patients
  Q44: Tests pénétration annuels
  Q48: Chiffrement données au repos
  Q50: SLA notification incident
  Q54: Destruction données procédure
  Q58: Sous-traitants agréés
```

### PHASE 3 : Réunion technique (< 30 jours)

```
AGENDA simple:

I. Intro (10')
  - OneOrtho: "Nous devons confirmer conformité HDS avant renouvellement"
  - Contrat actuel = 40 questions + 12 défaillances = risque CNIL

II. Bloc-par-bloc (60')
  - Traçabilité données patients (Q1-Q3, Q41-Q42, Q43)
  - Tests sécurité (Q44-Q45)
  - Isolement données (Q46-Q47)
  - Chiffrement (Q48-Q49)
  - Incident & notification (Q50-Q51, Q50, Q53)
  - Destruction fin de contrat (Q54-Q55)
  - Audit & sous-traitants (Q56-Q61)
  - Governante (Q33, Q58-Q59)

III. Prochaines étapes (20')
  - AVA6 commits: Réponses écrites par J+21
  - Contrat amendment draft: J+45
  - Signature renouvellement: J+60

IV. Escalade CRITICAL issues si AVA6 refuse (10')
  - Plan B: Audit HDS tiers chez AVA6 (coût? délai?)
  - Plan C: Migration données vers hébergeur HDS plus compliant
```

### PHASE 4 : Contrat renouvellement (< 60 jours)

```
☐ Draft amended contract terms with AVA6 legal
  - Add HDS explicit responsibility clause (#1)
  - Add SLA notification incident < 24h (#50)
  - Add chiffrement at-rest requirement (#48)
  - Add pentest annual + SOC 2 sharing (#44, #57)
  - Add audit rights OneOrtho (#56)
  - Add sous-traitant approval process (#58)
  - Add destruction procedure certificate (#54)

☐ Legal review OneOrtho: 2-week review cycle with AVA6

☐ Signature & renewal by Jour 60 max
```

---

## 🎯 METRIC DE SUCCES

| Métrique | Cible | Status |
|---|---|---|
| Responsabilité HDS formalisée contractuellement | ✅ Clause explicite article 1 | ❌ Absent |
| SLA notification incident < 24h | ✅ Signé par AVA6 | ❌ Absent |
| Tests pénétration annuels + rapports partagés | ✅ Inclusion contrat | ❌ Non contractualisé |
| Chiffrement données au repos formalisé | ✅ Clause + audit SOC 2 | ❌ Non spécifié |
| Audit rights OneOrtho chez AVA6 | ✅ Droit de visite & audit | ❌ Non reconnu |
| Sous-traitants agréés par OneOrtho | ✅ REDSOC + WatchGuard signed | ❌ Not approved |
| PRA/PCA formalisé + testé | ✅ Document signé, test annuel | ❌ Oral only |
| Destruction données procédure + certificat | ✅ Signed procedure + cert | ❌ No procedure |

---

## 💰 RISQUE FINANCIER

### Estimation amende CNIL si non-conformité HDS

- **Non-conformité identifiée audit** : 10 000 € - 50 000 €
- **Incident patients données + non-notification < 72h** : 50 000 € - 200 000 €
- **Violation RGPD data breach** : jusqu'à 20 million € (4% chiffre affaires global)

**Comparaison :**
- Coût négociation contrat AVA6 (legal heures) : ~5 000 €
- Coût audit HDS tiers chez AVA6 : ~10 000 €
- Coût potentiel amende CNIL : **100 000 € - 500 000 €**

➡️ **Négociation proactive = assurance contre risque CNIL**

---

## 📞 CONTACTS & ESCALADE

### Leadership OneOrtho
- **CTO** : Arbitrer négociation AVA6
- **Legal** : Review contrat modifications
- **Compliance Officer** (if exists) : Validate HDS compliance

### AVA6 Key Contacts
- AVA6 Commercial Manager (existing relationship)
- AVA6 CTO / Technical Leadership (for questions 41-61 technical depths)
- AVA6 Compliance / Legal (for HDS & RGPD clauses)

---

## 📎 DOCUMENTS REFERENCES

1. **questions_point_ombre.md** — 40 questions existantes (comprèhensive, well-documented)
2. **ANALYSE_DEFAILLANCES_HDS_COMPLEMENTAIRE.md** — 12 défaillances majeures + 150+ références légales HDS/RGPD
3. **QUESTIONS_COMPLEMENTAIRES_REGLEMENTAIRES_Q41-Q61.md** — 21 questions complémentaires avec blocs légaux
4. **contrat_hebergement.md** — Contrat original AVA6

### Lois & standards réference
- CSP (Code Santé Publique) L.1111-8, L.1110-4, L.1111-14
- **HDS Cahier des charges v1.0** (esante.gouv.fr/hds)
- RGPD Articles 28, 30, 33, 55
- ISO 27001:2022
- ANSSI Recommandations 2023

---

## ✅ CONCLUSION

Le contrat AVA6 actuel présente **11 défaillances CRITIQUE + 21 IMPORTANTES** en matière de gestion données patients.

**Risque audit CNIL : ÉLEVÉ** si hébérgement not formalisé correctement.

**Action immédiate requise** : < 30 jours réunion avec AVA6 pour clarifier et formaliser les 12 défaillances + 21 questions complémentaires.

**Timeline renouvellement contrat** : < 60 jours avec clauses HDS explicites.

---

**Document préparé par : Copilot Analysis**  
**Date : 15 avril 2026**  
**Next review date : 22 avril 2026 (après réunion interne)**

