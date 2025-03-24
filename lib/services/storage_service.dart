import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/avatar.dart';

/// A service that handles storing and retrieving avatar data from local storage
class StorageService {
  // Keys for SharedPreferences
  static const String _avatarsKey = 'avatars';
  static const String _lastSyncKey = 'last_sync';

  /// Save avatars to local storage
  ///
  /// This method serializes the list of avatars to JSON and stores it in SharedPreferences
  Future<bool> saveAvatars(List<Avatar> avatars) async {
    try {
      // Get SharedPreferences instance
      final prefs = await SharedPreferences.getInstance();

      // If the list is empty, save an empty JSON array
      if (avatars.isEmpty) {
        final success = await prefs.setString(_avatarsKey, '[]');
        if (success) {
          await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
        }
        return success;
      }

      // Convert avatars to a list of JSON maps
      final List<Map<String, dynamic>> avatarsJson = [];

      // Process each avatar individually to prevent one bad avatar from failing the entire save
      for (final avatar in avatars) {
        try {
          // Convert each avatar to a JSON map
          final avatarJson = _avatarToJson(avatar);
          avatarsJson.add(avatarJson);
        } catch (e) {
          // Log the error but continue with other avatars
          debugPrint('Error converting avatar ${avatar.id} to JSON: $e');
        }
      }

      // Encode the JSON list to a string
      String jsonString;
      try {
        jsonString = jsonEncode(avatarsJson);
      } catch (e) {
        debugPrint('Error encoding avatars to JSON: $e');
        return false;
      }

      // Store the JSON string in SharedPreferences
      final success = await prefs.setString(_avatarsKey, jsonString);

      // Update last sync time
      if (success) {
        await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
      }

      return success;
    } catch (e) {
      debugPrint('Error saving avatars: $e');
      return false;
    }
  }

  /// Load avatars from local storage
  ///
  /// This method retrieves the JSON string from SharedPreferences and deserializes it to a list of avatars
  Future<List<Avatar>> loadAvatars() async {
    try {
      // Get SharedPreferences instance
      final prefs = await SharedPreferences.getInstance();

      // Get the JSON string from SharedPreferences
      final String? avatarsJson = prefs.getString(_avatarsKey);

      // If no data is found, return an empty list
      if (avatarsJson == null || avatarsJson.isEmpty) {
        return [];
      }

      // Decode the JSON string to a list of maps
      // Add extra validation to handle empty JSON
      try {
        final List<dynamic> decodedJson = jsonDecode(avatarsJson);

        // If the decoded JSON is empty, return an empty list
        if (decodedJson.isEmpty) {
          return [];
        }

        // Convert each map to an Avatar object
        return decodedJson
            .map<Avatar>((json) => _avatarFromJson(json))
            .toList();
      } catch (jsonError) {
        debugPrint('Error decoding JSON: $jsonError');
        // If there's an error decoding the JSON, clear the corrupted data
        await prefs.remove(_avatarsKey);
        return [];
      }
    } catch (e) {
      debugPrint('Error loading avatars: $e');
      return [];
    }
  }

  /// Get the last sync time
  Future<DateTime?> getLastSyncTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? lastSyncString = prefs.getString(_lastSyncKey);

      if (lastSyncString == null || lastSyncString.isEmpty) {
        return null;
      }

