#Requires AutoHotkey v2.0
#SingleInstance Force
ListLines(0)

global MainScriptName := "ascc main.ahk"
global MaxStaleTime   := 45000 
global LastPulseTime  := A_TickCount
global RecoveryCount  := 0
global IsDebugVisible := false

; ==========================================================
; DEBUG GUI INITIALIZATION
; ==========================================================
HeartbeatGui := Gui("+AlwaysOnTop -MaximizeBox -MinimizeBox", "System Debugger")
HeartbeatGui.SetFont("s9", "Segoe UI")

HeartbeatGui.Add("Text", "x10 y10 w280", "TELEMETRY & PROCESS GUARD")
HeartbeatGui.Add("Text", "x10 y25 w280", "--------------------------------------------------")

global TxtStatus   := HeartbeatGui.Add("Text", "x10 y45 w280 cGreen", "Guard Status: STANDBY")
global TxtPulse    := HeartbeatGui.Add("Text", "x10 y65 w280", "Pulse Delay: 0 ms")
global TxtRecover  := HeartbeatGui.Add("Text", "x10 y85 w280", "Crash Recoveries: 0")

HeartbeatGui.Add("Text", "x10 y110 w280", "--------------------------------------------------")
global TxtState    := HeartbeatGui.Add("Text", "x10 y130 w280 cBlue", "Macro State: Awaiting data...")
global TxtFunction := HeartbeatGui.Add("Text", "x10 y150 w280", "Last Action: Awaiting data...")

MonitorGetWorkArea(1, &WorkLeft, &WorkTop, &WorkRight, &WorkBottom)
global GuiX := WorkRight - 320
global GuiY := WorkTop + 20

; Do NOT call .Show() here so it starts hidden!

; ==========================================================
; HOTKEY & TIMERS
; ==========================================================
F12:: {
    global IsDebugVisible, HeartbeatGui, GuiX, GuiY
    IsDebugVisible := !IsDebugVisible
    if (IsDebugVisible) {
        HeartbeatGui.Show("w300 h185 x" . GuiX . " y" . GuiY . " NoActivate")
    } else {
        HeartbeatGui.Hide()
    }
}

OnMessage(0x004A, InterceptMainPulse) 
SetTimer(UpdateGuiTimer, 100)
SetTimer(MonitorMainProcessHealth, 5000)

; ==========================================================
; CORE FUNCTIONS
; ==========================================================
InterceptMainPulse(wParam, lParam, msg, hwnd) {
    global LastPulseTime, TxtState, TxtFunction, TxtStatus
    LastPulseTime := A_TickCount
    
    ; Extract the payload string sent from ascc main.ahk
    StringAddress := NumGet(lParam, 2 * A_PtrSize, "UPtr")
    payload := StrGet(StringAddress)
    
    ; Parse the data (Format expected: "State|Function")
    dataParts := StrSplit(payload, "|")
    
    if (dataParts.Length >= 1)
        TxtState.Text := "Macro State: " . dataParts[1]
    if (dataParts.Length >= 2)
        TxtFunction.Text := "Last Action: " . dataParts[2]
        
    return 1
}

UpdateGuiTimer() {
    global LastPulseTime, MaxStaleTime, TxtStatus, TxtPulse
    
    timeSinceLastPulse := A_TickCount - LastPulseTime
    TxtPulse.Text := "Pulse Delay: " . timeSinceLastPulse . " ms"
    
    if (timeSinceLastPulse > 15000 && timeSinceLastPulse <= MaxStaleTime) {
        TxtStatus.Text := "Guard Status: WARNING - HUNG THREAD"
        TxtStatus.SetFont("cFF8C00") 
    } else if (timeSinceLastPulse <= 15000) {
        TxtStatus.Text := "Guard Status: ONLINE & HEALTHY"
        TxtStatus.SetFont("cGreen")
    }
}

MonitorMainProcessHealth() {
    global LastPulseTime, MaxStaleTime, MainScriptName, TxtStatus, TxtFunction, RecoveryCount, TxtRecover
    
    timeSinceLastPulse := A_TickCount - LastPulseTime
    if (timeSinceLastPulse > MaxStaleTime) {
        SetTimer(UpdateGuiTimer, 0)
        
        TxtStatus.Text := "Guard Status: CRASH DETECTED!"
        TxtStatus.SetFont("cRed bold")
        TxtFunction.Text := "Last Action: EXECUTING HARD RECOVERY"
        
        RecoveryCount++
        TxtRecover.Text := "Crash Recoveries: " . RecoveryCount
        
        DetectHiddenWindows(true)
        targetScriptHwnd := MainScriptName . " ahk_class AutoHotkey"
        if WinExist(targetScriptHwnd) {
            ; Extract the unique Process ID (PID) for the main script
            targetPID := WinGetPID(targetScriptHwnd)
            
            ; Force kill only that specific PID, leaving the heartbeat untouched
            if (targetPID) {
                ProcessClose(targetPID)
                Sleep(1000)
            }
        }
        
        if ProcessExist("RobloxPlayerBeta.exe") {
            ProcessClose("RobloxPlayerBeta.exe")
            Sleep(2000)
        }
        
        if FileExist(A_ScriptDir "\" . MainScriptName) {
            Run('"' . A_AhkPath . '" "' . A_ScriptDir "\" . MainScriptName . '" /recovery')
            Sleep(5000)
        }
        
        LastPulseTime := A_TickCount
        SetTimer(UpdateGuiTimer, 100)
    }
}