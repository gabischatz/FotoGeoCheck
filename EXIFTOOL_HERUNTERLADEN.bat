@echo off
setlocal
chcp 65001 >nul

rem =====================================================================
rem FotoGeoCheck - ExifTool Downloader fuer Windows
rem Version: 1.1.5
rem
rem Installiert ExifTool in den tools-Ordner der Installation,
rem aus der diese BAT gestartet wird.
rem
rem WICHTIGER FIX 1.1.5:
rem %%~dp0 endet immer mit Backslash. Wird dieser Pfad direkt in
rem Anfuehrungszeichen an PowerShell uebergeben, kann daraus ein
rem kaputter Pfad mit illegalem Zeichen entstehen. Deshalb wird fuer
rem -BaseDir jetzt %%~dp0. verwendet.
rem =====================================================================

set "BATDIR=%~dp0"
set "BASEDIR=%~dp0."
set "PS1=%BATDIR%EXIFTOOL_HERUNTERLADEN.ps1"

rem Falls diese BAT aus dem tools-Ordner gestartet wird, liegt die PS1 eine Ebene hoeher.
if not exist "%PS1%" (
    set "PS1=%BATDIR%..\EXIFTOOL_HERUNTERLADEN.ps1"
)

if not exist "%PS1%" (
    echo FEHLER: Die PowerShell-Datei wurde nicht gefunden:
    echo %BATDIR%EXIFTOOL_HERUNTERLADEN.ps1
    echo %BATDIR%..\EXIFTOOL_HERUNTERLADEN.ps1
    echo.
    echo Bitte die ZIP vollstaendig entpacken.
    echo.
    pause
    exit /b 2
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%PS1%" -BaseDir "%BASEDIR%"
set "ERR=%ERRORLEVEL%"

echo.
if not "%ERR%"=="0" (
    echo FEHLER: ExifTool konnte nicht automatisch heruntergeladen werden.
    echo Bitte pruefe deine Internetverbindung oder lade ExifTool manuell von https://exiftool.org/ herunter.
    pause
    exit /b %ERR%
)

echo Fertig.
echo.
pause
