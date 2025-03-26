import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_routing_provider.dart';
import 'dart:io';

class AudioRoutingStatus extends StatelessWidget {
  const AudioRoutingStatus({super.key});

  @override
  Widget build(BuildContext context) {
    // Only show on Windows platforms
    if (!Platform.isWindows) return const SizedBox.shrink();

    final routingProvider = Provider.of<AudioRoutingProvider>(context);

    // Don't show if the user has disabled hints
    if (!routingProvider.showRoutingHints) return const SizedBox.shrink();

    final bool isProperlyRouted = routingProvider.isAudioRoutingDetected;
    final theme = Theme.of(context);

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color:
              isProperlyRouted
                  ? theme.colorScheme.primaryContainer.withOpacity(0.7)
                  : theme.colorScheme.errorContainer.withOpacity(0.7),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              isProperlyRouted
                  ? Icons.check_circle
                  : Icons.warning_amber_rounded,
              color:
                  isProperlyRouted
                      ? theme.colorScheme.primary
                      : theme.colorScheme.error,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isProperlyRouted
                        ? 'Audio Properly Routed'
                        : 'Audio Routing Issue Detected',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color:
                          isProperlyRouted
                              ? theme.colorScheme.primary
                              : theme.colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isProperlyRouted
                        ? 'Your audio will be heard in calls'
                        : 'Audio from this app may not be heard during calls. Click for setup help.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                isProperlyRouted ? Icons.close : Icons.help_outline,
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                size: 20,
              ),
              onPressed: () {
                if (isProperlyRouted) {
                  // If properly routed, hide the notification
                  routingProvider.toggleRoutingHints(false);
                } else {
                  // If not properly routed, show setup help
                  _showSetupHelp(context);
                }
              },
              tooltip: isProperlyRouted ? 'Dismiss' : 'Setup Help',
            ),
            if (!isProperlyRouted)
              TextButton(
                child: const Text('Test'),
                onPressed: () => routingProvider.testAudioRouting(),
              ),
          ],
        ),
      ),
    );
  }

  void _showSetupHelp(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Audio Routing Setup'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'To make your voice avatars work with call center software:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildStep(
                    '1',
                    'Download and install VB-Audio Virtual Cable:',
                    'https://vb-audio.com/Cable/',
                  ),
                  _buildStep(
                    '2',
                    'Set VB-CABLE Input as Default Playback Device:',
                    'Right-click sound icon → Sound Settings → Choose VB-CABLE Input as Output',
                  ),
                  _buildStep(
                    '3',
                    'Enable Listen feature for VB-CABLE Output:',
                    'Control Panel → Sound → Recording tab → VB-CABLE Output → Properties → Listen tab → Check "Listen to this device" → Choose your speakers',
                  ),
                  _buildStep(
                    '4',
                    'Configure Vici Dialer:',
                    'Set audio input to "VB-CABLE Output" in your call software settings',
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'This creates a virtual audio connection that allows your voice avatar sounds to be heard on calls.',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
              ElevatedButton(
                onPressed: () {
                  // Run the audio routing test again
                  Provider.of<AudioRoutingProvider>(
                    context,
                    listen: false,
                  ).testAudioRouting();
                  Navigator.of(context).pop();
                },
                child: const Text('Test Audio Routing'),
              ),
            ],
          ),
    );
  }

  Widget _buildStep(String number, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(description, style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
