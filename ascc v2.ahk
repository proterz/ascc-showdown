#Requires AutoHotkey v2.0
#SingleInstance Force
#include lib\OCR.ahk ; OCR library, shoutout Descolada on github

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

; === GUI STUFF ===
myGui := Gui("-MaximizeBox", "ASCC auto showdown")

myGui.SetFont("s20")
global TextCurrentLevelLabel := myGui.Add("Text", "x16 y8 w261 h40", "Current Level: 0")

myGui.SetFont("s20")
myGui.Add("Text", "x16 y48 w168 h39", "Level to stop:")

myGui.SetFont("s20")
global EditLevelToStopTextbox := myGui.Add("Edit", "x184 y48 w93 h39 +Number", LevelToStop)

myGui.SetFont("s14")
global StartButton := myGui.Add("Button", "x16 y88 w261 h40 Default", "&Start")

myGui.SetFont("s20")
global CheckboxRepeat := myGui.Add("CheckBox", "x16 y128 w262 h40", "Repeat Showdown")

myGui.SetFont("s20")
global CheckboxAutoSetup := myGui.Add("CheckBox", "x16 y168 w262 h40", "AutoSetup")

myGui.SetFont("s20")
global TextStatus := myGui.Add("Text", "x16 y232 w645 h47", "Status: Idle")

myGui.SetFont("s14")
myGui.Add("Text", "x296 y8 w366 h40", "Press [Insert] key to stop the whole process")

myGui.SetFont("s14")
myGui.Add("Text", "x296 y56 w366 h55", "Press [End] key to forcefully close this application")

StartButton.OnEvent("Click", StartClicked)
myGui.OnEvent('Close', (*) => ExitApp())

myGui.Show("w675 h293")

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
    
    ; Loop until the target time is reached
    while (A_TickCount < endTime) {
        ; Calculate remaining time in seconds with 1 decimal place (e.g., 2.4s)
        timeLeft := Round((endTime - A_TickCount) / 1000, 1)
        
        ; Update the GUI
        TextStatus.Text := statusText . " (" . timeLeft . "s)"
        
        ; Sleep in 100ms chunks to keep the GUI updating smoothly
        Sleep(100) 
    }
    
    ; Revert the text to normal once the sleep finishes
    TextStatus.Text := statusText 
} ; just to show countdowns of sleep function if ever they are longer than 2000ms ?

