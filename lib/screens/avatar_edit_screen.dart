import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../models/avatar.dart';
import '../providers/avatar_provider.dart';

class AvatarEditScreen extends StatefulWidget {
  final Avatar avatar;

  const AvatarEditScreen({super.key, required this.avatar});

  @override
  State<AvatarEditScreen> createState() => _AvatarEditScreenState();
}

class _AvatarEditScreenState extends State<AvatarEditScreen> {
  late TextEditingController _nameController;
  late IconData _selectedIcon;
  late String _selectedColor;
  File? _selectedImage;
  bool _isImageLoading = false;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.avatar.name);
    _selectedIcon = widget.avatar.icon;
    _selectedColor = widget.avatar.color;

    // Initialize image if avatar has one
    if (widget.avatar.imagePath != null) {
      _selectedImage = File(widget.avatar.imagePath!);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

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
    final avatarProvider = Provider.of<AvatarProvider>(context, listen: false);
    final isDesktop = MediaQuery.of(context).size.width > 900;
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // Function to handle avatar update
    void updateAvatar() async {
      if (_nameController.text.trim().isEmpty) {
        // Show error message
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Please enter a name for your avatar',
              style: TextStyle(
                color: isDarkMode ? theme.colorScheme.onInverseSurface : null,
              ),
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor:
                isDarkMode ? theme.colorScheme.inverseSurface : null,
          ),
        );
        return;
      }

      // Update the avatar
      if (!mounted) return;
      avatarProvider.updateAvatar(
        widget.avatar.id,
        name: _nameController.text.trim(),
        color: _selectedColor,
        icon: _selectedIcon,
        imagePath: _selectedImage?.path,
      );

      if (!mounted) return;
      Navigator.of(context).pop();
    }

    // Function to handle cancellation
    void cancelEditing() {
      if (!mounted) return;
      Navigator.of(context).pop();
    }

    // Build the form section
    Widget buildFormSection() {
      final theme = Theme.of(context);
      final isDarkMode = theme.brightness == Brightness.dark;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image picker section
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Avatar Image (Optional)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: GestureDetector(
                    onTap: _isImageLoading ? null : _pickImage,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _getColorFromString(
                            _selectedColor,
                          ).withOpacity(0.5),
                          width: 2,
                        ),
                      ),
                      child:
                          _isImageLoading
                              ? Center(
                                child: CircularProgressIndicator(
                                  color: _getColorFromString(_selectedColor),
                                ),
                              )
                              : _selectedImage != null
                              ? Stack(
                                fit: StackFit.expand,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: Image.file(
                                      _selectedImage!,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 5,
                                    right: 5,
                                    child: Material(
                                      color: Colors.black54,
                                      shape: const CircleBorder(),
                                      child: InkWell(
                                        customBorder: const CircleBorder(),
                                        onTap: _removeImage,
                                        child: const Padding(
                                          padding: EdgeInsets.all(4.0),
                                          child: Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                              : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_photo_alternate_outlined,
                                    size: 40,
                                    color: _getColorFromString(
                                      _selectedColor,
                                    ).withOpacity(0.7),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Tap to add image',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Name input with animated label
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Avatar Name',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Enter a name for your avatar',
                    hintStyle: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: theme.colorScheme.outline,
                        width: 1.5,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: theme.colorScheme.outline.withOpacity(0.7),
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: _getColorFromString(_selectedColor),
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor:
                        isDarkMode
                            ? theme.colorScheme.surfaceContainerHighest
                            : theme.colorScheme.surface,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    prefixIcon: Icon(
                      Icons.person_outline,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: 16,
                  ),
                  onSubmitted: (_) => updateAvatar(),
                ),
              ],
            ),
          ),

          // Icon selection
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose an Icon',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                _buildIconGrid(avatarProvider.predefinedIcons),
              ],
            ),
          ),

          // Color selection
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose a Color',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                _buildColorGrid(avatarProvider.predefinedColors),
              ],
            ),
          ),
        ],
      );
    }

    // Build the preview section
    Widget buildPreviewSection() {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutBack,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color:
              isDarkMode
                  ? theme.colorScheme.surfaceContainerHighest
                  : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _getColorFromString(_selectedColor).withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: _getColorFromString(_selectedColor).withOpacity(0.2),
              blurRadius: 20,
              spreadRadius: 0,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Preview',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 32),
            // Avatar preview with animated container
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _getColorFromString(_selectedColor),
                boxShadow: [
                  BoxShadow(
                    color: _getColorFromString(_selectedColor).withOpacity(0.4),
                    blurRadius: 24,
                    spreadRadius: 4,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child:
                  _selectedImage != null
                      ? ClipOval(
                        child: Image.file(
                          _selectedImage!,
                          fit: BoxFit.cover,
                          width: 160,
                          height: 160,
                        ),
                      )
                      : Icon(_selectedIcon, size: 80, color: Colors.white),
            ),
            const SizedBox(height: 32),
            // Avatar name preview
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
                letterSpacing: 0.5,
              ),
              child: Text(
                _nameController.text.isEmpty
                    ? 'Your Avatar'
                    : _nameController.text,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'This is how your avatar will appear in the app',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (isDesktop) ...[
              const SizedBox(height: 48),
              // Save button for desktop in preview section
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: updateAvatar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getColorFromString(_selectedColor),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  child: const Text(
                    'SAVE AVATAR',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Cancel button for desktop
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: cancelEditing,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.onSurface,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(
                      color: theme.colorScheme.outline,
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'CANCEL',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Delete button for desktop
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    if (!mounted) return;
                    showDialog(
                      context: context,
                      builder:
                          (context) => AlertDialog(
                            title: const Text('Delete Avatar?'),
                            content: const Text(
                              'This will permanently delete this avatar and all associated voice samples. This action cannot be undone.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Cancel'),
                              ),
                              FilledButton(
                                onPressed: () {
                                  if (!mounted) return;
                                  avatarProvider.removeAvatar(widget.avatar.id);
                                  Navigator.of(context).pop(); // Close dialog
                                  Navigator.of(
                                    context,
                                  ).pop(); // Return to previous screen
                                },
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                    );
                  },
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  label: const Text(
                    'DELETE AVATAR',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Focus(
      autofocus: true,
      onKeyEvent:
          isDesktop
              ? (node, event) {
                // Handle keyboard shortcuts for desktop
                if (event.runtimeType.toString() == 'KeyDownEvent') {
                  // Escape key to cancel
                  if (event.logicalKey == LogicalKeyboardKey.escape) {
                    cancelEditing();
                    return KeyEventResult.handled;
                  }

                  // Enter key to save
                  if (event.logicalKey == LogicalKeyboardKey.enter &&
                      (HardwareKeyboard.instance.isControlPressed ||
                          HardwareKeyboard.instance.isMetaPressed)) {
                    updateAvatar();
                    return KeyEventResult.handled;
                  }
                }
                return KeyEventResult.ignored;
              }
              : null,
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: AppBar(
          title: Text(
            'Edit Avatar',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: _AnimatedIconButton(
            icon: Icons.arrow_back,
            color: theme.colorScheme.onSurface,
            hoverColor: _getColorFromString(_selectedColor),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Back',
          ),
          actions: [
            if (!isDesktop)
              _AnimatedTextButton(
                text: 'SAVE',
                onPressed: updateAvatar,
                color: _getColorFromString(_selectedColor),
              ),
          ],
        ),
        body:
            isDesktop
                // Two-column layout for desktop
                ? Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Form section (left column)
                    Expanded(
                      flex: 3,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(32.0),
                        child: buildFormSection(),
                      ),
                    ),
                    // Preview section (right column)
                    Expanded(
                      flex: 2,
                      child: Container(
                        color:
                            isDarkMode
                                ? theme.colorScheme.surfaceContainerLow
                                : theme.colorScheme.surfaceContainerLowest,
                        padding: const EdgeInsets.all(32.0),
                        child: Center(child: buildPreviewSection()),
                      ),
                    ),
                  ],
                )
                // Single column layout for mobile
                : SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      buildFormSection(),
                      const SizedBox(height: 32),
                      buildPreviewSection(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
      ),
    );
  }

  Widget _buildIconGrid(List<IconData> icons) {
    final avatarProvider = Provider.of<AvatarProvider>(context, listen: false);
    final isDesktop = MediaQuery.of(context).size.width > 900;
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color:
            isDarkMode
                ? theme.colorScheme.surfaceContainerHighest
                : Colors.white,
        border: Border.all(
          color: isDarkMode ? theme.colorScheme.outline : Colors.grey.shade200,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color:
                isDarkMode
                    ? Colors.black.withOpacity(0.2)
                    : Colors.black.withOpacity(0.03),
            blurRadius: 4,
            spreadRadius: 0,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: isDesktop ? 8 : 5,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.0,
        ),
        itemCount: icons.length,
        itemBuilder: (context, index) {
          final icon = icons[index];
          final isSelected = _selectedIcon == icon;

          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                if (!mounted) return;
                setState(() {
                  _selectedIcon = icon;
                });
              },
              borderRadius: BorderRadius.circular(8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color:
                      isSelected
                          ? theme.colorScheme.primary.withOpacity(0.1)
                          : isDarkMode
                          ? theme.colorScheme.surface
                          : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color:
                        isSelected
                            ? theme.colorScheme.primary
                            : isDarkMode
                            ? theme.colorScheme.outline
                            : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Icon(
                  icon,
                  size: 28,
                  color:
                      isSelected
                          ? theme.colorScheme.primary
                          : isDarkMode
                          ? theme.colorScheme.onSurface
                          : Colors.grey.shade700,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildColorGrid(List<String> colors) {
    final avatarProvider = Provider.of<AvatarProvider>(context, listen: false);
    final isDesktop = MediaQuery.of(context).size.width > 900;
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      height: isDesktop ? 140 : 90,
      width: double.infinity,
      decoration: BoxDecoration(
        color:
            isDarkMode
                ? theme.colorScheme.surfaceContainerHighest
                : Colors.white,
        border: Border.all(
          color: isDarkMode ? theme.colorScheme.outline : Colors.grey.shade200,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color:
                isDarkMode
                    ? Colors.black.withOpacity(0.2)
                    : Colors.black.withOpacity(0.03),
            blurRadius: 4,
            spreadRadius: 0,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child:
          isDesktop
              // Grid layout for desktop
              ? GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 10,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.0,
                ),
                itemCount: colors.length,
                itemBuilder: (context, index) {
                  final color = colors[index];
                  final isSelected = _selectedColor == color;

                  return InkWell(
                    onTap: () {
                      if (!mounted) return;
                      setState(() {
                        _selectedColor = color;
                      });
                    },
                    borderRadius: BorderRadius.circular(30),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: _getColorFromString(color),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.white : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _getColorFromString(
                              color,
                            ).withOpacity(isSelected ? 0.5 : 0.3),
                            blurRadius: isSelected ? 12 : 4,
                            spreadRadius: isSelected ? 2 : 0,
                          ),
                        ],
                      ),
                      child:
                          isSelected
                              ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 24,
                              )
                              : null,
                    ),
                  );
                },
              )
              // Horizontal list for mobile
              : ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(16),
                itemCount: colors.length,
                itemBuilder: (context, index) {
                  final color = colors[index];
                  final isSelected = _selectedColor == color;

                  return Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: InkWell(
                      onTap: () {
                        if (!mounted) return;
                        setState(() {
                          _selectedColor = color;
                        });
                      },
                      borderRadius: BorderRadius.circular(30),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: _getColorFromString(color),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color:
                                isSelected ? Colors.white : Colors.transparent,
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _getColorFromString(
                                color,
                              ).withOpacity(isSelected ? 0.5 : 0.3),
                              blurRadius: isSelected ? 12 : 4,
                              spreadRadius: isSelected ? 2 : 0,
                            ),
                          ],
                        ),
                        child:
                            isSelected
                                ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 24,
                                )
                                : null,
                      ),
                    ),
                  );
                },
              ),
    );
  }

  // Pick image from gallery
  Future<void> _pickImage() async {
    if (!mounted) return;
    setState(() {
      _isImageLoading = true;
    });

    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        if (!mounted) return;
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isImageLoading = false;
      });
    }
  }

  // Remove the selected image
  void _removeImage() {
    if (!mounted) return;
    setState(() {
      _selectedImage = null;
    });
  }
}

