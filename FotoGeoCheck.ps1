<#
Projekt: FotoGeoCheck - Metadaten-Prüfer für Panoramax-Vorbereitung
Datei: FotoGeoCheck.ps1
Version: 1.1.0
- Kurzer Name: FotoGeoCheck.
- HTML-Ausgabe mit Umlauten überarbeitet.
Datum: 2026-05-10
Autor: Lutz Müller / erstellt mit ChatGPT

Zweck:
  Vergleicht Originalbilder/-videos mit vorbereiteten Dateien.
  Erkennt fehlende EXIF/GPS/XMP-Metadaten.
  Kann bei JPG/JPEG-Dateien Metadaten aus dem Original zur vorbereiteten Datei zurückkopieren.

Voraussetzung:
  ExifTool muss installiert sein. Das Script sucht automatisch:
  - tools\exiftool.exe im Tool-Ordner
  - exiftool.exe neben diesem Script
  - PATH
  - typische Windows-Installationsordner

Beispiel prüfen:
  powershell -ExecutionPolicy Bypass -File .\FotoGeoCheck.ps1 -OriginalDir .\original -PreparedDir .\prepared

Beispiel prüfen und reparieren:
  powershell -ExecutionPolicy Bypass -File .\FotoGeoCheck.ps1 -OriginalDir .\original -PreparedDir .\prepared -Repair
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$OriginalDir = "",

    [Parameter(Mandatory = $false)]
    [string]$PreparedDir = "",

    [Parameter(Mandatory = $false)]
    [string]$OutputDir = "",

    [Parameter(Mandatory = $false)]
    [string]$ExifTool = "",

    [Parameter(Mandatory = $false)]
    [switch]$Repair,

    [Parameter(Mandatory = $false)]
    [switch]$OpenReport,

    # Diese drei Parameter sind absichtlich vorhanden, damit ein SpeedCommander-Makro
    # seine Standardwerte übergeben darf, ohne dass PowerShell mit
    # "Parameter nicht gefunden" abbricht. Für die Prüfung werden sie nur
    # als Start-/Diagnosehinweis verwendet.
    [Parameter(Mandatory = $false)]
    [string]$ActivePath = "",

    [Parameter(Mandatory = $false)]
    [string]$ActiveSelection = "",

    [Parameter(Mandatory = $false)]
    [string]$ActiveFocused = ""
)

$ErrorActionPreference = "Stop"

$ScriptVersion = "1.1.0"
$SupportedExtensions = @(".jpg", ".jpeg", ".mp4", ".mov")
$RepairExtensions = @(".jpg", ".jpeg")

function Write-Step {
    param([string]$Text, [string]$Color = "Cyan")
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] $Text" -ForegroundColor $Color
}

function Test-Tool {
    param([string]$Tool)
    try {
        $null = & $Tool -ver 2>$null
        return $true
    } catch {
        return $false
    }
}

function Get-ScriptFolder {
    if ($PSScriptRoot -and $PSScriptRoot.Trim().Length -gt 0) { return $PSScriptRoot }
    return Split-Path -Parent $MyInvocation.MyCommand.Path
}

function Resolve-ExifToolPath {
    param([string]$RequestedPath)

    $scriptFolder = Get-ScriptFolder
    $candidates = New-Object System.Collections.Generic.List[string]

    if (-not [string]::IsNullOrWhiteSpace($RequestedPath)) {
        $candidates.Add($RequestedPath)
    }

    $candidates.Add((Join-Path $scriptFolder "tools\exiftool.exe"))
    $candidates.Add((Join-Path $scriptFolder "exiftool.exe"))
    $candidates.Add("C:\ExifTool\exiftool.exe")
    $candidates.Add("C:\Tools\ExifTool\exiftool.exe")
    $candidates.Add("C:\Program Files\ExifTool\exiftool.exe")
    $candidates.Add("C:\Program Files (x86)\ExifTool\exiftool.exe")
    $candidates.Add("exiftool.exe")
    $candidates.Add("exiftool")

    foreach ($candidate in $candidates) {
        if ([string]::IsNullOrWhiteSpace($candidate)) { continue }
        if ($candidate -match "\\|:") {
            if ((Test-Path -LiteralPath $candidate -PathType Leaf) -and (Test-Tool $candidate)) { return $candidate }
        } else {
            $cmd = Get-Command $candidate -ErrorAction SilentlyContinue
            if ($cmd -and (Test-Tool $candidate)) { return $candidate }
        }
    }

    return ""
}

