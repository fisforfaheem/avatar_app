import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import '../providers/avatar_provider.dart';
import '../providers/theme_provider.dart';
import '../models/avatar.dart';
import '../widgets/reorderable_voice_grid.dart';
import 'add_avatar_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Audio player instance
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _currentlyPlayingVoiceId;
  StreamSubscription? _playerStateSubscription;

  @override
  void initState() {
    super.initState();

    // Set up player state listener with error handling
    _setupPlayerStateListener();
  }

  void _setupPlayerStateListener() {
    // Cancel any existing subscription first
    _playerStateSubscription?.cancel();

    // Listen for player state changes to update UI when playback completes
    _playerStateSubscription = _audioPlayer.onPlayerStateChanged.listen(
      (state) {
        if (state == PlayerState.completed && mounted) {
          setState(() {
            _currentlyPlayingVoiceId = null;
          });
        }
      },
      onError: (error) {
        debugPrint('Player state stream error: $error');
      },
    );
  }

  @override
  void dispose() {
    // Cancel subscription first
    _playerStateSubscription?.cancel();

    // Use try-catch to handle any errors during disposal
    try {
      _audioPlayer.dispose();
    } catch (e) {
      debugPrint('Error disposing audio player: $e');
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Consumer2<AvatarProvider, ThemeProvider>(
      builder: (context, avatarProvider, themeProvider, child) {
        final recentVoices = avatarProvider.getRecentlyUsedVoices(limit: 3);
        final popularVoices = avatarProvider.getMostUsedVoices(limit: 3);
        final isDeletingAvatar = avatarProvider.isDeletingAvatar;
        final theme = Theme.of(context);
        final isDarkMode = theme.brightness == Brightness.dark;

        return Scaffold(
          backgroundColor: theme.colorScheme.surface,
          appBar: AppBar(
            title: Text(
              'VOICE AVATAR HUB',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                fontSize: isMobile ? 16 : 18,
                color: theme.colorScheme.onSurface,
              ),
            ),
            centerTitle: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            foregroundColor: theme.colorScheme.onSurface,
            actions: [
              // Add Avatar button
              if (!isDeletingAvatar)
                _AnimatedIconButton(
                  icon: Icons.add_circle_outline,
                  tooltip: 'Add New Avatar (Ctrl+N)',
                  onPressed: () => _showAddAvatarDialog(context),
                  color: theme.colorScheme.onSurface,
                  hoverColor: theme.colorScheme.primary,
                  size: isMobile ? 20 : 22,
                ),
              // Search button
              _AnimatedIconButton(
                icon: Icons.search,
                tooltip: 'Search Voices (Ctrl+F)',
                onPressed:
                    isDeletingAvatar
                        ? null
                        : () =>
                            _showGlobalSearchDialog(context, avatarProvider),
                color: theme.colorScheme.onSurface,
                hoverColor: theme.colorScheme.primary,
                size: isMobile ? 20 : 22,
                isDisabled: isDeletingAvatar,
              ),
              // Quick access button
              if (recentVoices.isNotEmpty || popularVoices.isNotEmpty)
                _AnimatedPopupMenuButton<Map<String, dynamic>>(
                  tooltip: 'Quick Access',
                  icon: Icons.access_time,
                  iconSize: isMobile ? 20 : 22,
                  color: theme.colorScheme.onSurface,
                  hoverColor: theme.colorScheme.primary,
                  enabled: !isDeletingAvatar,
                  itemBuilder: (context) {
                    List<PopupMenuEntry<Map<String, dynamic>>> items = [];

                    // Recent voices section
                    if (recentVoices.isNotEmpty) {
                      items.add(
                        const PopupMenuItem<Map<String, dynamic>>(
                          enabled: false,
                          height: 24,
                          child: Text(
                            'RECENTLY USED',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                      );

                      for (final item in recentVoices) {
                        final avatar = item['avatar'] as Avatar;
                        final voice = item['voice'] as Voice;
                        final avatarColor = _getColorFromString(avatar.color);

                        items.add(
                          PopupMenuItem<Map<String, dynamic>>(
                            value: item,
                            height: 40,
                            child: Row(
                              children: [
                                Icon(avatar.icon, size: 16, color: avatarColor),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    voice.name,
                                    style: const TextStyle(fontSize: 14),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      // Add divider if we have both recent and popular
                      if (popularVoices.isNotEmpty) {
                        items.add(const PopupMenuDivider());
                      }
                    }

                    // Popular voices section
                    if (popularVoices.isNotEmpty) {
                      items.add(
                        const PopupMenuItem<Map<String, dynamic>>(
                          enabled: false,
                          height: 24,
                          child: Text(
                            'MOST USED',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                      );

                      for (final item in popularVoices) {
                        final avatar = item['avatar'] as Avatar;
                        final voice = item['voice'] as Voice;
                        final avatarColor = _getColorFromString(avatar.color);

                        items.add(
                          PopupMenuItem<Map<String, dynamic>>(
                            value: item,
                            height: 40,
                            child: Row(
                              children: [
                                _CustomBadge(
                                  label: '${voice.playCount}',
                                  child: Icon(
                                    avatar.icon,
                                    size: 16,
                                    color: avatarColor,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    voice.name,
                                    style: const TextStyle(fontSize: 14),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                    }

                    return items;
                  },
                  onSelected: (item) {
                    final voice = item['voice'] as Voice;
                    _playOrPauseVoice(voice);
                  },
                ),
              // Theme toggle button
              _AnimatedIconButton(
                icon:
                    themeProvider.themeMode == ThemeMode.light
                        ? Icons.dark_mode
                        : Icons.light_mode,
                tooltip:
                    themeProvider.themeMode == ThemeMode.light
                        ? 'Switch to Dark Mode'
                        : 'Switch to Light Mode',
                onPressed: () => _showThemeDialog(context),
                color: theme.colorScheme.onSurface,
                hoverColor: theme.colorScheme.primary,
                size: isMobile ? 18 : 20,
                useAnimatedSwitcher: true,
                switcherKey: ValueKey<ThemeMode>(themeProvider.themeMode),
              ),
              // Settings button
              _AnimatedIconButton(
                icon: Icons.settings,
                tooltip: 'Settings',
                onPressed:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsScreen(),
                      ),
                    ),
                color: theme.colorScheme.onSurface,
                hoverColor: theme.colorScheme.primary,
                size: isMobile ? 18 : 20,
              ),
              // Help button for keyboard shortcuts - hide on mobile
              if (!isMobile)
                _AnimatedIconButton(
                  icon: Icons.keyboard,
                  tooltip: 'Keyboard Shortcuts',
                  onPressed: () => _showKeyboardShortcutsDialog(context),
                  color: theme.colorScheme.onSurface,
                  hoverColor: theme.colorScheme.primary,
                  size: 20,
                ),
              // Stop button - only show when audio is playing
              if (_currentlyPlayingVoiceId != null)
                Padding(
                  padding: EdgeInsets.only(right: isMobile ? 8.0 : 12.0),
                  child: _AnimatedIconButton(
                    icon: Icons.stop_rounded,
                    tooltip: 'Stop playback (Esc)',
                    onPressed: _stopAllPlayback,
                    color: Colors.black87,
                    hoverColor: theme.colorScheme.error,
                    size: isMobile ? 18 : 20,
                    useContainer: true,
                    containerColor: Colors.black.withOpacity(0.08),
                    containerHoverColor: theme.colorScheme.errorContainer
                        .withOpacity(0.2),
                  ),
                ),
            ],
          ),
          body: Stack(
            children: [
              // Main content
              Focus(
                autofocus: true,
                onKeyEvent: (node, event) {
                  // Handle keyboard shortcuts
                  if (event is KeyDownEvent) {
                    // Escape key to stop playback
                    if (event.logicalKey == LogicalKeyboardKey.escape) {
                      _stopAllPlayback();
                      return KeyEventResult.handled;
                    }

                    // Ctrl+F to open search
                    if (event.logicalKey == LogicalKeyboardKey.keyF &&
                        (HardwareKeyboard.instance.isControlPressed ||
                            HardwareKeyboard.instance.isMetaPressed)) {
                      _showGlobalSearchDialog(context, avatarProvider);
                      return KeyEventResult.handled;
                    }

                    // Ctrl+N to create new avatar
                    if (event.logicalKey == LogicalKeyboardKey.keyN &&
                        (HardwareKeyboard.instance.isControlPressed ||
                            HardwareKeyboard.instance.isMetaPressed)) {
                      _showAddAvatarDialog(context);
                      return KeyEventResult.handled;
                    }

                    // Space to play/pause selected voice
                    if (event.logicalKey == LogicalKeyboardKey.space) {
                      // If there's a currently selected avatar, play/pause its first voice
                      if (avatarProvider.selectedAvatar != null &&
                          avatarProvider.selectedAvatar!.voices.isNotEmpty) {
                        _playOrPauseVoice(
                          avatarProvider.selectedAvatar!.voices.first,
                        );
                        return KeyEventResult.handled;
                      }
                      return KeyEventResult.ignored;
                    }

                    // Arrow keys for navigation
                    if (event.logicalKey == LogicalKeyboardKey.arrowUp ||
                        event.logicalKey == LogicalKeyboardKey.arrowDown) {
                      // Navigate between voices in the selected avatar
                      if (avatarProvider.selectedAvatar != null) {
                        // Implementation would depend on your UI structure
                        // This is a placeholder for the navigation logic
                        HapticFeedback.lightImpact();
                        return KeyEventResult.handled;
                      }
                      return KeyEventResult.ignored;
                    }

                    if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
                        event.logicalKey == LogicalKeyboardKey.arrowRight) {
                      // Navigate between avatars
                      final avatars = avatarProvider.avatars;
                      if (avatars.isNotEmpty) {
                        int currentIndex = -1;
                        if (avatarProvider.selectedAvatar != null) {
                          currentIndex = avatars.indexWhere(
                            (a) => a.id == avatarProvider.selectedAvatar!.id,
                          );
                        }

                        int newIndex;
                        if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                          // Move to previous avatar
                          newIndex =
                              currentIndex > 0
                                  ? currentIndex - 1
                                  : avatars.length - 1;
                        } else {
                          // Move to next avatar
                          newIndex = (currentIndex + 1) % avatars.length;
                        }

                        avatarProvider.setSelectedAvatar(avatars[newIndex].id);
                        HapticFeedback.lightImpact();
                        return KeyEventResult.handled;
                      }
                      return KeyEventResult.ignored;
                    }
                  }
                  return KeyEventResult.ignored;
                },
                child: SafeArea(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 12.0 : 16.0,
                    ),
                    child:
                        avatarProvider.isLoading
                            ? _buildLoadingState()
                            : avatarProvider.errorMessage != null
                            ? _buildErrorState(avatarProvider.errorMessage!)
                            : avatarProvider.avatars.isEmpty
                            ? _buildEmptyState()
                            : _buildAllAvatarsView(
                              context,
                              avatarProvider.avatars,
                            ),
                  ),
                ),
              ),

              // Deletion overlay
              if (isDeletingAvatar)
                Container(
                  color: theme.colorScheme.surface.withOpacity(0.7),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Deleting avatar...',
                          style: TextStyle(
                            fontWeight: FontWeight.w300,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Please wait, this may take a moment.',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // Build view showing all avatars with their voices
  Widget _buildAllAvatarsView(BuildContext context, List<Avatar> avatars) {
    return ListView.builder(
      itemCount: avatars.length,
      itemBuilder: (context, index) {
        return _buildAvatarWithVoices(context, avatars[index]);
      },
    );
  }

  // Build an avatar with its voices
  Widget _buildAvatarWithVoices(BuildContext context, Avatar avatar) {
    final Color avatarColor = _getColorFromString(avatar.color);
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Container(
      margin: EdgeInsets.only(bottom: isMobile ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar card with hover effect
          _HoverAnimatedContainer(
            builder:
                (context, isHovering) => Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 12 : 16,
                    vertical: isMobile ? 10 : 12,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isDarkMode
                            ? Theme.of(context).colorScheme.surface
                            : avatarColor.withOpacity(isHovering ? 0.12 : 0.08),
                    border: Border.all(
                      color:
                          isDarkMode
                              ? isHovering
                                  ? Theme.of(
                                    context,
                                  ).colorScheme.primary.withOpacity(0.5)
                                  : Theme.of(context).colorScheme.outline
                              : avatarColor.withOpacity(isHovering ? 0.4 : 0.2),
                      width: isHovering ? 2.0 : 1.5,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color:
                            isDarkMode
                                ? Colors.black.withOpacity(
                                  isHovering ? 0.3 : 0.2,
                                )
                                : avatarColor.withOpacity(
                                  isHovering ? 0.15 : 0.08,
                                ),
                        blurRadius: isHovering ? 12 : 8,
                        offset: Offset(0, isHovering ? 4 : 3),
                        spreadRadius: isHovering ? 1 : 0,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Avatar icon with animation
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(
                          begin: 0,
                          end: isHovering ? 1.0 : 0.0,
                        ),
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutBack,
                        builder: (context, value, child) {
                          return Transform.rotate(
                            angle: value * 0.05,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: EdgeInsets.all(isMobile ? 8 : 10),
                              decoration: BoxDecoration(
                                color: avatarColor.withOpacity(
                                  isDarkMode
                                      ? (isHovering ? 0.3 : 0.2)
                                      : (isHovering ? 0.25 : 0.15),
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: avatarColor.withOpacity(
                                      isHovering ? 0.2 : 0.1,
                                    ),
                                    blurRadius: isHovering ? 6 : 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                avatar.icon,
                                size: isMobile ? 20 : 24,
                                color: avatarColor,
                              ),
                            ),
                          );
                        },
                      ),
                      SizedBox(width: isMobile ? 8 : 12),

                      // Avatar name and voice count
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 200),
                              style: TextStyle(
                                fontSize: isMobile ? 14 : 16,
                                fontWeight:
                                    isHovering
                                        ? FontWeight.w800
                                        : FontWeight.w700,
                                letterSpacing: 0.5,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              child: Text(avatar.name.toUpperCase()),
                            ),
                            SizedBox(height: isMobile ? 1 : 2),
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 200),
                              style: TextStyle(
                                fontSize: isMobile ? 11 : 12,
                                fontWeight:
                                    isHovering
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                color: Theme.of(context).colorScheme.onSurface
                                    .withOpacity(isHovering ? 0.8 : 0.7),
                              ),
                              child: Text('${avatar.voices.length} voices'),
                            ),
                          ],
                        ),
                      ),

                      // Add voice button - hide text on mobile
                      _HoverButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/avatar/${avatar.id}');
                        },
                        builder:
                            (context, isButtonHovering) => Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isMobile ? 8 : 12,
                                vertical: isMobile ? 6 : 8,
                              ),
                              decoration: BoxDecoration(
                                color: avatarColor.withOpacity(
                                  isDarkMode
                                      ? (isButtonHovering ? 0.25 : 0.15)
                                      : (isButtonHovering ? 0.2 : 0.12),
                                ),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow:
                                    isButtonHovering
                                        ? [
                                          BoxShadow(
                                            color: avatarColor.withOpacity(0.2),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                        : null,
                              ),
                              child: Row(
                                children: [
                                  TweenAnimationBuilder<double>(
                                    tween: Tween<double>(
                                      begin: 0,
                                      end: isButtonHovering ? 1.0 : 0.0,
                                    ),
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeOutBack,
                                    builder: (context, value, child) {
                                      return Transform.scale(
                                        scale: 1.0 + (value * 0.2),
                                        child: Icon(
                                          Icons.add,
                                          size: isMobile ? 14 : 16,
                                          color: avatarColor,
                                        ),
                                      );
                                    },
                                  ),
                                  if (!isMobile) ...[
                                    const SizedBox(width: 4),
                                    AnimatedDefaultTextStyle(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight:
                                            isButtonHovering
                                                ? FontWeight.w700
                                                : FontWeight.w600,
                                        letterSpacing: 0.5,
                                        color: avatarColor,
                                      ),
                                      child: const Text('ADD VOICE'),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                      ),

                      // Edit avatar button
                      _HoverIconButton(
                        icon: Icons.edit_outlined,
                        size: isMobile ? 18 : 20,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                        hoverColor: Theme.of(context).colorScheme.primary,
                        tooltip: 'Edit Avatar',
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            '/edit-avatar/${avatar.id}',
                          );
                        },
                      ),
                    ],
                  ),
                ),
          ),

          // Voice list or empty message
          if (avatar.voices.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 8),
              child: Text(
                'No voices yet. Add one with the button above.',
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: ReorderableVoiceGrid(
                voices: avatar.voices,
                avatarId: avatar.id,
                avatarColor: avatarColor,
                onVoiceTap: _playOrPauseVoice,
                currentlyPlayingVoiceId: _currentlyPlayingVoiceId,
              ),
            ),
        ],
      ),
    );
  }

  // Play or pause voice
  Future<void> _playOrPauseVoice(Voice voice) async {
    try {
      if (_currentlyPlayingVoiceId == voice.id) {
        // If this voice is already playing, pause it
        await _audioPlayer.pause();
        setState(() {
          _currentlyPlayingVoiceId = null;
        });
      } else {
        // If another voice is playing, stop it first
        if (_currentlyPlayingVoiceId != null) {
          await _audioPlayer.stop();
        }

        // Play the selected voice
        await _audioPlayer.play(DeviceFileSource(voice.audioUrl));
        setState(() {
          _currentlyPlayingVoiceId = voice.id;
        });

        // Track voice usage for analytics
        // Find the avatar that contains this voice
        final avatarProvider = Provider.of<AvatarProvider>(
          context,
          listen: false,
        );
        for (final avatar in avatarProvider.avatars) {
          final voiceIndex = avatar.voices.indexWhere((v) => v.id == voice.id);
          if (voiceIndex != -1) {
            avatarProvider.trackVoiceUsage(avatar.id, voice.id);
            break;
          }
        }
      }
    } catch (e) {
      // Show error message if playback fails
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error playing audio: ${e.toString()}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Format duration
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));

    // Only show hours if needed
    if (duration.inHours > 0) {
      return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
    }
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  // Build empty state
  Widget _buildEmptyState() {
    final Color themeColor = Theme.of(context).colorScheme.primary;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: themeColor.withOpacity(0.12),
              border: Border.all(color: themeColor.withOpacity(0.25), width: 2),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: themeColor.withOpacity(0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Icon(Icons.record_voice_over, size: 72, color: themeColor),
          ),
          const SizedBox(height: 28),
          Text(
            'NO AVATARS YET',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Create your first avatar to start building your voice collection',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 36),
          ElevatedButton.icon(
            onPressed: () => _showAddAvatarDialog(context),
            icon: const Icon(Icons.add, size: 20),
            label: const Text(
              'CREATE AVATAR',
              style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.5),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: themeColor,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddAvatarDialog(BuildContext context) async {
    // Navigate to a dedicated screen instead of showing a dialog
    final result = await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const AddAvatarScreen()));

    if (result != null && result['name'].isNotEmpty && context.mounted) {
      final avatarProvider = Provider.of<AvatarProvider>(
        context,
        listen: false,
      );
      avatarProvider.addAvatar(
        result['name'],
        icon: result['icon'],
        color: result['color'],
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Avatar "${result['name']}" has been created successfully.',
          ),
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

  // Stop all audio playback
  Future<void> _stopAllPlayback() async {
    try {
      if (_currentlyPlayingVoiceId != null) {
        await _audioPlayer.stop();
        setState(() {
          _currentlyPlayingVoiceId = null;
        });
      }
    } catch (e) {
      // Show error message if stopping fails
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error stopping audio: ${e.toString()}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Show keyboard shortcuts dialog
  void _showKeyboardShortcutsDialog(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              'Keyboard Shortcuts',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            backgroundColor: theme.colorScheme.surface,
            elevation: isDarkMode ? 16 : 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side:
                  isDarkMode
                      ? BorderSide(color: theme.colorScheme.outline, width: 0.5)
                      : BorderSide.none,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ShortcutRow(
                  shortcut: 'Esc',
                  description: 'Stop audio playback',
                  isDarkMode: isDarkMode,
                ),
                _ShortcutRow(
                  shortcut: 'Ctrl+F',
                  description: 'Search voices',
                  isDarkMode: isDarkMode,
                ),
                _ShortcutRow(
                  shortcut: 'Ctrl+N',
                  description: 'Create new avatar',
                  isDarkMode: isDarkMode,
                ),
                _ShortcutRow(
                  shortcut: 'Space',
                  description: 'Play/pause selected voice',
                  isDarkMode: isDarkMode,
                ),
                _ShortcutRow(
                  shortcut: '↑/↓',
                  description: 'Navigate between voices',
                  isDarkMode: isDarkMode,
                ),
                _ShortcutRow(
                  shortcut: '←/→',
                  description: 'Navigate between avatars',
                  isDarkMode: isDarkMode,
                ),
              ],
            ),
            actions: [
              _HoverTextButton(
                text: 'Close',
                onPressed: () => Navigator.of(context).pop(),
                primaryColor: theme.colorScheme.primary,
              ),
            ],
          ),
    );
  }

  // Show global search dialog
  void _showGlobalSearchDialog(
    BuildContext context,
    AvatarProvider avatarProvider,
  ) {
    // Define variables outside the builder to maintain state
    String searchQuery = '';
    List<Map<String, dynamic>> searchResults = [];
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: Text(
                  'Search Voices',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                backgroundColor: theme.colorScheme.surface,
                elevation: isDarkMode ? 16 : 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side:
                      isDarkMode
                          ? BorderSide(
                            color: theme.colorScheme.outline,
                            width: 0.5,
                          )
                          : BorderSide.none,
                ),
                content: SizedBox(
                  width: 500,
                  height: 400,
                  child: Column(
                    children: [
                      // Search input
                      TextField(
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText:
                              'Type to search voices by name or category...',
                          hintStyle: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          filled: isDarkMode,
                          fillColor:
                              isDarkMode
                                  ? theme.colorScheme.surfaceContainerHighest
                                  : null,
                        ),
                        style: TextStyle(color: theme.colorScheme.onSurface),
                        onChanged: (value) {
                          setState(() {
                            searchQuery = value;
                            searchResults = avatarProvider.searchVoices(value);
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Search results
                      Expanded(
                        child:
                            searchQuery.isEmpty
                                ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.search,
                                        size: 48,
                                        color: theme
                                            .colorScheme
                                            .onSurfaceVariant
                                            .withOpacity(0.5),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Start typing to search for voices',
                                        style: TextStyle(
                                          color:
                                              theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Search by voice name or category',
                                        style: TextStyle(
                                          color: theme
                                              .colorScheme
                                              .onSurfaceVariant
                                              .withOpacity(0.7),
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                                : searchResults.isEmpty
                                ? Center(
                                  child: Text(
                                    'No voices found for "$searchQuery"',
                                    style: TextStyle(
                                      color: theme.colorScheme.onSurfaceVariant,
                                      fontSize: 16,
                                    ),
                                  ),
                                )
                                : ListView.builder(
                                  itemCount: searchResults.length,
                                  itemBuilder: (context, index) {
                                    final result = searchResults[index];
                                    final avatar = result['avatar'] as Avatar;
                                    final voice = result['voice'] as Voice;
                                    final avatarColor = _getColorFromString(
                                      avatar.color,
                                    );

                                    return _HoverListTile(
                                      title: voice.name,
                                      subtitle: Row(
                                        children: [
                                          Text(
                                            avatar.name,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: avatarColor,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 1,
                                            ),
                                            decoration: BoxDecoration(
                                              color: avatarColor.withOpacity(
                                                isDarkMode ? 0.2 : 0.1,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              voice.category,
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: avatarColor,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      leading: CircleAvatar(
                                        backgroundColor: avatarColor
                                            .withOpacity(
                                              isDarkMode ? 0.3 : 0.2,
                                            ),
                                        child: Icon(
                                          avatar.icon,
                                          color: avatarColor,
                                          size: 16,
                                        ),
                                      ),
                                      trailing:
                                          (
                                            BuildContext context,
                                            bool isHovering,
                                          ) => IconButton(
                                            icon: Icon(
                                              Icons.play_arrow,
                                              color:
                                                  isHovering
                                                      ? avatarColor
                                                      : theme
                                                          .colorScheme
                                                          .primary,
                                            ),
                                            onPressed: () {
                                              _playOrPauseVoice(voice);
                                              // Keep dialog open to allow multiple plays
                                            },
                                          ),
                                      onTap: () {
                                        // Navigate to the avatar detail screen
                                        Navigator.of(context).pop();
                                        Navigator.pushNamed(
                                          context,
                                          '/avatar/${avatar.id}',
                                        );
                                      },
                                    );
                                  },
                                ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  _HoverTextButton(
                    text: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    primaryColor: theme.colorScheme.primary,
                  ),
                ],
              );
            },
          ),
    );
  }

  // Show search dialog (simple version for keyboard shortcut)
  void _showSearchDialog(BuildContext context) {
    final avatarProvider = Provider.of<AvatarProvider>(context, listen: false);
    _showGlobalSearchDialog(context, avatarProvider);
  }

  void _showThemeDialog(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    themeProvider.toggleTheme();
  }

  // Build loading state
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 24),
          Text(
            'LOADING YOUR AVATARS',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please wait while we load your voice collection',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  // Build error state
  Widget _buildErrorState(String errorMessage) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 24),
          Text(
            'SOMETHING WENT WRONG',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: Theme.of(context).colorScheme.error,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              final avatarProvider = Provider.of<AvatarProvider>(
                context,
                listen: false,
              );
              avatarProvider.reloadAvatars();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('TRY AGAIN'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// Helper widget for keyboard shortcut row
class _ShortcutRow extends StatefulWidget {
  final String shortcut;
  final String description;
  final bool isDarkMode;

  const _ShortcutRow({
    required this.shortcut,
    required this.description,
    this.isDarkMode = false,
  });

  @override
  State<_ShortcutRow> createState() => _ShortcutRowState();
}

class _ShortcutRowState extends State<_ShortcutRow> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
          color:
              _isHovering
                  ? (widget.isDarkMode
                      ? theme.colorScheme.surfaceContainerHighest.withOpacity(
                        0.7,
                      )
                      : theme.colorScheme.primaryContainer.withOpacity(0.1))
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color:
                    widget.isDarkMode
                        ? theme.colorScheme.surfaceContainerHighest
                        : _isHovering
                        ? theme.colorScheme.primaryContainer.withOpacity(0.3)
                        : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color:
                      widget.isDarkMode
                          ? _isHovering
                              ? theme.colorScheme.primary.withOpacity(0.5)
                              : theme.colorScheme.outline
                          : _isHovering
                          ? theme.colorScheme.primary.withOpacity(0.3)
                          : Colors.grey.shade300,
                  width: _isHovering ? 1.5 : 1.0,
                ),
                boxShadow:
                    _isHovering
                        ? [
                          BoxShadow(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                        : null,
              ),
              child: Text(
                widget.shortcut,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontWeight: _isHovering ? FontWeight.w700 : FontWeight.w600,
                  color:
                      _isHovering
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              widget.description,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontWeight: _isHovering ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom badge widget
class _CustomBadge extends StatelessWidget {
  final Widget child;
  final String label;

  const _CustomBadge({required this.child, required this.label});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          top: -8,
          right: -8,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
            child: Center(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Hover animated container widget
class _HoverAnimatedContainer extends StatefulWidget {
  final Widget Function(BuildContext, bool) builder;

  const _HoverAnimatedContainer({required this.builder});

  @override
  State<_HoverAnimatedContainer> createState() =>
      _HoverAnimatedContainerState();
}

class _HoverAnimatedContainerState extends State<_HoverAnimatedContainer> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    // Only use hover effect on desktop/web platforms
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    return MouseRegion(
      onEnter: (_) => isMobile ? null : setState(() => _isHovering = true),
      onExit: (_) => isMobile ? null : setState(() => _isHovering = false),
      cursor: SystemMouseCursors.click,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: _isHovering ? 1.0 : 0.0),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutBack,
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(0, value * -4.0),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              child: widget.builder(context, _isHovering),
            ),
          );
        },
      ),
    );
  }
}

// Hover button widget
class _HoverButton extends StatefulWidget {
  final Widget Function(BuildContext, bool) builder;
  final VoidCallback onPressed;

  const _HoverButton({required this.builder, required this.onPressed});

  @override
  State<_HoverButton> createState() => _HoverButtonState();
}

class _HoverButtonState extends State<_HoverButton> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    // Only use hover effect on desktop/web platforms
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    return MouseRegion(
      onEnter: (_) => isMobile ? null : setState(() => _isHovering = true),
      onExit: (_) => isMobile ? null : setState(() => _isHovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: _isHovering ? 1.0 : 0.0),
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutBack,
          builder: (context, value, child) {
            return Transform.scale(
              scale: 1.0 + (value * 0.05),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                child: widget.builder(context, _isHovering),
              ),
            );
          },
        ),
      ),
    );
  }
}

// Hover icon button widget
class _HoverIconButton extends StatefulWidget {
  final IconData icon;
  final double size;
  final Color color;
  final Color hoverColor;
  final String tooltip;
  final VoidCallback onPressed;

  const _HoverIconButton({
    required this.icon,
    required this.size,
    required this.color,
    required this.hoverColor,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  State<_HoverIconButton> createState() => _HoverIconButtonState();
}

class _HoverIconButtonState extends State<_HoverIconButton> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    // Only use hover effect on desktop/web platforms
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    return MouseRegion(
      onEnter: (_) => isMobile ? null : setState(() => _isHovering = true),
      onExit: (_) => isMobile ? null : setState(() => _isHovering = false),
      cursor: SystemMouseCursors.click,
      child: Tooltip(
        message: widget.tooltip,
        child: IconButton(
          icon: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: _isHovering ? 1.0 : 0.0),
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              return Transform.scale(
                scale: 1.0 + (value * 0.2),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color:
                        _isHovering
                            ? widget.hoverColor.withOpacity(0.1)
                            : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    widget.icon,
                    size: widget.size,
                    color: Color.lerp(widget.color, widget.hoverColor, value),
                  ),
                ),
              );
            },
          ),
          onPressed: widget.onPressed,
          padding: EdgeInsets.zero,
          constraints: BoxConstraints(
            minWidth: widget.size + 12,
            minHeight: widget.size + 12,
          ),
        ),
      ),
    );
  }
}

// Hover text button widget
class _HoverTextButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final Color primaryColor;

  const _HoverTextButton({
    required this.text,
    required this.onPressed,
    required this.primaryColor,
  });

  @override
  State<_HoverTextButton> createState() => _HoverTextButtonState();
}

class _HoverTextButtonState extends State<_HoverTextButton> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: TextButton(
        onPressed: widget.onPressed,
        style: TextButton.styleFrom(
          foregroundColor: widget.primaryColor,
          backgroundColor:
              _isHovering
                  ? widget.primaryColor.withOpacity(0.1)
                  : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          widget.text,
          style: TextStyle(
            color: widget.primaryColor,
            fontWeight: _isHovering ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// Hover list tile widget
class _HoverListTile extends StatefulWidget {
  final String title;
  final Widget subtitle;
  final Widget leading;
  final Widget Function(BuildContext, bool) trailing;
  final VoidCallback onTap;

  const _HoverListTile({
    required this.title,
    required this.subtitle,
    required this.leading,
    required this.trailing,
    required this.onTap,
  });

  @override
  State<_HoverListTile> createState() => _HoverListTileState();
}

class _HoverListTileState extends State<_HoverListTile> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color:
              _isHovering
                  ? (isDarkMode
                      ? theme.colorScheme.surfaceContainerHighest
                      : theme.colorScheme.primaryContainer.withOpacity(0.1))
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: ListTile(
          title: Text(
            widget.title,
            style: TextStyle(
              fontWeight: _isHovering ? FontWeight.w600 : FontWeight.w500,
              color: theme.colorScheme.onSurface,
            ),
          ),
          subtitle: widget.subtitle,
          leading: widget.leading,
          trailing: widget.trailing(context, _isHovering),
          onTap: widget.onTap,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}

// Animated Icon Button for app bar icons
class _AnimatedIconButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color color;
  final Color hoverColor;
  final double size;
  final bool isDisabled;
  final bool useContainer;
  final Color? containerColor;
  final Color? containerHoverColor;
  final bool useAnimatedSwitcher;
  final Key? switcherKey;

  const _AnimatedIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    required this.color,
    required this.hoverColor,
    required this.size,
    this.isDisabled = false,
    this.useContainer = false,
    this.containerColor,
    this.containerHoverColor,
    this.useAnimatedSwitcher = false,
    this.switcherKey,
  });

  @override
  State<_AnimatedIconButton> createState() => _AnimatedIconButtonState();
}

class _AnimatedIconButtonState extends State<_AnimatedIconButton> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    // Only use hover effect on desktop/web platforms
    final bool isMobile = MediaQuery.of(context).size.width < 600;
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return MouseRegion(
      onEnter:
          (_) =>
              isMobile || widget.isDisabled
                  ? null
                  : setState(() => _isHovering = true),
      onExit:
          (_) =>
              isMobile || widget.isDisabled
                  ? null
                  : setState(() => _isHovering = false),
      cursor:
          widget.isDisabled
              ? SystemMouseCursors.forbidden
              : SystemMouseCursors.click,
      child: Tooltip(
        message: widget.tooltip,
        child: IconButton(
          icon: TweenAnimationBuilder<double>(
            tween: Tween<double>(
              begin: 0,
              end: _isHovering && !widget.isDisabled ? 1.0 : 0.0,
            ),
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              Widget iconWidget =
                  widget.useAnimatedSwitcher
                      ? AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (
                          Widget child,
                          Animation<double> animation,
                        ) {
                          return ScaleTransition(
                            scale: animation,
                            child: child,
                          );
                        },
                        child: Icon(
                          widget.icon,
                          key: widget.switcherKey,
                          size: widget.size,
                          color:
                              widget.isDisabled
                                  ? theme.colorScheme.onSurface.withOpacity(
                                    0.38,
                                  )
                                  : Color.lerp(
                                    widget.color,
                                    widget.hoverColor,
                                    value,
                                  ),
                        ),
                      )
                      : Icon(
                        widget.icon,
                        size: widget.size,
                        color:
                            widget.isDisabled
                                ? theme.colorScheme.onSurface.withOpacity(0.38)
                                : Color.lerp(
                                  widget.color,
                                  widget.hoverColor,
                                  value,
                                ),
                      );

              if (widget.useContainer) {
                return Transform.scale(
                  scale: 1.0 + (value * 0.15),
                  child: Container(
                    padding: EdgeInsets.all(widget.size * 0.3),
                    decoration: BoxDecoration(
                      color:
                          widget.isDisabled
                              ? (widget.containerColor ?? Colors.transparent)
                                  .withOpacity(0.5)
                              : Color.lerp(
                                widget.containerColor ?? Colors.transparent,
                                widget.containerHoverColor ??
                                    widget.hoverColor.withOpacity(0.1),
                                value,
                              ),
                      shape: BoxShape.circle,
                      boxShadow:
                          _isHovering && !widget.isDisabled
                              ? [
                                BoxShadow(
                                  color: widget.hoverColor.withOpacity(0.2),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                              : null,
                    ),
                    child: iconWidget,
                  ),
                );
              } else {
                return Transform.scale(
                  scale: 1.0 + (value * 0.2),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color:
                          _isHovering && !widget.isDisabled
                              ? widget.hoverColor.withOpacity(0.1)
                              : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(4),
                    child: iconWidget,
                  ),
                );
              }
            },
          ),
          onPressed: widget.isDisabled ? null : widget.onPressed,
          splashRadius: 24,
        ),
      ),
    );
  }
}

// Animated Popup Menu Button
class _AnimatedPopupMenuButton<T> extends StatefulWidget {
  final String tooltip;
  final IconData icon;
  final double iconSize;
  final Color color;
  final Color hoverColor;
  final bool enabled;
  final PopupMenuItemBuilder<T> itemBuilder;
  final PopupMenuItemSelected<T>? onSelected;

  const _AnimatedPopupMenuButton({
    required this.tooltip,
    required this.icon,
    required this.iconSize,
    required this.color,
    required this.hoverColor,
    required this.enabled,
    required this.itemBuilder,
    this.onSelected,
  });

  @override
  State<_AnimatedPopupMenuButton<T>> createState() =>
      _AnimatedPopupMenuButtonState<T>();
}

class _AnimatedPopupMenuButtonState<T>
    extends State<_AnimatedPopupMenuButton<T>> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    // Only use hover effect on desktop/web platforms
    final bool isMobile = MediaQuery.of(context).size.width < 600;
    final theme = Theme.of(context);

    return MouseRegion(
      onEnter:
          (_) =>
              isMobile || !widget.enabled
                  ? null
                  : setState(() => _isHovering = true),
      onExit:
          (_) =>
              isMobile || !widget.enabled
                  ? null
                  : setState(() => _isHovering = false),
      cursor:
          widget.enabled
              ? SystemMouseCursors.click
              : SystemMouseCursors.forbidden,
      child: PopupMenuButton<T>(
        tooltip: widget.tooltip,
        enabled: widget.enabled,
        itemBuilder: widget.itemBuilder,
        onSelected: widget.onSelected,
        icon: TweenAnimationBuilder<double>(
          tween: Tween<double>(
            begin: 0,
            end: _isHovering && widget.enabled ? 1.0 : 0.0,
          ),
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutBack,
          builder: (context, value, child) {
            return Transform.scale(
              scale: 1.0 + (value * 0.2),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color:
                      _isHovering && widget.enabled
                          ? widget.hoverColor.withOpacity(0.1)
                          : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(4),
                child: Icon(
                  widget.icon,
                  size: widget.iconSize,
                  color:
                      widget.enabled
                          ? Color.lerp(widget.color, widget.hoverColor, value)
                          : theme.colorScheme.onSurface.withOpacity(0.38),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
