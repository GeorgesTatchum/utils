<#
.SYNOPSIS
    Rotation périodique de la clé de chiffrement MariaDB TDE (file_key_management).
    Le plugin file_key_management ne gère PAS les versions de clés.
    La rotation se fait par ajout d'un NOUVEL ID de clé (1, 2, 3...).

    Sur MariaDB < 11.8, il n'y a PAS de FLUSH FILE_KEY_MANAGEMENT_KEYS.
    Le seul moyen de recharger les clés est de REDÉMARRER le service.

    Séquence :
      1. Ajouter la nouvelle clé dans keyfile.enc
      2. Mettre à jour my.ini (innodb_default_encryption_key_id)
      3. Redémarrer le service MySQL
      4. ALTER TABLE chaque table pour re-chiffrer avec le nouveau key_id

.NOTES
    À planifier via le Planificateur de tâches Windows (trimestriel).
    Exécuter en tant qu'Administrateur.
    Service MariaDB nommé "MySQL" sur ce serveur.
#>

param(
    [string]$MariaDBVersion = "MariaDB115",
    [string]$BasePath       = "C:\Sites\outils",
    [string]$ServiceName    = "MySQL"
)

$ErrorActionPreference = "Stop"
$encDir     = "$BasePath\$MariaDBVersion\encryption"
$logDir     = "$encDir\logs"
$LogPath    = "$logDir\tde-rotation.log"
$CycleLog   = "$logDir\tde-rotation-$((Get-Date -Format 'yyyyMMdd-HHmmss')).log"
$keyfileTmp = "$encDir\keyfile.tmp"
$keyfileEnc = "$encDir\keyfile.enc"
$keyfileKey = "$encDir\keyfile.key"
$backupDir  = "$encDir\backups"
$myIniPath  = "$BasePath\$MariaDBVersion\data\my.ini"
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
    Write-AuditLog "=== DEBUT ROTATION DE CLE TDE ==="
    Write-AuditLog "MariaDB < 11.8 : rotation avec redemarrage du service '$ServiceName'"

    # PHASE 1 : Mise à jour des fichiers (keyfile.enc + my.ini)

    # --- 1. Sauvegarder les fichiers actuels ---
    if (-not (Test-Path $backupDir)) { New-Item -ItemType Directory -Force -Path $backupDir | Out-Null }
    Copy-Item $keyfileEnc "$backupDir\keyfile.enc.$timestamp" -Force
    Copy-Item $keyfileKey "$backupDir\keyfile.key.$timestamp" -Force
    if (Test-Path $myIniPath) {
        Copy-Item $myIniPath "$backupDir\my.ini.$timestamp" -Force
    }
    Write-AuditLog "Backup: keyfile.enc, keyfile.key, my.ini dans $backupDir"

    # --- 2. Déchiffrer le keyfile actuel ---
    & openssl enc -aes-256-cbc -md sha1 -d `
      -pass "file:$keyfileKey" `
      -in $keyfileEnc `
      -out $keyfileTmp

    if (-not (Test-Path $keyfileTmp)) { throw "Echec du dechiffrement du keyfile.enc" }
    Write-AuditLog "Dechiffrement du keyfile.enc reussi"

    # --- 3. Déterminer le key_id le plus élevé ---
    # Format file_key_management : <key_id>;<hex_key>
    $lines = @(Get-Content $keyfileTmp | Where-Object { $_.Trim() -ne "" })
    $maxKeyId = 0

    foreach ($line in $lines) {
        $parts = $line -split ";"
        if ($parts.Count -ge 2) {
            $id = [int]$parts[0]
            if ($id -gt $maxKeyId) { $maxKeyId = $id }
        }
    }
    if ($maxKeyId -eq 0) { throw "Format de cle invalide : attendu '<key_id>;<hex_key>'." }
    $newKeyId = $maxKeyId + 1
    Write-AuditLog "Key ID actuel: $maxKeyId -> Nouveau key_id: $newKeyId"

    # --- 4. Générer une nouvelle clé AES-256 ---
    $newKeyHex = & openssl rand -hex 32

    # --- 5. Ajouter la nouvelle clé avec le nouvel ID ---
    $newLine = "$newKeyId;$newKeyHex"
    $allLines = $lines + $newLine
    $finalContent = ($allLines -join "`n") + "`n"
    [System.IO.File]::WriteAllBytes($keyfileTmp, [System.Text.Encoding]::ASCII.GetBytes($finalContent))
    Write-AuditLog "Nouvelle cle generee (key_id=$newKeyId)"

    # --- 6. Re-chiffrer le fichier de clés ---
    & openssl enc -aes-256-cbc -md sha1 `
      -pass "file:$keyfileKey" `
      -in $keyfileTmp `
      -out $keyfileEnc

    # --- 7. Vérifier le re-chiffrement ---
    $verifyOutput = & openssl enc -aes-256-cbc -md sha1 -d `
      -pass "file:$keyfileKey" `
      -in $keyfileEnc
    $verifyString = ($verifyOutput -join "`n")

    if ($verifyString -notmatch [regex]::Escape($newKeyHex)) { throw "Verification du chiffrement echouee" }
    Write-AuditLog "Verification re-chiffrement keyfile.enc: OK"

    # --- 8. Nettoyer le fichier temporaire ---
    Remove-Item $keyfileTmp -Force

    # --- 9. Mettre à jour my.ini AVANT le redémarrage ---
    if (Test-Path $myIniPath) {
        $iniContent = Get-Content $myIniPath -Raw

        if ($iniContent -match "innodb_default_encryption_key_id") {
            $iniContent = $iniContent -replace "innodb_default_encryption_key_id\s*=\s*\d+", "innodb_default_encryption_key_id = $newKeyId"
        } else {
            # Ajouter sous la section [mariadb]
            $iniContent = $iniContent -replace "(\[mariadb\])", "`$1`r`ninnodb_default_encryption_key_id = $newKeyId"
        }

        [System.IO.File]::WriteAllText($myIniPath, $iniContent)
        Write-AuditLog "my.ini mis a jour: innodb_default_encryption_key_id = $newKeyId"
    } else {
        Write-AuditLog "ATTENTION: my.ini non trouve a $myIniPath"
        throw "my.ini introuvable - impossible de persister le nouveau key_id"
    }

    # PHASE 2 : Redémarrage du service (seul moyen de recharger les clés < 11.8)

    Write-AuditLog "Arret du service $ServiceName..."
    Stop-Service -Name $ServiceName -Force
    Start-Sleep -Seconds 3

    # Vérifier que le service est bien arrêté
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

    # Attendre que MariaDB soit prêt (tester la connexion)
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

    # Vérifier que le nouveau key_id est bien chargé
    $keyCheck = (& $mysqlExe -u root -N -B -e "SHOW GLOBAL VARIABLES LIKE 'innodb_default_encryption_key_id';" 2>$null)
    Write-AuditLog "Verification innodb_default_encryption_key_id: $keyCheck"

    # --- Snapshot AVANT re-chiffrement (preuve FDA) ---
    Write-AuditLog "--- SNAPSHOT CHIFFREMENT AVANT RE-CHIFFREMENT ---"
    $encStatusQuery = "SELECT NAME AS 'Table/Space', ENCRYPTION_SCHEME AS 'Encrypted', CURRENT_KEY_ID AS 'KeyID', ROTATING_OR_FLUSHING AS 'Rotating' FROM INFORMATION_SCHEMA.INNODB_TABLESPACES_ENCRYPTION;"
    $encStatusBefore = @(& $mysqlExe -u root -e $encStatusQuery 2>$null)
    foreach ($row in $encStatusBefore) {
        Write-AuditLog "  $row"
    }

    # PHASE 3 : Re-chiffrer les tables existantes avec le nouveau key_id

    $query = "SELECT TABLE_SCHEMA, TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE ENGINE='InnoDB' AND TABLE_SCHEMA NOT IN ('information_schema','performance_schema','sys');"
    $rawTables = @(& $mysqlExe -u root -N -B -e "$query" 2>$null)

    $tableCount = 0
    $errorCount = 0
    foreach ($line in $rawTables) {
        $parts = $line -split "`t"
        if ($parts.Count -lt 2) { continue }

        $schema = $parts[0].Trim()
        $name   = $parts[1].Trim()

        if ($schema -notmatch '^[a-zA-Z0-9_]+$' -or $name -notmatch '^[a-zA-Z0-9_]+$') { continue }

        $fullTable = "``$schema``.``$name``"
        try {
            & $mysqlExe -u root -e "ALTER TABLE $fullTable ENCRYPTION_KEY_ID=$newKeyId;" 2>&1 | Out-Null
            $tableCount++
        } catch {
            Write-AuditLog "AVERTISSEMENT: Echec ALTER TABLE $fullTable : $($_.Exception.Message)"
            $errorCount++
        }
    }
    Write-AuditLog "Re-chiffrement: $tableCount table(s) OK, $errorCount echec(s)"

    # --- Snapshot APRES re-chiffrement (preuve FDA) ---
    Write-AuditLog "--- SNAPSHOT CHIFFREMENT APRES RE-CHIFFREMENT ---"
    $encStatusAfter = @(& $mysqlExe -u root -e $encStatusQuery 2>$null)
    foreach ($row in $encStatusAfter) {
        Write-AuditLog "  $row"
    }

    Write-AuditLog "=== ROTATION TERMINEE AVEC SUCCES (key_id=$newKeyId) ==="
    Write-AuditLog "Log de ce cycle : $CycleLog"

} catch {
    $errorMessage = $_.Exception.Message
    Write-AuditLog "ERREUR : $errorMessage"
    Write-AuditLog "=== ROTATION ECHOUEE ==="
    Write-AuditLog "Pour restaurer : copier les fichiers depuis $backupDir"
    Write-AuditLog "  Copy-Item $backupDir\keyfile.enc.$timestamp $keyfileEnc"
    Write-AuditLog "  Copy-Item $backupDir\my.ini.$timestamp $myIniPath"
    Write-AuditLog "  Restart-Service $ServiceName"
    throw $_
}