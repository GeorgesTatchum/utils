# Procédure de création et de gestion des comptes AWS nominatifs

> **Environnement** : Médical (dispositifs médicaux / SaMD)
> **Normes applicables** : FDA 21 CFR Part 11, SOC 2 Type II, ISO 27001, HDS, IEC 62304, ISO 13485, MDCG 2019-16
> **Version** : 1.1
> **Date** : 2026-03-12
> **Auteur** : *(à compléter)*
> **Approbateur** : *(à compléter)*
> **Classification** : Confidentiel – Usage interne

---

## Table des matières

1. [Objectif et périmètre](#1-objectif-et-périmètre)
2. [Exigences réglementaires](#2-exigences-réglementaires)
3. [Prérequis](#3-prérequis)
4. [Architecture organisationnelle AWS](#4-architecture-organisationnelle-aws)
5. [Procédure de création d'un compte AWS nominatif](#5-procédure-de-création-dun-compte-aws-nominatif)
6. [Configuration de la sécurité du compte](#6-configuration-de-la-sécurité-du-compte)
7. [Gestion des identités (IAM Identity Center)](#7-gestion-des-identités-iam-identity-center)
8. [Politiques IAM et moindre privilège](#8-politiques-iam-et-moindre-privilège)
9. [Journalisation et audit (CloudTrail / Config)](#9-journalisation-et-audit-cloudtrail--config)
10. [Rotation des credentials et gestion des clés](#10-rotation-des-credentials-et-gestion-des-clés)
11. [Revue périodique des accès](#11-revue-périodique-des-accès)
12. [Désactivation et suppression d'un compte](#12-désactivation-et-suppression-dun-compte)
13. [Tests et validation](#13-tests-et-validation)
14. [Annexes](#14-annexes)

---

## 1. Objectif et périmètre

### 1.1 Objectif

Définir la procédure standardisée pour la **création, la configuration et la gestion des comptes AWS nominatifs** dans un environnement médical réglementé. Cette procédure garantit :

- La **traçabilité** de chaque action effectuée par un utilisateur identifié nommément
- La **reproductibilité** des opérations via des commandes CLI documentées
- La **conformité** aux normes FDA 21 CFR Part 11, SOC 2, ISO 27001, HDS, IEC 62304, ISO 13485 et MDCG 2019-16
- Le **principe du moindre privilège** pour chaque accès
- La **qualification des environnements** de développement, test et production (IEC 62304 §5.1, ISO 13485 §6.3)
- La **cybersécurité by design** conforme au règlement EU MDR (MDCG 2019-16)

### 1.2 Périmètre

| Élément | Inclus |
|---|---|
| Création de comptes via AWS Organizations | ✅ |
| Gestion des utilisateurs IAM Identity Center (SSO) | ✅ |
| Configuration MFA obligatoire | ✅ |
| Journalisation CloudTrail / AWS Config | ✅ |
| Revue périodique des accès | ✅ |
| Gestion du cycle de vie complet (création → suppression) | ✅ |
| Qualification des environnements (IQ/OQ) | ✅ |
| Gestion de configuration logicielle (IEC 62304 §8) | ✅ (volet infrastructure) |
| Gestion des risques cybersécurité (MDCG 2019-16) | ✅ (volet infrastructure) |
| Réponse aux incidents de cybersécurité | ✅ |
| Infrastructure applicative (EC2, RDS, etc.) | ❌ (hors périmètre) |

### 1.3 Définitions

| Terme | Définition |
|---|---|
| **Compte nominatif** | Compte AWS ou identité SSO attribuée à une personne physique unique et identifiable |
| **MFA** | Multi-Factor Authentication — authentification à facteurs multiples |
| **SCP** | Service Control Policy — politique de contrôle de service au niveau AWS Organizations |
| **OU** | Organizational Unit — unité organisationnelle dans AWS Organizations |
| **IdP** | Identity Provider — fournisseur d'identité externe (ex : Azure AD, Okta) |
| **SaMD** | Software as a Medical Device — logiciel qualifié comme dispositif médical |
| **SOUP** | Software of Unknown Provenance — composant logiciel tiers (IEC 62304) |
| **QMS** | Quality Management System — système de management de la qualité (ISO 13485) |
| **DMR** | Device Master Record — dossier maître du dispositif médical |
| **DHR** | Device History Record — dossier historique du dispositif |

---

## 2. Exigences réglementaires

### 2.1 FDA 21 CFR Part 11 — Enregistrements électroniques et signatures

| Exigence | Implémentation AWS |
|---|---|
| §11.10(d) — Contrôle d'accès aux systèmes | IAM Identity Center + MFA obligatoire |
| §11.10(e) — Piste d'audit sécurisée | CloudTrail avec intégrité des logs activée |
| §11.10(g) — Vérification d'autorité | Politiques IAM à moindre privilège + SCP |
| §11.100 — Unicité des identifiants | Comptes nominatifs (1 personne = 1 identité unique) |
| §11.300 — Signature électronique | MFA + combinaison identifiant/mot de passe unique |

### 2.2 SOC 2 Type II

| Critère Trust Service | Implémentation |
|---|---|
| **CC6.1** — Contrôle d'accès logique | IAM policies + SCP + conditions IP/MFA |
| **CC6.2** — Authentification | MFA matériel obligatoire pour comptes privilégiés |
| **CC6.3** — Enregistrement et autorisation | Processus d'approbation documenté (ticket + validation manager) |
| **CC7.2** — Surveillance | CloudTrail + CloudWatch Alarms + AWS Config Rules |
| **CC8.1** — Gestion des changements | Versionning IaC (Terraform/CloudFormation) |

### 2.3 ISO 27001 (Annexe A)

| Contrôle | Implémentation |
|---|---|
| **A.5.15** — Contrôle d'accès | Politique d'accès formalisée, matrice RBAC |
| **A.5.17** — Informations d'authentification | Politique de mots de passe + MFA |
| **A.8.2** — Gestion des accès privilégiés | Comptes admin séparés, accès temporaires |
| **A.8.3** — Restriction d'accès | Moindre privilège, conditions IAM |
| **A.8.5** — Authentification sécurisée | SSO + MFA + politique de session |
| **A.8.15** — Journalisation | CloudTrail Organization trail |

### 2.4 HDS (Hébergement de Données de Santé)

| Exigence HDS | Implémentation |
|---|---|
| Traçabilité des accès | CloudTrail avec rétention ≥ 1 an (archivage ≥ 5 ans) |
| Séparation des environnements | Comptes AWS dédiés par environnement (dev/staging/prod) |
| Gestion des habilitations | IAM Identity Center + revue trimestrielle |
| Localisation des données | Restriction régionale via SCP (eu-west-1, eu-west-3) |
| Chiffrement | AWS KMS avec clés gérées par le client (CMK) |

### 2.5 IEC 62304 — Cycle de vie des logiciels de dispositifs médicaux

| Exigence | Implémentation AWS |
|---|---|
| **§5.1.1** — Plan de développement logiciel | Les environnements AWS (comptes dev/staging/prod) sont identifiés dans le plan de développement comme infrastructure de référence |
| **§5.1.9** — Séparation des environnements d'intégration, test et production | Comptes AWS séparés par OU : Development, Staging, Production — isolation par SCP |
| **§5.5.1** — Intégration logicielle dans l'environnement cible | Déploiement vers le compte staging/prod traçé via CloudTrail + pipeline CI/CD |
| **§8.1.1** — Identification des éléments de configuration | Chaque compte AWS, Permission Set, SCP et OU est un item de configuration identifié et versionné |
| **§8.1.2** — Maîtrise des modifications | Toute modification de compte/accès passe par un ticket ITSM approuvé → Change Control |
| **§8.2.1** — Contrôle des changements de configuration | CloudTrail + AWS Config enregistrent tout changement ; les SCP empêchent les modifications non autorisées |
| **§8.3** — Comptabilité de l'état de la configuration | Rapport d'état des comptes/accès via les scripts de revue (§11.2) |
| **§9.1** — Résolution des problèmes logiciels | Problèmes d'accès/sécurité tracés dans l'ITSM, liés au CAPA du QMS |

> **Note IEC 62304** : Les comptes AWS constituent l'**environnement de développement et d'exécution** du SaMD. À ce titre, ils sont des **éléments de configuration** (§8) devant être identifiés dans le Software Configuration Management Plan. Toute modification d'environnement doit suivre le processus de gestion des changements.

### 2.6 ISO 13485 — Système de management de la qualité pour les dispositifs médicaux

| Exigence | Implémentation AWS |
|---|---|
| **§4.1.6** — Validation des logiciels utilisés dans le QMS | La procédure présente est un document qualité contrôlé ; les outils AWS (Organizations, IAM, CloudTrail) sont validés selon leur usage prévu |
| **§4.2.4** — Maîtrise des enregistrements | Logs CloudTrail conservés ≥ vie du dispositif + 5 ans (minimum 15 ans recommandé pour DM implantables) avec Object Lock COMPLIANCE |
| **§4.2.5** — Maîtrise des documents | Ce document est versionné (historique §Annexe D), approuvé par le RSSI et le Responsable Qualité |
| **§6.2** — Compétences et formation | Formation obligatoire avant attribution d'accès AWS (voir §6.2-bis ci-dessous) |
| **§6.3** — Infrastructure | Les comptes AWS sont identifiés comme infrastructure critique ; leur création/modification est contrôlée et qualifiée |
| **§6.4** — Environnement de travail | Séparation stricte dev/staging/prod via comptes AWS dédiés ; conditions d'accès documentées |
| **§7.3.3** — Éléments d'entrée de la conception | L'architecture AWS (comptes, permissions, SCP) est un élément d'entrée du Design Input → documenté dans le DHF |
| **§7.5.6** — Validation des processus de production | L'environnement de production AWS est qualifié (IQ/OQ/PQ) avant mise en service |
| **§8.2.4** — Audit interne | Revue trimestrielle des accès (§11) + audit annuel (§11.1) |
| **§8.5.2** — Action corrective | Les non-conformités d'accès détectées lors des revues déclenchent un CAPA dans le QMS |

> **Note ISO 13485 §4.2.4** : La durée de rétention des enregistrements d'accès (logs CloudTrail, rapports de revue) doit être alignée sur la durée de vie du dispositif médical. Pour les dispositifs implantables, prévoir **15 ans minimum**. Adapter la politique de cycle de vie S3 en conséquence.

### 2.7 MDCG 2019-16 — Cybersécurité des dispositifs médicaux (EU MDR)

| Exigence MDCG 2019-16 | Section | Implémentation AWS |
|---|---|---|
| **Security by design** | §4.1 | Architecture multi-comptes avec SCP restrictives dès la conception ; moindre privilège par défaut |
| **Gestion des risques cybersécurité** | §4.2 | Analyse de risques de l'infrastructure AWS intégrée au dossier de gestion des risques (ISO 14971) — voir §2.7-bis |
| **Contrôle d'accès et authentification** | §4.3 | IAM Identity Center + MFA matériel + politiques à moindre privilège + sessions limitées |
| **Piste d'audit** | §4.4 | CloudTrail organisation avec intégrité des logs, chiffrement KMS, rétention longue durée |
| **Chiffrement** | §4.5 | KMS CMK pour les logs, chiffrement at-rest et in-transit sur tous les services |
| **Détection d'incidents** | §4.6 | CloudWatch Alarms (§9.4), GuardDuty, Security Hub — voir §2.7-ter |
| **Réponse aux incidents** | §4.7 | Procédure de désactivation d'urgence (§12.1, délai 4h), notification aux autorités compétentes |
| **Mises à jour de sécurité** | §4.8 | Rotation des credentials (§10), revue des SCP/permissions (§11), patching des AMI |
| **Surveillance post-marché** | §5 | Revue continue des alertes Security Hub + AWS Health Dashboard + rapports trimestriels |

#### 2.7-bis — Intégration au dossier de gestion des risques (ISO 14971)

Les risques liés à l'infrastructure AWS doivent être identifiés dans le dossier de gestion des risques du dispositif. Exemples :

| ID Risque | Danger | Situation dangereuse | Gravité | Probabilité | Mesure de maîtrise | Vérification |
|---|---|---|---|---|---|---|
| R-AWS-01 | Accès non autorisé au compte de production | Données patient exposées ou altérées | Critique | Faible | MFA + SCP + moindre privilège + IP restriction | Test T02, T05, T06 |
| R-AWS-02 | Suppression de logs d'audit | Perte de traçabilité réglementaire | Majeur | Très faible | SCP ProtectAuditServices + S3 Object Lock COMPLIANCE | Test T03 |
| R-AWS-03 | Compte compromis (credentials volées) | Modification non autorisée du SaMD | Critique | Faible | MFA matériel + rotation 90j + alertes CloudWatch + session 1h admin | Test T05, T09 |
| R-AWS-04 | Déploiement hors région EU | Non-conformité localisation données (RGPD/HDS) | Majeur | Faible | SCP DenyNonEURegions | Test T02 |
| R-AWS-05 | Maintien d'accès après départ | Accès persistant d'un ex-collaborateur | Critique | Moyenne | Procédure de désactivation 4h (§12.1) + revue trimestrielle | Test T10 |

> Ces risques doivent figurer dans le **Risk Management File** (ISO 14971) et être revus lors de chaque revue de gestion des risques.

#### 2.7-ter — Procédure de réponse aux incidents de cybersécurité AWS

```
┌─────────────────────┐
│  1. DÉTECTION        │  GuardDuty / Security Hub / CloudWatch Alarm
│     Délai : immédiat │  → Notification SNS vers security-team@
└──────────┬──────────┘
           ▼
┌─────────────────────┐
│  2. TRIAGE           │  RSSI évalue la gravité (Critique/Majeur/Mineur)
│     Délai : < 1h     │  → Crée un incident dans l'ITSM
└──────────┬──────────┘
           ▼
┌─────────────────────┐
│  3. CONFINEMENT      │  Désactiver le compte/user compromis (§12.1)
│     Délai : < 4h     │  Révoquer les sessions actives
│                      │  Isoler le compte dans OU Suspended si nécessaire
└──────────┬──────────┘
           ▼
┌─────────────────────┐
│  4. INVESTIGATION    │  Analyser CloudTrail pour identifier l'étendue
│     Délai : < 24h    │  Identifier les données/systèmes impactés
│                      │  Conserver les preuves (logs, snapshots)
└──────────┬──────────┘
           ▼
┌─────────────────────┐
│  5. REMÉDIATION      │  Corriger la vulnérabilité identifiée
│     Délai : variable │  Rotation de tous les credentials concernés
│                      │  Renforcer les contrôles (SCP, IAM)
└──────────┬──────────┘
           ▼
┌─────────────────────┐
│  6. NOTIFICATION     │  Si données patient : notifier la CNIL (72h RGPD)
│     Délai régl.      │  Si DM : notifier l'autorité compétente (ANSM/BSI)
│                      │  Rapport au fabricant (MDCG 2019-16 §5)
└──────────┬──────────┘
           ▼
┌─────────────────────┐
│  7. POST-INCIDENT    │  Root Cause Analysis → CAPA (ISO 13485 §8.5.2)
│     Délai : < 30j    │  Mise à jour du dossier de gestion des risques
│                      │  Mise à jour de cette procédure si nécessaire
└─────────────────────┘
```

---

## 3. Prérequis

### 3.1 Prérequis techniques

- [ ] Compte AWS Management (root) de l'organisation configuré
- [ ] AWS Organizations activé en mode "All Features"
- [ ] AWS CLI v2 installé et configuré (`aws --version` ≥ 2.x)
- [ ] Accès administrateur à AWS Organizations
- [ ] Adresse e-mail unique par compte AWS (convention : `aws-<env>-<team>@entreprise.com`)
- [ ] Dispositifs MFA disponibles selon le rôle :
  - **Rôles standards** (Developer, QA, Data Engineer) : application TOTP (Google Authenticator, Microsoft Authenticator, Authy) ou clé matérielle
  - **Rôles privilégiés** (Ops avec accès prod, Security Auditor, Admin) : clé matérielle FIDO2 **obligatoire** (YubiKey ou équivalent)
  - **Comptes root** : clé matérielle FIDO2 **obligatoire** (stockée en coffre-fort physique)

### 3.2 Prérequis organisationnels

- [ ] Politique de sécurité informatique approuvée
- [ ] Matrice des rôles et responsabilités (RACI) définie
- [ ] Processus d'approbation des accès formalisé (ticket ITSM)
- [ ] Convention de nommage validée
- [ ] Responsable sécurité (RSSI) désigné
- [ ] Responsable Qualité (QA/RA) désigné — approbateur pour les aspects ISO 13485
- [ ] Software Configuration Management Plan rédigé et approuvé (IEC 62304 §8)
- [ ] Dossier de gestion des risques incluant les risques cybersécurité AWS (ISO 14971 / MDCG 2019-16)
- [ ] Programme de formation AWS défini (ISO 13485 §6.2) — voir §7.8
- [ ] Procédure de réponse aux incidents de cybersécurité approuvée (MDCG 2019-16 §4.7)

### 3.3 Installation et configuration de l'AWS CLI

```bash
# Vérifier l'installation
aws --version

# Configurer le profil d'administration de l'organisation
aws configure --profile org-admin
# AWS Access Key ID: <VOTRE_ACCESS_KEY>
# AWS Secret Access Key: <VOTRE_SECRET_KEY>
# Default region name: eu-west-3
# Default output format: json

# Vérifier la connexion
aws sts get-caller-identity --profile org-admin
```

**Via la console web** : Se connecter à https://console.aws.amazon.com avec le compte Management → Vérifier en haut à droite que l'utilisateur et la région sont corrects.

---

## 4. Architecture organisationnelle AWS

### 4.1 Structure des Organizational Units (OU)

```
Root
├── Security OU
│   ├── Compte Log Archive (centralisation des logs)
│   └── Compte Security Tooling (GuardDuty, Security Hub)
├── Infrastructure OU
│   └── Compte Shared Services (DNS, réseau partagé)
├── Workloads OU
│   ├── Production OU
│   │   └── Compte Prod-<Application>
│   ├── Staging OU
│   │   └── Compte Staging-<Application>
│   └── Development OU
│       └── Compte Dev-<Application>
├── Sandbox OU
│   └── Compte Sandbox-<Utilisateur>
└── Suspended OU (comptes désactivés)
```

### 4.2 Convention de nommage

| Ressource | Format | Exemple |
|---|---|---|
| Compte AWS | `<entreprise>-<env>-<app>` | `medco-prod-hipplanner` |
| E-mail du compte | `aws-<env>-<app>@entreprise.com` | `aws-prod-hipplanner@medco.com` |
| Utilisateur SSO | `prenom.nom@entreprise.com` | `jean.dupont@medco.com` |
| Rôle IAM | `<Env>-<Fonction>-Role` | `Prod-DataScientist-Role` |
| Permission Set | `PS-<Fonction>-<Niveau>` | `PS-Developer-ReadOnly` |
| SCP | `SCP-<Objectif>` | `SCP-DenyNonEURegions` |

### 4.3 Création de la structure OU (si non existante)

#### Via AWS CLI

```bash
# Récupérer l'ID du root
ROOT_ID=$(aws organizations list-roots --profile org-admin \
  --query 'Roots[0].Id' --output text)

# Créer les OU principales
aws organizations create-organizational-unit \
  --parent-id "$ROOT_ID" \
  --name "Security" \
  --profile org-admin

aws organizations create-organizational-unit \
  --parent-id "$ROOT_ID" \
  --name "Infrastructure" \
  --profile org-admin

aws organizations create-organizational-unit \
  --parent-id "$ROOT_ID" \
  --name "Workloads" \
  --profile org-admin

aws organizations create-organizational-unit \
  --parent-id "$ROOT_ID" \
  --name "Sandbox" \
  --profile org-admin

aws organizations create-organizational-unit \
  --parent-id "$ROOT_ID" \
  --name "Suspended" \
  --profile org-admin

# Créer les sous-OU de Workloads
WORKLOADS_OU_ID=$(aws organizations list-organizational-units-for-parent \
  --parent-id "$ROOT_ID" --profile org-admin \
  --query "OrganizationalUnits[?Name=='Workloads'].Id" --output text)

for ENV in Production Staging Development; do
  aws organizations create-organizational-unit \
    --parent-id "$WORKLOADS_OU_ID" \
    --name "$ENV" \
    --profile org-admin
done

# Vérifier la structure
aws organizations list-organizational-units-for-parent \
  --parent-id "$ROOT_ID" --profile org-admin \
  --query "OrganizationalUnits[].{Name:Name, Id:Id}" \
  --output table
```

#### Via la console web

1. Accéder à **AWS Organizations** → **Organize accounts**
2. Sélectionner **Root** → **Actions** → **Create new organizational unit**
3. Saisir le nom de l'OU (ex : `Security`) → **Create**
4. Répéter pour chaque OU selon la structure ci-dessus

---

## 5. Procédure de création d'un compte AWS nominatif

### 5.1 Workflow d'approbation

```
┌──────────────────┐     ┌──────────────────┐     ┌──────────────────┐
│  1. Demandeur     │────►│  2. Manager      │────►│  3. RSSI         │
│  Crée le ticket   │     │  Valide le besoin│     │  Valide la       │
│  ITSM avec :      │     │  métier          │     │  conformité      │
│  - Justification  │     │                  │     │  sécurité        │
│  - Rôle demandé   │     │                  │     │                  │
│  - Durée          │     │                  │     │                  │
└──────────────────┘     └──────────────────┘     └──────────────────┘
                                                          │
                                                          ▼
┌──────────────────┐     ┌──────────────────┐     ┌──────────────────┐
│  6. Demandeur     │◄────│  5. Ops          │◄────│  4. Ops          │
│  Configure MFA    │     │  Attribue les    │     │  Crée le compte  │
│  et valide accès  │     │  permissions     │     │  / l'identité    │
└──────────────────┘     └──────────────────┘     └──────────────────┘
```

**Informations requises dans le ticket ITSM** :

| Champ | Description | Exemple |
|---|---|---|
| Demandeur | Nom complet | Jean Dupont |
| E-mail professionnel | Adresse nominative | jean.dupont@medco.com |
| Manager | Approbateur hiérarchique | Marie Martin |
| Justification métier | Raison du besoin d'accès | Développement du module HipPlanner |
| Environnement(s) | dev / staging / prod | dev, staging |
| Rôle demandé | Selon la matrice RBAC | Developer |
| Durée | Permanent ou temporaire | 6 mois (renouvellement par revue) |
| Données sensibles | Accès aux données de santé ? | Oui / Non |

### 5.2 Création du compte dans AWS Organizations

#### Via AWS CLI

```bash
# Variables — à adapter selon le ticket
ACCOUNT_NAME="medco-dev-hipplanner"
ACCOUNT_EMAIL="aws-dev-hipplanner@medco.com"
OU_NAME="Development"

# Créer le compte
CREATE_REQUEST=$(aws organizations create-account \
  --account-name "$ACCOUNT_NAME" \
  --email "$ACCOUNT_EMAIL" \
  --iam-user-access-to-billing DENY \
  --profile org-admin \
  --query 'CreateAccountStatus.Id' --output text)

echo "Request ID: $CREATE_REQUEST"

# Suivre la création (attendre le statut SUCCEEDED)
aws organizations describe-create-account-status \
  --create-account-request-id "$CREATE_REQUEST" \
  --profile org-admin

# Récupérer l'ID du nouveau compte
NEW_ACCOUNT_ID=$(aws organizations describe-create-account-status \
  --create-account-request-id "$CREATE_REQUEST" \
  --profile org-admin \
  --query 'CreateAccountStatus.AccountId' --output text)

echo "New Account ID: $NEW_ACCOUNT_ID"

# Déplacer le compte dans la bonne OU
# D'abord, récupérer l'ID de l'OU cible
WORKLOADS_OU_ID=$(aws organizations list-organizational-units-for-parent \
  --parent-id "$ROOT_ID" --profile org-admin \
  --query "OrganizationalUnits[?Name=='Workloads'].Id" --output text)

TARGET_OU_ID=$(aws organizations list-organizational-units-for-parent \
  --parent-id "$WORKLOADS_OU_ID" --profile org-admin \
  --query "OrganizationalUnits[?Name=='$OU_NAME'].Id" --output text)

# L'OU source est Root par défaut après la création
aws organizations move-account \
  --account-id "$NEW_ACCOUNT_ID" \
  --source-parent-id "$ROOT_ID" \
  --destination-parent-id "$TARGET_OU_ID" \
  --profile org-admin

# Vérifier le placement
aws organizations list-accounts-for-parent \
  --parent-id "$TARGET_OU_ID" --profile org-admin \
  --query "Accounts[?Id=='$NEW_ACCOUNT_ID'].{Name:Name, Id:Id, Status:Status}" \
  --output table
```

#### Via la console web

1. Aller sur **AWS Organizations** → **Add an AWS account**
2. Sélectionner **Create an AWS account**
3. Remplir :
   - **AWS account name** : `medco-dev-hipplanner`
   - **Email address** : `aws-dev-hipplanner@medco.com`
   - **IAM role name** : laisser `OrganizationAccountAccessRole` (par défaut)
4. Cliquer **Create AWS account**
5. Attendre la création → rafraîchir la page
6. Sélectionner le compte → **Actions** → **Move** → choisir l'OU cible (ex : `Workloads > Development`)

### 5.3 Tagging obligatoire du compte

```bash
# Appliquer les tags de conformité
aws organizations tag-resource \
  --resource-id "$NEW_ACCOUNT_ID" \
  --tags \
    Key=Environment,Value=development \
    Key=Project,Value=hipplanner \
    Key=Owner,Value=jean.dupont@medco.com \
    Key=CostCenter,Value=CC-R&D-001 \
    Key=DataClassification,Value=HealthData \
    Key=Compliance,Value="FDA,SOC2,ISO27001,HDS" \
    Key=CreatedBy,Value=ops-admin@medco.com \
    Key=CreatedDate,Value=$(date +%Y-%m-%d) \
    Key=TicketRef,Value=ITSM-2026-0042 \
  --profile org-admin
```

**Via la console web** : AWS Organizations → sélectionner le compte → onglet **Tags** → **Manage tags** → ajouter chaque paire clé/valeur.

---

## 6. Configuration de la sécurité du compte

### 6.1 Service Control Policies (SCP)

Les SCP s'appliquent au niveau de l'OU et limitent les permissions maximales des comptes enfants.

#### SCP — Restreindre aux régions EU uniquement

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyNonEURegions",
      "Effect": "Deny",
      "NotAction": [
        "a4b:*",
        "budgets:*",
        "ce:*",
        "chime:*",
        "cloudfront:*",
        "cur:*",
        "globalaccelerator:*",
        "health:*",
        "iam:*",
        "importexport:*",
        "organizations:*",
        "route53:*",
        "sts:*",
        "support:*",
        "trustedadvisor:*",
        "waf:*"
      ],
      "Resource": "*",
      "Condition": {
        "StringNotEquals": {
          "aws:RequestedRegion": [
            "eu-west-1",
            "eu-west-3",
            "eu-central-1"
          ]
        }
      }
    }
  ]
}
```

#### SCP — Exiger le MFA pour actions sensibles

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyStopDeleteWithoutMFA",
      "Effect": "Deny",
      "Action": [
        "ec2:StopInstances",
        "ec2:TerminateInstances",
        "rds:DeleteDBInstance",
        "rds:DeleteDBCluster",
        "s3:DeleteBucket",
        "kms:DisableKey",
        "kms:ScheduleKeyDeletion"
      ],
      "Resource": "*",
      "Condition": {
        "BoolIfExists": {
          "aws:MultiFactorAuthPresent": "false"
        }
      }
    }
  ]
}
```

#### SCP — Empêcher la désactivation de CloudTrail et Config

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ProtectAuditServices",
      "Effect": "Deny",
      "Action": [
        "cloudtrail:StopLogging",
        "cloudtrail:DeleteTrail",
        "cloudtrail:UpdateTrail",
        "config:StopConfigurationRecorder",
        "config:DeleteConfigurationRecorder",
        "config:DeleteDeliveryChannel"
      ],
      "Resource": "*"
    }
  ]
}
```

#### Appliquer les SCP

```bash
# Créer la SCP (exemple pour la restriction régionale)
SCP_ID=$(aws organizations create-policy \
  --name "SCP-DenyNonEURegions" \
  --description "Restreindre l'utilisation aux régions EU pour conformité HDS" \
  --type SERVICE_CONTROL_POLICY \
  --content file://scp-deny-non-eu-regions.json \
  --profile org-admin \
  --query 'Policy.PolicySummary.Id' --output text)

# Attacher la SCP à l'OU Workloads
aws organizations attach-policy \
  --policy-id "$SCP_ID" \
  --target-id "$WORKLOADS_OU_ID" \
  --profile org-admin

# Vérifier les SCP attachées
aws organizations list-policies-for-target \
  --target-id "$WORKLOADS_OU_ID" \
  --filter SERVICE_CONTROL_POLICY \
  --profile org-admin \
  --query "Policies[].{Name:Name, Id:Id}" --output table
```

**Via la console web** : AWS Organizations → **Policies** → **Service control policies** → **Create policy** → coller le JSON → **Create** → sélectionner la policy → **Targets** → **Attach** → choisir l'OU.

### 6.2 Activer AWS Security Hub

```bash
# Se connecter au nouveau compte via le rôle cross-account
aws sts assume-role \
  --role-arn "arn:aws:iam::${NEW_ACCOUNT_ID}:role/OrganizationAccountAccessRole" \
  --role-session-name "SecuritySetup" \
  --profile org-admin

# Activer Security Hub avec les standards de conformité
aws securityhub enable-security-hub \
  --enable-default-standards \
  --profile new-account

# Activer les standards spécifiques
aws securityhub batch-enable-standards \
  --standards-subscription-requests \
    '[{"StandardsArn":"arn:aws:securityhub:::ruleset/cis-aws-foundations-benchmark/v/1.4.0"},
      {"StandardsArn":"arn:aws:securityhub:eu-west-3::standards/aws-foundational-security-best-practices/v/1.0.0"}]' \
  --profile new-account
```

**Via la console web** : Se connecter au compte → **Security Hub** → **Go to Security Hub** → Activer → Cocher les standards CIS et AWS Foundational.

---

## 7. Gestion des identités (IAM Identity Center)

### 7.1 Activation d'IAM Identity Center

> **Recommandation** : Utiliser IAM Identity Center (ex-AWS SSO) comme point d'entrée unique. Ne PAS créer d'utilisateurs IAM locaux.

```bash
# Activer IAM Identity Center (doit être fait dans le compte Management)
aws sso-admin create-instance --profile org-admin

# Récupérer l'ARN de l'instance SSO
SSO_INSTANCE_ARN=$(aws sso-admin list-instances --profile org-admin \
  --query 'Instances[0].InstanceArn' --output text)

IDENTITY_STORE_ID=$(aws sso-admin list-instances --profile org-admin \
  --query 'Instances[0].IdentityStoreId' --output text)

echo "SSO Instance: $SSO_INSTANCE_ARN"
echo "Identity Store: $IDENTITY_STORE_ID"
```

**Via la console web** : Accéder à **IAM Identity Center** → **Enable** → Choisir la région (eu-west-3).

### 7.2 Création d'un utilisateur nominatif

#### Via AWS CLI

```bash
# Variables du ticket ITSM
USER_FIRST_NAME="Jean"
USER_LAST_NAME="Dupont"
USER_EMAIL="jean.dupont@medco.com"
USER_DISPLAY_NAME="Jean Dupont"
USER_NAME="jean.dupont"

# Créer l'utilisateur dans l'Identity Store
USER_ID=$(aws identitystore create-user \
  --identity-store-id "$IDENTITY_STORE_ID" \
  --user-name "$USER_NAME" \
  --name "{\"FamilyName\":\"$USER_LAST_NAME\",\"GivenName\":\"$USER_FIRST_NAME\"}" \
  --display-name "$USER_DISPLAY_NAME" \
  --emails "[{\"Value\":\"$USER_EMAIL\",\"Type\":\"work\",\"Primary\":true}]" \
  --profile org-admin \
  --query 'UserId' --output text)

echo "User created: $USER_ID"
```

#### Via la console web

1. **IAM Identity Center** → **Users** → **Add user**
2. Remplir :
   - **Username** : `jean.dupont`
   - **Email** : `jean.dupont@medco.com`
   - **First name** : `Jean`
   - **Last name** : `Dupont`
   - **Display name** : `Jean Dupont`
3. Cliquer **Next** → (facultatif) ajouter à un groupe → **Add user**
4. L'utilisateur recevra un e-mail d'activation

### 7.3 Création de groupes fonctionnels

```bash
# Définir les groupes selon la matrice RBAC
declare -A GROUPS=(
  ["GRP-Developers"]="Développeurs - accès dev/staging en lecture-écriture"
  ["GRP-DataEngineers"]="Ingénieurs données - accès aux pipelines data"
  ["GRP-QA"]="Équipe qualité - accès staging en lecture"
  ["GRP-Ops"]="Opérations - accès infra tous environnements"
  ["GRP-SecurityAuditors"]="Auditeurs sécurité - lecture seule tous comptes"
  ["GRP-Admins"]="Administrateurs - accès complet (usage exceptionnel)"
)

for GROUP_NAME in "${!GROUPS[@]}"; do
  GROUP_ID=$(aws identitystore create-group \
    --identity-store-id "$IDENTITY_STORE_ID" \
    --display-name "$GROUP_NAME" \
    --description "${GROUPS[$GROUP_NAME]}" \
    --profile org-admin \
    --query 'GroupId' --output text)
  echo "Group created: $GROUP_NAME ($GROUP_ID)"
done
```

**Via la console web** : IAM Identity Center → **Groups** → **Create group** → remplir le nom et la description → **Create group**.

### 7.4 Ajout d'un utilisateur à un groupe

```bash
# Récupérer l'ID du groupe
GROUP_ID=$(aws identitystore list-groups \
  --identity-store-id "$IDENTITY_STORE_ID" \
  --filters "[{\"AttributePath\":\"DisplayName\",\"AttributeValue\":\"GRP-Developers\"}]" \
  --profile org-admin \
  --query 'Groups[0].GroupId' --output text)

# Ajouter l'utilisateur au groupe
aws identitystore create-group-membership \
  --identity-store-id "$IDENTITY_STORE_ID" \
  --group-id "$GROUP_ID" \
  --member-id "{\"UserId\":\"$USER_ID\"}" \
  --profile org-admin
```

**Via la console web** : IAM Identity Center → **Groups** → sélectionner le groupe → **Add users** → rechercher l'utilisateur → **Add**.

### 7.5 Création des Permission Sets

Les Permission Sets définissent les droits accordés lors de l'accès à un compte.

```bash
# Permission Set : Developer (accès limité aux services de développement)
PS_DEVELOPER_ARN=$(aws sso-admin create-permission-set \
  --instance-arn "$SSO_INSTANCE_ARN" \
  --name "PS-Developer" \
  --description "Accès développeur - services de dev uniquement" \
  --session-duration "PT8H" \
  --profile org-admin \
  --query 'PermissionSet.PermissionSetArn' --output text)

# Attacher une politique gérée AWS
aws sso-admin attach-managed-policy-to-permission-set \
  --instance-arn "$SSO_INSTANCE_ARN" \
  --permission-set-arn "$PS_DEVELOPER_ARN" \
  --managed-policy-arn "arn:aws:iam::aws:policy/PowerUserAccess" \
  --profile org-admin

# Ajouter une politique inline restrictive
cat > ps-developer-inline.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyCriticalActions",
      "Effect": "Deny",
      "Action": [
        "organizations:*",
        "account:*",
        "iam:CreateUser",
        "iam:DeleteUser",
        "iam:CreateRole",
        "iam:DeleteRole",
        "cloudtrail:StopLogging",
        "cloudtrail:DeleteTrail",
        "config:StopConfigurationRecorder"
      ],
      "Resource": "*"
    },
    {
      "Sid": "RequireMFA",
      "Effect": "Deny",
      "NotAction": [
        "iam:CreateVirtualMFADevice",
        "iam:EnableMFADevice",
        "iam:GetUser",
        "iam:ListMFADevices",
        "sts:GetSessionToken"
      ],
      "Resource": "*",
      "Condition": {
        "BoolIfExists": {
          "aws:MultiFactorAuthPresent": "false"
        }
      }
    }
  ]
}
EOF

aws sso-admin put-inline-policy-to-permission-set \
  --instance-arn "$SSO_INSTANCE_ARN" \
  --permission-set-arn "$PS_DEVELOPER_ARN" \
  --inline-policy file://ps-developer-inline.json \
  --profile org-admin

# Permission Set : ReadOnly pour les auditeurs
PS_READONLY_ARN=$(aws sso-admin create-permission-set \
  --instance-arn "$SSO_INSTANCE_ARN" \
  --name "PS-SecurityAuditor" \
  --description "Accès lecture seule pour audit de sécurité" \
  --session-duration "PT4H" \
  --profile org-admin \
  --query 'PermissionSet.PermissionSetArn' --output text)

aws sso-admin attach-managed-policy-to-permission-set \
  --instance-arn "$SSO_INSTANCE_ARN" \
  --permission-set-arn "$PS_READONLY_ARN" \
  --managed-policy-arn "arn:aws:iam::aws:policy/SecurityAudit" \
  --profile org-admin

aws sso-admin attach-managed-policy-to-permission-set \
  --instance-arn "$SSO_INSTANCE_ARN" \
  --permission-set-arn "$PS_READONLY_ARN" \
  --managed-policy-arn "arn:aws:iam::aws:policy/ReadOnlyAccess" \
  --profile org-admin

# Permission Set : Admin (usage exceptionnel, session courte)
PS_ADMIN_ARN=$(aws sso-admin create-permission-set \
  --instance-arn "$SSO_INSTANCE_ARN" \
  --name "PS-Admin-Emergency" \
  --description "Accès admin - usage exceptionnel uniquement" \
  --session-duration "PT1H" \
  --profile org-admin \
  --query 'PermissionSet.PermissionSetArn' --output text)

aws sso-admin attach-managed-policy-to-permission-set \
  --instance-arn "$SSO_INSTANCE_ARN" \
  --permission-set-arn "$PS_ADMIN_ARN" \
  --managed-policy-arn "arn:aws:iam::aws:policy/AdministratorAccess" \
  --profile org-admin
```

**Via la console web** : IAM Identity Center → **Permission sets** → **Create permission set** → suivre l'assistant.

### 7.6 Attribution des accès (Account Assignment)

```bash
# Attribuer le groupe GRP-Developers au compte dev avec le Permission Set Developer
aws sso-admin create-account-assignment \
  --instance-arn "$SSO_INSTANCE_ARN" \
  --target-id "$NEW_ACCOUNT_ID" \
  --target-type AWS_ACCOUNT \
  --permission-set-arn "$PS_DEVELOPER_ARN" \
  --principal-type GROUP \
  --principal-id "$GROUP_ID" \
  --profile org-admin

# Vérifier l'attribution
aws sso-admin list-account-assignments \
  --instance-arn "$SSO_INSTANCE_ARN" \
  --account-id "$NEW_ACCOUNT_ID" \
  --permission-set-arn "$PS_DEVELOPER_ARN" \
  --profile org-admin
```

**Via la console web** : IAM Identity Center → **AWS accounts** → cocher le compte cible → **Assign users or groups** → choisir le groupe → choisir le Permission Set → **Submit**.

### 7.7 Qualification des environnements AWS (IEC 62304 / ISO 13485)

> **Exigence** : Chaque environnement AWS utilisé pour le développement, le test ou l'exécution d'un SaMD doit être **qualifié** conformément à ISO 13485 §7.5.6 et IEC 62304 §5.1.1.

#### Processus IQ/OQ (Installation Qualification / Operational Qualification)

| Phase | Objectif | Evidence |
|---|---|---|
| **IQ (Installation Qualification)** | Vérifier que le compte AWS est créé et configuré conformément à la spécification | Checklist Annexe A complétée + capture d'écran |
| **OQ (Operational Qualification)** | Vérifier que les contrôles fonctionnent comme prévu | Résultats des tests T01–T13 (§13) tous PASS |

#### Script de qualification IQ

```bash
#!/bin/bash
# iq-aws-account.sh
# Installation Qualification d'un compte AWS
# Document qualité : à archiver dans le DHF

ACCOUNT_ID="$1"
REPORT_DATE=$(date +%Y-%m-%d)
REPORT_FILE="IQ-AWS-${ACCOUNT_ID}-${REPORT_DATE}.txt"

echo "=============================================" > "$REPORT_FILE"
echo "  INSTALLATION QUALIFICATION (IQ)" >> "$REPORT_FILE"
echo "  Compte AWS : $ACCOUNT_ID" >> "$REPORT_FILE"
echo "  Date : $REPORT_DATE" >> "$REPORT_FILE"
echo "  Opérateur : $(aws sts get-caller-identity --query 'Arn' --output text)" >> "$REPORT_FILE"
echo "=============================================" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# IQ-01 : Vérifier que le compte existe et est ACTIVE
STATUS=$(aws organizations describe-account --account-id "$ACCOUNT_ID" \
  --profile org-admin --query 'Account.Status' --output text)
echo "IQ-01 Statut du compte : $STATUS" >> "$REPORT_FILE"

# IQ-02 : Vérifier l'OU
OU_NAME=$(aws organizations list-parents --child-id "$ACCOUNT_ID" \
  --profile org-admin --query 'Parents[0].Id' --output text)
echo "IQ-02 OU parent : $OU_NAME" >> "$REPORT_FILE"

# IQ-03 : Vérifier les tags de conformité
TAGS=$(aws organizations list-tags-for-resource --resource-id "$ACCOUNT_ID" \
  --profile org-admin --output json)
echo "IQ-03 Tags : $TAGS" >> "$REPORT_FILE"

# IQ-04 : Vérifier les SCP appliquées
SCPS=$(aws organizations list-policies-for-target --target-id "$OU_NAME" \
  --filter SERVICE_CONTROL_POLICY --profile org-admin \
  --query 'Policies[].Name' --output json)
echo "IQ-04 SCP appliquées : $SCPS" >> "$REPORT_FILE"

# IQ-05 : Vérifier CloudTrail
CT=$(aws cloudtrail get-trail-status --name "medco-organization-trail" \
  --profile org-admin --query 'IsLogging' --output text)
echo "IQ-05 CloudTrail actif : $CT" >> "$REPORT_FILE"

echo "" >> "$REPORT_FILE"
echo "Signature de l'opérateur : ___________________" >> "$REPORT_FILE"
echo "Signature Qualité (QA)  : ___________________" >> "$REPORT_FILE"

echo "IQ généré : $REPORT_FILE"
```

#### Enregistrement dans la gestion de configuration (IEC 62304 §8)

Chaque compte AWS qualifié doit être enregistré comme **item de configuration** :

| Champ | Valeur |
|---|---|
| ID Configuration Item | CI-AWS-\<account-id\> |
| Type | Infrastructure — Compte AWS |
| Version | v1.0 (selon révision des SCP/permissions) |
| Propriétaire | Ops Lead |
| Date de qualification | Date IQ/OQ |
| Statut | Qualifié / Non qualifié / Suspendu |
| Lien DHF | Référence au Design History File |

### 7.8 Formation obligatoire (ISO 13485 §6.2)

> **Exigence ISO 13485 §6.2** : Le personnel effectuant un travail affectant la qualité du produit doit être compétent sur la base de la formation initiale et professionnelle, du savoir-faire et de l'expérience.

#### Matrice de formation requise

| Rôle | Formations obligatoires | Fréquence | Validation |
|---|---|---|---|
| Tous les utilisateurs AWS | Sécurité AWS de base + MFA + politique d'accès | À l'onboarding + annuelle | QCM (score ≥ 80%) |
| Developer | AWS Well-Architected Security Pillar + IEC 62304 awareness | À l'onboarding + annuelle | QCM + exercice pratique |
| Ops / DevOps | IAM avanced + Organizations + CloudTrail + cette procédure | À l'onboarding + annuelle | QCM + exécution supervisée |
| Security Auditor | AWS Security Specialty + ISO 27001 Lead Auditor | À l'onboarding | Certification |
| Admin | Toutes les formations ci-dessus | À l'onboarding + semestrielle | QCM + certification |

#### Processus de formation

1. **Avant attribution d'accès** : l'utilisateur doit avoir complété la formation requise pour son rôle
2. **Enregistrement** : le certificat de formation est archivé dans le Training Record (QMS)
3. **Vérification** : l'opérateur Ops vérifie le Training Record avant de créer l'identité SSO
4. **Recyclage** : les formations doivent être renouvelées selon la fréquence définie

#### Champ supplémentaire dans le ticket ITSM

| Champ | Description | Exemple |
|---|---|---|
| Formation validée | Référence du Training Record | TR-2026-0142 |
| Date de validation | Date de complétion de la formation | 2026-03-01 |
| Score obtenu | Résultat du QCM | 92% |

> **Blocage** : Aucun accès AWS ne sera attribué sans preuve de formation validée. Ce point est vérifié lors de la revue trimestrielle (§11).

---

## 8. Politiques IAM et moindre privilège

### 8.1 Matrice RBAC (Role-Based Access Control)

| Rôle | Permission Set | Comptes autorisés | Session max | MFA requis | Type MFA |
|---|---|---|---|---|---|
| Developer | PS-Developer | Dev, Staging | 8h | Oui | TOTP ou matériel |
| Data Engineer | PS-DataEngineer | Dev, Staging | 8h | Oui | TOTP ou matériel |
| QA | PS-QA-ReadOnly | Staging | 4h | Oui | TOTP ou matériel |
| Ops | PS-Ops | Dev, Staging, Prod | 8h | Oui | **Matériel FIDO2** |
| Security Auditor | PS-SecurityAuditor | Tous | 4h | Oui | **Matériel FIDO2** |
| Admin | PS-Admin-Emergency | Tous | 1h | Oui | **Matériel FIDO2** |

> **Justification** : L'approche est **proportionnée au risque** (ISO 27001 A.8.5, MDCG 2019-16 §4.3). Les rôles sans accès production ni données patient peuvent utiliser une application TOTP (Google Authenticator, Microsoft Authenticator, Authy). Les rôles avec accès production ou tous comptes exigent une clé matérielle FIDO2, résistante au phishing.

### 8.2 Politique de mot de passe IAM (sur chaque compte)

```bash
# Appliquer la politique de mot de passe (se connecter au compte cible d'abord)
aws iam update-account-password-policy \
  --minimum-password-length 14 \
  --require-symbols \
  --require-numbers \
  --require-uppercase-characters \
  --require-lowercase-characters \
  --max-password-age 90 \
  --password-reuse-prevention 24 \
  --hard-expiry \
  --profile new-account
```

**Via la console web** : IAM → **Account settings** → **Password policy** → **Edit** → configurer selon les valeurs ci-dessus.

### 8.3 Conditions IAM avancées

Exemple de politique exigeant MFA + IP source + tag utilisateur :

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowWithConditions",
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject"
      ],
      "Resource": "arn:aws:s3:::medco-health-data-*/*",
      "Condition": {
        "Bool": {
          "aws:MultiFactorAuthPresent": "true"
        },
        "IpAddress": {
          "aws:SourceIp": [
            "203.0.113.0/24",
            "198.51.100.0/24"
          ]
        },
        "StringEquals": {
          "aws:PrincipalTag/Department": "Engineering"
        }
      }
    }
  ]
}
```

---

## 9. Journalisation et audit (CloudTrail / Config)

### 9.1 CloudTrail Organisation Trail

> **Exigence HDS/FDA** : Tous les appels API doivent être journalisés, avec intégrité vérifiable et rétention ≥ 1 an (archivage ≥ 5 ans).

```bash
# Créer un trail organisationnel (depuis le compte Management)
# Prérequis : bucket S3 dans le compte Log Archive avec la bonne bucket policy

LOG_ARCHIVE_ACCOUNT_ID="111111111111"  # Adapter
TRAIL_BUCKET="medco-org-cloudtrail-logs"

aws cloudtrail create-trail \
  --name "medco-organization-trail" \
  --s3-bucket-name "$TRAIL_BUCKET" \
  --is-organization-trail \
  --is-multi-region-trail \
  --enable-log-file-validation \
  --kms-key-id "arn:aws:kms:eu-west-3:${LOG_ARCHIVE_ACCOUNT_ID}:key/mrk-xxxx" \
  --include-global-service-events \
  --profile org-admin

# Activer le trail
aws cloudtrail start-logging \
  --name "medco-organization-trail" \
  --profile org-admin

# Vérifier le statut
aws cloudtrail get-trail-status \
  --name "medco-organization-trail" \
  --profile org-admin
```

**Via la console web** : CloudTrail → **Trails** → **Create trail** → cocher **Enable for all accounts in my organization** → configurer le bucket S3, le chiffrement KMS et la validation de l'intégrité.

### 9.2 Politique de rétention S3 pour les logs

```bash
# Politique de cycle de vie du bucket de logs
cat > lifecycle-policy.json << 'EOF'
{
  "Rules": [
    {
      "ID": "CloudTrailRetention",
      "Status": "Enabled",
      "Filter": { "Prefix": "AWSLogs/" },
      "Transitions": [
        {
          "Days": 90,
          "StorageClass": "STANDARD_IA"
        },
        {
          "Days": 365,
          "StorageClass": "GLACIER"
        }
      ],
      "Expiration": {
        "Days": 2555
      }
    }
  ]
}
EOF

aws s3api put-bucket-lifecycle-configuration \
  --bucket "$TRAIL_BUCKET" \
  --lifecycle-configuration file://lifecycle-policy.json \
  --profile log-archive

# Activer le verrouillage d'objet (Object Lock) pour empêcher la suppression
# Note : doit être activé à la création du bucket
aws s3api put-object-lock-configuration \
  --bucket "$TRAIL_BUCKET" \
  --object-lock-configuration '{
    "ObjectLockEnabled": "Enabled",
    "Rule": {
      "DefaultRetention": {
        "Mode": "COMPLIANCE",
        "Years": 7
      }
    }
  }' \
  --profile log-archive
```

### 9.3 AWS Config Rules

```bash
# Activer AWS Config sur le nouveau compte
aws configservice put-configuration-recorder \
  --configuration-recorder name=default,roleARN=arn:aws:iam::${NEW_ACCOUNT_ID}:role/aws-service-role/config.amazonaws.com/AWSServiceRoleForConfig \
  --recording-group allSupported=true,includeGlobalResourceTypes=true \
  --profile new-account

# Règles de conformité obligatoires
CONFIG_RULES=(
  "iam-user-mfa-enabled"
  "root-account-mfa-enabled"
  "iam-root-access-key-check"
  "iam-user-no-policies-check"
  "iam-password-policy"
  "cloud-trail-enabled"
  "cloud-trail-log-file-validation-enabled"
  "cloud-trail-encryption-enabled"
  "s3-bucket-server-side-encryption-enabled"
  "s3-bucket-public-read-prohibited"
  "s3-bucket-public-write-prohibited"
  "encrypted-volumes"
  "rds-storage-encrypted"
  "restricted-ssh"
  "access-keys-rotated"
  "mfa-enabled-for-iam-console-access"
)

for RULE in "${CONFIG_RULES[@]}"; do
  aws configservice put-config-rule \
    --config-rule "{
      \"ConfigRuleName\": \"$RULE\",
      \"Source\": {
        \"Owner\": \"AWS\",
        \"SourceIdentifier\": \"$(echo $RULE | tr '[:lower:]-' '[:upper:]_')\"
      }
    }" \
    --profile new-account
  echo "Config Rule enabled: $RULE"
done
```

**Via la console web** : AWS Config → **Get started** / **Rules** → **Add rule** → rechercher et activer chaque règle listée.

### 9.4 Alarmes CloudWatch pour événements critiques

```bash
# Créer un topic SNS pour les alertes de sécurité
SNS_TOPIC_ARN=$(aws sns create-topic \
  --name "medco-security-alerts" \
  --profile new-account \
  --query 'TopicArn' --output text)

# Abonner l'équipe sécurité
aws sns subscribe \
  --topic-arn "$SNS_TOPIC_ARN" \
  --protocol email \
  --notification-endpoint security-team@medco.com \
  --profile new-account

# Alarme : connexion root
aws cloudwatch put-metric-alarm \
  --alarm-name "RootAccountUsage" \
  --alarm-description "Alerte : utilisation du compte root détectée" \
  --metric-name "RootAccountUsageCount" \
  --namespace "CloudTrailMetrics" \
  --comparison-operator GreaterThanOrEqualToThreshold \
  --threshold 1 \
  --evaluation-periods 1 \
  --period 300 \
  --statistic Sum \
  --treat-missing-data notBreaching \
  --alarm-actions "$SNS_TOPIC_ARN" \
  --profile new-account

# Alarme : changements IAM non autorisés
aws cloudwatch put-metric-alarm \
  --alarm-name "UnauthorizedIAMChanges" \
  --alarm-description "Alerte : modifications IAM détectées" \
  --metric-name "IAMPolicyChangesCount" \
  --namespace "CloudTrailMetrics" \
  --comparison-operator GreaterThanOrEqualToThreshold \
  --threshold 1 \
  --evaluation-periods 1 \
  --period 300 \
  --statistic Sum \
  --treat-missing-data notBreaching \
  --alarm-actions "$SNS_TOPIC_ARN" \
  --profile new-account
```

**Via la console web** : CloudWatch → **Alarms** → **Create alarm** → sélectionner la métrique → configurer le seuil et l'action SNS.

---

## 10. Rotation des credentials et gestion des clés

### 10.1 Politique de rotation

| Credential | Durée maximale | Rotation | Responsable |
|---|---|---|---|
| Mot de passe utilisateur | 90 jours | Automatique (politique IAM) | Utilisateur |
| Access Keys | 90 jours | Manuelle (script automatisé) | Ops |
| Mot de passe root | N/A — désactivé | N/A | RSSI |
| Clés KMS (CMK) | 365 jours | Automatique (AWS KMS) | Ops |
| Certificats TLS | 365 jours | Automatique (ACM) | Ops |

### 10.2 Script de détection des clés expirées

```bash
#!/bin/bash
# detect-stale-access-keys.sh
# Détecte les access keys de plus de 90 jours

MAX_AGE_DAYS=90
TODAY=$(date +%s)

echo "=== Rapport des Access Keys anciennes (> ${MAX_AGE_DAYS} jours) ==="
echo "Date du rapport : $(date +%Y-%m-%d)"
echo ""

aws iam generate-credential-report --profile new-account > /dev/null 2>&1
sleep 5

aws iam get-credential-report --profile new-account \
  --query 'Content' --output text | base64 -d | \
while IFS=',' read -r user arn creation pw_enabled pw_last_used pw_last_changed \
  pw_next_rotation mfa ak1_active ak1_last_rotated ak1_last_used \
  ak1_last_used_region ak1_last_used_service ak2_active ak2_last_rotated rest; do

  if [[ "$ak1_active" == "true" && "$ak1_last_rotated" != "N/A" && "$ak1_last_rotated" != "access_key_1_last_rotated" ]]; then
    KEY_DATE=$(date -d "$ak1_last_rotated" +%s 2>/dev/null)
    if [ -n "$KEY_DATE" ]; then
      AGE=$(( (TODAY - KEY_DATE) / 86400 ))
      if [ "$AGE" -gt "$MAX_AGE_DAYS" ]; then
        echo "⚠ ALERTE: $user - Access Key 1 a $AGE jours (max: $MAX_AGE_DAYS)"
      fi
    fi
  fi
done

echo ""
echo "=== Fin du rapport ==="
```

### 10.3 Rotation automatique KMS

```bash
# Activer la rotation automatique des clés KMS
aws kms enable-key-rotation \
  --key-id "arn:aws:kms:eu-west-3:${NEW_ACCOUNT_ID}:key/mrk-xxxx" \
  --profile new-account

# Vérifier
aws kms get-key-rotation-status \
  --key-id "arn:aws:kms:eu-west-3:${NEW_ACCOUNT_ID}:key/mrk-xxxx" \
  --profile new-account
```

---

## 11. Revue périodique des accès

### 11.1 Fréquence des revues

| Type de revue | Fréquence | Responsable | Livrable |
|---|---|---|---|
| Revue des accès utilisateurs | Trimestrielle | Manager + RSSI | Rapport signé |
| Revue des Permission Sets | Semestrielle | Ops + RSSI | Matrice mise à jour |
| Revue des SCP | Annuelle | RSSI + Direction | SCP actualisées |
| Revue des comptes dormants | Mensuelle | Ops | Liste des comptes à désactiver |
| Audit externe | Annuelle | Auditeur certifié | Rapport d'audit |

### 11.2 Script de revue des accès

```bash
#!/bin/bash
# access-review.sh
# Génère un rapport de revue des accès IAM Identity Center
# À exécuter trimestriellement

REPORT_DATE=$(date +%Y-%m-%d)
REPORT_FILE="access-review-${REPORT_DATE}.csv"

echo "Compte,Utilisateur/Groupe,Type,PermissionSet,DateAttribution" > "$REPORT_FILE"

# Lister tous les comptes de l'organisation
ACCOUNTS=$(aws organizations list-accounts --profile org-admin \
  --query "Accounts[?Status=='ACTIVE'].Id" --output text)

# Lister tous les Permission Sets
PERMISSION_SETS=$(aws sso-admin list-permission-sets \
  --instance-arn "$SSO_INSTANCE_ARN" --profile org-admin \
  --query 'PermissionSets[]' --output text)

for ACCOUNT_ID in $ACCOUNTS; do
  ACCOUNT_NAME=$(aws organizations describe-account \
    --account-id "$ACCOUNT_ID" --profile org-admin \
    --query 'Account.Name' --output text)

  for PS_ARN in $PERMISSION_SETS; do
    PS_NAME=$(aws sso-admin describe-permission-set \
      --instance-arn "$SSO_INSTANCE_ARN" \
      --permission-set-arn "$PS_ARN" --profile org-admin \
      --query 'PermissionSet.Name' --output text)

    ASSIGNMENTS=$(aws sso-admin list-account-assignments \
      --instance-arn "$SSO_INSTANCE_ARN" \
      --account-id "$ACCOUNT_ID" \
      --permission-set-arn "$PS_ARN" --profile org-admin \
      --query 'AccountAssignments[]' --output json)

    echo "$ASSIGNMENTS" | jq -r ".[] | \"$ACCOUNT_NAME ($ACCOUNT_ID),\(.PrincipalId),\(.PrincipalType),$PS_NAME,N/A\"" >> "$REPORT_FILE"
  done
done

echo "Rapport généré : $REPORT_FILE"
echo "Nombre d'attributions : $(tail -n +2 "$REPORT_FILE" | wc -l)"
```

### 11.3 Détection des utilisateurs inactifs

```bash
#!/bin/bash
# detect-inactive-users.sh
# Détecte les utilisateurs n'ayant pas accédé aux comptes depuis 90 jours

INACTIVITY_THRESHOLD=90

echo "=== Utilisateurs inactifs (> ${INACTIVITY_THRESHOLD} jours) ==="

# Vérifier la dernière authentification via CloudTrail
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=EventName,AttributeValue=AssumeRoleWithSAML \
  --start-time "$(date -d "-${INACTIVITY_THRESHOLD} days" +%Y-%m-%dT%H:%M:%S)" \
  --profile org-admin \
  --query 'Events[].{User:Username, Time:EventTime}' \
  --output table
```

### 11.4 Checklist de revue trimestrielle

- [ ] Exporter le rapport des attributions (`access-review.sh`)
- [ ] Vérifier que chaque utilisateur a toujours un besoin métier justifié
- [ ] Identifier les comptes dormants (pas de connexion > 90 jours)
- [ ] Vérifier que les Permission Sets respectent le moindre privilège
- [ ] Confirmer que le MFA est actif pour tous les utilisateurs
- [ ] Vérifier la rotation des access keys
- [ ] Documenter les actions correctives dans le ticket ITSM
- [ ] Faire signer le rapport par le Manager et le RSSI
- [ ] Archiver le rapport signé (rétention ≥ 5 ans)

---

## 12. Désactivation et suppression d'un compte

### 12.1 Procédure de départ d'un collaborateur

> **Délai** : La désactivation doit être effectuée dans les **4 heures** suivant la notification du départ (immédiat en cas de licenciement).

#### Étape 1 — Désactiver l'utilisateur SSO

```bash
# Récupérer l'ID de l'utilisateur
USER_ID=$(aws identitystore list-users \
  --identity-store-id "$IDENTITY_STORE_ID" \
  --filters "[{\"AttributePath\":\"UserName\",\"AttributeValue\":\"jean.dupont\"}]" \
  --profile org-admin \
  --query 'Users[0].UserId' --output text)

# Désactiver l'utilisateur (ne supprime pas, conserve la traçabilité)
aws identitystore update-user \
  --identity-store-id "$IDENTITY_STORE_ID" \
  --user-id "$USER_ID" \
  --operations '[{"AttributePath":"active","AttributeValue":"false"}]' \
  --profile org-admin
```

**Via la console web** : IAM Identity Center → **Users** → sélectionner l'utilisateur → **Disable user**.

#### Étape 2 — Révoquer toutes les sessions actives

```bash
# Supprimer les attributions de comptes
ASSIGNMENTS=$(aws sso-admin list-account-assignments-for-principal \
  --instance-arn "$SSO_INSTANCE_ARN" \
  --principal-id "$USER_ID" \
  --principal-type USER \
  --profile org-admin \
  --query 'AccountAssignments[]' --output json)

echo "$ASSIGNMENTS" | jq -c '.[]' | while read -r ASSIGNMENT; do
  ACCT=$(echo "$ASSIGNMENT" | jq -r '.AccountId')
  PS=$(echo "$ASSIGNMENT" | jq -r '.PermissionSetArn')

  aws sso-admin delete-account-assignment \
    --instance-arn "$SSO_INSTANCE_ARN" \
    --target-id "$ACCT" \
    --target-type AWS_ACCOUNT \
    --permission-set-arn "$PS" \
    --principal-type USER \
    --principal-id "$USER_ID" \
    --profile org-admin

  echo "Revoked: Account $ACCT, PermissionSet $PS"
done
```

**Via la console web** : Pour chaque compte → **AWS accounts** → sélectionner → **Remove user assignment**.

#### Étape 3 — Supprimer les access keys éventuelles

```bash
# Sur chaque compte où l'utilisateur avait des access keys IAM
# (normalement non applicable si SSO est utilisé exclusivement)
aws iam list-access-keys --user-name "jean.dupont" --profile target-account | \
  jq -r '.AccessKeyMetadata[].AccessKeyId' | while read KEY_ID; do
    aws iam update-access-key \
      --user-name "jean.dupont" \
      --access-key-id "$KEY_ID" \
      --status Inactive \
      --profile target-account
    echo "Désactivé: $KEY_ID"
  done
```

#### Étape 4 — Documentation

```bash
# Logger l'action de désactivation
echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) | DEACTIVATION | User: jean.dupont | Reason: Départ | Operator: ops-admin | Ticket: ITSM-2026-0099" >> /var/log/aws-account-management.log
```

### 12.2 Suspension d'un compte AWS

```bash
# Déplacer le compte dans l'OU Suspended (les SCP restrictives s'appliquent)
SUSPENDED_OU_ID=$(aws organizations list-organizational-units-for-parent \
  --parent-id "$ROOT_ID" --profile org-admin \
  --query "OrganizationalUnits[?Name=='Suspended'].Id" --output text)

CURRENT_OU_ID=$(aws organizations list-parents \
  --child-id "$NEW_ACCOUNT_ID" --profile org-admin \
  --query 'Parents[0].Id' --output text)

aws organizations move-account \
  --account-id "$NEW_ACCOUNT_ID" \
  --source-parent-id "$CURRENT_OU_ID" \
  --destination-parent-id "$SUSPENDED_OU_ID" \
  --profile org-admin
```

#### SCP de l'OU Suspended — Bloquer toute action

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyAllActions",
      "Effect": "Deny",
      "Action": "*",
      "Resource": "*",
      "Condition": {
        "StringNotLike": {
          "aws:PrincipalArn": [
            "arn:aws:iam::*:role/OrganizationAccountAccessRole"
          ]
        }
      }
    }
  ]
}
```

### 12.3 Fermeture définitive (après période de rétention)

```bash
# ATTENTION : irréversible après 90 jours de grâce
# Vérifier qu'aucune donnée n'a besoin d'être conservée

# Fermer le compte
aws organizations close-account \
  --account-id "$NEW_ACCOUNT_ID" \
  --profile org-admin
```

**Via la console web** : AWS Organizations → sélectionner le compte → **Actions** → **Close** → confirmer.

---

## 13. Tests et validation

### 13.1 Plan de tests

| # | Test | Action | Résultat attendu | Statut |
|---|---|---|---|---|
| T01 | Création de compte | Exécuter la procédure §5 | Compte créé dans la bonne OU avec tags | ☐ |
| T02 | SCP régionale | Tenter de lancer EC2 dans us-east-1 | Accès refusé | ☐ |
| T03 | SCP protection audit | Tenter `cloudtrail:StopLogging` | Accès refusé | ☐ |
| T04 | Création utilisateur SSO | Créer un utilisateur via §7.2 | Utilisateur reçoit l'email d'activation | ☐ |
| T05 | MFA obligatoire | Se connecter sans MFA | Accès refusé ou prompt MFA | ☐ |
| T06 | Permission Set Developer | Se connecter en tant que dev | Accès PowerUser, pas de modification IAM | ☐ |
| T07 | Permission Set ReadOnly | Se connecter en tant qu'auditeur | Lecture seule confirmée | ☐ |
| T08 | CloudTrail logging | Effectuer une action API | Événement visible dans CloudTrail ≤ 15 min | ☐ |
| T09 | Alerte root login | Se connecter avec le compte root | Notification SNS reçue | ☐ |
| T10 | Désactivation utilisateur | Exécuter la procédure §12.1 | Utilisateur ne peut plus se connecter | ☐ |
| T11 | Rotation access key | Exécuter le script §10.2 | Clé > 90 jours détectée et signalée | ☐ |
| T12 | Revue des accès | Exécuter `access-review.sh` | Rapport CSV complet généré | ☐ |
| T13 | Suspension de compte | Déplacer dans OU Suspended | Toute action bloquée (sauf OrganizationRole) | ☐ |
| T14 | Qualification IQ | Exécuter `iq-aws-account.sh` | Rapport IQ complet généré avec tous les contrôles PASS | ☐ |
| T15 | Formation pré-accès | Demander un accès sans Training Record | Rejeté par l'opérateur (ISO 13485 §6.2) | ☐ |
| T16 | Réponse incident | Simuler une alerte GuardDuty | Procédure de confinement exécutée en < 4h (MDCG 2019-16) | ☐ |
| T17 | Gestion de configuration | Modifier une SCP sans ticket ITSM | Changement identifié et signalé en non-conformité (IEC 62304 §8) | ☐ |

### 13.2 Scripts de test automatisés

```bash
#!/bin/bash
# test-scp-region-restriction.sh
# Test T02 : Vérifier que la SCP bloque les régions hors EU

echo "=== Test T02 : Restriction régionale SCP ==="
echo "Attempting to run EC2 instance in us-east-1..."

RESULT=$(aws ec2 run-instances \
  --image-id ami-0c55b159cbfafe1f0 \
  --instance-type t3.micro \
  --count 1 \
  --region us-east-1 \
  --profile test-developer 2>&1)

if echo "$RESULT" | grep -q "AccessDenied\|UnauthorizedOperation"; then
  echo "✅ PASS — Déploiement en us-east-1 correctement bloqué"
else
  echo "❌ FAIL — Déploiement en us-east-1 NON bloqué"
  echo "Détail: $RESULT"
fi

echo ""
echo "Attempting to run EC2 instance in eu-west-3..."

RESULT2=$(aws ec2 run-instances \
  --image-id ami-0c55b159cbfafe1f0 \
  --instance-type t3.micro \
  --count 1 \
  --region eu-west-3 \
  --dry-run \
  --profile test-developer 2>&1)

if echo "$RESULT2" | grep -q "DryRunOperation"; then
  echo "✅ PASS — Déploiement en eu-west-3 autorisé (dry-run)"
else
  echo "❌ FAIL — Déploiement en eu-west-3 bloqué alors qu'il ne devrait pas"
  echo "Détail: $RESULT2"
fi
```

```bash
#!/bin/bash
# test-cloudtrail-protection.sh
# Test T03 : Vérifier que la SCP protège CloudTrail

echo "=== Test T03 : Protection CloudTrail ==="
echo "Attempting to stop CloudTrail logging..."

RESULT=$(aws cloudtrail stop-logging \
  --name "medco-organization-trail" \
  --profile test-developer 2>&1)

if echo "$RESULT" | grep -q "AccessDenied\|UnauthorizedOperation"; then
  echo "✅ PASS — Arrêt de CloudTrail correctement bloqué"
else
  echo "❌ FAIL — Arrêt de CloudTrail NON bloqué !"
  echo "CRITIQUE : Relancer immédiatement le logging"
  echo "Détail: $RESULT"
fi
```

```bash
#!/bin/bash
# test-mfa-enforcement.sh
# Test T05 : Vérifier que le MFA est requis

echo "=== Test T05 : Vérification MFA ==="

# Vérifier que tous les utilisateurs IAM ont le MFA activé
USERS_WITHOUT_MFA=$(aws iam generate-credential-report --profile new-account > /dev/null 2>&1; \
  sleep 5; \
  aws iam get-credential-report --profile new-account \
    --query 'Content' --output text | base64 -d | \
  awk -F',' 'NR>1 && $4=="true" && $8=="false" {print $1}')

if [ -z "$USERS_WITHOUT_MFA" ]; then
  echo "✅ PASS — Tous les utilisateurs avec accès console ont le MFA activé"
else
  echo "❌ FAIL — Utilisateurs sans MFA détectés :"
  echo "$USERS_WITHOUT_MFA"
fi
```

### 13.3 Validation de conformité

```bash
#!/bin/bash
# compliance-check.sh
# Vérifie les points de conformité critiques

echo "============================================="
echo "  RAPPORT DE CONFORMITÉ — $(date +%Y-%m-%d)"
echo "============================================="
echo ""

PASS=0
FAIL=0

check() {
  if [ "$1" -eq 0 ]; then
    echo "✅ PASS : $2"
    PASS=$((PASS + 1))
  else
    echo "❌ FAIL : $2"
    FAIL=$((FAIL + 1))
  fi
}

# FDA §11.10(e) — CloudTrail actif avec validation d'intégrité
CT_STATUS=$(aws cloudtrail get-trail-status \
  --name "medco-organization-trail" \
  --profile org-admin \
  --query 'IsLogging' --output text 2>/dev/null)
[ "$CT_STATUS" == "true" ]; check $? "FDA §11.10(e) — CloudTrail organisation actif"

CT_VALIDATION=$(aws cloudtrail describe-trails \
  --trail-name-list "medco-organization-trail" \
  --profile org-admin \
  --query 'trailList[0].LogFileValidationEnabled' --output text 2>/dev/null)
[ "$CT_VALIDATION" == "true" ]; check $? "FDA §11.10(e) — Validation d'intégrité des logs activée"

# SOC2 CC6.1 — SCP attachées aux OU
SCP_COUNT=$(aws organizations list-policies-for-target \
  --target-id "$WORKLOADS_OU_ID" \
  --filter SERVICE_CONTROL_POLICY \
  --profile org-admin \
  --query 'length(Policies)' --output text 2>/dev/null)
[ "$SCP_COUNT" -gt 1 ]; check $? "SOC2 CC6.1 — SCP attachées à l'OU Workloads ($SCP_COUNT SCP)"

# ISO 27001 A.8.5 — MFA activé sur le compte root
ROOT_MFA=$(aws iam get-account-summary --profile new-account \
  --query 'SummaryMap.AccountMFAEnabled' --output text 2>/dev/null)
[ "$ROOT_MFA" == "1" ]; check $? "ISO 27001 A.8.5 — MFA activé sur le compte root"

# HDS — Chiffrement CloudTrail (KMS)
CT_KMS=$(aws cloudtrail describe-trails \
  --trail-name-list "medco-organization-trail" \
  --profile org-admin \
  --query 'trailList[0].KmsKeyId' --output text 2>/dev/null)
[ -n "$CT_KMS" ] && [ "$CT_KMS" != "None" ]; check $? "HDS — CloudTrail chiffré avec KMS"

# AWS Config actif
CONFIG_STATUS=$(aws configservice describe-configuration-recorder-status \
  --profile new-account \
  --query 'ConfigurationRecordersStatus[0].recording' --output text 2>/dev/null)
[ "$CONFIG_STATUS" == "true" ]; check $? "ISO 27001 A.8.15 — AWS Config recorder actif"

# Politique de mot de passe
PW_MIN=$(aws iam get-account-password-policy --profile new-account \
  --query 'PasswordPolicy.MinimumPasswordLength' --output text 2>/dev/null)
[ "$PW_MIN" -ge 14 ]; check $? "ISO 27001 A.5.17 — Longueur minimale mot de passe ≥ 14 ($PW_MIN)"

echo ""
echo "============================================="
echo "  RÉSULTAT : $PASS PASS / $FAIL FAIL"
echo "============================================="

if [ "$FAIL" -gt 0 ]; then
  echo "⚠ Des points de non-conformité ont été détectés."
  echo "  Action requise : corriger les FAIL et relancer le test."
  exit 1
else
  echo "✅ Tous les contrôles de conformité sont validés."
  exit 0
fi
```

---

## 14. Annexes

### Annexe A — Checklist de création de compte

```
CHECKLIST — CRÉATION DE COMPTE AWS NOMINATIF
=============================================
Date : ____/____/________
Opérateur : ___________________
Ticket ITSM : ___________________

PRÉ-REQUIS :
[ ] Ticket ITSM approuvé par le Manager
[ ] Ticket ITSM validé par le RSSI
[ ] Adresse e-mail unique disponible
[ ] Clé MFA matérielle disponible

CRÉATION :
[ ] Compte AWS créé dans Organizations
[ ] Compte déplacé dans la bonne OU
[ ] Tags de conformité appliqués
[ ] CloudTrail vérifié (logs reçus)
[ ] AWS Config activé

IDENTITÉ :
[ ] Utilisateur créé dans IAM Identity Center
[ ] Utilisateur ajouté au(x) groupe(s) approprié(s)
[ ] Permission Set attribué via group assignment
[ ] MFA configuré et vérifié

VALIDATION :
[ ] Tests d'accès effectués (peut accéder aux ressources autorisées)
[ ] Tests de restriction effectués (ne peut pas accéder aux ressources interdites)
[ ] Rapport de conformité exécuté (compliance-check.sh)

FORMATION (ISO 13485 §6.2) :
[ ] Training Record vérifié (formation complétée et validée)
[ ] Référence Training Record : ___________________

DOCUMENTATION :
[ ] Ticket ITSM mis à jour avec les détails de configuration
[ ] Enregistrement dans le registre des accès
[ ] Utilisateur informé de la politique de sécurité
[ ] Item de configuration enregistré (IEC 62304 §8)

QUALIFICATION (IEC 62304 / ISO 13485) :
[ ] IQ exécuté et archivé (iq-aws-account.sh)
[ ] OQ exécuté et archivé (tests T01–T17)

Signature de l'opérateur : ___________________
Signature du RSSI : ___________________
Signature Qualité (QA/RA) : ___________________
```

### Annexe B — Matrice RACI

| Activité | Demandeur | Manager | RSSI | Ops | Qualité (QA/RA) | Direction |
|---|---|---|---|---|---|---|
| Demande d'accès | **R** | **A** | C | I | I | - |
| Validation sécurité | I | I | **R/A** | I | C | - |
| Vérification formation (ISO 13485) | I | C | I | **R** | **A** | - |
| Création du compte | - | - | I | **R/A** | I | - |
| Qualification IQ/OQ (IEC 62304) | - | - | C | **R** | **A** | - |
| Configuration MFA | **R** | - | I | **A** | - | - |
| Revue trimestrielle | I | **R** | **A** | C | C | I |
| Gestion de configuration (IEC 62304) | - | - | C | **R** | **A** | - |
| Réponse incident (MDCG 2019-16) | - | I | **R/A** | **R** | C | I |
| Désactivation (départ) | - | **R** | **A** | **R** | I | I |
| Audit annuel | I | C | **R** | C | **R** | **A** |

> **R** = Responsable, **A** = Approbateur, **C** = Consulté, **I** = Informé

### Annexe C — Contacts

| Rôle | Nom | E-mail | Téléphone |
|---|---|---|---|
| RSSI | *(à compléter)* | | |
| Ops Lead | *(à compléter)* | | |
| Responsable Qualité (QA/RA) | *(à compléter)* | | |
| DPO | *(à compléter)* | | |
| Responsable Formation | *(à compléter)* | | |
| AWS TAM | *(à compléter)* | | |

### Annexe D — Historique des révisions

| Version | Date | Auteur | Description |
|---|---|---|---|
| 1.0 | 2026-03-12 | *(à compléter)* | Version initiale (FDA, SOC2, ISO 27001, HDS) |
| 1.1 | 2026-03-12 | *(à compléter)* | Ajout IEC 62304, ISO 13485, MDCG 2019-16 : qualification environnements, formation, gestion de configuration, réponse incidents, intégration gestion des risques |

---

> **Rappel** : Ce document doit être revu et mis à jour au minimum **annuellement** ou à chaque changement significatif de l'infrastructure, des politiques de sécurité ou des exigences réglementaires. Toute modification doit être approuvée par le RSSI **et le Responsable Qualité** (ISO 13485 §4.2.5) et tracée dans l'historique des révisions. Ce document fait partie du **QMS** et du **Software Configuration Management Plan** (IEC 62304 §8).