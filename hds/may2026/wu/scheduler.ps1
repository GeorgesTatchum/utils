$heure = '2026-06-30 03:00'   # ajuster par vague (cf. §5.5)
$cible = '10.0.20348.5139'  # build cible de la version du serveur (§2). Méthode B : remplacer par -File ... sans -BuildCible.
$action = New-ScheduledTaskAction -Execute 'powershell.exe' `
  -Argument "-NoProfile -ExecutionPolicy Bypass -File C:\sites\outils\tools\patch\applyPatch.ps1 -BuildCible $cible"
$trigger = New-ScheduledTaskTrigger -Once -At $heure
$principal = New-ScheduledTaskPrincipal -UserId 'SYSTEM' -LogonType ServiceAccount -RunLevel Highest
Register-ScheduledTask -TaskName 'TI-Patch-2026-05-OWU-1597' `
  -Action $action -Trigger $trigger -Principal $principal -Force