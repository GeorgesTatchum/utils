# Procédure — Configuration de l'agrégateur RSS pour la veille Threat Intelligence

Document opérationnel pour mettre en place l'agrégateur RSS qui centralise les sources §3.1, §3.2 et §3.3 du plan de revue mensuelle.

## 1. Choix de l'agrégateur

Recommandation : **FreshRSS**, open source self-hosted.

Pourquoi :
- souveraineté des données (aucun service tiers n'a la liste des sources que tu surveilles),
- multi-utilisateurs (partage possible entre membres du Service Numérique),
- API native pour automatisation (export, recherche par tag),
- déploiement simple via Docker,
- continuité d'exploitation maîtrisée (pas de risque qu'un SaaS ferme ou change ses CGU).

Alternative SaaS si self-hosting indisponible : **Feedly** (gratuit pour usage de base, version Pro pour annotations, partage limité) ou **Inoreader** (plus orienté pro). Inconvénient : la liste des sources est connue d'un tiers. Tolérable pour ce cas d'usage (sources toutes publiques) mais moins aligné sur le profil DM.

## 2. Déploiement FreshRSS (Docker)

### 2.1 Prérequis

- serveur Linux interne (VM ou conteneur sur un host existant),
- Docker + Docker Compose installés,
- nom de domaine interne ou IP fixe accessible aux membres du Service Numérique,
- certificat TLS (Let's Encrypt interne ou autorité certificat interne).

### 2.2 docker-compose minimal

```yaml
services:
  freshrss:
    image: freshrss/freshrss:latest
    container_name: freshrss
    restart: unless-stopped
    environment:
      TZ: Europe/Paris
      CRON_MIN: '*/30'
    volumes:
      - ./data:/var/www/FreshRSS/data
      - ./extensions:/var/www/FreshRSS/extensions
    ports:
      - "8080:80"
```

`CRON_MIN: '*/30'` = rafraîchissement des flux toutes les 30 minutes. Adapter selon besoin (15 pour réactivité accrue, 60 pour charge réduite).

### 2.3 Mise en place TLS

Reverse-proxy (Nginx ou Traefik) en frontal pour exposer FreshRSS en HTTPS. Indispensable si l'instance contient des comptes nominatifs.

### 2.4 Premier démarrage

1. Accéder à `https://freshrss.interne.oneortho/` (ou IP).
2. Suivre l'assistant : choix langue (FR), SGBD (SQLite suffisant pour < 10 utilisateurs, sinon MariaDB), compte administrateur.
3. Créer un compte par membre habilité (DevSecOps, Responsable Numérique).

### 2.5 Sauvegarde

- snapshot du volume `./data` quotidien (le dossier `data` contient toute la configuration + l'historique des items).
- export OPML hebdomadaire vers un emplacement séparé (réimport facile en cas de perte).

## 3. Organisation des catégories

Créer dans FreshRSS les catégories suivantes (correspondance directe avec les sections du plan) :

- `1-Sources génériques` (§3.1 du plan)
- `2-Sources santé` (§3.2)
- `3-Stack — Frameworks et runtimes` (§3.3, composants nommés)
- `3-Stack — Imagerie médicale` (§3.3, DICOM et Three.js)
- `3-Stack — Infrastructure et bases` (§3.3, MariaDB et OS)
- `3-Stack — Outils CI/CD et scanners` (Snyk, GitHub, etc.)
- `4-Réservé veille concurrentielle / actualités secteur` (optionnel)

L'ordre alphabétique est important : FreshRSS trie les catégories par nom.

## 4. Liste des flux à ajouter

### 4.1 Sources génériques (§3.1)

| Source | URL du flux | Catégorie |
|--------|-------------|-----------|
| CISA KEV Catalog | https://www.cisa.gov/sites/default/files/feeds/known_exploited_vulnerabilities.xml | 1-Sources génériques |
| CERT-FR avis | https://www.cert.ssi.gouv.fr/avis/feed/ | 1-Sources génériques |
| CERT-FR alertes | https://www.cert.ssi.gouv.fr/alerte/feed/ | 1-Sources génériques |
| NVD CVE recent | https://nvd.nist.gov/feeds/xml/cve/misc/nvd-rss.xml | 1-Sources génériques |
| GitHub Security Advisories (filtre par écosystème, voir §6.1) | (variable) | 1-Sources génériques |

### 4.2 Sources santé (§3.2)

| Source | URL du flux | Catégorie | Commentaire |
|--------|-------------|-----------|-------------|
| FDA Safety Communications | https://www.fda.gov/medical-devices/safety-communications/rss.xml | 2-Sources santé | |
| CISA ICS Medical Advisories | https://www.cisa.gov/uscert/ncas/alerts.xml | 2-Sources santé | flux global ICS, filtrer "medical" en mots-clés |
| CERT Santé (ANS) | https://esante.gouv.fr/produits-services/cert-sante (vérifier disponibilité RSS sur le portail) | 2-Sources santé | pas de RSS officiel à ce jour — fallback en abonnement mail |
| HHS HC3 | (subscription mail) | 2-Sources santé | pas de RSS — fallback en mail dans une boîte dédiée |
| ENISA Health publications | https://www.enisa.europa.eu/publications/corporate/rss | 2-Sources santé | filtrer "health" |
| ANSM (matériovigilance, hors-scope cyber) | https://ansm.sante.fr/feed | 4-Veille concurrentielle | n'est pas une source cyber, voir note §3.2 du plan |

### 4.3 Stack — Frameworks et runtimes (§3.3)

| Source | URL du flux | Catégorie |
|--------|-------------|-----------|
| Angular Security Advisories | https://github.com/angular/angular/security/advisories.atom | 3-Stack — Frameworks et runtimes |
| Node.js Security | https://nodejs.org/en/feed/vulnerability.xml | 3-Stack — Frameworks et runtimes |
| PHP News (filtrer "Security") | https://www.php.net/news.rss | 3-Stack — Frameworks et runtimes |
| GitHub Advisories `php/php-src` | https://github.com/php/php-src/security/advisories.atom | 3-Stack — Frameworks et runtimes |
| Symfony Security Advisories | https://symfony.com/blog/category/security-advisories/feed | 3-Stack — Frameworks et runtimes |
| Packagist Security Advisories | pas de RSS officiel, voir §6.2 (alternative API ou RSSHub) | 3-Stack — Frameworks et runtimes |

### 4.4 Stack — Imagerie médicale (§3.3)

| Source | URL du flux | Catégorie |
|--------|-------------|-----------|
| NEMA DICOM Standard News | https://www.dicomstandard.org/news/feed | 3-Stack — Imagerie médicale |
| Three.js Security Advisories | https://github.com/mrdoob/three.js/security/advisories.atom | 3-Stack — Imagerie médicale |
| Three.js Releases | https://github.com/mrdoob/three.js/releases.atom | 3-Stack — Imagerie médicale |

### 4.5 Stack — Infrastructure et bases (§3.3)

| Source | URL du flux | Catégorie |
|--------|-------------|-----------|
| MSRC Security Update Guide | https://api.msrc.microsoft.com/update-guide/rss | 3-Stack — Infrastructure et bases |
| MariaDB blog (filtrer Security) | https://mariadb.org/feed/ | 3-Stack — Infrastructure et bases |

### 4.6 Stack — Outils CI/CD et scanners

| Source | URL du flux | Catégorie |
|--------|-------------|-----------|
| Snyk blog Security | https://snyk.io/blog/feed/ | 3-Stack — CI/CD et scanners |
| GitHub Engineering Blog (security tag) | https://github.blog/security/feed/ | 3-Stack — CI/CD et scanners |

## 5. Bonnes pratiques d'usage

- **Marquage** : utiliser les étoiles ou favoris pour marquer les items à traiter à la consolidation mensuelle (ne pas se contenter de "lu/non lu").
- **Filtres** : configurer des règles de mise en surbrillance sur les mots-clés métier (Angular, Symfony, PHP, Three.js, DICOM, MariaDB, Windows Server, Composer). FreshRSS permet ces règles via les "Filtres" dans les paramètres.
- **Export mensuel** : à chaque consolidation, exporter en CSV/OPML les items traités pour archivage en pièce probante du rapport (§7 du template).
- **Revue trimestrielle des sources** : vérifier que tous les flux fonctionnent (FreshRSS signale les flux en erreur dans la sidebar). Réparer ou remplacer les flux cassés.
- **Partage** : créer un compte lecture seule pour le Responsable Numérique pour qu'il consulte la veille sans nécessairement la consommer.

## 6. Cas particuliers et astuces

### 6.1 GitHub Security Advisories par organisation

GitHub n'expose pas un flux Atom unique pour toute une organisation. Deux options :

1. Suivre un flux par repo critique : `https://github.com/<org>/<repo>/security/advisories.atom` (chaque repo public a son flux).
2. Configurer **GitHub Dependabot** côté forge avec notifications mail vers une boîte dédiée et créer un flux RSS depuis cette boîte avec un outil comme **kill-the-newsletter.com** (SaaS gratuit qui transforme un email en RSS — attention exposition, à n'utiliser que pour des mails non sensibles) ou un script interne qui pousse vers FreshRSS via son API.

### 6.2 Packagist Security Advisories

Pas de RSS officiel. Trois solutions :

1. **API Packagist** : `https://packagist.org/api/security-advisories/?packages[]=symfony/symfony` consultée par script en cron interne, qui pousse dans FreshRSS via l'API.
2. **RSSHub** (instance self-hosted) qui sait transformer l'API Packagist en RSS. Voir https://docs.rsshub.app
3. **Confier à Snyk et Dependabot** la surveillance Composer, en sachant que Packagist Security Advisories alimente ces deux services. L'absence du flux RSS Packagist dans FreshRSS reste alors acceptable.

### 6.3 NVD CVE filtré par stack

Le flux `nvd-rss.xml` envoie toutes les CVE publiées (volume très important). Pour filtrer :

- soit créer un filtre FreshRSS sur mots-clés (Symfony, Angular, PHP, etc.) → diminue le bruit,
- soit basculer sur l'**API NVD avec une requête paramétrée** lancée en cron interne qui pousse dans FreshRSS.

### 6.4 Sources sans flux (HHS HC3, H-ISAC)

Abonnement mail vers une boîte dédiée. Conversion email → RSS via kill-the-newsletter ou intégration directe dans FreshRSS via extension. Acceptable pour des sources à faible cadence (quelques items par mois).

## 7. Vérification de la mise en service

Checklist avant de considérer l'agrégateur opérationnel :

- [ ] Instance FreshRSS accessible en HTTPS depuis le réseau interne
- [ ] Comptes des membres habilités créés et connectables
- [ ] Toutes les catégories §3 créées
- [ ] Tous les flux RSS de §4 ajoutés et au moins un item récupéré pour chaque (les flux sans item récent affichent un message d'erreur ou de retard)
- [ ] Filtres de mise en surbrillance configurés sur les mots-clés stack
- [ ] Sauvegarde quotidienne du volume `data` opérationnelle
- [ ] Export OPML hebdomadaire vers emplacement séparé
- [ ] Procédure de réparation d'un flux cassé documentée (au moins en commentaire dans ce fichier)

Une fois ces points cochés, l'agrégateur RSS est utilisable comme entrée principale de la collecte mensuelle (Phase 2 de `methodologie_premier_rapport.md`).

## 8. Note de maintenance

- Les flux RSS référencés ici sont susceptibles d'évoluer (changement d'URL, fermeture). Le DevSecOps fait une **vérification annuelle** (alignée sur la révision annuelle du plan §8) et inscrit toute évolution en §7 du premier rapport mensuel suivant.
- L'ajout d'une nouvelle catégorie de composant en §2.2 du plan déclenche l'ajout d'au moins un flux correspondant dans FreshRSS.
- L'arrêt d'un composant (ex : sortie de Bootstrap 4) déclenche le retrait des flux associés et la mise à jour du tableau §3.3 du plan.
