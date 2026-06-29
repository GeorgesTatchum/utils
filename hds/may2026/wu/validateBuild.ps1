# C:\sites\outils\tools\validateBuild.ps1  (exécuté au démarrage suivant le patch)
param([version]$BuildCible)
$log = 'C:\sites\outils\tools\patch\apply-2026-05.log'
$v = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
$cur = [version]"$($v.CurrentBuild).$($v.UBR)"
$ok = $cur -ge $BuildCible
"$(Get-Date -Format s) $env:COMPUTERNAME build après = $cur ; cible $BuildCible ; conclusion = $(if($ok){'PATCHÉ'}else{'NON PATCHÉ — à investiguer'})" | Out-File $log -Append
# Auto-désinscription (one-shot)
Unregister-ScheduledTask -TaskName 'TI-Patch-2026-05-Validate' -Confirm:$false -ErrorAction SilentlyContinue