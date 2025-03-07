import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/avatar_provider.dart';

class AddAvatarScreen extends StatefulWidget {
  const AddAvatarScreen({super.key});

  @override
  State<AddAvatarScreen> createState() => _AddAvatarScreenState();
}

class _AddAvatarScreenState extends State<AddAvatarScreen> {
  final TextEditingController _nameController = TextEditingController();
  late IconData _selectedIcon;
  late String _selectedColor;

  @override
  void initState() {
    super.initState();
    // Initialize with default values
    final avatarProvider = Provider.of<AvatarProvider>(context, listen: false);
    _selectedIcon = avatarProvider.predefinedIcons.first;
    _selectedColor = avatarProvider.predefinedColors.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final avatarProvider = Provider.of<AvatarProvider>(context, listen: false);
    final isDesktop = MediaQuery.of(context).size.width > 900;
    final theme = Theme.of(context);

    // Function to handle avatar creation
    void createAvatar() {
              if (_nameController.text.trim().isEmpty) {
                // Show error message
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a name for your avatar'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }

              Navigator.of(context).pop({
                'name': _nameController.text.trim(),
                'icon': _selectedIcon,
                'color': _selectedColor,
              });
    }

    // Function to handle cancellation
    void cancelCreation() {
      Navigator.of(context).pop();
    }

    return Focus(
      autofocus: true,
      onKeyEvent: isDesktop
          ? (node, event) {
              // Handle keyboard shortcuts for desktop
              if (event.runtimeType.toString() == 'KeyDownEvent') {
                // Escape key to cancel
                if (event.logicalKey == LogicalKeyboardKey.escape) {
                  cancelCreation();
                  return KeyEventResult.handled;
                }

                // Enter key with Ctrl/Cmd to create
                if (event.logicalKey == LogicalKeyboardKey.enter &&
                    (HardwareKeyboard.instance.isControlPressed ||
                        HardwareKeyboard.instance.isMetaPressed)) {
                  createAvatar();
                  return KeyEventResult.handled;
                }
              }
              return KeyEventResult.ignored;
            }
          : null,
      child: Scaffold(
        backgroundColor: isDesktop ? Colors.grey.shade50 : Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'Create New Avatar',
            style: TextStyle(
              fontWeight: FontWeight.w400,
              fontSize: 18,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: cancelCreation,
            tooltip: 'Cancel (Esc)',
            style: IconButton.styleFrom(
              foregroundColor: theme.colorScheme.onSurface,
            ),
          ),
          actions: [
            if (isDesktop)
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Tooltip(
                  message: 'Cancel (Esc)',
                  child: TextButton.icon(
                    onPressed: cancelCreation,
                    icon: const Icon(Icons.cancel_outlined, size: 18),
                    label: const Text('Cancel'),
                    style: TextButton.styleFrom(
                      foregroundColor:
                          theme.colorScheme.onSurface.withOpacity(0.8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                    ),
                  ),
                ),
              ),
            Padding(
              padding: EdgeInsets.only(right: isDesktop ? 16.0 : 8.0),
              child: isDesktop
                  ? Tooltip(
                      message: 'Create Avatar (Ctrl+Enter)',
                      child: ElevatedButton.icon(
                        onPressed: createAvatar,
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Create Avatar'),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: theme.colorScheme.primary,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    )
                  : TextButton(
                      onPressed: createAvatar,
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.primary,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: const Text(
                        'Create',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                    ),
          ),
        ],
      ),
        body: Center(
          child: Container(
            width: isDesktop ? 800 : double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 40 : 20,
              vertical: isDesktop ? 32 : 20,
            ),
            decoration: isDesktop
                ? BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        spreadRadius: 0,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  )
                : null,
            child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name field
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Avatar Name',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurface.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              autofocus: true,
                        decoration: InputDecoration(
                hintText: 'Enter avatar name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: theme.colorScheme.primary,
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

            // Icon selection
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
              'Choose an Icon',
              style: TextStyle(
                          fontSize: 14,
                fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
                      const SizedBox(height: 12),
            Container(
                        height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 4,
                              spreadRadius: 0,
                              offset: const Offset(0, 1),
                            ),
                          ],
              ),
              child: GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: isDesktop ? 8 : 5,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                  childAspectRatio: 1.0,
                ),
                itemCount: avatarProvider.predefinedIcons.length,
                itemBuilder: (context, index) {
                  final icon = avatarProvider.predefinedIcons[index];
                  final isSelected = _selectedIcon == icon;

                            return Material(
                              color: Colors.transparent,
                              child: InkWell(
                    onTap: () {
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
                        color: isSelected
                                        ? theme.colorScheme.primary
                                            .withOpacity(0.1)
                                        : Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                                          ? theme.colorScheme.primary
                                          : Colors.grey.shade300,
                                      width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Icon(
                        icon,
                        size: 28,
                        color: isSelected
                                        ? theme.colorScheme.primary
                            : Colors.grey.shade700,
                                  ),
                      ),
                    ),
                  );
                },
              ),
            ),
                    ],
                  ),
                  const SizedBox(height: 32),

            // Color selection
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
              'Choose a Color',
              style: TextStyle(
                          fontSize: 14,
                fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
                      const SizedBox(height: 12),
            Container(
                        height: isDesktop ? 140 : 90,
              width: double.infinity,
              decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 4,
                              spreadRadius: 0,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: isDesktop
                            // Grid layout for desktop
                            ? GridView.builder(
                                padding: const EdgeInsets.all(16),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 10,
                                  mainAxisSpacing: 16,
                                  crossAxisSpacing: 16,
                                  childAspectRatio: 1.0,
                                ),
                                itemCount:
                                    avatarProvider.predefinedColors.length,
                                itemBuilder: (context, index) {
                                  final color =
                                      avatarProvider.predefinedColors[index];
                                  final isSelected = _selectedColor == color;

                                  return InkWell(
                                    onTap: () {
                                      setState(() {
                                        _selectedColor = color;
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(30),
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      decoration: BoxDecoration(
                                        color: _getColorFromString(color),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isSelected
                                              ? Colors.white
                                              : Colors.transparent,
                                          width: 3,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: _getColorFromString(color)
                                                .withOpacity(
                                                    isSelected ? 0.5 : 0.3),
                                            blurRadius: isSelected ? 12 : 4,
                                            spreadRadius: isSelected ? 2 : 0,
                                          ),
                                        ],
                                      ),
                                      child: isSelected
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
                                itemCount:
                                    avatarProvider.predefinedColors.length,
                itemBuilder: (context, index) {
                                  final color =
                                      avatarProvider.predefinedColors[index];
                  final isSelected = _selectedColor == color;

                  return Padding(
                                    padding: const EdgeInsets.only(right: 16),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedColor = color;
                        });
                      },
                                      borderRadius: BorderRadius.circular(30),
                                      child: AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 200),
                                        width: 56,
                                        height: 56,
                        decoration: BoxDecoration(
                          color: _getColorFromString(color),
                          shape: BoxShape.circle,
                          border: Border.all(
                                            color: isSelected
                                                ? Colors.white
                                                : Colors.transparent,
                                            width: 3,
                                          ),
                                          boxShadow: [
                                  BoxShadow(
                                    color: _getColorFromString(color)
                                                  .withOpacity(
                                                      isSelected ? 0.5 : 0.3),
                                              blurRadius: isSelected ? 12 : 4,
                                              spreadRadius: isSelected ? 2 : 0,
                                            ),
                                          ],
                                        ),
                                        child: isSelected
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
                      ),
                    ],
            ),

            // Preview section
            const SizedBox(height: 40),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
              'Preview',
              style: TextStyle(
                          fontSize: 14,
                fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
                      const SizedBox(height: 24),
            Center(
              child: Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                spreadRadius: 0,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _getColorFromString(_selectedColor),
                  boxShadow: [
                    BoxShadow(
                                      color: _getColorFromString(_selectedColor)
                                          .withOpacity(0.3),
                                      blurRadius: 16,
                      spreadRadius: 2,
                                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(
                  _selectedIcon,
                  size: 60,
                  color: Colors.white,
                ),
              ),
                              const SizedBox(height: 20),
                              Text(
                _nameController.text.isEmpty
                    ? 'Your Avatar'
                    : _nameController.text,
                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              if (isDesktop) ...[
                                const SizedBox(height: 24),
                                Text(
                                  'This is how your avatar will appear in the app',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ],
                ),
              ),
            ),
          ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
