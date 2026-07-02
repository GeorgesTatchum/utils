# Procédure — Spike 1 : Microsoft Defender (CVE-2026-41091 + CVE-2026-45498)

Objet : déterminer si Microsoft Defender est l'antivirus actif sur les serveurs Windows OneOrtho et, le cas échéant, si son moteur/plateforme est déjà corrigé — afin de conclure le Spike (créer une remédiation ou clore en non applicable).
Spike associé : `SEC-THREATINTEL-2026-05` / CICD-169. Échéance : 11/06/2026.
CVE : CVE-2026-41091 (Malware Protection Engine, EoP) et CVE-2026-45498 (Antimalware Platform, DoS). **Les deux sont au CISA KEV depuis le 20/05/2026 (exploitation active)** → vérification explicite requise.

## 1. Principe

Le **moteur** (Malware Protection Engine, version `1.1.x`) et la **plateforme** (Antimalware Platform, `4.18.x`) de Defender se mettent à jour **automatiquement**, hors du cycle Patch Tuesday de l'OS. Conséquences :
- si Defender est actif **et** l'auto-update fonctionne, le correctif est très probablement déjà appliqué → vérifier la version ;
- si un **antivirus tiers** est le scanner actif (Defender en mode passif/désactivé), l'exposition au moteur Defender est fortement réduite → tendance « non applicable ».

La conclusion repose donc sur 2 questions : Defender est-il l'AV actif ? sa version est-elle ≥ version corrigée ?

## 2. Versions corrigées (cible)

Source : MSRC (export `Security Updates 2026-06-02-121531pm.csv`).

| CVE | Composant Defender | Version corrigée (≥) | Propriété à relever |
|-----|--------------------|----------------------|---------------------|
| CVE-2026-41091 | Malware Protection Engine | **1.1.26040.8** | `AMEngineVersion` |
| CVE-2026-45498 | Antimalware Platform | **4.18.26040.7** | `AMProductVersion` (plateforme) |

## 3. Étapes

### Étape 1 — Defender est-il l'antivirus actif ?
Relever le mode de fonctionnement. Si un AV tiers assure la protection, Defender bascule en passif/désactivé.

### Étape 2 — Relever les versions moteur et plateforme
Comparer aux versions corrigées du §2.

### Étape 3 — Vérifier que l'auto-update est actif
Confirmer que les mises à jour de définitions/moteur sont fonctionnelles (sinon le correctif ne se propage pas).

### Étape 4 — Conclure (grille §5)

## 4. Commandes PowerShell

### Sur un serveur (local)
```powershell
# Mode de fonctionnement + versions moteur/plateforme + état auto-update
Get-MpComputerStatus | Select-Object `
  AMRunningMode, AntivirusEnabled, AMServiceEnabled, `
  AMEngineVersion, AMProductVersion, AntivirusSignatureVersion, `
  AntispywareSignatureLastUpdated
```
- `AMRunningMode` : `Normal` = Defender est l'AV actif ; `Passive` / `EDR Block` / `SxS Passive Mode` / `Not running` = un AV tiers est probablement actif.
- `AMEngineVersion` → comparer à **1.1.26040.8**.
- `AMProductVersion` → comparer à **4.18.26040.7**.

### À distance sur plusieurs serveurs (si WinRM disponible)
```powershell
$serveurs = @('SRV-XXX-01','SRV-XXX-02')  # à compléter
Invoke-Command -ComputerName $serveurs -ScriptBlock {
  $s = Get-MpComputerStatus
  [PSCustomObject]@{
    Serveur   = $env:COMPUTERNAME
    Mode      = $s.AMRunningMode
    Moteur    = $s.AMEngineVersion
    Plateforme= $s.AMProductVersion
  }
} | Sort-Object Serveur | Format-Table -AutoSize
```

> Si l'accès est détenu par AVA6, transmettre ces commandes et demander le retour `AMRunningMode / AMEngineVersion / AMProductVersion` par serveur.

## 5. Grille de décision

| Constat | Conclusion | Action |
|---------|------------|--------|
| Defender **non actif** (AV tiers en mode Normal, Defender Passive/Disabled) | **Non applicable** : le moteur Defender n'effectue pas les analyses | Documenter en §3.3 « Items levés après investigation », clore le Spike. (Vérifier par ailleurs que l'AV tiers est lui-même à jour — hors périmètre de ces CVE.) |
| Defender **actif** + `AMEngineVersion` ≥ 1.1.26040.8 **et** `AMProductVersion` ≥ 4.18.26040.7 | **Déjà corrigé** (auto-update) | Documenter le relevé, clore le Spike sans ticket de remédiation |
| Defender **actif** + une version **< cible** | **Applicable** | Forcer la mise à jour (§6), puis créer le(s) ticket(s) de remédiation : CVE-2026-41091 → P2 (KEV + EoP), CVE-2026-45498 → P3 (KEV + DoS, sévérité MSRC Low) |
| Auto-update **inactif/défaillant** | À corriger en priorité | Réactiver l'auto-update Defender (cause racine de la latence), puis re-vérifier |

## 6. Traitement des serveurs applicables (Ticket 9)

Résultat de l'investigation (juin 2026) : **moteur à jour partout** (`AMEngineVersion` 1.1.26050.11 ≥ 1.1.26040.8 → CVE-2026-41091 non applicable), mais **2 serveurs** avec `AMProductVersion` **4.18.1911.3** (nov. 2019) < 4.18.26040.7 → **CVE-2026-45498 applicable** sur ces 2 serveurs.

**Attention** : `Update-MpSignature` met à jour signatures + moteur (1.1.x), **pas la plateforme** (4.18.x). La plateforme se met à jour **via Windows Update**. Une plateforme figée à 2019 = canal de mise à jour cassé (probablement les mêmes serveurs isolés que le Ticket 3).

### Voie A — canal Windows Update réparable (recommandée)

À lancer en PowerShell **administrateur** sur le serveur (compatible WS2016).

**A.1 Diagnostiquer la cause**
```powershell
# a) Un WSUS est-il imposé ?
Get-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate' -EA SilentlyContinue |
  Select-Object WUServer, WUStatusServer
