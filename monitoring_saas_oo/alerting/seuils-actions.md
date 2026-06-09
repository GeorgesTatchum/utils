# Seuils, alertes et réaction

Détecter un téléchargement massif ou anormalement fréquent (objectif : exfiltration de données). Périmètre : production uniquement. Source des signaux : couches 1 et 3 de `../tracabilite/strategie-3-couches.md`.

## 1. Pourquoi pas le seuil unique « 5 Go/jour »

Le seuil global proposé par le client/AVA6 est un bon point de départ mais insuffisant seul :
- Trop haut pour un attaquant prudent (3 à 4 Go/jour passent sous le radar).
- Faux positifs sur usage légitime cumulé (campagne de récupération de rapports).
- Ne distingue pas « 1 gros fichier légitime » de « 200 dossiers de patients différents ».

Réponse : seuils **par utilisateur et par IP**, croisant volume, fréquence et diversité. Le volume seul est le critère le plus faible ; la **diversité d'interventions accédées** est le meilleur indicateur d'exfiltration.

## 2. Jeu de règles recommandé

Valeurs initiales à calibrer sur 2 à 4 semaines de baseline (cf. §4). Sévérité : INFO (contexte), WARN (à revoir en HO), CRIT (alerte immédiate).

| ID | Règle | Seuil initial | Sévérité |
|---|---|---|---|
| VOL-DAY | Volume téléchargé par utilisateur sur 24 h glissantes | > 5 Go | WARN |
| VOL-HOUR | Volume téléchargé par utilisateur sur 1 h | > 1 Go | WARN |
| VOL-IP | Volume par IP sur 24 h (capte multi-comptes même IP) | > 8 Go | WARN |
| FREQ | Nb de téléchargements par utilisateur sur 1 h | > 60 | WARN |
| DIV | Nb d'interventions distinctes accédées par utilisateur sur 1 h | > 20 | CRIT |
| BURST | DIV + FREQ simultanés (rafale sur dossiers variés) | DIV>10 et FREQ>30 / 15 min | CRIT |
| OFFHOUR | Activité de download hors plage d'usage des plateformes (08h-20h FR) | tout téléchargement entre 20h-08h, seuil bas (ex. > 100 Mo cumulés) | CRIT |
| GEO | Download depuis un pays hors liste attendue (si géo activée) | 1 occurrence | WARN |

Note : DIV et BURST sont calculables uniquement grâce au log applicatif (couche 1), pas au log IIS ni au WAF (qui ne connaissent pas l'utilisateur). C'est la justification concrète du « pourquoi l'application et pas le WAF » de `../reponse-ava6/challenge-ava6.md` §2. VOL-IP est calculable côté IIS (`sc-bytes`) comme côté app.

OFFHOUR est passée en CRIT avec un seuil bas : les plateformes n'étant utilisées qu'en 08h-20h, tout téléchargement notable la nuit est par construction anormal (compte compromis ou exfiltration discrète). C'est la règle la plus discriminante de ce contexte, calculable aussi bien côté IIS (`sc-bytes` + horodatage) que côté app.

## 3. Canaux d'alerte

Réutiliser l'existant avant d'ajouter du coût :
- **Slack** : un handler Slack est déjà configuré (`config/packages/prod/monolog.yaml`, `slack_errors`, niveau `critical`). Ajouter un canal/handler dédié aux alertes sécurité (séparer du bruit applicatif).
- **Mail** : alerte CRIT vers la boîte sécurité/DPO.
- **Grafana alerting** (couche 3) : règles VOL/FREQ/DIV évaluées en continu, notification Slack/mail.

Aucune donnée patient identifiante dans le corps de l'alerte : n'inclure que `user_id`, `client_ip`, volumes, compteurs, `intervention identifier` (pas de nom patient). Conforme à l'exigence de pseudonymisation.

## 4. Calibration des seuils (baseline)

Avant d'activer en mode bloquant :
1. Déployer la collecte (couches 1-2-3) en observation seule.
2. Sur 2 à 4 semaines, mesurer les percentiles par utilisateur (p50, p95, p99) du volume/jour, des téléchargements/h, des interventions distinctes/h.
3. Fixer WARN au p99 observé + marge, CRIT nettement au-dessus.
4. Réviser trimestriellement (revue documentée, traçable MDR).

Sans baseline, les valeurs §2 sont des estimations prudentes, pas des vérités.

## 5. Détection 24/7, réaction en heures ouvrées (08h-20h)

Les plateformes ne servent qu'en 08h-20h : pas d'astreinte 24/7 à prévoir.
- **Détection** : automatisée, continue, 24/7/365 (coût marginal nul une fois la couche 3 en place). La garder 24/7 sert précisément à capter l'activité hors plage d'usage (règle OFFHOUR), signal le plus fort ici.
- **Réaction de niveau 1** : en heures ouvrées, alignée sur la fenêtre d'usage 08h-20h. Les alertes CRIT (dont OFFHOUR) restent envoyées la nuit (Slack/mail) et sont traitées à l'ouverture, sauf gravité justifiant une intervention immédiate. Pas de supervision 24/7 AVA6 à souscrire.

## 6. Procédure en cas de dépassement

Pas de coupure automatique du service (un dispositif médical indisponible sur faux positif a un impact patient). Réaction graduée et documentée :

1. **Alerte + journalisation** horodatée (constitue la preuve).
2. **Triage** (HO) : volume légitime connu ? compte compromis ? IP inhabituelle ?
3. Si confirmé suspect : **suspension du compte concerné** (pas du service global), via une procédure d'urgence documentée. Forcer la déconnexion : aujourd'hui sessions PHP sur disque du nœud Windows (suppression de la session côté serveur), demain sessions Redis (invalidation centralisée, cible de migration).
4. **Notification** : DPO + client concerné selon la procédure incident. En cas de violation de données de santé avérée, obligation de notification CNIL sous 72 h à évaluer par le DPO.
5. **Post-mortem** et ajustement des seuils.

La coupure globale automatique n'est envisageable que sur signal d'attaque actif (et non sur simple dépassement de volume), décision à formaliser avec le DPO et à n'appliquer qu'en dernier recours.

## 7. Géoblocage (optionnel, complémentaire)

Si la base clients d'un environnement est géographiquement stable :
- Au niveau du **Firewall / Reverse Proxy AVA6** (filtrage IP/pays en entrée), pas via un WAF payant.
- Gérer explicitement les exceptions (clients itinérants, VPN).
- Mesure de réduction de surface, jamais substitut à la traçabilité applicative.

## Récapitulatif des décisions à valider

| Point | Recommandation | À valider par |
|---|---|---|
| Seuils | Multi-critères par user/IP, calibrés sur baseline | Sécurité + métier |
| Plage de réaction | Détection 24/7, réaction HO FR | Direction + AVA6 |
| Action sur dépassement | Suspension compte, pas coupure service | DPO + Direction |
| Rétention des traces | ≥ durée légale, chiffrée, intègre | DPO |
| Géoblocage | Firewall/RP AVA6, si base clients bornée | Métier |

## Sources
- `../docs/00-architecture-reference.md`
- `../tracabilite/strategie-3-couches.md`
- `saas_local/app/config/packages/prod/monolog.yaml` (handler `slack_errors`)
