# Procédure de vérification — Ticket 3 : 6 RCE Critical Windows Server (Patch Tuesday 12/05/2026)

Objet : vérifier si les serveurs Windows du parc disposent déjà du correctif avant d'escalader à AVA6 (hébergeur / exploitant infrastructure) pour application.
Ticket associé : Ticket 3 (`SEC-THREATINTEL-2026-05` / CICD-169). Priorité P2, SLA 22/06/2026.
CVE couvertes : CVE-2026-32161, CVE-2026-35421, CVE-2026-40402, CVE-2026-40403, CVE-2026-41089, CVE-2026-41096.

## 1. Principe

Windows Server (2016 et ultérieurs) applique des **mises à jour cumulatives mensuelles**. Les 6 CVE sont corrigées par une seule KB cumulative par version d'OS. Donc :
- un serveur dont le **build est ≥ au build corrigé** est protégé (qu'il ait reçu la cumulative de mai 2026 OU une cumulative plus récente) ;
- la **comparaison du build** est la preuve la plus fiable (plus robuste que la recherche de la KB exacte, qui est masquée si une cumulative ultérieure a été installée).

## 2. Tableau de référence (cible par version)

Source : export MSRC `Security Updates 2026-06-02-121531pm.csv`.

| Version Windows Server | KB cumulative (mai 2026) | Build corrigé (≥) |
|------------------------|--------------------------|--------------------|
| Windows Server 2016 | KB5087537 | 10.0.14393.9140 |
| Windows Server 2019 | KB5087538 | 10.0.17763.8755 |
| Windows Server 2022 | KB5087545 | 10.0.20348.5139 |
| Windows Server 2022 23H2 | KB5087541 | 10.0.25398.2330 |
| Windows Server 2025 | KB5087539 | 10.0.26100.32860 |

Lecture du build : format `CurrentBuild.UBR` (ex. `20348.5139`). Un serveur est **à jour** si son `CurrentBuild.UBR` est **supérieur ou égal** au build corrigé de sa version.

## 3. Étapes

### Étape 1 — Inventorier les serveurs Windows du parc
Lister chaque serveur concerné et sa version Windows Server. S'appuyer sur l'inventaire infra (ou le demander à AVA6 si l'inventaire n'est pas tenu en interne).

### Étape 2 — Relever le build de chaque serveur
Exécuter sur chaque serveur (ou à distance, cf. §4) et noter `ProductName`, `CurrentBuild`, `UBR`.

### Étape 3 — Comparer au build cible
Pour chaque serveur, comparer `CurrentBuild.UBR` relevé au build corrigé du tableau §2.
- build relevé ≥ build cible → **Patché** (rien à faire).
- build relevé < build cible → **Non patché** → escalade AVA6 (§5).

### Étape 4 — Consolider
Remplir le tableau de relevé (§6) avec la conclusion par serveur.

## 4. Commandes PowerShell

### Sur un serveur (local)
```powershell
# Build complet (CurrentBuild.UBR) + version
Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' |
  Select-Object ProductName, CurrentBuild, UBR

# Vérification ciblée de la KB de mai (si non superseded par une cumulative ultérieure)
Get-HotFix -Id KB5087537,KB5087538,KB5087545,KB5087541,KB5087539 -ErrorAction SilentlyContinue |
  Select-Object HotFixID, InstalledOn
```

### À distance sur plusieurs serveurs (si WinRM disponible)
```powershell
$serveurs = @('SRV-XXX-01','SRV-XXX-02')  # à compléter
Invoke-Command -ComputerName $serveurs -ScriptBlock {
  $v = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
  [PSCustomObject]@{
    Serveur     = $env:COMPUTERNAME
    Produit     = $v.ProductName
    Build       = "$($v.CurrentBuild).$($v.UBR)"
  }
} | Sort-Object Serveur | Format-Table -AutoSize
```

> Note : si l'accès aux serveurs est exclusivement détenu par AVA6, transmettre ces commandes à AVA6 et demander le retour du `CurrentBuild.UBR` par serveur — la vérification reste pilotée par OneOrtho, l'exécution est déléguée.

## 4 bis. Vérification via Zabbix (parc complet)

Intérêt : obtenir le build de **tous** les serveurs Windows en une vue, au lieu d'un échantillon. À privilégier si Zabbix supervise l'ensemble du parc.

### Pré-requis à confirmer
- Agent Zabbix déployé sur **tous** les serveurs Windows concernés.
- Item remontant le build **avec révision (UBR)** effectivement configuré — par défaut Zabbix ne collecte pas l'UBR, il faut l'ajouter (cf. ci-dessous).
- Accès à l'instance Zabbix (préciser si gérée par OneOrtho ou par AVA6).

### Collecte du build complet

Option A — Zabbix agent 2 récent (clé native `registry.data`), 2 items :
```
registry.data[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion,CurrentBuild]
registry.data[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion,UBR]
```
Construire le build complet `CurrentBuild.UBR` par calcul/concaténation (item calculé ou côté tableau de bord).

Option B — fallback UserParameter (agent ancien ou clé `registry.data` indisponible). Dans `zabbix_agentd.conf` / `zabbix_agent2.conf` du serveur :
```
UserParameter=win.build,powershell -NoProfile -Command "$v=Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'; Write-Output ($v.CurrentBuild.ToString()+'.'+$v.UBR.ToString())"
```
Item Zabbix associé : clé `win.build` (type texte). Redémarrer l'agent après ajout.

> Insuffisant seul : `system.sw.os` et `wmi.get[root\cimv2,"SELECT Version FROM Win32_OperatingSystem"]` renvoient le build majeur sans l'UBR → ne permettent pas la comparaison au build cible. Utiliser `registry.data`/UBR ou le UserParameter.

### Déclencheur (trigger) par version
Créer un trigger comparant la valeur collectée au build cible §2 selon la version de l'hôte (à mapper via un tag/macro d'inventaire d'hôte, ex. `{$WIN_VERSION}`). Exemple Windows Server 2022 :
```
last(/{HOST}/win.build) < "20348.5139"
```
> La comparaison de chaînes `CurrentBuild.UBR` n'est fiable que si les deux nombres (build et révision) sont comparés numériquement. Privilégier un item calculé qui sépare `CurrentBuild` et `UBR` et applique la logique « build < cible OU (build = cible ET UBR < révision cible) », ou définir un trigger par version avec la valeur cible exacte.

### Exploitation du résultat
- Tableau de bord / dernières valeurs : exporter la liste des hôtes avec leur build → remplir le tableau de relevé §6 pour l'ensemble du parc.
- Les hôtes dont le trigger est actif (build < cible) = serveurs **non patchés** → escalade AVA6 (§5).

### Conséquence sur la démarche
- Si Zabbix couvre tout le parc avec le build complet : tu disposes de la vue autoritative toi-même → le mail AVA6 devient une **demande d'application ciblée** sur la liste des serveurs sous le build cible (et non une demande de confirmation parc).
- Si l'UBR n'est pas encore collecté : configurer l'item d'abord (toi ou via AVA6), sinon rester sur la méthode échantillon §4 + demande de confirmation.

### Vérifier dans l'interface Zabbix si la donnée est collectée

Deux écrans : **Latest data** (la donnée remonte-t-elle ?) et **Items** de l'hôte (l'item est-il configuré ?). Les noms de menus diffèrent selon la version.

