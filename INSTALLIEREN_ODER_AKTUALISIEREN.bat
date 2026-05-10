@echo off
setlocal EnableExtensions

REM UTF-8-Konsole fuer Windows 10/11.
chcp 65001 >nul 2>&1

title FotoGeoCheck v1.1.7 installieren/aktualisieren

echo FotoGeoCheck v1.1.7 installieren/aktualisieren
echo.
echo Standard-Ziel: %USERPROFILE%\fotogeocheck
echo.
set /p "USER_TARGET=Bitte geben Sie das gewuenschte Installationsverzeichnis ein (oder druecken Sie Enter fuer Standard): "

if "%USER_TARGET%"=="" (
    set "TARGET=%USERPROFILE%\fotogeocheck"
) else (
    set "TARGET=%USER_TARGET%"
)

REM Anfuehrungszeichen entfernen, falls der Pfad hineinkopiert wurde.
set "TARGET=%TARGET:"=%"
set "SRC=%~dp0"

cd /d "%SRC%" >nul 2>&1

echo.
echo Quelle: %SRC%
echo Ziel:   %TARGET%
echo.

if not exist "%TARGET%" mkdir "%TARGET%"
if not exist "%TARGET%\original" mkdir "%TARGET%\original"
if not exist "%TARGET%\prepared" mkdir "%TARGET%\prepared"
if not exist "%TARGET%\reports" mkdir "%TARGET%\reports"
if not exist "%TARGET%\tools" mkdir "%TARGET%\tools"

call :copy_file "FotoGeoCheck.ps1" "%TARGET%\FotoGeoCheck.ps1"
call :copy_file "SpeedCommander-FotoGeoCheck-Starter.vbs" "%TARGET%\SpeedCommander-FotoGeoCheck-Starter.vbs"
call :copy_file "Start-Pruefung.bat" "%TARGET%\Start-Pruefung.bat"
call :copy_file "Start-Reparatur.bat" "%TARGET%\Start-Reparatur.bat"
call :copy_file "Start-SpeedCommander-kompatibel.bat" "%TARGET%\Start-SpeedCommander-kompatibel.bat"
call :copy_file "EXIFTOOL_HERUNTERLADEN.bat" "%TARGET%\EXIFTOOL_HERUNTERLADEN.bat"
call :copy_file "EXIFTOOL_HERUNTERLADEN.ps1" "%TARGET%\EXIFTOOL_HERUNTERLADEN.ps1"
call :copy_file "README.md" "%TARGET%\README.md"
call :copy_file "README-GitHub.md" "%TARGET%\README-GitHub.md"
call :copy_file "FORUMSBEITRAG.md" "%TARGET%\FORUMSBEITRAG.md"
call :copy_file "tools\HIER_EXIFTOOL_EXE_HINEINLEGEN.txt" "%TARGET%\tools\HIER_EXIFTOOL_EXE_HINEINLEGEN.txt"
call :copy_file "tools\EXIFTOOL_HERUNTERLADEN.bat" "%TARGET%\tools\EXIFTOOL_HERUNTERLADEN.bat"

if errorlevel 1 goto :copy_error

echo.
echo +--------------------------------------------------+
echo   Fertig.
echo.
echo   Wichtige Hinweise:
echo   - tools\exiftool.exe wurde NICHT ueberschrieben.
echo   - Falls ExifTool fehlt: rufen Sie auf:
echo     %TARGET%\EXIFTOOL_HERUNTERLADEN.bat
echo   - Installation in:
echo     %TARGET%
echo +--------------------------------------------------+
echo.
pause
exit /b 0

:copy_file
if not exist "%~1" (
    echo FEHLER: Quelldatei fehlt: %~1
    exit /b 1
)
copy /Y "%~1" "%~2" >nul
if errorlevel 1 (
    echo FEHLER: Kopieren fehlgeschlagen: %~1
    echo Ziel: %~2
    exit /b 1
)
exit /b 0

:copy_error
echo.
echo Installation wurde wegen eines Kopierfehlers abgebrochen.
echo Bitte pruefe, ob die ZIP vollstaendig entpackt wurde und ob Dateien geoeffnet sind.
echo.
pause
exit /b 1
