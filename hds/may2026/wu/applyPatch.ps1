# C:\sites\outils\tools\patch\applyPatch.ps1
param([version]$BuildCible)   # ex. 2016='10.0.14393.9140' 2019='10.0.17763.8755' 2022='10.0.20348.5139' 2025='10.0.26100.32860'
$log = 'C:\sites\outils\tools\patch\apply-2026-05.log'
function Log($m){ "$(Get-Date -Format s) $env:COMPUTERNAME $m" | Out-File $log -Append }

$v0 = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
Log "build avant = $($v0.CurrentBuild).$($v0.UBR) ; cible >= $BuildCible"

if (-not (Get-Module -ListAvailable PSWindowsUpdate)) {
    Install-PackageProvider -Name NuGet -Force -Scope AllUsers | Out-Null
    Install-Module PSWindowsUpdate -Force -Scope AllUsers
}
Import-Module PSWindowsUpdate

# Journaliser les mises à jour disponibles (preuve)
Log "disponibles :"
(Get-WindowsUpdate -MicrosoftUpdate -Category 'Security Updates' 4>&1) | Out-File $log -Append

# Enregistrer la validation post-redémarrage (le build fait autorité)
$valArg = "-NoProfile -ExecutionPolicy Bypass -File C:\sites\outils\tools\patch\validateBuild.ps1 -BuildCible $BuildCible"
$a = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument $valArg
$t = New-ScheduledTaskTrigger -AtStartup
$pr = New-ScheduledTaskPrincipal -UserId 'SYSTEM' -LogonType ServiceAccount -RunLevel Highest
Register-ScheduledTask -TaskName 'TI-Patch-2026-05-Validate' -Action $a -Trigger $t -Principal $pr -Force

# Installer la dernière cumulative de sécurité (KB non figée) ; redémarre si requis
Log "installation Security Updates (AutoReboot si requis)"
Install-WindowsUpdate -MicrosoftUpdate -Category 'Security Updates' -AcceptAll -AutoReboot -Confirm:$false -Verbose 4>&1 | Out-File $log -Append