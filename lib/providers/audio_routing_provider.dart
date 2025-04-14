import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:io'; // Needed for Platform checks (like Platform.isWindows)
import 'dart:async'; // Needed for Timer
import '../utils/audio_routing_util.dart'; // Helper functions for audio checks

/// Manages the state related to audio output routing.
///
/// This is particularly important for scenarios where audio needs to be sent
/// to specific software (like call center apps) via a virtual audio cable.
/// It helps detect if the setup seems correct (on Windows) and allows the user
/// to run tests.
///
/// It uses `ChangeNotifier` to notify widgets when the routing status or test progress changes.
class AudioRoutingProvider extends ChangeNotifier {
  // --- State Variables ---

  // Tracks if the audio routing seems *correctly* configured for the intended use case.
  // (e.g., virtual cable installed and selected, potentially call software running).
  bool _isAudioRoutingDetected = false;

  // Is the audio routing test currently running? Used to show loading indicators.
  bool _isTestInProgress = false;

  // Should we show hints/warnings related to audio routing in the UI?
  // This is controlled by a setting and defaults to false.
  bool _showRoutingHints = false;

  // What was the name of the audio output device detected during the last test?
  String? _lastDetectedOutputDevice;

  // A dedicated AudioPlayer instance just for playing the silent test sound.
  final AudioPlayer _testPlayer = AudioPlayer();

  // Timer used for any periodic checks (currently not used for automatic checks).
  Timer? _detectionTimer;

  // Have we performed the audio routing check at least once since the app started?
  bool _hasCheckedRouting = false;

  // --- Public Getters ---

  /// Indicates if the audio routing is believed to be correctly set up (based on the last test).
  bool get isAudioRoutingDetected => _isAudioRoutingDetected;

  /// True if the `testAudioRouting` function is currently executing.
  bool get isTestInProgress => _isTestInProgress;

  /// Should the UI display helpful hints or warnings about audio routing?
  bool get showRoutingHints => _showRoutingHints;

  /// Has the `testAudioRouting` function been run at least once?
  bool get hasCheckedRouting => _hasCheckedRouting;

  /// The name of the audio output device found during the last check (e.g., "Speakers", "CABLE Input").
  String? get lastDetectedOutputDevice => _lastDetectedOutputDevice;

  // --- Constructor ---

  AudioRoutingProvider() {
    // Note: We used to run an initial check here automatically.
    // Now, the check is triggered manually by the user (e.g., from a settings screen)
    // to avoid unnecessary checks on startup and give the user more control.
    debugPrint('AudioRoutingProvider initialized. Manual test required.');
  }

  // --- Public Methods ---

  /// Allows enabling or disabling the display of audio routing hints in the UI.
  /// This is typically connected to a toggle switch in the settings.
  void toggleRoutingHints(bool value) {
    if (_showRoutingHints == value) return; // No change needed
    _showRoutingHints = value;
    debugPrint('Routing hints toggled: $_showRoutingHints');
    notifyListeners(); // Tell the UI to update
  }

  /// Performs the audio routing check.
  ///
  /// This involves:
  /// 1. Checking for virtual audio cable software (Windows only).
  /// 2. Checking for running call center software (Windows only).
  /// 3. Getting the current default audio output device (Windows only).
  /// 4. Playing a short, quiet sound to ensure the audio engine is active.
  ///
  /// Returns `true` if the routing *seems* correct, `false` otherwise.
  Future<bool> testAudioRouting() async {
    // If a test is already running, just return the current status.
    if (_isTestInProgress) return _isAudioRoutingDetected;

    // Mark the test as started and notify listeners (e.g., show loading spinner).
    _isTestInProgress = true;
    _hasCheckedRouting =
        true; // Mark that we've now run the check at least once.
    _lastDetectedOutputDevice = null; // Reset last detected device
    notifyListeners();

    bool detectedResult = false;

    try {
      debugPrint('Starting audio routing test...');
      // --- Platform-Specific Checks (Currently Windows Only) ---
      if (!kIsWeb && Platform.isWindows) {
        // Perform the checks using our utility functions.
        detectedResult = await _checkAudioDevices();
        debugPrint('Windows audio device check result: $detectedResult');
      } else {
        // On non-Windows platforms (or web), we assume routing is okay
        // as we don't have a reliable way to check virtual cables etc.
        debugPrint('Skipping detailed audio check on non-Windows platform.');
        detectedResult = true;
        _lastDetectedOutputDevice = "N/A (Non-Windows)";
      }

      // --- Play Test Sound (Regardless of Platform) ---
      // This helps confirm the audio player itself is working and might trigger
      // system prompts if audio access is blocked.
      debugPrint('Playing silent test sound...');
      await _playTestSound();
      debugPrint('Test sound played.');

      // Update the final detection status.
      _isAudioRoutingDetected = detectedResult;
      debugPrint(
        'Audio routing test completed. Detected: $_isAudioRoutingDetected',
      );
    } catch (e) {
      // Log any errors that occurred during the test.
      debugPrint('Error during audio routing test: $e 🤯');
      _isAudioRoutingDetected = false; // Assume failure if an error occurs.
      _lastDetectedOutputDevice = "Error during test";
    } finally {
      // Ensure the test progress flag is reset and notify listeners.
      _isTestInProgress = false;
      notifyListeners();
    }

    // Return the final result of the test.
    return _isAudioRoutingDetected;
  }

