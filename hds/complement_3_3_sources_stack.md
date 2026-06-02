# Complément §3.3 — Sources stack technique

Contenu prêt à coller dans le §3.3 du plan original `plan_revu_mensuel.md`, en remplacement du tableau vide actuel.

## Principe rédactionnel

Le §3.3 se limite strictement aux composants déjà nommés en **§2.2 du plan** (frameworks front Angular, runtime Node.js, backend Symfony, base MariaDB, cloud Windows Server, imagerie DICOM et Three.js, dépendances tierces via SBOM), avec l'ajout de **PHP** (runtime backend Symfony) et **Composer** (gestionnaire de dépendances PHP) — composants structurellement indispensables au backend mais non explicitement listés en §2.2 du plan. Recommandation associée : compléter §2.2 du plan pour les nommer (à inscrire en §7 du premier rapport mensuel).

Le §3.3 ne réintroduit pas les sous-bibliothèques applicatives, qui sont couvertes par les scanners CI sur la base du SBOM.

Cette autolimitation a deux objectifs :
- éviter de transformer le plan en inventaire technique exposable en audit externe ;
- garder le plan stable dans le temps (le SBOM évolue, les catégories §2.2 non).

## 3.3 — Tableau de base (format Source | Composant)

Aligné sur le tableau initial du §3.3.

