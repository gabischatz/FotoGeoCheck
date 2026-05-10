@echo off
setlocal
chcp 65001 >nul
set "TARGET=%USERPROFILE%\fotogeocheck"
set "SRC=%~dp0"

echo FotoGeoCheck v1.1.0 installieren/aktualisieren
echo Ziel: %TARGET%
echo.
if not exist "%TARGET%" mkdir "%TARGET%"
if not exist "%TARGET%\original" mkdir "%TARGET%\original"
if not exist "%TARGET%\prepared" mkdir "%TARGET%\prepared"
if not exist "%TARGET%\reports" mkdir "%TARGET%\reports"
if not exist "%TARGET%\tools" mkdir "%TARGET%\tools"

copy /Y "%SRC%FotoGeoCheck.ps1" "%TARGET%\FotoGeoCheck.ps1" >nul
copy /Y "%SRC%SpeedCommander-FotoGeoCheck-Starter.vbs" "%TARGET%\SpeedCommander-FotoGeoCheck-Starter.vbs" >nul
copy /Y "%SRC%Start-Pruefung.bat" "%TARGET%\Start-Pruefung.bat" >nul
copy /Y "%SRC%Start-Reparatur.bat" "%TARGET%\Start-Reparatur.bat" >nul
copy /Y "%SRC%Start-SpeedCommander-kompatibel.bat" "%TARGET%\Start-SpeedCommander-kompatibel.bat" >nul
copy /Y "%SRC%README.md" "%TARGET%\README.md" >nul
copy /Y "%SRC%README-GitHub.md" "%TARGET%\README-GitHub.md" >nul
copy /Y "%SRC%FORUMSBEITRAG.md" "%TARGET%\FORUMSBEITRAG.md" >nul

echo.
echo Fertig. Wichtig:
echo - tools\exiftool.exe wurde NICHT überschrieben oder gelöscht.
echo - Starte im Zielordner: %TARGET%
echo.
pause