FocusRoblox() {
    targetWindow := "ahk_exe RobloxPlayerBeta.exe"
    if !WinExist(targetWindow) {
        MsgBox("Roblox is not running!")
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

LoadCards() {
    CustomClick(314, 304) ; strong card
    Sleep(500)

    Loop 6 { ; modify the number after "loop" to decide how many times to scroll down
        Send "{WheelDown}"
        Sleep(200)
    }

    CustomClick(541, 487) ; weak card 1
    Sleep(500)
    CustomClick(660, 487) ; weak card 2
    Sleep(500)
} ; loads the cards, use AutoHotkey Windows Spy if you want to modify, only use the client coordinates!!!!

CheckShowdownUI() {
    imageFileName := A_ScriptDir "\imagesearch pics\showdown.png"
    colorVariation := "*20 "

    ; Removed FocusRoblox() here so your computer doesn't stutter every 400ms.
    WinGetClientPos(&_, &_, &shWidth, &shHeight, "ahk_exe RobloxPlayerBeta.exe")
    
    ; Changed &_ to explicit output variables to prevent memory overlap bugs
    return ImageSearch(&outX, &outY, 0, 0, shWidth, shHeight, colorVariation . imageFileName)
} ; checks if the showdown UI is on the screen by checking if the top left icon of the showdown is on the screen

CheckIfIngame() {
    imageFileName := A_ScriptDir "\imagesearch pics\plotButton.png"
    colorVariation := "*20 "

    FocusRoblox()
    WinGetClientPos(&_, &_, &ighWidth, &igHeight, "ahk_exe RobloxPlayerBeta.exe")
    return ImageSearch(&_, &_, 0, 0, ighWidth, igHeight, colorVariation . imageFileName)
} ; checks if the player is ingame

TheSetup() {
    TextStatus.Text := "Status: Leaving game..."
    Send "{Escape}"
    Sleep(500)
    Send "L"
    Sleep(500)
    Send "{Enter}"
    Sleep(4000)

    TextStatus.Text := "Status: Navigating to search..."
    Send "{Down}"
    Sleep(1000)
    Send "{Down}"
    Sleep(500)
    Send "{Down}"
    Sleep(500)
    Send "/"
    Sleep(1000)

    TextStatus.Text := "Status: Searching the game..."
    Send "^a"
    Sleep(800)
    Send "anime "
    Sleep(800)
    Send "stars "
    Sleep(1000)
    Send "card "
    Sleep(1000)
    ; Send "collection"
    ; Sleep(1000)
    Send "{Enter}"
    Sleep(5000)

    TextStatus.Text := "Status: Entering the game..."
    Send "{Down}"
    Sleep(500)
    Send "{Down}"
    Sleep(500)
    Send "{Down}"
    Sleep(500)
    Send "{Enter}"
    Sleep(5000)

    TextStatus.Text := "Status: Going to showdown..."
    CustomClick(754, 475)
    Sleep(500)
    CustomClick(804, 34)
    Sleep(500)
    CustomClick(635, 376)
    Sleep(100)

    Loop 4 {
        Send "{WheelDown}"
        Sleep(300)
    }

    CustomRightClick(268, 327)
    Sleep(1000)
    TextStatus.Text := "Status: Idle"
} ; leaves game, goes back to game, then goes to showdown, only uses keyboard to navigate (unused)

TheSetup2() {
    TextStatus.Text := "Status: Leaving game..."
    Send "{Escape}"
    Sleep(500)
    Send "L"
    Sleep(500)
    Send "{Enter}"
    StatusSleep(4000, "Status: Waiting for menu to load...")

    TextStatus.Text := "Status: Reloading the main tab..."
    CustomClick(33, 35)
    Sleep(100)
    CustomClick(33, 35)
    StatusSleep(5000, "Status: Waiting for main tab to load...")
    TextStatus.Text := "Status: Navigating to the game..."
    SendMode "Event"
    MouseMove(504, 294, 10)
    Loop 5 {
        Send "{WheelDown}"
        Sleep(300)
    }
    MouseMove(162, 403, 10)
    Sleep(300)
    SendMode "Input"
    CustomClick(162, 403)
    Sleep(1000)
    CustomClick(575, 360)
    TextStatus.Text := "Status: Waiting for the game to load..."

    while (!CheckIfIngame()) {
        Sleep(1000)
    }

    TextStatus.Text := "Status: Going to showdown..."
    CustomClick(754, 475)
    Sleep(500)
    CustomClick(804, 34)
    Sleep(500)
    CustomClick(635, 376)
    Sleep(100)

    Loop 4 {
        Send "{WheelDown}"
        Sleep(300)
    }

    CustomRightClick(268, 327)
    Sleep(2000)
    TextStatus.Text := "Status: Idle"
} ; basically the same as the original one but uses mouse

GoToShowdown() {
    TextStatus.Text := "Status: Going to showdown..."
    CustomClick(754, 475)
    Sleep(500)
    CustomClick(804, 34)
    Sleep(500)
    CustomClick(635, 376)
    Sleep(100)

    Loop 4 {
        Send "{WheelDown}"
        Sleep(300)
    }

    CustomRightClick(268, 327)
    Sleep(2000)
    TextStatus.Text := "Status: Idle"
} ; purely used for going back to showdown area after reconnecting from disconnection

CheckIfDisconnected() {
    imageFileName := A_ScriptDir "\imagesearch pics\disconnected.png"
    colorVariation := "*20 "

    ; Removed FocusRoblox() here so your computer doesn't stutter every 400ms.
    WinGetClientPos(&_, &_, &cidWidth, &cidHeight, "ahk_exe RobloxPlayerBeta.exe")
    
    ; Changed &_ to explicit output variables to prevent memory overlap bugs
    return ImageSearch(&outX, &outY, 0, 0, cidWidth, cidHeight, colorVariation . imageFileName)
} ; checks for disconnected UI

CheckInternet() {
    http := ComObject("WinHttp.WinHttpRequest.5.1")
    try {
        http.Open("GET", "http://www.msftconnecttest.com/connecttest.txt", false)
        http.Send()
        return http.Status = 200
    }
    catch {
        return false
    }
} ; uses http request to check for internet connectivity, the link itself is from microsoft used to test connectivity

; === FARMING LOOPS ===
ExecuteFarmCycle() {
    global IsFarming
    
    Loop {
        if (!IsFarming)
            break
            
        SetWindowSize()
        Sleep(500)
        TextStatus.Text := "Status: Loading cards..."
        LoadCards()
        CustomClick(879, 530)
        Sleep(500)
        
        RunFarmLoop()
        
        if (!IsFarming || CheckboxRepeat.Value == 0) {
            break 
        }
        
        TextStatus.Text := "Status: Restarting"
        Sleep(500)
    }
    
    if (IsFarming) {
        ResetGUI()
    }
}

RunFarmLoop() {
    global CurrentLevel, LevelToStop, IsFarming, goalReached
    ShowdownUIFailCount := 0 ; this tracks how many times the macro fails to detect showdown UI before leaving and going back into the game
    
    Loop {
        if (!IsFarming)
            break
            
        try {
            if (!CheckIfDisconnected()) {
                WinGetClientPos(&cX, &cY, &cWidth, &cHeight, "ahk_exe RobloxPlayerBeta.exe") ; these are for making OCR work even on another monitor
                cX -= 8 ; calibrates window position to 0,0 as it gets nudged by window title bar
                cY -= 31
                scanX := cX + 244
                scanY := cY + 215
                
                if (!goalReached) {
                    TextStatus.Text := "Status: Farming..."

                    if (!CheckShowdownUI()) {
                        ShowdownUIFailCount++ ; increments showdown ui check failures if showdown ui not found
                        ToolTip("Warning! UI missing: " ShowdownUIFailCount "/10", scanX, scanY+90)
                        Sleep(3000)
                        
                        if (ShowdownUIFailCount >= 10) {
                            ToolTip() 
                            TextStatus.Text := "Status: Showdown UI not found! Running AutoSetup..."
                            Highlight()
                            TheSetup2() ; if it reaches 10 failed checks, leaves the game, joins back in, then go to showdown area
                            ShowdownUIFailCount := 0
                            break ; restart the entire macro cycle
                        }
                    } else {
                        ShowdownUIFailCount := 0 ; reset strikes if showdown ui is found
                    }


                    scanned_text := OCR.FromRect(scanX, scanY, 150, 60).Text
                    Highlight(scanX, scanY, 150, 60)
                    ToolTip("OCR readings: " scanned_text, scanX, scanY + 65)

                    ; erase everything after the dash
                    if InStr(scanned_text, "-") {
                        scanned_text := StrSplit(scanned_text, "-")[1]
                    }
                    
                    ; corrects wrong readings due to font style
                    scanned_text := StrReplace(scanned_text, "S", "5")
                    scanned_text := StrReplace(scanned_text, "s", "5")
                    scanned_text := StrReplace(scanned_text, "O", "0")
                    scanned_text := StrReplace(scanned_text, "T", "7")
                    scanned_text := StrReplace(scanned_text, "t", "7")
                    scanned_text := StrReplace(scanned_text, "I", "1")
                    scanned_text := StrReplace(scanned_text, "l", "1")
                    scanned_text := StrReplace(scanned_text, "i", "1")

                    ; take 1-3 digit number
                    if RegExMatch(scanned_text, "\b\d{1,3}\b", &match) {
                        cleaned_text := match[0]
                    } else {
                        cleaned_text := ""
                    }

                    if (cleaned_text == "") {
                        ToolTip("OCR Blind: Clicking to progress...", scanX, scanY+67)
                        CustomClick(783, 496) 
                        continue 
                    }
                    
                    CurrentLevel := Integer(cleaned_text)
                    TextCurrentLevelLabel.Text := "Current Level: " CurrentLevel 

                    if (CurrentLevel > LevelToStop + 2) {
                        ToolTip("Ignored false reading: " CurrentLevel, scanX, scanY+67)
                        continue
                    }

                    ; the actual part that clicks next level button
                    if (CurrentLevel < LevelToStop) {
                        CustomClick(783, 496) 
                    } else {
                        goalReached := true 
                    } 
                } else {
                    TextStatus.Text := "Status: Goal reached! Claiming..."
                    claimScanX := cX + 565
                    claimScanY := cY + 512
                    scanned_text := OCR.FromRect(claimScanX, claimScanY, 150, 60).Text
                    Highlight(claimScanX, claimScanY, 150, 60)
                    
                    if (scanned_text != "CLAIM") {
                        ToolTip("Waiting for CLAIM button...", claimScanX, claimScanY + 60)
                        CustomClick(782, 584) 
                        Sleep(400)
                    } else {
                        ToolTip("CLAIM button found! Clicking CLAIM", claimScanX, claimScanY + 60)
                        CustomClick(635, 511) 
                        Highlight()
                        ToolTip()
                        goalReached := false
                        break
                    }
                }
            } else {
                ; this is the part when the disconnected UI shows up, it will test internet connection then rejoin the game
                Highlight()
                ToolTip()
                TextStatus.Text := "Status: Disconnected! Testing internet..."

                while (!CheckInternet()) {
                    StatusSleep(5000, "Status: Testing internet...")
                }

                TextStatus.Text := "Status: Internet restored!"
                Sleep(2000)

                CustomClick(723, 432)
                TextStatus.Text := "Status: Reconnecting to the game..."

                while (!CheckIfIngame()) {
                    Sleep(1000)
                }
                TextStatus.Text := "Status: Successfully reconnected to the game!"
                Sleep(3000)
                GoToShowdown()
                ShowdownUIFailCount := 0
                break
            }
        } catch {
            Sleep(500)
        }
        Sleep(400)
    }
}

; === HOTKEYS ===
Insert:: {
    global IsFarming
    if (IsFarming) {
        ResetGUI()
    }
} ; stops farming

End::ExitApp ; forcefully closes app

; ^t:: {
;     if CheckShowdownUI() {
;         MsgBox("Found!")
;     } else {
;         MsgBox("Not found")
;     }
; }
; this is just for testing image search, dont mind it

Home::Pause(-1) ; actually pausing the whole process, as if time has stopped
