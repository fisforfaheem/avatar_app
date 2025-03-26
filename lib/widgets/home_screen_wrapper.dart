import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import '../providers/audio_routing_provider.dart';
import '../screens/home_screen.dart';
import 'audio_routing_status.dart';

/// A wrapper widget for HomeScreen that adds audio routing status notification
class HomeScreenWrapper extends StatelessWidget {
  const HomeScreenWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the audio routing provider
    final routingProvider = Provider.of<AudioRoutingProvider>(context);

    // Only relevant for Windows
    final bool shouldShowAudioRouting =
        !kIsWeb && Platform.isWindows && routingProvider.showRoutingHints;

    return Scaffold(
      body: Stack(
        children: [
          // Original HomeScreen
          const HomeScreen(),

          // Audio routing status notification
          if (shouldShowAudioRouting)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Center(child: const AudioRoutingStatus()),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
