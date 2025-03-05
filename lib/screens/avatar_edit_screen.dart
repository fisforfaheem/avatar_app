import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.avatar.name);
    _selectedIcon = widget.avatar.icon;
    _selectedColor = widget.avatar.color;
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Avatar'),
        actions: [
          TextButton(
            onPressed: () {
              // Update the avatar
              avatarProvider.updateAvatar(
                widget.avatar.id,
                name: _nameController.text.trim(),
                icon: _selectedIcon,
                color: _selectedColor,
              );
              Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name field
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Avatar Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            // Icon selection
            const Text(
              'Choose an Icon',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              // Use ConstrainedBox instead of setting a fixed height
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200),
                child: GridView.builder(
                  shrinkWrap:
                      true, // Important to avoid intrinsic dimension issues
                  physics: const ClampingScrollPhysics(), // Prevents bouncing
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1.0, // Square cells
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
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 48, // Fixed width
                        height: 48, // Fixed height
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Theme.of(context).primaryColor.withOpacity(0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? Theme.of(context).primaryColor
                                : Colors.transparent,
                          ),
                        ),
                        child: Icon(
                          icon,
                          color: isSelected
                              ? Theme.of(context).primaryColor
                              : Colors.grey.shade700,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Color selection
            const Text(
              'Choose a Color',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              // Use a fixed height container
              height: 70,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(8),
                itemCount: avatarProvider.predefinedColors.length,
                itemBuilder: (context, index) {
                  final color = avatarProvider.predefinedColors[index];
                  final isSelected = _selectedColor == color;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedColor = color;
                        });
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 40,
                        height: 40,
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
            const SizedBox(height: 24),

            // Preview section
            const Text(
              'Preview',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: _getColorFromString(_selectedColor),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _selectedIcon,
                  size: 50,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Delete button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Avatar?'),
                      content: const Text(
                          'This will permanently delete this avatar and all associated voice samples. This action cannot be undone.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () {
                            avatarProvider.removeAvatar(widget.avatar.id);
                            Navigator.of(context).pop(); // Close dialog
                            Navigator.of(context)
                                .pop(); // Return to previous screen
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
                ),
                label: const Text('Delete Avatar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
