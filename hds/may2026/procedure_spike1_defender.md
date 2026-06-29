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

## 6. Si version < cible → forcer la mise à jour

```powershell
# Met à jour signatures + moteur Defender
Update-MpSignature

# Re-vérifier ensuite
Get-MpComputerStatus | Select-Object AMEngineVersion, AMProductVersion
```
Si la mise à jour n'aboutit pas (proxy, WSUS, connectivité), escalader à AVA6 : application de la dernière plateforme/moteur Defender sur les serveurs concernés + confirmation des versions atteintes. Référencer CICD-169, échéance alignée sur la priorité (P2 → 22/06/2026).

## 7. Conclusion du Spike et traçabilité

- Reporter le constat (mode + versions par serveur) dans le Spike et, selon la grille §5, en §3.3 du rapport (non applicable / déjà corrigé) ou en nouveaux tickets de remédiation.
- Pièces probantes à conserver : sortie `Get-MpComputerStatus` (avant / après si MAJ forcée), échange AVA6 le cas échéant.
- Mettre à jour la décision §6 du rapport (ligne 7) avec la conclusion.

> Rappel : ces 2 CVE étant au KEV, traiter le Spike sans attendre — même si l'auto-update les a probablement déjà couvertes, la confirmation explicite du niveau de version est ce qui clôt l'item pour l'audit.
