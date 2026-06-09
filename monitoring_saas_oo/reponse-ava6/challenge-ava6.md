# Challenge des propositions AVA6

Réponse point par point à la note AVA6, avec critique technique et recommandation. Les faits techniques sont sourcés dans `../docs/01-flux-telechargement.md`.

## 0. Cadrage : architecture réelle (hybride)

Le document d'architecture de référence (`../docs/00-architecture-reference.md`) confirme la topologie actuelle :
- **Zone métier AVA6** : Firewall AVA6 → Reverse Proxy AVA6 (terminaison SSL) → **Windows Server 2022 + IIS + PHP/Symfony FastCGI** ; MariaDB locale (loopback 3306). C'est ici que se font les téléchargements de fichiers patients.
- **Zone calcul IA OVH** : Traefik → Debian (API + Messenger) → Ubuntu (Worker + Docker IA). Reçoit du HTTPS direct (chirurgiens, API externes) et traite des données dérivées patient.

Conséquences pour le challenge :
- Le référentiel « Windows/IIS » d'AVA6 est **correct pour la prod métier actuelle**. La stack Debian/Docker/nginx du dépôt `oo-infra` est une **cible de migration non encore en prod** : ne pas la confondre avec la réalité d'aujourd'hui.
- **IIS journalise nativement les octets** (`sc-bytes`, format W3C) : la piste « le serveur web mesure le volume » d'AVA6 est donc **techniquement fondée** (ce qui n'aurait pas été le cas sur le nginx cible, dont le `log_format` n'inclut pas les octets).
- Mais ni IIS ni le firewall/reverse proxy ne connaissent l'**utilisateur applicatif** (auth en session Symfony). Pour détecter une exfiltration par un compte, il faut le **journal applicatif**.
- **Périmètre = zone métier AVA6** (IIS + app). La zone IA OVH est hors périmètre : elle ne traite que des données anonymisées (`anonymousCode` / `patient_hashed_id`). À confirmer (anonymisation irréversible vs pseudonymisation, dé-identification DICOM) ; sinon la réintégrer.
- **IP cliente : OK.** Le reverse proxy AVA6 propage l'IP réelle via `X-Forwarded-For` et l'application est câblée pour la lire (`trusted_proxies`). Reste à confirmer la valeur `TRUSTED_PROXIES` en prod (IP du proxy AVA6).
- **Plages d'usage : 08h-20h.** Les plateformes ne sont utilisées qu'en journée, donc pas d'astreinte 24/7 à prévoir. Cela aligne la réaction sur les heures ouvrées et fait de toute activité nocturne un signal fort (voir §4 et `../alerting/seuils-actions.md`).

## 1. « Tracer les téléchargements via le serveur Web / un plugin »

**Critique.** Vrai pour le volume, insuffisant pour l'identité.
- IIS (format W3C) voit l'URL (`cs-uri-stem`), l'IP (`c-ip`), le statut (`sc-status`), l'horodatage, **et les octets servis (`sc-bytes`)**. Mesurer le volume par URL et par IP est donc faisable **sans plugin payant**, juste en activant les bons champs W3C.
- En revanche IIS **ne voit pas** l'utilisateur authentifié, l'intervention, le patient, le type de fichier : l'auth est gérée en session Symfony, donc `cs-username` est vide. Et l'IP vue est celle du reverse proxy AVA6 si `X-Forwarded-For` n'est pas exploité.
- Comme les fichiers patients sont **servis à travers PHP** (`BinaryFileResponse`), toutes les URL de download apparaissent sous `/interventions/.../download`. IIS peut donc les compter, mais sans les rattacher à un compte.

**Recommandation.** Combiner, sans plugin payant :
- Source d'**identité** = canal Monolog `sensitive` (déjà existant, 20 points d'appel), à enrichir : utilisateur, IP, taille.
- Source de **volume** = log IIS W3C (`sc-bytes`), déjà disponible, à centraliser. Sert aussi de filet si un fichier était un jour servi hors PHP.
Pas besoin d'un module web tiers : les deux sources existent ou s'activent par configuration. Voir `../tracabilite/strategie-3-couches.md`.

