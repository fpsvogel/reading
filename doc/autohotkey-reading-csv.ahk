; AutoHotkey helper script for reading.csv
; Provides two keyboard macros:
; - Today's date (ctrl + \ below)
; - Create a row (alt b below)
; You will probably want to customize the hotkeys.
; See https://www.autohotkey.com/docs/Hotkeys.htm

; Today's date
!\::
  SendInput %A_YYYY%/%A_MM%/%A_DD%
  Sleep 50
  ReleaseAlt()
return

; Create a row
; Uses the text in the current line (if any) as the Head and Sources columns.
; The head (title) can optionally be followed by a pipe character and then a Sources column.
; If a comment character (\) starts the line, delete it.
!b::
  oCB := ClipboardAll
  Clipboard := ""
  Send ^x
  Sleep 50
  beforeText = |
  afterText = |%A_YYYY%/%A_MM%/%A_DD%| ||0
  Clipboard := A_Space . beforeText . Trim(Clipboard, "`r`n\ ") . (InStr(Clipboard, "|") ? "" : "| ") . afterText . "`r`n"
  Send ^v
  Sleep 100
  Clipboard := oCB
  Sleep 200
  Send {Ctrl Up}{Shift Up}
  Send {Left 3}  ; move cursor to the Genres column
  Sleep 50
  ReleaseAlt()
return
