# ⚠️ Rolling Updates en Contexte Médical - Analyse Critique

## La Question Fondamentale

> "Est-ce vraiment une bonne idée d'avoir des rolling updates si on ne peut pas forcer le réplica utilisé et le réplica de support?"

**Réponse honnête: NON. Pas dans un contexte médical avec les exigences réglementaires actuelles.**

---

## Comprendre les Risques Réels

### 1. Le Problème avec Rolling Updates Standard

```
Contexte: PHP v1.0 → PHP v1.1 (mise à jour de code ou dépendances)
Stratégie actuelles: Parallelism: 1 (un réplica à la fois)

Timeline Réelle:
T0:00 | État: PHP.1 (v1.0) ✓ | PHP.2 (v1.0) ✓ | PHP.3 (v1.0) ✓
      | 3 requêtes actives en cours
      
T0:01 | DÉBUT arrêt PHP.1 (grace_period: 30s)
      | Requête R1: EN COURS sur PHP.1
      | Requête R2: EN COURS sur PHP.1
      | Traefik/Nginx: "PHP.1 est down, route vers PHP.2/3"

T0:15 | PHP.1 toujours en arrêt gracieux (timeout: 30s, 15s restant)
      | Requête R1: TOUJOURS EN COURS sur PHP.1!!!
      | Requête R2: TOUJOURS EN COURS sur PHP.1!!!
      | Le container ne peut pas être kilé tant que les requêtes ne finissent pas
      
T0:28 | Requête R1: FINIT (elle a pris 28 secondes)
      | Requête R2: FINIT (elle a pris 27 secondes)
      | Grace period: 2 secondes restantes
      | Container PHP.1 peut être arrêté

T0:30 | PHP.1 image v1.1 téléchargée et lancée
      | État: PHP.1 (v1.1) ⚠️ NOUVEAU | PHP.2 (v1.0) ✓ ANCIEN | PHP.3 (v1.0) ✓ ANCIEN
      | PROBLÈME: Code en exécution utilise v1.1, mais basé de données reste v1.0
      
T0:45 | PHP.2 image v1.1 téléchargée et lancée
      | État: PHP.1 (v1.1) ⚠️ NOUVEAU | PHP.2 (v1.1) ⚠️ NOUVEAU | PHP.3 (v1.0) ✓ ANCIEN
      
T1:00 | PHP.3 image v1.1 téléchargée et lancée
      | État: PHP.1 (v1.1) ✓ | PHP.2 (v1.1) ✓ | PHP.3 (v1.1) ✓
      | Mise à jour terminée
```

### 2. Risques Spécifiques en Domaine Médical

#### Risque 1: Version Mismatch en Transaction Multi-Étapes

```
Cas clinique: Prescription de médicament

Étape 1: [T0:05] Requête démarre sur PHP.1 (v1.0)
  - Vérifier si patient est allergique au médicament
  - Query: SELECT * FROM allergies WHERE patient_id = 4521
  - Résultat: Pas d'allergie connue ✓

Étape 2: [T0:10] Même requête continue sur PHP.1 (toujours v1.0, OK)
  - Vérifier interactions médicamenteuses
  - Query: SELECT * FROM drug_interactions WHERE ...
  - Résultat: OK ✓

Étape 3: [T0:15] PENDANT CE TEMPS: Grace period timeout
  - PHP.1 forcément arrêté, requête pas finie
  - REQUEST TRANSFÉRÉE À PHP.2 (désormais v1.1)
  
Étape 4: [T0:16] Requête continue sur PHP.2 (v1.1)
  - Code v1.1 utilisé (peut-être nouvelles règles, nouveau format JSON, etc)
  - La suite de la transaction utilise une version DIFFÉRENTE
  - Risque: Logique métier incohérente

Étape 5: [T0:18] ÉCRIRE la prescription
  - INSERT INTO prescriptions (...)
  - Mais les données validées avec v1.0, code d'écriture en v1.1
  - RÉSULTAT: Potentiellement données corrompues ou incohérentes
```

#### Risque 2: Database Schema Mismatch

