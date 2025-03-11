import 'package:flutter/material.dart';
import '../models/avatar.dart';
import 'package:provider/provider.dart';
import '../providers/avatar_provider.dart';
import '../screens/edit_avatar_screen.dart';

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
    final isDesktop = screenWidth > 900;
    final isMobile = screenWidth < 600;

    // Adjust cross axis count based on screen size
    final crossAxisCount =
        screenWidth > 1200
            ? 4
            : screenWidth > 900
            ? 3
            : screenWidth > 600
            ? 2
            : 1;

    // Calculate a minimum height for the grid based on the number of items
    // This ensures the grid has a size during initial rendering
    final totalItems = widget.avatars.length + 1; // +1 for the "Add" tile
    final rowCount = (totalItems / crossAxisCount).ceil();
    final minHeight =
        rowCount * (isMobile ? 180.0 : 220.0); // Adjust height based on device

    return Container(
      // Add a minimum height constraint to ensure the grid has a size
      constraints: BoxConstraints(minHeight: minHeight),
      child: GridView.count(
        crossAxisCount: crossAxisCount,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: isMobile ? 12 : 20,
        crossAxisSpacing: isMobile ? 12 : 20,
        childAspectRatio:
            isDesktop
                ? 1.1
                : isMobile
                ? 1.3
                : 1.2,
        children: [
          ...widget.avatars.asMap().entries.map((entry) {
            final index = entry.key;
            final avatar = entry.value;
            return AnimatedOpacity(
              opacity: _visibleItems > index ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              child: TweenAnimationBuilder<double>(
                tween: Tween(
                  begin: 20.0,
                  end: _visibleItems > index ? 0.0 : 20.0,
                ),
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
          // Add avatar tile
          AnimatedOpacity(
            opacity: _visibleItems > widget.avatars.length ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            child: TweenAnimationBuilder<double>(
              tween: Tween(
                begin: 20.0,
                end: _visibleItems > widget.avatars.length ? 0.0 : 20.0,
              ),
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
      ),
    );
  }
}

class AvatarTile extends StatefulWidget {
  final Avatar avatar;

  const AvatarTile({super.key, required this.avatar});

  @override
  State<AvatarTile> createState() => _AvatarTileState();
}

class _AvatarTileState extends State<AvatarTile> {
  bool _isHovered = false;

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

  @override
  Widget build(BuildContext context) {
    final color = _getColorFromString(widget.avatar.color);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;
    final isMobile = screenWidth < 600;
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: _isHovered && isDesktop ? -5 : 0),
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Transform.translate(offset: Offset(0, value), child: child);
        },
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color:
                    _isHovered && isDesktop
                        ? color.withOpacity(0.3)
                        : isDarkMode
                        ? Colors.black.withOpacity(0.2)
                        : Colors.black.withOpacity(0.05),
                blurRadius: _isHovered && isDesktop ? 12 : 5,
                offset: const Offset(0, 3),
                spreadRadius: _isHovered && isDesktop ? 1 : 0,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () {
                Navigator.pushNamed(context, '/avatar/${widget.avatar.id}');
              },
              child: Padding(
                padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar icon and voice count
                    Row(
                      children: [
                        // Avatar icon
                        Container(
                          width: isMobile ? 48 : 56,
                          height: isMobile ? 48 : 56,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Icon(
                              widget.avatar.icon,
                              color: Colors.white,
                              size: isMobile ? 24 : 28,
                            ),
                          ),
                        ),
                        const Spacer(),
                        // Voice count badge
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 8 : 10,
                            vertical: isMobile ? 3 : 4,
                          ),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.mic,
                                size: isMobile ? 14 : 16,
                                color: color,
                              ),
                              SizedBox(width: isMobile ? 3 : 4),
                              Text(
                                '${widget.avatar.voices.length}',
                                style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.w500,
                                  fontSize: isMobile ? 12 : 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isMobile ? 12 : 16),
                    // Avatar name
                    Text(
                      widget.avatar.name,
                      style: TextStyle(
                        fontSize: isMobile ? 16 : 18,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: isMobile ? 2 : 4),
                    // Last updated
                    Text(
                      'Updated ${_formatDate(widget.avatar.voices.isNotEmpty ? widget.avatar.voices.last.createdAt : DateTime.now())}',
                      style: TextStyle(
                        fontSize: isMobile ? 10 : 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    // View button - show on hover for desktop, always show for mobile
                    if (_isHovered && isDesktop || isMobile)
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton.tonal(
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              '/avatar/${widget.avatar.id}',
                            );
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: color.withOpacity(0.1),
                            foregroundColor: color,
                            padding: EdgeInsets.symmetric(
                              horizontal: isMobile ? 10 : 12,
                              vertical: isMobile ? 6 : 8,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'View Details',
                            style: TextStyle(fontSize: isMobile ? 12 : 14),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class AddAvatarTile extends StatefulWidget {
  final VoidCallback onTap;

  const AddAvatarTile({super.key, required this.onTap});

  @override
  State<AddAvatarTile> createState() => _AddAvatarTileState();
}

class _AddAvatarTileState extends State<AddAvatarTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;
    final isMobile = screenWidth < 600;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: _isHovered && isDesktop ? -5 : 0),
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Transform.translate(offset: Offset(0, value), child: child);
        },
        child: Container(
          decoration: BoxDecoration(
            color:
                _isHovered && isDesktop
                    ? primaryColor.withOpacity(0.05)
                    : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  _isHovered && isDesktop
                      ? primaryColor
                      : isDarkMode
                      ? theme.colorScheme.outline
                      : Colors.grey.shade200,
              width: 2,
              style: BorderStyle.solid,
            ),
            boxShadow: [
              if (_isHovered && isDesktop)
                BoxShadow(
                  color: primaryColor.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: widget.onTap,
              child: Padding(
                padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: isMobile ? 56 : 64,
                      height: isMobile ? 56 : 64,
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.add,
                        size: isMobile ? 28 : 32,
                        color: primaryColor,
                      ),
                    ),
                    SizedBox(height: isMobile ? 12 : 16),
                    Text(
                      'Create New Avatar',
                      style: TextStyle(
                        fontSize: isMobile ? 14 : 16,
                        fontWeight: FontWeight.w500,
                        color: primaryColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
