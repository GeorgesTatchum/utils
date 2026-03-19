<#
.SYNOPSIS
    Analyse des rapports CSV de monitoring CPU et génération d'un rapport synthétique.
    
.DESCRIPTION
    Ce script :
    - Lit tous les fichiers CSV de collecte CPU d'un répertoire
    - Agrège les données de plusieurs exécutions
    - Calcule des statistiques avancées (moyenne, P50, P95, P99, max)
    - Génère un rapport HTML avec graphiques
    - Exporte un JSON récapitulatif pour agrégation multi-serveurs
    
.PARAMETER InputDir
    Répertoire contenant les fichiers csv_ générés par cpu_quick_eval.ps1
    
.PARAMETER OutputDir
    Répertoire de sortie pour les rapports (HTML et JSON)
    
.PARAMETER ServerName
    Nom du serveur (optionnel, sinon utilise le nom local)
    
.EXAMPLE
    .\cpu_analysis_report.ps1 -InputDir "C:\Sites\outils\cpu_monitoring" -OutputDir "C:\Reports"
    .\cpu_analysis_report.ps1 -InputDir "C:\monitoring" -ServerName "PROD-WEB-01"
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$InputDir,
    
    [string]$OutputDir = $PSScriptRoot,
    
    [string]$ServerName = $env:COMPUTERNAME
)

# Vérification des répertoires
if (-not (Test-Path $InputDir)) {
    Write-Host "Erreur : Répertoire d'entrée non trouvé : $InputDir" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
    Write-Host "Répertoire de sortie créé : $OutputDir" -ForegroundColor Yellow
}

Write-Host "Analyse CPU : $ServerName" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# Collecte des CSV
$CsvFiles = @(Get-ChildItem -Path $InputDir -Filter "cpu_eval_*.csv" -ErrorAction SilentlyContinue)

if ($CsvFiles.Count -eq 0) {
    Write-Host "Aucun fichier CSV trouvé dans $InputDir" -ForegroundColor Yellow
    exit 0
}

Write-Host "Fichiers CSV trouvés : $($CsvFiles.Count)" -ForegroundColor Green

# Fusion des données
$allData = @()
foreach ($csvFile in $CsvFiles) {
    try {
        $data = Import-Csv -Path $csvFile.FullName -ErrorAction Stop
        $allData += $data
    } catch {
        Write-Host "Erreur lecture $($csvFile.Name) : $_" -ForegroundColor Yellow
    }
}

if ($allData.Count -eq 0) {
    Write-Host "Aucune donnée valide à analyser" -ForegroundColor Yellow
    exit 0
}

Write-Host "Enregistrements importés : $($allData.Count)" -ForegroundColor Green
Write-Host ""

# Conversion en nombres (remplacer virgules par points)
$avgValues = $allData | ForEach-Object { [float]($_.Avg_CPU_Pct -replace ',', '.') }
$p95Values = $allData | ForEach-Object { [float]($_.P95_CPU_Pct -replace ',', '.') }
$maxValues = $allData | ForEach-Object { [float]($_.Max_CPU_Pct -replace ',', '.') }

# Infos serveur (identiques dans tous les CSV)
$vCpuAllocated = [int]$allData[0].vCPU_Allocated
$cpuModel = $allData[0].CPU_Model
$coresVisible = [int]$allData[0].Cores_Visible

# Calculs : moyenne des moyennes, moyenne des P95, pic observé
$overallAvg = ($avgValues | Measure-Object -Average).Average
$overallP95 = ($p95Values | Measure-Object -Average).Average
$overallMax = ($maxValues | Measure-Object -Maximum).Maximum

# Calcul de la recommandation vCPU basée sur P95
# Règle : utiliser le P95 observé + 20% de marge
$recommendedCpu = [Math]::Ceiling(($vCpuAllocated * $overallP95 / 100) * 1.2)

