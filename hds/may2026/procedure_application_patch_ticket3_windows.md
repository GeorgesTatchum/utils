# Procédure — Ticket 3 : application interne des correctifs Windows Server (6 RCE Critical)

Objet : appliquer en interne les correctifs Windows Server pour les 6 CVE RCE Critical (Patch Tuesday 12/05/2026), sur les serveurs identifiés « Non patché », dans une fenêtre **02h–03h** pour ne pas impacter les activités clients.
**Le MCO de l'OS est assuré par OneOrtho** (pas par AVA6) : OneOrtho applique, planifie et vérifie.
Ticket : `SEC-THREATINTEL-2026-05` / CICD-169 — priorité P2.
CVE couvertes : CVE-2026-32161, CVE-2026-35421, CVE-2026-40402, CVE-2026-40403, CVE-2026-41089, CVE-2026-41096.

## 1. Principe

Windows Server (2016 et ultérieurs) applique des mises à jour **cumulatives mensuelles** : les 6 CVE sont corrigées par une seule KB cumulative par version d'OS.
- Un serveur dont le **build est ≥ au build corrigé** est protégé.
- La **comparaison du build** (`CurrentBuild.UBR`) est la preuve la plus fiable.

## 2. Tableau de référence (cible par version)

Source : export MSRC `Security Updates 2026-06-02-121531pm.csv` (SharePoint OneOrthoGED).

| Version Windows Server | KB cumulative (mai 2026) | Build corrigé (≥) |
|------------------------|--------------------------|--------------------|
| Windows Server 2016 | KB5087537 | 10.0.14393.9140 |
| Windows Server 2019 | KB5087538 | 10.0.17763.8755 |
| Windows Server 2022 | KB5087545 | 10.0.20348.5139 |
| Windows Server 2022 23H2 | KB5087541 | 10.0.25398.2330 |
| Windows Server 2025 | KB5087539 | 10.0.26100.32860 |

## 3. Étapes (vérification — réalisée)

1. Inventorier les serveurs Windows et leur version.
2. Relever `ProductName, CurrentBuild, UBR` (local ou à distance, §4).
3. Comparer `CurrentBuild.UBR` au build cible §2 → Patché / Non patché.
4. Consolider dans le relevé §6.

> Statut : vérification effectuée le 17/06–29/06/2026, **14 serveurs identifiés Non patché** (cf. §6). On passe à l'application interne (§5).

## 4. Commandes de relevé (rappel)

```powershell
# Build complet (CurrentBuild.UBR) + version
Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' |
  Select-Object ProductName, CurrentBuild, UBR
```
Relevé distant parallèle (un identifiant par serveur) : voir `verif_builds_parallele.ps1` et `procedure_verification_ticket3_windows.md` §4 ter.

## 5. Application interne des correctifs (planifiée 02h–03h)

### 5.1 Préparation (avant la nuit d'intervention)

1. **Identifier la KB par serveur** selon sa version (§2) : 2016 → KB5087537, 2022 → KB5087545, 2025 → KB5087539. (Le parc non patché ne contient ni 2019 ni 2022 23H2.)
2. **Choisir la méthode d'application** (cf. §5.2) : Windows Update — dernière cumulative + validation par build (recommandé), ou .msu hors-ligne (repli). Pour le repli, télécharger les .msu nécessaires (Microsoft Update Catalog, version x64 Server) et les copier dans `C:\patch\` des serveurs concernés. Noter le **build cible** de chaque version (§2) à passer en paramètre.
3. **Vérifier le canal Windows Update** sur chaque serveur (surtout les très en retard) : `(New-Object -ComObject Microsoft.Update.AutoUpdate).Results` et tester un scan. Si le canal est cassé (cf. constat Spike Defender : plateforme figée depuis 2019 sur 2 serveurs), le **réparer d'abord** ou basculer sur la méthode .msu hors-ligne.
4. **Snapshot de chaque VM avant intervention** (rollback) — voir §5.1bis.
5. **Plan canary** : appliquer d'abord les **préprod** (nuit N), valider le lendemain, puis les **prod** (nuit N+1). Ce sont des portails clients par distributeur → ne pas patcher prod et préprod la même nuit.
6. **Cas particuliers WS2016 très en retard** (WEBPRODI2B 14393.3474, WEBPREPRODI2B 14393.7785) : builds de 2018–2021. Privilégier **Windows Update** (il enchaîne automatiquement SSU → cumulative) ; en .msu, installer le SSU récent avant la cumulative.
7. **Taille affichée ≠ téléchargement réel.** La colonne `Size` de `Get-WUList` (ex. 21–26 Go observés sur WS2025/WS2022) correspond au `MaxDownloadSize` de l'API WU (paquet complet avec tous les différentiels du bundle), **pas au téléchargement réel** : une cumulative LCU WS2022 fait en réalité ~1–2 Go, quel que soit le retard du serveur (les cumulatives sont auto-contenues, le retard ne les fait pas grossir). Vérifier la taille réelle sur le Microsoft Update Catalog (par KB) et la **mesurer sur le canary préprod** (download + durée + delta disque) pour dimensionner la fenêtre prod.
8. **Espace disque** : prévoir **≥ 15–20 Go libres** (la maintenance du *component store* sur un serveur très en retard consomme temporairement plusieurs Go). Après validation post-patch, récupérer l'espace : `DISM /Online /Cleanup-Image /StartComponentCleanup` (après le patch, jamais avant). Si la bande passante à 02h est un sujet, **pré-stager le .msu** (Méthode B) plutôt que laisser chaque serveur tirer de WU.

