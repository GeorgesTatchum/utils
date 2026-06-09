# Architecture actuelle de référence (hybride)

Source : `Documentation+d'Architecture+Technique+_+Infrastructure+Hybride+(OneSoftware).doc` (placé dans ce dossier). Document faisant foi pour l'architecture **en production aujourd'hui**. Prévaut sur les documents `architecture/` du dépôt (`oo-infra`, Phase 2 v2), qui décrivent une cible de migration et non la prod actuelle.

## Vue d'ensemble

Architecture hybride à deux zones, séparant la logique métier (Windows) des charges de calcul IA (Linux/Docker).

```
                          Internet (clients / chirurgiens)
                              │                      │
                  HTTPS 443   │                      │  HTTPS 443 (accès direct IA/API)
                              ▼                      ▼
            ┌──── Zone AVA6 (métier) ────┐   ┌──── Zone OVH (calcul IA) ────┐
            │  Firewall AVA6 (L3/L4)     │   │  Traefik (edge / LB Docker)  │
            │  Reverse Proxy AVA6        │   │                              │
            │   (terminaison SSL,        │   │  Serveur Debian              │
            │    routage prod/preprod)   │   │   - API Symfony légère       │
            │                            │   │   - Messenger (queue)        │
            │  Windows Server 2022       │   │                              │
            │   - IIS (web + assets)     │   │  Serveur Ubuntu              │
            │   - PHP/Symfony (FastCGI)  │   │   - Worker (consume queue)   │
            │   - Angular 2D/3D inclus   │   │   - Docker IA (à la demande, │
            │     (Include Path, pas de  │   │     détruit après traitement)│
            │      Node.js séparé)       │   │                              │
            │   - MariaDB locale         │   │  Réseau privé Debian<->Ubuntu│
            │     (loopback 3306)        │   └──────────────────────────────┘
            │  Prod et Preprod isolés    │              ▲
            └────────────┬───────────────┘              │
                         └───── HTTPS 443 (flux critique : ───┘
                                app métier demande un traitement IA)
```

## Zone AVA6 (principale, métier)

- **Firewall AVA6** : filtrage niveau 3/4 en entrée.
- **Reverse Proxy AVA6** : terminaison SSL, routage par nom de domaine (`prod.domain.com` vs `preprod.domain.com`).
- **Nœuds Windows Server 2022** : architecture monolithique répliquée, prod et preprod isolés.
  - **Serveur web : IIS** (requêtes HTTP, assets statiques).
  - **Couche applicative : PHP/Symfony via FastCGI**. Modules Angular 2D/3D intégrés par Include Path (pas de Node.js séparé).
- **MariaDB** locale sur chaque nœud Windows, accès **loopback 3306 uniquement**, non exposée réseau (isolation forte).

## Zone OVH (calcul IA, asynchrone)

- **Traefik** : edge router / load balancer Docker. Reçoit du **HTTPS direct** (chirurgiens, appels API externes).
- **Serveur Debian** : API Symfony légère + composant Messenger (file d'attente).
- **Serveur Ubuntu** : Worker (consomme la file) + Docker IA (instancie une image par traitement, détruite en fin).
- Réseau privé virtuel entre Debian et Ubuntu.

## Matrice des flux

| Source | Destination | Protocole / Port | Description |
|---|---|---|---|
| Internet (client) | Firewall AVA6 | HTTPS / 443 | Accès à l'application principale |
| Internet (client) | Traefik (OVH) | HTTPS / 443 | Accès direct services IA/API |
| Reverse Proxy AVA6 | IIS (Windows) | HTTP(S) standard | Routage prod/preprod |
| Symfony (Windows) | Traefik (OVH) | HTTPS / 443 | Flux critique : app métier demande un traitement IA |
| Symfony (Windows) | MariaDB (local) | TCP / 3306 | Persistance (loopback interne) |
| Worker (Ubuntu) | Messenger (Debian) | TCP / interne | Polling de la file d'attente |

## Implications pour le monitoring des téléchargements

1. **Les téléchargements de fichiers patients se font sur la zone AVA6** : IIS → PHP/Symfony (FastCGI) → fichier sur stockage local Windows. La couche web concernée est **IIS**, pas nginx.
2. **AVA6 a la main sur la couche web (IIS) et le reverse proxy** ; OneSoftware a la main sur l'application (Symfony) et son journal applicatif.
3. **Périmètre de la traçabilité = zone métier AVA6/IIS** : rapports, DICOM, documents, et sorties d'inférence une fois revenues dans l'app. La **zone IA OVH est hors périmètre** car elle ne traite que des données anonymisées (`anonymousCode` / `patient_hashed_id`).
4. **Réserve à confirmer** : anonymisation irréversible vs pseudonymisation, et dé-identification des en-têtes DICOM envoyés à l'IA (aucun strip de tags trouvé dans le code). Si la donnée OVH n'est pas réellement anonyme, réintégrer la zone OVH au périmètre et vérifier l'hébergement HDS de cette zone.
5. Le reverse proxy AVA6 fait la terminaison SSL : l'IP cliente vue par IIS est celle du reverse proxy sauf si `X-Forwarded-For` est propagé et que Symfony fait confiance à ce proxy (`trusted_proxies`).

## Sources
- `Documentation+d'Architecture+Technique+_+Infrastructure+Hybride+(OneSoftware).doc`
- À recouper avec `01-flux-telechargement.md` (chemin applicatif des downloads, identique quel que soit l'OS car même codebase Symfony)
