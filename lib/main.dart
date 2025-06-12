// Hey there! 👋 Welcome to the main entry point of our Voice Avatar Hub!
// This is where the magic begins when you launch the app. ✨
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io' show Platform, Directory;
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:window_manager/window_manager.dart';
import 'providers/avatar_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/audio_routing_provider.dart';
import 'config/theme_config.dart';
import 'screens/avatar_detail_screen.dart';
import 'screens/add_avatar_screen.dart';
import 'screens/avatars_screen.dart';
import 'screens/home_screen.dart';
import 'screens/avatar_edit_screen.dart';
import 'screens/settings_screen.dart';

// The main function - the very first thing that runs! 🚀
Future<void> main() async {
  // Flutter needs its engine initialized before we can do much. Think of it like warming up the car. 🚗
  WidgetsFlutterBinding.ensureInitialized();

  // Setting up the window for desktop users (Windows, Mac, Linux). We don't need this for web.
  // This makes sure the app window looks and behaves nicely on a computer.
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    // Make sure the window manager is ready to go.
    await windowManager.ensureInitialized();

    // Define how our app window should look and feel.
    // Size, centering, title, minimum size - all the good stuff!
    WindowOptions windowOptions = const WindowOptions(
      size: Size(1280, 720), // Default size when the app opens.
      center: true, // Start the window in the center of the screen.
      backgroundColor:
          Colors.transparent, // Allows for cool transparency effects if needed.
      skipTaskbar: false, // Show the app in the taskbar/dock.
      titleBarStyle: TitleBarStyle.normal, // Use the standard OS title bar.
      title: "Voice Avatar Hub", // The name displayed in the window title.
      minimumSize: Size(
        800,
        600,
      ), // Smallest size the user can resize the window to.
    );

    // Wait until the window is actually ready to be shown, then show and focus it.
    // This prevents a jarring flash of an unstyled window. ✨
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  // --- Quick Note for Developers ---
  // If you see strange "Failed to update ui::AXTree" errors in your console,
  // especially on Windows, don't panic! 😅
  // These are usually related to Flutter's accessibility features and generally
  // don't break anything important in the app. You can usually ignore them.
  // --- End Note ---

  // Initialize some essential plugins we need.
  // We wrap this in a function to keep `main` cleaner.
  await _initializePlugins();

  // Time to actually run the app! We wrap our main app widget (`MainApp`)
  // with `MultiProvider`. This is like giving our app superpowers! 💪
  // It lets different parts of the app access shared data and services easily.
  runApp(
    MultiProvider(
      providers: [
        // The AvatarProvider manages all the voice avatar data.
        ChangeNotifierProvider(create: (_) => AvatarProvider()),
        // The ThemeProvider handles switching between light and dark mode. 🌙☀️
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        // The AudioRoutingProvider deals with where the audio plays. 🎧🔊
        ChangeNotifierProvider(create: (_) => AudioRoutingProvider()),
      ],
      // The actual root widget of our application UI.
      child: const MainApp(),
    ),
  );
}

// Helper function to initialize plugins needed by the app.
// Keeps the `main` function tidy! ✨
Future<void> _initializePlugins() async {
  try {
    // We need path_provider to know where to store files on the device.
    // Doesn't make sense on the web, so we skip it there.
    if (!kIsWeb) {
      // Get the standard directory for app documents.
      final appDocDir = await getApplicationDocumentsDirectory();
      if (kDebugMode) {
        // Little debug message to see where files are being stored. Handy! 📁
        print('App documents directory: ${appDocDir.path}');
      }

      // We need a specific folder to store our audio files. Let's make sure it exists.
      // On web, we don't use the file system for this, so we skip it.
      if (!kIsWeb) {
        final audioDir = Directory('${appDocDir.path}/audio_files');
        if (!await audioDir.exists()) {
          // If the folder isn't there, create it!
          await audioDir.create(
            recursive: true,
          ); // `recursive: true` creates parent dirs if needed.
        }
      }
    }

    // Configure the audioplayers plugin.
    // Setting the log level helps reduce noisy output in the console, especially some harmless errors.
    AudioLogger.logLevel = AudioLogLevel.error; // Only show serious errors.

    // Sometimes, initializing a dummy player helps ensure the audio system
    // is fully ready, especially regarding platform threading. Bit of a quirk, but it works!
    final player = AudioPlayer();
    await player
        .dispose(); // We don't actually need this player, so get rid of it.
  } catch (e) {
    // Uh oh, something went wrong during plugin initialization. 😱
    // Let's log the error so we can investigate, but let the app try to continue anyway.
    if (kDebugMode) {
      print('Error initializing plugins: $e');
    }
    // In a real production app, you might want more robust error handling here.
  }
}

