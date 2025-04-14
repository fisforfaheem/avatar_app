import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/avatar.dart';

/// Handles the nitty-gritty of saving and loading avatar data.
///
/// This service takes care of:
/// - Storing the list of `Avatar` objects (as JSON) in `SharedPreferences`.
/// - Loading the list back from `SharedPreferences`.
/// - Saving individual audio files (`.mp3`, `.wav`, etc.) to the device's file system.
/// - Deleting those audio files.
/// - Providing methods to clear all stored data (both preferences and files).
/// - Converting `Avatar` and `Voice` objects to/from JSON.
class StorageService {
  // --- Constants for SharedPreferences Keys ---
  // Using constants makes it easier to avoid typos when accessing preferences.
  static const String _avatarsKey =
      'avatars_data_v2'; // Key for the main avatar JSON string (v2 includes imagePath)
  static const String _lastSyncKey =
      'last_storage_sync'; // Key for timestamp of last save
  static const String _audioDirName =
      'audio_files'; // Name of the subdirectory for audio

  // --- Avatar List Persistence (SharedPreferences) ---

  /// Saves the provided list of `Avatar` objects to `SharedPreferences`.
  /// Converts the list to a JSON string first.
  /// Returns `true` if saving was successful, `false` otherwise.
  Future<bool> saveAvatars(List<Avatar> avatars) async {
    try {
      debugPrint(
        '[StorageService] Attempting to save ${avatars.length} avatars...',
      );
      // Get the SharedPreferences instance (like opening the app's private storage box).
      final prefs = await SharedPreferences.getInstance();

      // Handle the case where the list is empty - store an empty JSON array.
      if (avatars.isEmpty) {
        debugPrint('[StorageService] Saving empty avatar list.');
        final success = await prefs.setString(_avatarsKey, '[]');
        if (success) {
          // Update the sync time even for an empty list save.
          await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
        }
        return success;
      }

      // Convert the list of Avatar objects into a list of JSON-representable Maps.
      // We do this carefully, handling potential errors for individual avatars.
      final List<Map<String, dynamic>> avatarsJsonList = [];
      for (final avatar in avatars) {
        try {
          // Use our helper function to convert one Avatar to a Map.
          final avatarJson = _avatarToJson(avatar);
          avatarsJsonList.add(avatarJson);
        } catch (e, stackTrace) {
          // Log an error if a specific avatar fails conversion, but keep going.
          debugPrint(
            '[StorageService] Error converting avatar ${avatar.id} to JSON: $e\n$stackTrace',
          );
          // Optionally, skip adding this avatar to avoid corrupting the whole save.
        }
      }

      // If all avatars failed conversion (unlikely), don't save.
      if (avatarsJsonList.isEmpty && avatars.isNotEmpty) {
        debugPrint(
          '[StorageService] All avatars failed JSON conversion. Save aborted.',
        );
        return false;
      }

      // Encode the entire list of maps into a single JSON string.
      String jsonString;
      try {
        jsonString = jsonEncode(avatarsJsonList);
      } catch (e, stackTrace) {
        // This error means the overall structure couldn't be encoded.
        debugPrint(
          '[StorageService] Error encoding avatar list to JSON: $e\n$stackTrace',
        );
        return false; // Can't save if encoding fails.
      }

      // Finally, save the JSON string to SharedPreferences using our key.
      debugPrint(
        '[StorageService] Saving JSON string (${jsonString.length} chars) to key "$_avatarsKey"',
      );
      final success = await prefs.setString(_avatarsKey, jsonString);

      // If saving the string was successful, update the last sync timestamp.
      if (success) {
        await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
        debugPrint('[StorageService] Avatars saved successfully.');
      } else {
        debugPrint(
          '[StorageService] Failed to save avatars JSON string to SharedPreferences.',
        );
      }

      return success;
    } catch (e, stackTrace) {
      // Catch-all for unexpected errors during the save process.
      debugPrint(
        '[StorageService] Unexpected error saving avatars: $e\n$stackTrace',
      );
      return false;
    }
  }

