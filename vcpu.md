# Évaluation de la consommation vCPU et CPU – Guide complet

## 1. Concepts fondamentaux

### Différence CPU vs vCPU

| Concept | Définition | Mesure |
|---------|-----------|--------|
| **vCPU** | Nombre de processeurs logiques alloués à la machine (ce que l'OS voit) | `Get-CimInstance Win32_Processor \| Select -ExpandProperty NumberOfLogicalProcessors` |
| **% CPU** | Taux d'occupation de ces vCPU (0–100%) | `\Processor(_Total)\% Processor Time` |
| **vCPU consommés** | Nombre réel de vCPU utilisés = vCPU alloués × (% CPU / 100) | `$ \text{vAlloués} \times \frac{\% CPU}{100}$ |

### Point critique en virtualisation

- **Dans la VM** : on mesure l'utilisation jusqu'aux vCPU alloués. Pas de visibilité sur la contention hyperviseur.
- **À l'hôte** : le hyperviseur (VMware/Hyper-V) voit *CPU Ready/CPU Steal* si la VM attend une ressource physique.
- **Pour ce guide** : on se focalise sur la vue *intra-VM*, suffisante pour le dimensionnement applicatif.

---

## 2. Script 1 : Évaluation simple sur une machine (test rapide)

**Usage** : pour une première approche ou test rapide sur 1 machine via IP/credentials.

**Fichier** : `cpu_quick_eval.ps1`

```powershell
<#
.SYNOPSIS
    Évaluation rapide de la consommation CPU/vCPU sur une machine distante.
    
.PARAMETER ComputerIP
    Adresse IP de la cible (ex: 192.168.1.100)
    
.PARAMETER Username
    Username au format DOMAIN\User ou local\User
    
.PARAMETER Password
    Mot de passe (sera converti en SecureString)
    
.PARAMETER DurationSeconds
    Durée totale de la collecte en secondes (défaut: 300 = 5 min)
    
.PARAMETER SampleIntervalSec
    Intervalle entre chaque mesure en secondes (défaut: 5)
    
.EXAMPLE
    .\cpu_quick_eval.ps1 -ComputerIP "192.168.1.100" -Username "DOMAIN\admin" -Password "MyP@ssw0rd" -DurationSeconds 600
#>

param(
    [Parameter(Mandatory=$true)]
    [ValidatePattern('^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$|^[a-zA-Z0-9-]+$')]
    [string]$ComputerIP,
    
    [Parameter(Mandatory=$true)]
    [string]$Username,
    
    [Parameter(Mandatory=$true)]
    [string]$Password,
    
    [int]$DurationSeconds = 300,
    
    [int]$SampleIntervalSec = 5
)

# Convertir le mot de passe en SecureString et créer les credentials
$SecPassword = ConvertTo-SecureString $Password -AsPlainText -Force
$Credential = New-Object System.Management.Automation.PSCredential($Username, $SecPassword)

Write-Host "=== Connexion à $ComputerIP ... ===" -ForegroundColor Cyan

try {
    $TestConnection = Test-WSMan -ComputerName $ComputerIP -Credential $Credential -ErrorAction Stop
    Write-Host "✓ Connexion OK" -ForegroundColor Green
} catch {
    Write-Host "✗ Erreur de connexion : $_" -ForegroundColor Red
    exit 1
}

$MaxSamples = [Math]::Ceiling($DurationSeconds / $SampleIntervalSec)
Write-Host "Collecte : $MaxSamples échantillons toutes les ${SampleIntervalSec}s = ${DurationSeconds}s total" -ForegroundColor Yellow

# Script à exécuter sur la cible
$ScriptBlock = {
    param($SampleIntervalSec, $MaxSamples)
    
    $counter = '\Processor(_Total)\% Processor Time'
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

    # P50 (médiane)
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

# Exécution
$result = Invoke-Command -ComputerName $ComputerIP `
                         -Credential $Credential `
                         -ScriptBlock $ScriptBlock `
                         -ArgumentList $SampleIntervalSec, $MaxSamples `
                         -ErrorAction Stop

Write-Host "`n=== RÉSULTATS ===" -ForegroundColor Cyan
$result | Format-List

Write-Host "`n=== RÉSUMÉ ===" -ForegroundColor Yellow
Write-Host "Machine           : $($result.ComputerName)" 
Write-Host "vCPU alloués      : $($result.vCPU_Allocated)"
Write-Host "Utilisation moy.  : $($result.Avg_CPU_Pct)%"
Write-Host "Utilisation P95   : $($result.P95_CPU_Pct)%"
Write-Host "vCPU consommés moy: $($result.Avg_vCPU_Consumed)/$($result.vCPU_Allocated)"
Write-Host "vCPU consommés P95: $($result.P95_vCPU_Consumed)/$($result.vCPU_Allocated)"

$result | Export-Csv -Path ".\cpu_eval_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv" -NoTypeInformation -Encoding UTF8
Write-Host "`nFichier CSV exporté." -ForegroundColor Green
```

### Utilisation – Version locale (ACTUELLE)

```powershell
# Test rapide 5 min (CSV dans le dossier courant)
.\cpu_quick_eval_local.ps1 -DurationSeconds 300

# Test 10 min avec intervalle 10s
.\cpu_quick_eval_local.ps1 -DurationSeconds 600 -SampleIntervalSec 10

# Specifier un repertoire de sortie personnalise
.\cpu_quick_eval_local.ps1 -OutputDir "D:\cpu_baseline" -DurationSeconds 300
```

---

## 3. Script 2 : Collecte sur longue période (1 semaine à 14 jours)

**Usage** : pour constituer une baseline représentative sur plusieurs jours/semaines.

**Fichier** : `cpu_long_term_collector.ps1`

```powershell
<#
.SYNOPSIS
    Collecteur CPU de longue durée à planifier via Task Scheduler.
    Exécution quotidienne, stockage en CSV par jour, rapport agrégé.
    
.PARAMETER ConfigFile
    Fichier JSON contenant les machines et credentials.
    
.PARAMETER OutputDir
    Répertoire de sortie pour les fichiers CSV (défaut: .\cpu_data)
    
.PARAMETER CollectionInterval
    Intervalle entre les mesures en minutes (défaut: 5 min)
    
.EXAMPLE
    .\cpu_long_term_collector.ps1 -ConfigFile ".\servers.json" -OutputDir "D:\cpu_baseline"
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$ConfigFile,
    
    [string]$OutputDir = ".\cpu_data",
    
    [int]$CollectionInterval = 5
)

# Créer le répertoire de sortie s'il n'existe pas
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
    Write-Host "Répertoire créé : $OutputDir" -ForegroundColor Green
}