```
Mise à jour contient une migration DB:

v1.0 → v1.1:
  - Ajouter colonne: prescriptions.dosage_unit
  - ALTER TABLE prescriptions ADD COLUMN dosage_unit VARCHAR(50)
  
Problème avec rolling update:

T0:05 | Migration n'a pas encore roulé
      | Colonne dosage_unit n'existe PAS dans DB
      | PHP.1 (v1.0): Code ne cherche pas dosage_unit ✓
      
T0:10 | PHP.1 arrêt en cours
      | Migration COMMENCE à cause de readiness probe
      | Erreur: ALTER TABLE prend 2 minutes (table prescriptions = 50M rows)
      | Table LOCK pendant 2 minutes ⚠️
      
T0:12 | Requête actives encore en cours sur PHP.1:
      | INSERT prescription ÉCHOUE (table locked)
      | Requête transférée à PHP.2 (v1.0 aussi, migration pas finie)
      | INSERT prescription ÉCHOUE (dosage_unit n'existe pas)
      | Erreur: "Unknown column 'dosage_unit'"
      
T0:30 | Migration terminée
      | Mais PHP.1 et PHP.2 en état inconsistant
      | Certaines transactions ont échoué
      | Certaines données partiellement écrites
```

#### Risque 3: Requête "Orpheline" Pendant Basculement

```
Cas: Lecture longue (rapport clinique, export données, etc)

[T0:00] Requête démarre sur PHP.1 (v1.0)
  - SELECT 50,000 lignes d'un rapport (curseur)
  - Copier patients, dossiers, examens, résultats, etc
  - "SELECT * FROM patient_full_report WHERE ..." (longue requête)
  - Temps estimé: 45 secondes
  
[T0:30] Grace period PHP.1 = timeout
  - Connection fermée de force
  - Rapport partiellement téléchargé (10,000 lignes seulement)
  - Client reçoit fichier incomplet
  - Médecin pense qu'il a accès aux données complètes du patient
  - RÉSULTAT: Mauvaise décision médicale basée sur données partielles ⚠️⚠️⚠️
```

#### Risque 4: Audit Trail Incohérent

```
Request ID: req-2024-0408-1430-abc123

PHP.1 (v1.0) logs:
  [15:30:23.456] [req-abc123] [php.1] [PRESCRIPTION_CHECK] Allergie check passed

PHP.2 (v1.1) logs:
  [15:30:45.890] [req-abc123] [php.2] [PRESCRIPTION_CREATE] Prescription created

DB audit_logs:
  [TIMESTAMP: 15:30:23] [CONTAINER: php.1] [ACTION: ALLERGY_CHECK]
  [TIMESTAMP: 15:30:46] [CONTAINER: php.2] [ACTION: PRESCRIPTION_CREATE]

Problème: Code qui a créé la prescription (v1.1) est DIFFÉRENT de celui qui a validé (v1.0)
Audit trail montre deux conteneurs différents mais MÊME REQUEST_ID
Question d'audit: "Pourquoi deux conteneurs différents pour la même requête?"
Réponse: "Parce qu'on a mis à jour pendant qu'elle était en cours"
→ Ça invalide la chaîne de conformité
```

---

## Vrais Exigences Médicales pour Déploiement Sûr

### En Domaine Médical, on Doit Garantir:

```
✅ 1. Immuabilité des opérations
   - Une requête utilise UNE SEULE VERSION du code
   - Pas de changement de version pendant l'exécution

✅ 2. Atomicité des transactions
   - Une transaction = même réplica, même version
   - Pas de basculement au milieu d'une opération

✅ 3. Schéma de base de données stable
   - Migrations DB complétées AVANT nouveau code en production
   - Or: Rolling updates = code et DB décalés dans le temps

✅ 4. Audit trail cohérent
   - Une requête = un conteneur, une version
   - Pas de "saut" entre conteneurs

✅ 5. Traceabilité du code exécuté
   - Le médecin/auditeur doit savoir EXACTEMENT quel code a traité la requête
   - Pas de versioning hybrid

✅ 6. Zéro risque de données partielles
   - Les longues opérations doivent FINIR ou ÉCHOUER complètement
   - Pas de "moitié de rapport généré"

✅ 7. Continuité de service sans risque
   - Service continue, mais sans compromis de sécurité
```

### La Réalité des Rolling Updates:

```
Rolling Update Simple = ❌ Ne satisfait AUCUNE de ces exigences en contexte médical

Raisons:
- Requêtes tournent plus longtemps que grace period
- Version code ≠ version schéma DB au même moment
- Requêtes basculées d'un conteneur à l'autre
- Pas de garantie sur "quel code a exécuté"
- Transactions can be partial/incomplete
```

---

## La Bonne Approche pour Contexte Médical