# Affichage des résultats
Write-Host "=== STATISTIQUES CPU ===" -ForegroundColor Cyan
Write-Host "Serveur              : $ServerName"
Write-Host "Modèle CPU           : $cpuModel"
Write-Host "vCPU alloués         : $vCpuAllocated"
Write-Host "Cores visibles       : $coresVisible"
Write-Host "Exécutions analysées : $($allData.Count)"
Write-Host ""

Write-Host "Utilisation moyenne (moyenne de tous les prélèvements):" -ForegroundColor Yellow
Write-Host "  Valeur   : $([Math]::Round($overallAvg, 2))%"
Write-Host ""

Write-Host "P95 CPU (percentile 95 observé en moyenne):" -ForegroundColor Yellow
Write-Host "  Valeur   : $([Math]::Round($overallP95, 2))%"
Write-Host ""

Write-Host "Pic CPU (pic absolu observé):" -ForegroundColor Yellow
Write-Host "  Valeur   : $([Math]::Round($overallMax, 2))%"
Write-Host ""

Write-Host "=== RECOMMANDATION ===" -ForegroundColor Green
Write-Host "Basée sur P95 + 20% marge :"
Write-Host "  P95 observé      : $([Math]::Round($overallP95, 2))%"
Write-Host "  vCPU recommandés : $recommendedCpu / $vCpuAllocated"
Write-Host "  Gain possible    : $($vCpuAllocated - $recommendedCpu) vCPU ($([Math]::Round((($vCpuAllocated - $recommendedCpu) / $vCpuAllocated) * 100, 1))%)"
Write-Host ""

# Création du JSON pour agrégation multi-serveurs
$jsonSummary = [PSCustomObject]@{
    ServerName             = $ServerName
    Timestamp              = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    vCPU_Allocated         = $vCpuAllocated
    CPU_Model              = $cpuModel
    Cores_Visible          = $coresVisible
    Samples_Count          = $allData.Count
    Avg_CPU_Usage_Pct      = [Math]::Round($overallAvg, 2)
    P95_CPU_Pct            = [Math]::Round($overallP95, 2)
    Max_Recorded_CPU_Pct   = [Math]::Round($overallMax, 2)
    vCPU_Recommended       = $recommendedCpu
    Margin_Allocated_Pct   = [Math]::Round(($recommendedCpu / $vCpuAllocated) * 100, 2)
}

$jsonPath = Join-Path $OutputDir "cpu_summary_${ServerName}_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
$jsonContent = $jsonSummary | ConvertTo-Json
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($jsonPath, $jsonContent, $Utf8NoBom)
Write-Host "JSON exporté : $jsonPath" -ForegroundColor Green

# Création du rapport HTML
$htmlPath = Join-Path $OutputDir "cpu_analysis_${ServerName}_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"

