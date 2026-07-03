#Requires AutoHotkey v2.0

; === UI CHECKS ===
CheckShowdownUI() {
    return ImageSearchBase64(GetShowdownUIBase64())
} ; checks if the showdown UI is on the screen by checking if the top left icon of the showdown is on the screen

CheckIfIngame() {
    FocusRoblox()
    return ImageSearchBase64(GetIfIngameBase64())
} ; checks if the player is ingame

CheckLoadCardsUI() {
    return ImageSearchBase64(GetLoadCardsUIBase64())
} ; checks if in load card menu of showdown

CheckIfDisconnected() {
    return ImageSearchBase64(GetIfDisconnectedBase64())
} ; checks for disconnected UI

CheckClaimButton() {
    return ImageSearchBase64(GetClaimButtonBase64())
} ; checks for claim button UI

ImageSearchBase64(base64string) {
    targetWindow := "ahk_exe RobloxPlayerBeta.exe"
    if !WinExist(targetWindow)
        return false

    hwnd := WinExist(targetWindow)
    WinGetClientPos(&bmX, &bmY, &bmWidth, &bmHeight, hwnd)
    
    ; capture game frame straight to RAM
    captureString := bmX "|" bmY "|" bmWidth "|" bmHeight
    RobloxWindowBitmap := Gdip_BitmapFromScreen(captureString)
    
    ; decode asset string straight to RAM
    TargetImageBitmap := Gdip_BitmapFromBase64(base64String)
    
    ; runs search matrix
    outputList := ""
    result := Gdip_ImageSearch(RobloxWindowBitmap, TargetImageBitmap, &outputList, 0, 0, 0, 0, 35)
    
    ; very important part that frees up ram that was used by this function
    Gdip_DisposeImage(RobloxWindowBitmap)
    Gdip_DisposeImage(TargetImageBitmap)
    
    return (result > 0)
} ; uses GDI+ for imagesearch using base64 strings converted from pictures of game UI

; === FAILSAFE ACTIONS ===
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
    MacroEventManager.Broadcast("StatusTextUpdated", "Disconnected! Testing internet...")

    while (!CheckInternet()) {
        ; Use standard Sleep here so we don't create an infinite loop with StatusSleep
        Sleep(5000) 
        MacroEventManager.Broadcast("StatusTextUpdated", "Testing internet...")
    }

    MacroEventManager.Broadcast("StatusTextUpdated", "Internet restored!")
    Sleep(2000)

    CustomClick(723, 432)
    MacroEventManager.Broadcast("StatusTextUpdated", "Reconnecting to the game...")

    while (!CheckIfIngame()) {
        Sleep(1000)
    }
    MacroEventManager.Broadcast("StatusTextUpdated", "Successfully reconnected to the game!")
    Sleep(3000)
    CustomClick(754, 475)
    Sleep(500)
    GoToShowdown2()
    
    ; This stops the script from returning to the old broken function
    throw Error("GameReconnected") 
} ; handles disconnection and navigates to showdown area, to be used almost everywhere in the code

EndRunEarly() {
    global IsFarming
    MacroEventManager.Broadcast("StatusTextUpdated", "Ending run early...")
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
            
            if (!CheckClaimButton()) {
                attempts++
                
                ; If tried 5 times and no CLAIM, the run is already clear
                if (attempts > 10) {
                    Highlight()
                    ToolTip()
                    MacroEventManager.Broadcast("StatusTextUpdated", "Lobby clear, starting farm cycle...")
                    break
                }
                
                ToolTip("Checking for active match... Attempt " attempts "/5", claimScanX, claimScanY + 60)
                CustomClick(782, 584) ; Click Cash Out to test if we are in a match
                Sleep(1000)
            } else {
                ToolTip("CLAIM button found! Clicking CLAIM", claimScanX, claimScanY + 60)
                CustomClick(635, 511) ; Click CLAIM
                Sleep(500)
                Highlight()
                ToolTip()
                
                MacroEventManager.Broadcast("StatusTextUpdated", "Waiting for lobby...")
                Sleep(2000)
                break
            }
        } catch {
            Sleep(500)
        }
    }
} ; if starting the macro or when going back to showdown area and showdown is in the middle of the run, end the run to be able to start again

LaunchASCCviaDeeplink() {
    MacroEventManager.Broadcast("StatusTextUpdated", "Closing old game process...")
    if ProcessExist("RobloxPlayerBeta.exe") {
        ProcessClose("RobloxPlayerBeta.exe")
        Sleep(2000)
    }
    
    MacroEventManager.Broadcast("StatusTextUpdated", "Launching via Deeplink...")
    Run("roblox://placeId=109715918987082")
    
    ; Wait up to 60 seconds for the engine process window to instantiate
    if WinWait("ahk_exe RobloxPlayerBeta.exe",, 60) {
        MacroEventManager.Broadcast("StatusTextUpdated", "Roblox engine detected! Waiting for game load...")
        Sleep(13000) ; give the game 13 seconds to load
        WinActivate("ahk_exe RobloxPlayerBeta.exe")
        return true
    } else {
        MacroEventManager.Broadcast("StatusTextUpdated", "Launch initialization timed out!")
        return false
    }
}