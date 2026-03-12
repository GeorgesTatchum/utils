<#
.SYNOPSIS
    Rotation annuelle de la cle d'enveloppe (keyfile.key) qui chiffre le fichier de cles TDE.

    Sur MariaDB < 11.8, un redemarrage du service est necessaire pour recharger
    la nouvelle cle d'enveloppe.

.NOTES
    A planifier via le Planificateur de taches Windows (annuel).
    Executer en tant qu'Administrateur.
    Service MariaDB nomme "MySQL" sur ce serveur.
#>

param(
    [string]$MariaDBVersion = "MariaDB115",
    [string]$BasePath       = "C:\Sites\outils",
    [string]$ServiceName    = "MySQL",
    [string]$ExportPath     = ""          # Chemin externe (UNC/local) ex: \\NAS\backups\TDE
)

$ErrorActionPreference = "Stop"
$encDir     = "$BasePath\$MariaDBVersion\encryption"
$logDir     = "$encDir\logs"
$LogPath    = "$logDir\tde-envelope-rotation.log"
$CycleLog   = "$logDir\tde-envelope-rotation-$((Get-Date -Format 'yyyyMMdd-HHmmss')).log"
$keyfileTmp = "$encDir\keyfile.plain.tmp"
$keyfileEnc = "$encDir\keyfile.enc"
$keyfileKey = "$encDir\keyfile.key"
$backupDir  = "$encDir\backups"
$mysqlExe   = "$BasePath\$MariaDBVersion\bin\mysql.exe"
$timestamp  = Get-Date -Format "yyyyMMdd-HHmmss"

# --- Fonction de journalisation (audit trail FDA) ---
# Ecrit dans le log principal (historique complet) ET dans le log du cycle courant
function Write-AuditLog {
    param([string]$Message)
    $entry = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] [$(whoami)] $Message"
    if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Force -Path $logDir | Out-Null }
    Add-Content -Path $LogPath  -Value $entry
    Add-Content -Path $CycleLog -Value $entry
    Write-Host $entry
}

