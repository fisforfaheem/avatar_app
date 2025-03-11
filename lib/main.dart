import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io' show Platform, Directory;
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:flutter/semantics.dart';
import 'providers/avatar_provider.dart';
import 'providers/theme_provider.dart';
import 'config/theme_config.dart';
import 'screens/avatar_detail_screen.dart';
import 'screens/add_avatar_screen.dart';
import 'screens/avatars_screen.dart';
import 'screens/home_screen.dart';
import 'screens/avatar_edit_screen.dart';
import 'screens/settings_screen.dart';

Future<void> main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Note: If you're seeing "Failed to update ui::AXTree" errors in the console,
  // these are related to Flutter's Windows accessibility implementation and can be safely ignored.
  // They don't affect app functionality.

  // Initialize plugins
  await _initializePlugins();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AvatarProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const MainApp(),
    ),
  );
}

Future<void> _initializePlugins() async {
  try {
    // Initialize path_provider (skip on web)
    if (!kIsWeb) {
      // Get application documents directory to ensure it's created
      final appDocDir = await getApplicationDocumentsDirectory();
      debugPrint('App documents directory: ${appDocDir.path}');

      // Create audio_files directory if it doesn't exist
      final audioDir = Directory('${appDocDir.path}/audio_files');
      if (!await audioDir.exists()) {
        await audioDir.create(recursive: true);
      }
    }

    // Configure audioplayers to reduce console noise and fix threading issues
    // For audioplayers 6.3.0, we need to set the log level to minimize errors
    AudioLogger.logLevel = AudioLogLevel.error;

    // Initialize audioplayers with a dummy player to ensure proper setup
    // This helps ensure the plugin is properly initialized on the platform thread
    final player = AudioPlayer();
    await player.dispose();
  } catch (e) {
    // Log error but continue app initialization
    debugPrint('Error initializing plugins: $e');
  }
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the current theme mode from the provider
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Voice Avatar Hub',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      onGenerateRoute: (settings) {
        // Route for viewing avatar details
        if (settings.name?.startsWith('/avatar/') ?? false) {
          final avatarId = settings.name!.substring('/avatar/'.length);
          return MaterialPageRoute(
            builder: (context) => AvatarDetailScreen(avatarId: avatarId),
          );
        }

        // Route for editing avatar
        if (settings.name?.startsWith('/edit-avatar/') ?? false) {
          final avatarId = settings.name!.substring('/edit-avatar/'.length);
          // Get the avatar provider to find the avatar by ID
          final avatarProvider = Provider.of<AvatarProvider>(
            context,
            listen: false,
          );
          final avatar = avatarProvider.avatars.firstWhere(
            (a) => a.id == avatarId,
            orElse: () => throw Exception('Avatar not found'),
          );

          // Navigate to the edit screen with the avatar object
          return MaterialPageRoute(
            builder: (context) => AvatarEditScreen(avatar: avatar),
          );
        }

        return null;
      },
      routes: {
        '/add-avatar': (context) => const AddAvatarScreen(),
        '/avatars': (context) => const AvatarsScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
      home: const HomeScreen(),
    );
  }
}
