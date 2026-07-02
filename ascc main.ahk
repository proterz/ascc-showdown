#Requires AutoHotkey v2.0
#SingleInstance Force

global TargetMonitor := 1 ; Set to 1 for Primary Monitor, 2 for Secondary, etc...
global LevelToStop := 5
global CurrentLevel := 0
global CurrentLevel2 := 0 ; for potions part (to be developed in the future)
global goalReached := false

global MACRO_STATE := "IDLE" ; IDLE, PREPARATION (setting window size, going to showdown area, etc), LOADING_CARDS, FARM_LOOP, CLAIMING, RECONNECTING

CoordMode("Mouse", "Client")
CoordMode("Pixel", "Client")
CoordMode("ToolTip", "Screen")
DllCall("SetThreadDpiAwarenessContext", "ptr", -4)

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

; === Event Manager Class ===
class MacroEventManager {
    static listeners := Map() ; make listeners a dictionary

    static Listen(eventName, callback) {
        if !this.listeners.Has(eventName)
            this.listeners[eventName] := []

        this.listeners[eventName].Push(callback)
    } ; if there's no such eventName yet, make one, then insert the function (callback) into its value

    static Broadcast(eventName, data*) {
        if this.listeners.Has(eventName) {
            for callback in this.listeners[eventName]
                callback(data*)
        }
    } ; if the eventName exists, insert whatever's in data* into the function's parameter and execute it, do this for every function assigned to this event
}

; === State Manager Engine ===
PerformMacroState() {
    global MACRO_STATE, IsFarming, LevelToStop

    while (IsFarming) {
        try {
            switch MACRO_STATE {
                case "PREPARATION":
                    SetWindowSize()
                    Sleep(500)

                    if (!CheckLoadCardsUI() && !CheckShowdownUI()) {
                        TheSetup3()
                    }
                    
                    if (CheckShowdownUI()) {
                        EndRunEarly()
                    }

                    MACRO_STATE := "LOADING_CARDS"
                
                case "LOADING_CARDS": 
                    MacroEventManager.Broadcast("StatusTextUpdated", "Loading cards...")
                    LoadCards()
                    CustomClick(879, 530)
                    Sleep(500)
                    MACRO_STATE := "FARM_LOOP"
                
                case "FARM_LOOP":
                    RunFarmLoop()

                case "CLAIMING": 
                    ClaimRewards()
            }
        } catch Error as err {
            if (err.Message == "GameReconnected") {
                MACRO_STATE := "PREPARATION"
                continue
            } else {
                throw err
            }
        }
        Sleep(50)
    }
    MacroEventManager.Broadcast("FarmingStopped")
}

; === INCLUDES ===
#include lib\OCR.ahk ; OCR library, shoutout Descolada on github
#include core\failsafes.ahk ; UI checks, disconnect procedures
#include core\navigation.ahk ; clicks, movement, window sizing
#include core\showdown.ahk ; loading cards, farm loops
#include gui\interface.ahk ; GUI

; === HOTKEYS ===
Insert:: {
    global IsFarming, MACRO_STATE
    if (IsFarming) {
        IsFarming := false
        MACRO_STATE := "IDLE"
        MacroEventManager.Broadcast("FarmingStopped")
    }
} ; stops farming

End::ExitApp ; forcefully closes app
Home::Pause(-1) ; actually pausing the whole process, as if time has stopped

; ^t:: {
;     if CheckLoadCardsUI() {
;         MsgBox("Found!")
;     } else {
;         MsgBox("Not found")
;     }
; }
; this is just for testing image search, dont mind it