  // --- Private Helper Methods ---

  /// Plays a short, quiet audio file.
  /// This is mainly to ensure the AudioPlayer is functioning correctly.
  Future<void> _playTestSound() async {
    try {
      // We use a very short, silent (or near-silent) MP3 file.
      // Set low volume just in case.
      await _testPlayer.setVolume(0.1);
      // Play the sound from the app's assets.
      await _testPlayer.play(AssetSource('audio/routing_test.mp3'));

      // Give it a moment to play.
      // TODO: Ideally, use player state events instead of a fixed delay.
      await Future.delayed(const Duration(milliseconds: 500));
      // Stop playback explicitly.
      await _testPlayer.stop();
    } catch (e) {
      // Log if the test sound couldn't play.
      debugPrint('Error playing test sound: $e 🔇');
      // Don't re-throw, as the main test can continue.
    }
  }

  /// Performs the core logic for checking audio devices on Windows.
  /// Uses helper functions from `AudioRoutingUtil`.
  Future<bool> _checkAudioDevices() async {
    // This check is only designed for Windows.
    if (!Platform.isWindows) return true;

    try {
      // 1. Check if known virtual audio cable software seems to be installed.
      final bool hasVirtualAudio =
          await AudioRoutingUtil.isVirtualAudioCableInstalled();
      debugPrint('Virtual audio cable installed check: $hasVirtualAudio');

      // 2. Check if known call center software processes appear to be running.
      final bool isCallSoftwareRunning =
          await AudioRoutingUtil.isCallCenterSoftwareRunning();
      debugPrint('Call center software running check: $isCallSoftwareRunning');

      // 3. Get the name of the *current* default audio output device.
      _lastDetectedOutputDevice =
          await AudioRoutingUtil.getCurrentAudioDevice();
      debugPrint('Current audio output device: $_lastDetectedOutputDevice');

      // 4. Check if the current output device name *looks like* a virtual cable.
      final bool usingVirtualCable =
          _lastDetectedOutputDevice != null &&
          _lastDetectedOutputDevice!.toLowerCase().contains(
            RegExp(r'cable|virtual|voicemeeter|vac|vb-audio'), // Added vb-audio
          );
      debugPrint('Currently using virtual cable check: $usingVirtualCable');

      // --- Determine the Result ---
      // The logic here might need adjustment based on exact requirements.
      // Current logic: Routing is considered potentially OK if:
      // a) Virtual audio software IS installed AND
      // b) EITHER call software IS running OR the current output IS NOT a virtual cable
      //    (This OR condition is a bit lenient, maybe we always require usingVirtualCable? TBD)
      // bool routingSeemsCorrect = hasVirtualAudio && (isCallSoftwareRunning || !usingVirtualCable);

      // --- Revised Logic (Stricter) ---
      // Routing is OK if:
      // 1. Virtual audio IS installed AND
      // 2. The current output device IS a virtual cable.
      // (We removed the check for call software running, as it's less reliable
      // and the essential part is routing to the virtual cable itself).
      bool routingSeemsCorrect = hasVirtualAudio && usingVirtualCable;
      debugPrint('Final routing check determination: $routingSeemsCorrect');

      return routingSeemsCorrect;
    } catch (e) {
      // Log errors during the check.
      debugPrint('Error checking Windows audio devices: $e');
      _lastDetectedOutputDevice = "Error during check";
      return false; // Assume failure on error.
    }
  }

  // --- Cleanup ---

  /// Dispose of resources when the provider is no longer needed.
  @override
  void dispose() {
    debugPrint('Disposing AudioRoutingProvider...');
    _detectionTimer?.cancel(); // Cancel any active timer.
    _testPlayer.dispose(); // Release the audio player resources.
    super.dispose(); // Call the parent class's dispose method.
  }
}