function Write-LastRunLog {
    param([string]$OutputDirValue, [string]$Text, [switch]$Append)
    try {
        if (-not (Test-Path -Path $OutputDirValue)) { New-Item -Path $OutputDirValue -ItemType Directory -Force | Out-Null }
        $logPath = Join-Path $OutputDirValue "fotogeocheck_last_run.log"
        if ($Append) { Add-Content -Path $logPath -Value $Text -Encoding UTF8 }
        else { Set-Content -Path $logPath -Value $Text -Encoding UTF8 }
    } catch {
        # Logfehler dürfen den eigentlichen Lauf nicht stoppen.
    }
}

function Resolve-ToolRootFromActivePath {
    param([string]$PathValue)
    $scriptFolder = Get-ScriptFolder
    if ([string]::IsNullOrWhiteSpace($PathValue)) { return $scriptFolder }
    try {
        $p = [System.IO.Path]::GetFullPath($PathValue)
        if ((Test-Path -LiteralPath (Join-Path $p "original") -PathType Container) -and
            (Test-Path -LiteralPath (Join-Path $p "prepared") -PathType Container)) { return $p }
        $parent = Split-Path -Parent $p
        if ($parent -and (Test-Path -LiteralPath (Join-Path $parent "original") -PathType Container) -and
            (Test-Path -LiteralPath (Join-Path $parent "prepared") -PathType Container)) { return $parent }
    } catch {}
    return $scriptFolder
}

function Normalize-PathSafe {
    param([string]$PathValue)
    return [System.IO.Path]::GetFullPath($PathValue)
}

function Get-MediaFiles {
    param([string]$Dir)
    Get-ChildItem -Path $Dir -File -Recurse | Where-Object {
        $SupportedExtensions -contains $_.Extension.ToLowerInvariant()
    } | Sort-Object FullName
}

function Split-SpeedCommanderPathList {
    param([string]$PathList)

    # Wichtig: keine .NET-Generic-List zurückgeben.
    # SpeedCommander liefert eine Pipe-Liste als String. PowerShell kann Generic-Lists
    # je nach Host/Version unerwartet als Einzelobjekt statt als Array behandeln.
    # Das fuehrte in v1.0.4 zu: "Die Argumenttypen stimmen nicht überein."
    $items = @()
    if ([string]::IsNullOrWhiteSpace($PathList)) { return @() }

    foreach ($part in ($PathList -split "\|")) {
        $clean = [string]$part
        $clean = $clean.Trim()
        if ([string]::IsNullOrWhiteSpace($clean)) { continue }
        if (Test-Path -LiteralPath $clean) {
            $items += [System.IO.Path]::GetFullPath($clean)
        }
    }
    return @($items)
}

function Get-MediaFilesFromPaths {
    param([object[]]$Paths)

    # Absichtlich normales PowerShell-Array statt List[FileInfo].
    # Dadurch ist die Rückgabe für foreach, Count und Parameterbindung stabil.
    $items = @()

    foreach ($pRaw in @($Paths)) {
        if ($null -eq $pRaw) { continue }
        $p = [string]$pRaw
        if ([string]::IsNullOrWhiteSpace($p)) { continue }

        if (Test-Path -LiteralPath $p -PathType Leaf) {
            $fi = Get-Item -LiteralPath $p
            if ($SupportedExtensions -contains $fi.Extension.ToLowerInvariant()) {
                $items += $fi
            }
        } elseif (Test-Path -LiteralPath $p -PathType Container) {
            foreach ($fi in @(Get-MediaFiles $p)) {
                $items += $fi
            }
        }
    }

    # Doppelte vermeiden, falls eine Datei mehrfach markiert/enthalten ist.
    return @($items | Sort-Object FullName -Unique)
}

