# Justification de la structure des Organizational Units (OU) AWS

> **Document associé** : [account_management.md](account_management.md) — §4.1
> **Environnement** : Médical (dispositifs médicaux / SaMD)
> **Normes applicables** : FDA 21 CFR Part 11, SOC 2 Type II, ISO 27001, HDS, IEC 62304, ISO 13485, MDCG 2019-16
> **Version** : 1.0
> **Date** : 2026-03-12

---

## Structure retenue

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

---

## 1. Security OU (Log Archive + Security Tooling)

### Principe

Isoler les outils de sécurité et les logs dans des comptes que **personne en dehors de l'équipe sécurité ne peut modifier**.

### Justification réglementaire

| Norme | Exigence | Justification |
|---|---|---|
| **FDA 21 CFR Part 11 §11.10(e)** | La piste d'audit doit être protégée contre toute modification | Si les logs sont dans le même compte que l'application, un admin de ce compte peut les supprimer. En les isolant dans un compte dédié (Log Archive), même un admin de production ne peut pas y toucher. |
| **IEC 62304 §8.2.1** | Contrôle des changements de configuration — les preuves ne doivent pas être altérables | Les logs de changement doivent être stockés dans un compte séparé de celui où les changements sont effectués. |
| **SOC 2 CC7.2** | L'infrastructure de surveillance doit être indépendante de l'infrastructure surveillée | Le compte Security Tooling (GuardDuty, Security Hub) est séparé des comptes applicatifs. |
| **HDS** | Traçabilité inaltérable des accès aux données de santé | Les logs CloudTrail dans Log Archive sont protégés par S3 Object Lock COMPLIANCE. |
| **ISO 27001 A.8.15** | Journalisation sécurisée | L'isolation par compte empêche toute altération des journaux par les équipes opérationnelles. |
| **MDCG 2019-16 §4.4** | Piste d'audit sécurisée | Les logs d'audit ne peuvent pas être modifiés par les utilisateurs audités. |

### Pourquoi 2 comptes et pas 1 ?

Séparation des responsabilités :

