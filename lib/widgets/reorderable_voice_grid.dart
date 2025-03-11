import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math';
import '../models/avatar.dart';
import 'package:provider/provider.dart';
import '../providers/avatar_provider.dart';
import '../screens/home_screen.dart';

/// A grid of voice items that can be reordered by dragging
class ReorderableVoiceGrid extends StatefulWidget {
  final List<Voice> voices;
  final String avatarId;
  final Color avatarColor;
  final Function(Voice) onVoiceTap;
  final String? currentlyPlayingVoiceId;

  const ReorderableVoiceGrid({
    super.key,
    required this.voices,
    required this.avatarId,
    required this.avatarColor,
    required this.onVoiceTap,
    this.currentlyPlayingVoiceId,
  });

  @override
  State<ReorderableVoiceGrid> createState() => _ReorderableVoiceGridState();
}

class _ReorderableVoiceGridState extends State<ReorderableVoiceGrid>
    with TickerProviderStateMixin {
  // Track if we're currently dragging an item
  bool _isDragging = false;

  // Timer for long press
  Timer? _longPressTimer;

  // Timer for tracking playback duration
  Timer? _playbackTimer;

  // Current playback duration in seconds
  int _playbackDuration = 0;

  // Maximum duration for voice playback (default 30 seconds)
  final int _maxDuration = 30;

  // Animation controller for wave effect
  late AnimationController _waveAnimationController;

  // Animation controller for tap effect
  late AnimationController _tapAnimationController;

  // Animation controller for progress bar
  late AnimationController _progressAnimationController;

  // Currently selected voice for context menu
  Voice? _selectedVoice;

  // Animation controller for reordering animation
  late AnimationController _animationController;

  // Map to track which voice was tapped for animation
  final Map<String, bool> _tappedVoices = {};

  // List of available colors for voices
  final List<Color> _availableColors = [
    const Color(0xFF1E88E5), // Strong blue
    const Color(0xFF5E35B1), // Deep purple
    const Color(0xFFD81B60), // Bold crimson
    const Color(0xFFE53935), // Vibrant red
    const Color(0xFF43A047), // Forest green
    const Color(0xFF039BE5), // Ocean blue
    const Color(0xFF546E7A), // Steel blue-gray
    const Color(0xFFEF6C00), // Burnt orange
    const Color(0xFF6D4C41), // Rich brown
    const Color(0xFF00897B), // Teal green
  ];

  // Map color names to colors
  final Map<String, Color> _colorMap = {
    'blue': const Color(0xFF1E88E5), // Strong blue
    'purple': const Color(0xFF5E35B1), // Deep purple
    'crimson': const Color(0xFFD81B60), // Bold crimson
    'red': const Color(0xFFE53935), // Vibrant red
    'green': const Color(0xFF43A047), // Forest green
    'ocean': const Color(0xFF039BE5), // Ocean blue
    'steel': const Color(0xFF546E7A), // Steel blue-gray
    'orange': const Color(0xFFEF6C00), // Burnt orange
    'brown': const Color(0xFF6D4C41), // Rich brown
    'teal': const Color(0xFF00897B), // Teal green
  };

  // Map colors to color names
  String _getColorName(Color color) {
    for (final entry in _colorMap.entries) {
      if (entry.value == color) {
        return entry.key;
      }
    }
    return 'blue'; // Default color name - changed back to blue as it's more recognizable
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    // Initialize wave animation controller but don't start it yet
    _waveAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    // Initialize tap animation controller
    _tapAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    // Initialize progress animation controller
    _progressAnimationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: _maxDuration),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _waveAnimationController.dispose();
    _tapAnimationController.dispose();
    _progressAnimationController.dispose();
    _longPressTimer?.cancel();
    _playbackTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(ReorderableVoiceGrid oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle changes in currently playing voice
    if (widget.currentlyPlayingVoiceId != oldWidget.currentlyPlayingVoiceId) {
      // Reset playback timer when voice changes
      _playbackTimer?.cancel();
      _playbackDuration = 0;

      // Reset and stop progress animation
      _progressAnimationController.reset();

      // Stop animations if nothing is playing
      if (widget.currentlyPlayingVoiceId == null) {
        _animationController.stop();
        _waveAnimationController.stop();
      } else {
        // Start animations only when a voice is playing
        if (!_animationController.isAnimating) {
          _animationController.repeat(
            reverse: true,
          ); // Use reverse for a gentler pulse
        }
        if (!_waveAnimationController.isAnimating) {
          _waveAnimationController.repeat(reverse: false);
        }

        // Start progress animation
        _progressAnimationController.forward(from: 0.0);

        _playbackTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() {
            _playbackDuration++;
          });
        });
      }
    }
  }

  // Show the color selection menu
  void _showColorSelectionMenu(
    BuildContext context,
    Voice voice,
    Offset position,
  ) {
    // Cancel any existing timer
    _longPressTimer?.cancel();

    // Don't show the menu if we're currently dragging
    if (_isDragging) return;

    // Get the current color of the voice
    final avatarProvider = Provider.of<AvatarProvider>(context, listen: false);
    final avatar = avatarProvider.avatars.firstWhere(
      (a) => a.id == widget.avatarId,
      orElse: () => throw Exception('Avatar not found'),
    );

    final voiceIndex = avatar.voices.indexWhere((v) => v.id == voice.id);
    if (voiceIndex == -1) return;

    // Provide haptic feedback
    HapticFeedback.mediumImpact();

    // Show the iOS-style context menu
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 1,
        position.dy + 1,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 8,
      items: <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          enabled: false,
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          value: '',
          child: Text(
            'Change Color',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        const PopupMenuDivider(),
        ...List<PopupMenuEntry<String>>.generate(_availableColors.length, (
          index,
        ) {
          final color = _availableColors[index];
          final colorName = _getColorName(color);

          return PopupMenuItem<String>(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            value: colorName,
            onTap: () {
              // Update the voice color
              _updateVoiceColor(voice, colorName);
            },
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  colorName.substring(0, 1).toUpperCase() +
                      colorName.substring(1),
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          );
        }),
      ],
    ).then((colorName) {
      if (colorName != null && colorName.isNotEmpty) {
        _updateVoiceColor(voice, colorName);
      }
    });
  }

  // Update the voice color
  void _updateVoiceColor(Voice voice, String colorName) {
    final avatarProvider = Provider.of<AvatarProvider>(context, listen: false);

    // Update the voice color
    avatarProvider.updateVoiceColor(widget.avatarId, voice.id, colorName);

    // Play animation
    _animationController.forward().then((_) {
      _animationController.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Calculate the number of items per row based on screen width
    final int itemsPerRow =
        screenWidth > 1200
            ? 6
            : screenWidth > 900
            ? 5
            : screenWidth > 600
            ? 4
            : 3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Instructional message for using the audio player
        Padding(
          padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Tap a voice to play. Long press or right-click to change color. Drag the handle to reorder.',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ),
            ],
          ),
        ),

        SizedBox(
          width: double.infinity,
          child: ReorderableWrap(
            spacing: 8.0,
            runSpacing: 8.0,
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 4.0 : 8.0,
              vertical: 8.0,
            ),
            onReorder: (oldIndex, newIndex) {
              // Play animation with spring curve for more natural feel
              _animationController.forward().then((_) {
                _animationController.reverse();
              });

              // Update the provider
              Provider.of<AvatarProvider>(
                context,
                listen: false,
              ).reorderVoices(widget.avatarId, oldIndex, newIndex);
            },
            onReorderStarted: (index) {
              setState(() {
                _isDragging = true;
              });

              // Provide haptic feedback when drag starts
              HapticFeedback.mediumImpact();
            },
            onNoReorder: (index) {
              // This is called when a drag is canceled
              setState(() {
                _isDragging = false;
              });
            },
            onReorderEnd: (index) {
              setState(() {
                _isDragging = false;
              });

              // Provide haptic feedback when drag ends
              HapticFeedback.lightImpact();
            },
            children: List.generate(widget.voices.length, (index) {
              final voice = widget.voices[index];
              return _buildVoiceItem(
                context,
                voice,
                widget.avatarColor,
                isDarkMode,
                isMobile,
              );
            }),
          ),
        ),
      ],
    );
  }

  // Build a single voice item
  Widget _buildVoiceItem(
    BuildContext context,
    Voice voice,
    Color avatarColor,
    bool isDarkMode,
    bool isMobile,
  ) {
    // Check if this voice is currently playing
    final bool isPlaying = widget.currentlyPlayingVoiceId == voice.id;

    // Check if this voice was tapped
    final bool wasTapped = _tappedVoices[voice.id] ?? false;

    // Get the voice color if it exists, otherwise use the avatar color
    final Color voiceColor =
        voice.color != null && voice.color!.isNotEmpty
            ? _colorMap[voice.color!] ?? avatarColor
            : avatarColor;

    // Only use animations for the currently playing item
    return isPlaying
        ? _buildPlayingVoiceItem(
          context,
          voice,
          voiceColor,
          isDarkMode,
          isMobile,
          wasTapped,
        )
        : _buildNonPlayingVoiceItem(
          context,
          voice,
          voiceColor,
          isDarkMode,
          isMobile,
          wasTapped,
        );
  }

  // Build a voice item that is currently playing (with animations)
  Widget _buildPlayingVoiceItem(
    BuildContext context,
    Voice voice,
    Color voiceColor,
    bool isDarkMode,
    bool isMobile,
    bool wasTapped,
  ) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        // Create a gentler animation curve
        final curve = CurvedAnimation(
          parent: _animationController,
          curve: Curves.easeInOut,
        );

        // Reduce the scale effect to be more subtle
        final scale = 1.0 + (curve.value * 0.03);

        // Remove the rotation effect as it's causing too much movement
        // Just use a very subtle scale animation instead

        return Transform.scale(
          scale: scale,
          alignment: Alignment.center,
          child: _buildVoiceItemContent(
            context,
            voice,
            voiceColor,
            isDarkMode,
            isMobile,
            wasTapped,
            true, // isPlaying
          ),
        );
      },
    );
  }

  // Build a voice item that is not playing (without animations)
  Widget _buildNonPlayingVoiceItem(
    BuildContext context,
    Voice voice,
    Color voiceColor,
    bool isDarkMode,
    bool isMobile,
    bool wasTapped,
  ) {
    return _buildVoiceItemContent(
      context,
      voice,
      voiceColor,
      isDarkMode,
      isMobile,
      wasTapped,
      false, // isPlaying
    );
  }

  // Common content for both playing and non-playing voice items
  Widget _buildVoiceItemContent(
    BuildContext context,
    Voice voice,
    Color voiceColor,
    bool isDarkMode,
    bool isMobile,
    bool wasTapped,
    bool isPlaying,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      key: ValueKey(voice.id),
      width: isMobile ? 150 : 180,
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color:
            isDarkMode
                ? Theme.of(context).colorScheme.surfaceContainerHighest
                : voiceColor.withOpacity(
                  isPlaying ? 0.15 : 0.1,
                ), // Adjusted opacity for better visibility
        border: Border.all(
          color:
              isDarkMode
                  ? (isPlaying
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.6)
                      : Theme.of(context).colorScheme.outline)
                  : voiceColor.withOpacity(
                    isPlaying ? 0.5 : 0.3,
                  ), // Increased opacity for better visibility
          width: isPlaying ? 2.0 : 1.5, // Maintained thicker borders
        ),
        borderRadius: BorderRadius.circular(8), // Maintained sharper corners
        boxShadow: [
          BoxShadow(
            color:
                isDarkMode
                    ? Colors.black.withOpacity(0.25)
                    : voiceColor.withOpacity(
                      isPlaying ? 0.25 : 0.1,
                    ), // Adjusted shadow opacity
            blurRadius: isPlaying ? 8 : 5, // Maintained larger blur radius
            offset: const Offset(0, 3), // Maintained lower shadow
            spreadRadius: isPlaying ? 1 : 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: _HoverDetector(
          builder: (context, isHovering) {
            return Tooltip(
              message:
                  'Tap to play. Long press or right-click to change color.',
              waitDuration: const Duration(seconds: 1),
              child: GestureDetector(
                // Add GestureDetector to handle right-click (secondary tap)
                onSecondaryTap: () {
                  // Show color selection menu on right-click
                  final RenderBox renderBox =
                      context.findRenderObject() as RenderBox;
                  final position = renderBox.localToGlobal(
                    renderBox.size.center(Offset.zero),
                  );
                  _showColorSelectionMenu(context, voice, position);
                },
                child: InkWell(
                  // Use InkWell for more reliable tap detection
                  onTap: () {
                    // Animate the tap effect
                    setState(() {
                      _tappedVoices[voice.id] = true;
                    });

                    // Reset the animation controller and play it
                    _tapAnimationController.reset();
                    _tapAnimationController.forward().then((_) {
                      setState(() {
                        _tappedVoices[voice.id] = false;
                      });
                    });

                    // Call the onVoiceTap callback
                    widget.onVoiceTap(voice);
                  },
                  onLongPress: () {
                    // Show color selection menu on long press
                    final RenderBox renderBox =
                        context.findRenderObject() as RenderBox;
                    final position = renderBox.localToGlobal(
                      renderBox.size.center(Offset.zero),
                    );
                    _showColorSelectionMenu(context, voice, position);
                  },
                  splashColor: voiceColor.withOpacity(0.3),
                  highlightColor: voiceColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  child: Stack(
                    children: [
                      // Wave animation background when playing
                      if (isPlaying)
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(
                              7,
                            ), // Match container border radius
                            child: AnimatedBuilder(
                              animation: _waveAnimationController,
                              builder: (context, child) {
                                return CustomPaint(
                                  painter: _WavePainter(
                                    animation: _waveAnimationController,
                                    color: voiceColor,
                                    isDarkMode: isDarkMode,
                                  ),
                                  size: Size.infinite,
                                );
                              },
                            ),
                          ),
                        ),

                      // Tap animation overlay
                      if (wasTapped)
                        Positioned.fill(
                          child: AnimatedBuilder(
                            animation: _tapAnimationController,
                            builder: (context, child) {
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  7,
                                ), // Match container border radius
                                child: Opacity(
                                  opacity: 1.0 - _tapAnimationController.value,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: RadialGradient(
                                        colors: [
                                          voiceColor.withOpacity(0.3),
                                          voiceColor.withOpacity(0.0),
                                        ],
                                        center: Alignment.center,
                                        radius:
                                            0.8 +
                                            (_tapAnimationController.value *
                                                0.5),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                      // Play icon overlay when hovering
                      if (isHovering && !isPlaying)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: voiceColor.withOpacity(
                                0.2,
                              ), // Increased opacity for better visibility
                              borderRadius: BorderRadius.circular(
                                7,
                              ), // Match container border radius
                            ),
                            child: Center(
                              child: Icon(
                                Icons.play_arrow_rounded,
                                color: voiceColor.withOpacity(
                                  0.9,
                                ), // Slightly transparent for a softer look
                                size: 36, // Larger icon for better visibility
                                weight: 700, // Bolder icon if available
                              ),
                            ),
                          ),
                        ),

                      // Drag handle indicator (visible on hover)
                      if (isHovering)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: voiceColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Icon(
                              Icons.drag_indicator,
                              size: 16,
                              color: voiceColor.withOpacity(0.8),
                            ),
                          ),
                        ),

                      // Main content
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        child: Row(
                          children: [
                            // Voice icon or playing indicator - Removing the icon
                            isPlaying
                                ? _buildPlayingIndicator(voiceColor)
                                : SizedBox(
                                  width: 4,
                                ), // Replaced icon with small spacer

                            const SizedBox(width: 8),

                            // Voice name and duration
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    voice.name,
                                    style: TextStyle(
                                      fontSize: isMobile ? 13 : 14,
                                      fontWeight:
                                          isPlaying
                                              ? FontWeight.w600
                                              : FontWeight.w500,
                                      color:
                                          isPlaying
                                              ? voiceColor
                                              : Theme.of(
                                                context,
                                              ).colorScheme.onSurface,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),

                                  // Show duration when playing
                                  if (isPlaying)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        _formatDuration(_playbackDuration),
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          color: voiceColor.withOpacity(0.8),
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Animated progress indicator at the bottom
                      if (isPlaying)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: _buildProgressIndicator(voiceColor),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // Format duration as MM:SS
  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  // Build an animated progress indicator
  Widget _buildProgressIndicator(Color color) {
    return AnimatedBuilder(
      animation: _progressAnimationController,
      builder: (context, child) {
        return Stack(
          children: [
            // Base progress bar - now determinate
            LinearProgressIndicator(
              value: _progressAnimationController.value,
              minHeight: 4, // Increased height for better visibility
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(
                color.withOpacity(0.8),
              ), // Increased opacity for better visibility
              borderRadius: BorderRadius.circular(0), // Sharp edges
            ),

            // Pulsing highlight effect - make it more visible
            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      // Create a pulsing highlight that moves across the progress bar
                      return Align(
                        alignment: Alignment(
                          -1.0 + (_animationController.value * 2.0),
                          0,
                        ),
                        child: Container(
                          width:
                              constraints.maxWidth *
                              0.15, // Wider for better visibility
                          height: 4, // Match progress bar height
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                color.withOpacity(0.0),
                                color.withOpacity(
                                  0.7,
                                ), // Increased opacity for better visibility
                                color.withOpacity(0.0),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // Progress markers - simplified
            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(5, (index) {
                      final markerPosition = index / 4;
                      final isActive =
                          _progressAnimationController.value >= markerPosition;

                      return Container(
                        width: 2, // Maintained width
                        height: 4, // Match progress bar height
                        color:
                            isActive
                                ? color.withOpacity(
                                  0.8,
                                ) // Increased opacity for better visibility
                                : color.withOpacity(
                                  0.2,
                                ), // Increased opacity for better visibility
                      );
                    }),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // Build a playing indicator animation
  Widget _buildPlayingIndicator(Color color) {
    return SizedBox(
      width: 22, // Slightly larger for better visibility
      height: 22, // Slightly larger for better visibility
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer pulsing circle - make it more visible
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.9, end: 1.1),
            duration: const Duration(milliseconds: 1500),
            curve: Curves.easeInOut,
            builder: (context, value, child) {
              return Container(
                width: 22 * value, // Slightly larger for better visibility
                height: 22 * value, // Slightly larger for better visibility
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(
                    0.15,
                  ), // Increased opacity for better visibility
                ),
              );
            },
          ),

          // Main progress indicator
          CircularProgressIndicator(
            strokeWidth: 2.5, // Thicker stroke for better visibility
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),

          // Center dot - square instead of circle for more angular look
          Container(
            width: 7, // Slightly larger for better visibility
            height: 7, // Slightly larger for better visibility
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(1.5), // Slightly angular
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // Check if a voice is currently playing
  bool _isVoicePlaying(String voiceId) {
    return widget.currentlyPlayingVoiceId == voiceId;
  }

  // Build an empty drag handle (removed visual elements)
  Widget _buildDragHandle(BuildContext context, bool isDarkMode) {
    return const SizedBox.shrink(); // Empty widget
  }
}

/// A custom implementation of ReorderableWrap
/// This is a simplified version of the ReorderableWrap widget
class ReorderableWrap extends StatefulWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final EdgeInsets padding;
  final Function(int oldIndex, int newIndex) onReorder;
  final Function(int index)? onReorderStarted;
  final Function(int index)? onNoReorder;
  final Function(int index)? onReorderEnd;

  const ReorderableWrap({
    super.key,
    required this.children,
    this.spacing = 0.0,
    this.runSpacing = 0.0,
    this.padding = EdgeInsets.zero,
    required this.onReorder,
    this.onReorderStarted,
    this.onNoReorder,
    this.onReorderEnd,
  });

  @override
  State<ReorderableWrap> createState() => _ReorderableWrapState();
}

class _ReorderableWrapState extends State<ReorderableWrap>
    with SingleTickerProviderStateMixin {
  int? _draggedIndex;
  int? _targetIndex;
  late AnimationController _reorderAnimationController;

  @override
  void initState() {
    super.initState();
    _reorderAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _reorderAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.padding,
      child: AnimatedSize(
        duration: const Duration(milliseconds: 400),
        curve:
            Curves.easeOutBack, // Spring-like curve for more natural animation
        alignment: Alignment.topCenter,
        child: Wrap(
          spacing: widget.spacing,
          runSpacing: widget.runSpacing,
          children: List.generate(
            widget.children.length,
            (index) => _buildDraggable(index),
          ),
        ),
      ),
    );
  }

  Widget _buildDraggable(int index) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final itemWidth = isMobile ? 150.0 : 180.0;

    return LongPressDraggable<int>(
      data: index,
      delay: const Duration(
        milliseconds: 300,
      ), // Increased delay to avoid accidental drags
      hapticFeedbackOnStart: true, // Enable haptic feedback
      dragAnchorStrategy: (draggable, context, position) {
        // Return the center of the draggable
        final RenderBox renderObject = context.findRenderObject() as RenderBox;
        return renderObject.size.center(Offset.zero);
      },
      // Add a handle to make it clear where to drag from
      childWhenDragging: Opacity(
        opacity: 0.2,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1), // Slightly more visible
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
              width: 2,
              strokeAlign: BorderSide.strokeAlignOutside,
            ),
          ),
          child: widget.children[index],
        ),
      ),
      onDragStarted: () {
        // Cancel any long press timer in the parent widget
        final parentState =
            context.findAncestorStateOfType<_ReorderableVoiceGridState>();
        parentState?._longPressTimer?.cancel();

        setState(() {
          _draggedIndex = index;
        });

        // Provide stronger haptic feedback when drag starts
        HapticFeedback.heavyImpact();

        widget.onReorderStarted?.call(index);
      },
      onDragCompleted: () {
        setState(() {
          _draggedIndex = null;
          _targetIndex = null;
        });

        // Play reorder animation
        _reorderAnimationController.forward(from: 0.0);

        widget.onReorderEnd?.call(index);
      },
      onDraggableCanceled: (_, __) {
        setState(() {
          _draggedIndex = null;
          _targetIndex = null;
        });
        widget.onNoReorder?.call(index);
      },
      feedback: Material(
        elevation: 12.0, // Increased elevation for better shadow
        shadowColor: Colors.black54,
        borderRadius: BorderRadius.circular(10),
        animationDuration: const Duration(milliseconds: 150),
        child: Transform.scale(
          scale: 1.05, // Slightly larger when dragging
          child: Container(
            width: itemWidth,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: widget.children[index],
          ),
        ),
      ),
      child: Tooltip(
        message:
            'Long press to reorder', // Add tooltip for better discoverability
        waitDuration: const Duration(seconds: 1), // Show tooltip after 1 second
        child: DragTarget<int>(
          onWillAcceptWithDetails: (details) {
            // Update target index for visual indicator
            if (details.data != index) {
              setState(() {
                _targetIndex = index;
              });
              return true;
            }
            return false;
          },
          onLeave: (_) {
            // Clear target index when drag leaves
            setState(() {
              _targetIndex = null;
            });
          },
          onAcceptWithDetails: (details) {
            final draggedIndex = details.data;

            // Play animation before reordering
            _reorderAnimationController.forward(from: 0.0);

            // Perform the reordering
            widget.onReorder(draggedIndex, index);

            // Add haptic feedback when item is dropped
            HapticFeedback.mediumImpact();

            // Clear target index
            setState(() {
              _targetIndex = null;
            });
          },
          builder: (context, candidateData, rejectedData) {
            final isTarget = candidateData.isNotEmpty;
            final bool isTargetIndex = _targetIndex == index;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutQuart,
              transform:
                  isTarget
                      ? (Matrix4.identity()..scale(1.05))
                      : Matrix4.identity(),
              margin:
                  isTargetIndex
                      ? const EdgeInsets.all(
                        4.0,
                      ) // Add margin to show drop indicator
                      : EdgeInsets.zero,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                boxShadow:
                    isTarget
                        ? [
                          BoxShadow(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.4),
                            blurRadius: 12,
                            spreadRadius: 3,
                          ),
                        ]
                        : null,
              ),
              child:
                  isTarget
                      ? AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutCubic,
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.6),
                            width: 2.5,
                          ),
                        ),
                        child: widget.children[index],
                      )
                      : widget.children[index],
            );
          },
        ),
      ),
    );
  }
}

