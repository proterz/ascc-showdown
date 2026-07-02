#Requires AutoHotkey v2.0

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

CheckLoadCardsUI() {
    imageFileName := A_ScriptDir "\imagesearch pics\loadcard.png"
    colorVariation := "*20 "

    ; Removed FocusRoblox() here so your computer doesn't stutter every 400ms.
    WinGetClientPos(&_, &_, &lcWidth, &lcHeight, "ahk_exe RobloxPlayerBeta.exe")
    
    ; Changed &_ to explicit output variables to prevent memory overlap bugs
    return ImageSearch(&outX, &outY, 0, 0, lcWidth, lcHeight, colorVariation . imageFileName)
} ; checks if in load card menu of showdown

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

HandleDisconnect() {
    Highlight()
    ToolTip()
    TextStatus.Text := "Status: Disconnected! Testing internet..."

    while (!CheckInternet()) {
        ; Use standard Sleep here so we don't create an infinite loop with StatusSleep
        Sleep(5000) 
        TextStatus.Text := "Status: Testing internet..."
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
    CustomClick(754, 475)
    Sleep(500)
    GoToShowdown2()
    
    ; This stops the script from returning to the old broken function
    throw Error("GameReconnected") 
} ; handles disconnection and navigates to showdown area, to be used almost everywhere in the code

EndRunEarly() {
    global IsFarming
    TextStatus.Text := "Status: Ending run early..."
    attempts := 0 ; Tracks how many times we try to force-clear a match
    
    Loop {
        if (!IsFarming)
            break
            
        try {
            if (CheckIfDisconnected()) {
                HandleDisconnect()
            }
            WinGetClientPos(&dX, &dY, &cWidth, &cHeight, "ahk_exe RobloxPlayerBeta.exe")
            dX -= 8
            dY -= 31
            claimScanX := dX + 565
            claimScanY := dY + 512
            scanned_text := OCR.FromRect(claimScanX, claimScanY, 150, 60).Text
            Highlight(claimScanX, claimScanY, 150, 60)
            
            if (scanned_text != "CLAIM") {
                attempts++
                
                ; If tried 5 times and no CLAIM, the run is already clear
                if (attempts > 10) {
                    Highlight()
                    ToolTip()
                    TextStatus.Text := "Status: Lobby clear, starting farm cycle..."
                    break
                }
                
                ToolTip("Checking for active match... Attempt " attempts "/5", claimScanX, claimScanY + 60)
                CustomClick(782, 584) ; Click Cash Out to test if we are in a match
                Sleep(1000)
            } else {
                ToolTip("CLAIM button found! Clicking CLAIM", claimScanX, claimScanY + 60)
                CustomClick(635, 511) ; Click CLAIM
                Highlight()
                ToolTip()
                
                TextStatus.Text := "Status: Waiting for load card menu..."
                Sleep(2000)
                break
            }
        } catch {
            Sleep(500)
        }
    }
} ; if starting the macro or when going back to showdown area and showdown is in the middle of the run, end the run to be able to start again