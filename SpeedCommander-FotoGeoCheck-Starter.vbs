'Beginn von (Deklarationen)
' *******************************************************************
' SpeedCommander FotoGeoCheck Starter v1.1.0
'
' Zweck:
'   - Startet FotoGeoCheck.ps1 aus einem festen Tool-Ordner.
'   - Standardordner: %USERPROFILE%\fotogeocheck
'   - Dadurch ist der Starter nicht mehr davon abhängig,
'     welcher Ordner gerade im SpeedCommander geöffnet ist.
'   - Übergibt markierte Dateien an den Prüfer.
'   - Wenn Dateien markiert sind, werden genau diese Dateien geprüft.
'   - Der vorbereitete Ordner wird nur genutzt, wenn keine passenden Dateien markiert sind.
'   - Schreibt ein Startlog nach %TEMP%\fotogeocheck_starter_last_run.log.
'
' Wichtig:
'   - Den ZIP-Inhalt bitte nach %USERPROFILE%\fotogeocheck entpacken.
'   - Also z.B.: C:\Users\DEINNAME\fotogeocheck\FotoGeoCheck.ps1
' *******************************************************************
Option Explicit

Const START_MODE = 1 ' 1 = versteckt, 2 = Diagnose sichtbar
Const TOOL_FOLDER = "%USERPROFILE%\fotogeocheck"
Const PS1_FILE = "FotoGeoCheck.ps1"
Const REQUIRED_PS1_VERSION = "1.1.0"

Dim wshShell
Set wshShell = CreateObject("WScript.Shell")

Private Function CleanArg(ByVal s)
    If IsNull(s) Then s = ""
    s = CStr(s)
    s = Replace(s, Chr(34), "")
    s = Trim(s)
    If Len(s) > 3 Then
        If Right(s, 1) = "\" Then s = Left(s, Len(s) - 1)
    End If
    CleanArg = s
End Function

Private Function QuoteArg(ByVal s)
    Dim qq: qq = Chr(34)
    s = CleanArg(s)
    s = Replace(s, qq, qq & qq)
    QuoteArg = qq & s & qq
End Function

Private Function FileExists(ByVal path)
    On Error Resume Next
    Dim fso
    Set fso = CreateObject("Scripting.FileSystemObject")
    FileExists = fso.FileExists(path)
    On Error GoTo 0
End Function

Private Function FolderExists(ByVal path)
    On Error Resume Next
    Dim fso
    Set fso = CreateObject("Scripting.FileSystemObject")
    FolderExists = fso.FolderExists(path)
    On Error GoTo 0
End Function

Private Sub EnsureFolder(ByVal path)
    On Error Resume Next
    Dim fso
    Set fso = CreateObject("Scripting.FileSystemObject")
    If Not fso.FolderExists(path) Then fso.CreateFolder(path)
    On Error GoTo 0
End Sub

Private Sub WriteLauncherLog(ByVal logPath, ByVal text)
    On Error Resume Next
    Dim fso, ts
    Set fso = CreateObject("Scripting.FileSystemObject")
    Set ts = fso.CreateTextFile(logPath, True, True)
    ts.Write text
    ts.Close
    On Error GoTo 0
End Sub

Private Function GetActiveFolder(ByVal activeWin)
    On Error Resume Next
    Dim p
    p = ""
    p = activeWin.Folder.Folder
    GetActiveFolder = CleanArg(p)
    Err.Clear
    On Error GoTo 0
End Function

Private Function GetSelectionList(ByVal activeWin)
    On Error Resume Next
    Dim item, s
    s = ""
    For Each item In activeWin.SelectedItems
        s = s & item.PathName & "|"
    Next
    If Len(s) > 0 Then s = Left(s, Len(s) - 1)
    GetSelectionList = s
    Err.Clear
    On Error GoTo 0
End Function

