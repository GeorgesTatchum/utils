# Procédure — reporting mensuel des coûts AWS

## Objectif
Produire chaque mois un reporting synthétique des **coûts**, **économies** et **anomalies/abonnements non conformes** pour l’organisation.

## Prérequis (une fois)
1. **Activer** dans la console AWS :
   - Cost Explorer
   - AWS Cost and Usage Report (CUR)
   - Cost Anomaly Detection
2. **Définir la taxonomie de tags** (ex. `Owner`, `CostCenter`, `Environment`, `Service`) et imposer leur usage.
3. **Budgets** : créer des budgets par compte, OU, service critique (EC2, RDS, S3, EKS).
4. **Savings** : activer Savings Plans/Reserved Instances et AWS Compute Optimizer.

## Cycle mensuel (J+1 à J+5)
1. **Extraire les données** (mois M-1) :
   - CUR (S3) pour le détail des coûts
   - Cost Explorer pour les vues synthétiques
   - AWS Budgets + Anomaly Detection pour alertes
2. **Synthèse coûts** :
   - Total M-1 vs M-2 (+/-%)
   - Top 10 services
   - Top 10 comptes/OU
   - Répartition par tags obligatoires (owner/cost center)
3. **Économies réalisées** :
   - Savings Plans/RI : couverture, utilisation, économies
   - Right-sizing (Compute Optimizer) : recommandations appliquées
4. **Anomalies & non-conformités** :
   - Anomalies détectées (montant, service, compte)
   - Dépassements de budgets
   - Ressources sans tags obligatoires
   - Abonnements/engagements non conformes (plans non approuvés)
5. **Plan d’action** :
   - Actions correctives priorisées (par coût et risque)
   - Responsable et échéance

## Modèle de livrable (structure)
1. **Résumé exécutif** (5–10 lignes)
2. **Coûts** (tableaux + graphiques)
3. **Économies** (savings plans, RI, optimisations)
4. **Anomalies & non-conformités** (liste priorisée)
5. **Actions** (qui/quoi/quand)

## Outils recommandés
- **AWS Cost Explorer**
- **AWS CUR + Athena/QuickSight**
- **AWS Cost Anomaly Detection**
- **AWS Budgets**
- **AWS Compute Optimizer**

## Démarrage immédiat (checklist)
1. Activer CUR + Anomaly Detection
2. Définir tags obligatoires + politique de tagging
3. Créer budgets par compte/OU/service
4. Générer le premier rapport M-1
