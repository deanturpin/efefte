-- Turbeaux Sounds EFEFTE Installer

on run
    set dmgPath to (path to me as text)
    set posixPath to POSIX path of dmgPath
    set installerDir to do shell script "dirname " & quoted form of posixPath

    display dialog "This will install Turbeaux Sounds EFEFTE Audio Unit plugin and Standalone app." buttons {"Cancel", "Install"} default button 2 with title "Turbeaux Sounds EFEFTE Installer"

    if button returned of result is "Install" then
        -- Create Components directory if needed
        do shell script "mkdir -p ~/Library/Audio/Plug-Ins/Components"

        -- Install Audio Unit
        try
            do shell script "cp -R " & quoted form of (installerDir & "/EFEFTEAudioUnit.component") & " ~/Library/Audio/Plug-Ins/Components/"
            set audioUnitInstalled to true
        on error
            set audioUnitInstalled to false
        end try

        -- Install Standalone App (may require admin)
        try
            do shell script "cp -R " & quoted form of (installerDir & "/EFEFTEStandalone.app") & " /Applications/" with administrator privileges
            set standaloneInstalled to true
        on error
            set standaloneInstalled to false
        end try

        -- Show results
        set resultMessage to ""
        if audioUnitInstalled then
            set resultMessage to resultMessage & "✅ Audio Unit plugin installed" & return
        else
            set resultMessage to resultMessage & "⚠️ Audio Unit plugin not installed" & return
        end if

        if standaloneInstalled then
            set resultMessage to resultMessage & "✅ Standalone app installed" & return
        else
            set resultMessage to resultMessage & "⚠️ Standalone app not installed" & return
        end if

        set resultMessage to resultMessage & return & "Please restart Logic Pro to use the plugin."

        display dialog resultMessage buttons {"OK"} default button 1 with title "Installation Complete"
    end if
end run