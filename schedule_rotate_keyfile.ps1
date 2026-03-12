# --- Rotation trimestrielle de la clé de données (key_id version) ---
$action = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument "-NoProfile -ExecutionPolicy Bypass -File `"C:\Sites\outils\tools\rotate_keyfile_enc.ps1`""

# Tous les 90 jours, à 02:00 (hors heures de travail)
$trigger = New-ScheduledTaskTrigger -Daily -DaysInterval 90 -At "02:00"

$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -DontStopOnIdleEnd
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

Register-ScheduledTask `
    -TaskName "MariaDB TDE - Rotation cle donnees (90j)" `
    -Action $action `
    -Trigger $trigger `
    -Settings $settings `
    -Principal $principal `
    -Description "Rotation trimestrielle cle TDE MariaDB (avec redemarrage du service)"

# --- Rotation annuelle de la clé d'enveloppe ---
$actionEnv = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument "-NoProfile -ExecutionPolicy Bypass -File `"C:\Sites\outils\tools\rotate_keyfile_key.ps1`""

$triggerEnv = New-ScheduledTaskTrigger -Daily -DaysInterval 365 -At "02:00"

Register-ScheduledTask `
    -TaskName "MariaDB TDE - Rotation cle enveloppe (annuel)" `
    -Action $actionEnv `
    -Trigger $triggerEnv `
    -Settings $settings `
    -Principal $principal `
    -Description "Rotation annuelle cle d'enveloppe TDE MariaDB (avec redemarrage du service)"