$htmlContent = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rapport Analyse CPU - $ServerName</title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            margin: 20px;
            background-color: #f5f5f5;
            color: #333;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
            background: white;
            padding: 20px;
            border-radius: 8px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        h1 {
            color: #0066cc;
            border-bottom: 3px solid #0066cc;
            padding-bottom: 10px;
        }
        h2 {
            color: #333;
            margin-top: 30px;
            margin-bottom: 15px;
        }
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
            margin: 20px 0;
        }
        .stat-card {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 20px;
            border-radius: 8px;
            text-align: center;
        }
        .stat-card.warning {
            background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);
        }
        .stat-card.success {
            background: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%);
        }
        .stat-value {
            font-size: 28px;
            font-weight: bold;
            margin: 10px 0;
        }
        .stat-label {
            font-size: 12px;
            opacity: 0.9;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin: 15px 0;
        }
        th, td {
            padding: 12px;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }
        th {
            background-color: #0066cc;
            color: white;
        }
        tr:hover {
            background-color: #f9f9f9;
        }
        .chart-container {
            position: relative;
            width: 100%;
            height: 300px;
            margin: 30px 0;
        }
        .recommendation {
            background: #e8f5e9;
            border-left: 4px solid #4caf50;
            padding: 15px;
            margin: 20px 0;
            border-radius: 4px;
        }
        .footer {
            text-align: center;
            margin-top: 40px;
            padding-top: 20px;
            border-top: 1px solid #ddd;
            color: #999;
            font-size: 12px;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Rapport Analyse CPU - $ServerName</h1>
        <p><strong>G&eacute;n&eacute;r&eacute;:</strong> $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')</p>
        
        <h2>Informations Serveur</h2>
        <table>
            <tr>
                <td><strong>Serveur</strong></td>
                <td>$ServerName</td>
            </tr>
            <tr>
                <td><strong>Modèle CPU</strong></td>
                <td>$cpuModel</td>
            </tr>
            <tr>
                <td><strong>vCPU Alloués</strong></td>
                <td>$vCpuAllocated</td>
            </tr>
            <tr>
                <td><strong>Cores Visibles</strong></td>
                <td>$coresVisible</td>
            </tr>
            <tr>
                <td><strong>Périodes Analysées</strong></td>
                <td>$($allData.Count) mesures</td>
            </tr>
        </table>
        
        <h2>Statistiques Cl&eacute;s</h2>
        <div class="stats-grid">
            <div class="stat-card">
                <div class="stat-label">Utilisation Moyenne</div>
                <div class="stat-value">$([Math]::Round($overallAvg, 1))%</div>
            </div>
            <div class="stat-card warning">
                <div class="stat-label">P95 (Percentile 95)</div>
                <div class="stat-value">$([Math]::Round($overallP95, 1))%</div>
            </div>
            <div class="stat-card warning">
                <div class="stat-label">Pic Observ&eacute;</div>
                <div class="stat-value">$([Math]::Round($overallMax, 1))%</div>
            </div>
            <div class="stat-card success">
                <div class="stat-label">vCPU Recommand&eacute;s</div>
                <div class="stat-value">$recommendedCpu</div>
            </div>
        </div>
        
        <div class="recommendation">
            <h3>📊 Recommandation</h3>
            <p><strong>Bas&eacute;e sur P95 + 20% marge de s&eacute;curit&eacute;</strong></p>
            <p>P95 observ&eacute; : <strong>$([Math]::Round($overallP95, 2))%</strong></p>
            <p>vCPU actuels : <strong>$vCpuAllocated</strong> | vCPU recommand&eacute;s : <strong>$recommendedCpu</strong></p>
            <p>Potentiel d'&eacute;conomie : <strong>$($vCpuAllocated - $recommendedCpu) vCPU</strong> ($([Math]::Round((($vCpuAllocated - $recommendedCpu) / $vCpuAllocated) * 100, 1))%)</p>
        </div>
        
        <h2>D&eacute;tails des Mesures</h2>
        <table>
            <thead>
                <tr>
                    <th>Métrique</th>
                    <th>Valeur</th>
                </tr>
            </thead>
            <tbody>
                <tr>
                    <td><strong>Utilisation Moyenne (%)</strong></td>
                    <td>$([Math]::Round($overallAvg, 2))%</td>
                </tr>
                <tr>
                    <td><strong>P95 (%)</strong></td>
                    <td>$([Math]::Round($overallP95, 2))%</td>
                </tr>
                <tr>
                    <td><strong>Pic CPU (%)</strong></td>
                    <td>$([Math]::Round($overallMax, 2))%</td>
                </tr>
            </tbody>
        </table>
        
        <div class="footer">
            <p>Rapport g&eacute;n&eacute;r&eacute; automatiquement par cpu_analysis_report.ps1</p>
        </div>
    </div>
</body>
</html>
"@

$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($htmlPath, $htmlContent, $Utf8NoBom)
Write-Host "Rapport HTML exporté : $htmlPath" -ForegroundColor Green
Write-Host ""
