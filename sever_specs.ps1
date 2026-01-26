# --- Configuration de l'affichage ---
Clear-Host
$ErrorActionPreference = "SilentlyContinue"


$OS = Get-CimInstance Win32_OperatingSystem
$CS = Get-CimInstance Win32_ComputerSystem

$IPs = Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -notlike "*Loopback*" } | Select-Object -ExpandProperty IPAddress

Write-Host "`n--- [1] GÉNÉRAL ---" -ForegroundColor Yellow
Write-Host "Hostname       : " -NoNewline; Write-Host $CS.Name -ForegroundColor White
Write-Host "Adresse(s) IP  : " -NoNewline; Write-Host ($IPs -join ", ") -ForegroundColor White
Write-Host "Système (OS)   : " -NoNewline; Write-Host "$($OS.Caption) (Build $($OS.BuildNumber))" -ForegroundColor White
Write-Host "Architecture   : " -NoNewline; Write-Host $OS.OSArchitecture -ForegroundColor White

# CPU
$CPU = Get-CimInstance Win32_Processor

# On fait la moyenne de charge si plusieurs CPU
$CPULoad = ($CPU | Measure-Object -Property LoadPercentage -Average).Average

Write-Host "`n--- [2] CPU ---" -ForegroundColor Yellow
Write-Host "Modèle         : " -NoNewline; Write-Host $CPU[0].Name -ForegroundColor White
Write-Host "Nombre de Cœurs: " -NoNewline; Write-Host "$($CPU.NumberOfCores) Cores (Logiques: $($CPU.NumberOfLogicalProcessors))" -ForegroundColor White
Write-Host "Utilisation    : " -NoNewline; 
if ($CPULoad -gt 80) { Write-Host "$CPULoad % (Élevée)" -ForegroundColor Red }
else { Write-Host "$CPULoad %" -ForegroundColor Green }

# RAM
# Conversion des valeurs (Win32_OperatingSystem donne des KB)
$TotalRAM = [math]::Round($OS.TotalVisibleMemorySize / 1MB, 2)
$FreeRAM  = [math]::Round($OS.FreePhysicalMemory / 1MB, 2)
$UsedRAM  = [math]::Round($TotalRAM - $FreeRAM, 2)
$PercentRAM = [math]::Round(($UsedRAM / $TotalRAM) * 100, 1)

Write-Host "`n--- RAM ---" -ForegroundColor Yellow
Write-Host "Total          : " -NoNewline; Write-Host "$TotalRAM Go" -ForegroundColor White
Write-Host "Utilisé        : " -NoNewline; Write-Host "$UsedRAM Go ($PercentRAM %)" -ForegroundColor White

# GPU
Write-Host "`n--- GPU (Graphique) ---" -ForegroundColor Yellow
$GPUs = Get-CimInstance Win32_VideoController
if ($GPUs) {
    foreach ($gpu in $GPUs) {
        Write-Host "Modèle         : $($gpu.Name)"
        if ($gpu.AdapterRAM) {
            $GpuRam = [math]::Round($gpu.AdapterRAM / 1GB, 2)
            Write-Host "VRAM (Mémoire) : $GpuRam Go"
        }
    }
} else {
    Write-Host "Aucun GPU détecté (Serveur Headless ou VM)" -ForegroundColor DarkGray
}

# Disques Logiques & Physiques
Write-Host "`n--- STOCKAGE ---" -ForegroundColor Yellow


Write-Host ">> Type de Disques Physiques :" -ForegroundColor Gray
try {
    Get-PhysicalDisk | Select-Object FriendlyName, MediaType, @{N="Taille(Go)";E={[math]::Round($_.Size/1GB, 0)}} | Format-Table -AutoSize | Out-String | Write-Host
} catch {
    Write-Host "Impossible de déterminer le type physique (Pilote RAID ou VM générique)." -ForegroundColor Red
}

# Espace Disque (Volumes C:, D:, etc.)
Write-Host ">> Espace par Volume :" -ForegroundColor Gray
$Disks = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" # 3 = Disque dur local
foreach ($disk in $Disks) {
    $Total = [math]::Round($disk.Size / 1GB, 2)
    $Free  = [math]::Round($disk.FreeSpace / 1GB, 2)
    $Used  = [math]::Round($Total - $Free, 2)
    $PercentDisk = [math]::Round(($Used / $Total) * 100, 1)
    
    # Barre de progression visuelle simple
    $Color = "Green"
    if ($PercentDisk -gt 90) { $Color = "Red" } elseif ($PercentDisk -gt 75) { $Color = "Yellow" }
    
    Write-Host "Volume $($disk.DeviceID) " -NoNewline
    Write-Host "$Used Go utilisés / $Total Go Total " -NoNewline
    Write-Host "($PercentDisk %)" -ForegroundColor $Color
}

Write-Host "`n==============================================" -ForegroundColor Cyan