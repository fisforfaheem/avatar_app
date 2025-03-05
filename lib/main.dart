import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'providers/avatar_provider.dart';
import 'widgets/avatar_grid.dart';
import 'screens/avatar_detail_screen.dart';
import 'screens/add_avatar_screen.dart';

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
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar.large(
                title: const Text(
                  'Voice Avatars',
                  style: TextStyle(
                    fontWeight: FontWeight.w300,
                    fontSize: 32,
                  ),
                ),
                centerTitle: false,
                floating: true,
                expandedHeight: 140,
                backgroundColor: Theme.of(context).colorScheme.surface,
                actions: const [
                  // IconButton(
                  //   icon: const Icon(Icons.info_outline),
                  //   onPressed: () => _showInfoDialog(context),
                  //   tooltip: 'About Voice Avatars',
                  // ),
                ],
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Hero text with gradient
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.8),
                              Theme.of(context)
                                  .colorScheme
                                  .secondary
                                  .withOpacity(0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Create Your Voice Collection',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w300,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Personalize your digital avatars with unique voices. Record, organize, and manage your voice collection with ease.',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                            const SizedBox(height: 16),
                            FilledButton.tonal(
                              onPressed: () => _showAddAvatarDialog(context),
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.white.withOpacity(0.2),
                                foregroundColor: Colors.white,
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.add),
                                  SizedBox(width: 8),
                                  Text('Create New Avatar'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Stats section
                      if (avatarProvider.avatars.isNotEmpty) ...[
                        _buildStatsSection(avatarProvider),
                        const SizedBox(height: 24),
                      ],

                      // Your Avatars section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Your Avatars',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (avatarProvider.avatars.isNotEmpty)
                            TextButton.icon(
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Add New'),
                              onPressed: () => _showAddAvatarDialog(context),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Avatar grid - Wrap in a SizedBox with a minimum height to ensure it has a size during initial rendering
                      avatarProvider.avatars.isEmpty
                          ? _buildEmptyState(context)
                          : SizedBox(
                              // Ensure the grid has a minimum height
                              width: double.infinity,
                              child: AvatarGrid(
                                avatars: avatarProvider.avatars,
                                onAddAvatar: () =>
                                    _showAddAvatarDialog(context),
                              ),
                            ),

                      // Add some bottom padding to ensure there's space below the grid
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ],
          ),
          floatingActionButton: avatarProvider.avatars.isEmpty
              ? FloatingActionButton.extended(
                  onPressed: () => _showAddAvatarDialog(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Create Avatar'),
                )
              : FloatingActionButton(
                  onPressed: () => _showAddAvatarDialog(context),
                  child: const Icon(Icons.add),
                ),
        );
      },
    );
  }

  // Build stats section
  Widget _buildStatsSection(AvatarProvider provider) {
    final totalAvatars = provider.avatars.length;
    final totalVoices = provider.avatars.fold<int>(
      0,
      (sum, avatar) => sum + avatar.voices.length,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _buildStatItem(
            icon: Icons.face,
            value: totalAvatars.toString(),
            label: 'Avatars',
          ),
          const SizedBox(width: 16),
          _buildStatItem(
            icon: Icons.mic,
            value: totalVoices.toString(),
            label: 'Voices',
          ),
        ],
      ),
    );
  }

  // Build individual stat item
  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade300,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.grey.shade700),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Build empty state
  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 2,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.face_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          const Text(
            'No Avatars Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first avatar to start building your voice collection',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _showAddAvatarDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Create Your First Avatar'),
          ),
        ],
      ),
    );
  }

  // Show info dialog
  Future<void> _showInfoDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text(
          'About Voice Avatars',
          style: TextStyle(fontWeight: FontWeight.w300),
        ),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Voice Avatars lets you create and manage unique voice collections for your digital personas.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              Text(
                'Features:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text('• Create multiple avatars with custom icons and colors'),
              Text('• Record and organize voice samples for each avatar'),
              Text('• Easily manage and edit your voice collection'),
              Text('• Personalize your digital presence with unique voices'),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddAvatarDialog(BuildContext context) async {
    // Navigate to a dedicated screen instead of showing a dialog
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AddAvatarScreen(),
      ),
    );

    if (result != null && result['name'].isNotEmpty && context.mounted) {
      final avatarProvider =
          Provider.of<AvatarProvider>(context, listen: false);
      avatarProvider.addAvatar(
        result['name'],
        icon: result['icon'],
        color: result['color'],
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Avatar "${result['name']}" has been created successfully.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Helper function to get color from string
  Color _getColorFromString(String colorName) {
    switch (colorName) {
      case 'blue':
        return const Color(0xFF007AFF); // iOS blue
      case 'purple':
        return const Color(0xFF5856D6); // iOS purple
      case 'pink':
        return const Color(0xFFFF2D55); // iOS pink
      case 'orange':
        return const Color(0xFFFF9500); // iOS orange
      case 'green':
        return const Color(0xFF34C759); // iOS green
      case 'teal':
        return const Color(0xFF5AC8FA); // iOS teal
      case 'red':
        return const Color(0xFFFF3B30); // iOS red
      case 'amber':
        return const Color(0xFFFFCC00); // iOS yellow
      case 'indigo':
        return const Color(0xFF5E5CE6); // iOS indigo
      case 'cyan':
        return const Color(0xFF32ADE6); // iOS cyan
      default:
        return const Color(0xFF007AFF); // Default to iOS blue
    }
  }
}
