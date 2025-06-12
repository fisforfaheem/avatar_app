import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/avatar_provider.dart';
import '../widgets/avatar_grid.dart';
import 'add_avatar_screen.dart';

class AvatarsScreen extends StatelessWidget {
  const AvatarsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions for responsive layout
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;
    final isMobile = screenWidth < 600;
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Consumer<AvatarProvider>(
      builder: (context, avatarProvider, child) {
        return Scaffold(
          appBar:
              !isDesktop
                  ? AppBar(
                    title: const Text('Your Avatars'),
                    centerTitle: false,
                    elevation: isDarkMode ? 4 : 0,
                  )
                  : null,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: EdgeInsets.all(
                  isDesktop
                      ? 24.0
                      : isMobile
                      ? 12.0
                      : 16.0,
                ),
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
                            color: theme.colorScheme.onSurfaceVariant,
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
                            style: TextStyle(
                              fontSize: isMobile ? 18 : 20,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (!isMobile)
                            FilledButton.icon(
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('New Avatar'),
                              onPressed: () => _showAddAvatarDialog(context),
                            ),
                        ],
                      ),
                      SizedBox(height: isMobile ? 12 : 16),

                      // Avatar grid
                      avatarProvider.avatars.isEmpty
                          ? _buildEmptyState(context)
                          : SizedBox(
                            width: double.infinity,
                            child: AvatarGrid(
                              avatars: avatarProvider.avatars,
                              onAddAvatar: () => _showAddAvatarDialog(context),
                            ),
                          ),

                      // Add some bottom padding
                      SizedBox(height: isMobile ? 60 : 80),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Show FAB only on mobile
          floatingActionButton:
              !isDesktop
                  ? FloatingActionButton(
                    onPressed: () => _showAddAvatarDialog(context),
                    tooltip: 'Add Avatar',
                    elevation: isDarkMode ? 4 : 2,
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    child: const Icon(Icons.add),
                  )
                  : null,
        );
      },
    );
  }

  // Build empty state when no avatars exist
  Widget _buildEmptyState(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: isMobile ? 30 : 40),
          Icon(
            Icons.face_outlined,
            size: isMobile ? 60 : 80,
            color: theme.colorScheme.onSurfaceVariant.withAlpha(153),
          ),
          SizedBox(height: isMobile ? 16 : 24),
          Text(
            'No Avatars Yet',
            style: TextStyle(
              fontSize: isMobile ? 18 : 20,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: isMobile ? 8 : 12),
          Text(
            'Create your first avatar to get started',
            style: TextStyle(
              fontSize: isMobile ? 14 : 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: isMobile ? 24 : 32),
          FilledButton.icon(
            onPressed: () => _showAddAvatarDialog(context),
            icon: Icon(Icons.add, size: isMobile ? 16 : 18),
            label: Text(
              'Create New Avatar',
              style: TextStyle(fontSize: isMobile ? 14 : 16),
            ),
            style: FilledButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 24,
                vertical: isMobile ? 10 : 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Show dialog to add a new avatar
  void _showAddAvatarDialog(BuildContext context) {
    final avatarProvider = Provider.of<AvatarProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => const AddAvatarScreen(),
    ).then((result) {
      if (result != null && result['name'].isNotEmpty) {
        avatarProvider.addAvatar(
          result['name'],
          icon: result['icon'],
          color: result['color'],
        );
      }
    });
  }
}
