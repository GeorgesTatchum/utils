@echo off
rem create_base_directories.bat
rem Usage: create_base_directories.bat [REPERTOIRE_BASE]
rem Si aucun répertoire n'est fourni, le répertoire courant est utilisé.

if "%~1"=="" (
    set "base_dir=%CD%"
) else (
    set "base_dir=%~1"
)

if "%base_dir%"=="" (
    echo Répertoire de base invalide. 1>&2
    exit /b 1
)

mkdir "%base_dir%\app" >nul 2>&1
if errorlevel 1 (
    echo Erreur lors de la création de "%base_dir%\app" 1>&2
    exit /b 1
)

mkdir "%base_dir%\modules_js" >nul 2>&1
if errorlevel 1 (
    echo Erreur lors de la création de "%base_dir%\modules_js" 1>&2
    exit /b 1
)

echo Répertoires prêts :
echo   %base_dir%\app
echo   %base_dir%\modules_js

exit /b 0