**1. La donnée est-elle collectée ? — Monitoring → Latest data**
- Filtrer par Host group / Host = un serveur Windows ; rechercher `OS`, `build`, `version`.
- Lire la valeur :
  - `system.sw.os` avec `... 10.0.20348` **sans 4ᵉ nombre** → build majeur présent mais **pas l'UBR** (`.5139`) → insuffisant.
  - valeur complète `20348.5139` (item `registry.data[...UBR]` ou `win.build`) → UBR collecté, exploitable directement.

**2. Quels items sont configurés ? — Items de l'hôte**
- Zabbix 6.x : `Configuration → Hosts → <hôte> → Items`.
- Zabbix 7.0 : `Data collection → Hosts → <hôte> → Items` (menu « Configuration » renommé « Data collection »).
- Filtrer par **Key** : `system.sw.os` (template standard, sans UBR), `registry.data` (UBR, seulement si ajouté), `win.build` (UserParameter custom).

**3. Template lié** — colonne **Templates** de l'hôte : « Windows by Zabbix agent » fournit `system.sw.os` mais **pas l'UBR** par défaut (template lié ≠ UBR disponible).

**4. Tester un item en direct** — ouvrir/créer l'item → bouton **Test → Get value** : Zabbix interroge l'agent en live (utile pour valider `registry.data[...,UBR]` avant déploiement sur le parc).

**Conclusion de la vérification :**

| Constat | Signification |
|---------|---------------|
| Build complet `xxxxx.UBR` sur tous les hôtes | Collecté → exploiter directement |
| Seulement `system.sw.os` (sans UBR) | UBR non collecté → ajouter l'item, ou utiliser le script §4 ter |
| Pas d'item OS / hôte absent | Agent non déployé ou template non lié |

Rappels : accès à l'instance Zabbix requis (OneOrtho ou AVA6 ?) ; agent présent sur **tous** les serveurs pour une vue parc complète, sinon compléter avec le script §4 ter.

## 4 ter. Vérification distante parallèle (un identifiant par serveur)

Pour éviter de parcourir les serveurs un à un : exécuter la vérification **en parallèle** sur tout le parc en quelques secondes, chaque serveur étant joint avec **son propre identifiant**. Script prêt à l'emploi : `utils/hds/may2026/verif_builds_parallele.ps1`.

