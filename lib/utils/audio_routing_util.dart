import 'dart:io';

import 'package:flutter/foundation.dart';

/// Utility class for checking audio routing setup
class AudioRoutingUtil {
  /// Check if virtual audio cable is installed
  static Future<bool> isVirtualAudioCableInstalled() async {
    try {
      if (!kIsWeb && Platform.isWindows) {
        // Check for audio devices that match virtual audio cable names
        // Use simple commands with explicit quotes to avoid Dart string interpolation
        final result = await Process.run('powershell', [
          '-command',
          'Get-WmiObject Win32_SoundDevice | Select-Object -ExpandProperty Name'
        ]);
        
        final output = result.stdout.toString().toLowerCase();
        return output.contains('cable') || 
               output.contains('virtual') || 
               output.contains('voicemeeter') ||
               output.contains('vac');
      }
      
      // On other platforms, we can't reliably detect audio routing
      return true;
    } catch (e) {
      debugPrint('Error checking virtual audio cable: $e');
      return false;
    }
  }
  
  /// Check if call center software is running
  static Future<bool> isCallCenterSoftwareRunning() async {
    try {
      if (!kIsWeb && Platform.isWindows) {
        // Check for common call center software processes
        final result = await Process.run('tasklist', []);
        final output = result.stdout.toString().toLowerCase();
        
        // Check for known call center software
        return output.contains('vici') || 
               output.contains('zoiper') ||
               output.contains('3cxphone') ||
               output.contains('softphone') ||
               output.contains('microsip');
      }
      
      // On other platforms, we can't reliably detect call center software
      return true;
    } catch (e) {
      debugPrint('Error checking call center software: $e');
      return false;
    }
  }
  
  /// Get information about the current default playback device
  static Future<String?> getCurrentAudioDevice() async {
    try {
      if (!kIsWeb && Platform.isWindows) {
        // Use a simpler command to avoid Dart string interpolation issues
        final result = await Process.run('powershell', [
          '-command',
          'Get-WmiObject Win32_SoundDevice | Select-Object -First 1 -ExpandProperty Name'
        ]);
        
        final output = result.stdout.toString().trim();
        if (output.isNotEmpty) {
          return output;
        }
        
        return "Unknown audio device";
      }
      
      return null;
    } catch (e) {
      debugPrint('Error getting current audio device: $e');
      return null;
    }
  }
}
