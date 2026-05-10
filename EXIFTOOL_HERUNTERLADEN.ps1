# =====================================================================
# FotoGeoCheck - ExifTool Downloader fuer Windows
# Version: 1.1.5
# Laedt die aktuelle Windows-Version von exiftool.org.
# Ziel: tools\exiftool.exe relativ zum Ordner der gestarteten BAT.
# =====================================================================

param(
    [string]$BaseDir = (Split-Path -Parent $MyInvocation.MyCommand.Path)
)

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Fix 1.1.5:
# CMD/PowerShell kann bei Pfaden mit abschliessendem Backslash und Anfuehrungszeichen
# versehentlich ein Quote-Zeichen in den Parameter uebernehmen. Deshalb wird BaseDir
# hier defensiv bereinigt.
$BaseDir = [string]$BaseDir
$BaseDir = $BaseDir.Trim()
$BaseDir = $BaseDir.Trim([char]34)
$BaseDir = $BaseDir.TrimEnd([char]34)
if ([string]::IsNullOrWhiteSpace($BaseDir)) {
    $BaseDir = Split-Path -Parent $MyInvocation.MyCommand.Path
}

$baseFull = [System.IO.Path]::GetFullPath($BaseDir)
$baseFull = $baseFull.TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)

# Wenn die BAT direkt im tools-Ordner gestartet wurde, ist dieser Ordner selbst das Ziel.
# Sonst wird ein tools-Unterordner neben der BAT verwendet.
if ((Split-Path -Leaf $baseFull) -ieq 'tools') {
    $tools = $baseFull
    $targetRootFull = Split-Path -Parent $baseFull
} else {
    $targetRootFull = $baseFull
    $tools = Join-Path $targetRootFull 'tools'
}

$tmp = Join-Path $env:TEMP 'fotogeocheck-exiftool-download'

if (-not (Test-Path $targetRootFull)) { New-Item -ItemType Directory -Path $targetRootFull -Force | Out-Null }
if (-not (Test-Path $tools)) { New-Item -ItemType Directory -Path $tools -Force | Out-Null }
if (Test-Path $tmp) { Remove-Item $tmp -Recurse -Force }
New-Item -ItemType Directory -Path $tmp -Force | Out-Null

$versionUrl = 'https://exiftool.org/ver.txt'
Write-Host 'Ermittle aktuelle ExifTool-Version von exiftool.org ...'
$ver = (Invoke-WebRequest -Uri $versionUrl -UseBasicParsing).Content.Trim()
if (-not ($ver -match '^[0-9]+\.[0-9]+$')) {
    throw "Ungueltige Versionsnummer von ver.txt: $ver"
}

$arch = if ([Environment]::Is64BitOperatingSystem) { '64' } else { '32' }
$zipName = "exiftool-$($ver)_$arch.zip"
$zipUrl = "https://exiftool.org/$zipName"
$zipPath = Join-Path $tmp $zipName
$extract = Join-Path $tmp "extract-$ver-$arch"
New-Item -ItemType Directory -Path $extract -Force | Out-Null

Write-Host "Lade herunter: $zipUrl"
Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath -UseBasicParsing

Write-Host 'Entpacke ZIP ...'
Expand-Archive -LiteralPath $zipPath -DestinationPath $extract -Force

$exe = Get-ChildItem -Path $extract -Recurse -File | Where-Object {
    $_.Name -ieq 'exiftool(-k).exe' -or $_.Name -ieq 'exiftool.exe'
} | Select-Object -First 1

if (-not $exe) {
    throw 'In der ZIP wurde keine exiftool(-k).exe oder exiftool.exe gefunden.'
}

$targetExe = Join-Path $tools 'exiftool.exe'
Copy-Item -LiteralPath $exe.FullName -Destination $targetExe -Force

$srcFiles = Join-Path $exe.Directory.FullName 'exiftool_files'
$targetFiles = Join-Path $tools 'exiftool_files'
if (Test-Path $srcFiles) {
    if (Test-Path $targetFiles) { Remove-Item $targetFiles -Recurse -Force }
    Copy-Item -LiteralPath $srcFiles -Destination $targetFiles -Recurse -Force
}

Write-Host ''
Write-Host 'ExifTool wurde installiert:'
Write-Host $targetExe
Write-Host ''
Write-Host 'ExifTool-Version:'
& $targetExe -ver
Write-Host ''
Write-Host 'Zielordner:'
Write-Host $tools
