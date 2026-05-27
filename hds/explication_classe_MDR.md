 Classe │ Niveau de risque │                   Implication                   │                      Évaluation conformité                      │
  ├────────┼──────────────────┼─────────────────────────────────────────────────┼─────────────────────────────────────────────────────────────────┤
  │ I      │ Faible           │ Auto-déclaration                                │ Sans organisme notifié (sauf I stérile, mesurage, réutilisable) │
  ├────────┼──────────────────┼─────────────────────────────────────────────────┼─────────────────────────────────────────────────────────────────┤
  │ IIa    │ Modéré           │ Organisme notifié requis                        │ Audit + évaluation technique par échantillonnage                │
  ├────────┼──────────────────┼─────────────────────────────────────────────────┼─────────────────────────────────────────────────────────────────┤
  │ IIb    │ Élevé            │ Organisme notifié requis                        │ Audit + évaluation technique systématique                       │
  ├────────┼──────────────────┼─────────────────────────────────────────────────┼─────────────────────────────────────────────────────────────────┤
  │ III    │ Très élevé       │ Organisme notifié requis + consultation experts │ Procédure renforcée, scrutiny obligatoire                       │
  └────────┴──────────────────┴─────────────────────────────────────────────────┴─────────────────────────────────────────────────────────────────┘

  Pour un logiciel (SaMD), la classe est déterminée par la Règle 11 de l'Annexe VIII :

  - logiciel fournissant des informations utilisées pour des décisions diagnostiques ou thérapeutiques = au minimum IIa,
  - si ces décisions peuvent causer une détérioration grave de l'état d'un patient ou une intervention chirurgicale = IIb,
  - si elles peuvent causer décès ou détérioration irréversible = III,
  - logiciel destiné à surveiller des processus physiologiques = IIa (IIb si paramètre vital),
  - tout autre logiciel = I.

  Hypothèse probable pour tes planificateurs

  plannerHip2D, plannerHip3D, plannerKneeMadison fournissent des informations utilisées pour planifier une pose d'implant. La pose d'implant est une intervention chirurgicale invasive, donc la lecture standard de la Règle 11
  conduit à classe IIb pour ces trois produits. Mais c'est une lecture indicative — la classification officielle est dans le dossier technique remis à l'organisme notifié (à confirmer côté Céline Antoine / pôle Affaires
  Réglementaires).

  Pourquoi cette classe doit figurer dans le plan

  Elle conditionne quatre choses concrètes :

  Domaine: Délai de notification vigilance MDR art. 87
  Impact de la classe: Incident grave : 15 jours (toutes classes). Menace de santé publique : 2 jours. Décès ou détérioration grave : 10 jours. Indépendant strict de la classe, mais la qualification "grave" est plus sensible pour
    IIb/III.
  ────────────────────────────────────────
  Domaine: PSUR (Periodic Safety Update Report)
  Impact de la classe: Classe I : pas de PSUR (PMSR plan-based). Classe IIa : PSUR au moins tous les 2 ans. IIb et III : PSUR annuel obligatoire (MDR art. 86 §1).
  ────────────────────────────────────────
  Domaine: Surveillance post-market
  Impact de la classe: Classe I : surveillance de base. Classe IIa et au-delà : PMS plan avec analyse de tendances obligatoire. IIb/III : reporting renforcé vers l'organisme notifié.
  ────────────────────────────────────────
  Domaine: Seuil d'acceptabilité du risque résiduel ISO 14971
  Impact de la classe: Plus la classe est élevée, plus le seuil d'acceptation est strict. Une vulnérabilité acceptable pour un logiciel classe I peut être inacceptable pour un classe IIb.

  Donc pour le plan de veille mensuelle, connaître la classe permet :

  - d'ajuster les SLA de réaction (un P1 sur classe IIb mérite peut-être 48 h plutôt que 72 h),
  - de définir ce qui alimente le PSUR (en classe IIb il faut nourrir un PSUR annuel obligatoire, sans cette synthèse threat intel mensuelle on ne tient pas le PSUR),
  - d'éclairer la décision de notification §4.9 (l'arbitrage "risque sécurité patient" est lu par l'organisme notifié à travers le prisme de la classe).

  Action concrète

  Demander à Céline Antoine la classe officielle des 3 DM (probablement IIb pour les 3, à confirmer). Si la classe est confirmée IIb, intégrer en §4.9 du plan v2 :

  - alignement de la production threat intel sur la cadence PSUR annuel (la synthèse 12 rapports mensuels devient une entrée du PSUR de l'année),
  - mention que la liste des items P1 affectant un DM doit être restituée à l'organisme notifié au prochain audit ou via le canal EUDAMED quand opérationnel.