// Custom painter for wave animation
class _WavePainter extends CustomPainter {
  final Animation<double> animation;
  final Color color;
  final bool isDarkMode;

  _WavePainter({
    required this.animation,
    required this.color,
    required this.isDarkMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color.withOpacity(
            isDarkMode ? 0.06 : 0.05,
          ) // Increased opacity for better visibility
          ..style = PaintingStyle.fill;

    final width = size.width;
    final height = size.height;

    // Create path for first wave
    final path1 = Path();
    path1.moveTo(0, height);

    // First wave parameters - reduced height
    final waveHeight1 = height * 0.08; // Reduced from 0.15
    final frequency1 = 2.0; // Fewer waves
    final phase1 =
        animation.value * 2 * 3.14159; // Phase shift based on animation

    // Draw first wave
    for (var x = 0.0; x <= width; x++) {
      final y =
          height -
          waveHeight1 *
              (0.5 + 0.5 * sin(frequency1 * 2 * 3.14159 * x / width + phase1));
      path1.lineTo(x, y);
    }

    path1.lineTo(width, height);
    path1.close();

    // Draw first wave
    canvas.drawPath(path1, paint);

    // Create path for second wave (offset and different frequency)
    final path2 = Path();
    path2.moveTo(0, height);

    // Second wave parameters - reduced height
    final waveHeight2 = height * 0.05; // Reduced from 0.1
    final frequency2 = 3.0; // Fewer waves (was 5.0)
    final phase2 = -animation.value * 2 * 3.14159; // Opposite phase shift

    // Draw second wave
    for (var x = 0.0; x <= width; x++) {
      final y =
          height -
          waveHeight2 *
              (0.5 + 0.5 * sin(frequency2 * 2 * 3.14159 * x / width + phase2));
      path2.lineTo(x, y);
    }

    path2.lineTo(width, height);
    path2.close();

    // Draw second wave with slightly different opacity
    canvas.drawPath(
      path2,
      paint
        ..color = color.withOpacity(
          isDarkMode ? 0.04 : 0.03,
        ), // Increased opacity for better visibility
    );
  }

  @override
  bool shouldRepaint(_WavePainter oldDelegate) => true;
}

// Hover scale effect widget
class _HoverScaleEffect extends StatefulWidget {
  final Widget Function(BuildContext, bool) builder;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onSecondaryTap;

  const _HoverScaleEffect({
    required this.builder,
    required this.onTap,
    this.onLongPress,
    this.onSecondaryTap,
  });

  @override
  State<_HoverScaleEffect> createState() => _HoverScaleEffectState();
}

class _HoverScaleEffectState extends State<_HoverScaleEffect>
    with SingleTickerProviderStateMixin {
  bool _isHovering = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        onSecondaryTap: widget.onSecondaryTap,
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) => _controller.reverse(),
        onTapCancel: () => _controller.reverse(),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: widget.builder(context, _isHovering),
            );
          },
        ),
      ),
    );
  }
}

/// A widget that detects hover state
class _HoverDetector extends StatefulWidget {
  final Widget Function(BuildContext, bool) builder;

  const _HoverDetector({required this.builder});

  @override
  State<_HoverDetector> createState() => _HoverDetectorState();
}

class _HoverDetectorState extends State<_HoverDetector> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor: SystemMouseCursors.click,
      child: widget.builder(context, _isHovering),
    );
  }
}