function Find-OriginalForPreparedFile {
    param(
        [object]$PreparedFile,
        [hashtable]$OriginalIndex
    )

    if ($null -eq $PreparedFile) { return $null }
    if (-not ($PreparedFile -is [System.IO.FileInfo])) {
        if (Test-Path -LiteralPath ([string]$PreparedFile) -PathType Leaf) {
            $PreparedFile = Get-Item -LiteralPath ([string]$PreparedFile)
        } else {
            return $null
        }
    }

    $key = Get-KeyForFile $PreparedFile
    if ($OriginalIndex.ContainsKey($key)) { return $OriginalIndex[$key] }

    # Fallback für typische FotoGeoTool-/FotoGeoCheck-Namen, z.B. name-prepared.jpg, name_fotogeotool.jpg, name_bearbeitet.jpg
    $base = $PreparedFile.BaseName.ToLowerInvariant()
    $candidates = New-Object System.Collections.Generic.List[string]
    $candidates.Add($base)

    foreach ($suffix in @('-prepared','_prepared','-fotogeotool','_fotogeotool','-bearbeitet','_bearbeitet','-export','_export','-fixed','_fixed','-geo','_geo')) {
        if ($base.EndsWith($suffix)) { $candidates.Add($base.Substring(0, $base.Length - $suffix.Length)) }
    }

    # Falls FotoGeoTool eine Nummer am Ende anhängt: bild-001.jpg -> bild.jpg
    $short = ($base -replace '[-_ ]\d{1,5}$','')
    if ($short -ne $base) { $candidates.Add($short) }

    foreach ($c in @($candidates | Select-Object -Unique)) {
        if ($OriginalIndex.ContainsKey($c)) { return $OriginalIndex[$c] }
    }
    return $null
}

function Get-KeyForFile {
    param([System.IO.FileInfo]$File)
    # Primaer gleicher Dateiname ohne Erweiterung.
    # Dadurch kann prepared.jpg gegen original.jpg oder original.jpeg gefunden werden.
    return $File.BaseName.ToLowerInvariant()
}

function Read-Metadata {
    param([string]$FilePath)

    $args = @(
        "-j", "-n", "-s", "-a",
        "-FileName", "-FileType", "-MIMEType",
        "-ImageWidth", "-ImageHeight", "-ExifImageWidth", "-ExifImageHeight",
        "-Make", "-Model", "-Software",
        "-DateTimeOriginal", "-CreateDate", "-ModifyDate", "-SubSecTimeOriginal", "-OffsetTimeOriginal",
        "-GPSLatitude", "-GPSLongitude", "-GPSAltitude", "-GPSDateStamp", "-GPSTimeStamp",
        "-GPSImgDirection", "-GPSImgDirectionRef", "-PoseHeadingDegrees",
        "-ProjectionType", "-UsePanoramaViewer", "-FullPanoWidthPixels", "-FullPanoHeightPixels",
        "-CroppedAreaImageWidthPixels", "-CroppedAreaImageHeightPixels", "-CroppedAreaLeftPixels", "-CroppedAreaTopPixels",
        "-Orientation", "-XResolution", "-YResolution", "-ColorSpace",
        "--ThumbnailImage", "--PreviewImage",
        $FilePath
    )

    $json = & $ExifTool @args 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "ExifTool konnte Metadaten nicht lesen: $json"
    }

    $arr = $json | ConvertFrom-Json
    if ($arr.Count -lt 1) { return $null }
    return $arr[0]
}

function Has-Value {
    param($Obj, [string]$Name)
    if ($null -eq $Obj) { return $false }
    $prop = $Obj.PSObject.Properties[$Name]
    if ($null -eq $prop) { return $false }
    if ($null -eq $prop.Value) { return $false }
    $text = [string]$prop.Value
    return ($text.Trim().Length -gt 0)
}

function Get-Val {
    param($Obj, [string]$Name)
    if ($null -eq $Obj) { return $null }
    $prop = $Obj.PSObject.Properties[$Name]
    if ($null -eq $prop) { return $null }
    return $prop.Value
}

