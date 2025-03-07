import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/avatar.dart';
import '../providers/avatar_provider.dart';
import '../widgets/audio_uploader.dart';
import '../widgets/audio_player.dart';
import '../screens/avatar_edit_screen.dart';
import '../widgets/bulk_audio_uploader.dart';

class AvatarDetailScreen extends StatelessWidget {
  final String avatarId;

  const AvatarDetailScreen({
    super.key,
    required this.avatarId,
  });

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

        return Scaffold(
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar.large(
                title: Text(
                  avatar.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w300,
                    fontSize: 28,
                  ),
                ),
                centerTitle: false,
                floating: true,
                expandedHeight: 140,
                backgroundColor: Theme.of(context).colorScheme.surface,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _showEditDialog(context, avatar),
                    tooltip: 'Edit Avatar',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
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
                              color.withOpacity(0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
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
                                      fontWeight: FontWeight.w300,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${avatar.voices.length} ${avatar.voices.length == 1 ? 'voice' : 'voices'} in collection',
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
                              onPressed: () => _showAddVoiceBottomSheet(
                                  context, avatarProvider, avatarId),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Voice collection content
                      if (avatar.voices.isEmpty)
                        _buildEmptyVoiceState(context, avatarProvider, avatarId)
                      else
                        _buildVoiceList(context, avatar, avatarProvider),
                    ],
                  ),
                ),
              ),
            ],
          ),
          floatingActionButton: avatar.voices.isNotEmpty
              ? FloatingActionButton(
                  onPressed: () => _showAddVoiceBottomSheet(
                      context, avatarProvider, avatarId),
                  child: const Icon(Icons.add),
                )
              : null,
        );
      },
    );
  }

  // Build empty voice state widget
  Widget _buildEmptyVoiceState(
      BuildContext context, AvatarProvider avatarProvider, String avatarId) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.mic_none,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'No voices yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first voice recording to get started',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () =>
                _showAddVoiceBottomSheet(context, avatarProvider, avatarId),
            icon: const Icon(Icons.add),
            label: const Text('Add Your First Voice'),
          ),
        ],
      ),
    );
  }

  // Build voice list widget
  Widget _buildVoiceList(
      BuildContext context, Avatar avatar, AvatarProvider avatarProvider) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: avatar.voices.length,
      itemBuilder: (context, index) {
        final voice = avatar.voices[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ExpansionTile(
            title: Text(
              voice.name,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ),
            subtitle: Text(
              'Added ${_formatDate(voice.createdAt)}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            leading: CircleAvatar(
              backgroundColor:
                  _getColorFromString(avatar.color).withOpacity(0.2),
              child: Icon(
                Icons.mic,
                color: _getColorFromString(avatar.color),
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete Voice',
              onPressed: () {
                avatarProvider.removeVoiceFromAvatar(
                  avatarId,
                  voice.id,
                );
              },
            ),
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: VoicePlayer(
                  audioPath: voice.audioUrl,
                  duration: voice.duration,
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  // Show add voice bottom sheet
  void _showAddVoiceBottomSheet(
      BuildContext context, AvatarProvider avatarProvider, String avatarId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Add New Voice',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                      tooltip: 'Close',
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Tab selection
                DefaultTabController(
                  length: 2,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TabBar(
                        tabs: const [
                          Tab(text: 'SINGLE UPLOAD'),
                          Tab(text: 'BULK UPLOAD'),
                        ],
                        labelColor: Colors.black87,
                        unselectedLabelColor: Colors.black54,
                        indicatorColor: _getColorFromString(
                          avatarProvider.avatars
                              .firstWhere((a) => a.id == avatarId)
                              .color,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 400, // Fixed height for the tab content
                        child: TabBarView(
                          children: [
                            // Single upload tab
                            SingleChildScrollView(
                              child: AudioUploader(
                                onUpload: (name, audioPath, duration) {
                                  final voice = Voice(
                                    name: name,
                                    audioUrl: audioPath,
                                    duration: duration,
                                  );
                                  avatarProvider.addVoiceToAvatar(
                                      avatarId, voice);
                                  Navigator.pop(context);
                                },
                              ),
                            ),

                            // Bulk upload tab
                            SingleChildScrollView(
                              child: BulkAudioUploader(
                                avatarColor: avatarProvider.avatars
                                    .firstWhere((a) => a.id == avatarId)
                                    .color,
                                onUpload: (voices) {
                                  for (final voice in voices) {
                                    avatarProvider.addVoiceToAvatar(
                                        avatarId, voice);
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
      MaterialPageRoute(
        builder: (context) => AvatarEditScreen(avatar: avatar),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
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
      builder: (context) => AlertDialog(
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
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      // First navigate back to the home screen
      Navigator.of(context).pop();
      // Then remove the avatar
      context.read<AvatarProvider>().removeAvatar(avatarId);
      // Show a confirmation message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Avatar "${avatar.name}" has been deleted.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
