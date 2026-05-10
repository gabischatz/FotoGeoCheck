# FotoGeoCheck

FotoGeoCheck ist ein kleines Windows-/PowerShell-Werkzeug zur Prüfung von Bild- und Videometadaten für die Vorbereitung von Panoramax.

Es entstand als Ergänzung zum FotoGeoTool:

```text
https://gabischatz.de.cool/FotoGeoTool/index.html
```

## Zweck

Panoramax benötigt für hochgeladene Bilder saubere Metadaten, insbesondere GPS-Position und Zeitinformationen. Viele Messenger und Apps, zum Beispiel WhatsApp, entfernen oder verändern diese Daten.

FotoGeoCheck prüft deshalb vorbereitete Bilder und kurze Videos auf typische Probleme:

- GPSLatitude fehlt
- GPSLongitude fehlt
- DateTimeOriginal fehlt
- CreateDate fehlt
- passendes Originalbild fehlt
- Metadaten weichen vom Original ab

Das Werkzeug beweist nicht, dass eine Datei von Panoramax sicher akzeptiert wird. Es zeigt aber, ob typische Metadaten beim Bearbeiten, Konvertieren oder Weiterleiten verloren gegangen sind.

## Technischer Hintergrund

Die PowerShell-Datei `sli-guardian.ps1` aus dem TDEI-Tools-Projekt war ein technischer Hinweis für diesen Ansatz.

Dort wird sinngemäß folgender Arbeitsablauf genutzt:

```text
Originalbild nehmen
→ Kopie oder bearbeitete Version erzeugen
→ Metadaten mit ExifTool aus dem Original zurück in die bearbeitete Datei schreiben
```

FotoGeoCheck nutzt diesen Gedanken nicht als fertigen Upload-Prozess, sondern als Grundlage für die Metadatenprüfung und optional für die Reparatur von JPG/JPEG-Dateien.

## Voraussetzungen

Benötigt wird ExifTool für Windows.

ExifTool wird nicht automatisch heruntergeladen. Lege die Datei hier ab:

```text
tools\exiftool.exe
```

Falls die Datei `exiftool(-k).exe` heißt, muss sie in `exiftool.exe` umbenannt werden.

## Installation

ZIP entpacken und ausführen:

```text
INSTALLIEREN_ODER_AKTUALISIEREN.bat
```

Der feste Zielordner ist:

```text
%USERPROFILE%\fotogeocheck
```

## Nutzung

### Ohne SpeedCommander

Originale in den Ordner legen:

```text
original
```

Vorbereitete Dateien in den Ordner legen:

```text
prepared
```

Dann starten:

```text
Start-Pruefung.bat
```

### Mit SpeedCommander

Eine oder mehrere Dateien markieren und starten:

```text
SpeedCommander-FotoGeoCheck-Starter.vbs
```

Wenn Dateien markiert sind, werden genau diese Dateien geprüft.

## Reparaturmodus

Für JPG/JPEG-Dateien kann FotoGeoCheck Metadaten aus einem passenden Originalbild zurückkopieren:

```text
Start-Reparatur.bat
```

Der Reparaturmodus funktioniert nur sinnvoll, wenn im Ordner `original` ein passendes Originalbild mit gleichem Basisnamen vorhanden ist.

## Unterstützte Dateien

```text
.jpg
.jpeg
.mp4
.mov
```

Automatisches Zurückkopieren von Metadaten ist derzeit nur für JPG/JPEG vorgesehen.

## Berichte

FotoGeoCheck erzeugt im Ordner `reports`:

```text
HTML-Bericht
CSV-Bericht
JSON-Bericht
```

Der HTML-Bericht wird nach der Prüfung automatisch geöffnet.

## Status

FotoGeoCheck ist ein Hilfswerkzeug für die Vorbereitung und Prüfung. Es ist kein offizieller Panoramax-Uploader.
