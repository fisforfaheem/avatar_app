# Create a ZIP file of the dist folder
$appName = "Voice_Avatar_Hub"
$version = "1.0.0"
$zipFileName = "$appName-$version.zip"

Write-Host "Creating ZIP package for distribution..."

# Check if the dist folder exists
if (-not (Test-Path -Path "dist")) {
    Write-Host "Error: dist folder not found. Please run create_windows_package.bat first."
    exit 1
}

# Create the ZIP file
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::CreateFromDirectory("$PWD\dist", "$PWD\$zipFileName")

Write-Host "ZIP package created successfully: $zipFileName"
Write-Host "You can distribute this ZIP file to your users." 