| Source | Composant |
|--------|-----------|
| Angular Security Advisories | Angular (front) |
| Node.js Security | Node.js (runtime front / build) |
| PHP Security Releases + GitHub Advisories `php/php-src` | PHP (runtime backend Symfony) |
| Symfony Security Advisories | Symfony (backend) |
| GitHub Advisories par composant (php/php-src, symfony/*, twig/*, doctrine/*, etc.) + Snyk + Dependabot | Composer (gestionnaire de dépendances PHP) |
| MariaDB Security Releases | MariaDB (base de données) |
| MSRC Security Update Guide | Windows Server (cloud) |
| NEMA DICOM Standard | DICOM (imagerie médicale) |
| Three.js Security Advisories + Releases | Three.js (imagerie médicale) |
| Snyk (scanner SCA en CI) + GitHub Dependabot + Trivy (image) | Dépendances tierces critiques (cf. SBOM) |

## 3.3 — Tableau de raffinement (format Source | URL | Type | Fréquence vérif)

Aligné sur le format des §3.1 et §3.2 du plan.

| Source | URL | Type | Fréquence vérif |
|--------|-----|------|-----------------|
| Angular Security Advisories | https://github.com/angular/angular/security/advisories | API | Mensuelle |
| Node.js Security | https://nodejs.org/en/blog/vulnerability | RSS | Mensuelle |
| PHP Security Releases | https://www.php.net/ChangeLog-8.php | Web | Mensuelle |
| GitHub Advisories `php/php-src` | https://github.com/php/php-src/security/advisories | API | Mensuelle |
| Symfony Security Advisories | https://symfony.com/blog/category/security-advisories | RSS | Mensuelle |
| MariaDB Security Releases | https://mariadb.org/about/security/ | RSS | Mensuelle |
| MSRC Security Update Guide (Patch Tuesday) | https://msrc.microsoft.com/update-guide/ | RSS / API | Mensuelle |
| NEMA DICOM Standard Newsroom | https://www.dicomstandard.org/news | RSS | Mensuelle |
| Recherche NVD filtrée DICOM | https://nvd.nist.gov/vuln/search?query=dicom | Web | Trimestrielle |
| Three.js Security Advisories | https://github.com/mrdoob/three.js/security/advisories | API | Mensuelle |
| Three.js Releases | https://github.com/mrdoob/three.js/releases | RSS | Mensuelle |
| Dépendances tierces — Snyk SCA (en workflow GitHub Actions) | https://snyk.io | API / CLI | À chaque build + scan quotidien |
| Dépendances tierces — GitHub Dependabot | (forge GitHub `oneorthomedical`) | API | Continue (push) |
| Dépendances tierces — Trivy image | (GitHub Actions) | CLI | À chaque build image |

## Articulation entre canaux (source primaire vs scanners)

Les sources éditeur (Angular Security Advisories, Symfony Security Advisories, Three.js, GitHub Advisories par composant) restent les **sources primaires autoritaires** pour la qualification d'une vulnérabilité (description, CVSS, vecteur, version corrigée).

Snyk, GitHub Dependabot, Trivy et — à terme — Dependency-Track sont des **canaux de détection automatisée**, complémentaires, qui :
- accélèrent le signalement (push push push contre lecture mensuelle des advisories),
- couvrent les dépendances transitives qui ne sont pas dans la liste §2.2 du plan,
- offrent une défense en profondeur (si un canal manque une CVE, les autres rattrapent).

En cas de divergence entre canaux :
- la **source éditeur fait foi sur la qualification** de la vulnérabilité,
- les **canaux scanners font foi sur l'applicabilité** au stack OneSoftware (via croisement SBOM).

## Tableau de couverture par source §3.3

Colonnes : ce que chaque canal automatisé couvre ou non par rapport à chaque source §3.3 nommée.

| Source §3.3 | Snyk (actuel) | Dependency-Track (futur) | GitHub Dependabot | Trivy (image) | Commentaire |
|-------------|---------------|--------------------------|-------------------|---------------|-------------|
| Angular Security Advisories | ✔ | ✔ (via SBOM CycloneDX) | ✔ | partiel (si dans image) | Couverture forte multi-canal sur packages npm `@angular/*` |
| Node.js Security | ✗ | ✗ | ✗ | ✔ (si Node embarqué dans image) | Le binaire Node n'est pas une dépendance npm, suivi uniquement par source éditeur et Trivy image |
| PHP Security Releases + GitHub Advisories `php/php-src` | ✗ | ✗ | ✗ | ✔ (si PHP embarqué dans image) | Idem Node, le binaire PHP n'est pas suivi par scanner SCA |
| Symfony Security Advisories | ✔ | ✔ (via SBOM CycloneDX) | ✔ | ✗ | Couverture forte multi-canal sur packages Composer `symfony/*` |
| GitHub Advisories Composer (par composant) | ✔ | ✔ (via SBOM CycloneDX) | ✔ | ✗ | Sources éditeur (Symfony, Twig, Doctrine, php/php-src) déjà suivies individuellement ; Packagist non listé car simple agrégateur de GitHub Advisories + FriendsOfPHP, déjà couvert par Snyk + Dependabot |
| MariaDB Security Releases | ✗ | ✗ | ✗ | partiel (si embarqué dans image) | Serveur de base hors scope SCA, source éditeur uniquement |
| MSRC Security Update Guide (Windows Server) | ✗ | ✗ | ✗ | ✗ | OS hôte hors scope, source éditeur uniquement |
| NEMA DICOM Standard + recherche NVD DICOM | ✗ | ✗ | ✗ | ✗ | Standard, pas un package |
| Three.js Security Advisories + Releases | ✔ | ✔ (via SBOM CycloneDX) | ✔ | ✗ | Couverture forte multi-canal sur package npm `three` |
| Dépendances tierces (cf. SBOM) | ✔ | ✔ | ✔ | ✔ (côté OS image) | Cœur de couverture des scanners SCA, sur toute la couche dépendances applicatives |

**Lecture du tableau** :
- Pas d'effet sur les sources éditeur des runtimes (PHP, Node) ni des SGBD/OS : ces composants doivent rester suivis via les advisories éditeur officiels, aucun scanner SCA ne les couvre.
- Forte redondance sur les dépendances applicatives (Angular, Symfony, Three.js, toutes les bibliothèques tierces) : 3 à 4 canaux convergent sur les mêmes packages, d'où la nécessité de déduplication décrite en méthodologie premier rapport §2.
- Dependency-Track, une fois déployé, n'ajoute pas de catégorie nouvelle par rapport à Snyk : il prend simplement la place de Snyk avec souveraineté des données. La couverture reste la même.

## Note sur "Dépendances tierces critiques (cf. SBOM)"

La granularité fine des sous-bibliothèques applicatives (couches Symfony, Angular et leurs dépendances) est portée par :
- le **SBOM** généré à chaque build par Syft et par Trivy (image), au format CycloneDX (document interne classifié, non reproduit dans le plan),
- **Snyk** en workflow GitHub Actions, scanner SCA opérationnel actuel sur les lockfiles backend (`composer.lock`) et front (`package-lock.json` / `yarn.lock`),
- **GitHub Dependabot** côté forge, alertes continues sur les lockfiles trackés,
- **Trivy** côté image conteneur de production.

Toute alerte issue de ces outils est versée dans le backlog Jira `SEC-INBOX` pour triage à la consolidation mensuelle. Le plan ne nomme pas individuellement les bibliothèques.

**Évolution prévue** : déploiement futur de **Dependency-Track** (instance self-hosted) pour consommer les SBOM CycloneDX produits par Syft et cyclonedx-php/cyclonedx-js, en remplacement de Snyk sur le volet SCA. Objectifs : souveraineté des données SBOM (qui ne quittent plus l'environnement OneOrtho), audit trail 7 ans contrôlé en interne, cohérence avec la chaîne SBOM déjà en place. Action à ouvrir en §7 du premier rapport mensuel.

**Note sur les outils CLI natifs (`composer audit`, `npm audit`, `yarn audit`)** : ces commandes restent disponibles en local pour les développeurs et peuvent être lancées ad-hoc lors d'une investigation. Elles ne sont pas listées en §3.3 du plan car elles font doublon avec Snyk côté CI (mêmes bases de données consultées) et avec Dependabot côté forge. Conserver une seule porte d'entrée dans le plan évite le surcompte d'items lors de la consolidation mensuelle.
