<#
.SYNOPSIS
    Evaluation rapide de la consommation CPU/vCPU sur une machine distante.
    
.PARAMETER DurationSeconds
    Duree totale de la collecte en secondes (defaut: 300 = 5 min)
    
.PARAMETER SampleIntervalSec
    Intervalle entre chaque mesure en secondes (defaut: 5)
    
.EXAMPLE
    .\cpu_quick_eval.ps1 -DurationSeconds 600
#>

param(
    
    [int]$DurationSeconds = 300,
    
    [int]$SampleIntervalSec = 5,
    
    [string]$OutputDir = $PSScriptRoot
)



$MaxSamples = [Math]::Ceiling($DurationSeconds / $SampleIntervalSec)
Write-Host "Collecte : $MaxSamples echantillons toutes les ${SampleIntervalSec}s = ${DurationSeconds}s total" -ForegroundColor Yellow

# Script a executer sur la cible
$ScriptBlock = {
    param($SampleIntervalSec, $MaxSamples)
    
    $culture = [System.Globalization.CultureInfo]::CurrentCulture.Name

    if ($culture -like "fr-*") {
        $counter = '\processeur(_total)\% temps processeur'
    } else {
        $counter = '\processor(_total)\% processor time'
    }
    $samples = Get-Counter -Counter $counter -SampleInterval $SampleIntervalSec -MaxSamples $MaxSamples
    $values  = $samples.CounterSamples | Select-Object -ExpandProperty CookedValue

    # Calculs statistiques
    $avg = ($values | Measure-Object -Average).Average
    $max = ($values | Measure-Object -Maximum).Maximum
    $min = ($values | Measure-Object -Minimum).Minimum
    
    # P95
    $sorted = $values | Sort-Object
    $p95Index = [Math]::Ceiling($sorted.Count * 0.95) - 1
    $p95 = $sorted[[Math]::Max($p95Index, 0)]

    # P50 (mediane)
    $p50Index = [Math]::Ceiling($sorted.Count * 0.50) - 1
    $p50 = $sorted[[Math]::Max($p50Index, 0)]

    # Infos CPU
    $cpuInfo = Get-CimInstance Win32_Processor
    $vCpuAllocated = ($cpuInfo | Measure-Object -Property NumberOfLogicalProcessors -Sum).Sum
    $coresVisible  = ($cpuInfo | Measure-Object -Property NumberOfCores -Sum).Sum
    $cpuModel      = $cpuInfo[0].Name

    [PSCustomObject]@{
        ComputerName           = $env:COMPUTERNAME
        vCPU_Allocated         = [int]$vCpuAllocated
        Cores_Visible          = [int]$coresVisible
        CPU_Model              = $cpuModel
        Samples_Collected      = $sorted.Count
        Duration_Seconds       = $SampleIntervalSec * $sorted.Count
        Min_CPU_Pct            = [Math]::Round($min, 2)
        P50_CPU_Pct            = [Math]::Round($p50, 2)
        Avg_CPU_Pct            = [Math]::Round($avg, 2)
        P95_CPU_Pct            = [Math]::Round($p95, 2)
        Max_CPU_Pct            = [Math]::Round($max, 2)
        Min_vCPU_Consumed      = [Math]::Round($vCpuAllocated * $min / 100, 2)
        P50_vCPU_Consumed      = [Math]::Round($vCpuAllocated * $p50 / 100, 2)
        Avg_vCPU_Consumed      = [Math]::Round($vCpuAllocated * $avg / 100, 2)
        P95_vCPU_Consumed      = [Math]::Round($vCpuAllocated * $p95 / 100, 2)
        Max_vCPU_Consumed      = [Math]::Round($vCpuAllocated * $max / 100, 2)
    }
}

# Execution
$result = Invoke-Command -ScriptBlock $ScriptBlock `
                         -ArgumentList $SampleIntervalSec, $MaxSamples `
                         -ErrorAction Stop

Write-Host "`n=== RESULTATS ===" -ForegroundColor Cyan
$result | Format-List

Write-Host "`n=== RESUME ===" -ForegroundColor Yellow
Write-Host "Machine           : $($result.ComputerName)" 
Write-Host "vCPU alloues      : $($result.vCPU_Allocated)"
Write-Host "Utilisation moy.  : $($result.Avg_CPU_Pct)%"
Write-Host "Utilisation P95   : $($result.P95_CPU_Pct)%"
Write-Host "vCPU consommes moy: $($result.Avg_vCPU_Consumed)/$($result.vCPU_Allocated)"
Write-Host "vCPU consommes P95: $($result.P95_vCPU_Consumed)/$($result.vCPU_Allocated)"

$CsvPath = Join-Path $OutputDir "cpu_eval_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
$result | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
Write-Host "`nFichier CSV exporte : $CsvPath" -ForegroundColor Green