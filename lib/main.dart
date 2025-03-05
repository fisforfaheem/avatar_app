import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'providers/avatar_provider.dart';
import 'widgets/avatar_grid.dart';
import 'screens/avatar_detail_screen.dart';

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
    // Initialize path_provider
    await getApplicationDocumentsDirectory();

    // Initialize audioplayers
    final player = AudioPlayer();
    await player.dispose();
  } catch (e) {
    debugPrint('Error initializing plugins: $e');
  }
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AvatarProvider>(
      builder: (context, avatarProvider, child) {
        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar.large(
                title: const Text(
                  'Voice Avatars',
                  style: TextStyle(
                    fontWeight: FontWeight.w300,
                  ),
                ),
                centerTitle: false,
                floating: true,
                expandedHeight: 120,
                backgroundColor: Theme.of(context).colorScheme.surface,
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Create and manage unique voice collections for your digital avatars',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 24),
                      AvatarGrid(
                        avatars: avatarProvider.avatars,
                        onAddAvatar: () => _showAddAvatarDialog(context),
                        // Add a new avatar
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddAvatarDialog(context),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  Future<void> _showAddAvatarDialog(BuildContext context) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text(
          'Create New Avatar',
          style: TextStyle(fontWeight: FontWeight.w300),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter avatar name',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) => Navigator.of(context).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (result != null && result.trim().isNotEmpty && context.mounted) {
      context.read<AvatarProvider>().addAvatar(result.trim());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Avatar "${result.trim()}" has been created successfully.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