- **Log Archive** = stockage pur, lecture seule, aucune exécution de code → surface d'attaque minimale
- **Security Tooling** = exécute les outils actifs (GuardDuty, Security Hub, détection d'intrusion) → peut être compromis théoriquement

Un compromis du compte Security Tooling **ne donne pas accès aux logs archivés**. Cette séparation répond au principe de défense en profondeur (ISO 27001).

---

## 2. Infrastructure OU (Shared Services)

### Principe

Centraliser les services transverses (DNS Route53, Transit Gateway, réseau partagé) dans un compte neutre, accessible par tous les environnements.

### Justification réglementaire

| Norme | Exigence | Justification |
|---|---|---|
| **ISO 27001 A.8.22** | Ségrégation des réseaux | Un compte réseau centralisé permet de contrôler le routage et la segmentation entre environnements depuis un seul point. |
| **ISO 13485 §6.3** | L'infrastructure doit être identifiée et maîtrisée | Centraliser les services partagés permet un point unique de contrôle, de documentation et de qualification. |
| **IEC 62304 §8.1.1** | Identification des éléments de configuration | L'infrastructure réseau partagée est identifiée comme un item de configuration unique et centralisé. |

### Bénéfices opérationnels

- Évite la duplication de configuration réseau dans chaque compte applicatif
- Réduit les erreurs de configuration et les coûts
- Point unique pour les règles de firewall et de routage inter-comptes

---

## 3. Workloads OU (Production / Staging / Development)

### Principe

C'est le choix **le plus important** pour un environnement médical. Chaque environnement est un **compte AWS séparé**, regroupé dans une sous-OU dédiée.

### Justification réglementaire

| Norme | Exigence | Justification |
|---|---|---|
| **IEC 62304 §5.1.9** | Séparation des environnements d'intégration, de test et de production | Un compte AWS par environnement est l'isolation la plus forte possible : aucun réseau partagé, aucune IAM partagée, aucune ressource partagée. |
| **ISO 13485 §6.4** | L'environnement de travail doit être maîtrisé | Séparer dev/staging/prod garantit qu'un développeur ne peut pas accidentellement modifier la production. |
| **ISO 13485 §7.5.6** | La production doit être qualifiée (IQ/OQ) | Un compte prod dédié permet de qualifier précisément cet environnement sans interférence des activités de développement. |
| **MDCG 2019-16 §4.1** | Security by design | L'isolation par compte AWS minimise le blast radius : un compromis du compte dev n'impacte pas la production. |
| **FDA 21 CFR Part 11 §11.10(d)** | Contrôle d'accès aux systèmes | Des SCP différentes par sous-OU permettent des règles strictes en prod (pas de delete, MFA matériel requis) tout en laissant plus de liberté en dev. |
| **HDS** | Séparation des données de santé | Les données de santé réelles (prod) sont strictement séparées des données de test (dev/staging). |
| **SOC 2 CC6.1** | Contrôle d'accès logique | Chaque environnement a ses propres politiques d'accès, indépendantes les unes des autres. |

### Pourquoi des sous-OU et pas juste des comptes séparés ?

Les SCP (Service Control Policies) s'appliquent **par OU et s'héritent**. Avec des sous-OU :

```
Workloads OU         → SCP commune : régions EU uniquement, protection CloudTrail
├── Production OU    → SCP additionnelle : deny delete, MFA matériel obligatoire
├── Staging OU       → SCP additionnelle : deny delete (protéger les tests de validation)
└── Development OU   → SCP minimale : liberté encadrée pour l'expérimentation
```

Cela garantit que :

- La **restriction régionale** (HDS) s'applique à tous les environnements automatiquement
- La **production a des protections supplémentaires** sans configuration manuelle par compte
- Tout nouveau compte ajouté dans une sous-OU **hérite automatiquement** des bonnes SCP → reproductibilité (IEC 62304 §8)

---

## 4. Sandbox OU

### Principe

Fournir un espace d'expérimentation **isolé et jetable** par utilisateur ou par équipe.

### Justification réglementaire

| Norme | Exigence | Justification |
|---|---|---|
| **IEC 62304 §5.1** | Le plan de développement doit prévoir les activités exploratoires | Un sandbox dédié sépare les expérimentations des environnements de développement du SaMD. |
| **MDCG 2019-16 §4.1** | Security by design | Un sandbox compromis ou mal configuré n'impacte aucun autre compte de l'organisation. |
| **ISO 13485 §6.4** | Maîtrise de l'environnement de travail | Les expérimentations ne polluent pas les environnements contrôlés. |

### Contrôles recommandés (SCP du Sandbox)

- Budget maximum (ex : 50€/mois, auto-nuke après dépassement)
- Pas d'accès aux données réelles de santé
- Pas de peering réseau avec les autres comptes
- Pas de connexion aux services partagés de l'Infrastructure OU

---

## 5. Suspended OU

### Principe

Parking pour les comptes à désactiver, avec une SCP **Deny All** qui bloque toute action.

### Justification réglementaire

| Norme | Exigence | Justification |
|---|---|---|
| **ISO 13485 §4.2.4** | Les enregistrements doivent être conservés pendant la durée de vie du DM | On ne peut pas supprimer immédiatement un compte qui contient des données historiques ou des preuves. Le déplacer dans Suspended le gèle sans le détruire. |
| **FDA 21 CFR Part 11 §11.10(e)** | Conservation de la piste d'audit | La preuve que le compte a existé, quand il a été suspendu et pourquoi, est conservée. |
| **MDCG 2019-16 §4.7** | Réponse aux incidents — conservation des preuves | En cas d'incident, on doit pouvoir investiguer un ancien compte sans qu'il ait été supprimé prématurément. |
| **SOC 2 CC6.3** | Traçabilité des changements d'accès | Le déplacement vers Suspended est lui-même un événement auditable dans CloudTrail. |

### Flux de vie d'un compte suspendu

```
Compte actif (dans son OU)
     │
     ▼  Décision de suspension (ticket ITSM approuvé)
Déplacé dans Suspended OU
     │  → SCP Deny All appliquée automatiquement
     │  → Le compte est gelé mais intact
     │
     ▼  Après la période de rétention
         (alignée sur la durée de vie du DM, ex: 15 ans pour implantables)
Fermeture définitive (aws organizations close-account)
```

---

## Alternatives rejetées

### ❌ Alternative 1 : Un seul compte AWS pour tout

| Problème | Norme violée |
|---|---|
| Pas d'isolation entre dev et prod | IEC 62304 §5.1.9 |
| Un admin voit et peut modifier tout | ISO 13485 §6.4, FDA §11.10(d) |
| Blast radius = total en cas de compromis | MDCG 2019-16 §4.1 |
| Impossible de qualifier la prod indépendamment | ISO 13485 §7.5.6 |
| Les logs sont dans le même compte que les ressources | FDA §11.10(e) |

### ❌ Alternative 2 : Comptes séparés sans OU

| Problème | Norme violée |
|---|---|
| Pas de SCP héritées → configuration manuelle par compte | IEC 62304 §8 (gestion de configuration) |
| Risque de dérive entre comptes | ISO 13485 §4.2.5 (maîtrise des documents) |
| Non reproductible | FDA §11.10(d) |
| Chaque nouveau compte doit être configuré de zéro | SOC 2 CC8.1 (gestion des changements) |

### ❌ Alternative 3 : OU plates (sans sous-OU pour Workloads)

| Problème | Conséquence |
|---|---|
| Même SCP pour dev et prod | Impossible d'avoir des règles plus strictes en prod sans affecter le dev |
| Pas de granularité dans les protections | Les développeurs subissent les restrictions de production ou la production manque de protections |

### ✅ Structure retenue : OU hiérarchiques avec SCP héritées

| Avantage | Détail |
|---|---|
| Isolation forte | 1 compte = 1 périmètre de sécurité |
| SCP héritées | Politique de sécurité appliquée structurellement, impossible à contourner |
| Reproductible | Tout nouveau compte hérite automatiquement des bonnes règles |
| Auditable | Structure visible en un coup d'œil pour les auditeurs |
| Conforme | Répond à toutes les exigences de toutes les normes applicables |
| Standard AWS | Alignée avec l'AWS Security Reference Architecture (SRA) → facilite les échanges avec AWS Support et les auditeurs |

---

## Références

- [AWS Security Reference Architecture (SRA)](https://docs.aws.amazon.com/prescriptive-guidance/latest/security-reference-architecture/)
- [AWS Organizations Best Practices](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_best-practices.html)
- Procédure de gestion des comptes : [account_management.md](account_management.md)
