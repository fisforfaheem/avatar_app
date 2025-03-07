import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'providers/avatar_provider.dart';
import 'screens/avatar_detail_screen.dart';
import 'screens/add_avatar_screen.dart';
import 'screens/avatars_screen.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize plugins
  await _initializePlugins();

  runApp(
    ChangeNotifierProvider(
      create: (_) => AvatarProvider(),
      child: const MainApp(),
    ),
  );
}

Future<void> _initializePlugins() async {
  try {
    // Initialize path_provider (skip on web)
    if (!kIsWeb) {
      await getApplicationDocumentsDirectory();
    }

    // Configure audioplayers to ensure it uses the platform thread
    if (!kIsWeb && Platform.isAndroid) {
      AudioPlayer.global.setAudioContext(AudioContext(
        android: const AudioContextAndroid(
          isSpeakerphoneOn: true,
          stayAwake: true,
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.media,
          audioFocus: AndroidAudioFocus.gain,
        ),
      ));
    } else if (!kIsWeb && Platform.isIOS) {
      AudioPlayer.global.setAudioContext(AudioContext(
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: const {
            AVAudioSessionOptions.mixWithOthers,
            AVAudioSessionOptions.duckOthers,
          },
        ),
      ));
    }

    // Initialize audioplayers
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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Voice Avatar Hub',
      theme: ThemeData(
        // Using system font for native feel across platforms
        fontFamily: '.SF Pro Display',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF007AFF), // iOS blue color
          brightness: Brightness.light,
        ),
        useMaterial3: true, // Enable Material 3 design
      ),
      onGenerateRoute: (settings) {
        if (settings.name?.startsWith('/avatar/') ?? false) {
          final avatarId = settings.name!.substring('/avatar/'.length);
          return MaterialPageRoute(
            builder: (context) => AvatarDetailScreen(avatarId: avatarId),
          );
        }
        return null;
      },
      routes: {
        '/add-avatar': (context) => const AddAvatarScreen(),
        '/avatars': (context) => const AvatarsScreen(),
      },
      home: const HomeScreen(),
    );
  }
}
