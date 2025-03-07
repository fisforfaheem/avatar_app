import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import '../providers/avatar_provider.dart';
import '../models/avatar.dart';
import 'add_avatar_screen.dart';

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

  // Animation controller for FAB
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // Create animations
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _rotateAnimation = Tween<double>(begin: 0.0, end: 0.125).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AvatarProvider>(
      builder: (context, avatarProvider, child) {
        return Scaffold(
          backgroundColor:
              const Color(0xFFF5F5F7), // Slightly darker background
          appBar: AppBar(
            title: const Text(
              'VOICE AVATAR HUB',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                fontSize: 18,
                color: Colors.black87,
              ),
            ),
            centerTitle: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.black87,
            actions: [
              // Stop button - only show when audio is playing
              if (_currentlyPlayingVoiceId != null)
                Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.08),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.stop_rounded,
                        color: Colors.black87,
                        size: 20,
                      ),
                    ),
                    tooltip: 'Stop playback',
                    onPressed: _stopAllPlayback,
                  ),
                ),
            ],
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: avatarProvider.avatars.isEmpty
                  ? _buildEmptyState()
                  : _buildAllAvatarsView(context, avatarProvider.avatars),
            ),
          ),
          // Animated floating action button
          floatingActionButton: _buildAnimatedFAB(context),
        );
      },
    );
  }

  // Build animated floating action button
  Widget _buildAnimatedFAB(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _animationController.forward(),
      onExit: (_) => _animationController.reverse(),
      child: GestureDetector(
        onTapDown: (_) => _animationController.forward(),
        onTapUp: (_) {
          _animationController.reverse();
          _showAddAvatarDialog(context);
        },
        onTapCancel: () => _animationController.reverse(),
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Transform.rotate(
                angle: _rotateAnimation.value * 3.14159 * 2,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.primary.withBlue(
                              (Theme.of(context).colorScheme.primary.blue + 40)
                                  .clamp(0, 255),
                            ),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            );
          },
        ),
      ),
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

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: avatarColor.withOpacity(0.08),
              border:
                  Border.all(color: avatarColor.withOpacity(0.2), width: 1.5),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: avatarColor.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                // Avatar icon
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: avatarColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: avatarColor.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    avatar.icon,
                    size: 24,
                    color: avatarColor,
                  ),
                ),
                const SizedBox(width: 12),

                // Avatar name and voice count
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        avatar.name.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${avatar.voices.length} voices',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),

                // Add voice button
                TextButton.icon(
                  icon: Icon(Icons.add, size: 16, color: avatarColor),
                  label: Text(
                    'ADD VOICE',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: avatarColor,
                    ),
                  ),
                  onPressed: () {
                    Navigator.pushNamed(context, '/avatar/${avatar.id}');
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: avatarColor,
                    backgroundColor: avatarColor.withOpacity(0.12),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    visualDensity: VisualDensity.compact,
                    minimumSize: const Size(0, 32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),

                // Edit avatar button
                IconButton(
                  icon: const Icon(
                    Icons.edit_outlined,
                    size: 20,
                    color: Colors.black54,
                  ),
                  tooltip: 'Edit Avatar',
                  onPressed: () {
                    Navigator.pushNamed(context, '/avatar/${avatar.id}');
                  },
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                ),
              ],
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
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: _buildVoiceGrid(context, avatar.voices, avatarColor),
              ),
            ),
        ],
      ),
    );
  }

  // Build a grid of voices with 3 items per column
  Widget _buildVoiceGrid(
      BuildContext context, List<Voice> voices, Color avatarColor) {
    // Calculate how many columns we need
    final int totalVoices = voices.length;
    final int columnsNeeded = (totalVoices / 3).ceil();

    // Create a list of columns
    List<Widget> columns = [];

    for (int colIndex = 0; colIndex < columnsNeeded; colIndex++) {
      // Calculate start and end indices for this column
      final int startIdx = colIndex * 3;
      final int endIdx =
          (startIdx + 3 <= totalVoices) ? startIdx + 3 : totalVoices;

      // Create a list of voice items for this column
      List<Widget> columnItems = [];
      for (int i = startIdx; i < endIdx; i++) {
        columnItems.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _buildCompactVoiceItem(context, voices[i], avatarColor),
          ),
        );
      }

      // Add this column to our list of columns
      columns.add(
        Container(
          margin: const EdgeInsets.only(right: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: columnItems,
          ),
        ),
      );
    }

    // Return a row of columns
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: columns,
    );
  }

  // Build compact voice item
  Widget _buildCompactVoiceItem(
      BuildContext context, Voice voice, Color avatarColor) {
    final bool isPlaying = _currentlyPlayingVoiceId == voice.id;

    return Container(
      width: 160, // Slightly wider for more substantial feel
      decoration: BoxDecoration(
        color: isPlaying
            ? avatarColor.withOpacity(0.18)
            : avatarColor.withOpacity(0.08),
        border: Border.all(
          color: avatarColor.withOpacity(isPlaying ? 0.4 : 0.15),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: avatarColor.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => _playOrPauseVoice(voice),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                if (isPlaying)
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: avatarColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                Expanded(
                  child: Text(
                    voice.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isPlaying ? FontWeight.w600 : FontWeight.w500,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
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

        // Listen for completion to update UI
        _audioPlayer.onPlayerComplete.listen((event) {
          if (mounted) {
            setState(() {
              _currentlyPlayingVoiceId = null;
            });
          }
        });
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
            child: Icon(
              Icons.record_voice_over,
              size: 72,
              color: themeColor,
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'NO AVATARS YET',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Create your first avatar to start building your voice collection',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black54,
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
              style: TextStyle(
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: themeColor,
              foregroundColor: Colors.white,
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
}