function Almost-EqualNumber {
    param($A, $B, [double]$Tolerance)
    try {
        if ($null -eq $A -or $null -eq $B) { return $false }
        return ([Math]::Abs(([double]$A) - ([double]$B)) -le $Tolerance)
    } catch {
        return ([string]$A -eq [string]$B)
    }
}

function Compare-Tag {
    param(
        $Original,
        $Prepared,
        [string]$Tag,
        [string]$Kind = "text"
    )

    $origHas = Has-Value $Original $Tag
    $prepHas = Has-Value $Prepared $Tag
    $origVal = Get-Val $Original $Tag
    $prepVal = Get-Val $Prepared $Tag

    if ($origHas -and -not $prepHas) {
        return @{ Tag = $Tag; Status = "FEHLT"; Original = $origVal; Prepared = $prepVal }
    }
    if ($origHas -and $prepHas) {
        $same = $false
        if ($Kind -eq "gps") {
            $same = Almost-EqualNumber $origVal $prepVal 0.000001
        } elseif ($Kind -eq "number") {
            $same = Almost-EqualNumber $origVal $prepVal 0.01
        } else {
            $same = ([string]$origVal -eq [string]$prepVal)
        }
        if (-not $same) {
            return @{ Tag = $Tag; Status = "ABWEICHEND"; Original = $origVal; Prepared = $prepVal }
        }
    }
    return $null
}

function Compare-Metadata {
    param($Original, $Prepared)

    $critical = New-Object System.Collections.Generic.List[object]
    $warnings = New-Object System.Collections.Generic.List[object]

    foreach ($tag in @("GPSLatitude", "GPSLongitude")) {
        $diff = Compare-Tag $Original $Prepared $tag "gps"
        if ($null -ne $diff) { $critical.Add($diff) }
    }

    foreach ($tag in @("DateTimeOriginal", "CreateDate")) {
        $diff = Compare-Tag $Original $Prepared $tag "text"
        if ($null -ne $diff) { $critical.Add($diff) }
    }

    foreach ($tag in @("Make", "Model", "ImageWidth", "ImageHeight")) {
        $kind = if ($tag -match "Width|Height") { "number" } else { "text" }
        $diff = Compare-Tag $Original $Prepared $tag $kind
        if ($null -ne $diff) { $warnings.Add($diff) }
    }

    foreach ($tag in @("GPSAltitude", "GPSImgDirection", "GPSImgDirectionRef", "PoseHeadingDegrees", "ProjectionType", "UsePanoramaViewer", "FullPanoWidthPixels", "FullPanoHeightPixels", "Orientation", "ColorSpace")) {
        $diff = Compare-Tag $Original $Prepared $tag "text"
        if ($null -ne $diff) { $warnings.Add($diff) }
    }

    $score = 100
    $score -= ($critical.Count * 25)
    $score -= ($warnings.Count * 5)
    if ($score -lt 0) { $score = 0 }

    $status = "OK"
    if ($critical.Count -gt 0) { $status = "FEHLER" }
    elseif ($warnings.Count -gt 0) { $status = "WARNUNG" }

    return @{ Status = $status; Score = $score; Critical = @($critical); Warnings = @($warnings) }
}

function Copy-MetadataBack {
    param([string]$OriginalFile, [string]$PreparedFile)

    $args = @(
        "-overwrite_original",
        "-P",
        "-m",
        "-TagsFromFile", $OriginalFile,
        "-all:all>all:all",
        "--ThumbnailImage",
        "--PreviewImage",
        $PreparedFile
    )

    $out = & $ExifTool @args 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Metadaten konnten nicht zurückkopiert werden: $out"
    }
    return ($out -join "`n")
}

function HtmlEncode {
    param($Text)
    return [System.Net.WebUtility]::HtmlEncode([string]$Text)
}

function DiffListToText {
    param($List)
    if ($null -eq $List -or $List.Count -eq 0) { return "" }
    return (($List | ForEach-Object { "$($_.Tag): $($_.Status)" }) -join "; ")
}