      return DateTime.parse(lastSyncString);
    } catch (e) {
      debugPrint('Error getting last sync time: $e');
      return null;
    }
  }

  /// Clear all data from storage
  ///
  /// This method removes all avatar data from SharedPreferences and deletes all audio files
  Future<void> clearAllData() async {
    debugPrint('[StorageService] Starting clearAllData...');

    // Track what operations succeeded
    bool prefsCleared = false;
    bool filesDeleted = false;

    try {
      // Clear SharedPreferences data
      debugPrint('[StorageService] Clearing SharedPreferences data...');
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_avatarsKey);
        await prefs.remove(_lastSyncKey);

        // Clear any other app-specific preferences
        // Add any additional keys that need to be cleared here

        prefsCleared = true;
        debugPrint(
          '[StorageService] Successfully cleared SharedPreferences data',
        );
      } catch (prefsError) {
        debugPrint(
          '[StorageService] Error clearing SharedPreferences: $prefsError',
        );
        // Continue to file deletion even if prefs clearing fails
      }

      // Clear audio files directory
      if (!kIsWeb) {
        debugPrint('[StorageService] Clearing audio files directory...');
        try {
          final appDocDir = await getApplicationDocumentsDirectory();
          final audioDir = Directory('${appDocDir.path}/audio_files');

          if (await audioDir.exists()) {
            // Delete all files in the directory
            debugPrint(
              '[StorageService] Audio directory exists, listing files...',
            );
            final files = await audioDir.list().toList();
            debugPrint(
              '[StorageService] Found ${files.length} files to delete',
            );

            int deletedCount = 0;
            int errorCount = 0;

            for (final file in files) {
              if (file is File) {
                try {
                  await file.delete();
                  deletedCount++;
                  // Add a small delay between deletions
                  await Future.delayed(const Duration(milliseconds: 10));
                } catch (e) {
                  errorCount++;
                  debugPrint(
                    '[StorageService] Error deleting file ${file.path}: $e',
                  );
                  // Continue with other files even if this one fails
                }
              }
            }

            debugPrint(
              '[StorageService] Deleted $deletedCount files with $errorCount errors',
            );
            filesDeleted = true;
          } else {
            debugPrint(
              '[StorageService] Audio directory does not exist, nothing to delete',
            );
            filesDeleted =
                true; // Consider it successful if directory doesn't exist
          }
        } catch (e) {
          debugPrint(
            '[StorageService] Error clearing audio files directory: $e',
          );
          // Continue even if clearing the directory fails
        }
      } else {
        debugPrint(
          '[StorageService] Running on web platform, skipping file deletion',
        );
        filesDeleted = true; // Consider it successful on web
      }

      debugPrint(
        '[StorageService] clearAllData completed - Prefs cleared: $prefsCleared, Files deleted: $filesDeleted',
      );
    } catch (e) {
      debugPrint('[StorageService] Error in clearAllData: $e');
      rethrow; // Rethrow to allow caller to handle the error
    }
  }

  /// Save audio file to local storage
  ///
  /// This method saves an audio file to the application documents directory
  Future<String> saveAudioFile(String fileName, List<int> bytes) async {
    try {
      // Get the application documents directory
      final directory = await getApplicationDocumentsDirectory();

      // Create a subdirectory for audio files if it doesn't exist
      final audioDir = Directory('${directory.path}/audio_files');
      if (!await audioDir.exists()) {
        await audioDir.create(recursive: true);
      }

      // Create the file path
      final filePath = '${audioDir.path}/$fileName';

      // Write the bytes to the file
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      return filePath;
    } catch (e) {
      debugPrint('Error saving audio file: $e');
      rethrow;
    }
  }

  /// Delete audio file from local storage
  Future<bool> deleteAudioFile(String filePath) async {
    try {
      // Check if the file path is valid
      if (filePath.isEmpty) {
        debugPrint('Cannot delete file: Empty file path');
        return false;
      }

      final file = File(filePath);
      if (await file.exists()) {
        try {
          await file.delete();
          return true;
        } catch (deleteError) {
          // Handle specific file deletion errors
          debugPrint('Error deleting file $filePath: $deleteError');

          // Try to delete the file again after a short delay
          await Future.delayed(const Duration(milliseconds: 100));
          try {
            if (await file.exists()) {
              await file.delete();
              return true;
            }
          } catch (retryError) {
            debugPrint('Retry failed to delete file $filePath: $retryError');
          }
        }
      } else {
        // File doesn't exist, so consider it "deleted"
        debugPrint('File does not exist: $filePath');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting audio file: $e');
      return false;
    }
  }

  // Helper method to convert an Avatar to a JSON map
  Map<String, dynamic> _avatarToJson(Avatar avatar) {
    return {
      'id': avatar.id,
      'name': avatar.name,
      'color': avatar.color,
      'icon': _iconDataToString(avatar.icon),
      'voices': avatar.voices.map((voice) => _voiceToJson(voice)).toList(),
      'imagePath': avatar.imagePath,
    };
  }

  // Helper method to convert a JSON map to an Avatar
  Avatar _avatarFromJson(Map<String, dynamic> json) {
    return Avatar(
      id: json['id'],
      name: json['name'],
      color: json['color'],
      icon: _stringToIconData(json['icon']),
      voices:
          (json['voices'] as List)
              .map<Voice>((voiceJson) => _voiceFromJson(voiceJson))
              .toList(),
      imagePath: json['imagePath'],
    );
  }

  // Helper method to convert a Voice to a JSON map
  Map<String, dynamic> _voiceToJson(Voice voice) {
    return {
      'id': voice.id,
      'name': voice.name,
      'audioUrl': voice.audioUrl,
      'duration': voice.duration.inMilliseconds,
      'createdAt': voice.createdAt.toIso8601String(),
      'category': voice.category,
      'playCount': voice.playCount,
      'lastPlayed': voice.lastPlayed?.toIso8601String(),
      'color': voice.color,
    };
  }

  // Helper method to convert a JSON map to a Voice
  Voice _voiceFromJson(Map<String, dynamic> json) {
    return Voice(
      id: json['id'],
      name: json['name'],
      audioUrl: json['audioUrl'],
      duration: Duration(milliseconds: json['duration']),
      createdAt: DateTime.parse(json['createdAt']),
      category: json['category'],
      playCount: json['playCount'],
      lastPlayed:
          json['lastPlayed'] != null
              ? DateTime.parse(json['lastPlayed'])
              : null,
      color: json['color'],
    );
  }

  // Helper method to convert IconData to a string
  String _iconDataToString(IconData icon) {
    return '${icon.codePoint}:${icon.fontFamily}:${icon.fontPackage}';
  }

  // Helper method to convert a string to IconData
  IconData _stringToIconData(String iconString) {
    final parts = iconString.split(':');
    return IconData(
      int.parse(parts[0]),
      fontFamily: parts[1] == 'null' ? null : parts[1],
      fontPackage: parts.length > 2 && parts[2] != 'null' ? parts[2] : null,
    );
  }
}