  /// Loads the list of `Avatar` objects from `SharedPreferences`.
  /// Reads the JSON string and deserializes it back into `Avatar` objects.
  /// Returns an empty list if no data is found or if an error occurs.
  Future<List<Avatar>> loadAvatars() async {
    try {
      debugPrint(
        '[StorageService] Attempting to load avatars from key "$_avatarsKey"...',
      );
      final prefs = await SharedPreferences.getInstance();

      // Retrieve the saved JSON string.
      final String? avatarsJsonString = prefs.getString(_avatarsKey);

      // If there's no saved string (or it's empty), return an empty list.
      if (avatarsJsonString == null || avatarsJsonString.isEmpty) {
        debugPrint(
          '[StorageService] No avatar data found in SharedPreferences.',
        );
        return [];
      }

      debugPrint(
        '[StorageService] Found JSON string (${avatarsJsonString.length} chars). Decoding...',
      );

      // Decode the JSON string into a Dart List<dynamic> (list of maps).
      List<dynamic> decodedJsonList;
      try {
        decodedJsonList = jsonDecode(avatarsJsonString);
      } catch (e, stackTrace) {
        // If decoding fails, the stored data is corrupt. Log it and return empty.
        debugPrint(
          '[StorageService] CRITICAL: Error decoding avatars JSON: $e\n$stackTrace',
        );
        debugPrint('[StorageService] Corrupt JSON data: $avatarsJsonString');
        // Consider removing the corrupt data here to prevent repeated load failures.
        // await prefs.remove(_avatarsKey);
        return [];
      }

      // If the decoded JSON is not a list or is empty, return empty.
      if (decodedJsonList.isEmpty) {
        debugPrint('[StorageService] Decoded JSON is empty or not a list.');
        return [];
      }

      // Convert each map in the list back into an Avatar object.
      final List<Avatar> loadedAvatars = [];
      for (final item in decodedJsonList) {
        // Ensure the item is actually a Map before trying to parse it.
        if (item is Map<String, dynamic>) {
          try {
            // Use our helper function to convert the map back to an Avatar.
            loadedAvatars.add(_avatarFromJson(item));
          } catch (e, stackTrace) {
            // Log an error if a specific avatar fails parsing, but continue.
            final id = item['id'] ?? 'unknown';
            debugPrint(
              '[StorageService] Error parsing avatar with ID $id from JSON: $e\n$stackTrace',
            );
            // Optionally, skip this avatar.
          }
        } else {
          debugPrint(
            '[StorageService] Skipped non-map item in decoded JSON list: $item',
          );
        }
      }

      debugPrint(
        '[StorageService] Successfully loaded and parsed ${loadedAvatars.length} avatars.',
      );
      return loadedAvatars;
    } catch (e, stackTrace) {
      // Catch-all for unexpected errors during loading.
      debugPrint(
        '[StorageService] Unexpected error loading avatars: $e\n$stackTrace',
      );
      return []; // Return empty list on error.
    }
  }

  /// Retrieves the timestamp of the last successful avatar save operation.
  Future<DateTime?> getLastSyncTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? lastSyncString = prefs.getString(_lastSyncKey);

      if (lastSyncString == null || lastSyncString.isEmpty) {
        return null; // No sync time recorded yet.
      }

