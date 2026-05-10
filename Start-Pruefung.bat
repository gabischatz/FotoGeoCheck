@echo off
setlocal
chcp 65001 >nul
cd /d "%~dp0"
echo FotoGeoCheck v1.1.0
echo.
echo Lege deine Originaldateien in den Ordner: original
echo Lege die vom Tool vorbereiteten Dateien in den Ordner: prepared
echo.
if not exist "original" mkdir "original"
if not exist "prepared" mkdir "prepared"
if not exist "reports" mkdir "reports"
if not exist "tools" mkdir "tools"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0FotoGeoCheck.ps1" -OriginalDir "%~dp0original" -PreparedDir "%~dp0prepared" -OutputDir "%~dp0reports" -OpenReport
pause
