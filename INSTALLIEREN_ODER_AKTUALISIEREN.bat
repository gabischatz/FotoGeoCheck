@echo off
setlocal

REM Für UTF-8-Konsole (Windows 10/11)
chcp 65001 >nul 2>&1

REM Alternativ: Deutsche Umlaute ohne UTF-8
REM chcp 1252 >nul

echo FotoGeoCheck v1.1.4 installieren/aktualisieren
echo.
echo Standard-Ziel: %USERPROFILE%\fotogeocheck
echo.
set /p "USER_Target=Bitte geben Sie das gewuenschte Installationsverzeichnis ein (oder druecken Sie Enter fuer Standard): "

if "%USER_Target%"=="" (
    set "TARGET=%USERPROFILE%\fotogeocheck"
) else (
    set "TARGET=%USER_Target%"
)

set "SRC=%~dp0"

echo.
echo Ziel: %TARGET%
echo.

if not exist "%TARGET%" mkdir "%TARGET%"
if not exist "%TARGET%\original" mkdir "%TARGET%\original"
if not exist "%TARGET%\prepared" mkdir "%TARGET%\prepared"
if not exist "%TARGET%\reports" mkdir "%TARGET%\reports"
if not exist "%TARGET%\tools" mkdir "%TARGET%\tools"

copy /Y "%SRC%FotoGeoCheck.ps1" "%TARGET%\FotoGeoCheck.ps1" >nul
copy /Y "%SRC%SpeedCommander-FotoGeoCheck-Starter.scmac" "%TARGET%\SpeedCommander-FotoGeoCheck-Starter.scmac" >nul
copy /Y "%SRC%Start-Pruefung.bat" "%TARGET%\Start-Pruefung.bat" >nul
copy /Y "%SRC%Start-Reparatur.bat" "%TARGET%\Start-Reparatur.bat" >nul
copy /Y "%SRC%Start-SpeedCommander-kompatibel.bat" "%TARGET%\Start-SpeedCommander-kompatibel.bat" >nul
copy /Y "%SRC%EXIFTOOL_HERUNTERLADEN.bat" "%TARGET%\EXIFTOOL_HERUNTERLADEN.bat" >nul
copy /Y "%SRC%EXIFTOOL_HERUNTERLADEN.ps1" "%TARGET%\EXIFTOOL_HERUNTERLADEN.ps1" >nul
copy /Y "%SRC%README.md" "%TARGET%\README.md" >nul
copy /Y "%SRC%README-GitHub.md" "%TARGET%\README-GitHub.md" >nul
copy /Y "%SRC%FORUMSBEITRAG.md" "%TARGET%\FORUMSBEITRAG.md" >nul
copy /Y "%SRC%tools\HIER_EXIFTOOL_EXE_HINEINLEGEN.txt" "%TARGET%\tools\HIER_EXIFTOOL_EXE_HINEINLEGEN.txt" >nul
copy /Y "%SRC%tools\EXIFTOOL_HERUNTERLADEN.bat" "%TARGET%\tools\EXIFTOOL_HERUNTERLADEN.bat" >nul

echo.
echo +--------------------------------------------------+
echo   Fertig.
echo.
echo   Wichtige Hinweise:
echo   - tools\exiftool.exe wurde NICHT ueberschrieben
echo   - Falls ExifTool fehlt: rufen Sie auf:
echo     %TARGET%\EXIFTOOL_HERUNTERLADEN.bat
echo   - Installation in: %TARGET%
echo +--------------------------------------------------+
echo.

pause