## 2. « WAF / Firewall N7 pour tracer et mesurer »

**Critique.** Surdimensionné pour le besoin exprimé, et mal positionné comme source de traçabilité.
- Un WAF protège contre des patterns d'attaque (injections, scanning). Il ne sait pas qu'un chirurgien légitime exfiltre 50 dossiers : pour lui c'est du trafic HTTPS valide et authentifié. Le WAF ne répond donc pas à « comportement inhabituel d'un compte légitime », qui est le risque décrit (téléchargement massif via requêtes applicatives).
- Un WAF a une vraie valeur **par ailleurs** (durcissement périmétrique, exigence raisonnable en contexte HDS), mais ce n'est pas l'outil de détection d'exfiltration par volume. Le présenter comme tel mélange deux objectifs.

**Recommandation.** Découpler :
- Détection d'exfiltration par volume/fréquence : **couche applicative + agrégation de logs** (réponse au besoin réel).
- WAF : à étudier comme **chantier sécurité distinct** (défense périmétrique), pas comme réponse à cette demande. Ne pas laisser AVA6 facturer un WAF en le présentant comme la solution de traçabilité.

## 3. Seuil d'alerte (> 5 Go/jour) et fréquence anormale

**Critique.** Le principe est bon mais un seuil global unique (5 Go/jour, tous comptes confondus) est **trop grossier** : un usage légitime cumulé peut le dépasser, et un attaquant prudent (4 Go/jour) passe sous le radar.

