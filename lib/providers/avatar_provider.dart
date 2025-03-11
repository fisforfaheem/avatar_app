import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/avatar.dart';
import '../services/storage_service.dart';

/// A list of predefined avatar icons to choose from
final List<IconData> predefinedAvatarIcons = [
  Icons.person,
  Icons.face,
  Icons.face_2,
  Icons.face_3,
  Icons.face_4,
  Icons.face_5,
  Icons.face_6,
  Icons.face_retouching_natural,
  Icons.sentiment_satisfied_alt,
  Icons.emoji_emotions,
  Icons.emoji_people,
  Icons.sports_esports,
  Icons.music_note,
  Icons.pets,
  Icons.workspace_premium,
];

/// A list of predefined avatar colors to choose from
final List<String> predefinedAvatarColors = [
  'blue',
  'purple',
  'pink',
  'orange',
  'green',
  'teal',
  'red',
  'amber',
  'indigo',
  'cyan',
];

class AvatarProvider with ChangeNotifier {
  final List<Avatar> _avatars = [];
  Avatar? _selectedAvatar;
  String _searchQuery = '';
  final StorageService _storageService = StorageService();
  bool _isLoading = true;
  String? _errorMessage;

  AvatarProvider() {
    _loadAvatarsFromStorage();
  }