# Charger le fichier de configuration JSON
if (-not (Test-Path $ConfigFile)) {
    Write-Host "✗ Fichier config non trouvé : $ConfigFile" -ForegroundColor Red
    exit 1
}

$Config = Get-Content $ConfigFile | ConvertFrom-Json
$Servers = $Config.servers

if ($null -eq $Servers -or $Servers.Count -eq 0) {
    Write-Host "✗ Aucun serveur défini dans $ConfigFile" -ForegroundColor Red
    exit 1
}

$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$DayStamp = Get-Date -Format "yyyyMMdd"
$LogFile = Join-Path $OutputDir "collection_${DayStamp}_${Timestamp}.log"

# Logger
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $LogMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [$Level] $Message"
    Add-Content -Path $LogFile -Value $LogMessage
    Write-Host $LogMessage -ForegroundColor $(if ($Level -eq "ERROR") { "Red" } else { "Gray" })
}

Write-Log "=== Démarrage collecte CPU ===" "INFO"
Write-Log "Fichier config : $ConfigFile" "INFO"
Write-Log "Intervalle : ${CollectionInterval} min" "INFO"
Write-Log "Nombre de serveurs : $($Servers.Count)" "INFO"

# Script de collecte sur chaque machine
$ScriptBlock = {
    param($CollectionIntervalSec, $NumSamples)
    
    $counter = '\Processor(_Total)\% Processor Time'
    
    try {
        $samples = Get-Counter -Counter $counter `
                               -SampleInterval $CollectionIntervalSec `
                               -MaxSamples $NumSamples `
                               -ErrorAction Stop
        
        $values = $samples.CounterSamples | Select-Object -ExpandProperty CookedValue

        $cpuInfo = Get-CimInstance Win32_Processor
        $vCpuAllocated = ($cpuInfo | Measure-Object -Property NumberOfLogicalProcessors -Sum).Sum
        
        $avg = ($values | Measure-Object -Average).Average
        $max = ($values | Measure-Object -Maximum).Maximum
        $min = ($values | Measure-Object -Minimum).Minimum
        
        $sorted = $values | Sort-Object
        $p95Index = [Math]::Ceiling($sorted.Count * 0.95) - 1
        $p95 = $sorted[[Math]::Max($p95Index, 0)]

        [PSCustomObject]@{
            ComputerName         = $env:COMPUTERNAME
            Timestamp            = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            vCPU_Allocated       = [int]$vCpuAllocated
            Min_CPU_Pct          = [Math]::Round($min, 2)
            Avg_CPU_Pct          = [Math]::Round($avg, 2)
            P95_CPU_Pct          = [Math]::Round($p95, 2)
            Max_CPU_Pct          = [Math]::Round($max, 2)
            Avg_vCPU_Consumed    = [Math]::Round($vCpuAllocated * $avg / 100, 2)
            P95_vCPU_Consumed    = [Math]::Round($vCpuAllocated * $p95 / 100, 2)
            Max_vCPU_Consumed    = [Math]::Round($vCpuAllocated * $max / 100, 2)
            Samples_Count        = $sorted.Count
        }
    } catch {
        [PSCustomObject]@{
            ComputerName = $env:COMPUTERNAME
            Timestamp    = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            Error        = $_.Exception.Message
        }
    }
}

# Boucle sur les serveurs
$AllResults = @()

foreach ($Server in $Servers) {
    $IP       = $Server.ip
    $User     = $Server.username
    $Pass     = $Server.password
    $Alias    = $Server.alias
    
    Write-Log "Traitement $Alias ($IP)..." "INFO"
    
    try {
        $SecPassword = ConvertTo-SecureString $Pass -AsPlainText -Force
        $Credential = New-Object System.Management.Automation.PSCredential($User, $SecPassword)
        
        # Vérifier la connectivité
        $TestWS = Test-WSMan -ComputerName $IP -Credential $Credential -ErrorAction SilentlyContinue
        if ($null -eq $TestWS) {
            Write-Log "  ✗ Pas de connectivité WinRM" "ERROR"
            continue
        }
        
        # Exécuter la collecte
        $Result = Invoke-Command -ComputerName $IP `
                                  -Credential $Credential `
                                  -ScriptBlock $ScriptBlock `
                                  -ArgumentList ($CollectionInterval * 60), 12 `
                                  -ErrorAction Stop
        
        $Result | Add-Member -NotePropertyName "Alias" -NotePropertyValue $Alias
        $AllResults += $Result
        
        Write-Log "  ✓ OK : Avg=$($Result.Avg_CPU_Pct)% | P95=$($Result.P95_CPU_Pct)% | P95_vCPU=$($Result.P95_vCPU_Consumed)" "INFO"
        
    } catch {
        Write-Log "  ✗ Erreur : $_" "ERROR"
    }
}

# Exporter les résultats
if ($AllResults.Count -gt 0) {
    $CsvPath = Join-Path $OutputDir "cpu_${DayStamp}.csv"
    $AllResults | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8 -Append
    Write-Log "Résultats exportés : $CsvPath" "INFO"
} else {
    Write-Log "⚠ Aucune donnée collectée" "ERROR"
}

Write-Log "=== Fin collecte ===" "INFO"
```

### Fichier de configuration JSON

**Fichier** : `servers.json`

```json
{
  "servers": [
    {
      "alias": "srv-app-01",
      "ip": "192.168.1.100",
      "username": "DOMAIN\\admin",
      "password": "MyP@ssw0rd123"
    },
    {
      "alias": "srv-app-02",
      "ip": "192.168.1.101",
      "username": "DOMAIN\\admin",
      "password": "MyP@ssw0rd123"
    },
    {
      "alias": "srv-db-01",
      "ip": "192.168.1.110",
      "username": "DOMAIN\\dbadmin",
      "password": "DbP@ssw0rd456"
    },
    {
      "alias": "srv-web-01",
      "ip": "192.168.1.120",
      "username": "DOMAIN\\admin",
      "password": "MyP@ssw0rd123"
    }
  ]
}
```

### Utilisation

```powershell
# Exécution manuelle (test)
.\cpu_long_term_collector.ps1 -ConfigFile ".\servers.json" -OutputDir "D:\cpu_baseline" -CollectionInterval 5

# Planification quotidienne (Task Scheduler)
# Action : PowerShell -NoProfile -ExecutionPolicy Bypass -File "C:\Scripts\cpu_long_term_collector.ps1" -ConfigFile "C:\Scripts\servers.json"
# Fréquence : Quotidienne à 6h du matin (ou heure creuse)
```

---

## 4. Script 3 : Analyse et rapport final

**Fichier** : `cpu_analysis_report.ps1`

```powershell
<#
.SYNOPSIS
    Génère un rapport d'analyse des données collectées.
    
.PARAMETER DataDir
    Répertoire contenant les fichiers CSV de collecte.
    
.PARAMETER OutputPath
    Chemin du rapport final (Excel ou HTML).
    
.EXAMPLE
    .\cpu_analysis_report.ps1 -DataDir "D:\cpu_baseline" -OutputPath "D:\reports\cpu_report.html"
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$DataDir,
    
    [string]$OutputPath = ".\cpu_report_$(Get-Date -Format 'yyyyMMdd').html"
)

# Importer tous les CSV
$CsvFiles = Get-ChildItem -Path $DataDir -Filter "cpu_*.csv" -ErrorAction SilentlyContinue

if ($CsvFiles.Count -eq 0) {
    Write-Host "✗ Aucun fichier CSV trouvé dans $DataDir" -ForegroundColor Red
    exit 1
}

Write-Host "Fusion de $($CsvFiles.Count) fichier(s)..." -ForegroundColor Yellow

$AllData = @()
foreach ($File in $CsvFiles) {
    $AllData += Import-Csv -Path $File.FullName
}

Write-Host "Total d'enregistrements : $($AllData.Count)" -ForegroundColor Cyan

# Calculs par machine
$MachineStats = $AllData | Where-Object { $_.Alias -ne $null } | Group-Object -Property Alias | ForEach-Object {
    $Group = $_.Group
    $MachineName = $_.Name
    
    $CpuPcts = $Group.Avg_CPU_Pct | ForEach-Object { [double]$_ }
    $vCpuConsumed = $Group.P95_vCPU_Consumed | ForEach-Object { [double]$_ }
    
    $vCpuAllocated = $Group[0].vCPU_Allocated
    
    $CpuPctAvg = ($CpuPcts | Measure-Object -Average).Average
    $CpuPctMax = ($CpuPcts | Measure-Object -Maximum).Maximum
    $vCpuP95Avg = ($vCpuConsumed | Measure-Object -Average).Average
    $vCpuP95Max = ($vCpuConsumed | Measure-Object -Maximum).Maximum
    
    [PSCustomObject]@{
        Machine            = $MachineName
        vCPU_Allocated     = $vCpuAllocated
        Days_Sampled       = $Group.Count
        Avg_CPU_Pct_All    = [Math]::Round($CpuPctAvg, 2)
        Max_CPU_Pct_Daily  = [Math]::Round($CpuPctMax, 2)
        Avg_P95_vCPU       = [Math]::Round($vCpuP95Avg, 2)
        Max_P95_vCPU       = [Math]::Round($vCpuP95Max, 2)
        Utilization_Ratio  = [Math]::Round(($vCpuP95Avg / $vCpuAllocated) * 100, 2)
    }
}

Write-Host "`n=== RÉSUMÉ PAR MACHINE ===" -ForegroundColor Cyan
$MachineStats | Format-Table -AutoSize

# Totaux
$TotalvCpuAllocated = ($MachineStats | Measure-Object -Property vCPU_Allocated -Sum).Sum
$TotalP95Avg = ($MachineStats | Measure-Object -Property Avg_P95_vCPU -Sum).Sum

Write-Host "`n=== TOTAUX ACTUELS (Architecture $($MachineStats.Count) machines) ===" -ForegroundColor Yellow
Write-Host "vCPU total alloué    : $TotalvCpuAllocated"
Write-Host "vCPU consommés (P95) : $([Math]::Round($TotalP95Avg, 2))"
Write-Host "Taux d'utilisation   : $([Math]::Round(($TotalP95Avg / $TotalvCpuAllocated) * 100, 2))%"

# Exporter CSV
$CsvExport = Join-Path $DataDir "analysis_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
$MachineStats | Export-Csv -Path $CsvExport -NoTypeInformation -Encoding UTF8
Write-Host "`nAnalyse exportée : $CsvExport" -ForegroundColor Green

$MachineStats | Export-Csv -Path $CsvExport -NoTypeInformation -Encoding UTF8
```

### Utilisation

```powershell
.\cpu_analysis_report.ps1 -DataDir "D:\cpu_baseline"
```

---

## 5. Guide complet : Évaluer la réduction (4 → 2 ou autre)

### Méthodologie étape par étape

#### **Étape 1 : Collecte des données (7 à 14 jours)**

1. Créer le fichier `servers.json` avec les 4 machines actuelles.
2. Planifier `cpu_long_term_collector.ps1` quotidiennement pendant 7–14 jours.
3. Cette période doit inclure :
   - Jours de semaine (charge de production).
   - Week-end (charge de maintenance, batch jobs, etc.).
   - Pic d'activité si connu.

**Commande de démarrage rapide (test 1 jour cumulatif) :**
```powershell
for ($i = 1; $i -le 288; $i++) {
    .\cpu_long_term_collector.ps1 -ConfigFile ".\servers.json" -CollectionInterval 5
    Start-Sleep -Seconds 300  # Toutes les 5 min
}
```

#### **Étape 2 : Analyse des données collectées**

```powershell
.\cpu_analysis_report.ps1 -DataDir "D:\cpu_baseline"
```

Cela produit :

| Machine | vCPU alloué | Avg CPU % | Max P95 vCPU | Ratio |
|---------|------------|-----------|--------------|-------|
| srv-app-01 | 4 | 35% | 1.4 | 35% |
| srv-app-02 | 4 | 28% | 1.12 | 28% |
| srv-db-01 | 8 | 45% | 3.6 | 45% |
| srv-web-01 | 4 | 15% | 0.6 | 15% |
| **TOTAL** | **20** | **–** | **6.72** | **33.6%** |

#### **Étape 3 : Calcul du redimensionnement**

Pour passer de **4 machines → 2 machines** :

**Formule** :
$$\text{vCPU\,par\,machine} = \left\lceil \frac{\text{Total\_P95\_vCPU} \times (1 + \text{marge})}{N\_machines} \right\rceil$$

| Paramètre | Valeur | Justification |
|-----------|--------|---------------|
| **Total P95 vCPU** | 6.72 | Pic de consommation observé |
| **Marge** | +20% à +40% | Pour dégradation perf, pics imprévus, croissance court terme |
| **Nombre cible** | 2 machines | Architecture résilience (2×2 pour failover) |

**Cas 1 : Marge conservatrice (30%)**
```
vCPU req = CEILING(6.72 × 1.30 / 2) = CEILING(4.368) = 5 vCPU par machine
Architecture cible : 2 × vCPU-5 (capacité réelle : 10 vCPU)
```

**Cas 2 : Marge modérée (20%)**
```
vCPU req = CEILING(6.72 × 1.20 / 2) = CEILING(4.032) = 4 vCPU par machine
Architecture cible : 2 × vCPU-4 (capacité réelle : 8 vCPU)
```

#### **Étape 4 : Validation croisée (autres ressources)**

⚠️ **CPU seul ne suffit pas.** Valider aussi :

| Ressource | Commande PowerShell | Seuil |
|-----------|-------------------|-------|
| **RAM** | `(Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB` | ≤ 80% utilisation moyenne |
| **Disque IOPS** | `Get-Counter -Counter '\LogicalDisk(*)\Disk Transfers/sec'` | Pas de saturation I/O |
| **Réseau** | `Get-NetAdapterStatistics \| Select BytesReceived, BytesSent` | ≤ 70% bande passante lien |

#### **Étape 5 : Décision finale**

Exemple : Si P95-vCPU = 6.72 et marge = 30%

- ✅ **2 × 4 vCPU** : OK si RAM et IOPS OK, failover acceptable en 5 vCPU.
- ✅ **2 × 8 vCPU** : Sûr, peu d'impact si applications exigeantes.
- ❌ **2 × 2 vCPU** : Trop serré, perte de marge de manœuvre.

---

## 6. Cas pratiques supplémentaires

### Réduction 4 → 3 machines (ex: déclassement progressif)

```powershell
$P95Total = 6.72
$Marge = 1.20
$TargetMachines = 3

$vCpuPerMachine = [Math]::Ceiling(($P95Total * $Marge) / $TargetMachines)
# Résultat : 2 vCPU par machine (capacité : 6)
```

**Verdict** : Trop serré, augmenter à 3 vCPU/machine.

### Réduction 8 → 4 machines

```powershell
# Hypothèse : 8 machines actuelles, P95 total = 18.5 vCPU
$vCpuPerMachine = [Math]::Ceiling((18.5 * 1.25) / 4)
# = 6 vCPU /machine
```

---

## 7. Checklist avant migration

- [ ] Collecte complète (minimum 7 jours).
- [ ] P95 validé par métier (pics connus inclus).
- [ ] RAM, IOPS, réseau également dimensionnés.
- [ ] Marge de 20–40% justifiée (stabilité, croissance, pics).
- [ ] Plan de test en charge sur nouvelle archi.
- [ ] Rollback plan en cas dégradation.
- [ ] Fenêtre de maintenance hors heures ouvrables.

---

## 8. Notes sur la compatibilité (W2016 → W2025)

| Version | Compteur CPU | Performance Manager | Notes |
|---------|-------------|-------------------|-------|
| W2016 | Get-Counter | Oui | ✓ Compatible |
| W2019 | Get-Counter | Oui | ✓ Compatible |
| W2022 | Get-Counter | Oui | ✓ Compatible |
| W2025 | Get-Counter | Oui | ✓ A tester |

Tous les scripts utilisent `Get-Counter` et `CIM`, stables depuis W2008 R2.

---

## 9. Ordonnancement avec Task Scheduler (collecte automatisée)

**Fichier** : `setup_cpu_monitoring_scheduler_local.ps1`

Pour une collecte **sans intervention** sur plusieurs jours (7–14 jours), cette approche programme l'exécution automatique de `cpu_quick_eval_local.ps1` via Task Scheduler.

### Configuration initiale

```powershell
# Configuration simple (CSV dans le dossier du script)
.\setup_cpu_monitoring_scheduler_local.ps1

# Specifier un repertoire personnalise pour les CSV
.\setup_cpu_monitoring_scheduler_local.ps1 -OutputDir "D:\cpu_baseline"

# Configuration complete avec tous les parametres
.\setup_cpu_monitoring_scheduler_local.ps1 `
    -OutputDir "D:\cpu_baseline" `
    -DurationSeconds 600 `
    -SampleIntervalSec 10 `
    -TaskName "Mon_CPU_Monitoring"
```

### Fonctionnement

- **Calendrier** : Lundi–Vendredi
- **Horaires** : 9h, 10h, 11h, 12h, 13h, 14h, 15h, 16h, 17h, 18h, 19h, 20h
- **Récurrence** : Chaque semaine
- **Total** : 60 exécutions/semaine = 60 fichiers CSV
- **Fichiers générés** : `cpu_eval_YYYYMMDD_HHMMSS.csv` (dans OutputDir ou le dossier du script)
- **Répertoire de sortie** : Créé automatiquement s'il n'existe pas

### Notes importantes

- ⚠️ Exécuter le script setup **directement sur le serveur à monitorer** (pas en distantiel)
- ⚠️ Exécuter avec **droits administrateur**
- Le Service Task Scheduler doit être actif (démarره automatiquement par le script)
- Les CSV s'accumulent au fil du temps - pensez à les archiver régulièrement

### Gestion de la tâche (via PowerShell)

Afficher le statut et les prochaines exécutions :
```powershell
Get-ScheduledTask -TaskName "CPU_Monitoring_Local_Workdays" | Get-ScheduledTaskInfo
```

Exécuter la tâche immédiatement (test) :
```powershell
Start-ScheduledTask -TaskName "CPU_Monitoring_Local_Workdays"
```

Désactiver temporairement (sans la supprimer) :
```powershell
Disable-ScheduledTask -TaskName "CPU_Monitoring_Local_Workdays"
```

Réactiver :
```powershell
Enable-ScheduledTask -TaskName "CPU_Monitoring_Local_Workdays"
```

Supprimer la tâche définitivement :
```powershell
Unregister-ScheduledTask -TaskName "CPU_Monitoring_Local_Workdays" -Confirm:$false
```

### Vérification manuelle dans Task Scheduler

- Ouvrir `taskschd.msc`
- Naviguer vers : **Bibliothèque du Planificateur de tâches**
- Chercher `CPU_Monitoring_Local_Workdays`
- Clic droit → **Propriétés** pour voir détails, triggers, actions
- Clic droit → **Historique** pour voir les exécutions passées
- Clic droit → **Exécuter** pour tester immédiatement

### Collecte manuelle des résultats

À la fin de chaque semaine de travail :

```powershell
# Lister tous les fichiers CSV generes dans le repertoire de sortie
Get-ChildItem -Path "D:\cpu_baseline" -Filter "cpu_eval_*.csv" | Sort-Object LastWriteTime -Descending

# Ou si vous avez utilise un autre repertoire, adapter le chemin
```

### Dépannage

**La tâche ne s'exécute pas :**
1. Vérifier que Task Scheduler est actif : `Get-Service -Name Schedule | Select Status`
2. Vérifier les permissions (Admin requis)
3. Vérifier l'historique Task Scheduler : Clic droit sur la tâche → **Historique**
4. Vérifier qu'aucune instance ne s'exécute déjà : `tasklist /FI "IMAGENAME eq powershell.exe"`

**Les CSV ne sont pas générés :**
1. Vérifier le repertoire OutputDir existe : `Test-Path "D:\cpu_baseline"`
2. Vérifier les droits d'écriture sur le répertoire
3. Tester manuellement : `.\cpu_quick_eval_local.ps1 -OutputDir "D:\cpu_baseline"`

**Erreur au lancement du script :**
1. Vérifier ExecutionPolicy : `Get-ExecutionPolicy`
2. Au besoin : `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`

---

## 5. Workflow complet : Collecte → Analyse → Rapport

### Vue d'ensemble

```
Serveur A     Serveur B     Serveur C
     ↓             ↓             ↓
CPU_Monitoring_A  CPU_Monitoring_B  CPU_Monitoring_C
(CSV files)       (CSV files)       (CSV files)
     ↓             ↓             ↓
cpu_analysis_report.ps1  (x3)
     ↓             ↓             ↓
Report_A.html   Report_B.html   Report_C.html
Summary_A.json  Summary_B.json  Summary_C.json
     ↓             ↓             ↓
Agrégation globale → Calcul vCPU consolidé
```

### Étape 1 : Planification de la collecte (local ou centralisée)

**Pour chaque serveur :** lancer le scheduler pour collecter automatiquement

```powershell
# Sur chaque serveur
.\setup_monitoring_scheduler.ps1 `
    -DurationSeconds 39600 `
    -SampleIntervalSec 3600 `
    -OutputDir "C:\Sites\outils\cpu_monitoring"
```

**Résultat :**
- Une tâche planifiée crée 12 mesures quotidiennes (9h-20h)
- Les fichiers CSV s'accumulent : `cpu_eval_YYYYMMDD_HHMMSS.csv`

### Étape 2 : Analyse par serveur

**Fichier** : `cpu_analysis_report.ps1`

**Usage :**

```powershell
.\cpu_analysis_report.ps1 `
    -InputDir "C:\Sites\outils\cpu_monitoring" `
    -OutputDir "C:\Reports" `
    -ServerName "PROD-WEB-01"
```

**Ce que fait le script :**

1. **Lit tous les CSV** du répertoire d'entrée
2. **Agrège les mesures** (moyenne, min, max, P95)
3. **Calcule des statistiques** :
   - Utilisation moyenne % CPU
   - P95 (percentile 95) — seuil clé pour le dimensionnement
   - Pic observé
4. **Génère un rapport HTML** avec :
   - Infos serveur (modèle CPU, vCPU alloués, cores)
   - Statistiques visuelles en cartes colorées
   - Tableau détaillé des mesures
   - **Recommandation vCPU** : basée sur `P95 + 20% marge`
5. **Exporte un JSON** contenant :
   - Résumé pour incorporation dans un rapport global
   - Recommandation vCPU

**Résultat :**
- `cpu_analysis_SERVERNAME_YYYYMMDD_HHMMSS.html` — rapport humain
- `cpu_summary_SERVERNAME_YYYYMMDD_HHMMSS.json` — données structurées

### Exemple de sortie

```
=== STATISTIQUES CPU ===
Serveur              : PROD-WEB-01
Modèle CPU           : Intel(R) Xeon(R) Platinum 8280
vCPU alloués         : 16
Cores visibles       : 16

Utilisation moyenne  :
  Min       : 5.2%
  Moyenne   : 28.4%
  Max       : 62.1%

P95 CPU             :
  Min       : 18.5%
  Moyenne   : 42.3%
  Max       : 58.7%

=== RECOMMANDATION ===
Basée sur P95 + 20% marge :
  vCPU recommandés  : 8 / 16
  Gain possible     : 8 vCPU
```

### Étape 3 : Agrégation multi-serveurs

**Fichier** : `cpu_analysis_report_multi_server.ps1`

**Usage :**

```powershell
.\cpu_analysis_report_multi_server.ps1 `
    -InputDir "C:\Reports" `
    -OutputDir "C:\Reports\Consolidation" `
    -ConsolidationScenario "Migration-DC1"
```

**Ce que fait le script :**

1. **Lit tous les JSON** du répertoire (un par serveur)
2. **Affiche le détail** de chaque serveur
3. **Calcule 3 scénarios de consolidation** :
   - **Scénario 1 - Optimiste** : Moyenne + 10% marge
   - **Scénario 2 - Réaliste** : P95 + 20% marge (recommandé ⭐)
   - **Scénario 3 - Conservative** : Somme des recommandations individuelles
4. **Génère un rapport HTML** avec :
   - Tableau comparatif des serveurs
   - 3 scénarios côte à côte avec économies estimées
   - Recommandation finale
5. **Exporte un JSON** consolidé avec tous les calculs

**Résultat :**
- `consolidation_report_SCENARIO_YYYYMMDD_HHMMSS.html` — rapport décisionnel
- `consolidation_summary_SCENARIO_YYYYMMDD_HHMMSS.json` — données structurées

### Exemple de synthèse

```
=== SYNTHÈSE GLOBALE ===
Nombre de serveurs        : 5
Total vCPU alloués        : 80
Total vCPU recommandés    : 35

Utilisation moyenne glob. : 24.5%
P95 moyenne              : 38.2%

=== SCÉNARIOS DE CONSOLIDATION ===

Scénario 1 - OPTIMISTE (Moyenne + 10%):
  vCPU nécessaires   : 22 / 80
  Économies         : 58 vCPU

Scénario 2 - RÉALISTE (P95 + 20%):  ⭐ RECOMMANDÉ
  vCPU nécessaires   : 37 / 80
  Économies        : 43 vCPU (53.8%)
  vs Recommandé    : 2 vCPU supplémentaires possibles

Scénario 3 - CONSERVATIVE (Somme recommandations):
  vCPU nécessaires   : 35 / 80
  Économies         : 45 vCPU
```

### Workflow complet - Étape par étape

**Phase 1 : Collecte (semaines 1-2)**
```
Chaque serveur → Setup scheduler → CSV quotidiens s'accumulent
```

**Phase 2 : Analyse (fin semaine 2)**
```
Pour chaque serveur :
  ./cpu_analysis_report.ps1 -InputDir "\\Serveur\monitoring" -ServerName "PROD-WEB-01"
  → Génère: Report_PROD-WEB-01.html + Summary_PROD-WEB-01.json
```

**Phase 3 : Décision (semaine 3)**
```
./cpu_analysis_report_multi_server.ps1 -InputDir "C:\Reports"
→ Génère: Consolidation_Report.html
→ Montre 3 scénarios, économies, risques
→ Décision: Quel serveur pour la consolidation ?
```

**Phase 4 : Validation infra**
```
- Vérifier capacité hyperviseur
- Vérifier réseau (bande passante consolidée)
- Vérifier stockage (IOPS consolidés)
- Tester migration en non-prod
```

---

## 6. Formule de recommandation

### Approche conservative (recommandée pour production)

$$\text{vCPU recommandés} = \lceil \text{vCPU alloués} \times \frac{\text{P95 CPU %}}{100} \times 1.2 \rceil$$

**Rationale :**
- P95 : 95% du temps, l'utilisation est en deça de ce seuil
- ×1.2 : marge de sécurité de 20% pour pics exceptionnels et croissance
- Arrondir vers le haut : ne pas se retrouver juste sous un seuil critique

### Approche agressive (économie maximale)

$$\text{vCPU recommandés} = \lceil \text{vCPU alloués} \times \frac{\text{P99 CPU %}}{100} \rceil$$

(99ème percentile, zéro marge)

---

## Ressources et documentation

- [PowerShell Get-Counter](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.diagnostics/get-counter)
- [Win32_Processor WMI Class](https://learn.microsoft.com/en-us/windows/win32/cimwin32prov/win32-processor)
- [Processor Performance Counters](https://learn.microsoft.com/en-us/windows/win32/perfctrs/processor-object)
- [Register-ScheduledTask](https://learn.microsoft.com/en-us/powershell/module/scheduledtasks/register-scheduledtask)
