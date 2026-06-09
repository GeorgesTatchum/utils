# Flux de téléchargement de fichiers patients (base factuelle)

Objectif : établir où passe réellement un téléchargement avant de décider où l'instrumenter. Tout le reste découle de ces faits.

Architecture de référence : `00-architecture-reference.md`. La prod métier tourne sur **Windows Server 2022 + IIS + PHP/Symfony FastCGI chez AVA6** (et non sur la stack Debian/Docker du dépôt `oo-infra`, qui est une cible de migration et la zone de calcul IA OVH).

## 1. Chemin d'un téléchargement (zone métier AVA6)

```
Navigateur ──HTTPS──> Firewall AVA6 ──> Reverse Proxy AVA6 (SSL) ──> IIS ──FastCGI──> PHP/Symfony
                                                                                          │
                                                  InterventionFileSystem readFile (DSN local: sur disque Windows)
                                                                                          │
                                                                    tmp local + BinaryFileResponse
                                                                                          │
Navigateur <──────────────────────── octets du fichier <──────────────────────────────────┘
```

Constat clé : **le fichier transite par PHP**, il n'y a pas de redirection vers une URL présignée. Le contrôleur lit le fichier via l'abstraction `InterventionFileSystem` (DSN `local:` aujourd'hui, sur le disque du nœud Windows ; `aws+s3:` est la cible de migration non encore en prod), le copie dans un répertoire temporaire, puis le sert avec `BinaryFileResponse` + `deleteFileAfterSend()`.

Conséquence sur le choix de la couche web : **IIS** est le serveur web concerné. IIS journalise nativement les octets envoyés (`sc-bytes`), l'URI, le statut et l'IP au format W3C, donc la mesure de volume côté serveur web est possible (contrairement à ce qui était supposé pour nginx). Mais IIS ne connaît pas l'utilisateur applicatif (auth gérée en session Symfony, pas par IIS).

Conséquences directes :
- Le volume téléchargé est mesurable à **3 niveaux** : applicatif (taille du fichier servi), nginx (`$body_bytes_sent`), réseau (Traefik / firewall N7).
- L'**identité** (utilisateur, intervention, type de fichier) n'existe **qu'au niveau applicatif**. Un WAF/firewall voit un volume sur une URL et une IP, pas « qui » ni « quel patient ».

## 2. Routes de téléchargement identifiées

| Route (méthode GET) | Contrôleur | Donnée |
|---|---|---|
| `/interventions/hip/{id}/download/{fileType}` | `Module3DHip/.../EntryDataFileController.php` | DICOM, radio, fichiers source |
| `/interventions/hip/{id}/report/download` | `Module3DHip/.../ReportDownloadController.php` | Rapport PDF |
| `/interventions/knee/{id}/document/{type}/download` | `Module3DKnee/.../DocumentDownloadController.php` | Prescription, certificat, étiquettes |
| `/interventions/knee/{id}/download/{fileType}` | `Module3DKnee/.../EntryDataFileController.php` | DICOM, radio, fichiers source |
| `/interventions/hip/{id}/report/download` (2D) | `Module2DHip/.../ReportDownloadController.php` | Rapport PDF |
| accès thème / documentation | `src/Controller/ThemeImageCustomAccessController.php`, `DocumentationCustomAccessController.php` | non patient |
| sorties IA (ré-associées) | `src/Controller/ArtificialIntelligence/ExecutionController.php`, `ProcessOutputDownloadedSubscriber.php` | servies sur AVA6 |

Toutes les routes patient sont protégées par des Voters (`isGranted`) et par `EntryDataFileDownloadVoter` / `InterventionFileVoter`. Le contrôle d'accès existe ; ce qui manque est la **traçabilité exploitable et l'alerting**.

Périmètre : tous ces téléchargements (y compris les sorties d'inférence une fois revenues dans l'app) sont servis par **IIS/Windows (AVA6)**. La **zone IA OVH est hors périmètre** car les données qui y transitent sont anonymisées (`anonymousCode` / `patient_hashed_id`). Réserve à confirmer : anonymisation irréversible vs pseudonymisation, et dé-identification des en-têtes DICOM.

## 3. Traçabilité applicative déjà en place

Un canal Monolog dédié `sensitive` journalise déjà les accès et téléchargements sensibles. 20 points d'appel `sensitiveLogger->info(...)` recensés, dont les téléchargements ci-dessus.

Exemples (preuves) :
- `Module3DHip/.../ReportDownloadController.php:69` : `Intervention {identifier}'s report downloaded`
- `Module3DHip/.../EntryDataFileController.php:61` : `Intervention {identifier}'s {fileType} file downloaded`
- `Module3DKnee/.../DocumentDownloadController.php:85` : idem
- accès donnée patient : `.../PatientController.php:74` : `Access to a patient's data`

Configuration : `saas_local/app/config/packages/prod/monolog.yaml:46-52`
```yaml
sensitive_logs:
    type: rotating_file
    max_files: 366            # rétention ~1 an
    path: '%kernel.logs_dir%/sensitive/sensitive_%kernel.environment%.log'
    channels: [ 'sensitive' ]
    level: info
    formatter: 'monolog.formatter.sensitive'
```

## 4. Limites de l'existant (à corriger pour répondre à la demande)

1. **Pas de volume côté app** : le log sensible enregistre « fichier téléchargé » mais pas la taille en octets. Impossible de cumuler un volume/jour côté applicatif sans l'ajouter. (IIS, lui, logge `sc-bytes` : voir couche 2 de la stratégie.)
2. **Pas d'identité de l'auteur** : seul l'identifiant d'intervention est journalisé, pas l'utilisateur authentifié ni l'IP. Ni le log applicatif ni le log IIS ne portent aujourd'hui l'utilisateur (auth en session Symfony, donc `cs-username` IIS vide). Or la demande vise à détecter un comportement d'exfiltration, donc à corréler par utilisateur et par IP : l'enrichissement applicatif est obligatoire.
3. **Écriture sur fichier local au nœud** : le canal sensible écrit dans `%kernel.logs_dir%/sensitive/` sur le disque du nœud Windows. Risque pour la traçabilité (perte si réinstallation du nœud, pas de centralisation, pas d'horodatage scellé). À centraliser et sécuriser. Point de conformité HDS / IEC 62304. (Le même point se posera, autrement, après migration Docker stateless.)
4. **IP cliente : résolu côté transit, à confirmer côté valeur prod.** Le reverse proxy AVA6 propage bien l'IP cliente via `X-Forwarded-For` (confirmé), et Symfony est câblé pour la lire (`framework.trusted_proxies`, `framework.yaml:24`, commentaire « the IP address of AVA6 proxy »). Reste à garantir que la variable `TRUSTED_PROXIES` vaut **en prod l'IP/CIDR du reverse proxy AVA6** (le `.env` local porte `127.0.0.1`, valeur de dev). Sans cela, `Request::getClientIp()` renverrait l'IP du proxy. Point de configuration, pas de blocage.
5. **`monolog.formatter.sensitive`** : service formateur référencé mais non localisé dans `config/services.yaml`. À confirmer (définition + masquage des données).

## 5. Périmètre « production uniquement »

La prod et la preprod sont des nœuds Windows isolés (`00-architecture-reference.md`). Toute instrumentation doit être conditionnée à l'environnement (`APP_ENV=prod`, nœud prod) pour ne pas brouiller les seuils avec le trafic de test.

La couche applicative (Symfony, canal `sensitive`, `BinaryFileResponse`) est **identique quel que soit l'OS** : la solution applicative reste valable aujourd'hui (Windows/IIS) comme après la migration cible (Linux/Docker). Seule la couche web change (IIS aujourd'hui, nginx demain), ainsi que l'outillage de collecte (agent Windows aujourd'hui).

## Sources
- Code : `saas_local/app/` (contrôleurs et `config/packages/prod/monolog.yaml`)
- Architecture actuelle : `00-architecture-reference.md` (Windows/IIS AVA6 + zone IA OVH)
- Cible de migration (non en prod) : `architecture/2026-05-05_phase2_v2_action_plan.md`, `architecture/decisions/0001-stateful-to-stateless-migration.md`
