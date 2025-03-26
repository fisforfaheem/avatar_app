# Voice Avatar Hub

A Flutter desktop application for managing voice avatars and audio recordings.

## Features

- Create and manage voice avatars
- Record and organize audio samples
- Audio routing detection 
- Cross-platform support (Windows, macOS, Linux)

## App Icon

The app includes a placeholder SVG icon located in `assets/app_icons/app_icon.svg`.

To use this icon for desktop builds:
1. Convert the SVG file to appropriate formats:
   - Windows: ICO format (replace `windows/runner/resources/app_icon.ico`)
   - macOS: ICNS format (update `macos/Runner/Assets.xcassets/AppIcon.appiconset`)
   - Linux: PNG format (various sizes)
2. For MSIX packaging, convert to PNG (256x256) and save as `assets/app_icons/app_icon_256.png`

## Development

### Setup
```
flutter pub get
```

### Run
```
flutter run
```

### Build for Windows
```
flutter build windows
```

### Create MSIX package
```
flutter pub run msix:create
```
