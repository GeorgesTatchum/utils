$rootPath = "C:\Sites"

# Liste des dossiers à créer
$folders = @(
    $rootPath,
    "$rootPath\Certificats",
    "$rootPath\Logs",
    "$rootPath\outils",
    "$rootPath\outils\tools",
    "$rootPath\sessions",
    "$rootPath\SoapTemp",
    "$rootPath\tmp_upload",
    "$rootPath\wwwroot",
    "$rootPath\wwwroot\app",
    "$rootPath\wwwroot\modules_js"
)

# Création des dossiers
foreach ($folder in $folders) {
    if (-not (Test-Path -Path $folder)) {
        New-Item -Path $folder -ItemType Directory | Out-Null
        Write-Host "Créé : $folder"
    }
    else {
        Write-Host "Existe déjà : $folder"
    }
}

Write-Host "Arborescence terminée."