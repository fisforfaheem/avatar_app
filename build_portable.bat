@echo off
echo Building Voice Avatar Hub Portable App...
echo.

REM Step 1: Build Flutter web
echo [1/4] Building Flutter web app...
call flutter build web --release
if errorlevel 1 (
    echo Error building Flutter web app!
    pause
    exit /b 1
)

REM Step 2: Copy web build to electron wrapper
echo [2/4] Preparing Electron wrapper...
if not exist "electron_wrapper\web" mkdir "electron_wrapper\web"
xcopy "build\web\*" "electron_wrapper\web\" /E /Y /Q

REM Step 3: Install Electron dependencies (if needed)
echo [3/4] Installing Electron dependencies...
cd electron_wrapper
if not exist "node_modules" (
    call npm install
    if errorlevel 1 (
        echo Error installing dependencies!
        pause
        exit /b 1
    )
)

REM Step 4: Build portable executable
echo [4/4] Building portable executable...
call npm run build-portable
if errorlevel 1 (
    echo Error building portable app!
    pause
    exit /b 1
)

cd ..
echo.
echo ✅ Build complete! 
echo.
echo Portable app created in: electron_wrapper\dist\
echo.
echo Files created:
dir "electron_wrapper\dist\" /B
echo.
echo The .exe file can run on any Windows computer without installation!
pause 