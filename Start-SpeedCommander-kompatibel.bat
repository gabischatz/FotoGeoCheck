@echo off
setlocal
chcp 65001 >nul
cd /d "%~dp0"
echo FotoGeoCheck v1.1.0 - SpeedCommander-kompatibler Start
echo.
if not exist "original" mkdir "original"
if not exist "prepared" mkdir "prepared"
if not exist "reports" mkdir "reports"
if not exist "tools" mkdir "tools"
powershell.exe -STA -NoProfile -ExecutionPolicy Bypass -NoExit -File "%~dp0FotoGeoCheck.ps1" -ActivePath "%cd%" -ActiveSelection "" -ActiveFocused "" -OpenReport
pause