  List<Avatar> get avatars => List.unmodifiable(_avatars);
  Avatar? get selectedAvatar => _selectedAvatar;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Load avatars from storage
  Future<void> _loadAvatarsFromStorage() async {
    try {
      _isLoading = true;
      notifyListeners();

      final loadedAvatars = await _storageService.loadAvatars();
      _avatars.clear();
      _avatars.addAll(loadedAvatars);

      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load avatars: ${e.toString()}';
      debugPrint(_errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Save avatars to storage
  Future<void> _saveAvatarsToStorage() async {
    try {
      await _storageService.saveAvatars(_avatars);
    } catch (e) {
      _errorMessage = 'Failed to save avatars: ${e.toString()}';
      debugPrint(_errorMessage);
      // Rethrow to allow caller to handle the error
      rethrow;
    }
  }

  // Get the list of predefined avatar icons
  List<IconData> get predefinedIcons => predefinedAvatarIcons;

  // Get the list of predefined avatar colors
  List<String> get predefinedColors => predefinedAvatarColors;

  // Get filtered avatars based on search query
  List<Avatar> getFilteredAvatars() {
    if (_searchQuery.isEmpty) {
      return _avatars;
    }

    final query = _searchQuery.toLowerCase();
    return _avatars.where((avatar) {
      // Check if avatar name matches
      if (avatar.name.toLowerCase().contains(query)) {
        return true;
      }

      // Check if any voice name matches
      return avatar.voices.any(
        (voice) =>
            voice.name.toLowerCase().contains(query) ||
            voice.category.toLowerCase().contains(query),
      );
    }).toList();
  }

  // Get all voices that match the search query
  List<Map<String, dynamic>> searchVoices(String query) {
    if (query.isEmpty) {
      return [];
    }

    final lowercaseQuery = query.toLowerCase();
    List<Map<String, dynamic>> results = [];

    for (final avatar in _avatars) {
      for (final voice in avatar.voices) {
        if (voice.name.toLowerCase().contains(lowercaseQuery) ||
            voice.category.toLowerCase().contains(lowercaseQuery)) {
          results.add({'avatar': avatar, 'voice': voice});
        }
      }
    }

    return results;
  }

  // Set search query
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // Clear search query
  void clearSearchQuery() {
    _searchQuery = '';
    notifyListeners();
  }

  void addAvatar(String name, {IconData? icon, String? color}) {
    final avatar = Avatar(name: name, icon: icon, color: color);
    _avatars.add(avatar);
    _saveAvatarsToStorage();
    notifyListeners();
  }

  void updateAvatar(String id, {String? name, IconData? icon, String? color}) {
    final avatarIndex = _avatars.indexWhere((avatar) => avatar.id == id);
    if (avatarIndex != -1) {
      final avatar = _avatars[avatarIndex];
      _avatars[avatarIndex] = avatar.copyWith(
        name: name,
        icon: icon,
        color: color,
      );

      // Update selected avatar if it's the one being edited
      if (_selectedAvatar?.id == id) {
        _selectedAvatar = _avatars[avatarIndex];
      }

      _saveAvatarsToStorage();
      notifyListeners();
    }
  }

  void setSelectedAvatar(String? id) {
    if (id == null) {
      _selectedAvatar = null;
    } else {
      _selectedAvatar = _avatars.firstWhere((avatar) => avatar.id == id);
    }
    notifyListeners();
  }

  void addVoiceToAvatar(String avatarId, Voice voice) {
    final avatarIndex = _avatars.indexWhere((avatar) => avatar.id == avatarId);
    if (avatarIndex != -1) {
      final avatar = _avatars[avatarIndex];
      final updatedVoices = [...avatar.voices, voice];
      _avatars[avatarIndex] = avatar.copyWith(voices: updatedVoices);
      _saveAvatarsToStorage();
      notifyListeners();
    }
  }

  void removeVoiceFromAvatar(String avatarId, String voiceId) {
    final avatarIndex = _avatars.indexWhere((avatar) => avatar.id == avatarId);
    if (avatarIndex != -1) {
      final avatar = _avatars[avatarIndex];

      // Create a new list of voices without the removed voice
      final updatedVoices =
          avatar.voices.where((v) => v.id != voiceId).toList();

      // Update the avatar with the new voices list
      _avatars[avatarIndex] = avatar.copyWith(voices: updatedVoices);

      // Also delete the audio file
      for (final voice in avatar.voices) {
        if (voice.id == voiceId) {
          _storageService.deleteAudioFile(voice.audioUrl);
          break;
        }
      }

      _saveAvatarsToStorage();
      notifyListeners();
    }
  }

  // Remove all voices from an avatar
  void removeAllVoicesFromAvatar(String avatarId) {
    final avatarIndex = _avatars.indexWhere((avatar) => avatar.id == avatarId);
    if (avatarIndex != -1) {
      final avatar = _avatars[avatarIndex];

      // Delete all audio files for this avatar's voices
      for (final voice in avatar.voices) {
        _storageService.deleteAudioFile(voice.audioUrl);
      }

      // Update the avatar with an empty voices list
      _avatars[avatarIndex] = avatar.copyWith(voices: []);

      _saveAvatarsToStorage();
      notifyListeners();
    }
  }

  // Track voice usage
  void trackVoiceUsage(String avatarId, String voiceId) {
    final avatarIndex = _avatars.indexWhere((avatar) => avatar.id == avatarId);
    if (avatarIndex != -1) {
      final avatar = _avatars[avatarIndex];
      final voiceIndex = avatar.voices.indexWhere(
        (voice) => voice.id == voiceId,
      );

      if (voiceIndex != -1) {
        final voice = avatar.voices[voiceIndex];
        final updatedVoice = voice.incrementPlayCount();

        // Create a new list of voices with the updated voice
        final updatedVoices = List<Voice>.from(avatar.voices);
        updatedVoices[voiceIndex] = updatedVoice;

        // Update the avatar with the new voices list
        _avatars[avatarIndex] = avatar.copyWith(voices: updatedVoices);

        _saveAvatarsToStorage();
        notifyListeners();
      }
    }
  }

  // Get most used voices across all avatars
  List<Map<String, dynamic>> getMostUsedVoices({int limit = 10}) {
    List<Map<String, dynamic>> allVoices = [];

    for (final avatar in _avatars) {
      for (final voice in avatar.voices) {
        if (voice.playCount > 0) {
          allVoices.add({'avatar': avatar, 'voice': voice});
        }
      }
    }

    // Sort by play count (descending)
    allVoices.sort((a, b) {
      final voiceA = a['voice'] as Voice;
      final voiceB = b['voice'] as Voice;
      return voiceB.playCount.compareTo(voiceA.playCount);
    });

    // Return limited number of results
    return allVoices.take(limit).toList();
  }

  // Get recently used voices
  List<Map<String, dynamic>> getRecentlyUsedVoices({int limit = 10}) {
    List<Map<String, dynamic>> recentVoices = [];

    for (final avatar in _avatars) {
      for (final voice in avatar.voices) {
        if (voice.lastPlayed != null) {
          recentVoices.add({'avatar': avatar, 'voice': voice});
        }
      }
    }

    // Sort by last played time (most recent first)
    recentVoices.sort((a, b) {
      final voiceA = a['voice'] as Voice;
      final voiceB = b['voice'] as Voice;
      return (voiceB.lastPlayed ?? DateTime(0)).compareTo(
        voiceA.lastPlayed ?? DateTime(0),
      );
    });

    // Return limited number of results
    return recentVoices.take(limit).toList();
  }

  // Reorder voices within an avatar
  void reorderVoices(String avatarId, int oldIndex, int newIndex) {
    final avatarIndex = _avatars.indexWhere((avatar) => avatar.id == avatarId);
    if (avatarIndex != -1) {
      final avatar = _avatars[avatarIndex];

      // Create a new list of voices
      final updatedVoices = List<Voice>.from(avatar.voices);

      // Handle the reordering
      if (oldIndex < newIndex) {
        // Removing the item at oldIndex will shorten the list by 1
        newIndex -= 1;
      }

      // Remove the voice from the old position and insert at the new position
      final voice = updatedVoices.removeAt(oldIndex);
      updatedVoices.insert(newIndex, voice);

      // Update the avatar with the new voices list
      _avatars[avatarIndex] = avatar.copyWith(voices: updatedVoices);

      // Save changes
      _saveAvatarsToStorage();
      notifyListeners();
    }
  }

  // Update the color of a voice
  void updateVoiceColor(String avatarId, String voiceId, String colorName) {
    final avatarIndex = _avatars.indexWhere((avatar) => avatar.id == avatarId);
    if (avatarIndex != -1) {
      final avatar = _avatars[avatarIndex];
      final voiceIndex = avatar.voices.indexWhere(
        (voice) => voice.id == voiceId,
      );

      if (voiceIndex != -1) {
        final voice = avatar.voices[voiceIndex];
        final updatedVoice = voice.copyWith(color: colorName);

        // Create a new list of voices with the updated voice
        final updatedVoices = List<Voice>.from(avatar.voices);
        updatedVoices[voiceIndex] = updatedVoice;

        // Update the avatar with the new voices list
        _avatars[avatarIndex] = avatar.copyWith(voices: updatedVoices);

        // Save changes
        _saveAvatarsToStorage();
        notifyListeners();
      }
    }
  }

  // Flag to track if deletion is in progress
  bool _isDeletingAvatar = false;
  bool get isDeletingAvatar => _isDeletingAvatar;

  // Remove avatar asynchronously to prevent UI freezing
  Future<void> removeAvatar(String id) async {
    try {
      // Set deleting flag
      _isDeletingAvatar = true;
      notifyListeners();

      // Find the avatar to remove
      final avatarToRemove = _avatars.firstWhere(
        (avatar) => avatar.id == id,
        orElse: () => Avatar(name: ''),
      );

      // If avatar not found, just return
      if (avatarToRemove.id.isEmpty) {
        _isDeletingAvatar = false;
        notifyListeners();
        return;
      }

      // Make a copy of the voices for deletion later
      final voicesToDelete = List<Voice>.from(avatarToRemove.voices);

      // Remove the avatar from the list first to update UI
      _avatars.removeWhere((avatar) => avatar.id == id);
      if (_selectedAvatar?.id == id) {
        _selectedAvatar = null;
      }

      // Save changes to storage - wrap in try/catch to handle JSON errors
      try {
        await _saveAvatarsToStorage();
      } catch (e) {
        debugPrint('Error saving avatars to storage: $e');
        // Try again with a delay
        await Future.delayed(const Duration(milliseconds: 100));
        try {
          await _saveAvatarsToStorage();
        } catch (e) {
          debugPrint('Second attempt to save avatars failed: $e');
          // Continue anyway - we'll try to clean up as much as possible
        }
      }

      // Notify listeners that the avatar has been removed
      notifyListeners();

      // Delete audio files in the background
      // This happens after the UI is updated so it won't freeze
      for (final voice in voicesToDelete) {
        try {
          await _storageService.deleteAudioFile(voice.audioUrl);
          // Add a small delay between file deletions to prevent overwhelming the system
          await Future.delayed(const Duration(milliseconds: 50));
        } catch (e) {
          debugPrint('Error deleting audio file: ${voice.audioUrl}, error: $e');
          // Continue with the next file even if this one fails
        }
      }
    } catch (e) {
      debugPrint('Error removing avatar: $e');
      // If there was an error, try to reload avatars to ensure UI is in sync with storage
      try {
        await _loadAvatarsFromStorage();
      } catch (e) {
        debugPrint('Error reloading avatars: $e');
        // Ignore errors from reload attempt
      }
    } finally {
      // Clear deleting flag
      _isDeletingAvatar = false;
      notifyListeners();
    }
  }

  // Save audio file and return the file path
  Future<String> saveAudioFile(String fileName, List<int> bytes) async {
    return await _storageService.saveAudioFile(fileName, bytes);
  }

  // Force reload avatars from storage
  Future<void> reloadAvatars() async {
    await _loadAvatarsFromStorage();
  }

  // Clear all data
  Future<void> clearAllData() async {
    await _storageService.clearAllData();
    _avatars.clear();
    _selectedAvatar = null;
    notifyListeners();
  }

  // Delete all avatars and their associated data
  Future<void> deleteAllAvatars() async {
    try {
      debugPrint('[AvatarProvider] Starting deleteAllAvatars...');

      // Set loading state
      _isDeletingAvatar = true;
      notifyListeners();

      // Collect all voice audio URLs to delete
      final List<String> audioFilesToDelete = [];
      debugPrint('[AvatarProvider] Collecting audio files to delete...');

      for (final avatar in _avatars) {
        for (final voice in avatar.voices) {
          audioFilesToDelete.add(voice.audioUrl);
        }
      }

      debugPrint(
        '[AvatarProvider] Found ${audioFilesToDelete.length} audio files to delete',
      );

      // Clear avatars list
      _avatars.clear();
      _selectedAvatar = null;

      // Save empty list to storage
      debugPrint('[AvatarProvider] Saving empty avatars list to storage...');
      try {
        await _saveAvatarsToStorage();
        debugPrint('[AvatarProvider] Successfully saved empty avatars list');
      } catch (storageError) {
        debugPrint(
          '[AvatarProvider] Error saving empty avatars list: $storageError',
        );
        // Continue with deletion even if saving fails
      }

      // Notify listeners that avatars have been removed
      notifyListeners();

      // Delete audio files in the background
      debugPrint('[AvatarProvider] Starting to delete audio files...');
      int deletedCount = 0;
      int errorCount = 0;

      for (final audioUrl in audioFilesToDelete) {
        try {
          final result = await _storageService.deleteAudioFile(audioUrl);
          if (result) {
            deletedCount++;
          } else {
            errorCount++;
          }

          // Add a small delay between file deletions to prevent overwhelming the system
          await Future.delayed(const Duration(milliseconds: 20));
        } catch (e) {
          errorCount++;
          debugPrint(
            '[AvatarProvider] Error deleting audio file: $audioUrl, error: $e',
          );
          // Continue with the next file even if this one fails
        }
      }

      debugPrint(
        '[AvatarProvider] Deleted $deletedCount audio files with $errorCount errors',
      );

      // Clear any usage statistics or other data
      debugPrint('[AvatarProvider] Clearing all data in storage service...');
      try {
        await _storageService.clearAllData();
        debugPrint('[AvatarProvider] Successfully cleared all data');
      } catch (clearError) {
        debugPrint('[AvatarProvider] Error clearing all data: $clearError');
        // Continue even if clearing fails
      }

      debugPrint('[AvatarProvider] deleteAllAvatars completed successfully');
    } catch (e) {
      debugPrint('[AvatarProvider] Error deleting all avatars: $e');
      // If there was an error, try to reload avatars to ensure UI is in sync with storage
      try {
        await _loadAvatarsFromStorage();
      } catch (e) {
        debugPrint('[AvatarProvider] Error reloading avatars: $e');
        // Ignore errors from reload attempt
      }

      // Rethrow the error so the caller can handle it
      rethrow;
    } finally {
      // Clear deleting flag
      _isDeletingAvatar = false;
      notifyListeners();
      debugPrint('[AvatarProvider] Reset deleting flag and notified listeners');
    }
  }
}
