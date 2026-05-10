@mbuege

vielen Dank für deinen Erfahrungsbericht und die Arbeit an der Wiki-Seite. Gerade praktische Hinweise zu Ausrüstung, Befestigungen, Aufnahmeabständen und typischen Fehlerquellen sind für Panoramax sehr hilfreich.

Ich habe ergänzend ein kleines Tool erstellt:

https://gabischatz.de.cool/FotoGeoTool/index.html

Das FotoGeoTool soll Bilder und kurze Videosequenzen für den Panoramax-Upload vorbereiten. Hintergrund ist, dass viele Apps und Messenger – zum Beispiel WhatsApp – Metadaten wie GPS-Informationen, Zeitstempel oder andere EXIF-Daten entfernen oder verändern. Für Panoramax sind diese Informationen aber sehr wichtig.

Zusätzlich habe ich dafür ein kleines Prüfwerkzeug erstellt:

**FotoGeoCheck**

FotoGeoCheck prüft vorbereitete Bilder und kurze Videos darauf, ob wichtige Metadaten wie GPSLatitude, GPSLongitude, DateTimeOriginal und CreateDate vorhanden sind. Es kann außerdem vorbereitete Dateien mit passenden Originalbildern vergleichen.

Als technischen Hinweis für die Entwicklung habe ich mir die Datei `sli-guardian.ps1` angesehen. Diese Datei war für mich kein fertiger Panoramax-Uploader, sondern ein Hinweis auf die Methode:

```text
Originalbild behalten
→ Bild bearbeiten oder vorbereiten
→ Metadaten mit ExifTool aus dem Original zurück in die bearbeitete Datei kopieren
→ Ergebnis erneut prüfen
```

Genau dieser Punkt ist für Panoramax wichtig, weil bei der Bearbeitung oder beim Versand über Messenger häufig GPS-, Zeit- und EXIF-/XMP-Daten verloren gehen.

Wichtig: Der letzte Schritt funktioniert derzeit noch nicht. Die vom FotoGeoTool vorbereiteten Bilder werden von Panoramax aktuell noch nicht akzeptiert. Die genaue Ursache ist mir im Moment noch nicht bekannt.

Ich habe den Ersteller bzw. Ansprechpartner von Panoramax dazu bereits per E-Mail kontaktiert, bisher aber noch keine Antwort erhalten.

Das Tool ist deshalb momentan vor allem als Prüf- und Vorbereitungshilfe gedacht. Für einen vollständigen Panoramax-Workflow muss noch geklärt werden, warum Panoramax die vorbereiteten Bilder nicht annimmt und welche technischen Anforderungen dafür genau erfüllt sein müssen.

Vielleicht wäre ein Hinweis auf solche vorbereitenden Werkzeuge in der Wiki-Seite sinnvoll, zum Beispiel in einem Abschnitt „Vorbereitung der Bilder“ oder „Prüfung von Metadaten vor dem Upload“.

Das Tool ist noch in Entwicklung. Rückmeldungen, Tests und Verbesserungsvorschläge sind willkommen.
