@echo off
echo Creating Voice Avatar Hub Windows Release Package...

set RELEASE_DIR=build\windows\x64\runner\Release
set PACKAGE_DIR=release_package

:: Create package directory
mkdir %PACKAGE_DIR%
echo Created package directory: %PACKAGE_DIR%

:: Copy all files from the Release directory to the package directory
xcopy /E /I /Y %RELEASE_DIR%\* %PACKAGE_DIR%\
echo Copied release files to package directory

:: Create a README file
echo Creating README file...
echo Voice Avatar Hub > %PACKAGE_DIR%\README.txt
echo ================ >> %PACKAGE_DIR%\README.txt
echo. >> %PACKAGE_DIR%\README.txt
echo Installation Instructions: >> %PACKAGE_DIR%\README.txt
echo 1. Extract all files to a folder of your choice >> %PACKAGE_DIR%\README.txt
echo 2. Run avatar_app.exe to start the application >> %PACKAGE_DIR%\README.txt
echo. >> %PACKAGE_DIR%\README.txt
echo Note: All files must be kept together in the same folder. >> %PACKAGE_DIR%\README.txt

echo Package created successfully in the '%PACKAGE_DIR%' folder.
echo You can distribute this folder or create a ZIP archive from it.
pause 