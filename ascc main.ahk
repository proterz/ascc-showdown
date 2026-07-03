#Requires AutoHotkey v2.0
#SingleInstance Force

; === LIBRARIES AND DEPENDENCIES ===
#include core\config.ahk ; config handler to save macro settings
#include lib\OCR.ahk ; OCR library, shoutout Descolada on github
#include lib\Gdip_All.ahk
#include lib\Gdip_ImageSearch.ahk
#include assets\imagesearch\base64images.ahk ; ui image assets as base64 string

; === INCLUDES ===
#include core\failsafes.ahk ; UI checks, disconnect procedures
#include core\navigation.ahk ; clicks, movement, window sizing
#include core\showdown.ahk ; loading cards, farm loops
#include gui\interface.ahk ; GUI

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

; === GLOBAL VARIABLES ===
global TargetMonitor := 2 ; Set to 1 for Primary Monitor, 2 for Secondary, etc...
global LevelToStop := 5
global CurrentLevel := 0
global CurrentLevel2 := 0 ; for potions part (to be developed in the future)
global IsFarming := false
global MACRO_STATE := "IDLE" ; IDLE, PREPARATION (setting window size, going to showdown area, etc), LOADING_CARDS, FARM_LOOP, CLAIMING, RECONNECTING
global CURRENT_ACTION := "Awaiting start..." ; this is just for tracking the macro for debugging purposes

global IsRecoveryMode := false
global IsManualShutdown := false ; set when the user intentionally closes the macro
if (A_Args.Length > 0 && A_Args[1] == "/recovery") {
    IsRecoveryMode := true
}

CoordMode("Mouse", "Client")
CoordMode("Pixel", "Client")
CoordMode("ToolTip", "Screen")
DllCall("SetThreadDpiAwarenessContext", "ptr", -4)

; === GDI+ STUFF ===
global pToken := Gdip_Startup()
if (!pToken) {
    MsgBox("GDI+ failed to start! The macro cannot run.")
    ExitApp()
}

OnExit(ExitFunc)
OnExit(ExitFunc)
ExitFunc(*) {
    global pToken

    DetectHiddenWindows(true)
    
    targetGuardHwnd := "heartbeat.ahk ahk_class AutoHotkey"
    if WinExist(targetGuardHwnd) {
        WinClose(targetGuardHwnd)
    } 

    Gdip_Shutdown(pToken)
    ExitApp()
}

; === HEARTBEAT LAUNCHER ===
if !WinExist("heartbeat.ahk") {
    if FileExist(A_ScriptDir "\heartbeat.ahk") {
        Run('"' . A_AhkPath . '" "' . A_ScriptDir '\heartbeat.ahk"')
    }
} ; if heartbeat.ahk isn't open, run it

SetTimer(SendHeartbeatPulse, 10000) ; send pulse every 10 seconds

CreateGUI()
return ; THE WALL

; === UTILITY FUNCTIONS ===
SendHeartbeatPulse() {
    global MACRO_STATE, CURRENT_ACTION
    DetectHiddenWindows(true)
    if (targetHwnd := WinExist("heartbeat.ahk")) {
        dataString := MACRO_STATE . "|" . CURRENT_ACTION
        cds := Buffer(A_PtrSize * 3, 0)
        NumPut("UPtr", 1, cds, 0)
        NumPut("UInt", (StrLen(dataString) + 1) * 2, cds, A_PtrSize)
        NumPut("UPtr", StrPtr(dataString), cds, A_PtrSize * 2)

        DllCall("SendMessage", "Ptr", targetHwnd, "UInt", 0x004A, "Ptr", A_ScriptHwnd, "Ptr", cds.Ptr)
    }
} ; tells heartbeat.ahk that the macro is alive and working fine

DebugLog(actionString) {
    global CURRENT_ACTION := actionString
    SendHeartbeatPulse() ; Force an immediate pulse so the UI updates instantly
}

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

; === State Manager Engine ===
PerformMacroState() {
    global MACRO_STATE, IsFarming, LevelToStop

    while (IsFarming) {
        try {
            switch MACRO_STATE {
                case "PREPARATION":
                    ; if !ProcessExist("RobloxPlayerBeta.exe") {
                    ;     LaunchASCCviaDeeplink()
                    ; } ; if game down, open ASCC via Deeplink (roblox://placeId=109715918987082)

                    if !WinExist("ahk_exe RobloxPlayerBeta.exe") {
                        DebugLog("No game window found. Triggering Deeplink...")
                        
                        ; If the launcher fails or times out, restart the loop from the top
                        if !LaunchASCCviaDeeplink() {
                            Sleep(2000)
                            continue 
                        }
                    }

                    if WinWait("ahk_exe RobloxPlayerBeta.exe",, 15) {
                        DebugLog("Focusing and Resizing...")
                        FocusRoblox()
                        SetWindowSize()
                        Sleep(500)
                    } else {
                        DebugLog("Window failed to appear after launch.")
                        continue ; Restart the loop
                    }

                    FocusRoblox()
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

; === HOTKEYS ===
Insert:: {
    global IsFarming, MACRO_STATE
    if (IsFarming) {
        IsFarming := false
        MACRO_STATE := "IDLE"
        MacroEventManager.Broadcast("FarmingStopped")
    }
} ; stops farming

End:: {
    global IsManualShutdown
    IsManualShutdown := true
    ExitApp
}

Home::Pause(-1) ; actually pausing the whole process, as if time has stopped

; ^t:: {
;     if CheckShowdownUI() {
;         MsgBox("Found!")
;     } else {
;         MsgBox("Not found")
;     }
; }
; this is just for testing image search, dont mind it

^F12:: {
    MsgBox("Main script thread is now locked! Click OK to unfreeze, or wait 45 seconds to let the Heartbeat kill this process.")
    Loop {
        Sleep(1000) ; This loop will block the script from doing anything else permenantly
    }
}