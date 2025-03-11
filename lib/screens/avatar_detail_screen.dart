import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/avatar.dart';
import '../providers/avatar_provider.dart';
import '../widgets/audio_uploader.dart';
import '../screens/avatar_edit_screen.dart';
import '../widgets/bulk_audio_uploader.dart';

class AvatarDetailScreen extends StatelessWidget {
  final String avatarId;

  const AvatarDetailScreen({super.key, required this.avatarId});

  @override
  Widget build(BuildContext context) {
    return Consumer<AvatarProvider>(
      builder: (context, avatarProvider, child) {
        final avatar = avatarProvider.avatars.firstWhere(
          (a) => a.id == avatarId,
          orElse: () => throw Exception('Avatar not found'),
        );

        // Get the color from the avatar
        final color = _getColorFromString(avatar.color);
        final theme = Theme.of(context);
        final isDarkMode = theme.brightness == Brightness.dark;

        return Scaffold(
          backgroundColor: theme.colorScheme.surface,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar.large(
                title: Text(
                  avatar.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w300,
                    fontSize: 28,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                centerTitle: false,
                floating: true,
                expandedHeight: 140,
                backgroundColor: theme.colorScheme.surface,
                foregroundColor: theme.colorScheme.onSurface,
                leading: IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    color: theme.colorScheme.onSurface,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                actions: [
                  IconButton(
                    icon: Icon(Icons.edit, color: theme.colorScheme.onSurface),
                    onPressed: () => _showEditDialog(context, avatar),
                    tooltip: 'Edit Avatar',
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      color: theme.colorScheme.error,
                    ),
                    onPressed: () => _showDeleteDialog(context, avatar),
                    tooltip: 'Delete Avatar',
                  ),
                ],
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar header with icon
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              color,
                              isDarkMode
                                  ? color.withOpacity(0.7)
                                  : color.withOpacity(0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(isDarkMode ? 0.3 : 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Avatar icon
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Icon(
                                  avatar.icon,
                                  size: 36,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Avatar info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    avatar.name,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${avatar.voices.length} voices',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Section title
                      Text(
                        'VOICES',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Divider
                      Divider(
                        color:
                            isDarkMode
                                ? theme.colorScheme.outline
                                : Colors.grey.shade200,
                        height: 1,
                      ),
                      const SizedBox(height: 16),

                      // Voice collection header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Voice Collection',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[800],
                            ),
                          ),
                          if (avatar.voices.isNotEmpty)
                            TextButton.icon(
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Add Voice'),
                              onPressed:
                                  () => _showAddVoiceBottomSheet(
                                    context,
                                    avatarProvider,
                                    avatarId,
                                  ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Voice collection
                      if (avatar.voices.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 32.0),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.music_note,
                                  size: 64,
                                  color:
                                      isDarkMode
                                          ? theme.colorScheme.onSurfaceVariant
                                              .withOpacity(0.5)
                                          : Colors.grey.shade300,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No voices yet',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Add your first voice sample below',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: avatar.voices.length,
                          itemBuilder: (context, index) {
                            final voice = avatar.voices[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: isDarkMode ? 2 : 1,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side:
                                    isDarkMode
                                        ? BorderSide(
                                          color: theme.colorScheme.outline,
                                          width: 0.5,
                                        )
                                        : BorderSide.none,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Voice name and category
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                voice.name,
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w600,
                                                  color:
                                                      theme
                                                          .colorScheme
                                                          .onSurface,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: color.withOpacity(
                                                    isDarkMode ? 0.2 : 0.1,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  voice.category,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: color,
                  ),
                ),
              ),
            ],
          ),
                                        ),
                                        // Delete button
                                        IconButton(
                                          icon: Icon(
                                            Icons.delete_outline,
                                            color: theme.colorScheme.error,
                                            size: 20,
                                          ),
                    onPressed:
                                              () => _showDeleteVoiceDialog(
                          context,
                                                avatar,
                                                voice,
                                              ),
                                          tooltip: 'Delete Voice',
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    // Audio player
                                    Row(
        children: [
                                        IconButton(
                                          icon: Icon(
                                            Icons.play_circle_outline,
                                            size: 24,
                                            color:
                                                theme
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                          ),
                                          onPressed:
                                              () => _playVoice(
                                                context,
                                                voice.audioUrl,
                                              ),
                                        ),
                                      ],
          ),
          const SizedBox(height: 8),
                                    // Voice stats
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        // Duration
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.timer_outlined,
                                              size: 14,
                                              color:
                                                  theme
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                            ),
                                            const SizedBox(width: 4),
          Text(
                                              _formatDuration(voice.duration),
                                              style: TextStyle(
                                                fontSize: 12,
                                                color:
                                                    theme
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                              ),
          ),
        ],
      ),
                                        // Play count
                                        Row(
      children: [
                                            Icon(
                                              Icons.play_circle_outline,
                                              size: 14,
                                              color:
                                                  theme
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${voice.playCount} ${voice.playCount == 1 ? 'play' : 'plays'}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color:
                                                    theme
                                                        .colorScheme
                                                        .onSurfaceVariant,
                ),
              ),
            ],
          ),
                                        // Last played
                                        if (voice.lastPlayed != null)
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.history,
                                                size: 14,
                                                color:
                                                    theme
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                _formatDate(voice.lastPlayed!),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color:
                                                      theme
                                                          .colorScheme
                                                          .onSurfaceVariant,
                                                ),
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed:
                () =>
                    _showAddVoiceBottomSheet(context, avatarProvider, avatarId),
            tooltip: 'Add Voice',
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            elevation: isDarkMode ? 4 : 2,
            child: const Icon(Icons.add),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        );
      },
    );
  }

  // Show add voice bottom sheet
  void _showAddVoiceBottomSheet(
    BuildContext context,
    AvatarProvider avatarProvider,
    String avatarId,
  ) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final avatar = avatarProvider.avatars.firstWhere((a) => a.id == avatarId);
    final avatarColor = _getColorFromString(avatar.color);
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 600;
    final hasVoices = avatar.voices.isNotEmpty;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: theme.colorScheme.surface,
      constraints: BoxConstraints(
        maxHeight:
            isMobile
                ? screenSize.height *
                    0.9 // 90% of screen height on mobile
                : screenSize.height * 0.7, // 70% on larger screens
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: Container(
                    padding: EdgeInsets.all(isMobile ? 16 : 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Add New Voice',
                              style: TextStyle(
                                fontSize: isMobile ? 18 : 20,
                                fontWeight: FontWeight.w500,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            Row(
                              children: [
                                // Delete All Voices button - only show if there are voices
                                if (hasVoices)
                                  IconButton(
                                    icon: Icon(
                                      Icons.delete_sweep,
                                      color: theme.colorScheme.error,
                                    ),
                                    onPressed:
                                        () => _showDeleteAllVoicesDialog(
                                          context,
                                          avatar,
                                        ),
                                    tooltip: 'Delete All Voices',
                                  ),
                                // Close button
                            IconButton(
                                  icon: Icon(
                                    Icons.close,
                                    color: theme.colorScheme.onSurface,
                                  ),
                              onPressed: () => Navigator.pop(context),
                              tooltip: 'Close',
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Tab selection
                        Expanded(
                          child: DefaultTabController(
                          length: 2,
                          child: Column(
                            children: [
                              TabBar(
                                tabs: const [
                                  Tab(text: 'SINGLE UPLOAD'),
                                  Tab(text: 'BULK UPLOAD'),
                                ],
                                  labelColor: theme.colorScheme.onSurface,
                                  unselectedLabelColor:
                                      theme.colorScheme.onSurfaceVariant,
                                  indicatorColor: avatarColor,
                                  dividerColor:
                                      isDarkMode
                                          ? theme.colorScheme.outline
                                          : null,
                              ),
                              const SizedBox(height: 16),
                                Expanded(
                                child: TabBarView(
                                  children: [
                                    // Single upload tab
                                    SingleChildScrollView(
                                      child: AudioUploader(
                                          onUpload: (
                                            name,
                                            audioPath,
                                            duration,
                                          ) {
                                          final voice = Voice(
                                            name: name,
                                            audioUrl: audioPath,
                                            duration: duration,
                                          );
                                          avatarProvider.addVoiceToAvatar(
                                            avatarId,
                                            voice,
                                          );
                                          Navigator.pop(context);
                                        },
                                      ),
                                    ),

                                    // Bulk upload tab
                                    SingleChildScrollView(
                                      child: BulkAudioUploader(
                                          avatarColor: avatar.color,
                                        onUpload: (voices) {
                                          for (final voice in voices) {
                                            avatarProvider.addVoiceToAvatar(
                                              avatarId,
                                              voice,
                                            );
                                          }
                                          Navigator.pop(context);
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ),
    );
  }

  // Show edit avatar dialog
  Future<void> _showEditDialog(BuildContext context, Avatar avatar) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => AvatarEditScreen(avatar: avatar)),
    );
  }

  // Format duration
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  // Format date
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }

  // Get color from string
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

  Future<void> _showDeleteDialog(BuildContext context, Avatar avatar) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text(
              'Delete Avatar',
              style: TextStyle(fontWeight: FontWeight.w300),
            ),
            content: Text(
              'Are you sure you want to delete "${avatar.name}"? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirmed == true && context.mounted) {
      try {
        // Get the avatar provider before navigation
        final avatarProvider = context.read<AvatarProvider>();
        final avatarName = avatar.name; // Store name for later use

      // First navigate back to the home screen
        Navigator.of(context).pop();

        // Wait a moment for navigation to complete
        await Future.delayed(const Duration(milliseconds: 100));

        // Then remove the avatar (this happens asynchronously)
        if (context.mounted) {
          // Show a snackbar on the home screen to indicate deletion is in progress
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text('Deleting "$avatarName"...'),
                ],
              ),
              duration: const Duration(seconds: 10),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }

        // Remove the avatar (this happens asynchronously now)
        await avatarProvider.removeAvatar(avatarId);

        // Show a confirmation message if context is still valid
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).clearSnackBars(); // Clear the "in progress" snackbar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Avatar "$avatarName" has been deleted.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        // If we're still mounted, show an error message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting avatar: ${e.toString()}'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _showDeleteVoiceDialog(
    BuildContext context,
    Avatar avatar,
    Voice voice,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text(
              'Delete Voice',
              style: TextStyle(fontWeight: FontWeight.w300),
            ),
            content: Text(
              'Are you sure you want to delete "${voice.name}"? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirmed == true && context.mounted) {
      // Remove the voice without navigating away
      context.read<AvatarProvider>().removeVoiceFromAvatar(avatar.id, voice.id);

      // Show a confirmation message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Voice "${voice.name}" has been deleted.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _playVoice(BuildContext context, String audioUrl) {
    // Implementation of _playVoice method
  }

  // Show dialog to confirm deletion of all voices
  Future<void> _showDeleteAllVoicesDialog(
    BuildContext context,
    Avatar avatar,
  ) async {
    final theme = Theme.of(context);
    final voiceCount = avatar.voices.length;

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text(
              'Delete All Voices',
              style: TextStyle(fontWeight: FontWeight.w300),
            ),
            content: Text(
              'Are you sure you want to delete all $voiceCount voices from "${avatar.name}"? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                ),
                child: const Text('Delete All'),
              ),
            ],
          ),
    );

    if (confirmed == true && context.mounted) {
      // Close the bottom sheet
      Navigator.of(context).pop();

      // Remove all voices from the avatar
      final avatarProvider = Provider.of<AvatarProvider>(
        context,
        listen: false,
      );
      avatarProvider.removeAllVoicesFromAvatar(avatar.id);

      // Show a confirmation message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'All voices have been deleted from "${avatar.name}".',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
