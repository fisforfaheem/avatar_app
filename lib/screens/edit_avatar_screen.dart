import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/avatar_provider.dart';
import '../models/avatar.dart';

class EditAvatarScreen extends StatefulWidget {
  final Avatar avatar;

  const EditAvatarScreen({
    super.key,
    required this.avatar,
  });

  @override
  State<EditAvatarScreen> createState() => _EditAvatarScreenState();
}

class _EditAvatarScreenState extends State<EditAvatarScreen> {
  late TextEditingController _nameController;
  late IconData _selectedIcon;
  late String _selectedColor;

  @override
  void initState() {
    super.initState();
    // Initialize with avatar values
    _nameController = TextEditingController(text: widget.avatar.name);
    _selectedIcon = widget.avatar.icon;
    _selectedColor = widget.avatar.color;
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

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edit Avatar',
          style: TextStyle(fontWeight: FontWeight.w300),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: () {
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

              // Update the avatar
              avatarProvider.updateAvatar(
                widget.avatar.id,
                name: _nameController.text.trim(),
                icon: _selectedIcon,
                color: _selectedColor,
              );

              // Return true to indicate the avatar was updated
              Navigator.of(context).pop(true);
            },
            child: const Text('Save'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name field
            TextField(
              controller: _nameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Avatar Name',
                hintText: 'Enter avatar name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),

            // Icon selection
            const Text(
              'Choose an Icon',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 15),
            Container(
              height: 200, // Fixed height
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.0,
                ),
                itemCount: avatarProvider.predefinedIcons.length,
                itemBuilder: (context, index) {
                  final icon = avatarProvider.predefinedIcons[index];
                  final isSelected = _selectedIcon == icon;

                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedIcon = icon;
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Theme.of(context).primaryColor.withOpacity(0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? Theme.of(context).primaryColor
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        icon,
                        size: 28,
                        color: isSelected
                            ? Theme.of(context).primaryColor
                            : Colors.grey.shade700,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 30),

            // Color selection
            const Text(
              'Choose a Color',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 15),
            Container(
              height: 80, // Fixed height
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(12),
                itemCount: avatarProvider.predefinedColors.length,
                itemBuilder: (context, index) {
                  final color = avatarProvider.predefinedColors[index];
                  final isSelected = _selectedColor == color;

                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedColor = color;
                        });
                      },
                      borderRadius: BorderRadius.circular(25),
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: _getColorFromString(color),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color:
                                isSelected ? Colors.white : Colors.transparent,
                            width: 2,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: _getColorFromString(color)
                                        .withOpacity(0.5),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  )
                                ]
                              : null,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Preview section
            const SizedBox(height: 40),
            const Text(
              'Preview',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 15),
            Center(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _getColorFromString(_selectedColor),
                  boxShadow: [
                    BoxShadow(
                      color:
                          _getColorFromString(_selectedColor).withOpacity(0.3),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  _selectedIcon,
                  size: 60,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 15),
            Center(
              child: Text(
                _nameController.text.isEmpty
                    ? 'Your Avatar'
                    : _nameController.text,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ),

            // Delete button
            const SizedBox(height: 40),
            Center(
              child: OutlinedButton.icon(
                onPressed: () {
                  _showDeleteConfirmation(context);
                },
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                label: const Text(
                  'Delete Avatar',
                  style: TextStyle(color: Colors.red),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Show confirmation dialog before deleting
  Future<void> _showDeleteConfirmation(BuildContext context) async {
    final avatarProvider = Provider.of<AvatarProvider>(context, listen: false);

    final shouldDelete = await showModalBottomSheet<bool>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Delete Avatar?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Are you sure you want to delete "${widget.avatar.name}"? This action cannot be undone.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: const Text('Delete'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (shouldDelete == true) {
      // Delete the avatar
      avatarProvider.removeAvatar(widget.avatar.id);

      if (context.mounted) {
        // Return to previous screen
        Navigator.of(context).pop(true);

        // Show confirmation
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Avatar "${widget.avatar.name}" has been deleted.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
