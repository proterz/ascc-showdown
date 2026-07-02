#Requires AutoHotkey v2.0
#SingleInstance Force

global TargetMonitor := 1 ; Set to 1 for Primary Monitor, 2 for Secondary, etc...
global LevelToStop := 5
global CurrentLevel := 0
global CurrentLevel2 := 0
global IsFarming := false
global goalReached := false

CoordMode("Mouse", "Client")
CoordMode("Pixel", "Client")
CoordMode("ToolTip", "Screen")
DllCall("SetThreadDpiAwarenessContext", "ptr", -4)

; === GUI FUNCTIONS ===
StartClicked(*) {
    global LevelToStop, IsFarming
    
    inputValue := EditLevelToStopTextbox.Value
    if (inputValue == "") {
        MsgBox("Please enter a valid Level to stop!")
        return
    }
    LevelToStop := Integer(inputValue) + 1
    
    StartButton.Enabled := false
    StartButton.Text := "Running..."
    TextStatus.Text := "Status: Starting..."
    IsFarming := true
    
    if !FocusRoblox() {
        ResetGUI()
        return
    }
    
    ExecuteFarmCycle()
}

ResetGUI() {
    global IsFarming
    IsFarming := false
    StartButton.Enabled := true
    StartButton.Text := "&Start"
    TextStatus.Text := "Status: Idle"
    ToolTip() ; clears any tooltip
    Highlight() ; This cleans up the red box off your screen
}

; === UTILITY FUNCTIONS ===
Highlight(x?, y?, w?, h?, showTime:=0, color:="Red", d:=2) {
    static guis := []

    if !IsSet(x) {
        for _, r in guis
            r.Destroy()
        guis := []
        return
    }
    if !guis.Length {
        Loop 4
            guis.Push(Gui("+AlwaysOnTop -Caption +ToolWindow -DPIScale +E0x08000000"))
    }
    Loop 4 {
        i:=A_Index
        , x1:=(i=2 ? x+w : x-d)
        , y1:=(i=3 ? y+h : y-d)
        , w1:=(i=1 or i=3 ? w+2*d : d)
        , h1:=(i=2 or i=4 ? h+2*d : d)
        guis[i].BackColor := color
        guis[i].Show("NA x" . x1 . " y" . y1 . " w" . w1 . " h" . h1)
    }
    if showTime > 0 {
        Sleep(showTime)
        Highlight()
    } else if showTime < 0
        SetTimer(Highlight, -Abs(showTime))
} ; for highlighting where OCR is scanning

StatusSleep(timeMs, statusText) {
    global TextStatus
    endTime := A_TickCount + timeMs
    
    while (A_TickCount < endTime) {
        ; Universal check!
        if (CheckIfDisconnected()) {
            HandleDisconnect()
        }
        
        timeLeft := Round((endTime - A_TickCount) / 1000, 1)
        TextStatus.Text := statusText . " (" . timeLeft . "s)"
        Sleep(100) 
    }
    TextStatus.Text := statusText 
} ; just to show countdowns of sleep function if ever they are longer than 2000ms ?

; === INCLUDES ===
#include lib\OCR.ahk ; OCR library, shoutout Descolada on github
#include core\failsafes.ahk ; UI checks, disconnect procedures
#include core\navigation.ahk ; clicks, movement, window sizing
#include core\showdown.ahk ; loading cards, farm loops
#include gui\interface.ahk ; GUI

; === HOTKEYS ===
Insert:: {
    global IsFarming
    if (IsFarming) {
        ResetGUI()
    }
} ; stops farming

End::ExitApp ; forcefully closes app

; ^t:: {
;     if CheckLoadCardsUI() {
;         MsgBox("Found!")
;     } else {
;         MsgBox("Not found")
;     }
; }
; this is just for testing image search, dont mind it

Home::Pause(-1) ; actually pausing the whole process, as if time has stopped