import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/avatar.dart';
import '../providers/avatar_provider.dart';
import '../widgets/audio_uploader.dart';
import '../widgets/audio_player.dart';

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

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar.large(
                title: Text(
                  avatar.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w300,
                  ),
                ),
                centerTitle: false,
                floating: true,
                expandedHeight: 120,
                backgroundColor: Theme.of(context).colorScheme.surface,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _showDeleteDialog(context, avatar),
                  ),
                ],
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Voice Collection',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w300,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${avatar.voices.length} ${avatar.voices.length == 1 ? 'voice' : 'voices'} in collection',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (avatar.voices.isEmpty)
                        Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.mic_none,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No voices yet',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Add your first voice recording to get started',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 24),
                              AudioUploader(
                                onUpload: (name, audioPath, duration) {
                                  final voice = Voice(
                                    name: name,
                                    audioUrl: audioPath,
                                    duration: duration,
                                  );
                                  avatarProvider.addVoiceToAvatar(
                                      avatarId, voice);
                                },
                              ),
                            ],
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: avatar.voices.length,
                          separatorBuilder: (context, index) => const Divider(),
                          itemBuilder: (context, index) {
                            final voice = avatar.voices[index];
                            return ListTile(
                              title: Text(voice.name),
                              subtitle: Text(
                                'Added ${_formatDate(voice.createdAt)}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                              leading: const CircleAvatar(
                                child: Icon(Icons.mic),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () {
                                      avatarProvider.removeVoiceFromAvatar(
                                        avatarId,
                                        voice.id,
                                      );
                                    },
                                  ),
                                ],
                              ),
                              onTap: () {
                                showModalBottomSheet(
                                  context: context,
                                  builder: (context) => Container(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              voice.name,
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w300,
                                              ),
                                            ),
                                            const Spacer(),
                                            IconButton(
                                              icon: const Icon(Icons.close),
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        VoicePlayer(
                                          audioPath: voice.audioUrl,
                                          duration: voice.duration,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          floatingActionButton: avatar.voices.isNotEmpty
              ? FloatingActionButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (context) => Padding(
                        padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).viewInsets.bottom,
                        ),
                        child: AudioUploader(
                          onUpload: (name, audioPath, duration) {
                            final voice = Voice(
                              name: name,
                              audioUrl: audioPath,
                              duration: duration,
                            );
                            avatarProvider.addVoiceToAvatar(avatarId, voice);
                            Navigator.pop(context);
                          },
                        ),
                      ),
                    );
                  },
                  child: const Icon(Icons.add),
                )
              : null,
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
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
      context.read<AvatarProvider>().removeAvatar(avatarId);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Avatar "${avatar.name}" has been deleted.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
