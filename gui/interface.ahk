#Requires AutoHotkey v2.0
global LevelToStop, IsFarming, MACRO_STATE

; === GUI STUFF ===
CreateGUI() {
    global LevelToStop, IsFarming, MACRO_STATE
    savedConfig := LoadMacroConfig() ; for config

    myGui := Gui("-MaximizeBox", "ASCC Showdown Farm")
    myGui.SetFont("s12", "Segoe UI") 

    ; === LEFT COLUMN ===
    ConfigBox := myGui.Add("GroupBox", "Section w280 h260 Center", "Main Farming Loop")

    global TextCurrentLevelLabel := myGui.Add("Text", "xp+15 yp+30 w250", "Current Level: 0")

    myGui.Add("Text", "xs+15 y+20 w100", "Level Mode:")
    global DropLevelMode := myGui.Add("DropDownList", "x+m yp-4 w130 Choose" . (savedConfig["StopMode"] = "Manual" ? 2 : 1), ["Automatic", "Manual"])
    DropLevelMode.OnEvent("Change", ToggleLevelMode)

    global EditLevelToStopTextbox := myGui.Add("Edit", "xs+15 y+10 w250 +Number", savedConfig["LevelToStop"])
    ToggleLevelMode(DropLevelMode)
    global CheckboxRepeat := myGui.Add("CheckBox", "xs+15 y+15 w250 Checked" . savedConfig["CheckboxRepeat"], "Repeat Showdown")
    global StartButton := myGui.Add("Button", "xs+15 y+25 w250 h40 Default", "&Start")

    ; === RIGHT COLUMN ===
    myGui.Add("GroupBox", "ys w350 h260 Center", "Hotkeys")
    
    myGui.Add("Text", "xp+15 yp+30 w320", "Press [Insert] to stop the macro.")
    myGui.Add("Text", "xp y+20 w320", "Press [End] to completely exit.")
    myGui.Add("Text", "xp y+20 w320 cBlue", "Press [F12] to toggle the macro state window.") 

    btnCustomize := MyGui.Add("Button", "w200", "Customize Card Loading")
    btnCustomize.OnEvent("Click", CustomizeCardLoading)

    ; === BOTTOM ===
    global TextStatus := myGui.Add("Text", "xm y+150 w645 r2", "Status: Idle")

    ; === GUI EVENTS ===
    StartButton.OnEvent("Click", StartButtonClicked)
    myGui.OnEvent("Close", OnHeartbeatGuiClose)

    OnHeartbeatGuiClose(*) {
        global IsManualShutdown
        IsManualShutdown := true
        ExitApp()
    }


    RegisterGUIEventListeners()

    myGui.Show()

    ; === AUTO RESUME IF EVER MACRO CRASHES ===
    if (IsRecoveryMode && savedConfig["CheckboxRepeat"] == "1") {
        MacroEventManager.Broadcast("StatusTextUpdated", "Automated recovery triggered! Starting...")
        
        SetTimer((*) => StartButtonClicked(), -2000) ; give a 2 second window when recovering from the macro crashing
    }
}

; === GUI FUNCTIONS ===
ToggleLevelMode(ctrl, *) {
    global EditLevelToStopTextbox
    isManual := (ctrl.Text == "Manual")
    EditLevelToStopTextbox.Visible := isManual
    EditLevelToStopTextbox.Enabled := isManual
}

StartButtonClicked(*) {
    global LevelToStop, IsFarming, MACRO_STATE, EditLevelToStopTextbox, CheckboxRepeat, DropLevelMode, IsAutoStop

    selectedStopMode := DropLevelMode.Text
    manualLevelValue := EditLevelToStopTextbox.Value

    if (selectedStopMode == "Manual") {
        IsAutoStop := false
        
        if (manualLevelValue == "" || Integer(manualLevelValue) <= 0) {
            MsgBox("Please enter a valid target level above 0!", "Error", "Icon!")
            return
        }
        LevelToStop := Integer(manualLevelValue) + 1
    } else {
        ; Automatic Mode
        IsAutoStop := true
        LevelToStop := 9999 ; Set arbitrarily high so the manual check never triggers
    }

    savedRepeat := CheckboxRepeat.Value
    SaveMacroConfig(manualLevelValue, savedRepeat, selectedStopMode)
    IsFarming := true

    StartButton.Enabled := false
    StartButton.Text := "Running"

    ; if (!FocusRoblox()) {
    ;     MacroEventManager.Broadcast("FarmingStopped")
    ;     return
    ; }
    ; disabling this for now as PREPARATION state will launch Roblox by itself

    MACRO_STATE := "PREPARATION"
    PerformMacroState()
}

ResetGUIVisuals(*) {
    global IsFarming, MACRO_STATE
    IsFarming := false
    MACRO_STATE := "IDLE"

    StartButton.Enabled := true
    StartButton.Text := "&Start"
    TextStatus.Text := "Status: Idle"
    ToolTip()
    Highlight()
}

; === EVENT MANAGER FUNCTIONS ===
RegisterGUIEventListeners() {
MacroEventManager.Listen("StatusTextUpdated", (newStatusText) => TextStatus.Text := "Status: " . newStatusText)
MacroEventManager.Listen("LevelUpdated", (newLevelValue) => TextCurrentLevelLabel.Text := "Current Level: " . newLevelValue)
MacroEventManager.Listen("FarmingStopped", ResetGUIVisuals)
}