#Requires AutoHotkey v2.0
global LevelToStop, IsFarming, MACRO_STATE

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

StartButton.OnEvent("Click", StartButtonClicked)
myGui.OnEvent('Close', (*) => ExitApp())

myGui.Show("w675 h293")

; === GUI FUNCTIONS ===
StartButtonClicked(*) {
    global LevelToStop, IsFarming, MACRO_STATE

    inputValue := EditLevelToStopTextbox.Value
    if (inputValue == "") {
        MsgBox("Please enter a number into the Level to stop value")
        return
    }

    LevelToStop := Integer(inputValue) + 1
    IsFarming := true

    if (!FocusRoblox()) {
        MacroEventManager.Broadcast("FarmingStopped")
        return
    }

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
MacroEventManager.Listen("StatusTextUpdated", (newStatusText) => TextStatus.Text := "Status: " . newStatusText)
MacroEventManager.Listen("LevelUpdated", (newLevelValue) => TextCurrentLevelLabel.Text := "Current Level: " . newLevelValue)
MacroEventManager.Listen("FarmingStopped", ResetGUIVisuals)