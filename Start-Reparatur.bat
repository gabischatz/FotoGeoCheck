@echo off
setlocal
chcp 65001 >nul
cd /d "%~dp0"
echo FotoGeoCheck v1.1.0 - Reparaturmodus
echo.
echo WARNUNG:
echo Bei JPG/JPEG-Dateien werden Metadaten aus dem Original in die vorbereitete Datei zurückkopiert.
echo Lege Sicherungskopien an, wenn du unsicher bist.
echo.
if not exist "original" mkdir "original"
if not exist "prepared" mkdir "prepared"
if not exist "reports" mkdir "reports"
if not exist "tools" mkdir "tools"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0FotoGeoCheck.ps1" -OriginalDir "%~dp0original" -PreparedDir "%~dp0prepared" -OutputDir "%~dp0reports" -Repair -OpenReport
pause
