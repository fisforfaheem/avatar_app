import 'package:flutter/material.dart';
import '../models/avatar.dart';

class AvatarGrid extends StatefulWidget {
  final List<Avatar> avatars;
  final VoidCallback onAddAvatar;

  const AvatarGrid({
    super.key,
    required this.avatars,
    required this.onAddAvatar,
  });

  @override
  State<AvatarGrid> createState() => _AvatarGridState();
}

class _AvatarGridState extends State<AvatarGrid> {
  int _visibleItems = 0;

  @override
  void initState() {
    super.initState();
    _animateItems();
  }

  @override
  void didUpdateWidget(AvatarGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.avatars.length != widget.avatars.length) {
      _visibleItems = 0;
      _animateItems();
    }
  }

  void _animateItems() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      setState(() {
        _visibleItems = 0;
      });
      _showNextItem();
    });
  }

  void _showNextItem() {
    if (!mounted) return;
    setState(() {
      if (_visibleItems <= widget.avatars.length) {
        _visibleItems++;
        Future.delayed(const Duration(milliseconds: 100), _showNextItem);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Get the screen width to determine the grid layout
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 1200
        ? 4
        : screenWidth > 900
            ? 3
            : screenWidth > 600
                ? 2
                : 1;

    return GridView.count(
      crossAxisCount: crossAxisCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.2,
      children: [
        ...widget.avatars.asMap().entries.map((entry) {
          final index = entry.key;
          final avatar = entry.value;
          return AnimatedOpacity(
            opacity: _visibleItems > index ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            child: TweenAnimationBuilder<double>(
              tween:
                  Tween(begin: 20.0, end: _visibleItems > index ? 0.0 : 20.0),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, value),
                  child: child,
                );
              },
              child: AvatarTile(avatar: avatar),
            ),
          );
        }),
        // Add New Avatar Tile
        if (_visibleItems > widget.avatars.length)
          AnimatedOpacity(
            opacity: 1.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 20.0, end: 0.0),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, value),
                  child: child,
                );
              },
              child: AddAvatarTile(onTap: widget.onAddAvatar),
            ),
          ),
      ],
    );
  }
}

class AvatarTile extends StatelessWidget {
  final Avatar avatar;

  const AvatarTile({
    super.key,
    required this.avatar,
  });

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
      default:
        return const Color(0xFF007AFF); // Default to iOS blue
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColorFromString(avatar.color);

    return Card(
      elevation: 2,
      shadowColor: color.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, '/avatar/${avatar.id}');
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar Circle with Initial
                  Container(
                    width: 48,
                    height: 48,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.2),
                    ),
                    child: Center(
                      child: Text(
                        avatar.name[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w300,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  Text(
                    avatar.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w300,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${avatar.voices.length} ${avatar.voices.length == 1 ? 'voice' : 'voices'}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      avatar.voices.isEmpty ? Icons.mic_none : Icons.mic,
                      size: 16,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      avatar.voices.isEmpty
                          ? 'Add your first voice'
                          : 'Tap to manage voices',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AddAvatarTile extends StatelessWidget {
  final VoidCallback onTap;

  const AddAvatarTile({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shadowColor: Colors.grey.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.grey.shade200,
              width: 2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey.shade100,
                ),
                child: Icon(
                  Icons.add_circle_outline,
                  size: 32,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Add New Avatar',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w300,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Create a voice collection',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
