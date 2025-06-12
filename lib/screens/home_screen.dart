import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../providers/avatar_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/audio_routing_provider.dart';
import '../models/avatar.dart';
import '../widgets/reorderable_voice_grid.dart';
import '../widgets/audio_routing_status.dart';
import '../widgets/future_asset_builder.dart';
import '../services/web_db_service.dart';
import 'add_avatar_screen.dart';
import 'settings_screen.dart';
import 'dart:io';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  // Audio player instance
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _currentlyPlayingVoiceId;
  StreamSubscription? _playerStateSubscription;

  // Track which avatars are collapsed
  final Set<String> _collapsedAvatars = {};

  // Animation controller for app entrance animations
  late AnimationController _appEntranceController;

  // Toggle avatar collapsed state
  void _toggleAvatarCollapsed(String avatarId) {
    setState(() {
      if (_collapsedAvatars.contains(avatarId)) {
        _collapsedAvatars.remove(avatarId);
      } else {
        _collapsedAvatars.add(avatarId);
      }
    });

    // Add haptic feedback for collapse/expand
    HapticFeedback.selectionClick();
  }

  @override
  void initState() {
    super.initState();

    // Initialize app entrance animation controller
    _appEntranceController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Start animations when widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _appEntranceController.forward();
    });

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

    // Dispose animation controller
    _appEntranceController.dispose();

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
    final isTablet = screenWidth >= 600 && screenWidth < 1024;
    final isDesktop = screenWidth >= 1024;

    return Consumer3<AvatarProvider, ThemeProvider, AudioRoutingProvider>(
      builder: (
        context,
        avatarProvider,
        themeProvider,
        audioRoutingProvider,
        child,
      ) {
        final recentVoices = avatarProvider.getRecentlyUsedVoices(limit: 3);
        final popularVoices = avatarProvider.getMostUsedVoices(limit: 3);
        final isDeletingAvatar = avatarProvider.isDeletingAvatar;
        final theme = Theme.of(context);
        final isDarkMode = theme.brightness == Brightness.dark;

        // Check for audio routing issues (only on Windows)
        final bool showAudioRoutingAlert =
            !kIsWeb &&
            Platform.isWindows &&
            audioRoutingProvider.hasCheckedRouting &&
            !audioRoutingProvider.isAudioRoutingDetected;

        // Create app bar actions list
        final List<Widget> appBarActions = [
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
                    : () => _showGlobalSearchDialog(context, avatarProvider),
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
                            avatar.imagePath != null
                                ? ClipOval(
                                  child: FutureAssetBuilder(
                                    assetKey: avatar.imagePath!,
                                    loader: (key) async {
                                      if (key.startsWith('indexeddb://')) {
                                        final dbKey = key.substring(
                                          'indexeddb://'.length,
                                        );
                                        return WebDbService.instance.loadAsset(
                                          dbKey,
                                        );
                                      } else {
                                        return File(key).readAsBytes();
                                      }
                                    },
                                    loadingWidget: Container(
                                      width: 24,
                                      height: 24,
                                      color: avatarColor.withAlpha(51),
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.0,
                                        ),
                                      ),
                                    ),
                                    errorWidget: Container(
                                      width: 24,
                                      height: 24,
                                      color: Colors.grey.shade300,
                                      child: Icon(
                                        Icons.broken_image,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    builder: (context, data) {
                                      if (data == null) {
                                        return Icon(
                                          avatar.icon,
                                          size: 24,
                                          color: avatarColor,
                                        );
                                      }
                                      return Image.memory(
                                        data,
                                        fit: BoxFit.cover,
                                        width: 24,
                                        height: 24,
                                      );
                                    },
                                  ),
                                )
                                : Icon(
                                  avatar.icon,
                                  size: 24,
                                  color: avatarColor,
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

                  // Add divider if we have both recent and popular
                  if (popularVoices.isNotEmpty) {
                    items.add(const PopupMenuDivider());
                  }
                }

                return items;
              },
              onSelected: (item) {
                final voice = item['voice'] as Voice;
                _playOrPauseVoice(voice);
              },
            ),
          // Add the audio routing notification bell
          if (showAudioRoutingAlert)
            _AnimatedIconButton(
              icon: Icons.notifications_active,
              tooltip: 'Audio Routing Issue Detected',
              onPressed: () => _showAudioRoutingDialog(context),
              color: theme.colorScheme.error,
              hoverColor: theme.colorScheme.error,
              size: isMobile ? 20 : 22,
              useContainer: true,
              containerColor: theme.colorScheme.errorContainer.withAlpha(51),
              containerHoverColor: theme.colorScheme.errorContainer.withAlpha(
                80,
              ),
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
            onPressed: themeProvider.toggleTheme,
            color: theme.colorScheme.onSurface,
            hoverColor: theme.colorScheme.primary,
            size: isMobile ? 18 : 20,
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
                containerColor: Colors.black.withAlpha(14),
                containerHoverColor: theme.colorScheme.errorContainer.withAlpha(
                  80,
                ),
              ),
            ),
        ];

        return AnimatedTheme(
          data: theme,
          duration: const Duration(milliseconds: 400),
          child: Scaffold(
            backgroundColor: theme.colorScheme.surface,
            appBar: AnimatedAppBar(
              animation: _appEntranceController,
              title: 'VOICE AVATAR HUB',
              isMobile: isMobile,
              actions: appBarActions,
              theme: theme,
            ),
            body: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              color: theme.colorScheme.surface,
              child: SafeArea(
                child: _buildMainContent(
                  context,
                  avatarProvider,
                  theme,
                  isDarkMode,
                  isMobile,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Show audio routing dialog when notification bell is clicked
  void _showAudioRoutingDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: 8),
                const Text('Audio Routing Issue'),
              ],
            ),
            content: const SingleChildScrollView(child: AudioRoutingStatus()),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                },
                child: const Text('Open Settings'),
              ),
            ],
          ),
    );
  }

  // Build view showing all avatars with their voices
  Widget _buildAllAvatarsView(BuildContext context, List<Avatar> avatars) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;
    final isDesktop = screenWidth >= 1024;

    // Calculate optimal spacing based on screen size
    final horizontalPadding = isMobile ? 12.0 : (isTablet ? 24.0 : 32.0);
    final verticalSpacing = isMobile ? 16.0 : 24.0;

    return AnimationLimiter(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: ListView.builder(
          itemCount: avatars.length,
          padding: EdgeInsets.symmetric(vertical: verticalSpacing),
          itemBuilder: (context, index) {
            // Calculate stagger delay based on index
            final staggerDuration = Duration(milliseconds: 50 * index);
            final animationDuration = const Duration(milliseconds: 600);

            return AnimationConfiguration.staggeredList(
              position: index,
              duration: animationDuration,
              delay: staggerDuration,
              child: SlideAnimation(
                verticalOffset: 50.0, // Slide up from 50 pixels below
                curve: Curves.easeOutCubic,
                child: ScaleAnimation(
                  scale: 0.8, // Start at 80% scale
                  curve: Curves.easeOutBack,
                  child: FadeInAnimation(
                    curve: Curves.easeOut,
                    child: Padding(
                      padding: EdgeInsets.only(bottom: verticalSpacing),
                      child: _buildAvatarWithVoices(context, avatars[index]),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // Build an avatar with its voices
  Widget _buildAvatarWithVoices(BuildContext context, Avatar avatar) {
    final Color avatarColor = _getColorFromString(avatar.color);
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;
    final isDesktop = screenWidth >= 1024;
    final bool isCollapsed = _collapsedAvatars.contains(avatar.id);

    // Calculate sizes (only 20% smaller than original)
    final double verticalPadding = isMobile ? 6 : (isTablet ? 8 : 10);
    final double horizontalPadding = isMobile ? 10 : (isTablet ? 12 : 16);
    final double iconSize = isMobile ? 32 : (isTablet ? 38 : 46);
    final double fontSize = isMobile ? 14 : (isTablet ? 16 : 18);
    final double subFontSize = isMobile ? 11 : 13;

    return Container(
      margin: EdgeInsets.only(bottom: isMobile ? 8 : 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Modern avatar header with hover effect but no elevation
          Center(
            child: SizedBox(
              width: screenWidth * (isMobile ? 0.98 : (isTablet ? 0.9 : 0.85)),
              child: StatefulBuilder(
                builder: (context, setState) {
                  bool isHovering = false;

                  return MouseRegion(
                    onEnter: (_) => setState(() => isHovering = true),
                    onExit: (_) => setState(() => isHovering = false),
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => _toggleAvatarCollapsed(avatar.id),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: EdgeInsets.all(isMobile ? 6 : 8),
                        decoration: BoxDecoration(
                          color:
                              isDarkMode
                                  ? Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest
                                      .withAlpha(isHovering ? 128 : 192)
                                  : avatarColor.withAlpha(isHovering ? 19 : 30),
                          border: Border.all(
                            color:
                                isDarkMode
                                    ? isHovering
                                        ? Theme.of(
                                          context,
                                        ).colorScheme.primary.withAlpha(80)
                                        : Theme.of(context).colorScheme.outline
                                    : avatarColor.withAlpha(
                                      isHovering ? 76 : 51,
                                    ),
                            width: isHovering ? 1.5 : 1.0,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            // Avatar icon with subtle animation
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeOutCubic,
                              padding: EdgeInsets.all(isMobile ? 6 : 8),
                              decoration: BoxDecoration(
                                color: avatarColor.withAlpha(
                                  isDarkMode
                                      ? (isHovering ? 48 : 38)
                                      : (isHovering ? 38 : 30),
                                ),
                                shape: BoxShape.circle,
                              ),
                              child:
                                  avatar.imagePath != null
                                      ? ClipOval(
                                        child: FutureAssetBuilder(
                                          assetKey: avatar.imagePath!,
                                          loader: (key) async {
                                            if (key.startsWith(
                                              'indexeddb://',
                                            )) {
                                              final dbKey = key.substring(
                                                'indexeddb://'.length,
                                              );
                                              return WebDbService.instance
                                                  .loadAsset(dbKey);
                                            } else {
                                              return File(key).readAsBytes();
                                            }
                                          },
                                          loadingWidget: Container(
                                            width: iconSize,
                                            height: iconSize,
                                            color: avatarColor.withAlpha(20),
                                            child: const Center(
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.0,
                                              ),
                                            ),
                                          ),
                                          errorWidget: Container(
                                            width: iconSize,
                                            height: iconSize,
                                            color: Colors.grey.shade300,
                                            child: Icon(
                                              Icons.broken_image,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                          builder: (context, data) {
                                            if (data == null) {
                                              return Icon(
                                                avatar.icon,
                                                size: iconSize,
                                                color: avatarColor,
                                              );
                                            }
                                            return Image.memory(
                                              data,
                                              fit: BoxFit.cover,
                                              width: iconSize,
                                              height: iconSize,
                                            );
                                          },
                                        ),
                                      )
                                      : Icon(
                                        avatar.icon,
                                        size: iconSize,
                                        color: avatarColor,
                                      ),
                            ),
                            SizedBox(width: isMobile ? 8 : 10),

                            // Avatar name and voice count
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 200),
                                  style: TextStyle(
                                    fontSize: fontSize,
                                    fontWeight:
                                        isHovering
                                            ? FontWeight.w700
                                            : FontWeight.w600,
                                    letterSpacing: 0.5,
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  ),
                                  child: Text(avatar.name.toUpperCase()),
                                ),
                                SizedBox(height: 2),
                                AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 200),
                                  style: TextStyle(
                                    fontSize: subFontSize,
                                    fontWeight:
                                        isHovering
                                            ? FontWeight.w500
                                            : FontWeight.w400,
                                    color:
                                        Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                  ),
                                  child: Text('${avatar.voices.length} voices'),
                                ),
                              ],
                            ),

                            Spacer(),

                            // Collapse indicator with rotation animation
                            AnimatedRotation(
                              turns: isCollapsed ? -0.25 : 0.25, // -90° or 90°
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOutCubic,
                              child: Container(
                                padding: EdgeInsets.all(4),
                                child: Icon(
                                  Icons.chevron_right,
                                  size: isMobile ? 22 : 26,
                                  color:
                                      isHovering
                                          ? avatarColor
                                          : Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withAlpha(128),
                                ),
                              ),
                            ),

                            SizedBox(width: isMobile ? 6 : 8),

                            // Add voice button with modern styling
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap:
                                    () => Navigator.pushNamed(
                                      context,
                                      '/avatar/${avatar.id}',
                                    ),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isMobile ? 6 : 10,
                                    vertical: isMobile ? 4 : 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: avatarColor.withAlpha(
                                      isDarkMode ? 30 : 20,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.add,
                                        size: isMobile ? 22 : 26,
                                        color: avatarColor,
                                      ),
                                      if (!isMobile) ...[
                                        const SizedBox(width: 6),
                                        Text(
                                          'ADD VOICE',
                                          style: TextStyle(
                                            fontSize: subFontSize,
                                            fontWeight: FontWeight.w600,
                                            color: avatarColor,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(width: isMobile ? 2 : 4),

                            // Edit avatar button with modern styling
                            Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap:
                                    () => Navigator.pushNamed(
                                      context,
                                      '/edit-avatar/${avatar.id}',
                                    ),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Icon(
                                    Icons.edit_outlined,
                                    size: isMobile ? 22 : 26,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface.withAlpha(128),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Voice list or empty message with animated expanding/collapsing
          AnimatedCrossFade(
            firstChild:
                avatar.voices.isEmpty
                    ? Padding(
                      padding: const EdgeInsets.only(top: 12, bottom: 4),
                      child: Center(
                        child: Text(
                          'No voices yet. Add one with the button above.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withAlpha(128),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    )
                    : Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Center(
                        child: SizedBox(
                          width:
                              screenWidth *
                              (isMobile ? 0.98 : (isTablet ? 0.9 : 0.85)),
                          child: AnimationLimiter(
                            child: ReorderableVoiceGrid(
                              voices: avatar.voices,
                              avatarId: avatar.id,
                              avatarColor: avatarColor,
                              onVoiceTap: _playOrPauseVoice,
                              currentlyPlayingVoiceId: _currentlyPlayingVoiceId,
                            ),
                          ),
                        ),
                      ),
                    ),
            secondChild: const SizedBox.shrink(),
            crossFadeState:
                isCollapsed
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 400),
            reverseDuration: const Duration(milliseconds: 300),
            sizeCurve: Curves.easeOutCubic,
            firstCurve: Curves.easeOutCubic,
            secondCurve: Curves.easeInCubic,
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
        if (voice.audioUrl.startsWith('indexeddb://')) {
          final key = voice.audioUrl.substring('indexeddb://'.length);
          final bytes = await WebDbService.instance.loadAsset(key);
          if (bytes != null) {
            await _audioPlayer.play(BytesSource(bytes));
          } else {
            throw Exception('Failed to load audio from DB');
          }
        } else if (kIsWeb) {
          // Fallback for any other type of URL on web
          await _audioPlayer.play(UrlSource(voice.audioUrl));
        } else {
          await _audioPlayer.play(DeviceFileSource(voice.audioUrl));
        }
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error playing audio: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
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
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;

    return Center(
      child: AnimationLimiter(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: AnimationConfiguration.toStaggeredList(
            duration: const Duration(milliseconds: 800),
            childAnimationBuilder:
                (widget) => SlideAnimation(
                  verticalOffset: 50.0,
                  curve: Curves.easeOutQuint,
                  child: FadeInAnimation(curve: Curves.easeOut, child: widget),
                ),
            children: [
              // Animated pulsing avatar icon
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.95, end: 1.05),
                duration: const Duration(milliseconds: 2000),
                curve: Curves.easeInOutSine,
                builder: (context, value, child) {
                  return Transform.scale(scale: value, child: child);
                },
                child: Container(
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: primaryColor.withAlpha(15),
                    borderRadius: BorderRadius.circular(100),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withAlpha(32),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 1500),
                    curve: Curves.elasticOut,
                    builder: (context, value, child) {
                      return Transform.scale(scale: value, child: child);
                    },
                    child: Icon(
                      Icons.record_voice_over_rounded,
                      size: 80,
                      color: primaryColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              // Text elements with staggered animations
              AnimatedShimmer(
                child: Text(
                  'NO AVATARS YET',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'Create your first avatar to start building your voice collection',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface.withAlpha(128),
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 48),
              // Animated button
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutBack,
                builder: (context, value, child) {
                  return Transform.scale(scale: value, child: child);
                },
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: ElevatedButton.icon(
                    onPressed: () => _showAddAvatarDialog(context),
                    icon: const Icon(Icons.add, size: 20),
                    label: const Text(
                      'CREATE AVATAR',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: theme.colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 18,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 8,
                      shadowColor: primaryColor.withAlpha(128),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAddAvatarDialog(BuildContext context) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) => const AddAvatarScreen(),
    );

    if (result == null || !context.mounted) return;

    final name = result['name'] as String;
    final icon = result['icon'] as IconData;
    final color = result['color'] as String;
    final imagePath = result['imagePath'] as String?;
    final imageBytes = result['imageBytes'] as Uint8List?;
    final imageName = result['imageName'] as String?;

    try {
      final avatarProvider = Provider.of<AvatarProvider>(
        context,
        listen: false,
      );
      await avatarProvider.addAvatar(
        name,
        icon: icon,
        color: color,
        imagePath: imagePath,
        imageBytes: imageBytes,
        imageName: imageName,
      );

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Avatar "$name" created successfully.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error creating avatar: $e')));
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error stopping audio: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
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
                                            .withAlpha(128),
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
                                              .withAlpha(192),
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
                                              color: avatarColor.withAlpha(
                                                isDarkMode ? 32 : 20,
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
                                        backgroundColor: avatarColor.withAlpha(
                                          isDarkMode ? 48 : 32,
                                        ),
                                        radius: 16,
                                        child: Icon(
                                          avatar.icon,
                                          color: avatarColor,
                                          size: 22,
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

    // First toggle the theme
    themeProvider.toggleTheme();

    // Force a rebuild of the entire screen with animations
    setState(() {});

    // Trigger haptic feedback for theme change
    HapticFeedback.mediumImpact();

    // Show a subtle indicator of the theme change
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              themeProvider.themeMode == ThemeMode.dark
                  ? Icons.dark_mode
                  : Icons.light_mode,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              themeProvider.themeMode == ThemeMode.dark
                  ? 'Dark mode enabled'
                  : 'Light mode enabled',
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 1500),
        animation: CurvedAnimation(
          parent: const AlwaysStoppedAnimation(1),
          curve: Curves.easeOutBack,
        ),
      ),
    );
  }

  // Build loading state
  Widget _buildLoadingState() {
    return AnimationLimiter(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: AnimationConfiguration.toStaggeredList(
            duration: const Duration(milliseconds: 600),
            childAnimationBuilder:
                (widget) => SlideAnimation(
                  verticalOffset: 50.0,
                  curve: Curves.easeOutCubic,
                  child: ScaleAnimation(
                    scale: 0.8,
                    curve: Curves.easeOutBack,
                    child: FadeInAnimation(
                      curve: Curves.easeOut,
                      child: widget,
                    ),
                  ),
                ),
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
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(128),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build error state
  Widget _buildErrorState(String errorMessage) {
    return AnimationLimiter(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: AnimationConfiguration.toStaggeredList(
            duration: const Duration(milliseconds: 600),
            childAnimationBuilder:
                (widget) => SlideAnimation(
                  verticalOffset: 50.0,
                  curve: Curves.easeOutCubic,
                  child: ScaleAnimation(
                    scale: 0.8,
                    curve: Curves.easeOutBack,
                    child: FadeInAnimation(
                      curve: Curves.easeOut,
                      child: widget,
                    ),
                  ),
                ),
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
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withAlpha(128),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Animated AppBar that slides in from the top with fade effect
  Widget _buildMainContent(
    BuildContext context,
    AvatarProvider avatarProvider,
    ThemeData theme,
    bool isDarkMode,
    bool isMobile,
  ) {
    return Stack(
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
            child: AnimatedBuilder(
              animation: _appEntranceController,
              builder: (context, child) {
                return FadeTransition(
                  opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                    CurvedAnimation(
                      parent: _appEntranceController,
                      curve: Interval(0.3, 1.0, curve: Curves.easeOut),
                    ),
                  ),
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.1),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: _appEntranceController,
                        curve: Interval(0.3, 1.0, curve: Curves.easeOutQuint),
                      ),
                    ),
                    child: child,
                  ),
                );
              },
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
                        : _buildAllAvatarsView(context, avatarProvider.avatars),
              ),
            ),
          ),
        ),

        // Deletion overlay with animation
        if (avatarProvider.isDeletingAvatar)
          AnimatedOpacity(
            opacity: avatarProvider.isDeletingAvatar ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
            child: Container(
              color: theme.colorScheme.surface.withAlpha(128),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: AnimationConfiguration.toStaggeredList(
                    duration: const Duration(milliseconds: 400),
                    childAnimationBuilder:
                        (widget) => SlideAnimation(
                          verticalOffset: 30.0,
                          child: FadeInAnimation(child: widget),
                        ),
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
            ),
          ),
      ],
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
                      ? theme.colorScheme.surfaceContainerHighest.withAlpha(128)
                      : theme.colorScheme.primaryContainer.withAlpha(20))
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
                        ? theme.colorScheme.primaryContainer.withAlpha(32)
                        : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color:
                      widget.isDarkMode
                          ? _isHovering
                              ? theme.colorScheme.primary.withAlpha(80)
                              : theme.colorScheme.outline
                          : _isHovering
                          ? theme.colorScheme.primary.withAlpha(32)
                          : Colors.grey.shade300,
                  width: _isHovering ? 1.5 : 1.0,
                ),
                boxShadow:
                    _isHovering
                        ? [
                          BoxShadow(
                            color: theme.colorScheme.primary.withAlpha(20),
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
            tween: Tween<double>(
              begin: 0,
              end: _isHovering && !isMobile ? 1.0 : 0.0,
            ),
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              Widget iconWidget = Icon(
                widget.icon,
                size: widget.size,
                color: _isHovering ? widget.hoverColor : widget.color,
              );

              if (isMobile) {
                return iconWidget;
              } else {
                return Transform.scale(
                  scale: 1.0 + (value * 0.2),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color:
                          _isHovering
                              ? widget.hoverColor.withAlpha(20)
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
                  ? widget.primaryColor.withAlpha(20)
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
                      : theme.colorScheme.primaryContainer.withAlpha(20))
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
                                  ? theme.colorScheme.onSurface.withAlpha(64)
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
                                ? theme.colorScheme.onSurface.withAlpha(64)
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
                                  .withAlpha(128)
                              : widget.containerColor,
                      shape: BoxShape.circle,
                      boxShadow:
                          _isHovering && !widget.isDisabled
                              ? [
                                BoxShadow(
                                  color: widget.hoverColor.withAlpha(20),
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
                              ? widget.hoverColor.withAlpha(20)
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
                          ? widget.hoverColor.withAlpha(20)
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
                          : theme.colorScheme.onSurface.withAlpha(64),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// Custom shimmer animation for text
class AnimatedShimmer extends StatefulWidget {
  final Widget child;

  const AnimatedShimmer({super.key, required this.child});

  @override
  State<AnimatedShimmer> createState() => _AnimatedShimmerState();
}

class _AnimatedShimmerState extends State<AnimatedShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(opacity: _animation.value, child: widget.child);
      },
    );
  }
}

// Animated AppBar that slides in from the top with fade effect
class AnimatedAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Animation<double> animation;
  final String title;
  final bool isMobile;
  final List<Widget> actions;
  final ThemeData theme;

  const AnimatedAppBar({
    super.key,
    required this.animation,
    required this.title,
    required this.isMobile,
    required this.actions,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, -1),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutQuint)),
      child: FadeTransition(
        opacity: animation,
        child: AppBar(
          title: Text(
            title,
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
          actions: actions,
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
