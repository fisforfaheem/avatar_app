import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/avatar_provider.dart';
import '../widgets/avatar_grid.dart';

class AvatarsScreen extends StatelessWidget {
  const AvatarsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions for responsive layout
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;

    return Consumer<AvatarProvider>(
      builder: (context, avatarProvider, child) {
        return Scaffold(
          appBar: !isDesktop
              ? AppBar(
                  title: const Text('Your Avatars'),
                  centerTitle: false,
                )
              : null,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: EdgeInsets.all(isDesktop ? 24.0 : 16.0),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header section
                      if (isDesktop) ...[
                        const Text(
                          'Your Avatars',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Manage and customize your digital voice personas',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],

                      // Avatar grid
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'All Avatars (${avatarProvider.avatars.length})',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          FilledButton.icon(
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('New Avatar'),
                            onPressed: () => _showAddAvatarDialog(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Avatar grid
                      avatarProvider.avatars.isEmpty
                          ? _buildEmptyState(context)
                          : SizedBox(
                              width: double.infinity,
                              child: AvatarGrid(
                                avatars: avatarProvider.avatars,
                                onAddAvatar: () =>
                                    _showAddAvatarDialog(context),
                              ),
                            ),

                      // Add some bottom padding
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Show FAB only on mobile
          floatingActionButton: !isDesktop
              ? FloatingActionButton(
                  onPressed: () => _showAddAvatarDialog(context),
                  child: const Icon(Icons.add),
                )
              : null,
        );
      },
    );
  }

  // Build empty state when no avatars exist
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Icon(
            Icons.face_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 24),
          Text(
            'No Avatars Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Create your first avatar to get started',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: () => _showAddAvatarDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Create New Avatar'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Show dialog to add a new avatar
  void _showAddAvatarDialog(BuildContext context) {
    Navigator.pushNamed(context, '/add-avatar');
  }
}