Private Function GetFocusedPath(ByVal activeWin)
    On Error Resume Next
    Dim p
    p = ""
    If activeWin.FocusedItem > 0 Then
        p = activeWin.Items.Item(activeWin.FocusedItem).PathName
    End If
    GetFocusedPath = p
    Err.Clear
    On Error GoTo 0
End Function


Private Function ReadTextFileUtf8OrDefault(ByVal path)
    On Error Resume Next
    Dim fso, ts, txt
    Set fso = CreateObject("Scripting.FileSystemObject")
    Set ts = fso.OpenTextFile(path, 1, False)
    txt = ts.ReadAll
    ts.Close
    ReadTextFileUtf8OrDefault = txt
    If Err.Number <> 0 Then
        Err.Clear
        ReadTextFileUtf8OrDefault = ""
    End If
    On Error GoTo 0
End Function

Private Function Ps1HasRequiredVersion(ByVal ps1Path, ByVal wantedVersion)
    Dim txt, needle1, needle2
    txt = ReadTextFileUtf8OrDefault(ps1Path)
    needle1 = "Version: " & wantedVersion
    needle2 = "$ScriptVersion = " & Chr(34) & wantedVersion & Chr(34)
    Ps1HasRequiredVersion = (InStr(1, txt, needle1, vbTextCompare) > 0) Or (InStr(1, txt, needle2, vbTextCompare) > 0)
End Function