// This is the main application widget - the root of our UI tree. 🌳
class MainApp extends StatelessWidget {
  // Constructor - nothing fancy here, just passing the key.
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Grab the ThemeProvider so we know whether to use light or dark mode.
    // `Provider.of<ThemeProvider>(context)` is how we access the providers we set up earlier.
    final themeProvider = Provider.of<ThemeProvider>(context);

    // The MaterialApp is the core widget that sets up navigation, themes, etc.
    return MaterialApp(
      // Hides the little "Debug" banner in the top-right corner.
      debugShowCheckedModeBanner: false,
      // The title of the application (often used by the OS).
      title: 'Voice Avatar Hub',
      // Define the light theme (from our config file).
      theme: AppTheme.lightTheme,
      // Define the dark theme (from our config file).
      darkTheme: AppTheme.darkTheme,
      // Tell MaterialApp which theme mode to use based on the ThemeProvider's state.
      themeMode: themeProvider.themeMode,

      // --- Navigation Logic ---
      // `onGenerateRoute` handles routes that aren't explicitly defined in `routes`.
      // This is perfect for dynamic routes like showing details for a specific avatar.
      onGenerateRoute: (settings) {
        // Check if the requested route path looks like '/avatar/<some_id>'.
        if (settings.name?.startsWith('/avatar/') ?? false) {
          // Extract the avatar ID from the route path.
          final avatarId = settings.name!.substring('/avatar/'.length);
          // Create and return the route for the AvatarDetailScreen, passing the ID.
          return MaterialPageRoute(
            builder: (context) => AvatarDetailScreen(avatarId: avatarId),
          );
        }

        // Check if the requested route path looks like '/edit-avatar/<some_id>'.
        if (settings.name?.startsWith('/edit-avatar/') ?? false) {
          // Extract the avatar ID.
          final avatarId = settings.name!.substring('/edit-avatar/'.length);
          // We need the actual Avatar object to pass to the edit screen.
          // Get the AvatarProvider (using `listen: false` because we only need it once here).
          final avatarProvider = Provider.of<AvatarProvider>(
            context,
            listen:
                false, // Important: Prevents unnecessary widget rebuilds here.
          );
          // Find the avatar in the provider's list using the ID.
          final avatar = avatarProvider.avatars.firstWhere(
            (a) => a.id == avatarId,
            // If the avatar isn't found (e.g., bad URL), throw an error.
            // In a real app, you might redirect to an error page.
            orElse:
                () =>
                    throw Exception('Avatar not found for ID: $avatarId 🤷‍♂️'),
          );

          // Create and return the route for the AvatarEditScreen, passing the found avatar.
          return MaterialPageRoute(
            builder: (context) => AvatarEditScreen(avatar: avatar),
          );
        }

        // If the route didn't match any of our dynamic patterns, return null.
        // Flutter will then check the `routes` map.
        return null;
      },

      // `routes` defines the standard, named routes for our app.
      // Easier for simple navigation between main screens.
      routes: {
        // Route to the screen for adding a new avatar.
        '/add-avatar': (context) => const AddAvatarScreen(),
        // Route to the screen showing the list/grid of avatars.
        '/avatars': (context) => const AvatarsScreen(),
        // Route to the settings screen. ⚙️
        '/settings': (context) => const SettingsScreen(),
        // Note: '/' (the home route) is handled by the `home` property below.
      },

      // The default screen to show when the app starts.
      home: const HomeScreen(),
    );
  }
}
