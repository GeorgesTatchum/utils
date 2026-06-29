<#
  Vérification distante PARALLÈLE du niveau de correctif Windows Server — Ticket 3 (Threat Intel 2026-05)
  Relève CurrentBuild.UBR sur chaque serveur et compare au build cible de sa version.
  Gère un IDENTIFIANT PROPRE PAR SERVEUR (identifiants chiffrés DPAPI).

  Pré-requis :
   - PowerShell 7+ sur le poste d'exécution (pour ForEach-Object -Parallel).
   - WinRM joignable sur les cibles (port 5985/5986). Test : Test-WSMan <serveur>.
   - Pour des comptes LOCAUX (hors domaine) : déclarer les cibles en TrustedHosts (voir étape 0).
   - Droits administrateur local sur chaque serveur via l'identifiant fourni.

  Aucun mot de passe en clair dans ce script : chaque identifiant est lu depuis un .xml chiffré (DPAPI),
  déchiffrable uniquement par le même utilisateur Windows sur la même machine.
#>

# --- Étape 0 (une seule fois) : préparer les identifiants chiffrés, un fichier par serveur ---
# Pour CHAQUE serveur, exécuter une fois (saisie interactive du mot de passe) :
#   Get-Credential | Export-CliXml -Path 'C:\secure\creds\SRV-XXX-01.xml'
#
# Pour des comptes locaux (hors domaine), autoriser les cibles côté poste d'exécution :
#   Set-Item WSMan:\localhost\Client\TrustedHosts -Value 'SRV-XXX-01,SRV-XXX-02,...' -Concatenate -Force
#   (ou utiliser WinRM HTTPS avec certificats valides pour éviter TrustedHosts)

# --- Étape 1 : inventaire (CSV : ComputerName,CredFile) ---
# Exemple de C:\secure\inventaire.csv :
#   ComputerName,CredFile
#   SRV-XXX-01,C:\secure\creds\SRV-XXX-01.xml
#   SRV-XXX-02,C:\secure\creds\SRV-XXX-02.xml
$inventaire = Import-Csv 'C:\secure\inventaire.csv'

# --- Étape 2 : builds cibles par version (Patch Tuesday mai 2026) ---
$cibles = @{
  'Windows Server 2016' = [version]'10.0.14393.9140'
  'Windows Server 2019' = [version]'10.0.17763.8755'
  'Windows Server 2022' = [version]'10.0.20348.5139'
  'Windows Server 2025' = [version]'10.0.26100.32860'
}

# --- Étape 3 : vérification distante parallèle ---
$resultats = $inventaire | ForEach-Object -ThrottleLimit 30 -Parallel {
  $cibles = $using:cibles
  $nom    = $_.ComputerName
  try {
    $cred = Import-CliXml -Path $_.CredFile -ErrorAction Stop
    $info = Invoke-Command -ComputerName $nom -Credential $cred -ErrorAction Stop -ScriptBlock {
      $v = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
      [PSCustomObject]@{
        Produit = $v.ProductName
        Build   = [version]("$($v.CurrentBuild).$($v.UBR)")
      }
    }
    $cibleKey = $cibles.Keys | Where-Object { $info.Produit -like "*$_*" } | Select-Object -First 1
    $cible    = if ($cibleKey) { $cibles[$cibleKey] } else { $null }
    $statut   = if (-not $cible)            { 'Version non mappée' }
                elseif ($info.Build -ge $cible) { 'Patché' }
                else                        { 'NON patché' }
    [PSCustomObject]@{ Serveur=$nom; Produit=$info.Produit; Build=$info.Build; Cible=$cible; Statut=$statut }
  }
  catch {
    [PSCustomObject]@{ Serveur=$nom; Produit='-'; Build='-'; Cible='-'; Statut="Injoignable : $($_.Exception.Message)" }
  }
}

# --- Étape 4 : restitution + export probant ---
$resultats | Sort-Object Statut, Serveur | Format-Table -AutoSize
$resultats | Export-Csv -Path 'C:\secure\resultat_builds_2026-05.csv' -NoTypeInformation -Encoding UTF8

# Résumé
$resultats | Group-Object Statut | Select-Object Name, Count | Format-Table -AutoSize
