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