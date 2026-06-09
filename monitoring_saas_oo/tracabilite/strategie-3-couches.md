# Stratégie de traçabilité et détection : 3 couches

Réponse aux 3 demandes (tracer, mesurer le volume, alerter). Architecture cible : `../docs/00-architecture-reference.md` (prod métier Windows/IIS chez AVA6 + zone IA OVH). Principe : l'identité (qui télécharge) ne s'obtient qu'à la couche applicative ; le volume s'obtient à la fois côté app et côté IIS. On combine les deux.

```
Couche 1  APPLICATIF (identité + volume)   canal Monolog `sensitive` enrichi (user, IP, octets)
Couche 2  WEB IIS (volume + corrélation)   journal W3C (sc-bytes, c-ip, cs-uri-stem)
Couche 3  AGRÉGATION + ALERTING            collecteur de logs + règles de seuil
```

## Couche 1 : applicatif (priorité 1, coût quasi nul)

Le canal `sensitive` existe déjà et journalise chaque téléchargement (`../docs/01-flux-telechargement.md` §3). Trois évolutions à apporter, toutes dans `saas_local/app`.

### 1.1 Enrichir le contexte du log
Ajouter à chaque appel de download (ou via un processor Monolog global) :
- `user_id` et/ou identifiant de compte (depuis `Security::getUser()`)
- `client_ip` (`Request::getClientIp()`) : le reverse proxy AVA6 propage déjà `X-Forwarded-For` et `framework.trusted_proxies` est câblé (`framework.yaml:24`). Vérifier seulement que `TRUSTED_PROXIES` vaut en prod l'IP/CIDR du proxy AVA6 (pas `127.0.0.1`)
- `bytes` : taille du fichier servi (`filesize($tmpFile)` avant `BinaryFileResponse`)
- `route` et `intervention_id` (déjà partiellement présents)

Mise en oeuvre recommandée : un **EventSubscriber sur `kernel.response`** filtrant les `BinaryFileResponse` sur les routes de download, plutôt que de modifier 20 contrôleurs. Centralise l'enrichissement et garantit qu'aucune route n'est oubliée. Émettre un événement applicatif unique `FileDownloaded` consommé par un listener qui logge sur `sensitive`.

### 1.2 Centraliser et sécuriser le log sensible (conformité)
Problème : `sensitive_logs` écrit en `rotating_file` dans `%kernel.logs_dir%/sensitive/` sur le disque du nœud Windows (`config/packages/prod/monolog.yaml:46-52`). Risque : pas de centralisation, perte possible à la réinstallation du nœud, pas d'horodatage scellé. Traçabilité des accès aux données de santé fragile (HDS / IEC 62304).

Options, par ordre de préférence :
1. **Sortie JSON + agent de collecte sur le nœud Windows** poussant le fichier vers le collecteur central (voir couche 3). Le plus simple sur l'existant.
2. Handler Monolog poussant directement vers le collecteur (handler socket/HTTP/syslog), sans dépendre d'un agent.
3. Conserver le fichier local en append-only sur un volume chiffré, avec sauvegarde régulière hors nœud (transitoire).

À la migration Linux/Docker, l'option 1 deviendra « stdout + driver de log Docker » (cf. Phase 2 v2). Le format JSON enrichi reste identique : aucun re-travail applicatif.

Exigence transverse : **rétention ≥ durée légale** applicable aux traces d'accès aux données de santé (à confirmer avec le DPO ; le `max_files: 366` actuel vise déjà ~1 an), **chiffrement au repos**, **intégrité** (append-only, idéalement horodatage/scellement).

### 1.3 Vérifier le formatter et le masquage
`monolog.formatter.sensitive` est référencé mais sa définition n'a pas été localisée dans `config/services.yaml`. Vérifier : qu'il existe, qu'il ne logge **aucune donnée patient identifiante en clair** (utiliser `patient_hashed_id` / `intervention identifier`, ce qui est déjà le cas dans les appels existants). Aligné sur l'instruction « aucune donnée patient identifiante dans les traces ».

## Couche 2 : web IIS (volume + corrélation, coût quasi nul)

IIS journalise nativement au format W3C. Vérifier/activer sur les sites prod les champs utiles à la mesure de volume (action AVA6, sans plugin) :

