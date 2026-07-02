#Requires AutoHotkey v2.0
global CurrentLevel, LevelToStop, MACRO_STATE, IsFarming

LoadCards() {
    if (CheckIfDisconnected()) {
        HandleDisconnect()
    }
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

CheckClaimButton() {
    imageFileName := A_ScriptDir "\imagesearch pics\claim.png"
    colorVariation := "*20 "

    WinGetClientPos(&_, &_, &cbWidth, &cbHeight, "ahk_exe RobloxPlayerBeta.exe")
    return ImageSearch(&_, &_, 0, 0, cbWidth, cbHeight, colorVariation . imageFileName)
}

ClaimRewards() {
    global MACRO_STATE, IsFarming
    MacroEventManager.Broadcast("StatusTextUpdated", "Goal reached! Claiming...")
    loop {
        try {
            if (CheckIfDisconnected()) {
                HandleDisconnect()
            }

            if (!CheckClaimButton()) {
                CustomClick(782, 584) 
                    Sleep(500)
            } else {
                CustomClick(635, 511) 
                Highlight()
                ToolTip()

                MacroEventManager.Broadcast("StatusTextUpdated", "Waiting for UI to clear...")
                Sleep(1000)

                if (CheckboxRepeat.Value == 0) {
                    IsFarming := false
                    MACRO_STATE := "IDLE"
                    MacroEventManager.Broadcast("FarmingStopped")
                    break
                }

                MACRO_STATE := "PREPARATION"
                break
            }
        } catch {
            Sleep(500)
        }

        Sleep(400)
    }
}

; === FARMING LOOPS ===
RunFarmLoop() {
    global CurrentLevel, LevelToStop, IsFarming, MACRO_STATE
    ShowdownUIFailCount := 0 ; this tracks how many times the macro fails to detect showdown UI before leaving and going back into the game
    
    Loop {
        if (!IsFarming)
            break
            
        try {
            if (CheckIfDisconnected()) {
                HandleDisconnect()
            }
            WinGetClientPos(&cX, &cY, &cWidth, &cHeight, "ahk_exe RobloxPlayerBeta.exe") ; these are for making OCR work even on another monitor
            cX -= 8 ; calibrates window position to 0,0 as it gets nudged by window title bar
            cY -= 31
            scanX := cX + 244
            scanY := cY + 215
            
            if (!CheckShowdownUI()) {
                ShowdownUIFailCount++ ; increments showdown ui check failures if showdown ui not found
                ; ToolTip("Warning! UI missing: " ShowdownUIFailCount "/10", scanX, scanY+90)
                TextStatus.Text := "Status: Warning! UI missing: " ShowdownUIFailCount "/10"
                Sleep(3000)
                
                if (ShowdownUIFailCount >= 10) {
                    ToolTip() 
                    TextStatus.Text := "Status: Showdown UI not found! Running AutoSetup..."
                    Highlight()
                    TheSetup3() ; if it reaches 10 failed checks, leaves the game, joins back in, then go to showdown area
                    ShowdownUIFailCount := 0

                    MACRO_STATE := "PREPARATION"
                    break ; restart the entire macro cycle
                }

                continue
            } else {
                ShowdownUIFailCount := 0 ; reset strikes if showdown ui is found
            }

            TextStatus.Text := "Status: Farming..."
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
            MacroEventManager.Broadcast("LevelUpdated", CurrentLevel)

            if (CurrentLevel > LevelToStop + 2) {
                ToolTip("Ignored false reading: " CurrentLevel, scanX, scanY+67)
                continue
            }

            ; the actual part that clicks next level button
            if (CurrentLevel < LevelToStop) {
                CustomClick(783, 496) 
            } else {
                MACRO_STATE := "CLAIMING"
                break
            }
        } catch {
            Sleep(500)
        }
        
        Sleep(400)
    }
}