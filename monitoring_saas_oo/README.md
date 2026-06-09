# Monitoring SaaS OneOrtho

Définition et mise en oeuvre du monitoring de la plateforme SaaS, approche sécurité du SI et rentabilité des décisions.

## Sujet en cours : traçabilité et alerting des téléchargements de fichiers patients

Contexte : constat de faille permettant le téléchargement de données patients via requêtes applicatives. Demande : tracer les téléchargements, mesurer le volume, alerter sur comportement inhabituel (ex. > 5 Go/jour). Périmètre : production uniquement. Note AVA6 (hébergeur infra) reçue et à challenger.

### Document de synthèse (comité technique)

**`comite-technique-tracabilite-telechargements.md`** : document unique et autoportant pour traiter la question en comité technique avant retour à AVA6 (contexte, analyse, solution, décisions à acter, brouillon de réponse AVA6). Les fichiers ci-dessous en sont les annexes détaillées.

### Documents

| Dossier | Fichier | Contenu |
|---|---|---|
| `docs/` | `00-architecture-reference.md` | Architecture hybride actuelle (Windows/IIS AVA6 + IA OVH), document faisant foi |
| `docs/` | `01-flux-telechargement.md` | Base factuelle : par où passe un téléchargement, preuves code, limites de l'existant |
| `reponse-ava6/` | `challenge-ava6.md` | Critique point par point des propositions AVA6 + brouillon de réponse |
| `tracabilite/` | `strategie-3-couches.md` | Solution recommandée : applicatif + IIS/Traefik + agrégation/alerting |
| `alerting/` | `seuils-actions.md` | Seuils multi-critères, canaux, procédure de réaction |

### Conclusions clés (mises à jour avec l'architecture réelle)

1. Architecture **hybride** : la prod métier (téléchargements patients) est sur **Windows Server 2022 + IIS + PHP/Symfony chez AVA6** ; la zone IA est conteneurisée chez OVH (Traefik/Debian/Ubuntu). La stack Debian/Docker du dépôt `oo-infra` est une **cible de migration, pas la prod actuelle**.
2. Les fichiers patients sont **servis à travers PHP** (`BinaryFileResponse`) : l'identité (utilisateur, intervention) n'existe **qu'au niveau applicatif**. IIS, le firewall ou un WAF ne voient pas « qui ».
3. Le référentiel « Windows/IIS » d'AVA6 était **correct**. Et **IIS journalise nativement les octets** (`sc-bytes`) : la mesure de volume côté serveur web est possible sans plugin payant. Mais elle reste aveugle à l'utilisateur.
4. L'application **journalise déjà** les téléchargements sensibles (canal Monolog `sensitive`). C'est la source d'identité à enrichir (utilisateur, IP, octets) et à centraliser. On combine : identité via l'app, volume via IIS.
5. Le seuil unique « 5 Go/jour » est trop grossier : seuils **par utilisateur et par IP**, avec la diversité d'interventions accédées comme meilleur indicateur d'exfiltration.
6. Usage des plateformes en **08h-20h** : détection automatisée 24/7, réaction en heures ouvrées, **pas d'astreinte 24/7**. Toute activité hors plage est une anomalie forte (règle OFFHOUR). **Pas de coupure automatique** du service ; suspension ciblée du compte.
7. **IP cliente : OK.** Le reverse proxy AVA6 propage `X-Forwarded-For` et l'app est câblée (`trusted_proxies`, `framework.yaml:24`). Vérifier seulement la valeur `TRUSTED_PROXIES` en prod.
8. Périmètre = **zone métier AVA6 uniquement**. La zone IA OVH est hors périmètre car elle ne traite que des données anonymisées (à confirmer : anonymisation irréversible vs pseudonymisation, dé-identification DICOM).

### Actions livrables immédiatement (sans dépendance AVA6)

- Enrichir le canal `sensitive` (utilisateur, IP, taille) via un EventSubscriber `kernel.response`.
- Faire activer les champs W3C IIS (`sc-bytes`, `c-ip`, `cs-uri-stem`...) côté AVA6.

### À cadrer avec AVA6 / DPO

- Brique de centralisation des logs de la zone métier AVA6 et rétention chiffrée (seul coût récurrent réel).
- Confirmation des champs W3C IIS activés en prod (`sc-bytes`, `c-ip`, `cs-uri-stem`...).
- Valeur de `TRUSTED_PROXIES` en prod = IP du reverse proxy AVA6 (à vérifier, simple config).
- Procédure de suspension de compte.
- Confirmation de l'anonymisation des données envoyées à la zone IA OVH (sinon réintégrer au périmètre).
- Géoblocage éventuel (Firewall/RP AVA6 pour le métier).

## Conventions de ce dossier

Sortie en `.md`, un sous-dossier par sujet, concis et sourcé (chemins de fichiers, références normatives). Contexte MDR 2017/745 et IEC 62304 : aucune donnée patient identifiante dans les traces ni les exemples.