### Principe
- PowerShell 7+ sur le poste d'exécution → `ForEach-Object -Parallel` (exécution concurrente, `-ThrottleLimit 30`).
- Un identifiant **chiffré par serveur** (pas de mot de passe en clair) :
  - Simple (poste admin, usage ponctuel) : `Get-Credential | Export-CliXml -Path ...\SRV.xml` — chiffrement DPAPI, déchiffrable uniquement par le même utilisateur sur la même machine.
  - Robuste (équipe / automatisation) : module **SecretManagement + SecretStore** (ou coffre type CyberArk) — récupérer chaque identifiant par nom.
- Lecture distante du build via WinRM (`Invoke-Command` → registre `CurrentBuild` + `UBR`), comparaison automatique au build cible §2, restitution d'un tableau Patché / NON patché / Injoignable + export CSV probant.

### Pré-requis
- WinRM joignable sur les cibles (port 5985/5986) : `Test-WSMan <serveur>`. Activation côté cible : `Enable-PSRemoting`.
- Comptes **locaux** (hors domaine) : déclarer les cibles en TrustedHosts sur le poste d'exécution —
  `Set-Item WSMan:\localhost\Client\TrustedHosts -Value 'SRV-01,SRV-02' -Concatenate -Force` (ou WinRM HTTPS avec certificats).
- Droits administrateur local par serveur via l'identifiant fourni.

### Mise en œuvre
1. Préparer un `.xml` chiffré par serveur (étape 0 du script).
2. Renseigner l'inventaire CSV `ComputerName,CredFile`.
3. Lancer `verif_builds_parallele.ps1` → tableau consolidé + `resultat_builds_2026-05.csv` (à archiver comme pièce probante, cf. bordereau §4).

### Limites
- L'**application** du correctif Windows (cumulative) ne se déclenche pas par une simple commande distante : elle passe par Windows Update / WSUS, donc par AVA6 (§5). Ce script couvre la **vérification** parallèle, pas le patch lui-même. (Un déclenchement distant via le module `PSWindowsUpdate` est possible si OneOrtho exploite ses propres serveurs, mais le patching reste de la responsabilité AVA6.)
- Si **Zabbix** collecte déjà le build du parc (§4 bis), c'est encore plus direct et sans gestion d'identifiants — le préférer quand c'est disponible.

## 5. Si patch manquant → demande à AVA6

Constituer une demande à AVA6 (ticket exploitant / mail tracé) contenant :
- **Objet** : application Patch Tuesday Windows Server mai 2026 — 6 RCE Critical (réf. SEC-THREATINTEL-2026-05 / CICD-169).
- **Serveurs concernés** : liste des serveurs identifiés « Non patché » à l'étape 3, avec leur version.
- **KB attendue par version** : tableau §2 (KB cumulative correspondant à chaque version).
- **Criticité et échéance** : 6 vulnérabilités RCE de gravité Critical, exposition Internet (portail via IIS). Priorité P2, correctif attendu avant le **22/06/2026** (SLA J+14).
- **Demande** : application de la cumulative + redémarrage planifié + **confirmation du build atteint** par serveur après patch (doit être ≥ build cible §2).
- **Fenêtre de maintenance** : proposer un créneau (hors heures d'usage clinique) et demander validation.
- **Pré-requis** : sauvegarde / snapshot préalable, validation de la disponibilité du portail après redémarrage.

Répartition (RACI) : OneOrtho = demandeur + vérificateur (A/R sur la décision), AVA6 = exécutant de la mise à jour (R sur l'application), validation conjointe post-patch.

## 6. Tableau de relevé (à compléter)

| Serveur | Version Windows Server | Build relevé (CurrentBuild.UBR) | Build cible | Conclusion | Date relevé |
|---------|------------------------|----------------------------------|-------------|------------|-------------|
| | | | | Patché / Non patché | |

## 7. Vérification post-patch et clôture

Après intervention AVA6 :
1. Re-exécuter l'étape 2 sur les serveurs patchés.
2. Confirmer `CurrentBuild.UBR` ≥ build cible §2 pour chacun.
3. Vérifier la disponibilité du portail OneSoftware après redémarrage.
4. Joindre au Ticket 3 : tableau de relevé avant/après + confirmation AVA6.
5. Passer le critère d'acceptation « correctifs appliqués sur toutes les versions du parc » à validé, clore le Ticket 3.

## 8. Traçabilité (preuves à conserver pour l'audit)

- Capture / export du relevé de build avant patch (étape 2).
- Demande AVA6 (ticket exploitant ou mail) horodatée.
- Confirmation AVA6 post-patch + relevé de build après.
- Lien depuis le Ticket 3 et le rapport mensuel `cyber/may2026/`.

> Cas particulier : si l'étape 3 montre que **tous** les serveurs sont déjà ≥ build cible (parc déjà patché par AVA6 dans le cycle courant), documenter ce constat dans le Ticket 3, le clore en « déjà corrigé — aucune action AVA6 requise », et conserver le relevé comme preuve. Ne pas escalader inutilement.
