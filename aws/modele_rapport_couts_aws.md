# Modèle de rapport mensuel — Coûts AWS

> **Période :** [M-1, ex. 2026-04]  
> **Organisation/OU :** [Nom]  
> **Périmètre :** [Comptes inclus/exclus]  
> **Source données :** CUR + Cost Explorer + Budgets + Anomaly Detection  

---

## 1. Résumé exécutif
**À remplir :** 5–10 lignes max.  
- Coût total M-1 : **[€]**  
- Variation vs M-2 : **[+/- %]**  
- Principales causes : **[service/compte/usage]**  
- Économies : **[€]**  
- Anomalies majeures : **[nbr / €]**  

---

## 2. Synthèse des coûts
### 2.1 Total par mois
| Mois | Coût total | Var. vs mois précédent |
|---|---:|---:|
| M-2 | [€] | - |
| M-1 | [€] | [+/- %] |

**À remplir :** comparer M-1 à M-2, expliquer brièvement les écarts.

### 2.2 Top 10 services
| Rang | Service | Coût M-1 | Var. vs M-2 | Commentaire |
|---:|---|---:|---:|---|
| 1 | [ex. EC2] | [€] | [+/- %] | [cause] |
| ... | ... | ... | ... | ... |

**À remplir :** prendre les 10 services les plus coûteux (Cost Explorer).

### 2.3 Top 10 comptes / OU
| Rang | Compte/OU | Coût M-1 | Var. vs M-2 | Commentaire |
|---:|---|---:|---:|---|
| 1 | [Compte/OU] | [€] | [+/- %] | [cause] |
| ... | ... | ... | ... | ... |

**À remplir :** identifier les comptes/OU à plus forte contribution et expliquer l’écart.

### 2.4 Répartition par tags obligatoires
| Tag | Valeur | Coût M-1 | % du total |
|---|---|---:|---:|
| CostCenter | [CC-001] | [€] | [%] |
| Owner | [Nom] | [€] | [%] |

**À remplir :** consolider par tags (Owner, CostCenter, Environment, Service).

---

## 3. Économies réalisées
### 3.1 Savings Plans / Reserved Instances
| Type | Couverture | Utilisation | Économies M-1 |
|---|---:|---:|---:|
| Savings Plans | [%] | [%] | [€] |
| Reserved Instances | [%] | [%] | [€] |

**À remplir :** relever couverture/utilisation dans Cost Explorer (Savings).

### 3.2 Optimisations appliquées
| Action | Service | Gain estimé mensuel | Statut |
|---|---|---:|---|
| Right-sizing | EC2 | [€] | [fait/en cours] |
| Stop instances idle | RDS | [€] | [fait/en cours] |

**À remplir :** lister les optimisations réellement appliquées sur M-1.

---

## 4. Anomalies & non-conformités
### 4.1 Anomalies détectées
| Date | Service | Compte | Montant | Cause | Action |
|---|---|---|---:|---|---|
| [JJ/MM] | [Service] | [Compte] | [€] | [raison] | [action] |

**À remplir :** exporter les anomalies depuis Cost Anomaly Detection.

### 4.2 Budgets dépassés
| Budget | Compte/OU | Seuil | Dépassement | Action |
|---|---|---:|---:|---|
| [Nom] | [Compte/OU] | [€] | [€] | [action] |

**À remplir :** lister les budgets en alerte (AWS Budgets).

### 4.3 Non-conformités (tags/abonnements)
| Type | Détail | Impact | Action |
|---|---|---:|---|
| Tags manquants | [ex. 12% sans Owner] | [€] | [plan] |
| Abonnement non approuvé | [ex. SP/RI] | [€] | [plan] |

**À remplir :** identifier les ressources non taggées et engagements non validés.

---

## 5. Plan d’action (mois M)
| Priorité | Action | Responsable | Échéance | Gain estimé |
|---:|---|---|---|---:|
| 1 | [action] | [nom] | [date] | [€] |

**À remplir :** 3 à 10 actions max, triées par impact coût.

---

## 6. Annexes (facultatif)
- Captures/graphes Cost Explorer
- Extraits CUR/Athena
- Détails Compute Optimizer