### 5.1bis Snapshot avant patch (rollback)

Le snapshot est pris au niveau **hyperviseur**, donc selon ton accès :
- **Tu as la main sur l'hyperviseur** → tu prends le snapshot toi-même (commandes ci-dessous).
- **L'hyperviseur est géré par AVA6** (hébergeur) → demander à AVA6 de prendre le snapshot juste avant la fenêtre 02h–03h (c'est une action d'infrastructure, légitimement AVA6, même si le patch OS est interne).
- **Serveur physique** (pas de VM) → pas de snapshot : faire une **sauvegarde système** (`wbadmin start systemstatebackup` ou la solution de sauvegarde en place) avant patch.

Commandes selon l'hyperviseur (nom de snapshot conseillé : `pre-patch-TI-2026-05`) :

| Hyperviseur | Prise de snapshot | Suppression après validation |
|-------------|-------------------|------------------------------|
| VMware vSphere/ESXi (PowerCLI) | `New-Snapshot -VM <vm> -Name 'pre-patch-TI-2026-05' -Description 'Ticket3 RCE' -Quiesce` | `Get-Snapshot -VM <vm> -Name 'pre-patch-TI-2026-05' | Remove-Snapshot -Confirm:$false` |
| Hyper-V (sur l'hôte) | `Checkpoint-VM -Name <vm> -SnapshotName 'pre-patch-TI-2026-05'` | `Remove-VMSnapshot -VMName <vm> -Name 'pre-patch-TI-2026-05'` |
| Proxmox | `qm snapshot <vmid> pre-patch-TI-2026-05` | `qm delsnapshot <vmid> pre-patch-TI-2026-05` |
| Azure (disque OS) | Snapshot du disque OS (portail / `New-AzSnapshot`) | Supprimer le snapshot du disque |

Règles :
- Le snapshot est un **rollback court terme, pas une sauvegarde** : le prendre juste avant le patch.
- **Le supprimer après validation** post-patch (§7) — un snapshot laissé en place dégrade les performances et remplit le datastore.
- `-Quiesce` (VMware) ou checkpoint de production (Hyper-V) pour une cohérence applicative via VSS si les outils invité sont installés.
- Vérifier l'**espace libre du datastore** avant (un snapshot grossit avec les écritures).

### 5.2 Script d'application local (`apply-patch.ps1`)

À déposer dans `C:\patch\` de chaque serveur. Deux méthodes — **Méthode A (Windows Update ciblé) recommandée**, Méthode B (.msu) en repli.

**Méthode A — Windows Update : dernière cumulative + validation par build (recommandée)**

Ne pas épingler la KB du mois (elle disparaît dès qu'une cumulative plus récente la supersède → le script n'installerait rien). On installe les mises à jour de **sécurité** (la dernière cumulative OS, quelle que soit sa KB) et on **conclut sur le build atteint** : le build fait autorité, pas le numéro de KB. WU résout automatiquement le prérequis SSU. Nécessite un canal WU/WSUS fonctionnel (cf. §5.1 point 3).

On passe le **build cible** de la version (§2) en paramètre. Comme l'installation redémarre la machine, la validation du build se fait au **redémarrage suivant**, via une tâche de contrôle one-shot enregistrée par le script.

```powershell
# C:\patch\apply-patch.ps1  (Méthode A — dernière cumulative + validation par build)
param([version]$BuildCible)   # ex. 2016='10.0.14393.9140' 2019='10.0.17763.8755' 2022='10.0.20348.5139' 2025='10.0.26100.32860'
$log = 'C:\patch\apply-2026-05.log'
function Log($m){ "$(Get-Date -Format s) $env:COMPUTERNAME $m" | Out-File $log -Append }

$v0 = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
Log "build avant = $($v0.CurrentBuild).$($v0.UBR) ; cible >= $BuildCible"

if (-not (Get-Module -ListAvailable PSWindowsUpdate)) {
    Install-PackageProvider -Name NuGet -Force -Scope AllUsers | Out-Null
    Install-Module PSWindowsUpdate -Force -Scope AllUsers
}
Import-Module PSWindowsUpdate

# Journaliser les mises à jour disponibles (preuve)
Log "disponibles :"
(Get-WindowsUpdate -MicrosoftUpdate -Category 'Security Updates' 4>&1) | Out-File $log -Append

# Enregistrer la validation post-redémarrage (le build fait autorité)
$valArg = "-NoProfile -ExecutionPolicy Bypass -File C:\patch\validate-build.ps1 -BuildCible $BuildCible"
$a = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument $valArg
$t = New-ScheduledTaskTrigger -AtStartup
$pr = New-ScheduledTaskPrincipal -UserId 'SYSTEM' -LogonType ServiceAccount -RunLevel Highest
Register-ScheduledTask -TaskName 'TI-Patch-2026-05-Validate' -Action $a -Trigger $t -Principal $pr -Force

# Installer la dernière cumulative de sécurité (KB non figée) ; redémarre si requis
Log "installation Security Updates (AutoReboot si requis)"
Install-WindowsUpdate -MicrosoftUpdate -Category 'Security Updates' -AcceptAll -AutoReboot -Confirm:$false -Verbose 4>&1 | Out-File $log -Append
```

`-Category 'Security Updates'` borne le périmètre aux correctifs de sécurité (cumulative OS + .NET du mois), en excluant les pilotes, optionnelles et préversions → changement maîtrisé et traçable. La cumulative OS la plus récente est prise automatiquement, ce qui couvre rétroactivement les 6 CVE du Ticket 3 dès lors que le build atteint ≥ build cible §2.

Script de validation post-redémarrage, à déposer aussi dans `C:\patch\` :

```powershell
# C:\patch\validate-build.ps1  (exécuté au démarrage suivant le patch)
param([version]$BuildCible)
$log = 'C:\patch\apply-2026-05.log'
$v = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
$cur = [version]"$($v.CurrentBuild).$($v.UBR)"
$ok = $cur -ge $BuildCible
"$(Get-Date -Format s) $env:COMPUTERNAME build après = $cur ; cible $BuildCible ; conclusion = $(if($ok){'PATCHÉ'}else{'NON PATCHÉ — à investiguer'})" | Out-File $log -Append
# Auto-désinscription (one-shot)
Unregister-ScheduledTask -TaskName 'TI-Patch-2026-05-Validate' -Confirm:$false -ErrorAction SilentlyContinue
```

**Méthode B — .msu hors-ligne (repli : WU injoignable / serveur isolé)**
Déposer la .msu correspondant à la version dans `C:\patch\`. Pour un build très ancien, installer d'abord le SSU récent.

```powershell
# C:\patch\apply-patch.ps1  (Méthode B — .msu hors-ligne)
$msu = (Get-ChildItem 'C:\patch\*.msu' | Select-Object -First 1).FullName
$log = 'C:\patch\apply-2026-05.log'
"$(Get-Date -Format s) $env:COMPUTERNAME début MSU, msu=$msu" | Out-File $log -Append
$p = Start-Process wusa.exe -ArgumentList "`"$msu`"","/quiet","/norestart" -Wait -PassThru
"$(Get-Date -Format s) wusa exitcode=$($p.ExitCode)" | Out-File $log -Append
# 0 = installé ; 3010 = installé, redémarrage requis ; 2359302 = déjà présent
if ($p.ExitCode -in 0,3010) {
    "$(Get-Date -Format s) redémarrage" | Out-File $log -Append
    Restart-Computer -Force
} else {
    "$(Get-Date -Format s) PAS de redémarrage (exit $($p.ExitCode)) — à vérifier" | Out-File $log -Append
}
```

> Choix par serveur : Méthode A par défaut. Bascule en Méthode B si le canal WU est cassé (cas probable sur les serveurs très en retard — même cause que la plateforme Defender figée) ou si le serveur est isolé d'Internet/WSUS.

### 5.3 Planification à 02h–03h (tâche planifiée locale)

Créer sur chaque serveur une tâche planifiée déclenchée à l'heure voulue, exécutée en `SYSTEM` :

```powershell
# IMPORTANT : passer une DATE + heure complète et FUTURE. Une heure seule ('02:00') vise
# aujourd'hui 02:00 ; si c'est déjà passé, la tâche ne se déclenche jamais (pas de rattrapage par défaut).
$quand = Get-Date '2026-06-30 02:00'   # nuit d'intervention prévue (cf. §5.5), à adapter par vague
$cible = '10.0.20348.5139'  # build cible de la version du serveur (§2). Méthode B : retirer -BuildCible.
$action = New-ScheduledTaskAction -Execute 'powershell.exe' `
  -Argument "-NoProfile -ExecutionPolicy Bypass -File C:\patch\apply-patch.ps1 -BuildCible $cible"
$trigger = New-ScheduledTaskTrigger -Once -At $quand
$principal = New-ScheduledTaskPrincipal -UserId 'SYSTEM' -LogonType ServiceAccount -RunLevel Highest
Register-ScheduledTask -TaskName 'TI-Patch-2026-05-Ticket3' `
  -Action $action -Trigger $trigger -Principal $principal -Force

# Vérifier que la prochaine exécution est bien dans le futur (pas une heure passée)
Get-ScheduledTask -TaskName 'TI-Patch-2026-05-Ticket3' | Get-ScheduledTaskInfo | Select-Object NextRunTime
```

> Ne pas activer `-StartWhenAvailable` pour rattraper une exécution manquée : cela ferait tourner la tâche à un moment imprévisible (au prochain démarrage / réveil), hors de la fenêtre 02h–03h. Mieux vaut fixer une **date future explicite** et vérifier `NextRunTime`.

### 5.4 Mise en place à distance (un identifiant par serveur)

Pousser les scripts + la tâche sur chaque serveur depuis la station d'administration (PowerShell 7), avec l'identifiant propre à chaque serveur. En **Méthode A (WU)** il n'y a pas de .msu à copier (on passe le **build cible** de la version) ; en **Méthode B**, copier aussi la .msu de la version. Renseigner le build cible par serveur selon sa version (§2).

```powershell
# Inventaire : Hote, Cible (build §2 selon version), CredFile (xml chiffré DPAPI, cf. verif_builds_parallele.ps1), Quand (DATE+heure future)
# Méthode B uniquement : ajouter le champ Msu (chemin local du .msu de la version)
$cibles = @(
  @{ Hote='WEBPREPRODFH'; Cible='10.0.20348.5139'; Cred='C:\secure\WEBPREPRODFH.xml'; Quand='2026-06-30 02:00' }
  # ... une ligne par serveur ; build cible : 2016=10.0.14393.9140, 2022=10.0.20348.5139, 2025=10.0.26100.32860
  # Quand = DATE + heure FUTURE (préprod nuit N, prod nuit N+1) ; jamais une heure seule (sinon = aujourd'hui, déjà passé)
)

foreach ($c in $cibles) {
  $cred = Import-CliXml $c.Cred
  $sess = New-PSSession -ComputerName $c.Hote -Credential $cred
  Invoke-Command -Session $sess -ScriptBlock { New-Item -ItemType Directory -Force 'C:\patch' | Out-Null }
  # Méthode B uniquement : Copy-Item -ToSession $sess -Path $c.Msu -Destination 'C:\patch\' -Force
  Copy-Item -ToSession $sess -Path '.\apply-patch.ps1','.\validate-build.ps1' -Destination 'C:\patch\' -Force
  Invoke-Command -Session $sess -ArgumentList $c.Quand,$c.Cible -ScriptBlock {
    param($quand,$cible)
    $arg = "-NoProfile -ExecutionPolicy Bypass -File C:\patch\apply-patch.ps1 -BuildCible $cible"   # Méthode A
    $a = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument $arg
    $t = New-ScheduledTaskTrigger -Once -At (Get-Date $quand)
    $pr = New-ScheduledTaskPrincipal -UserId 'SYSTEM' -LogonType ServiceAccount -RunLevel Highest
    Register-ScheduledTask -TaskName 'TI-Patch-2026-05-Ticket3' -Action $a -Trigger $t -Principal $pr -Force
    Get-ScheduledTask -TaskName 'TI-Patch-2026-05-Ticket3' | Get-ScheduledTaskInfo | Select-Object NextRunTime
  }
  Remove-PSSession $sess
}
```

> Pré-requis identiques au relevé distant : WinRM joignable, TrustedHosts pour comptes hors-domaine, droits admin local. La tâche s'exécute **localement à l'heure prévue**, indépendamment de la station (qui peut être éteinte).

### 5.5 Étalement des vagues (fenêtre 02h–03h)

| Vague | Nuit | Heure | Serveurs |
|-------|------|-------|----------|
| 1 — Préprod (canary) | N | 02:00 | WEBPREPRODDEDIENNE, WEBPREPRODSTRYKER, WEBPREPRODI2B, WEBPREPRODFH, WEBPREPRODEVOLUTIS, WEBPREPRODKERI, WEBPREPRODLEPIN |
| 2 — Prod | N+1 | 02:00–02:45 (étaler par lots de 2–3) | WEBPRODGLOBALD, WEBPRODSTRYKER, WEBPRODI2B, WEBPRODFH, WEBPRODEVOLUTIS, WEBPRODKERI, WEBPRODLEPINE |

- Valider la préprod (§7) le matin suivant la vague 1 **avant** de planifier la vague 2.
- En prod, étaler les déclenchements (02:00 / 02:20 / 02:40) pour ne pas redémarrer tous les portails simultanément.

### 5.6 Synthèse du choix de méthode

| Situation du serveur | Méthode |
|----------------------|---------|
| Canal Windows Update fonctionnel | **A — WU dernière cumulative + validation par build** ; résout le SSU, périmètre borné à `Security Updates` |
| Très en retard mais WU fonctionnel | **A** (WU enchaîne SSU → cumulative automatiquement) |
| Canal WU cassé / serveur isolé | **B — .msu hors-ligne** (installer le SSU récent d'abord si build ancien) |

Principe Méthode A : **ne pas figer la KB du mois** (elle est supersédée par la cumulative suivante → rien ne s'installerait). On installe la dernière cumulative de sécurité offerte et **le build atteint fait autorité** : conclusion `PATCHÉ` si build ≥ build cible §2, vérifiée automatiquement au redémarrage (`validate-build.ps1`). `-Category 'Security Updates'` borne le périmètre (cumulative OS + .NET du mois), hors pilotes/optionnelles/préversions → changement maîtrisé et traçable (change management / IEC 62304).

> Ne jamais conclure sur « la tâche a tourné » : un ciblage par KB figée pourrait n'installer rien. C'est le **build après redémarrage** (≥ cible §2) qui prouve la remédiation.

## 6. Tableau de relevé (vérification du 17/06–29/06/2026)

| Serveur | Version Windows Server | Build relevé | Build cible | Conclusion | Date |
|---------|------------------------|--------------|-------------|------------|------|
| WEBPRODSAAS | Windows Server 2022 | 20348.5256 | 20348.5139 | Patché | 17/06/2026 |
| WEBPRODDEDIENNE | Windows Server 2025 | 26100.32860 | 26100.32860 | Patché | 17/06/2026 |
| WEBPRODGLOBALD | Windows Server 2016 Standard | 14393.8330 | 14393.9140 | **Non patché** | 17/06/2026 |
| WEBPREPRODSAAS | Windows Server 2022 | 20348.5256 | 20348.5139 | Patché | 26/06/2026 |
| WEBTESTSAAS | Windows Server 2022 | 20348.5256 | 20348.5139 | Patché | 26/06/2026 |
| WEBPREPRODDEDIENNE | Windows Server 2025 Standard | 26100.32370 | 26100.32860 | **Non patché** | 26/06/2026 |
| SERF-PROD | Windows Server 2016 Standard | 14393.9234 | 14393.9140 | Patché | 26/06/2026 |
| WEBPRODSTRYKER | Windows Server 2025 Standard | 26100.32370 | 26100.32860 | **Non patché** | 29/06/2026 |
| WEBPREPRODSTRYKER | Windows Server 2025 Standard | 26100.32370 | 26100.32860 | **Non patché** | 29/06/2026 |
| WEBPREPRODI2B | Windows Server 2016 Standard | 14393.7785 | 14393.9140 | **Non patché** | 29/06/2026 |
| WEBPRODI2B | Windows Server 2016 Standard | 14393.3474 | 14393.9140 | **Non patché** | 29/06/2026 |
| WEBPRODFH | Windows Server 2022 Standard | 20348.2527 | 20348.5139 | **Non patché** | 29/06/2026 |
| WEBPREPRODFH | Windows Server 2022 Standard | 20348.2527 | 20348.5139 | **Non patché** | 29/06/2026 |
| WEBPRODEVOLUTIS | Windows Server 2022 Standard | 20348.3453 | 20348.5139 | **Non patché** | 29/06/2026 |
| WEBPREPRODEVOLUTIS | Windows Server 2022 Standard | 20348.3453 | 20348.5139 | **Non patché** | 29/06/2026 |
| WEBPRODKERI | Windows Server 2022 Standard | 20348.3328 | 20348.5139 | **Non patché** | 29/06/2026 |
| WEBPREPRODKERI | Windows Server 2022 Standard | 20348.3328 | 20348.5139 | **Non patché** | 29/06/2026 |
| WEBPRODLEPINE | Windows Server 2022 Standard | 20348.3807 | 20348.5139 | **Non patché** | 29/06/2026 |
| WEBPREPRODLEPIN | Windows Server 2022 Standard | 20348.3807 | 20348.5139 | **Non patché** | 29/06/2026 |

Synthèse : 19 serveurs vérifiés, **5 patchés**, **14 à patcher** (7 préprod + 7 prod). KB requise : KB5087537 (2016 ×4), KB5087545 (2022 ×8), KB5087539 (2025 ×3).

## 7. Contrôle post-redémarrage et clôture

Pour chaque serveur patché, le matin suivant l'intervention :
1. **Re-relever le build** (`CurrentBuild.UBR`) → confirmer ≥ build cible §2.
2. **Vérifier l'état des services** : IIS démarré, pool d'applications actif.
   ```powershell
   Get-Service W3SVC | Select-Object Status
   Invoke-WebRequest -UseBasicParsing https://<url-portail> -TimeoutSec 20 | Select-Object StatusCode
   ```
3. **Vérifier la disponibilité fonctionnelle** du portail OneSoftware (connexion, page d'accueil).
4. **Consigner le log** `C:\patch\apply-2026-05.log` de chaque serveur (exit code wusa, redémarrage).
5. Mettre à jour le relevé §6 avec le build **après patch** (preuve de remédiation).
6. Passer le critère d'acceptation « correctifs appliqués sur toutes les versions du parc » à validé, clore le **Ticket 3**.

> Rollback : si un serveur ne redémarre pas correctement ou si le portail est indisponible, restaurer le snapshot pris en §5.1 et investiguer hors fenêtre client (cas probable sur les WS2016 très anciens).

## 8. Traçabilité (preuves à conserver pour l'audit)

- Relevé de build **avant** patch (§6) — déjà constitué.
- Fichiers .msu utilisés (référence KB + version) et logs `apply-2026-05.log` par serveur.
- Relevé de build **après** patch (≥ build cible) par serveur.
- Captures de contrôle post-redémarrage (IIS / portail répondant).
- Lien depuis le Ticket 3 et le rapport mensuel ; pièces déposées dans `annexes/2026-05/` (cf. bordereau `index_pieces_probantes_2026-05.md`).

> Note conformité : MCO OS interne OneOrtho. Aucune donnée patient ni secret dans les logs. Toute intervention hors fenêtre 02h–03h sur un portail prod doit être justifiée et tracée.