try {
    Write-AuditLog "=== DEBUT ROTATION CLE D'ENVELOPPE ==="

    # --- 1. Backup ---
    if (-not (Test-Path $backupDir)) { New-Item -ItemType Directory -Force -Path $backupDir | Out-Null }
    Copy-Item $keyfileKey "$backupDir\keyfile.key.$timestamp" -Force
    Copy-Item $keyfileEnc "$backupDir\keyfile.enc.$timestamp" -Force
    Write-AuditLog "Backup: keyfile.key, keyfile.enc dans $backupDir"

    # --- 2. Dechiffrer avec l'ancienne cle d'enveloppe ---
    & openssl enc -aes-256-cbc -md sha1 -d `
      -pass "file:$keyfileKey" `
      -in $keyfileEnc `
      -out $keyfileTmp

    if (-not (Test-Path $keyfileTmp)) { throw "Echec du dechiffrement du keyfile.enc" }
    Write-AuditLog "Dechiffrement avec ancienne cle d'enveloppe: OK"

    # --- 3. Generer une nouvelle cle d'enveloppe ---
    $newEnvKey = & openssl rand -hex 128
    [System.IO.File]::WriteAllBytes($keyfileKey, [System.Text.Encoding]::ASCII.GetBytes($newEnvKey))
    Write-AuditLog "Nouvelle cle d'enveloppe generee ($($newEnvKey.Length) caracteres)"

    # --- 4. Re-chiffrer avec la nouvelle cle d'enveloppe ---
    & openssl enc -aes-256-cbc -md sha1 `
      -pass "file:$keyfileKey" `
      -in $keyfileTmp `
      -out $keyfileEnc

    # --- 5. Verifier ---
    $verify = & openssl enc -aes-256-cbc -md sha1 -d `
      -pass "file:$keyfileKey" `
      -in $keyfileEnc
    $verifyString = ($verify -join "`n")
    if ([string]::IsNullOrWhiteSpace($verifyString)) { throw "Verification du re-chiffrement echouee: contenu vide" }
    Write-AuditLog "Verification re-chiffrement nouvelle enveloppe: OK"
    Write-AuditLog "Contenu verifie: $($verify.Count) ligne(s) de cles"

    # --- 6. Nettoyer le fichier temporaire ---
    Remove-Item $keyfileTmp -Force

    # --- 7. Redemarrer le service (seul moyen de recharger la cle < 11.8) ---
    Write-AuditLog "Arret du service $ServiceName..."
    Stop-Service -Name $ServiceName -Force
    Start-Sleep -Seconds 3

    $svc = Get-Service -Name $ServiceName
    if ($svc.Status -ne 'Stopped') {
        Start-Sleep -Seconds 5
        $svc = Get-Service -Name $ServiceName
        if ($svc.Status -ne 'Stopped') { throw "Le service $ServiceName ne s'est pas arrete" }
    }
    Write-AuditLog "Service $ServiceName arrete"

    Write-AuditLog "Demarrage du service $ServiceName..."
    Start-Service -Name $ServiceName
    Start-Sleep -Seconds 5

    $maxRetries = 12
    $ready = $false
    for ($i = 1; $i -le $maxRetries; $i++) {
        try {
            $testResult = (& $mysqlExe -u root -N -B -e "SELECT 1;" 2>$null)
            if ($testResult -match "1") {
                $ready = $true
                break
            }
        } catch { }
        Write-AuditLog "Attente demarrage MariaDB... ($i/$maxRetries)"
        Start-Sleep -Seconds 5
    }
    if (-not $ready) { throw "MariaDB n'a pas demarre apres le redemarrage du service" }
    Write-AuditLog "Service $ServiceName demarre et pret"

    # --- 8. Snapshot etat chiffrement (preuve FDA) ---
    Write-AuditLog "--- SNAPSHOT ETAT CHIFFREMENT APRES ROTATION ENVELOPPE ---"
    $encStatusQuery = "SELECT NAME AS 'Table/Space', ENCRYPTION_SCHEME AS 'Encrypted', CURRENT_KEY_ID AS 'KeyID', ROTATING_OR_FLUSHING AS 'Rotating' FROM INFORMATION_SCHEMA.INNODB_TABLESPACES_ENCRYPTION;"
    $encStatus = @(& $mysqlExe -u root -e $encStatusQuery 2>$null)
    foreach ($row in $encStatus) {
        Write-AuditLog "  $row"
    }

    Write-AuditLog "=== ROTATION CLE D'ENVELOPPE TERMINEE AVEC SUCCES ==="
    Write-AuditLog "Log de ce cycle : $CycleLog"

    # PHASE : Export externe des artefacts (cles + backups + logs)

    if (-not [string]::IsNullOrWhiteSpace($ExportPath)) {
        $exportDest = "$ExportPath\$($env:COMPUTERNAME)\encryption"
        Write-AuditLog "--- EXPORT EXTERNE ---"
        Write-AuditLog "Destination: $exportDest"
        try {
            $robocopyArgs = @($encDir, $exportDest, '/MIR', '/R:3', '/W:5', '/NP', '/NDL', '/NFL')
            & robocopy @robocopyArgs | Out-Null
            $rc = $LASTEXITCODE
            if ($rc -ge 8) { throw "robocopy code $rc" }
            Write-AuditLog "Export externe termine (robocopy exit: $rc)"
        } catch {
            Write-AuditLog "AVERTISSEMENT EXPORT: $($_.Exception.Message)"
            Write-AuditLog "La rotation a reussi mais l'export externe a echoue."
            Write-AuditLog "Export manuel: robocopy $encDir $exportDest /MIR"
        }
    } else {
        Write-AuditLog "AVERTISSEMENT: -ExportPath non defini - export externe ignore"
        Write-AuditLog "Recommande: relancer avec -ExportPath \\NAS\backups\TDE"
    }

} catch {
    $errorMessage = $_.Exception.Message
    Write-AuditLog "ERREUR: $errorMessage"
    Write-AuditLog "=== ROTATION ECHOUEE ==="
    Write-AuditLog "Pour restaurer : copier les fichiers depuis $backupDir"
    Write-AuditLog "  Copy-Item $backupDir\keyfile.key.$timestamp $keyfileKey"
    Write-AuditLog "  Copy-Item $backupDir\keyfile.enc.$timestamp $keyfileEnc"
    Write-AuditLog "  Restart-Service $ServiceName"
    throw $_
}