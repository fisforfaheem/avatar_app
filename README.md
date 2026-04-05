# Voice Avatar Hub

Voice Avatar Hub is a Flutter app for building small voiceboard-style avatar profiles. You can create avatars, attach custom images, upload multiple audio clips, group them, reorder them, and play them back from one place. The app stores everything locally, so there is no backend or account setup in the middle.

## Why I Built This

I wanted a simple way to keep voice clips organized by persona instead of dumping random audio files into folders. The call center routing checks were added because I also wanted a quick way to verify desktop audio setup without bouncing between different tools.

## Features

- Create avatars with a name, color, icon, and optional custom image
- Upload one or many audio files per avatar
- Organize clips by category
- Reorder clips with drag and drop
- Track recently used and most played voices
- Search voices by name or category
- Light and dark theme support
- Local persistence on desktop and mobile
- IndexedDB storage for web builds
- Windows audio routing checks for virtual cable / softphone style setups

## Tech Stack

- Flutter
- Dart
- `provider` for state management
- `shared_preferences` for app state persistence
- `path_provider` and local file storage for native platforms
- `idb_shim` for web asset storage
- `audioplayers` for playback
- Optional Electron wrapper for shipping the web build as a desktop app

## Getting Started

You need a recent Flutter SDK installed first.

```bash
git clone <repo-url>
cd avatar_app
flutter pub get
flutter run
```

A few common targets:

```bash
flutter run -d windows
flutter run -d chrome
flutter build web --release
flutter build windows
```

If you want to use the Electron wrapper:

```bash
cd electron_wrapper
npm install
npm start
```

## Project Structure

- `lib/` main app code
- `lib/models/` avatar and voice models
- `lib/providers/` app state, theme state, and audio routing state
- `lib/screens/` main screens for home, add/edit avatar, avatar detail, and settings
- `lib/widgets/` reusable UI pieces like uploaders, audio player UI, and reorderable grids
- `lib/services/` local storage and web IndexedDB handling
- `lib/utils/` platform-specific helpers
- `assets/` bundled audio and app icon assets
- `web/` Flutter web entry files
- `electron_wrapper/` Electron host for the web build

## Usage

Create an avatar first. Then add one or more audio clips to it. From there you can rename clips, group them by category, reorder them, and play them directly from the main screen.

On Windows there is also a settings section for checking audio routing. That part is meant for setups using virtual audio cable style tools or softphone apps.

## Notes

- The app is local-first. There is no server in this repo.
- Avatar data is stored in app preferences, and uploaded files are stored locally on native platforms.
- On web, binary assets are stored in IndexedDB.
- This repo no longer tracks packaged binaries or release zip files. Build those locally when you need them.
- The Electron wrapper is locked down a bit for public source use: sandboxing is enabled, external popup creation is denied, and devtools shortcuts are only exposed in development builds.

## Contributing

If you want to contribute, open an issue first or send a small PR. Bug fixes, cleanup, and UI improvements are all welcome.

## License

There is no license file in this repo yet. If I decide to keep the project public long term, I’ll add one.