function New-HtmlReport {
    param([object[]]$Rows, [string]$Path, [string]$OriginalDir, [string]$PreparedDir, [bool]$RepairMode)

    $created = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $repairText = if ($RepairMode) { "Ja" } else { "Nein" }
    $ok = @($Rows | Where-Object Status -eq "OK").Count
    $warn = @($Rows | Where-Object Status -eq "WARNUNG").Count
    $err = @($Rows | Where-Object Status -eq "FEHLER").Count
    $miss = @($Rows | Where-Object Status -eq "ORIGINAL_FEHLT").Count

    $htmlRows = foreach ($r in $Rows) {
        $cls = switch ($r.Status) {
            "OK" { "ok" }
            "WARNUNG" { "warn" }
            "FEHLER" { "err" }
            "ORIGINAL_FEHLT" { "missing" }
            default { "neutral" }
        }
        "<tr class='$cls'><td>$(HtmlEncode $r.PreparedFile)</td><td>$(HtmlEncode $r.OriginalFile)</td><td>$(HtmlEncode $r.Status)</td><td>$($r.Score)</td><td>$(HtmlEncode $r.CriticalText)</td><td>$(HtmlEncode $r.WarningText)</td><td>$(HtmlEncode $r.Action)</td></tr>"
    }

    $html = @"
<!doctype html>
<html lang="de">
<head>
<meta charset="utf-8">
<title>FotoGeoCheck Prüfbericht</title>
<style>
:root{--bg:#f5f8fb;--card:#fff;--text:#172033;--muted:#5c667a;--ok:#daf5dd;--warn:#fff1c2;--err:#ffd7d7;--missing:#e5e7eb;--line:#ccd5e1;--blue:#0b63ce;}
body{font-family:Segoe UI,Arial,sans-serif;background:var(--bg);color:var(--text);margin:0;padding:24px;}
header{background:linear-gradient(135deg,#e8f6ff,#ffffff);border:1px solid var(--line);border-radius:16px;padding:20px;margin-bottom:18px;box-shadow:0 4px 16px rgba(0,0,0,.06)}
h1{margin:0 0 8px;font-size:28px} .meta{color:var(--muted);line-height:1.55}.cards{display:flex;gap:12px;flex-wrap:wrap;margin:16px 0}
.card{background:var(--card);border:1px solid var(--line);border-radius:12px;padding:12px 16px;min-width:130px;box-shadow:0 3px 10px rgba(0,0,0,.04)}
.card b{font-size:24px;display:block}.ok b{color:#167a2f}.warn b{color:#936b00}.err b{color:#a51616}.missing b{color:#555}
table{width:100%;border-collapse:collapse;background:white;border:1px solid var(--line);border-radius:12px;overflow:hidden;box-shadow:0 4px 16px rgba(0,0,0,.05)}
th,td{border-bottom:1px solid var(--line);padding:9px 10px;text-align:left;vertical-align:top;font-size:14px}th{background:#edf4fb;color:#10233d;position:sticky;top:0}tr.ok{background:var(--ok)}tr.warn{background:var(--warn)}tr.err{background:var(--err)}tr.missing{background:var(--missing)}
.note{margin-top:18px;color:var(--muted);font-size:14px;line-height:1.5}.small{font-size:12px;color:var(--muted)}
</style>
</head>
<body>
<header>
<h1>FotoGeoCheck Prüfbericht</h1>
<div class="meta">
Version: $ScriptVersion<br>
Erstellt: $created<br>
Originalordner: $(HtmlEncode $OriginalDir)<br>
Vorbereitete Dateien: $(HtmlEncode $PreparedDir)<br>
Reparaturmodus: $repairText
</div>
</header>
<div class="cards">
<div class="card ok"><b>$ok</b>OK</div>
<div class="card warn"><b>$warn</b>Warnungen</div>
<div class="card err"><b>$err</b>Fehler</div>
<div class="card missing"><b>$miss</b>Original fehlt</div>
</div>
<table>
<thead><tr><th>Vorbereitete Datei</th><th>Original</th><th>Status</th><th>Score</th><th>Kritisch</th><th>Hinweise</th><th>Aktion</th></tr></thead>
<tbody>
$($htmlRows -join "`n")
</tbody>
</table>
<div class="note">
<b>Interpretation:</b> Kritisch sind GPSLatitude, GPSLongitude, DateTimeOriginal und CreateDate. Wenn diese fehlen oder abweichen, kann die Datei für Panoramax problematisch sein.<br>
<b>Wichtig:</b> Dieser Bericht beweist nicht, dass Panoramax die Datei sicher akzeptiert. Er zeigt aber, ob typische Metadaten beim Bearbeiten verloren gegangen sind.
</div>
</body>
</html>
"@
    Set-Content -Path $Path -Value $html -Encoding UTF8
}

# Hauptlauf
Write-Step "FotoGeoCheck v$ScriptVersion gestartet" "Cyan"

$toolRoot = Resolve-ToolRootFromActivePath $ActivePath
if ([string]::IsNullOrWhiteSpace($OriginalDir)) { $OriginalDir = Join-Path $toolRoot "original" }
if ([string]::IsNullOrWhiteSpace($PreparedDir)) { $PreparedDir = Join-Path $toolRoot "prepared" }
if ([string]::IsNullOrWhiteSpace($OutputDir)) { $OutputDir = Join-Path $toolRoot "reports" }

$OriginalDir = Normalize-PathSafe $OriginalDir
$PreparedDir = Normalize-PathSafe $PreparedDir
$OutputDir = Normalize-PathSafe $OutputDir

if (-not (Test-Path -Path $OutputDir)) { New-Item -Path $OutputDir -ItemType Directory -Force | Out-Null }

$logHeader = @(
    "FotoGeoCheck v$ScriptVersion",
    "Zeit: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')",
    "Script: $($MyInvocation.MyCommand.Path)",
    "ToolRoot: $toolRoot",
    "OriginalDir: $OriginalDir",
    "PreparedDir: $PreparedDir",
    "OutputDir: $OutputDir",
    "ActivePath: $ActivePath",
    "ActiveSelection: $ActiveSelection",
    "ActiveFocused: $ActiveFocused",
    "Repair: $([bool]$Repair)",
    ("-" * 70),
    ""
) -join "`r`n"
Write-LastRunLog -OutputDirValue $OutputDir -Text $logHeader

if (-not (Test-Path -Path $OriginalDir -PathType Container)) { throw "OriginalDir existiert nicht: $OriginalDir" }
if (-not (Test-Path -Path $PreparedDir -PathType Container)) { throw "PreparedDir existiert nicht: $PreparedDir" }

$resolvedExifTool = Resolve-ExifToolPath $ExifTool
if ([string]::IsNullOrWhiteSpace($resolvedExifTool)) {
    $msg = "ExifTool wurde nicht gefunden.`r`n`r`nLösung:`r`n1. Lade ExifTool für Windows herunter.`r`n2. Benenne die Datei ggf. in exiftool.exe um.`r`n3. Lege exiftool.exe in diesen Ordner:`r`n   $(Join-Path (Get-ScriptFolder) 'tools')`r`n`r`nAlternativ kannst du beim Start -ExifTool mit vollem Pfad angeben."
    Write-LastRunLog -OutputDirValue $OutputDir -Text $msg -Append
    throw $msg
}
$ExifTool = $resolvedExifTool
Write-Step "ExifTool gefunden: $ExifTool" "Green"
Write-LastRunLog -OutputDirValue $OutputDir -Text "ExifTool: $ExifTool`r`n" -Append

Write-Step "Originale werden eingelesen: $OriginalDir" "Yellow"
$originalFiles = @(Get-MediaFiles $OriginalDir)

$selectedPaths = @(Split-SpeedCommanderPathList $ActiveSelection)
$focusedPaths = @(Split-SpeedCommanderPathList $ActiveFocused)
$selectedMediaFiles = @(Get-MediaFilesFromPaths $selectedPaths)

if ($selectedMediaFiles.Count -gt 0) {
    Write-Step "SpeedCommander-Auswahl wird als vorbereitete Datei(en) geprüft: $($selectedMediaFiles.Count)" "Yellow"
    foreach ($sf in @($selectedMediaFiles)) { Write-LastRunLog -OutputDirValue $OutputDir -Text "Auswahl-Datei: $($sf.FullName)`r`n" -Append }
    $preparedFiles = @($selectedMediaFiles)
    $preparedSourceText = "SpeedCommander-Auswahl: " + (($selectedMediaFiles | ForEach-Object { $_.FullName }) -join " | ")
} else {
    # Wenn nichts markiert ist, darf die fokussierte Datei helfen.
    $focusedMediaFiles = @(Get-MediaFilesFromPaths $focusedPaths)
    if ($focusedMediaFiles.Count -gt 0) {
        Write-Step "Keine Auswahl gefunden; fokussierte Datei wird geprüft: $($focusedMediaFiles[0].FullName)" "Yellow"
        $preparedFiles = @($focusedMediaFiles)
        $preparedSourceText = "SpeedCommander-Fokus: " + (($focusedMediaFiles | ForEach-Object { $_.FullName }) -join " | ")
    } else {
        Write-Step "Vorbereitete Dateien werden eingelesen: $PreparedDir" "Yellow"
        $preparedFiles = @(Get-MediaFiles $PreparedDir)
        $preparedSourceText = $PreparedDir
    }
}

if ($preparedFiles.Count -eq 0) {
    throw "Keine vorbereiteten Medien gefunden. Unterstützt: $($SupportedExtensions -join ', '). Entweder Dateien im Ordner 'prepared' ablegen oder im SpeedCommander .jpg/.jpeg/.mp4/.mov markieren und dann den Starter ausführen."
}

$originalIndex = @{}
foreach ($f in $originalFiles) {
    $key = Get-KeyForFile $f
    if (-not $originalIndex.ContainsKey($key)) { $originalIndex[$key] = $f }
}

$rows = New-Object System.Collections.Generic.List[object]
$counter = 0
foreach ($preparedRaw in @($preparedFiles)) {
    $counter++
    try {
        if ($preparedRaw -is [System.IO.FileInfo]) {
            $prepared = $preparedRaw
        } else {
            $prepared = Get-Item -LiteralPath ([string]$preparedRaw)
        }
    } catch {
        $rows.Add([pscustomobject]@{
            PreparedFile = [string]$preparedRaw
            OriginalFile = ""
            Status = "FEHLER"
            Score = 0
            CriticalText = "Vorbereitete Datei konnte nicht als Dateiobjekt gelesen werden: $($_.Exception.Message)"
            WarningText = ""
            Action = "Datei übersprungen"
        })
        continue
    }

    Write-Progress -Activity "Metadaten pruefen" -Status "$counter / $($preparedFiles.Count): $($prepared.Name)" -PercentComplete ([int](($counter / [double]$preparedFiles.Count) * 100))

    $original = Find-OriginalForPreparedFile -PreparedFile $prepared -OriginalIndex $originalIndex
    if ($null -eq $original) {
        try {
            $metaPreparedOnly = Read-Metadata $prepared.FullName
            $missing = New-Object System.Collections.Generic.List[string]
            foreach ($tag in @("GPSLatitude", "GPSLongitude", "DateTimeOriginal", "CreateDate")) {
                if (-not (Has-Value $metaPreparedOnly $tag)) { $missing.Add($tag) }
            }
            $statusNoOriginal = if ($missing.Count -gt 0) { "FEHLER" } else { "ORIGINAL_FEHLT" }
            $criticalText = if ($missing.Count -gt 0) { "Ohne Original geprüft; fehlt in Datei: " + (($missing | ForEach-Object { $_ }) -join "; ") } else { "Kein passendes Original gefunden; Datei hat aber Basisdaten GPS/Zeit." }
            $rows.Add([pscustomobject]@{
                PreparedFile = $prepared.FullName
                OriginalFile = ""
                Status = $statusNoOriginal
                Score = if ($missing.Count -gt 0) { 30 } else { 60 }
                CriticalText = $criticalText
                WarningText = "Originalvergleich nicht möglich. Lege das passende Original mit gleichem Basisnamen in 'original'."
                Action = "Einzelpruefung der markierten Datei ausgeführt."
            })
        } catch {
            $rows.Add([pscustomobject]@{
                PreparedFile = $prepared.FullName
                OriginalFile = ""
                Status = "FEHLER"
                Score = 0
                CriticalText = $_.Exception.Message
                WarningText = ""
                Action = "Fehler bei Einzelpruefung ohne Original."
            })
        }
        continue
    }

    $action = "Nur geprüft"
    try {
        $metaOriginal = Read-Metadata $original.FullName
        $metaPrepared = Read-Metadata $prepared.FullName
        $cmp = Compare-Metadata $metaOriginal $metaPrepared

        if ($Repair -and ($RepairExtensions -contains $prepared.Extension.ToLowerInvariant()) -and $cmp.Status -ne "OK") {
            Copy-MetadataBack -OriginalFile $original.FullName -PreparedFile $prepared.FullName | Out-Null
            $metaPrepared2 = Read-Metadata $prepared.FullName
            $cmp = Compare-Metadata $metaOriginal $metaPrepared2
            $action = "Metadaten aus Original zurückkopiert und erneut geprüft"
        } elseif ($Repair -and -not ($RepairExtensions -contains $prepared.Extension.ToLowerInvariant())) {
            $action = "Reparatur übersprungen: Metadaten-Kopie wird in v1.1.0 nur für JPG/JPEG ausgeführt"
        }

        $rows.Add([pscustomobject]@{
            PreparedFile = $prepared.FullName
            OriginalFile = $original.FullName
            Status = $cmp.Status
            Score = $cmp.Score
            CriticalText = DiffListToText $cmp.Critical
            WarningText = DiffListToText $cmp.Warnings
            Action = $action
        })
    } catch {
        $rows.Add([pscustomobject]@{
            PreparedFile = $prepared.FullName
            OriginalFile = $original.FullName
            Status = "FEHLER"
            Score = 0
            CriticalText = $_.Exception.Message
            WarningText = ""
            Action = "Fehler beim Lesen/Reparieren"
        })
    }
}
Write-Progress -Activity "Metadaten pruefen" -Completed

$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$jsonPath = Join-Path $OutputDir "metadaten-report-$stamp.json"
$csvPath = Join-Path $OutputDir "metadaten-report-$stamp.csv"
$htmlPath = Join-Path $OutputDir "metadaten-report-$stamp.html"

# v1.1.0: Die interne Generic-List wird vor Export/HTML in ein echtes PowerShell-Array umgewandelt.
# Grund: In Windows PowerShell kann eine Generic-List bei Funktionsparametern/HTML-Erzeugung
# als falscher Objekttyp gebunden werden. Das verursachte in v1.0.5:
# "Die Argumenttypen stimmen nicht überein."
$rowsArray = @()
foreach ($row in $rows) { $rowsArray += $row }

$rowsArray | ConvertTo-Json -Depth 8 | Set-Content -Path $jsonPath -Encoding UTF8
$rowsArray | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8 -Delimiter ";"
New-HtmlReport -Rows $rowsArray -Path $htmlPath -OriginalDir $OriginalDir -PreparedDir $preparedSourceText -RepairMode ([bool]$Repair)

Write-Step "Berichte erstellt:" "Green"
Write-Host "  HTML: $htmlPath" -ForegroundColor White
Write-Host "  CSV : $csvPath" -ForegroundColor White
Write-Host "  JSON: $jsonPath" -ForegroundColor White

$okCount = @($rowsArray | Where-Object Status -eq "OK").Count
$warnCount = @($rowsArray | Where-Object Status -eq "WARNUNG").Count
$errCount = @($rowsArray | Where-Object Status -eq "FEHLER").Count
$missingCount = @($rowsArray | Where-Object Status -eq "ORIGINAL_FEHLT").Count

Write-Host ""
Write-Host "Ergebnis: OK=$okCount | Warnung=$warnCount | Fehler=$errCount | Original fehlt=$missingCount" -ForegroundColor Cyan

if ($OpenReport) {
    Start-Process $htmlPath
}

# v1.1.0: Prüfergebnis-Fehler sind kein technischer Programmfehler.
# Der SpeedCommander-Starter soll die Logdatei nur bei echten Script-/PowerShell-Fehlern öffnen.
# FEHLER / ORIGINAL_FEHLT / WARNUNG stehen im HTML/CSV/JSON-Bericht, aber das Script beendet normal mit 0.
exit 0
