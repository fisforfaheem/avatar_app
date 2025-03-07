@echo off
echo Creating Windows package for distribution...

:: Create a distribution folder
mkdir dist
mkdir dist\avatar_app

:: Copy the executable and all necessary files
xcopy /E /I build\windows\x64\runner\Release\*.* dist\avatar_app\

:: Create a shortcut to the exe in the root folder
echo Set oWS = WScript.CreateObject("WScript.Shell") > CreateShortcut.vbs
echo sLinkFile = "dist\Voice Avatar Hub.lnk" >> CreateShortcut.vbs
echo Set oLink = oWS.CreateShortcut(sLinkFile) >> CreateShortcut.vbs
echo oLink.TargetPath = "%CD%\dist\avatar_app\avatar_app.exe" >> CreateShortcut.vbs
echo oLink.WorkingDirectory = "%CD%\dist\avatar_app" >> CreateShortcut.vbs
echo oLink.Description = "Voice Avatar Hub" >> CreateShortcut.vbs
echo oLink.IconLocation = "%CD%\dist\avatar_app\avatar_app.exe,0" >> CreateShortcut.vbs
echo oLink.Save >> CreateShortcut.vbs
cscript CreateShortcut.vbs
del CreateShortcut.vbs

echo Package created successfully in the 'dist' folder.
echo You can distribute the entire 'dist' folder or create a zip file from it.
pause 