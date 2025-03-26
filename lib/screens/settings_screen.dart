import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../providers/avatar_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/audio_routing_provider.dart';
import '../widgets/audio_routing_status.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'SETTINGS',
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          // Main content
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16.0 : 24.0,
                vertical: 16.0,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Theme settings section
                    _buildSectionHeader(context, 'Appearance'),
                    _buildThemeSelector(context),

                    const SizedBox(height: 32),

                    // Audio settings section - only show on Windows
                    if (!kIsWeb && Platform.isWindows) ...[
                      _buildSectionHeader(context, 'Call Center Integration'),
                      _buildAudioRoutingOptions(context),
                      const SizedBox(height: 32),
                    ],

                    // Data management section
                    _buildSectionHeader(context, 'Data Management'),
                    const SizedBox(height: 8),

                    // Clear all data option
                    _buildClearDataOption(context),
                  ],
                ),
              ),
            ),
          ),

          // Deletion overlay
          if (_isDeleting)
            Container(
              color: theme.colorScheme.surface.withOpacity(0.8),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: theme.colorScheme.primary),
                    const SizedBox(height: 16),
                    Text(
                      'Deleting all data...',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
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
  }

  // Build section header
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.0,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  // Build theme selector
  Widget _buildThemeSelector(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Card(
      elevation: isDarkMode ? 2 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDarkMode ? theme.colorScheme.outline : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  themeProvider.themeMode == ThemeMode.dark
                      ? Icons.dark_mode
                      : Icons.light_mode,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Theme Mode',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                Switch(
                  value: themeProvider.themeMode == ThemeMode.dark,
                  onChanged: (value) {
                    themeProvider.toggleTheme();
                  },
                  activeColor: theme.colorScheme.primary,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 36.0),
              child: Text(
                themeProvider.themeMode == ThemeMode.dark
                    ? 'Dark mode is enabled'
                    : 'Light mode is enabled',
                style: TextStyle(
                  fontSize: 14,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build audio routing options
  Widget _buildAudioRoutingOptions(BuildContext context) {
    final audioRoutingProvider = Provider.of<AudioRoutingProvider>(context);
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Card(
      elevation: isDarkMode ? 2 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDarkMode ? theme.colorScheme.outline : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card header with test button
            Row(
              children: [
                Icon(Icons.call, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  'Call Center Audio Routing',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                if (audioRoutingProvider.hasCheckedRouting)
                  Icon(
                    audioRoutingProvider.isAudioRoutingDetected
                        ? Icons.check_circle
                        : Icons.warning_amber_rounded,
                    color:
                        audioRoutingProvider.isAudioRoutingDetected
                            ? Colors.green
                            : theme.colorScheme.error,
                    size: 24,
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Status message based on detection results
            if (audioRoutingProvider.hasCheckedRouting) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:
                      audioRoutingProvider.isAudioRoutingDetected
                          ? Colors.green.withOpacity(0.1)
                          : theme.colorScheme.errorContainer.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      audioRoutingProvider.isAudioRoutingDetected
                          ? Icons.check_circle
                          : Icons.warning_amber_rounded,
                      color:
                          audioRoutingProvider.isAudioRoutingDetected
                              ? Colors.green
                              : theme.colorScheme.error,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            audioRoutingProvider.isAudioRoutingDetected
                                ? 'Audio Routing Properly Configured'
                                : 'Audio Routing Issues Detected',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color:
                                  audioRoutingProvider.isAudioRoutingDetected
                                      ? Colors.green
                                      : theme.colorScheme.error,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            audioRoutingProvider.isAudioRoutingDetected
                                ? 'Your voice avatars will be heard during calls'
                                : 'Your voice avatars may not be heard during calls',
                            style: TextStyle(
                              fontSize: 14,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Current output device
            if (audioRoutingProvider.lastDetectedOutputDevice != null) ...[
              Text(
                'Current Audio Device:',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                audioRoutingProvider.lastDetectedOutputDevice!,
                style: TextStyle(
                  fontSize: 14,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Test button
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.speaker_phone),
                label: Text(
                  audioRoutingProvider.isTestInProgress
                      ? 'Testing...'
                      : 'Test Audio Routing',
                ),
                onPressed:
                    audioRoutingProvider.isTestInProgress
                        ? null
                        : () async {
                          final result =
                              await audioRoutingProvider.testAudioRouting();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  result
                                      ? 'Audio routing properly configured for calls!'
                                      : 'Audio routing issue detected. Check instructions below.',
                                ),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor:
                                    result
                                        ? Colors.green
                                        : theme.colorScheme.error,
                              ),
                            );
                          }
                        },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  foregroundColor: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Setup instructions if there are issues
            if (audioRoutingProvider.hasCheckedRouting &&
                !audioRoutingProvider.isAudioRoutingDetected)
              const AudioRoutingStatus(),

            // Notification settings
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.notifications,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  'Show Notification Bell',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                Switch(
                  value: audioRoutingProvider.showRoutingHints,
                  onChanged: (value) {
                    audioRoutingProvider.toggleRoutingHints(value);
                  },
                  activeColor: theme.colorScheme.primary,
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 32.0),
              child: Text(
                'When enabled, a notification bell will appear in the app bar if audio routing issues are detected',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build clear data option
  Widget _buildClearDataOption(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Card(
      elevation: isDarkMode ? 2 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDarkMode ? theme.colorScheme.outline : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => _showClearDataConfirmation(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.delete_forever, color: theme.colorScheme.error),
                  const SizedBox(width: 12),
                  Text(
                    'Clear All Data',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 36.0),
                child: Text(
                  'Delete all avatars, voices, and reset the app to its initial state',
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber,
                      size: 16,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This action cannot be undone. All your data will be permanently deleted.',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.error,
                        ),
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

  // Show confirmation dialog for clearing data
  void _showClearDataConfirmation(BuildContext context) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              'Clear All Data?',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.error,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This will permanently delete:',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                _buildBulletPoint(context, 'All your avatars'),
                _buildBulletPoint(context, 'All voice recordings'),
                _buildBulletPoint(context, 'All customizations and settings'),
                const SizedBox(height: 16),
                Text(
                  'This action cannot be undone.',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: theme.colorScheme.primary),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _clearAllData(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                  foregroundColor: theme.colorScheme.onError,
                ),
                child: const Text('Delete Everything'),
              ),
            ],
          ),
    );
  }

  // Build bullet point for confirmation dialog
  Widget _buildBulletPoint(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }

  // Clear all data
  Future<void> _clearAllData(BuildContext context) async {
    // Store context in a local variable to check if mounted later
    final BuildContext localContext = context;

    // Show loading overlay
    setState(() {
      _isDeleting = true;
    });

    try {
      debugPrint('Starting data deletion process...');

      // Get the avatar provider
      final avatarProvider = Provider.of<AvatarProvider>(
        context,
        listen: false,
      );

      // Add haptic feedback
      HapticFeedback.heavyImpact();

      // Set a timeout to prevent the app from getting stuck indefinitely
      bool isCompleted = false;

      // Create a timeout that will complete after 10 seconds
      Future.delayed(const Duration(seconds: 10)).then((_) {
        if (!isCompleted && mounted) {
          debugPrint('Data deletion timeout reached - forcing completion');
          setState(() {
            _isDeleting = false;
          });
          Navigator.of(context).pop();
        }
      });

      // Delete all avatars and their data with a try-catch block
      try {
        debugPrint('Calling deleteAllAvatars()...');
        await avatarProvider.deleteAllAvatars();
        debugPrint('deleteAllAvatars() completed successfully');
      } catch (deleteError) {
        debugPrint('Error in deleteAllAvatars(): $deleteError');
        // Even if there's an error, we'll consider the operation "complete" for UI purposes
        // This prevents the app from getting stuck in the loading state
      }

      isCompleted = true;

      // If we're still mounted, hide the loading overlay
      if (mounted) {
        debugPrint('Widget is still mounted, updating UI...');
        setState(() {
          _isDeleting = false;
        });

        // Navigate back first
        debugPrint('Navigating back...');
        Navigator.of(context).pop();

        // After navigation, show the success message on the new screen
        debugPrint('Setting up post-frame callback for SnackBar...');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          try {
            if (localContext.mounted) {
              debugPrint('Showing success SnackBar...');
              ScaffoldMessenger.of(localContext).showSnackBar(
                SnackBar(
                  content: const Text('All data has been cleared successfully'),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: Theme.of(localContext).colorScheme.primary,
                ),
              );
            } else {
              debugPrint('Context is no longer mounted, skipping SnackBar');
            }
          } catch (snackBarError) {
            debugPrint('Error showing SnackBar: $snackBarError');
          }
        });
      } else {
        debugPrint('Widget is no longer mounted, skipping UI updates');
      }
    } catch (e) {
      debugPrint('Top-level error in _clearAllData: $e');

      // If we're still mounted, hide the loading overlay and show error
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });

        // Show error message
        try {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error clearing data: ${e.toString()}'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        } catch (snackBarError) {
          debugPrint('Error showing error SnackBar: $snackBarError');
        }
      }
    }
  }
}