      // Parse the stored ISO 8601 string back into a DateTime object.
      return DateTime.parse(lastSyncString);
    } catch (e, stackTrace) {
      debugPrint(
        '[StorageService] Error getting last sync time: $e\n$stackTrace',
      );
      return null;
    }
  }

  // --- Audio File Persistence (File System) ---

  /// Gets the directory where audio files should be stored.
  /// Creates it if it doesn't exist.
  /// Returns null if the directory cannot be obtained or created (e.g., on web).
  Future<Directory?> _getAudioDirectory() async {
    if (kIsWeb) {
      debugPrint(
        '[StorageService] Cannot get audio directory on web platform.',
      );
      return null; // File system access is different on web.
    }
    try {
      // Find the standard directory for application documents.
      final appDocDir = await getApplicationDocumentsDirectory();
      // Define the path for our dedicated audio subdirectory.
      final audioDirPath = '${appDocDir.path}/$_audioDirName';
      final audioDir = Directory(audioDirPath);

      // Check if the directory exists. If not, create it.
      if (!await audioDir.exists()) {
        debugPrint(
          '[StorageService] Audio directory not found. Creating at: $audioDirPath',
        );
        // `recursive: true` creates parent directories if needed (though unlikely here).
        await audioDir.create(recursive: true);
        debugPrint('[StorageService] Audio directory created.');
      }
      return audioDir;
    } catch (e, stackTrace) {
      debugPrint(
        '[StorageService] Error getting/creating audio directory: $e\n$stackTrace',
      );
      return null;
    }
  }

  /// Saves the provided audio data (`bytes`) as a file with the given `fileName`
  /// within the app's dedicated audio directory.
  /// Returns the full path to the saved file.
  /// Throws an error if saving fails.
  Future<String> saveAudioFile(String fileName, List<int> bytes) async {
    // Get the audio storage directory.
    final audioDir = await _getAudioDirectory();
    if (audioDir == null) {
      throw FileSystemException(
        'Could not get audio directory (platform unsupported or error).',
      );
    }

    // TODO: Sanitize fileName? Ensure it doesn't contain path separators etc.
    final safeFileName = fileName.replaceAll(
      RegExp(r'[\/\\:*?"<>|]'),
      '_',
    ); // Basic sanitization
    final filePath = '${audioDir.path}/$safeFileName';
    debugPrint('[StorageService] Saving audio file to: $filePath');

    try {
      // Create a File object representing the target path.
      final file = File(filePath);
      // Write the byte data to the file. This overwrites if the file exists.
      await file.writeAsBytes(bytes);
      debugPrint('[StorageService] Audio file saved successfully.');
      return filePath; // Return the path where the file was saved.
    } catch (e, stackTrace) {
      debugPrint(
        '[StorageService] Error writing audio file $filePath: $e\n$stackTrace',
      );
      // Rethrow the error so the caller (e.g., AvatarProvider) knows it failed.
      rethrow;
    }
  }

  /// Deletes the audio file at the specified `filePath`.
  /// Returns `true` if the file was deleted or didn't exist, `false` on error.
  Future<bool> deleteAudioFile(String filePath) async {
    // Basic check: Don't try to delete if the path is empty.
    if (filePath.isEmpty) {
      debugPrint(
        '[StorageService] Cannot delete file: Empty file path provided.',
      );
      return false;
    }

    // Skip deletion on web as file paths might not be standard file system paths.
    if (kIsWeb) {
      debugPrint(
        '[StorageService] Skipping file deletion on web for path: $filePath',
      );
      return true; // Consider it deleted on web for consistency
    }

    try {
      final file = File(filePath);
      debugPrint('[StorageService] Attempting to delete file: $filePath');

      // Check if the file actually exists before trying to delete.
      if (await file.exists()) {
        try {
          await file.delete();
          debugPrint('[StorageService] File deleted successfully.');
          return true;
        } catch (deleteError, stackTrace) {
          // Log the specific error during deletion.
          debugPrint(
            '[StorageService] Error deleting file $filePath: $deleteError\n$stackTrace',
          );

          // Optional: Retry logic (could be useful for temporary locks)
          // await Future.delayed(const Duration(milliseconds: 100));
          // try {
          //   if (await file.exists()) { await file.delete(); return true; }
          // } catch (retryError) { ... }
          return false; // Return false if deletion failed.
        }
      } else {
        // If the file doesn't exist, we can consider the deletion successful.
        debugPrint(
          '[StorageService] File does not exist, deletion skipped (considered success).',
        );
        return true;
      }
    } catch (e, stackTrace) {
      // Catch unexpected errors (e.g., issues with File constructor itself).
      debugPrint(
        '[StorageService] Unexpected error during file deletion check for $filePath: $e\n$stackTrace',
      );
      return false;
    }
  }

  // --- Data Clearing ---

  /// Clears *all* data managed by this service:
  /// - Avatar list from SharedPreferences.
  /// - Last sync time from SharedPreferences.
  /// - All files within the dedicated audio directory.
  Future<void> clearAllData() async {
    debugPrint(
      '[StorageService] WARNING: Clearing ALL stored data (prefs and files)... 💣',
    );

    bool prefsCleared = false;
    bool filesCleared = false;

    // 1. Clear SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final r1 = await prefs.remove(_avatarsKey);
      final r2 = await prefs.remove(_lastSyncKey);
      // Add other keys here if needed: await prefs.remove('some_other_key');
      prefsCleared = r1 && r2; // Check if removals were successful
      debugPrint(
        '[StorageService] SharedPreferences cleared (success: $prefsCleared).',
      );
    } catch (e, stackTrace) {
      debugPrint(
        '[StorageService] Error clearing SharedPreferences: $e\n$stackTrace',
      );
    }

    // 2. Clear Audio Files Directory
    final audioDir = await _getAudioDirectory();
    if (audioDir != null) {
      try {
        debugPrint(
          '[StorageService] Clearing audio files in directory: ${audioDir.path}',
        );
        if (await audioDir.exists()) {
          // Delete the entire directory and its contents.
          await audioDir.delete(recursive: true);
          // Optionally recreate the empty directory immediately.
          await audioDir.create(recursive: true);
          filesCleared = true;
          debugPrint(
            '[StorageService] Audio files directory cleared and recreated.',
          );
        } else {
          debugPrint(
            '[StorageService] Audio directory did not exist, no files to clear.',
          );
          filesCleared = true; // Considered success if dir doesn't exist.
        }
      } catch (e, stackTrace) {
        debugPrint(
          '[StorageService] Error clearing audio files directory: $e\n$stackTrace',
        );
      }
    } else {
      // If _getAudioDirectory returned null (e.g., web), consider files cleared.
      filesCleared = true;
      debugPrint(
        '[StorageService] Skipping audio file clearing (platform unsupported or error).',
      );
    }

    debugPrint(
      '[StorageService] clearAllData finished. Prefs: $prefsCleared, Files: $filesCleared',
    );

    // Optionally throw an error if clearing failed partially or completely.
    // if (!prefsCleared || !filesCleared) {
    //   throw Exception('Failed to clear all storage data.');
    // }
  }

  // --- JSON Conversion Helpers --- //
  // These methods handle the conversion between Dart objects and JSON maps.

  /// Converts an `Avatar` object into a Map suitable for JSON encoding.
  Map<String, dynamic> _avatarToJson(Avatar avatar) {
    return {
      'id': avatar.id,
      'name': avatar.name,
      'color': avatar.color,
      'icon': _iconDataToString(avatar.icon), // Convert IconData to string
      // Recursively convert the list of Voice objects.
      'voices': avatar.voices.map((voice) => _voiceToJson(voice)).toList(),
      // Added in v2
      'imagePath': avatar.imagePath,
    };
  }

  /// Converts a Map (typically from decoded JSON) into an `Avatar` object.
  Avatar _avatarFromJson(Map<String, dynamic> json) {
    // Extract voices, ensuring it's a List and handling potential errors during Voice parsing.
    List<Voice> voices = [];
    if (json['voices'] is List) {
      voices =
          (json['voices'] as List)
              .map<Voice?>((voiceJson) {
                if (voiceJson is Map<String, dynamic>) {
                  try {
                    return _voiceFromJson(voiceJson);
                  } catch (e) {
                    debugPrint(
                      '[StorageService] Error parsing voice from JSON: $e. Skipping voice.',
                    );
                    return null;
                  }
                }
                return null;
              })
              .whereType<Voice>()
              .toList(); // Filter out nulls from failed parsing
    }

    return Avatar(
      // Provide default values or handle nulls gracefully for robustness.
      id:
          json['id'] as String? ??
          'missing_id_${DateTime.now().millisecondsSinceEpoch}', // Ensure ID exists
      name: json['name'] as String? ?? 'Unnamed Avatar',
      color:
          json['color']
              as String?, // Allow null color, constructor will handle default
      icon:
          json['icon'] != null
              ? _stringToIconData(json['icon'] as String)
              : null, // Handle null icon string
      voices: voices,
      imagePath: json['imagePath'] as String?, // Added in v2
    );
  }

  /// Converts a `Voice` object into a Map suitable for JSON encoding.
  Map<String, dynamic> _voiceToJson(Voice voice) {
    return {
      'id': voice.id,
      'name': voice.name,
      'audioUrl': voice.audioUrl,
      'duration':
          voice.duration.inMilliseconds, // Store duration as milliseconds
      'createdAt':
          voice.createdAt.toIso8601String(), // Store dates as ISO 8601 strings
      'category': voice.category,
      'playCount': voice.playCount,
      'lastPlayed':
          voice.lastPlayed?.toIso8601String(), // Handle nullable DateTime
      'color': voice.color, // Store voice-specific color
    };
  }

  /// Converts a Map (typically from decoded JSON) into a `Voice` object.
  Voice _voiceFromJson(Map<String, dynamic> json) {
    return Voice(
      id:
          json['id'] as String? ??
          'missing_id_${DateTime.now().millisecondsSinceEpoch}', // Ensure ID exists
      name: json['name'] as String? ?? 'Unnamed Voice',
      audioUrl: json['audioUrl'] as String? ?? '', // Ensure audioUrl exists
      // Parse duration from milliseconds, default to zero if missing/invalid.
      duration: Duration(milliseconds: (json['duration'] as int?) ?? 0),
      // Parse DateTime, default to now if missing/invalid.
      createdAt:
          json['createdAt'] != null
              ? (DateTime.tryParse(json['createdAt'] as String) ??
                  DateTime.now())
              : DateTime.now(),
      category: json['category'] as String? ?? 'Uncategorized',
      playCount: (json['playCount'] as int?) ?? 0,
      // Parse nullable DateTime.
      lastPlayed:
          json['lastPlayed'] != null
              ? DateTime.tryParse(json['lastPlayed'] as String)
              : null,
      color: json['color'] as String?, // Allow null color
    );
  }

  /// Converts `IconData` to a simple string representation for storage.
  /// Format: "codePoint:fontFamily:fontPackage"
  /// Nulls are represented as the string "null".
  String _iconDataToString(IconData? icon) {
    if (icon == null) return ''; // Return empty string for null icon
    // Ensure fontFamily and fontPackage are represented correctly if null.
    return '${icon.codePoint}:${icon.fontFamily ?? 'null'}:${icon.fontPackage ?? 'null'}';
  }

  /// Converts a string (from storage) back into `IconData`.
  /// Handles the format "codePoint:fontFamily:fontPackage".
  /// Returns null if the string is empty or invalid.
  IconData? _stringToIconData(String? iconString) {
    if (iconString == null || iconString.isEmpty) {
      return null; // Return null if input is null or empty
    }
    try {
      final parts = iconString.split(':');
      if (parts.length < 2)
        throw const FormatException('Invalid IconData string format');

      final codePoint = int.parse(parts[0]);
      // Handle "null" strings correctly when parsing.
      final fontFamily = (parts[1] == 'null') ? null : parts[1];
      final fontPackage =
          (parts.length > 2 && parts[2] != 'null') ? parts[2] : null;

      return IconData(
        codePoint,
        fontFamily: fontFamily,
        fontPackage: fontPackage,
      );
    } catch (e) {
      debugPrint(
        '[StorageService] Error converting string "$iconString" to IconData: $e',
      );
      return null; // Return null if parsing fails
    }
  }
}
