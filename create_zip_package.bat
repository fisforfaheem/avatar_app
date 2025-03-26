@echo off
echo Creating ZIP Package for Voice Avatar Hub...

set PACKAGE_DIR=release_package
set ZIP_NAME=VoiceAvatarHub_Windows_v0.1.0.zip

:: Check if PowerShell is available
where powershell >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo PowerShell is not available. Cannot create ZIP archive.
    pause
    exit /b 1
)

:: Create ZIP archive using PowerShell
echo Creating ZIP archive %ZIP_NAME%...
powershell -command "& {Add-Type -A 'System.IO.Compression.FileSystem'; [IO.Compression.ZipFile]::CreateFromDirectory('%PACKAGE_DIR%', '%ZIP_NAME%');}"

if %ERRORLEVEL% neq 0 (
    echo Failed to create ZIP archive.
    pause
    exit /b 1
)

echo.
echo ZIP package created successfully: %ZIP_NAME%
echo You can distribute this file to your users.
pause 