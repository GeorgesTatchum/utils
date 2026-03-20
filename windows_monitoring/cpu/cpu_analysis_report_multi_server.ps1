<#
.SYNOPSIS
    Agrégation et synthèse multi-serveurs pour analyse globale de vCPU.
    
.DESCRIPTION
    Ce script :
    - Lit tous les fichiers JSON générés par cpu_analysis_report.ps1
    - Agrège les données CPU de tous les serveurs
    - Calcule la consommation réelle consolidée
    - Détermine les vCPU nécessaires si consolidation sur 1 serveur
    - Génère un rapport HTML complet pour décision d'infra
    
.PARAMETER InputDir
    Répertoire contenant les fichiers json_ générés (défaut: répertoire courant)
    
.PARAMETER OutputDir
    Répertoire de sortie pour rapport HTML et JSON (défaut: répertoire courant)
    
.PARAMETER ConsolidationScenario
    Nom du scénario de consolidation (ex: "Datacenter-A", "Production")
    
.EXAMPLE
    .\cpu_analysis_report_multi_server.ps1 -InputDir "C:\Reports" -OutputDir "C:\Reports\Consolidation"
    .\cpu_analysis_report_multi_server.ps1 -InputDir "C:\Reports" -ConsolidationScenario "Migration-DC1"
#>

