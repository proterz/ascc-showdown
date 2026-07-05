#Requires AutoHotkey v2.0

global IniFilePath := A_ScriptDir "\config.ini"

; config loader, places default values if no config file yet
LoadMacroConfig() {
    global IniFilePath
    
    settings := Map()
    settings["LevelToStop"] := IniRead(IniFilePath, "Settings", "LevelToStop", "5")
    settings["CheckboxRepeat"] := IniRead(IniFilePath, "Settings", "CheckboxRepeat", "1")
    settings["StopMode"] := IniRead(IniFilePath, "Settings", "StopMode", "Automatic")
    
    return settings
}

; config saver to file
SaveMacroConfig(level, repeatValue, stopMode := "Automatic") {
    global IniFilePath
    
    IniWrite(level, IniFilePath, "Settings", "LevelToStop")
    IniWrite(repeatValue, IniFilePath, "Settings", "CheckboxRepeat")
    IniWrite(stopMode, IniFilePath, "Settings", "StopMode")
}

; === LOAD CARD CALIBRATION ===
global CalibrationTooltipText := ""
global IsCalibrating := false
CustomizeCardLoading(*) {
    global MacroState := "IDLE"

    MsgBox("Load Card Calibration has started! Press Escape if you want to abort.")

    targetWindow := "ahk_exe RobloxPlayerBeta.exe" 
    if !WinExist(targetWindow) {
        MsgBox("Roblox not found. Please launch the game first!")
        return
    }
    WinActivate(targetWindow)
    WinWaitActive(targetWindow)
    Sleep(200)
    if (!CheckLoadCardsUI()) {
        MsgBox("Please go to the Showdown Area and open the Load Cards UI first.")
        return
    }

    CoordMode("Mouse", "Client")
    targetWindow := "ahk_exe RobloxPlayerBeta.exe"
    if !WinExist(targetWindow) {
        MsgBox("Roblox client not found. Please launch the game first!")
        return
    }
    WinActivate(targetWindow)
    WinWaitActive(targetWindow)

    global IsCalibrating := true
    ; bind escape to abort calibration
    Hotkey("Escape", AbortCalibration, "On")

    ; show tooltip every 10 ms
    SetTimer(TrackCursorTooltip, 10)

    ; STEP 1: Strong Card
    global CalibrationTooltipText := "STEP 1: Click the 1st card (Strong Card)`n[Press ESC to abort]"
    if !WaitClick(&strongX, &strongY)
        return

    ; STEP 2: Scroll Counter
    global scrollCount := 0
    
    ; bind scrollwheels
    Hotkey("~WheelDown", CountScrollDown, "On")
    Hotkey("~WheelUp", CountScrollUp, "On")
    
    ; wait for Enter to be pressed
    while IsCalibrating && !GetKeyState("Enter", "P") {
        ; update the tooltip with the scroll count in real time
        global CalibrationTooltipText := "STEP 2: Scroll to weak cards.`nCurrent Scrolls: " . scrollCount . "`nPress ENTER when finished.`n[Press ESC to abort]"
        Sleep(50)
    }
    
    ; unbind scrollwheels
    try Hotkey("~WheelDown", "Off")
    try Hotkey("~WheelUp", "Off")
    
    if !IsCalibrating ; if user pressed escape
        return
        
    KeyWait("Enter", "U") ; wait for Enter key to unbind
    Sleep(200)

    ; STEP 3: Weak Card 1
    global CalibrationTooltipText := "STEP 3: Click WEAK Card 1`n[Press ESC to abort]"
    if !WaitClick(&w1X, &w1Y)
        return

    ; STEP 4: Weak Card 2
    global CalibrationTooltipText := "STEP 4: Click WEAK Card 2`n[Press ESC to abort]"
    if !WaitClick(&w2X, &w2Y)
        return

    EndCalibration()
    IniWrite(strongX, "config.ini", "LoadCards", "StrongX")
    IniWrite(strongY, "config.ini", "LoadCards", "StrongY")
    IniWrite(scrollCount, "config.ini", "LoadCards", "ScrollAmount")
    IniWrite(w1X, "config.ini", "LoadCards", "Weak1X")
    IniWrite(w1Y, "config.ini", "LoadCards", "Weak1Y")
    IniWrite(w2X, "config.ini", "LoadCards", "Weak2X")
    IniWrite(w2Y, "config.ini", "LoadCards", "Weak2Y")

    MsgBox("Card coordinates and scroll amount (" . scrollCount . ") successfully saved!", "ASCC Setup", 64)
}

; constant tooltip
TrackCursorTooltip() {
    CoordMode("Mouse", "Screen")
    CoordMode("ToolTip", "Screen")
    MouseGetPos(&mX, &mY)
    ToolTip(CalibrationTooltipText, mX + 15, mY + 15)
}

; Custom Wait function that allows us to break out if Escape is pressed
WaitClick(&outX, &outY) {
    global IsCalibrating
    
    ; wait for click down
    while IsCalibrating && !GetKeyState("LButton", "P") {
        Sleep(10)
    }
    if !IsCalibrating
        return false
        
    ; capture mouse pos
    CoordMode("Mouse", "Client") 
    MouseGetPos(&outX, &outY)
    
    ; wait for click up
    while IsCalibrating && GetKeyState("LButton", "P") {
        Sleep(10)
    }
    Sleep(200)
    return true
}

CountScrollDown(*) {
    global scrollCount
    scrollCount++
}

CountScrollUp(*) {
    global scrollCount
    if (scrollCount > 0) {
        scrollCount--
    }
}

AbortCalibration(*) {
    global IsCalibrating := false
    EndCalibration()
    MsgBox("Load Card Calibration aborted.")
}

EndCalibration() {
    SetTimer(TrackCursorTooltip, 0)
    ToolTip()
    try Hotkey("Escape", "Off")
    try Hotkey("~WheelDown", "Off")
}