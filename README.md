# FotoGeoCheck v1.1.0

FotoGeoCheck prüft Bilder und kurze Videos für die Vorbereitung von Panoramax. Das Werkzeug ist als Zusatzhilfe für das FotoGeoTool gedacht.

Es erkennt typische Probleme, die nach WhatsApp, Bildbearbeitung oder Konvertierung auftreten können:

- fehlende GPS-Koordinaten
- fehlende Originalzeit
- fehlende oder abweichende EXIF-/XMP-Metadaten
- fehlendes passendes Originalbild
- problematische vorbereitete Dateien

## Name

Der lange Arbeitsname `FotoGeoTool-MetadatenPruefer` wurde ab Version 1.1.0 gekürzt auf:

```text
FotoGeoCheck
```

Die Hauptdatei heißt jetzt:

```text
FotoGeoCheck.ps1
```

## Fester Zielordner

Installiere das Paket mit:

```text
INSTALLIEREN_ODER_AKTUALISIEREN.bat
```

Der feste Zielordner ist:

```text
%USERPROFILE%\fotogeocheck
```

Bei Lutz also normalerweise:

```text
C:\Users\lugm\fotogeocheck
```

## ExifTool

ExifTool wird nicht automatisch heruntergeladen. Die Datei muss hier liegen:

```text
tools\exiftool.exe
```

Falls die heruntergeladene Datei `exiftool(-k).exe` heißt, benenne sie um in:

```text
exiftool.exe
```

## Ordner

```text
original   = Originalbilder / Originalvideos
prepared   = vorbereitete Dateien, falls keine SpeedCommander-Auswahl übergeben wird
reports    = HTML-, CSV- und JSON-Berichte
tools      = exiftool.exe
```

## Start ohne SpeedCommander

Prüfen:

```text
Start-Pruefung.bat
```

Reparaturmodus für JPG/JPEG:

```text
Start-Reparatur.bat
```

Im Reparaturmodus werden Metadaten aus dem passenden Originalbild in die vorbereitete JPG/JPEG-Datei zurückkopiert.

## SpeedCommander

Als Starter verwenden:

```text
SpeedCommander-FotoGeoCheck-Starter.vbs
```

Wenn im SpeedCommander eine oder mehrere Dateien markiert sind, werden genau diese Dateien geprüft.

Wenn keine passende Datei markiert ist, wird der Ordner `prepared` geprüft.

Unterstützt werden aktuell:

```text
.jpg
.jpeg
.mp4
.mov
```

## Berichte

Nach der Prüfung wird ein HTML-Bericht im Ordner `reports` erstellt und geöffnet.

Ab Version 1.1.0 enthält die HTML-Ausgabe deutsche Umlaute, zum Beispiel:

```text
Prüfbericht
für Panoramax
geprüft
ausgeführt
möglich
zurückkopiert
```

## Technische Logdatei

Fachliche Prüfergebnisse wie fehlende GPS-Daten oder `ORIGINAL_FEHLT` öffnen keine technische Logdatei.

Die Logdatei wird nur bei einem echten Script- oder PowerShell-Fehler geöffnet.

## Hintergrund zu sli-guardian.ps1

Die Datei `sli-guardian.ps1` war für FotoGeoCheck kein fertiger Panoramax-Uploader. Sie diente als technischer Hinweis für die Methode:

```text
Originalbild behalten
→ bearbeitete Datei erzeugen
→ Metadaten mit ExifTool aus dem Original zurückkopieren
→ Ergebnis erneut prüfen
```

Dieser Ablauf ist für Panoramax wichtig, weil Messenger und Bildbearbeitungen häufig GPS-, Zeit- und EXIF-/XMP-Daten entfernen.

## Version 1.1.0

- Name gekürzt auf `FotoGeoCheck`.
- Hauptdatei heißt jetzt `FotoGeoCheck.ps1`.
- Fester Zielordner ist jetzt `%USERPROFILE%\fotogeocheck`.
- HTML-Bericht mit Umlauten überarbeitet.
- Anzeige der SpeedCommander-Auswahl im HTML-Bericht verbessert.
- GitHub-README und Forumsbeitrag als Markdown ergänzt.
