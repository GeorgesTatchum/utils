
# Chiffrement des donnees au repos - Windows Server (BitLocker)

> **Version** : 1.0  
> **Date** : 2026-03-12  
> **Contexte** : Serveurs dedies (un serveur par client), environnement medical, conformite FDA 21 CFR Part 11.

---

## Sommaire

1. [Definition](#1-definition)
2. [Liens vers la documentation officielle](#2-liens-vers-la-documentation-officielle)
3. [Fonctionnalites](#3-fonctionnalites)
4. [Processus de mise en place en production (Windows Server >= 2016)](#4-processus-de-mise-en-place-en-production-windows-server--2016)

---

## 1. Definition

### 1.1 Qu'est-ce que le chiffrement des donnees au repos (Data-at-Rest Encryption) ?

Le **chiffrement des donnees au repos** (ou **chiffrement a froid**) consiste a proteger les donnees stockees sur un support physique (disque dur, SSD, volume) de sorte qu'elles soient **illisibles sans la cle de dechiffrement**, meme si le support est physiquement vole, retire du serveur ou accede hors du systeme d'exploitation autorise.

Contrairement au chiffrement en transit (TLS/SSL) qui protege les donnees pendant leur transfert reseau, le chiffrement au repos protege les donnees **quand le serveur est eteint ou que le disque est hors-ligne**.

### 1.2 BitLocker Drive Encryption

Sur Windows Server, la technologie native pour le chiffrement au repos est **BitLocker Drive Encryption**. BitLocker :

- Chiffre **l'integralite d'un volume** (partition) au niveau du bloc, de maniere transparente pour les applications
- Utilise l'algorithme **AES-128** ou **AES-256** (XTS ou CBC selon la version)
- S'appuie sur le **TPM** (Trusted Platform Module) pour stocker et proteger les cles de chiffrement materiellement
- Est integre nativement a Windows Server depuis **Windows Server 2008 R2** et disponible sur toutes les editions **2016, 2019, 2022 et 2025**
- Fonctionne de maniere **transparente** : une fois active, les applications (MariaDB, IIS, etc.) lisent et ecrivent normalement, le chiffrement/dechiffrement est gere par le systeme d'exploitation

### 1.3 Relation avec le TDE MariaDB

| Couche | Technologie | Protege contre |
|---|---|---|
| **Volume (OS)** | BitLocker | Vol physique du disque, boot alternatif, acces offline |
| **Base de donnees** | MariaDB TDE (file_key_management) | Acces aux fichiers `.ibd` par un utilisateur OS non autorise |

Les deux couches sont **complementaires**. BitLocker protege le volume complet (OS + donnees), tandis que TDE protege specifiquement les fichiers de la base de donnees meme si l'OS est compromis.

---

## 2. Liens vers la documentation officielle

### 2.1 Documentation Microsoft

| Sujet | Lien |
|---|---|
| Vue d'ensemble BitLocker | https://learn.microsoft.com/fr-fr/windows/security/operating-system-security/data-protection/bitlocker/ |
| BitLocker sur Windows Server | https://learn.microsoft.com/fr-fr/windows/security/operating-system-security/data-protection/bitlocker/bitlocker-how-to-deploy-on-windows-server |
| FAQ BitLocker | https://learn.microsoft.com/fr-fr/windows/security/operating-system-security/data-protection/bitlocker/bitlocker-frequently-asked-questions |
| Cmdlets PowerShell BitLocker | https://learn.microsoft.com/fr-fr/powershell/module/bitlocker/ |
| Gestion des cles de recuperation (AD DS) | https://learn.microsoft.com/fr-fr/windows/security/operating-system-security/data-protection/bitlocker/bitlocker-recovery-guide-plan |
| TPM Fundamentals | https://learn.microsoft.com/fr-fr/windows/security/hardware-security/tpm/tpm-fundamentals |
| Group Policy BitLocker | https://learn.microsoft.com/fr-fr/windows/security/operating-system-security/data-protection/bitlocker/bitlocker-group-policy-settings |
| Chiffrement AES-XTS vs AES-CBC | https://learn.microsoft.com/fr-fr/windows/security/operating-system-security/data-protection/bitlocker/bitlocker-countermeasures |

### 2.2 Conformite et reglementation

| Reference | Lien |
|---|---|
| FDA 21 CFR Part 11 - Electronic Records | https://www.ecfr.gov/current/title-21/chapter-I/subchapter-A/part-11 |
| NIST SP 800-111 - Guide to Storage Encryption | https://csrc.nist.gov/pubs/sp/800/111/final |
| NIST SP 800-57 - Key Management | https://csrc.nist.gov/pubs/sp/800/57/pt1/r5/final |

---

## 3. Fonctionnalites

### 3.1 Algorithmes de chiffrement

| Mode | Algorithme | Taille de cle | Recommandation |
|---|---|---|---|
| **XTS-AES 128** | AES-128 en mode XTS | 128 bits | Acceptable (defaut Windows 10+) |
| **XTS-AES 256** | AES-256 en mode XTS | 256 bits | **Recommande pour serveurs** |
| CBC-AES 128 | AES-128 en mode CBC + Diffuser | 128 bits | Pour disques amovibles uniquement |
| CBC-AES 256 | AES-256 en mode CBC + Diffuser | 256 bits | Pour disques amovibles uniquement |

> **Note** : Le mode **XTS** (XEX-based Tweaked CodeBook mode with CipherText Stealing) est specifiquement concu pour le chiffrement de disques et resiste mieux aux attaques par manipulation de blocs que le mode CBC.

### 3.2 Protecteurs de cles (Key Protectors)

BitLocker supporte plusieurs mecanismes pour proteger la cle de chiffrement du volume (VMK - Volume Master Key) :

| Protecteur | Description | Cas d'usage serveur |
|---|---|---|
| **TPM seul** | Deverrouillage automatique au demarrage si le hardware n'a pas change | Serveurs physiques avec TPM 2.0 |
| **TPM + PIN** | TPM + code PIN au boot | Securite renforcee (necessite presence physique au reboot) |
| **TPM + cle USB** | TPM + cle USB de demarrage | Alternative au PIN |
| **Mot de passe** | Mot de passe au demarrage | Machines virtuelles sans vTPM |
| **Cle de recuperation (48 chiffres)** | Cle d'urgence si le TPM est modifie | **Obligatoire** - a sauvegarder dans AD DS |
| **Deverrouillage reseau** | Deverrouillage automatique via serveur WDS sur le reseau | Datacenters, redemarrage sans intervention |
| **Auto-unlock** | Le volume OS deverrouille automatiquement les volumes de donnees | Volumes de donnees secondaires |

### 3.3 Fonctionnalites cles

- **Chiffrement transparent** : Aucune modification applicative requise. Les processus (MariaDB, IIS, services) accedent aux fichiers normalement.
- **Chiffrement de l'espace utilise uniquement** : Option `UsedSpaceOnly` pour un chiffrement initial rapide sur un nouveau volume (le reste est chiffre a la volee).
- **Chiffrement complet du volume** : Option `FullEncryption` pour chiffrer l'integralite du volume, y compris l'espace libre (recommande pour les volumes deja en production).
- **Verification d'integrite au demarrage** : Le TPM mesure les composants de demarrage (BIOS/UEFI, bootloader, noyau). Si une modification est detectee, le deverrouillage est refuse.
- **Suspension temporaire** : `Suspend-BitLocker` permet de suspendre la protection pour une mise a jour BIOS/firmware sans perdre le chiffrement.
- **Sauvegarde des cles dans Active Directory** : Les cles de recuperation peuvent etre stockees automatiquement dans AD DS via GPO.
- **Compatible Hyper-V** : BiLocker fonctionne sur les volumes de l'hote Hyper-V. Les VM invitees peuvent utiliser le vTPM pour activer BitLocker a l'interieur de la VM.
- **Administration a distance** : Gestion complete via PowerShell Remoting ou `manage-bde.exe`.
- **Performance** : Impact minimal sur les performances (1-5% selon les benchmarks Microsoft) grace a l'acceleration materielle AES-NI presente sur tous les processeurs serveur modernes.
- **Audit** : Evenements BitLocker dans le journal `Applications and Services Logs > Microsoft > Windows > BitLocker-API`.

### 3.4 Commandes PowerShell principales

```powershell
# Statut de tous les volumes
Get-BitLockerVolume

# Activer BitLocker sur un volume
Enable-BitLocker -MountPoint "D:" -EncryptionMethod XtsAes256 -UsedSpaceOnly -TpmProtector

# Ajouter une cle de recuperation
Add-BitLockerKeyProtector -MountPoint "D:" -RecoveryPasswordProtector

# Sauvegarder la cle dans AD DS
Backup-BitLockerKeyProtector -MountPoint "D:" -KeyProtectorId "{GUID}"

# Suspendre (avant mise a jour BIOS)
Suspend-BitLocker -MountPoint "C:" -RebootCount 1

# Reprendre
Resume-BitLocker -MountPoint "C:"

# Verifier le statut de chiffrement
manage-bde -status D:

# Desactiver (dechiffre le volume)
Disable-BitLocker -MountPoint "D:"
```

---

## 4. Processus de mise en place en production (Windows Server >= 2016)

### 4.1 Pre-requis

| Element | Exigence | Verification |
|---|---|---|
| **OS** | Windows Server 2016, 2019, 2022 ou 2025 | `[System.Environment]::OSVersion` |
| **Edition** | Standard ou Datacenter | `Get-WindowsEdition -Online` |
| **TPM** | TPM 2.0 recommande (1.2 minimum) | `Get-Tpm` |
| **UEFI** | Mode UEFI avec Secure Boot active | `Confirm-SecureBootUEFI` |
| **Partitionnement** | Partition systeme separee (>= 350 Mo) | `Get-Partition` |
| **Processeur** | Support AES-NI (tous les Xeon/EPYC modernes) | `wmic cpu get Name` |
| **Role BitLocker** | Feature BitLocker installee | `Get-WindowsFeature BitLocker` |

### 4.2 Etape 1 - Installer la fonctionnalite BitLocker

```powershell
# Installer BitLocker (necessite un redemarrage)
Install-WindowsFeature BitLocker -IncludeAllSubFeature -IncludeManagementTools -Restart
```

Verification apres redemarrage :

```powershell
Get-WindowsFeature BitLocker | Select-Object Name, InstallState
# Attendu : InstallState = Installed
```

### 4.3 Etape 2 - Verifier le TPM

```powershell
# Verifier la presence et l'etat du TPM
Get-Tpm

# Resultat attendu :
# TpmPresent          : True
# TpmReady            : True
# TpmEnabled          : True
# TpmActivated        : True
# ManufacturerVersion : 2.0
```

Si le TPM n'est **pas pret** :

```powershell
# Initialiser le TPM (peut necessiter un redemarrage)
Initialize-Tpm
```

> **Cas des machines virtuelles** : Si le serveur est une VM sans vTPM, utiliser le protecteur par mot de passe a la place du TPM. Voir section 4.6.

### 4.4 Etape 3 - Identifier les volumes a chiffrer

```powershell
# Lister les volumes et leur statut BitLocker
Get-BitLockerVolume | Format-Table MountPoint, VolumeType, ProtectionStatus, EncryptionPercentage, VolumeStatus
```

Volumes a chiffrer :

| Volume | Contenu | Priorite |
|---|---|---|
| `C:` | Systeme d'exploitation, binaires MariaDB | **Obligatoire** |
| `D:` (si present) | Donnees MariaDB (`datadir`), fichiers `.ibd` | **Critique** |
| Autres volumes de donnees | Sauvegardes, exports | Recommande |

### 4.5 Etape 4 - Activer BitLocker sur le volume systeme (C:)

```powershell
# 1. Activer BitLocker avec TPM + AES-256-XTS
Enable-BitLocker -MountPoint "C:" `
    -EncryptionMethod XtsAes256 `
    -TpmProtector

# 2. Ajouter une cle de recuperation (OBLIGATOIRE)
$keyProtector = Add-BitLockerKeyProtector -MountPoint "C:" -RecoveryPasswordProtector
$keyId = $keyProtector.KeyProtector | Where-Object { $_.KeyProtectorType -eq 'RecoveryPassword' } | Select-Object -Last 1

# 3. Afficher la cle de recuperation (A SAUVEGARDER IMMEDIATEMENT)
Write-Host "CLE DE RECUPERATION : $($keyId.RecoveryPassword)"
Write-Host "ID : $($keyId.KeyProtectorId)"

# 4. Sauvegarder dans Active Directory (si AD DS disponible)
Backup-BitLockerKeyProtector -MountPoint "C:" -KeyProtectorId $keyId.KeyProtectorId

# 5. Redemarrer pour lancer le chiffrement
Restart-Computer
```

### 4.6 Etape 4b - Alternative sans TPM (machines virtuelles)

Si le serveur est une VM sans TPM/vTPM, autoriser BitLocker sans TPM via GPO :

```powershell
# Methode 1 : Via registre (si pas de GPO centrale)
$regPath = "HKLM:\SOFTWARE\Policies\Microsoft\FVE"
if (-not (Test-Path $regPath)) { New-Item -Path $regPath -Force | Out-Null }
Set-ItemProperty -Path $regPath -Name "EnableBDEWithNoTPM" -Value 1 -Type DWord
Set-ItemProperty -Path $regPath -Name "UseAdvancedStartup" -Value 1 -Type DWord
Set-ItemProperty -Path $regPath -Name "UseTPM" -Value 2 -Type DWord
Set-ItemProperty -Path $regPath -Name "UseTPMPIN" -Value 2 -Type DWord
Set-ItemProperty -Path $regPath -Name "UseTPMKey" -Value 2 -Type DWord
Set-ItemProperty -Path $regPath -Name "UseTPMKeyPIN" -Value 2 -Type DWord

# Methode 2 : Via GPO locale
# gpedit.msc > Configuration ordinateur > Modeles d'administration
#   > Composants Windows > Chiffrement de lecteur BitLocker
#   > Lecteurs du systeme d'exploitation
#   > "Exiger une authentification supplementaire au demarrage"
#   > Activer + cocher "Autoriser BitLocker sans un module TPM compatible"

# Activer BitLocker avec mot de passe (saisie au demarrage)
$securePassword = Read-Host -AsSecureString "Entrez le mot de passe BitLocker"
Enable-BitLocker -MountPoint "C:" `
    -EncryptionMethod XtsAes256 `
    -PasswordProtector `
    -Password $securePassword
```

> **Attention** : En mode mot de passe, chaque redemarrage du serveur necesstera la saisie du mot de passe (ou un deverrouillage reseau). Planifier en consequence.

### 4.7 Etape 5 - Activer BitLocker sur les volumes de donnees

```powershell
# Volume de donnees (D:) - avec auto-deverrouillage par le volume systeme
Enable-BitLocker -MountPoint "D:" `
    -EncryptionMethod XtsAes256 `
    -UsedSpaceOnly `
    -RecoveryPasswordProtector

# Activer le deverrouillage automatique (le volume C: deverrouille D: au demarrage)
Enable-BitLockerAutoUnlock -MountPoint "D:"

# Sauvegarder la cle de recuperation
$dp = Get-BitLockerVolume -MountPoint "D:"
$dpKey = $dp.KeyProtector | Where-Object { $_.KeyProtectorType -eq 'RecoveryPassword' }
Write-Host "CLE DE RECUPERATION D: $($dpKey.RecoveryPassword)"
```

> **Note** : `-UsedSpaceOnly` est acceptable pour un nouveau volume. Pour un volume **deja en production** avec des donnees existantes, utiliser `-FullEncryption` (ommettre le flag `-UsedSpaceOnly`) pour chiffrer aussi l'espace libre (qui peut contenir des donnees supprimees).

### 4.8 Etape 6 - Surveiller la progression du chiffrement

```powershell
# Surveiller en temps reel
while ($true) {
    $vol = Get-BitLockerVolume
    $vol | Format-Table MountPoint, VolumeStatus, EncryptionPercentage -AutoSize
    if (($vol | Where-Object { $_.VolumeStatus -like '*Progress*' }).Count -eq 0) { break }
    Start-Sleep -Seconds 30
}
Write-Host "Chiffrement termine sur tous les volumes."
```

Duree estimee :

| Taille du volume | HDD | SSD |
|---|---|---|
| 100 Go | ~1 heure | ~15 minutes |
| 500 Go | ~5 heures | ~1 heure |
| 1 To | ~10 heures | ~2 heures |

> **Impact production** : Le chiffrement initial s'execute en arriere-plan avec une priorite basse. Les applications continuent de fonctionner normalement. L'impact sur les I/O est generalement < 10% pendant le chiffrement initial.

### 4.9 Etape 7 - Verification finale

```powershell
# Script de verification complet
Write-Host "=== VERIFICATION BITLOCKER ===" -ForegroundColor Cyan

# 1. Statut de tous les volumes
Get-BitLockerVolume | Format-Table `
    MountPoint, VolumeType, ProtectionStatus, `
    EncryptionMethod, EncryptionPercentage, VolumeStatus -AutoSize

# 2. Verification que la protection est active
$volumes = Get-BitLockerVolume
foreach ($vol in $volumes) {
    if ($vol.ProtectionStatus -eq 'On' -and $vol.EncryptionPercentage -eq 100) {
        Write-Host "[OK] $($vol.MountPoint) - Chiffre a 100% - Protection active" -ForegroundColor Green
    } elseif ($vol.VolumeStatus -like '*Progress*') {
        Write-Host "[EN COURS] $($vol.MountPoint) - Chiffrement en cours ($($vol.EncryptionPercentage)%)" -ForegroundColor Yellow
    } else {
        Write-Host "[ATTENTION] $($vol.MountPoint) - Status: $($vol.ProtectionStatus) ($($vol.EncryptionPercentage)%)" -ForegroundColor Red
    }
}

# 3. Verification TPM
$tpm = Get-Tpm
Write-Host "`nTPM Present: $($tpm.TpmPresent) | Ready: $($tpm.TpmReady)"

# 4. Verification via manage-bde (plus detaille)
manage-bde -status
```

### 4.10 Etape 8 - Sauvegarder les cles de recuperation

> **CRITIQUE** : Sans les cles de recuperation, les donnees seront **definitivement perdues** si le TPM est reinitialise, la carte mere remplacee, ou le disque deplace sur un autre serveur.

```powershell
# Exporter toutes les cles de recuperation dans un fichier securise
$recoveryFile = "C:\Sites\outils\bitlocker-recovery-keys-$(hostname)-$(Get-Date -Format 'yyyyMMdd').txt"
$volumes = Get-BitLockerVolume

foreach ($vol in $volumes) {
    $keys = $vol.KeyProtector | Where-Object { $_.KeyProtectorType -eq 'RecoveryPassword' }
    foreach ($key in $keys) {
        Add-Content -Path $recoveryFile -Value "Volume: $($vol.MountPoint)"
        Add-Content -Path $recoveryFile -Value "ID: $($key.KeyProtectorId)"
        Add-Content -Path $recoveryFile -Value "Cle: $($key.RecoveryPassword)"
        Add-Content -Path $recoveryFile -Value "---"
    }
}

Write-Host "Cles exportees dans : $recoveryFile"
Write-Host "SAUVEGARDER CE FICHIER dans un emplacement securise hors serveur."
```

Emplacements de sauvegarde recommandes :

| Methode | Securite | Recommandation |
|---|---|---|
| Active Directory (AD DS) | Haute | **Prefere** si AD disponible |
| Azure AD / Entra ID | Haute | Pour les serveurs joints a Azure AD |
| Coffre-fort physique | Haute | Impression + stockage en coffre |
| Gestionnaire de mots de passe d'entreprise | Moyenne-Haute | KeePass, Vault, etc. |
| Fichier sur un autre serveur | Moyenne | Chiffrer le fichier de cles lui-meme |

### 4.11 Etape 9 - Configurer les GPO de securite (optionnel mais recommande)

```powershell
# Forcer AES-256-XTS pour tous les volumes via registre
$regPath = "HKLM:\SOFTWARE\Policies\Microsoft\FVE"
if (-not (Test-Path $regPath)) { New-Item -Path $regPath -Force | Out-Null }

# Methode de chiffrement pour les lecteurs du systeme d'exploitation (XTS-AES 256 = 7)
Set-ItemProperty -Path $regPath -Name "EncryptionMethodWithXtsOs" -Value 7 -Type DWord

# Methode de chiffrement pour les lecteurs de donnees fixes (XTS-AES 256 = 7)
Set-ItemProperty -Path $regPath -Name "EncryptionMethodWithXtsFdv" -Value 7 -Type DWord

# Methode de chiffrement pour les lecteurs amovibles (AES-CBC 256 = 4)
Set-ItemProperty -Path $regPath -Name "EncryptionMethodWithXtsRdv" -Value 4 -Type DWord

# Forcer la sauvegarde des cles dans AD avant d'activer BitLocker
Set-ItemProperty -Path $regPath -Name "RequireActiveDirectoryBackup" -Value 1 -Type DWord
Set-ItemProperty -Path $regPath -Name "ActiveDirectoryBackup" -Value 1 -Type DWord
```

### 4.12 Resume - Checklist de mise en production

```
[ ] 1. Feature BitLocker installee + redemarrage effectue
[ ] 2. TPM 2.0 verifie et initialise (ou GPO sans TPM pour les VM)
[ ] 3. Volumes identifies (C: systeme, D: donnees)
[ ] 4. BitLocker active sur C: en XTS-AES-256
[ ] 5. BitLocker active sur D: en XTS-AES-256 + Auto-Unlock
[ ] 6. Cles de recuperation sauvegardees (AD DS / coffre-fort)
[ ] 7. Chiffrement termine a 100% sur tous les volumes
[ ] 8. Protection verifiee (ProtectionStatus = On)
[ ] 9. Test de redemarrage effectue avec succes
[ ] 10. GPO de securite appliquees (AES-256, backup AD obligatoire)
[ ] 11. Documentation mise a jour (cles, procedure de restauration)
[ ] 12. Redemarrage teste apres mise a jour BIOS/firmware (Suspend/Resume)
```

### 4.13 Architecture de chiffrement multi-couches

```
+----------------------------------------------------------+
|                    SERVEUR WINDOWS                        |
|                                                          |
|  +----------------------------------------------------+  |
|  |              BitLocker (Volume C:)                  |  |
|  |              AES-256-XTS                            |  |
|  |  +----------------------------------------------+  |  |
|  |  |           Windows Server OS                   |  |  |
|  |  |  +----------------------------------------+  |  |  |
|  |  |  |     MariaDB (binaires + config)        |  |  |  |
|  |  |  +----------------------------------------+  |  |  |
|  |  +----------------------------------------------+  |  |
|  +----------------------------------------------------+  |
|                                                          |
|  +----------------------------------------------------+  |
|  |              BitLocker (Volume D:)                  |  |
|  |              AES-256-XTS + Auto-Unlock              |  |
|  |  +----------------------------------------------+  |  |
|  |  |       MariaDB datadir (fichiers .ibd)        |  |  |
|  |  |  +----------------------------------------+  |  |  |
|  |  |  |    TDE file_key_management              |  |  |  |
|  |  |  |    AES-256-CBC (par tablespace)         |  |  |  |
|  |  |  +----------------------------------------+  |  |  |
|  |  +----------------------------------------------+  |  |
|  +----------------------------------------------------+  |
|                                                          |
|  Protection : Vol physique --> BitLocker                  |
|               Acces fichier --> TDE MariaDB               |
|               Acces reseau  --> TLS/SSL                   |
+----------------------------------------------------------+
```