### Option 1: Blue-Green Deployment (RECOMMANDÉE)

```
PRE-DÉPLOIEMENT:

Blue Environment (Production):
  - PHP.1 (v1.0) ✓
  - PHP.2 (v1.0) ✓
  - PHP.3 (v1.0) ✓
  - MariaDB v11.4 ✓
  - Traffic: 100% → Blue

Green Environment (Staging):
  - PHP.1 (v1.1) - NOUVELLE VERSION
  - PHP.2 (v1.1)
  - PHP.3 (v1.1)
  - MariaDB v11.4 (SCHEMA v1.1 compatible)
  - Traffic: 0%

ÉTAPE 1: Migrations DB (AVANT traefik switch)
  - Exécuter migrations sur Blue environment
  - Attendre 100% succès
  - Vérifier schéma OK
  - Valider avec médecins (tests cliniques)

ÉTAPE 2: Basculer 10% du Traffic
  - Traefik route 10% vers Green
  - Monitorer:
    * Erreurs PHP
    * SQL query latency
    * Prescriptions creation time
    * Edge cases
  - Attendre 30 minutes (observation)
  - Si aucune erreur: continuer

ÉTAPE 3: Basculer 50%
  - Route 50% vers Green
  - Monitorer 30 minutes
  - Logs: OK?
  - DB queries: OK?
  - Audit trail: OK?

ÉTAPE 4: Basculer 100%
  - Tout le traffic vers Green
  - Blue devient la "fallback"
  - Garder Blue actif 24h (pour quick rollback)

ROLLBACK SI ERREUR:
  - T0:30 | Erreur détectée en Green
  - T0:31 | Traefik route 100% → Blue (immédiat)
  - T0:32 | Zero downtime, zéro perte données
  - T0:33 | Investigation sur Green

AVANTAGES:
✓ Zéro downtime
✓ Zéro requête "hybrid" (v1.0 ↔ v1.1)
✓ db schema stable pendant migration
✓ Requêtes complètes (pas de basculement)
✓ Audit trail cohérent
✓ Rollback en 1 minute
```

### Option 2: Canary Deployment (Alternative)

```
Comme Blue-Green mais:
- Garder tous les réplicas v1.0
- Ajouter 1 réplica v1.1
- Route 5% traffic vers ce réplica
- Monitorer 1h
- Si OK: ajouter 2e réplica v1.1
- Route 10% traffic
- Répéter jusqu'à 100%

AVANTAGES:
✓ Graduel et contrôlé
✓ Peut revenir en arrière facilement
✓ Moins de ressources (pas 2 envs complets)

INCONVÉNIENTS:
⚠️ Plus long (2-3h)
⚠️ Requêtes "hybrid" possible pendant la transition
⚠️ Deux versions en prod simultanément
```

### Option 3: Scheduled Maintenance Window (Acceptée en Médical)

```
Quand: Chaque dimanche, 02:00-04:00 UTC
- Période la plus calme (data statistique)
- Vérifier: pas de requête en cours
- Drain connections: 5 minutes
- Arrêter TOUS les réplicas
- Attendre EOF de toutes les requêtes
- Mettre à jour la DB (schéma)
- Lancer tous les réplicas v1.1
- Vérifier santé: 100%
- Réouvrir au traffic
- Downtime réel: 30-45 min (acceptable médically)

AVANTAGES:
✓ Zéro version mismatch
✓ Zéro requête hybrid
✓ Schéma DB cohérent
✓ Audit trail pure
✓ Prédictible et documentable

INCONVÉNIENTS:
❌ Downtime (mais prévisible)
❌ Pas zero-downtime
```

---

## Matrice de Décision par Type de Mise à Jour

