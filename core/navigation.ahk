#Requires AutoHotkey v2.0
global TargetMonitor, MACRO_STATE

FocusRoblox() {
    targetWindow := "ahk_exe RobloxPlayerBeta.exe"
    if !WinExist(targetWindow) {
        MsgBox("Roblox is not running!!!")
        return false
    }
    WinActivate(targetWindow)
    WinWaitActive(targetWindow, , 3)
    return true
} ; forcefully focuses on roblox

CustomClick(x, y) {
    targetWindow := "ahk_exe RobloxPlayerBeta.exe"
    
    if (WinGetID("A") != WinExist(targetWindow)) {
        WinActivate(targetWindow)
        WinWaitActive(targetWindow, , 1)
    }
    
    ; makes mouse cursor actually move instead of teleporting
    MouseMove(x, y, 2) 
    Sleep(50) 
    
    ; wiggle cursor to increase chances of clicking
    MouseMove(x + 1, y + 1, 1)
    Sleep(30)
    MouseMove(x, y, 1)
    Sleep(80)
    
    ; click
    Click("Left Down")
    Sleep(80) 
    Click("Left Up")
    
    Sleep(250) 
} ; jitters the mouse a bit to be able to click without failure

CustomRightClick(x, y) {
    targetWindow := "ahk_exe RobloxPlayerBeta.exe"
    
    if (WinGetID("A") != WinExist(targetWindow)) {
        WinActivate(targetWindow)
        WinWaitActive(targetWindow, , 1)
    }
    
    ; makes mouse cursor actually move instead of teleporting
    MouseMove(x, y, 2) 
    Sleep(50) 
    
    ; wiggle cursor to increase chances of clicking
    MouseMove(x + 1, y + 1, 1)
    Sleep(30)
    MouseMove(x, y, 1)
    Sleep(80)
    
    ; click
    Click("Right Down")
    Sleep(80) 
    Click("Right Up")
    
    Sleep(250) 
} ; same as the previous one but for right clicking

SetWindowSize() {
    targetWindow := "ahk_exe RobloxPlayerBeta.exe"
    global TargetMonitor 
    
    try {
        MonitorGetWorkArea(TargetMonitor, &Left, &Top, &Right, &Bottom)
    } catch {
        Left := 0
        Top := 0
    }
    
    WinMove(Left, Top, 1280, 720, targetWindow)
    Sleep(1000)
} ; resize roblox to 1280 x 720 then place them at topleft-most of the monitor

TheSetup3() {
    TextStatus.Text := "Status: Resetting..."
    MacroEventManager.Broadcast("StatusTextUpdated", "Resetting...")
    Send "{Escape}"
    Sleep(500)
    Send "R"
    Sleep(500)
    Send "{Enter}"
    StatusSleep(5500, "Status: Waiting for respawn to finish...")

    CustomClick(754, 475)
    Sleep(500)
    GoToShowdown2()
}

GoToShowdown2() {
    MacroEventManager.Broadcast("StatusTextUpdated", "Going to showdown...")
    CustomClick(804, 34)
    Sleep(500)
    
    Send "{s down}"
    while (!CheckLoadCardsUI() && !CheckShowdownUI()) {
        if (CheckIfDisconnected()) {
            Send "{s up}" ; Release the key first!
            HandleDisconnect()
        }
        Sleep(50)
    }
    Send "{s up}"
}