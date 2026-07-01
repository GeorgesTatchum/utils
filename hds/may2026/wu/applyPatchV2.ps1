# C:\Sites\outils\tools\patch\applyPatchV2.ps1
$patchDir = 'C:\Sites\outils\tools\patch'
$log      = "$patchDir\apply-$(Get-Date -Format yyyy-MM).log"

$v0 = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
"$(Get-Date -Format s) $env:COMPUTERNAME build avant = $($v0.CurrentBuild).$($v0.UBR)" | Out-File $log -Append
"$(Get-Date -Format s) $env:COMPUTERNAME hotfix avant :" | Out-File $log -Append
(Get-HotFix | Sort-Object InstalledOn | Select-Object HotFixID, Description, InstalledOn | Format-Table -AutoSize | Out-String).Trim() | Out-File $log -Append

$msus = Get-ChildItem "$patchDir\*.msu" | Sort-Object Name
if (-not $msus) {
    "$(Get-Date -Format s) $env:COMPUTERNAME aucun .msu trouve dans $patchDir" | Out-File $log -Append
    exit
}
"$(Get-Date -Format s) $env:COMPUTERNAME debut lot, $($msus.Count) fichier(s) : $($msus.Name -join ', ')" | Out-File $log -Append
$needsReboot = $false
$errors      = @()
foreach ($msu in $msus) {
    "$(Get-Date -Format s) debut MSU, msu=$($msu.FullName)" | Out-File $log -Append
    $p = Start-Process wusa.exe -ArgumentList "`"$($msu.FullName)`"","/quiet","/norestart" -Wait -PassThru
    "$(Get-Date -Format s) wusa exitcode=$($p.ExitCode) ($($msu.Name))" | Out-File $log -Append
    switch ($p.ExitCode) {
        0       { }
        3010    { $needsReboot = $true }
        2359302 { "$(Get-Date -Format s) deja present : $($msu.Name)" | Out-File $log -Append }
        default {
            "$(Get-Date -Format s) ERREUR exit $($p.ExitCode) sur $($msu.Name)" | Out-File $log -Append
            $errors += "$($msu.Name) (exit $($p.ExitCode))"
        }
    }
}
if ($errors.Count -gt 0) {
    "$(Get-Date -Format s) lot termine avec erreur(s) : $($errors -join '; ') - verifier avant redemarrage" | Out-File $log -Append
}

$v1 = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
"$(Get-Date -Format s) $env:COMPUTERNAME build apres (avant redemarrage) = $($v1.CurrentBuild).$($v1.UBR)" | Out-File $log -Append
"$(Get-Date -Format s) $env:COMPUTERNAME hotfix apres (avant redemarrage) :" | Out-File $log -Append
(Get-HotFix | Sort-Object InstalledOn | Select-Object HotFixID, Description, InstalledOn | Format-Table -AutoSize | Out-String).Trim() | Out-File $log -Append

if ($needsReboot) {
    "$(Get-Date -Format s) redemarrage final" | Out-File $log -Append
    Restart-Computer -Force
} else {
    "$(Get-Date -Format s) aucun redemarrage necessaire" | Out-File $log -Append
}