Get-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU' -EA SilentlyContinue |
  Select-Object UseWUServer, NoAutoUpdate

# b) Proxy WinHTTP utilisé par Windows Update / Defender
netsh winhttp show proxy

# c) Sortie vers Microsoft ?
Test-NetConnection windowsupdate.microsoft.com -Port 443
Test-NetConnection www.microsoft.com -Port 443
```
Lecture : `WUServer` renseigné + `UseWUServer=1` = forcé vers un WSUS (down → rien ne descend) · `netsh` en « accès direct » alors qu'un proxy est requis = pas de sortie · `Test-NetConnection` `TcpTestSucceeded : False` = blocage réseau (correction réseau, pas serveur).

**A.2 Corriger selon la cause**

*WSUS imposé et injoignable → basculer en accès direct Microsoft Update*
```powershell
Set-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU' -Name UseWUServer -Value 0
Restart-Service wuauserv
```
Si le pointage vient d'une **GPO**, il reviendra au prochain `gpupdate` → corriger la GPO (ou sortir le serveur de son périmètre). Retrait complet du pointage local :
```powershell
Remove-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate' -Name WUServer,WUStatusServer -EA SilentlyContinue
Restart-Service wuauserv
```

*Proxy requis mais absent → le renseigner (adresse+port récupérés, non calculés)*
```powershell
# option 1 : réutiliser le proxy déjà connu de la session / IE
Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings' |
  Select-Object ProxyEnable, ProxyServer, AutoConfigURL
netsh winhttp import proxy source=ie
# option 2 : le poser manuellement si le proxy d'entreprise est connu
netsh winhttp set proxy proxy-server="http=proxy.corp:3128;https=proxy.corp:3128" bypass-list="<local>"
# annuler un proxy erroné :
netsh winhttp reset proxy
```
Si aucune source n'a de proxy et pas d'accès sortant → serveur **isolé par conception** (décision réseau à confirmer auprès de qui gère la sortie / le pare-feu) → passer en **Voie B**.

**A.3 Forcer la détection + mise à jour, puis vérifier**
```powershell
Restart-Service wuauserv
(New-Object -ComObject Microsoft.Update.AutoUpdate).DetectNow()
& "C:\Program Files\Windows Defender\MpCmdRun.exe" -SignatureUpdate
Get-MpComputerStatus | Select-Object AMProductVersion, AMEngineVersion
```
`AMProductVersion` doit monter ≥ 4.18.26040.7 (le rollout plateforme peut prendre quelques minutes/heures après rétablissement du canal → re-vérifier).

> Bénéfice : réparer le canal une seule fois fait redescendre **la plateforme Defender ET la cumulative OS** (Ticket 3), même cause racine. À privilégier.

### Voie B — serveur isolé / canal non réparable rapidement

Mise à jour de plateforme **hors-ligne** : récupérer le package « Update for Microsoft Defender Antivirus antimalware platform » sur le Microsoft Update Catalog (rechercher *antimalware platform*, version x64 de la version d'OS), le copier sur le serveur et l'exécuter. Puis re-vérifier `AMProductVersion`.
Solution pérenne : pointer le serveur vers un WSUS/SCCM qui synchronise les mises à jour Defender.

### Validation

```powershell
Get-MpComputerStatus | Select-Object AMProductVersion   # doit être >= 4.18.26040.7
```
Conserver la sortie **avant/après** par serveur → pièce probante du Ticket 9. Clôturer quand les 2 serveurs sont ≥ cible.

### Fallback — acceptation de risque documentée

Si la Voie B est impraticable à court terme sur un serveur vraiment isolé : CVE-2026-45498 étant un **DoS (MSRC Low)** à exposition **interne**, une **acceptation de risque temporaire** documentée (décidée avec le Responsable Numérique, avec échéance de correction) est défendable — sans laisser l'item ouvert sans décision écrite (c'est au KEV). Tracer en parallèle la réparation du canal comme action de fond.

## 7. Conclusion du Spike et traçabilité

- Reporter le constat (mode + versions par serveur) dans le Spike et, selon la grille §5, en §3.3 du rapport (non applicable / déjà corrigé) ou en nouveaux tickets de remédiation.
- Pièces probantes à conserver : sortie `Get-MpComputerStatus` (avant / après si MAJ forcée), logs d'application internes le cas échéant.
- Mettre à jour la décision §6 du rapport (ligne 7) avec la conclusion.

> Rappel : ces 2 CVE étant au KEV, traiter le Spike sans attendre — même si l'auto-update les a probablement déjà couvertes, la confirmation explicite du niveau de version est ce qui clôt l'item pour l'audit.