Sub Main
    Dim shell, activeWin
    Dim toolFolder, ps1Path, originalDir, preparedDir, reportsDir, toolsDir
    Dim activePath, activeSel, activeFoc
    Dim logPath, psOutLogPath, cmdPs, exitCode, debugHeader, runStyle

    Set shell = CreateObject("WScript.Shell")
    toolFolder = CleanArg(shell.ExpandEnvironmentStrings(TOOL_FOLDER))
    ps1Path = toolFolder & "\" & PS1_FILE
    originalDir = toolFolder & "\original"
    preparedDir = toolFolder & "\prepared"
    reportsDir = toolFolder & "\reports"
    toolsDir = toolFolder & "\tools"
    logPath = shell.ExpandEnvironmentStrings("%TEMP%") & "\fotogeocheck_starter_last_run.log"
    psOutLogPath = shell.ExpandEnvironmentStrings("%TEMP%") & "\fotogeocheck_powershell_output.log"

    On Error Resume Next
    Set activeWin = Workspace.ActiveWindow.FolderWindows.Active
    If Err.Number <> 0 Then
        activePath = ""
        activeSel = ""
        activeFoc = ""
        Err.Clear
    Else
        activePath = GetActiveFolder(activeWin)
        activeSel = GetSelectionList(activeWin)
        activeFoc = GetFocusedPath(activeWin)
    End If
    On Error GoTo 0

    If Not FileExists(ps1Path) Then
        MsgBox "Die PS1-Datei wurde im festen Tool-Ordner nicht gefunden:" & vbCrLf & vbCrLf & _
               ps1Path & vbCrLf & vbCrLf & _
               "Bitte den ZIP-Inhalt genau hierhin entpacken:" & vbCrLf & _
               toolFolder & vbCrLf & vbCrLf & _
               "Die Datei muss danach so liegen:" & vbCrLf & _
               toolFolder & "\" & PS1_FILE, _
               vbCritical, "FotoGeoCheck Starter"
        Exit Sub
    End If


    If Not Ps1HasRequiredVersion(ps1Path, REQUIRED_PS1_VERSION) Then
        MsgBox "Die gefundene PS1-Datei ist NICHT die erwartete Version." & vbCrLf & vbCrLf & _
               "Erwartet: v" & REQUIRED_PS1_VERSION & vbCrLf & _
               "Gefunden/Pfad: " & ps1Path & vbCrLf & vbCrLf & _
               "Bitte die neue ZIP komplett nach diesem Ordner entpacken und vorhandene Dateien ersetzen:" & vbCrLf & _
               toolFolder & vbCrLf & vbCrLf & _
               "Wichtig: Der Ordner tools mit exiftool.exe darf bleiben.", _
               vbCritical, "FotoGeoCheck Starter - alte PS1 gefunden"
        Exit Sub
    End If

    EnsureFolder originalDir
    EnsureFolder preparedDir
    EnsureFolder reportsDir
    EnsureFolder toolsDir

    If START_MODE = 2 Then
        ' Diagnosemodus: PowerShell sichtbar, bleibt offen.
        runStyle = 1
        cmdPs = "powershell.exe -STA -NoProfile -ExecutionPolicy Bypass -NoExit -File " & QuoteArg(ps1Path) & _
                " -OriginalDir " & QuoteArg(originalDir) & _
                " -PreparedDir " & QuoteArg(preparedDir) & _
                " -OutputDir " & QuoteArg(reportsDir) & _
                " -ActivePath " & QuoteArg(activePath) & _
                " -ActiveSelection " & QuoteArg(activeSel) & _
                " -ActiveFocused " & QuoteArg(activeFoc) & _
                " -OpenReport"
    Else
        ' Produktivmodus: PowerShell versteckt.
        ' stdout/stderr werden in eine eigene PowerShell-Logdatei geschrieben.
        ' Die Logdatei wird NUR geöffnet, wenn PowerShell mit echtem technischem Fehler beendet.
        runStyle = 0
        cmdPs = "cmd.exe /C powershell.exe -STA -NoProfile -NonInteractive -ExecutionPolicy Bypass -File " & QuoteArg(ps1Path) & _
                " -OriginalDir " & QuoteArg(originalDir) & _
                " -PreparedDir " & QuoteArg(preparedDir) & _
                " -OutputDir " & QuoteArg(reportsDir) & _
                " -ActivePath " & QuoteArg(activePath) & _
                " -ActiveSelection " & QuoteArg(activeSel) & _
                " -ActiveFocused " & QuoteArg(activeFoc) & _
                " -OpenReport" & _
                " > " & QuoteArg(psOutLogPath) & " 2>&1"
    End If

    debugHeader = "SpeedCommander FotoGeoCheck Starter v1.1.0" & vbCrLf & _
                  "Zeit: " & Now & vbCrLf & _
                  "ToolFolder: " & toolFolder & vbCrLf & _
                  "PS1: " & ps1Path & vbCrLf & _
                  "OriginalDir: " & originalDir & vbCrLf & _
                  "PreparedDir: " & preparedDir & vbCrLf & _
                  "ReportsDir: " & reportsDir & vbCrLf & _
                  "PowerShellOutputLog: " & psOutLogPath & vbCrLf & _
                  "SpeedCommander ActivePath: " & activePath & vbCrLf & _
                  "SpeedCommander ActiveSelection: " & activeSel & vbCrLf & _
                  "SpeedCommander ActiveFocused: " & activeFoc & vbCrLf & _
                  "Befehl: " & cmdPs & vbCrLf & _
                  String(70, "-") & vbCrLf & vbCrLf

    WriteLauncherLog logPath, debugHeader

    If START_MODE = 2 Then
        MsgBox debugHeader, vbInformation, "FotoGeoCheck Starter Diagnose"
    End If

    exitCode = shell.Run(cmdPs, runStyle, True)

    If exitCode <> 0 Then
        MsgBox "PowerShell wurde mit einem technischen Fehler beendet. ExitCode: " & exitCode & "." & vbCrLf & vbCrLf & _
               "Die Logdateien werden jetzt geöffnet:" & vbCrLf & _
               logPath & vbCrLf & psOutLogPath, _
               vbExclamation, "FotoGeoCheck Starter"
        shell.Run "notepad.exe " & QuoteArg(logPath), 1, False
        shell.Run "notepad.exe " & QuoteArg(psOutLogPath), 1, False
    End If
End Sub

Main
'Ende von (Deklarationen)
