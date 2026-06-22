# Modèle de mail à AVA6 — Ticket 3 (RCE Critical Windows Server)

À envoyer après avoir testé un échantillon de serveurs. Le mail demande à AVA6 de **confirmer le statut de correctif sur l'ensemble du parc** (OneOrtho n'a vérifié qu'un échantillon et n'a pas la visibilité complète) et d'appliquer la mise à jour là où elle manque. Adapter les champs entre {{...}}.

---

**À** : {{contact exploitation AVA6}}
**Cc** : {{Responsable Numérique OneOrtho}}, {{équipe infrastructure}}
**Objet** : [SÉCURITÉ – Priorité haute] Confirmation du niveau de correctif Windows Server — Patch Tuesday mai 2026, 6 RCE Critical (réf. CICD-169)

---

Bonjour,

Dans le cadre de notre revue mensuelle de sécurité, nous avons identifié 6 vulnérabilités critiques d'exécution de code à distance (RCE) corrigées par le Patch Tuesday Microsoft du 12/05/2026, affectant Windows Server.

De notre côté, nous avons testé **un échantillon de {{3}} serveurs** (un par version Windows présente) afin d'évaluer le niveau de correctif. Ces relevés sont indicatifs et ne couvrent pas l'ensemble du parc, dont vous avez la visibilité complète.

**Résultats de notre échantillon :**

| Serveur testé | Version Windows Server | Build relevé | Build cible (≥) | Constat |
|---------------|------------------------|--------------|-----------------|---------|
| {{SRV-XXX-01}} | Windows Server 2016 | {{14393.xxxx}} | 10.0.14393.9140 | {{Patché / Non patché}} |
| {{SRV-XXX-02}} | Windows Server 2019 | {{17763.xxxx}} | 10.0.17763.8755 | {{Patché / Non patché}} |
| {{SRV-XXX-03}} | Windows Server 2022 | {{20348.xxxx}} | 10.0.20348.5139 | {{Patché / Non patché}} |

**Nous vous demandons :**
1. De **confirmer, pour l'ensemble des serveurs Windows du parc**, s'ils disposent ou non du correctif — c'est-à-dire un build supérieur ou égal au build cible de leur version (tableau de référence ci-dessous).
2. D'**appliquer la mise à jour cumulative** correspondante sur tout serveur dont le build est inférieur au build cible, avec redémarrage planifié et sauvegarde/snapshot préalable.
3. De nous **retourner, par serveur, le build (`CurrentBuild.UBR`)** constaté — afin que nous tracions le statut de l'ensemble du parc dans notre dossier de sécurité.

**Tableau de référence — KB cumulative et build corrigé par version :**

| Version Windows Server | KB cumulative (mai 2026) | Build cible (≥) |
|------------------------|--------------------------|-----------------|
| Windows Server 2016 | KB5087537 | 10.0.14393.9140 |
| Windows Server 2019 | KB5087538 | 10.0.17763.8755 |
| Windows Server 2022 | KB5087545 | 10.0.20348.5139 |
| Windows Server 2022 23H2 | KB5087541 | 10.0.25398.2330 |
| Windows Server 2025 | KB5087539 | 10.0.26100.32860 |

**Criticité** : 6 CVE de gravité Critical (RCE), exposition Internet via le portail applicatif (IIS).
CVE concernées : CVE-2026-32161, CVE-2026-35421, CVE-2026-40402, CVE-2026-40403, CVE-2026-41089, CVE-2026-41096.
**Échéance souhaitée** : correctif appliqué et statut confirmé avant le 22/06/2026.
**Fenêtre de maintenance** : {{date / plage horaire hors usage clinique}} — merci de confirmer ou de proposer une alternative.

Cette demande est tracée sous la référence CICD-169 (revue Threat Intelligence 2026-05). Nous restons disponibles pour toute précision et pour valider conjointement le résultat.

Cordialement,
{{Prénom NOM}}
{{Fonction — Service Numérique OneOrtho}}
{{coordonnées}}

---

## Notes d'usage

- Méthode de relevé (pour info ou à transmettre à AVA6) — identique à la procédure §4 :
  `Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' | Select ProductName, CurrentBuild, UBR`
- L'échantillon testé sert d'indice ; la confirmation parc complet relève d'AVA6 (exploitant), qui a la visibilité et l'accès sur l'ensemble des serveurs.
- Conserver ce mail (envoi + réponse AVA6 avec les builds par serveur) comme pièce probante du Ticket 3 et du rapport mensuel `cyber/may2026/`.
- Aucune donnée patient ni identifiant sensible ; n'inclure que les noms d'hôtes nécessaires.
- Selon la réponse d'AVA6 :
  - parc déjà à jour → clore le Ticket 3 en « déjà corrigé », joindre les builds confirmés ;
  - serveurs non patchés → suivre l'application puis vérifier les builds post-patch avant clôture.