param(
    [string]$InputDir = $PSScriptRoot,
    
    [string]$OutputDir = $PSScriptRoot,
    
    [string]$ConsolidationScenario = "Global"
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

Write-Host "Agrégation Multi-Serveurs : $ConsolidationScenario" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# Collecte des JSON
$JsonFiles = @(Get-ChildItem -Path $InputDir -Filter "cpu_summary_*.json" -ErrorAction SilentlyContinue)

if ($JsonFiles.Count -eq 0) {
    Write-Host "Aucun fichier JSON trouvé dans $InputDir" -ForegroundColor Yellow
    exit 0
}

Write-Host "Fichiers JSON trouvés : $($JsonFiles.Count) serveur(s)" -ForegroundColor Green
Write-Host ""

# Lecture et import des JSON
$allServers = @()
foreach ($jsonFile in $JsonFiles) {
    try {
        $serverData = Get-Content -Path $jsonFile.FullName -Raw | ConvertFrom-Json
        $allServers += $serverData
        Write-Host "Import : $($serverData.ServerName)" -ForegroundColor Green
    } catch {
        Write-Host "Erreur lecture $($jsonFile.Name) : $_" -ForegroundColor Yellow
    }
}

if ($allServers.Count -eq 0) {
    Write-Host "Aucune donnée valide à analyser" -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "=== ANALYSE PAR SERVEUR ===" -ForegroundColor Cyan
Write-Host ""

# Affichage détaillé par serveur
$totalVCpuAllocated = 0
$totalVCpuRecommended = 0
$totalAvgCpu = 0
$totalP95Cpu = 0

foreach ($server in $allServers) {
    Write-Host "Serveur: $($server.ServerName)" -ForegroundColor Yellow
    Write-Host "  vCPU alloués         : $($server.vCPU_Allocated)"
    Write-Host "  vCPU recommandés     : $($server.vCPU_Recommended)"
    Write-Host "  Utilisation moyenne  : $($server.Avg_CPU_Usage_Pct)%"
    Write-Host "  P95 CPU              : $($server.P95_CPU_Pct)%"
    Write-Host "  Pic observé          : $($server.Max_Recorded_CPU_Pct)%"
    Write-Host "  Marge allouée        : $($server.Margin_Allocated_Pct)%"
    Write-Host ""
    
    $totalVCpuAllocated += $server.vCPU_Allocated
    $totalVCpuRecommended += $server.vCPU_Recommended
    $totalAvgCpu += $server.Avg_CPU_Usage_Pct
    $totalP95Cpu += $server.P95_CPU_Pct
}

# Calculs globaux
$avgServers = $allServers.Count
$overallAvgCpu = $totalAvgCpu / $avgServers
$overallP95Cpu = $totalP95Cpu / $avgServers

# Scénario 1 : Consolidation avec moyenne (optimiste)
$consolidatedAvgVCpu = [Math]::Ceiling($totalVCpuAllocated * ($overallAvgCpu / 100) * 1.1)

# Scénario 2 : Consolidation avec P95 (réaliste)
$consolidatedP95VCpu = [Math]::Ceiling($totalVCpuAllocated * ($overallP95Cpu / 100) * 1.2)

# Scénario 3 : Somme des recommandations (conservative)
$consolidatedRecommendedVCpu = $totalVCpuRecommended

# Économies potentielles
$savingsVsCurrent = $totalVCpuAllocated - $consolidatedP95VCpu
$savingsVsRecommended = $totalVCpuRecommended - $consolidatedP95VCpu
$savingsPct = [Math]::Round(($savingsVsCurrent / $totalVCpuAllocated) * 100, 1)

Write-Host "=== SYNTHÈSE GLOBALE ===" -ForegroundColor Green
Write-Host ""
Write-Host "Nombre de serveurs        : $avgServers"
Write-Host "Total vCPU alloués        : $totalVCpuAllocated"
Write-Host "Total vCPU recommandés    : $totalVCpuRecommended"
Write-Host ""
Write-Host "Utilisation moyenne glob. : $([Math]::Round($overallAvgCpu, 2))%"
Write-Host "P95 moyenne              : $([Math]::Round($overallP95Cpu, 2))%"
Write-Host ""

Write-Host "=== SCÉNARIOS DE CONSOLIDATION ===" -ForegroundColor Cyan
Write-Host ""

Write-Host "Scénario 1 - OPTIMISTE (Moyenne + 10% marge):" -ForegroundColor Yellow
Write-Host "  Formule : vCPU × (Avg% / 100) × 1.1"
Write-Host "  vCPU nécessaires   : $consolidatedAvgVCpu / $totalVCpuAllocated"
Write-Host "  Économies         : $($totalVCpuAllocated - $consolidatedAvgVCpu) vCPU"
Write-Host ""

Write-Host "Scénario 2 - RÉALISTE (P95 + 20% marge) ⭐ RECOMMANDÉ:" -ForegroundColor Green
Write-Host "  Formule : vCPU × (P95% / 100) × 1.2"
Write-Host "  vCPU nécessaires   : $consolidatedP95VCpu / $totalVCpuAllocated"
Write-Host "  Économies        : $savingsVsCurrent vCPU ($savingsPct%)"
Write-Host "  vs Recommandé    : $([Math]::Max($consolidatedRecommendedVCpu - $consolidatedP95VCpu, 0)) vCPU supplém."
Write-Host ""

Write-Host "Scénario 3 - CONSERVATIVE (Somme recommandations):" -ForegroundColor Yellow
Write-Host "  Formule : Σ vCPU_Recomandé par serveur"
Write-Host "  vCPU nécessaires   : $consolidatedRecommendedVCpu / $totalVCpuAllocated"
Write-Host "  Économies         : $($totalVCpuAllocated - $consolidatedRecommendedVCpu) vCPU"
Write-Host ""

# Création du JSON consolidé
$consolidationSummary = [PSCustomObject]@{
    ConsolidationScenario        = $ConsolidationScenario
    Timestamp                    = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Total_Servers                = $avgServers
    Total_vCPU_Allocated         = $totalVCpuAllocated
    Total_vCPU_Recommended       = $totalVCpuRecommended
    Overall_Avg_CPU_Pct          = [Math]::Round($overallAvgCpu, 2)
    Overall_P95_CPU_Pct          = [Math]::Round($overallP95Cpu, 2)
    Scenario_Optimiste_vCPU      = $consolidatedAvgVCpu
    Scenario_Realiste_vCPU       = $consolidatedP95VCpu
    Scenario_Conservative_vCPU   = $consolidatedRecommendedVCpu
    Savings_Realistic_vCPU       = $savingsVsCurrent
    Savings_Realistic_Pct        = $savingsPct
    Servers                      = $allServers
}

$jsonPath = Join-Path $OutputDir "consolidation_summary_${ConsolidationScenario}_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
$jsonContent = $consolidationSummary | ConvertTo-Json -Depth 3
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($jsonPath, $jsonContent, $Utf8NoBom)
Write-Host "JSON consolidé exporté : $jsonPath" -ForegroundColor Green

# Création du rapport HTML
$htmlPath = Join-Path $OutputDir "consolidation_report_${ConsolidationScenario}_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"

$serverTableRows = ""
foreach ($server in $allServers) {
    $serverTableRows += @"
    <tr>
        <td>$($server.ServerName)</td>
        <td>$($server.vCPU_Allocated)</td>
        <td>$($server.vCPU_Recommended)</td>
        <td>$($server.Avg_CPU_Usage_Pct)%</td>
        <td>$($server.P95_CPU_Pct)%</td>
        <td>$($server.Max_Recorded_CPU_Pct)%</td>
        <td>$([Math]::Round(($server.vCPU_Recommended / $server.vCPU_Allocated) * 100, 1))%</td>
    </tr>
"@
}

$htmlContent = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rapport Consolidation - $ConsolidationScenario</title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            margin: 20px;
            background-color: #f5f5f5;
            color: #333;
        }
        .container {
            max-width: 1400px;
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
            border-left: 4px solid #0066cc;
            padding-left: 10px;
        }
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
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
        .stat-card.success {
            background: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%);
        }
        .stat-card.warning {
            background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);
        }
        .stat-card.info {
            background: linear-gradient(135deg, #43e97b 0%, #38f9d7 100%);
        }
        .stat-value {
            font-size: 32px;
            font-weight: bold;
            margin: 10px 0;
        }
        .stat-label {
            font-size: 11px;
            opacity: 0.9;
            text-transform: uppercase;
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
            font-weight: bold;
        }
        tbody tr:nth-child(odd) {
            background-color: #f9f9f9;
        }
        tbody tr:hover {
            background-color: #f0f0f0;
        }
        .scenario-card {
            border-left: 4px solid;
            padding: 15px;
            margin: 15px 0;
            border-radius: 4px;
            background-color: #f9f9f9;
        }
        .scenario-card.optimiste {
            border-left-color: #ff9800;
        }
        .scenario-card.realiste {
            border-left-color: #4caf50;
            background-color: #e8f5e9;
        }
        .scenario-card.conservative {
            border-left-color: #2196f3;
        }
        .recommendation {
            background: linear-gradient(135deg, #4caf50 0%, #45a049 100%);
            color: white;
            padding: 20px;
            margin: 20px 0;
            border-radius: 8px;
        }
        .recommendation h3 {
            margin-top: 0;
            color: white;
        }
        .savings-highlight {
            background-color: #fff3cd;
            border-left: 4px solid #ffc107;
            padding: 10px 15px;
            margin: 10px 0;
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
        <h1>Rapport Consolidation Multi-Serveurs</h1>
        <p><strong>Sc&eacute;nario:</strong> $ConsolidationScenario</p>
        <p><strong>G&eacute;n&eacute;r&eacute;:</strong> $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')</p>
        
        <h2>Synth&egrave;se Globale</h2>
        <div class="stats-grid">
            <div class="stat-card">
                <div class="stat-label">Serveurs</div>
                <div class="stat-value">$avgServers</div>
            </div>
            <div class="stat-card">
                <div class="stat-label">Total vCPU Allou&eacute;s</div>
                <div class="stat-value">$totalVCpuAllocated</div>
            </div>
            <div class="stat-card warning">
                <div class="stat-label">Total vCPU Recommand&eacute;s</div>
                <div class="stat-value">$totalVCpuRecommended</div>
            </div>
            <div class="stat-card success">
                <div class="stat-label">Utilisation Moyenne</div>
                <div class="stat-value">$([Math]::Round($overallAvgCpu, 1))%</div>
            </div>
            <div class="stat-card info">
                <div class="stat-label">P95 Moyenne</div>
                <div class="stat-value">$([Math]::Round($overallP95Cpu, 1))%</div>
            </div>
        </div>
        
        <h2>D&eacute;tail des Serveurs</h2>
        <table>
            <thead>
                <tr>
                    <th>Serveur</th>
                    <th>vCPU Allou&eacute;s</th>
                    <th>vCPU Recommand&eacute;s</th>
                    <th>Avg CPU</th>
                    <th>P95 CPU</th>
                    <th>Pic Observ&eacute;</th>
                    <th>Marge %</th>
                </tr>
            </thead>
            <tbody>
                $serverTableRows
            </tbody>
        </table>
        
        <h2>Sc&eacute;narios de Consolidation</h2>
        
        <div class="scenario-card optimiste">
            <h3>Sc&eacute;nario 1 - OPTIMISTE (Moyenne + 10%)</h3>
            <p><strong>Hypoth&egrave;se:</strong> Les pics de chaque serveur ne sont pas simultan&eacute;s</p>
            <p><strong>vCPU n&eacute;cessaires:</strong> <span style="font-size: 24px; font-weight: bold;">$consolidatedAvgVCpu</span> / $totalVCpuAllocated</p>
            <p><strong>&Eacute;conomies:</strong> $($totalVCpuAllocated - $consolidatedAvgVCpu) vCPU</p>
            <p style="font-size: 12px; color: #666;"> <strong>Risque:</strong> Pics simultan&eacute;s peuvent cr&eacute;er des contentions</p>
        </div>
        
        <div class="scenario-card realiste">
            <h3> Sc&eacute;nario 2 - R&Eacute;ALISTE (P95 + 20%) - RECOMMAND&Eacute;</h3>
            <p><strong>Hypoth&egrave;se:</strong> P95 de chaque serveur additionn&eacute;s avec s&eacute;curit&eacute; (20% marge)</p>
            <p><strong>vCPU n&eacute;cessaires:</strong> <span style="font-size: 24px; font-weight: bold; color: #4caf50;">$consolidatedP95VCpu</span> / $totalVCpuAllocated</p>
            <div class="savings-highlight">
                <strong> &Eacute;conomies:</strong> $savingsVsCurrent vCPU ($savingsPct%)<br>
                <strong> vs Recommand&eacute; actuel:</strong> $([Math]::Max($consolidatedRecommendedVCpu - $consolidatedP95VCpu, 0)) vCPU suppl&eacute;mentaires possibles
            </div>
        </div>
        
        <div class="scenario-card conservative">
            <h3> Sc&eacute;nario 3 - CONSERVATIVE (Somme recommandations)</h3>
            <p><strong>Hypoth&egrave;se:</strong> Chaque serveur garde sa marge recommand&eacute;e individuellement</p>
            <p><strong>vCPU n&eacute;cessaires:</strong> <span style="font-size: 24px; font-weight: bold;">$consolidatedRecommendedVCpu</span> / $totalVCpuAllocated</p>
            <p><strong>&Eacute;conomies:</strong> $($totalVCpuAllocated - $consolidatedRecommendedVCpu) vCPU</p>
            <p style="font-size: 12px; color: #666;">✓ <strong>Avantage:</strong> Z&eacute;ro risque, marges individuelles conserv&eacute;es</p>
        </div>
        
        <div class="recommendation">
            <h3> Recommandation Finale</h3>
            <p><strong>Approche sugg&eacute;r&eacute;e : Sc&eacute;nario 2 (R&eacute;aliste)</strong></p>
            <p>Allouer <strong>$consolidatedP95VCpu vCPU</strong> au serveur consolid&eacute;</p>
            <p>Cela permet une &eacute;conomie de <strong style="font-size: 18px;">$savingsVsCurrent vCPU ($savingsPct%)</strong> par rapport &agrave; la situation actuelle<br>
            tout en maintenant une marge de s&eacute;curit&eacute; de 20% pour les pics exceptionnels.</p>
            <p style="margin-top: 20px; font-size: 12px; opacity: 0.9;">
            V&eacute;rifier que le hyperviseur h&ocirc;te a la capacit&eacute; : $consolidatedP95VCpu vCPU min + marge infrastructure (~30%)
            </p>
        </div>
        
        <div class="footer">
            <p>Rapport g&eacute;n&eacute;r&eacute; automatiquement par cpu_analysis_report_multi_server.ps1</p>
            <p>Donn&eacute;es sources: $(($allServers | Measure-Object).Count) serveur(s) analys&eacute;s</p>
        </div>
    </div>
</body>
</html>
"@

$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($htmlPath, $htmlContent, $Utf8NoBom)
Write-Host "Rapport HTML exporté : $htmlPath" -ForegroundColor Green
Write-Host ""