| Champ W3C | Apport |
|---|---|
| `date`, `time` | horodatage |
| `c-ip` | IP cliente (voir réserve XFF ci-dessous) |
| `cs-username` | utilisateur (vide ici : auth en session Symfony, pas IIS) |
| `cs-uri-stem`, `cs-uri-query` | route de download |
| `sc-status` | statut |
| `sc-bytes` | **octets servis = volume téléchargé** |
| `cs-bytes` | octets reçus |
| `time-taken` | durée |

`sc-bytes` donne le volume réellement servi par requête, même pour un chemin ne passant pas par le canal applicatif (filet de sécurité). 

Réserves :
- IIS ne connaît pas l'utilisateur applicatif (`cs-username` vide) : la corrélation par compte se fait à la couche 1.
- L'IP vue par IIS (`c-ip`) est celle du **reverse proxy AVA6**. L'IP cliente réelle est dans `X-Forwarded-For` (propagé, confirmé). Pour l'avoir aussi dans le log IIS, journaliser cet en-tête (champ personnalisé via le module Custom Logging / `X-Forwarded-For`). À défaut, s'appuyer sur l'IP cliente déjà enrichie par l'application en couche 1 (qui exploite XFF via `trusted_proxies`) : c'est suffisant pour la corrélation par compte.

Zone IA OVH : **hors périmètre** (données anonymisées y transitant, cf. `../docs/00-architecture-reference.md`). Si cette anonymisation n'est pas confirmée, activer aussi les access logs Traefik OVH (champ `DownstreamContentSize`) et réintégrer cette zone.

## Couche 3 : agrégation et alerting (le seul vrai coût)

C'est la brique à dimensionner avec AVA6 (espace de centralisation + rétention). Sources : nœuds Windows de la zone métier AVA6.

Pile recommandée (légère, souveraine, open source) :
- Agent de collecte : **Grafana Alloy** ou **Promtail** (binaire Windows) sur les nœuds Windows AVA6.
- Stockage/index : **Loki**. Visualisation + alerting : **Grafana**.
- Alternative si une pile existe déjà chez AVA6 : y router les logs JSON (déjà structurés), pas besoin de redévelopper.

Sources à collecter : fichier(s) du canal `sensitive` (couche 1) + journaux W3C IIS (couche 2).

Pourquoi Loki/Grafana : faible empreinte, agent Windows disponible, alerting intégré, requêtes par label (user_id, client_ip, route). Évite l'achat d'une solution propriétaire.

Données poussées :
- Couche 1 : événements `FileDownloaded` (user_id, ip, bytes, route, intervention_id, timestamp).
- Couche 2 : journal W3C IIS (AVA6).

Règles d'alerte : voir `../alerting/seuils-actions.md`.

Placement : collecteur **hors des nœuds applicatifs** (pour survivre à un incident sur un nœud), accès restreint. Rétention et chiffrement selon exigence DPO. Logs chiffrés en transit vers le collecteur.

## Plan de mise en oeuvre (séquencé, du moins cher au plus structurant)

| Étape | Action | Effort | Dépendance |
|---|---|---|---|
| 1 | Enrichir canal `sensitive` (user, ip, bytes) via EventSubscriber | S (app) | aucune |
| 2 | Activer champs W3C IIS (`sc-bytes`, `c-ip`...) côté AVA6 | XS (infra AVA6) | aucune |
| 3 | Centraliser les logs AVA6 (Alloy/Promtail + Loki/Grafana) | M (infra) | espace à dimensionner AVA6 |
| 4 | Router le canal `sensitive` vers le collecteur + rétention chiffrée | S (infra) | étape 3 |
| 5 | Définir et activer les règles d'alerte | S | étapes 3-4 |
| 6 | Calibrer les seuils sur 2 à 4 semaines de baseline | continu | étape 5 |

Étapes 1 et 2 livrables immédiatement, indépendamment d'AVA6, et constituent déjà la traçabilité demandée. L'alerting (3 à 6) suit dès que la centralisation est disponible.

## Sources
- `../docs/00-architecture-reference.md` (hybride : Windows/IIS AVA6 + IA OVH)
- `../docs/01-flux-telechargement.md`
- `saas_local/app/config/packages/prod/monolog.yaml:46-52`
- IIS W3C logging (champs `sc-bytes`, `c-ip`, `cs-uri-stem`, `time-taken`)
- Traefik access logs (champ `DownstreamContentSize`)
- Grafana Loki / Alloy : https://grafana.com/docs/loki/latest/ , agents Windows disponibles