**Recommandation.** Seuils **par utilisateur et par IP**, multi-critères :
- Volume : > 5 Go / 24 h **par utilisateur** (et un seuil plus bas, ex. 1 Go/h, pour la vélocité).
- Fréquence : > N téléchargements / heure par utilisateur (N à calibrer sur 2 à 4 semaines de baseline preprod/prod).
- Diversité : un même compte téléchargeant des fichiers de M interventions distinctes / heure (signal d'exfiltration plus fiable que le seul volume).
Détail et valeurs dans `../alerting/seuils-actions.md`.

## 4. « HO FR ou 24/7/365 ? »

Tranché par l'usage : les plateformes ne servent qu'en **08h-20h**. Pas besoin d'astreinte 24/7.

**Recommandation.** Dissocier détection et réaction :
- **Détection automatisée 24/7** (le système agrège et alerte en continu, coût quasi nul une fois en place). À garder 24/7 justement parce que l'usage est diurne : toute activité de téléchargement significative en dehors de 08h-20h est un **signal d'anomalie fort** (règle OFFHOUR).
- **Réaction humaine en heures ouvrées FR**, alignée sur la fenêtre d'usage. Alerte critique (mail + Slack, canal déjà configuré dans `monolog.yaml`) consultable le cas échéant. Inutile de souscrire une supervision 24/7 AVA6.

## 5. « Action en cas de dépassement : coupure ou appel client ? »

**Recommandation.** Pas de coupure automatique du service (risque d'indisponibilité d'un dispositif médical sur faux positif, impact patient). Réaction graduée :
1. Alerte + journalisation horodatée (preuve).
2. Revue humaine en HO : confirmer légitime / suspect.
3. Si suspect : **suspension du compte concerné** (pas du service global) + contact client, via une procédure documentée.
La coupure globale automatique n'est justifiable que sur signal d'attaque actif avéré, décision à formaliser avec le DPO.

## 6. Géolocalisation / restriction par pays

**Critique.** Idée pertinente comme **mesure de réduction de surface**, pas comme détection. Limites : VPN, clients multi-pays, faux sentiment de sécurité.

**Recommandation.** Pertinent si et seulement si la base clients d'un environnement est géographiquement bornée et stable. À traiter au niveau du Firewall / Reverse Proxy AVA6 (filtrage IP/pays) plutôt qu'au WAF payant. À documenter comme exception gérée (clients itinérants). Mesure complémentaire, jamais substitut à la traçabilité applicative.

## 7. « Tout ce qui sort de la config du site aura un coût »

**Critique.** Vrai côté infra AVA6, mais cela ne doit pas conduire à acheter du WAF/supervision 24/7 alors que **la donnée la plus utile est déjà produite gratuitement par l'application** (canal `sensitive`). L'essentiel du besoin se traite par du logiciel déjà en place + une brique d'agrégation légère, sans coût récurrent AVA6.

## Synthèse de la position à tenir face à AVA6

| Proposition AVA6 | Verdict | Notre réponse |
|---|---|---|
| Log serveur web (IIS) pour tracer/mesurer | Bon pour le volume, aveugle à l'identité | Volume via IIS `sc-bytes` (sans plugin) ; identité via log applicatif `sensitive` |
| WAF/FW N7 comme traçabilité | Hors sujet pour ce besoin | WAF = chantier sécurité distinct, pas cette réponse |
| Seuil 5 Go/jour global | Trop grossier | Seuils par utilisateur + IP, multi-critères |
| HO vs 24/7 | Tranché (usage 08h-20h) | Détection 24/7 auto, réaction HO, hors-plage = anomalie |
| Coupure service | Risqué | Suspension compte ciblée, pas coupure globale auto |
| Géoblocage | Complémentaire | Au niveau Firewall/RP AVA6, si base clients bornée |
| Coût hors config | Vrai mais | Le cœur de la solution est déjà gratuit (app) |

## Brouillon de réponse à AVA6 (à ajuster)

> Merci pour ces pistes. Notre analyse, à partir de l'architecture en place (Windows Server 2022 / IIS / PHP-Symfony chez vous pour le métier, zone IA conteneurisée chez OVH) :
>
> 1. Le log IIS (format W3C) nous convient pour **mesurer le volume** : il enregistre déjà les octets servis (`sc-bytes`) par URL et par IP. Pouvez-vous confirmer que les champs W3C `c-ip`, `cs-username`, `cs-uri-stem`, `cs-uri-query`, `sc-status`, `sc-bytes`, `time-taken` sont activés sur les sites prod IIS, et nous préciser la rétention et l'emplacement de ces journaux ? Pas besoin de module/plugin tiers a priori.
>
> 2. Pour identifier **qui** télécharge (un WAF ou IIS ne voient pas l'utilisateur applicatif, l'auth étant en session Symfony), nous enrichissons notre journal applicatif dédié (utilisateur, IP, volume) côté code. C'est la source fiable pour détecter un téléchargement massif par un compte. L'IP cliente réelle nous est déjà transmise par votre reverse proxy via `X-Forwarded-For`, que l'application exploite.
>
> Cadrage proposé :
> - Traçabilité et volume : log applicatif (identité) + log IIS (volume), agrégés. Besoin d'un espace de centralisation/rétention des logs de la zone métier (les données envoyées à la zone IA OVH étant anonymisées, elles sont hors périmètre).
> - Détection automatisée 24/7, réaction en heures ouvrées : nos plateformes ne servent qu'en 08h-20h, donc pas d'astreinte 24/7 nécessaire de votre côté. Toute activité hors de cette plage est traitée comme anomalie.
> - En cas de dépassement : alerte et revue humaine, suspension éventuelle du compte concerné, pas de coupure automatique du service.
> - WAF et géoblocage : à étudier comme renforcement périmétrique distinct, pas comme réponse à ce besoin précis.
>
> Pouvez-vous chiffrer la brique de centralisation/rétention des logs (volume à préciser) et confirmer le point 1 (champs W3C IIS) ci-dessus ?

## Sources
- `../docs/00-architecture-reference.md` (architecture hybride actuelle : Windows/IIS AVA6 + IA OVH)
- `../docs/01-flux-telechargement.md`
- `saas_local/app/config/packages/prod/monolog.yaml`
- IIS W3C logging (champs `sc-bytes`, `c-ip`, `cs-uri-stem`, `time-taken`)
- `architecture/2026-05-05_phase2_v2_action_plan.md` (cible de migration, non en prod)
