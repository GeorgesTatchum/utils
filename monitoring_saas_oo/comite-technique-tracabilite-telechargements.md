# Comité technique : traçabilité et alerting des téléchargements de données patients

Document de travail pour décision en comité technique, avant retour à AVA6. Autoportant. Les analyses détaillées sont en annexe (fichiers de ce dossier).

- Date :
- Participants :
- Décision attendue : valider la stratégie de traçabilité/alerting et le contenu du retour à AVA6.

## 1. Objet

Suite au constat d'un risque de téléchargement de données patients via des requêtes applicatives, mettre en place sur la production :
1. la traçabilité et l'identification des téléchargements de fichiers,
2. la visibilité sur les volumes téléchargés,
3. une alerte sur comportement inhabituel (volume élevé ou fréquence anormale, ex. > 5 Go/jour).

AVA6 (hébergeur) a répondu par des pistes (log serveur web, WAF/firewall N7, géoblocage, seuil d'alerte, questions HO vs 24/7 et action sur dépassement). Ce document les challenge et propose une stratégie.

## 2. Architecture concernée (rappel)

Architecture hybride (source : `docs/00-architecture-reference.md`, document Word d'AVA6/OneSoftware).

```
Internet ─HTTPS─> Firewall AVA6 ─> Reverse Proxy AVA6 (SSL) ─> IIS ─FastCGI─> PHP/Symfony   [Zone métier AVA6, Windows Server 2022]
                                                                                  └─> MariaDB locale (loopback 3306)
Internet ─HTTPS─> Traefik ─> Debian (API + Messenger) ─> Ubuntu (Worker + Docker IA)        [Zone calcul IA, OVH]
PHP/Symfony (Windows) ─HTTPS─> Traefik (OVH)   (flux critique : demande de traitement IA, donnée patient sortante)
```

Points structurants :
- Les téléchargements de fichiers patients (rapports, DICOM, documents) se font sur la **zone métier AVA6 (IIS/Windows)**. C'est le périmètre de cette demande.
- **Zone IA OVH hors périmètre** : les données qui y transitent sont anonymisées (usage d'un `anonymousCode` / `patient_hashed_id`, cf. code). Les sorties d'inférence ne sont ré-associées à une intervention qu'une fois revenues dans l'app métier AVA6, où leur téléchargement est déjà couvert par la couche applicative. Réserve à confirmer : voir §11 (anonymisation irréversible vs pseudonymisation, dé-identification des en-têtes DICOM).
- La stack Debian/Docker/nginx du dépôt `oo-infra` est une **cible de migration, pas la prod actuelle**.

## 3. Constats techniques (faits, sourcés)

1. **Les fichiers patients transitent par PHP** : le contrôleur lit le fichier (DSN `local:` sur disque Windows) et le sert via `BinaryFileResponse`. Pas d'URL présignée. Donc le volume est mesurable, mais l'identité (utilisateur, intervention) n'existe qu'au niveau applicatif. Preuves : `ReportDownloadController.php:67`, `EntryDataFileController.php:60`, `DocumentDownloadController.php`.
2. **Un journal applicatif des accès sensibles existe déjà** : canal Monolog `sensitive`, 20 points d'appel, dont chaque téléchargement, avec l'identifiant d'intervention. Config : `config/packages/prod/monolog.yaml:46-52` (rotating_file, rétention ~1 an).
3. **IIS journalise nativement les octets** (`sc-bytes`, format W3C) : la mesure de volume côté serveur web est possible sans plugin payant.
4. **IP cliente disponible** : le reverse proxy AVA6 propage `X-Forwarded-For` et l'application est câblée pour le lire (`framework.trusted_proxies`, `framework.yaml:24`). À confirmer : valeur `TRUSTED_PROXIES` en prod = IP du proxy AVA6 (le `.env` du repo porte `127.0.0.1`, valeur de dev).
5. **Usage des plateformes : 08h-20h** : pas d'astreinte 24/7 nécessaire ; toute activité nocturne est une anomalie par construction.

Limites de l'existant à corriger :
- Le log `sensitive` n'enregistre ni l'utilisateur, ni l'IP, ni la taille du fichier (pas de volume cumulable côté app).
- Il écrit dans un fichier local au nœud Windows : pas de centralisation, traçabilité fragile (HDS / IEC 62304).
- Le monitoring de la zone métier n'est aujourd'hui ni agrégé ni alertable.

## 4. Analyse des propositions AVA6

| Proposition AVA6 | Verdict | Position retenue |
|---|---|---|
| Log serveur web (IIS) pour tracer/mesurer | Bon pour le volume, aveugle à l'identité | Volume via IIS `sc-bytes` (sans plugin) ; identité via journal applicatif |
| WAF / firewall N7 comme traçabilité | Hors sujet pour ce besoin | Le WAF ne voit pas un compte légitime qui exfiltre. Chantier sécurité distinct, pas cette réponse |
| Seuil unique 5 Go/jour | Trop grossier | Seuils par utilisateur et par IP, multi-critères |
| HO FR vs 24/7 | Tranché par l'usage (08h-20h) | Détection auto 24/7, réaction en heures ouvrées, hors-plage = anomalie |
| Action : coupure service ? | Risqué (impact patient sur faux positif) | Suspension du compte concerné, pas de coupure globale automatique |
| Géoblocage | Complémentaire | Au Firewall/RP AVA6 (métier) et Traefik (IA), si base clients bornée. Jamais substitut à la traçabilité |
| « Tout hors config a un coût » | Vrai côté infra | Mais le cœur de la solution (journal applicatif) est déjà produit sans coût récurrent |

Message clé pour le comité : AVA6 voit l'infrastructure mais pas l'application. La donnée la plus utile (qui télécharge quoi, en quel volume) est produite par l'application et doit rester la source primaire d'identité. AVA6 apporte le volume (IIS) et la centralisation.

## 5. Solution recommandée : 3 couches

Détail : `tracabilite/strategie-3-couches.md`.

| Couche | Rôle | Contenu |
|---|---|---|
| 1. Applicatif | Identité + volume | Canal `sensitive` enrichi (user_id, IP, octets, route, intervention) via un EventSubscriber `kernel.response` sur les `BinaryFileResponse` |
| 2. Web | Volume + corrélation | Champs W3C IIS (`sc-bytes`, `c-ip`, `cs-uri-stem`...) côté AVA6 |
| 3. Agrégation + alerting | Détection | Agent (Alloy/Promtail, binaire Windows) → Loki → Grafana. Règles de seuil, notifications |

Principes :
- On combine : l'app donne le « qui », IIS donne le « combien », l'agrégateur corrèle et alerte.
- Le journal `sensitive` doit être centralisé et sécurisé (chiffrement, intégrité, rétention ≥ durée légale à confirmer DPO).
- Périmètre : **zone métier AVA6** uniquement (la zone IA OVH ne traite que des données anonymisées, hors périmètre).

## 6. Seuils et alerting

Détail et calibration : `alerting/seuils-actions.md`. Valeurs initiales à calibrer sur 2 à 4 semaines de baseline.

| ID | Règle | Seuil initial | Sévérité |
|---|---|---|---|
| VOL-DAY | Volume / utilisateur / 24 h | > 5 Go | WARN |
| VOL-HOUR | Volume / utilisateur / 1 h | > 1 Go | WARN |
| VOL-IP | Volume / IP / 24 h | > 8 Go | WARN |
| FREQ | Téléchargements / utilisateur / 1 h | > 60 | WARN |
| DIV | Interventions distinctes / utilisateur / 1 h | > 20 | CRIT |
| BURST | DIV > 10 et FREQ > 30 / 15 min | rafale | CRIT |
| OFFHOUR | Téléchargement entre 20h-08h (hors plage d'usage) | seuil bas (> 100 Mo) | CRIT |
| GEO | Téléchargement hors pays attendu (si géo activée) | 1 occurrence | WARN |

OFFHOUR et DIV sont les règles les plus discriminantes dans ce contexte. DIV/BURST ne sont calculables qu'avec le journal applicatif.

Canaux : Slack (handler déjà configuré dans `monolog.yaml`) + mail vers boîte sécurité/DPO + alerting Grafana. Aucune donnée patient identifiante dans les alertes (user_id, IP, compteurs, identifiant d'intervention uniquement).

## 7. Procédure en cas de dépassement (à valider)

1. Alerte + journalisation horodatée (preuve).
2. Triage en heures ouvrées : légitime / compte compromis / IP inhabituelle.
3. Si suspect : suspension du compte concerné (pas du service global), forçage de déconnexion.
4. Notification DPO + client. En cas de violation de données de santé avérée, évaluer la notification CNIL sous 72 h (DPO).
5. Post-mortem et ajustement des seuils.

Pas de coupure automatique du service (un dispositif indisponible sur faux positif a un impact patient). Coupure réservée à un signal d'attaque actif avéré, décision DPO.

## 8. Décisions à acter en comité

| # | Décision | Recommandation | Responsable |
|---|---|---|---|
| D1 | Source primaire d'identité | Journal applicatif `sensitive` enrichi | Tech |
| D2 | Mesure de volume | IIS (`sc-bytes`) + Traefik, sans plugin payant | Tech + AVA6 |
| D3 | Centralisation des logs | Loki/Grafana, agents 2 zones ; ou pile existante | Tech + AVA6 |
| D4 | Seuils | Multi-critères par user/IP, calibrés sur baseline | Sécurité + métier |
| D5 | Plage de réaction | Détection 24/7, réaction 08h-20h, pas d'astreinte | Direction |
| D6 | Action sur dépassement | Suspension compte, pas coupure service | DPO + Direction |
| D7 | WAF / géoblocage | Chantiers distincts, pas dans ce périmètre | Sécurité |
| D8 | Rétention des traces | ≥ durée légale, chiffrée, intègre | DPO |
| D9 | Périmètre = AVA6 seul | Valider que la zone IA OVH ne traite que de l'anonymisé (sinon réintégrer) | DPO + Tech |

## 9. Effort et séquencement

| Étape | Action | Effort | Dépendance |
|---|---|---|---|
| 1 | Enrichir canal `sensitive` (user, IP, octets) via EventSubscriber | S (app) | aucune |
| 2 | Activer les champs W3C IIS (AVA6) | XS (AVA6) | aucune |
| 3 | Centraliser les logs AVA6 (agent + Loki/Grafana) | M (infra) | espace à dimensionner AVA6 |
| 4 | Router `sensitive` vers le collecteur + rétention chiffrée | S | étape 3 |
| 5 | Définir et activer les règles d'alerte | S | étapes 3-4 |
| 6 | Calibrer les seuils sur baseline | continu | étape 5 |

Étapes 1 et 2 livrables immédiatement, sans dépendance AVA6, et constituent déjà la traçabilité demandée. Seul vrai coût récurrent : la centralisation/rétention (étape 3).

## 10. Brouillon de réponse à AVA6 (à valider en comité)

> Merci pour ces pistes. Notre analyse à partir de l'architecture en place (Windows Server 2022 / IIS / PHP-Symfony chez vous pour le métier, zone IA conteneurisée chez OVH) :
>
> 1. Le log IIS (format W3C) nous convient pour mesurer le volume : il enregistre déjà les octets servis (`sc-bytes`) par URL et par IP. Pouvez-vous confirmer que les champs `c-ip`, `cs-username`, `cs-uri-stem`, `cs-uri-query`, `sc-status`, `sc-bytes`, `time-taken` sont activés sur les sites prod IIS, et préciser rétention et emplacement de ces journaux ? Pas de module tiers nécessaire a priori.
>
> 2. Pour identifier qui télécharge (IIS et un WAF ne voient pas l'utilisateur applicatif, l'auth étant en session Symfony), nous enrichissons notre journal applicatif dédié (utilisateur, IP, volume) côté code. C'est la source fiable pour détecter un téléchargement massif par un compte. L'IP cliente réelle nous est déjà transmise via `X-Forwarded-For`, que l'application exploite.
>
> 3. Détection automatisée 24/7, réaction en heures ouvrées : nos plateformes ne servent qu'en 08h-20h, donc pas d'astreinte 24/7 nécessaire de votre côté. Toute activité hors de cette plage est traitée comme une anomalie.
>
> 4. En cas de dépassement : alerte et revue humaine, suspension éventuelle du compte concerné, pas de coupure automatique du service.
>
> 5. WAF et géoblocage : à étudier comme renforcement périmétrique distinct, pas comme réponse à ce besoin précis.
>
> Pouvez-vous chiffrer la brique de centralisation/rétention des logs de la zone métier (IIS + journal applicatif), et confirmer le point 1 ?

## 11. Points ouverts / à vérifier

- **Anonymisation OVH** : confirmer que les données envoyées à la zone IA sont anonymisées de façon irréversible (et non seulement pseudonymisées via un `anonymousCode` réversible en base), et que les fichiers/DICOM sont dé-identifiés dans leurs en-têtes (aucun strip de tags DICOM trouvé dans le code). Si non, réintégrer la zone OVH au périmètre.
- Définition réelle du service `monolog.formatter.sensitive` (référencé mais non localisé dans `config/services.yaml`) : confirmer existence et absence de donnée patient en clair.
- Valeur `TRUSTED_PROXIES` en prod = IP du reverse proxy AVA6.
- Volume de logs estimé (pour dimensionner la rétention) à fournir à AVA6.
- Durée légale de rétention des traces d'accès à valider avec le DPO.

## Annexes (ce dossier)

- `docs/00-architecture-reference.md` : architecture hybride actuelle.
- `docs/01-flux-telechargement.md` : base factuelle du flux de téléchargement.
- `reponse-ava6/challenge-ava6.md` : critique détaillée des propositions AVA6.
- `tracabilite/strategie-3-couches.md` : conception de la solution.
- `alerting/seuils-actions.md` : seuils, alertes, procédure.