```
╔═════════════════════════════════════════════════════════════════════════════╗
║ TYPE DE MISE À JOUR          │ STRATÉGIE           │ RECOMMANDATION MÉDICAL  ║
╠═════════════════════════════════════════════════════════════════════════════╣
║ Bugfix mineure (hotpatch)    │ Blue-Green          │ ✅ RECOMMANDÉ           ║
║ Exemple: typo, regex bug     │ 10min total         │ Zero-downtime + sûr     ║
╠═════════════════════════════════════════════════════════════════════════════╣
║ Changement UX (frontend)     │ Blue-Green          │ ✅ RECOMMANDÉ           ║
║ Exemple: form layout         │ 20min total         │ Zero-downtime + sûr     ║
╠═════════════════════════════════════════════════════════════════════════════╣
║ Nouvelle feature (backend)   │ Blue-Green          │ ✅ RECOMMANDÉ           ║
║ Exemple: nouveau endpoint    │ 30min total         │ Migration DB sûre       ║
╠═════════════════════════════════════════════════════════════════════════════╣
║ Grosse refacto code          │ Canary + Testing    │ ⚠️ Considérer           ║
║ Exemple: réécrire logique    │ 2-3h + validation   │ Tests = critiques        ║
╠═════════════════════════════════════════════════════════════════════════════╣
║ Changement schéma DB         │ Scheduled Maintenance│ ⚠️ DÉCONSEILLÉ en live   ║
║ Exemple: refactor tables     │ Downtime 1-2h       │ Ou Blue-Green très care ║
╠═════════════════════════════════════════════════════════════════════════════╣
║ Update de dépendances critiq.│ Scheduled Maintenance│ ⚠️ À planifier           ║
║ Exemple: update openSSL      │ Coordonné           │ Coordination IT/Médical ║
╠═════════════════════════════════════════════════════════════════════════════╣
║ Patch de sécurité urgent     │ Blue-Green ASAP     │ ✅ PRIORITÉ ABSOLUE      ║
║ Exemple: CVE-critical        │ 15min total         │ Sécurité > disponibilité║
╚═════════════════════════════════════════════════════════════════════════════╝
```

---

## Pour Votre Contexte Actuel

### Si vous continuez Rolling Updates:

⚠️ **Risques acceptés (documenter)::**
```
1. Requête peut utiliser deux versions de code
2. Transaction peut être partielle
3. Audit trail peut montrer deux conteneurs
4. DB schema et code peuvent être désalignés
5. Grace period timeout peut couper requête
```

**Mitigations obligatoires:**
```
✓ Grace period TRÈS LONG (60s minimum, mieux: 120s)
✓ Idempotent operations (retry-safe)
✓ Request timeout > grace period
✓ No long-running operations (refactor ou async)
✓ Version-aware logging (logger la version utilisée)
✓ Transaction rollback on error
✓ Comprehensive testing AVANT déploiement
```

### Passage à Blue-Green (TRÈS RECOMMANDÉ):

```
Effort: 1-2 jours de travail
Complexité: Moyenne
Bénéfices:

  🏥 Médical:
    • Zéro version mismatch
    • Zéro transaction hybrid
    • Schéma DB stable
    • Audit trail pur
    • Conformité RGPD/RCPD améliorée

  👨‍💼 Opérationnel:
    • Rollback ultra rapide (1 minute)
    • Moins de stress en production
    • Logs plus clairs
    • Debugging plus facile

  📊 DevOps:
    • Pattern standard industrie
    • Scaling + facile
    • Monitoring + facile
    • Documentable facilement
```

---

## Recommandation Finale

### Pour Domaine Médical STRICTEMENT:

**❌ Ne pas continuer Rolling Updates simples**

**✅ Migrer vers Blue-Green au plus tôt**

Raisons:
1. **Conformité RGPD/RCPD/HIPAA**: Rolling updates ne garantissent pas les exigences
2. **Liability Médical**: Si un problème survient pendant déploiement, c'est documenté
3. **Audit Externe**: Consultants diront "rolling updates = risqué"
4. **Patient Safety**: Zéro risque > zéro downtime in healthcare

### Timeline Proposé:

```
Semaine 1: Valider Blue-Green architecture (1 jour)
Semaine 1: Implémenter Blue-Green infrastructure (2 jours)
Semaine 1: Tester rollback scénarios (1 jour)
Semaine 2: Deployer en preprod en Blue-Green (1 jour)
Semaine 2: Valider en preprod (2 jours)
Semaine 3: Deployer en prod Blue-Green (1 jour)
Semaine 3: Arrêter rolling updates (1 jour)

Total: ~2 semaines de travail

Résultat: 
✅ Zero-downtime SÛRS pour domaine médical
✅ Conforme RGPD
✅ Auditables et documentés
✅ Rollback en cas d'erreur
```

---

## Conclusion

La question que vous vous posez est **THE question** que les équipes médicales devraient toujours se poser mais qu'elles ignorent souvent.

**Votre intuition est correcte**: Rolling updates sans contrôle du réplica = risqué en médical.

**Solution**: Blue-Green deployments = standard pour healthcare.

Voulez-vous que je crée un plan concret pour passer de rolling updates à Blue-Green?