// Animated Icon Button for app bar icons
class _AnimatedIconButton extends StatefulWidget {
  final IconData icon;
  final Color color;
  final Color hoverColor;
  final VoidCallback onPressed;
  final String tooltip;

  const _AnimatedIconButton({
    required this.icon,
    required this.color,
    required this.hoverColor,
    required this.onPressed,
    required this.tooltip,
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
                    color: Color.lerp(widget.color, widget.hoverColor, value),
                    size: 24,
                  ),
                ),
              );
            },
          ),
          onPressed: widget.onPressed,
          splashRadius: 24,
        ),
      ),
    );
  }
}

// Animated Text Button for app bar actions
class _AnimatedTextButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final Color color;

  const _AnimatedTextButton({
    required this.text,
    required this.onPressed,
    required this.color,
  });

  @override
  State<_AnimatedTextButton> createState() => _AnimatedTextButtonState();
}

class _AnimatedTextButtonState extends State<_AnimatedTextButton> {
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
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutBack,
        builder: (context, value, child) {
          return TextButton(
            onPressed: widget.onPressed,
            style: TextButton.styleFrom(
              foregroundColor: widget.color,
              backgroundColor: widget.color.withOpacity(value * 0.1),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Transform.scale(
              scale: 1.0 + (value * 0.05),
              child: Text(
                widget.text,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: widget.color,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
