import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:io';
import 'dart:async';
import '../utils/audio_routing_util.dart';

/// Provider that handles audio routing detection and settings
class AudioRoutingProvider extends ChangeNotifier {
  bool _isAudioRoutingDetected = false;
  bool _isTestInProgress = false;
  bool _showRoutingHints =
      false; // Default to false - don't show hints automatically
  String? _lastDetectedOutputDevice;
  final AudioPlayer _testPlayer = AudioPlayer();
  Timer? _detectionTimer;
  bool _hasCheckedRouting = false;

  /// Whether audio is being properly routed for call center software
  bool get isAudioRoutingDetected => _isAudioRoutingDetected;

  /// Whether an audio routing test is currently in progress
  bool get isTestInProgress => _isTestInProgress;

  /// Whether to show audio routing hints and warnings
  bool get showRoutingHints => _showRoutingHints;

  /// Whether the routing has been checked at least once
  bool get hasCheckedRouting => _hasCheckedRouting;

  /// The last detected audio output device
  String? get lastDetectedOutputDevice => _lastDetectedOutputDevice;

  AudioRoutingProvider() {
    // We don't run the check automatically on startup anymore
    // The user will need to run the test manually from settings
  }

  /// Toggle whether to show audio routing hints
  void toggleRoutingHints(bool value) {
    _showRoutingHints = value;
    notifyListeners();
  }

  /// Run a test to detect if audio routing is properly set up
  Future<bool> testAudioRouting() async {
    if (_isTestInProgress) return _isAudioRoutingDetected;

    _isTestInProgress = true;
    notifyListeners();

    bool result = false;

    try {
      // Check audio routing on Windows
      if (!kIsWeb && Platform.isWindows) {
        result = await _checkAudioDevices();
      } else {
        // For other platforms, we can't reliably detect routing
        result = true;
      }

      // Play a test sound to verify routing
      await _playTestSound();

      _isAudioRoutingDetected = result;
      _hasCheckedRouting = true;
    } catch (e) {
      debugPrint('Error testing audio routing: $e');
      _isAudioRoutingDetected = false;
    } finally {
      _isTestInProgress = false;
      notifyListeners();
    }

    return _isAudioRoutingDetected;
  }

  Future<void> _playTestSound() async {
    try {
      // Use a silent test sound that won't disturb users
      await _testPlayer.setVolume(0.1);
      await _testPlayer.play(AssetSource('audio/routing_test.mp3'));

      // Wait for playback to finish
      await Future.delayed(const Duration(seconds: 1));
      await _testPlayer.stop();
    } catch (e) {
      debugPrint('Error playing test sound: $e');
    }
  }

  Future<bool> _checkAudioDevices() async {
    if (!Platform.isWindows) return true; // Only relevant for Windows

    try {
      // Check if virtual audio cable is installed
      final bool hasVirtualAudio =
          await AudioRoutingUtil.isVirtualAudioCableInstalled();

      // Check if call center software is running
      final bool isCallSoftwareRunning =
          await AudioRoutingUtil.isCallCenterSoftwareRunning();

      // Get current audio device
      _lastDetectedOutputDevice =
          await AudioRoutingUtil.getCurrentAudioDevice();

      // Check if current audio device is a virtual cable
      final bool usingVirtualCable =
          _lastDetectedOutputDevice != null &&
          _lastDetectedOutputDevice!.toLowerCase().contains(
            RegExp('cable|virtual|voicemeeter|vac'),
          );

      // Audio is properly routed if:
      // 1. Virtual audio software is installed
      // 2. Call software is running
      // 3. Current audio device is a virtual cable (optional check)
      return hasVirtualAudio && (isCallSoftwareRunning || !usingVirtualCable);
    } catch (e) {
      debugPrint('Error checking audio devices: $e');
      return false;
    }
  }

  @override
  void dispose() {
    _detectionTimer?.cancel();
    _testPlayer.dispose();
    super.dispose();
  }
}
