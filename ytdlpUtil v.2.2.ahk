A_ScriptName :=("ytdlpUtil")
Version :=("v2.2.1")
A_AllowMainWindow := 1
A_DetectHiddenWindows :=(1)
if A_IsCompiled =(1){
    A_TrayMenu.Delete
A_TrayMenu.add("Exit", TrayExit)    ;Create script exit button
Persistent
ManualExit := false
TrayExit(ItemName, ItemPos, MyMenu){
    ExitApp
}
Persistent
}

Temp :=(A_Temp "\yt-dlpUtility")
InstallDir :=("C:\Users\" A_UserName "\AppData\Local\Programs\AstScripts\ytdlpUtil")
ext :=(".ahk")
if A_IsCompiled{
    ext :=(".exe")
}
if !DirExist(InstallDir){
    DirCreate(InstallDir)
}
try SetWorkingDir(InstallDir)
LaunchGui := Gui("ToolWindow OwnDialogs","Launcher")
LaunchGUIText := LaunchGui.Add("Text","W250","Checking config file")
LaunchGui.Show("Center W250")
LaunchGui.OnEvent("Close", LaunchGUIClose)
LaunchGUIClose(*){
    ExitApp
}
;Validate integrity of config
ConfigValid := 0
if FileExist(InstallDir "\config.txt"){
    loop{
        ConfigError := 0
        ConfigChecker := 0
        ConfigFile := FileOpen(InstallDir "\config.txt","r")
        ConfigFile.ReadLine()
        global ConfigLastVersion := ConfigFile.ReadLine()
        ;If executed version is newer than previously logged, skip sanity checks to avoid errors
        global isUpdate := StrCompare(Version, ConfigLastVersion, 0)
        if isUpdate >= 1{
            global updatePrompt := 1
            break
        }
        global ConfigDownloads := ConfigFile.ReadLine()
        global ConfigConfigs := ConfigFile.ReadLine()
        ConfigFile.Close
        if DirExist(ConfigDownloads){
            global ConfigChecker +=1
        }
        else{
            ConfigErrorReason :=("Downloads folder does not exist")
        }
        if DirExist(ConfigConfigs){
        global ConfigChecker +=2
        }
        else{
            ConfigErrorReason :=("Configs Folder does not exist")
        }
        if ConfigChecker = 3{
            global ConfigValid := 1
            break
        }
        else{ 
            ;If an error occurs due to running an older version, tell the user
            if isUpdate < 0{
                ConfigError := MsgBox("You're running an older version of the utility, which is causing errors with the saved config. Please use a newer version.`n`nDo you wish to downgrade the utility?","Version Error", 0x4)
                if ConfigError =("No"){
                    ExitApp
                }
                if ConfigError =("Yes"){
                    ConfigError := MsgBox("Downgrading will remove your saved configuration file, and you must re-complete the first-time setup. Are you sure?","Version Error", 0x4)
                    if ConfigError =("No"){
                        ExitApp
                    }
                    if ConfigError =("Yes"){
                        global ConfigError := 1
                        break
                    }
                }
            }
            ;this FUCKING SUCKS
            if ConfigError = 0{ 
                configError := MsgBox("The utility's config is broken, please either continue to reconfigure, or manually repair it yourself.`nReason: " ConfigErrorReason, "Broken Config", 0x36)
                if configError =("Continue"){
                    global setupConfig := 1
                    break
                }
                if configError =("Cancel"){
                    ExitApp
                }
            }
        }
    }
}
else{
    setupConfig := 1
}
;If the executed file is a newer version than stored, prompt update
try if updatePrompt = 1{
    ConfigError := MsgBox("You're attempting to run a newer version of the utility, updating will be required to continue.`nLast used version: " ConfigLastVersion "`nNew version: " Version,"Update!", 0x1)
    if ConfigError =("Ok"){
        LaunchGUIText.Value :=("Updating utility")
    }
    if ConfigError =("Cancel"){
        ExitApp
    }
    loop{
        DirCreate(Temp "\config")
        FileCopy(InstallDir "\config.txt", Temp "\config", 1)
        sleep 100
        global movedConfig := FileExist(Temp "\config\config.txt")
        if A_index = 5{
            global UpdateErrors +=("Config")
            break
        }
    }until movedConfig =("A")
    global setupConfig := 1
    if IsSet(UpdateErrors){
        MsgBox("Error: " UpdateErrors)
    }
    loop files, A_Programs "\AstScripts\*", "F"{
        isInStart := InStr(A_LoopFileName, A_ScriptName A_Space ConfigLastVersion ".lnk")
        if isInStart{
            FileDelete(A_Programs "\AstScripts\" A_LoopFileName)
            
        }
        continue
    }
    loop files, A_Desktop "\*", "F"{
        isOnDesktop := InStr(A_LoopFileName,A_ScriptName A_Space ConfigLastVersion ".lnk")
        if isOnDesktop{
            FileDelete(A_Desktop "\" A_LoopFileName)
        }
    }
}
;Begin configuration file creation
try if setupConfig = 1{
    global ConfigFile := FileOpen(InstallDir "\config.txt", "w")
    ConfigFile.WriteLine(";Configuration file for the ytdlpUtil script")
    ConfigFile.WriteLine(Version)

    if movedConfig =("A"){
        oldConfigFile := FileOpen(Temp "\config\config.txt","r")
        oldConfigFile.ReadLine()
        oldConfigVer := oldConfigFile.ReadLine()
        global oldConfigDownloads := oldConfigFile.ReadLine()
        global oldConfigConfigs := oldConfigFile.ReadLine()
        oldConfigFile.Close
    }
}
;Handle first-time setup & updater config importing
if ConfigValid = 0{
    FirstTimeGui := Gui()
    global FTGScriptDir :=("")
    setupDownloadSet := IsSet(oldConfigDownloads)
    setupConfigsSet := IsSet(oldConfigConfigs)
    if !setupDownloadSet{
        global oldConfigDownloads :=("")
    }
    if !setupConfigsSet{
        global oldConfigConfigs :=("")
    }
    updaterDownloadsValid := StrCompare(oldConfigDownloads,'', 0)
    if updaterDownloadsValid > 0{
        ConfigFile.WriteLine(oldConfigDownloads)
    }
    else{
        SelectedDownloadDir :=("")
        while SelectedDownloadDir =(""){
            SelectedDownloadDir := DirSelect(,3,"Select a folder to download media to (Two subfolders will be created, I'd suggest making a dedicated folder for downloads):")
            if SelectedDownloadDir =(""){
                selectedDirError := MsgBox("No directory was specified. Please select a directory.","Error", 0x5)
                if selectedDirError =("retry"){
                    return          
                }
                if selectedDirError =("Cancel"){
                    ExitApp
                }
            }
        }
        try ConfigFile.WriteLine(SelectedDownloadDir)
        catch{
            MsgBox("An error occured while trying to add your downloads folder, a default folder has been created instead. This can be manually fixed later.","Error",)
            ConfigFile.WriteLine("C:\Users\" A_UserName "\Downloads\AstScripts\yt-dlpUtil")
        }
    }
    updaterConfigsValid := StrCompare(oldConfigConfigs,'', 0)
    if updaterConfigsValid > 0{
        ConfigFile.WriteLine(oldConfigConfigs)
        global FTGScriptDir :=(oldConfigConfigs)
        global setupConfigsWritten := 1
    }
    else{
        FTGText := FirstTimeGui.Add("Text",,"(Optional) Custom YTDLP config directory:")
        FTGScriptBtn := FirstTimeGui.Add("Button","w40","Config")
    }
    FTGShort := FirstTimeGui.Add("Checkbox","Checked","Add shortcut to Desktop?")
    FTGStart := FirstTimeGui.Add("Checkbox","Checked","Add to start menu?")
    FTGSubButton := FirstTimeGui.Add("Button",,"Continue")
    firstTimeWait := 1
    FirstTimeGui.Show
    Loop{
        try FirstTimeGui.OnEvent("Close",FirstTimeGuiClose)
        FirstTimeGuiClose(*){
            ExitApp
        }
        try FTGSubButton.OnEvent("Click",FTGSubButtonClck)
        FTGSubButtonClck(*){
            if FTGScriptDir =(""){
                global FTGScriptDir :=(InstallDir "\Configs")
            try DirCreate(InstallDir "\Configs")
            }
            if IsSet(setupConfigsWritten) = 0{
                ConfigFile.WriteLine(FTGScriptDir)
            }
            global FTGShortValue := FTGShort.Value
            global FTGStartValue := FTGStart.Value
            global firstTimeWait := 0
            FirstTimeGui.Destroy
        }
        if updaterConfigsValid <= 0{
            try FTGScriptBtn.OnEvent("Click",FTGScriptBtnEvnt)
            FTGScriptBtnEvnt(*){
                global FTGScriptDir := DirSelect(,3,)
                if not FTGScriptDir =(""){
                    FTGText.Value := FTGScriptDir
                }
            }
        }
    }until firstTimeWait = 0
    sleep 100
    ConfigFile.Close
    try FileCopy(A_ScriptFullPath, InstallDir "\" A_ScriptName A_Space Version ext)
    if A_IsCompiled{
        try if FTGShortValue = 1{
            FileCreateShortcut(InstallDir "\" A_ScriptName A_Space Version ext, A_Desktop "\" A_ScriptName A_Space Version ".lnk",,,, InstallDir "\" A_ScriptName A_space Version ext)
        }
        try if FTGStartValue = 1{
            DirCreate(A_Programs "\AstScripts")
            FileCreateShortcut(InstallDir "\" A_ScriptName A_space Version ext, A_Programs "\AstScripts\" A_ScriptName A_Space Version ".lnk",,,, InstallDir "\" A_ScriptName A_Space Version ext)
        }
    }
    LaunchGUIText.Value :=("The utility has been installed, it will not auto-run")
    sleep 5000
    ExitApp
}
LaunchGui.OnEvent("Escape", LaunchGUIEsc)
LaunchGUIEsc(*){
global EscapeGUIOpen :=(1)
    try{
        openlogfile.Close
    }
    SetWorkingDir(InstallDir)
    EscapeGUI :=(Gui("ToolWindow","Magical Error Menu"))
    EscapeGUI.MarginX :=("32")
    EscapeGUI.MarginY :=("10")
    EscapeGUIExitBtn := EscapeGUI.Add("Button",,"Clear All Data")
    EscapeGUITempBtn := EscapeGUI.Add("Button",,"Open Temp")
    EscapeGUIWorkBtn := EscapeGUI.Add("Button",,"Open Working")
    EscapeGUI.Show
    EscapeGUI.OnEvent("Close", EscapeGUIExit)
    EscapeGUIExit(*){
        ExitApp
    }
    EscapeGUITempBtn.OnEvent("Click", EscapeGUIExitEvnt)
    EscapeGUIExitEvnt(*){
        run("C:\Windows\explorer.exe " Temp)
    }
    EscapeGUIWorkBtn.OnEvent("Click", EscapeGUIWorkEvnt)
    EscapeGUIWorkEvnt(*){
        run("C:\Windows\explorer.exe " A_WorkingDir)
    }
    EscapeGUIExitBtn.OnEvent("Click", ExitBtnClck)
    ExitBtnClck(*){
        finalprompt := MsgBox('Clicking "Yes" will clear all saved data from this tool (local config & local versions of YT-DLP and FFMPEG). Do you wish to continue?', 'Warning', 0x1144)
        if finalprompt =("No"){
        }
        if finalprompt =("Yes"){
            WorkDelStat :=("Dependencies not deleted")
            TempDelStat :=("Temp folder not deleted")
            try{
                FileDelete(InstallDir "\config.txt")
                FileDelete(InstallDir "\log.txt")
                DirDelete(InstallDir "\Dependencies",1)
                DirDelete(Temp,1)
            }
            sleep 1000
            if not DirExist(InstallDir "\Dependencies"){
                global WorkDelStat :=("Dependencies deleted")
            }
            if not DirExist(Temp){
                global TempDelStat :=("Temp folder deleted")
            }
            sleep 500
            MsgBox("Deletion Complete: " WorkDelStat ", " TempDelStat ".`n The program will now exit.",,"T15")
            ExitApp
        }
    }
} 
SetWorkingDir(InstallDir)
LogFile :=(InstallDir "\log.txt")
if not DirExist(Temp){
    DirCreate(Temp)
}
EscapeGUIOpen :=(0)
ytdlpinstallrun :=(0)
ffmpegdir :=("")
localffmpeg :=("")
ytdlpLocal :=("")
ffmpegOverride :=("")
;yt-dlp cmd check, auto-download if not found
loop{
    if EscapeGUIOpen =(1){
        Exit
    }
    LaunchGUIText.value :=("Checking for yt-dlp")
    RunWait(A_ComSpec " /c yt-dlp --version >" LogFile " 2>&1",,"Hide",&cmdPID)
    loop{
        try{ 
            global openlogfile := FileOpen(LogFile, "r")
            break
        }
        catch{
            sleep 250
            if A_Index =(5){
                MsgBox("An error has occured during startup, please ensure that the utility is able to access " InstallDir)
            }
        }
    }
    global ytdlpVer := openlogfile.ReadLine()
    ytdlpExist := StrCompare(ytdlpVer, "2024")
    if EscapeGUIOpen =(1){
        Exit
    }
    if ytdlpExist > 0{
        LaunchGUIText.value :=("yt-dlp found")
        break
    }
    if ytdlpExist <= 0{
        LaunchGUIText.Value :=("yt-dlp not found")
        sleep 100
    if ytdlpinstallrun =(0){
        Download("https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe", "yt-dlp.exe")
        ytdlpinstallrun :=(1)
        }
    }
    if A_index =(5){
        MsgBox("Something went wrong installing yt-dlp.`nPlease try again or install yt-dlp manually","Error",)
        ExitApp
    }
} ;ffmpeg cmd check, prompt download if not found
loop{
    if EscapeGUIOpen =(1){
        Exit
    }
    LaunchGUIText.value :=("Checking for ffmpeg")
    openlogfile.Seek("0",2)
    RunWait(A_ComSpec " /c " ffmpegdir "ffmpeg -version >>" LogFile " 2>&1",,,&cmdPID)
    ffmpegVer := openlogfile.ReadLine()
    ffmpegExist := StrCompare(ffmpegVer, "7.0")
    if ffmpegExist <= 0{
        global ffmpegdir :=(InstallDir "\Dependencies\ffmpeg\bin\")
        global localffmpeg :=("--ffmpeg-location ")
    }
    if ffmpegExist > 0{
        sleep 200
        if FileExist(InstallDir "\Dependencies\ffmpeg\bin\ffmpeg.exe"){
            LaunchGUIText.value :=("ffmpeg found locally")
            global ffmpegOverride := ("--ffmpeg-location " ffmpegdir "ffmpeg.exe")
            global ffmpegdir :=("")
            break
        }
    }
    if A_index =(3){
        ffmpegDownPrompt := MsgBox("ffmpeg was not located, would you like to install it?`n`nffmpeg is not required to utilize this utility, but it is recommended.","Error", 0x4)
        if ffmpegDownPrompt =("Yes"){
            LaunchGUIText.Value :=("ffmpeg not found, installing..")
            if not FileExist(Temp "\ffmpegdownload.zip"){
                Download("https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip",Temp "\ffmpegdownload.zip")
            }
            loop{
                if EscapeGUIOpen =(1){
                    break
                }
                if FileExist(Temp "\ffmpegdownload.zip")
                try{
                    DirCopy(Temp "\ffmpegdownload.zip", Temp "\ffmpegdownloaded", 1)
                    loop files, Temp "\ffmpegdownloaded\*", "D"{
                        global ffmpegTempDir :=(A_LoopFilePath)
                        DirMove(ffmpegTempDir, InstallDir "\Dependencies\ffmpeg",1)     
                        sleep 100  
                        break
                    }
                    if IsSet(ffmpegTempDir)
                        break
                    }
                }
            }
        }
        try if ffmpegDownPrompt =("No"){
            localffmpeg :=("")
            ffmpegdir :=("")
            break
        }
    }

;Clear all unneeded variables, exit launcher gui
openlogfile.Close
LaunchGUIText :=(unset)
ffmpegTempDir :=(unset)
ytdlpinstallrun :=(unset)
EscapeGUIOpen :=("")
ytsearch :=("")
Temp :=(unset)
CustomConfigFilePath :=("Null")
LaunchGui.Destroy
LaunchGui :=(unset)
;Create and show GUI and inputs
MainGUIMenu := Menu()
MainGUIMenuBar := MenuBar()
MainGUIMenuBar.Add("&File", MainGUIMenu)
MainGUIMenu.Add("&Downloads", MainGUIMenuDownloads)
MainGUIMenuDownloads(*){
    try Run("C:\Windows\explorer.exe " ConfigDownloads)
}
MainGUIMenu.Add("&Install", MainGUIMenuInstall)
MainGUIMenuInstall(*){
    try Run("C:\Windows\explorer.exe " InstallDir)
}
MainGUIMenu.Add("&Versions", MainGUIMenuVersions)
MainGUIMenuVersions(*){
    VersionsGUI := Gui("ToolWindow OwnDialogs +Owner" MainGUI.Hwnd, "Versions")
    VersionsGUI.Add("Text","Center", "ytdlpUtil: " Version)
    VersionsGUI.Add("Text","Center", "YT-DLP: " ytdlpVer)
    VersionsGUI.Add("Text","Center", "ffmpeg: " ffmpegVer)
    VersionsGUI.Show("")
    VersionsGUI.OnEvent("Close",VersionsGUIClose)
    VersionsGUIClose(*){   
    }
}
MainGUI := Gui("OwnDialogs", "Downloader")
MainGUI.MenuBar := MainGUIMenuBar
MainGUI.MarginX :=("20")
MainGUI.MarginY :=("10")
;MainGUIURLText := MainGUI.Add("Text","X30 Y10","URL:")
MainGUIToggleSearch := MainGUI.Add("Checkbox","X30 Y10 w105","URL:")
MainGUIEdit := MainGUI.Add("Edit","X30 Y30 w250 limit100","")
MainGUIDownload := MainGUI.Add("Button","+Default X30 Y55 W100","Download")
MainGUIRadioVid := MainGUI.Add("Radio","Checked X30 Y85","Video")
MainGUIRadioAud := MainGUI.Add("Radio","X30 Y105","Audio")
MainGUIRadioCstm := MainGUI.Add("Radio","X30 Y125","Custom")
MainGUIStatus := MainGUI.Add("StatusBar","w250", "hello everybody, my name is markiplier")
MainGUIOpenDir := MainGUI.Add("Button","X200 Y55","Open Folder")
MainGUIcstmcfg := MainGui.Add("DropDownList","X160 Y122 +Disabled",)
MainGUI.Show()
if DirExist(ConfigConfigs){
    loop files, ConfigConfigs "\*", "R"{
        MainGUIcstmcfg.Add([A_LoopFileName])
    }
}
if not DirExist(ConfigConfigs){
    DirCreate(ConfigConfigs)
}
loop{
    MainGUI.Opt("-Disabled")
    if EscapeGUIOpen =(1){
        Exit
    }

    MainGUIToggleSearch.OnEvent("Click", MainGUITSClick)
    MainGUITSClick(*){
        if MainGUIToggleSearch.Value = 1{
            MainGUIToggleSearch.Text :=("YouTube Search:")
            ;MainGUIURLText
            global ytsearch :=("ytsearch:")

        }
        if MainGUIToggleSearch.Value = 0{
            MainGUIToggleSearch.Text :=("URL:")
            ytsearch :=("")
        }
    }
    MainGUIcstmcfg.OnEvent("Change", CstmCfgChange)
    CstmCfgChange(*){
        loop files, ConfigConfigs "\" MainGUIcstmcfg.Text, "R"{
        global CustomConfigFilePath :=(A_LoopFileDir)
        }
    }

    MainGUIRadioCstm.OnEvent("Click", MainGUIRadioCstmClck)
    MainGUIRadioCstmClck(*){
        MainGUIcstmcfg.Opt("-Disabled")
    }
    MainGUIRadioVid.OnEvent("Click",MainGUIRadioVidClck)
    MainGUIRadioVidClck(*){
        MainGUIcstmcfg.Opt("+Disabled")
    }
        MainGUIRadioAud.OnEvent("Click",MainGUIRadioAudClck)
    MainGUIRadioAudClck(*){
        MainGUIcstmcfg.Opt("+Disabled")
    }
    MainGUIDownload.OnEvent("Click", DownloadClick)
    DownloadClick(*){
        MainGUI.Opt("+Disabled")
        loop{
            try{
                openlogfile := FileOpen(LogFile, 0x300)
                sleep 100
                openlogfile.seek("0",2)
                break
            }
            catch{
                sleep 250
            }
        }
        sleep 50
        if MainGUIRadioVid.value =(1){
            global ActiveConfig := '-P "' ConfigDownloads '\Video"'
            if not DirExist(ConfigDownloads "\Video"){
            DirCreate(ConfigDownloads "\Video")
            }
        }
        if MainGUIRadioAud.value =(1){
            global ActiveConfig := '--audio-format mp3  --audio-quality 128k --extract-audio -P "' ConfigDownloads '\Audio"'
            if not DirExist(ConfigDownloads "\Audio"){
                DirCreate(ConfigDownloads "\Audio")
            }
        }
        if MainGUIRadioCstm.value =(1){
            if not DirExist(InstallDir "\Configs"){
                MainGUIStatus.SetText("Configs folder is missing")
                return
            }
            if InStr(CustomConfigFilePath, "\Configs") = 0{
                MainGUIStatus.SetText("Invalid custom config")
                return
            }
            customConfigPathCheck := FileRead(CustomConfigFilePath "\" MainGUIcstmcfg.Text)
            if not InStr(customConfigPathCheck, "-P" or "--paths"){
                if not DirExist(ConfigDownloads "\Custom"){
                    DirCreate(ConfigDownloads)
                }
                customConfigPath :=(A_Space '-P "' ConfigDownloads '\Custom"')
            }
            else{
                customConfigPath :=("")
            }
            global ActiveConfig :=('--config-location "' CustomConfigFilePath '\' MainGUIcstmcfg.Text '"' customConfigPath)
        }
        Run(A_ComSpec " /c yt-dlp " ffmpegOverride A_Space ActiveConfig A_space ytsearch '"' MainGUIEdit.Text '" >>' LogFile " 2>&1",,,&runPID)
        loop{
            sleep 500
            while WinExist("ahk_pid " runPID){
                MainGUIStatus.SetText(openlogfile.ReadLine())
                sleep 300
            } ;When cmd exits, reset var, notify user, update activity display
            if not WinExist("ahk_pid " runPID){
                openlogfile.Close
                MainGUI.Flash
                MainGUIStatus.SetText("Download Finished")
                return
            }
        }
    }
    MainGUIOpenDir.OnEvent("Click", OpenDirClick)
    OpenDirClick(*){
        Run("C:\Windows\explorer.exe " ConfigDownloads)
    }
    MainGUI.OnEvent("Close", MainGUIClose)
    MainGUIClose(*){
        ExitApp
    }
}
