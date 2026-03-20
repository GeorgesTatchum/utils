<# 

.EXAMPLE
    .\setup_monitoring_scheduler_local.ps1
    .\setup_monitoring_scheduler_local.ps1 -OutputDir "D:\cpu_baseline"
    .\setup_monitoring_scheduler_local.ps1 -DurationSeconds 600 -OutputDir "D:\monitoring"
#>

param(
    [int]$DurationSeconds = 300,
    
    [int]$SampleIntervalSec = 5,
    
    [string]$TaskName = "CPU_Monitoring_Local_Workdays",

    [string]$OutputDir = $PSScriptRoot
)

# Verifier que Task Scheduler est disponible
try {
    $SchService = Get-Service -Name Schedule -ErrorAction Stop
    if ($SchService.Status -ne "Running") {
        Write-Host "Demarrage du service Task Scheduler..." -ForegroundColor Yellow
        Start-Service -Name Schedule
        Start-Sleep -Seconds 2
    }
    Write-Host "Service Task Scheduler : OK" -ForegroundColor Green
} catch {
    Write-Host "Erreur : Service Task Scheduler non disponible" -ForegroundColor Red
    exit 1
}

# Chemin complet du script local
$ScriptPath = "C:\Sites\outils\tools\cpu_quick_eval.ps1"
if (-not (Test-Path $ScriptPath)) {
    Write-Host "Erreur : Fichier non trouve : $ScriptPath" -ForegroundColor Red
    Write-Host "Assurez-vous que cpu_quick_eval.ps1 est dans le meme dossier" -ForegroundColor Yellow
    exit 1
}

# Resoudre le chemin absolu
$OutputDir = (Resolve-Path $OutputDir).Path

Write-Host "Repertoire de sortie : $OutputDir" -ForegroundColor Green
Write-Host "Script de collecte : $ScriptPath" -ForegroundColor Green
Write-Host ""

# Construire la commande
$Arguments = @(
    "-NoProfile",
    "-ExecutionPolicy Bypass",
    "-File `"$ScriptPath`"",
    "-DurationSeconds $DurationSeconds",
    "-SampleIntervalSec $SampleIntervalSec",
    "-OutputDir `"$OutputDir`""
) -join " "

# Creer ou remplacer la tache
$TaskExists = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
if ($null -ne $TaskExists) {
    Write-Host "Tache existante detectee. Remplacement..." -ForegroundColor Yellow
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
}

# Definition de l'action (la commande a executer)
$Action = New-ScheduledTaskAction -Execute "powershell.exe" `
                                  -Argument $Arguments `
                                  -WorkingDirectory $PSScriptRoot

# Creer un trigger hebdomadaire pour lun-ven a 8h00
Write-Host "Creation du trigger hebdomadaire (lun-ven, 8h00)..." -ForegroundColor Cyan
Write-Host "Duree : $DurationSeconds secondes ($(($DurationSeconds/3600).ToString('F1')) heures)" -ForegroundColor Yellow
Write-Host "Intervalle echantillonnage : $SampleIntervalSec secondes" -ForegroundColor Yellow
Write-Host ""

$Trigger = New-ScheduledTaskTrigger -Weekly `
                                   -DaysOfWeek @("Monday", "Tuesday", "Wednesday", "Thursday", "Friday") `
                                   -At "08:00:00"

$Triggers = @($Trigger)

Write-Host "1 trigger cree" -ForegroundColor Green
Write-Host ""

# Configuration de la tache
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries `
                                         -DontStopIfGoingOnBatteries `
                                         -StartWhenAvailable `
                                         -RunOnlyIfNetworkAvailable `
                                         -MultipleInstances IgnoreNew

# Enregistrer la tache
try {
    Write-Host "Enregistrement de la tache..." -ForegroundColor Cyan
    Register-ScheduledTask -TaskName $TaskName `
                          -Action $Action `
                          -Trigger $Triggers `
                          -Settings $Settings `
                          -Force `
                          -ErrorAction Stop | Out-Null
    
    Write-Host "Tache planifiee creee avec succes" -ForegroundColor Green
    Write-Host ""
    
    # Afficher les details
    Write-Host "=== DETAILS ===" -ForegroundColor Cyan
    $Task = Get-ScheduledTask -TaskName $TaskName
    Write-Host "Nom              : $($Task.TaskName)"
    Write-Host "Chemin           : $($Task.TaskPath)"
    Write-Host "Etat             : $($Task.State)"
    Write-Host "Nombre triggers  : $($Task.Triggers.Count)"
    Write-Host ""

} catch {
    Write-Host "Erreur lors de la creation de la tache : $($_)" -ForegroundColor Red
    exit 1
}
