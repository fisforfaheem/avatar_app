import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/avatar.dart';
import '../services/storage_service.dart';

/// A handy list of icons users can pick from when creating an Avatar.
/// Makes setup quick and easy! ✨
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

/// A palette of colors users can assign to their Avatars.
/// Helps keep things organized and visually distinct. 🎨
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

/// The main state management class for all things Avatar!
///
/// This provider is responsible for:
/// - Holding the list of all Avatars.
/// - Loading avatars from and saving them to persistent storage (`StorageService`).
/// - Managing the currently selected Avatar.
/// - Handling search and filtering.
/// - Adding, updating, and deleting Avatars and their Voices.
/// - Tracking voice usage statistics.
/// - Providing access to predefined icons and colors.
///
/// It uses `ChangeNotifier` so that the UI automatically updates when avatar data changes.
class AvatarProvider with ChangeNotifier {
  // --- State Variables ---

  // The main list holding all the Avatar objects in memory.
  // It's private (`_`) so it can only be modified through the provider's methods.
  final List<Avatar> _avatars = [];

  // The currently selected Avatar, if any. Used for detail views or focused operations.
  Avatar? _selectedAvatar;

  // The current text entered in the search bar.
  String _searchQuery = '';

  // An instance of our storage service to handle saving/loading data to disk/prefs.
  final StorageService _storageService = StorageService();

  // Are we currently busy loading data from storage? Used for loading indicators.
  bool _isLoading = true;

  // If an error occurred during loading/saving, this holds the message.
  String? _errorMessage;

  // Is an avatar deletion operation currently in progress?
  bool _isDeletingAvatar = false;

  // --- Constructor ---

  /// When the provider is first created, immediately try to load existing avatars.
  AvatarProvider() {
    debugPrint('AvatarProvider initialized - Loading avatars...');
    _loadAvatarsFromStorage();
  }

  // --- Public Getters ---

  /// Provides a read-only view of the current avatars list.
  /// `List.unmodifiable` prevents external code from accidentally changing the list directly.
  List<Avatar> get avatars => List.unmodifiable(_avatars);

  /// The currently selected Avatar (can be null if none is selected).
  Avatar? get selectedAvatar => _selectedAvatar;

  /// The current search query text.
  String get searchQuery => _searchQuery;

  /// True if the provider is currently loading initial data.
  bool get isLoading => _isLoading;

  /// The last error message, if any (null otherwise).
  String? get errorMessage => _errorMessage;

  /// True if an avatar deletion is currently happening in the background.
  bool get isDeletingAvatar => _isDeletingAvatar;

  /// Provides access to the predefined list of icons.
  List<IconData> get predefinedIcons => predefinedAvatarIcons;

  /// Provides access to the predefined list of colors.
  List<String> get predefinedColors => predefinedAvatarColors;

  // --- Data Persistence (Loading & Saving) ---

  /// Loads the list of avatars from the `StorageService`.
  /// This is usually called once when the provider is initialized.
  Future<void> _loadAvatarsFromStorage() async {
    try {
      debugPrint('Attempting to load avatars from storage...');
      _isLoading = true;
      _errorMessage = null; // Clear previous errors
      notifyListeners(); // Notify UI about loading state

      // Call the storage service to get the saved data.
      final loadedAvatars = await _storageService.loadAvatars();
      _avatars.clear(); // Clear the current list
      _avatars.addAll(loadedAvatars); // Add the loaded avatars
      debugPrint('Loaded ${_avatars.length} avatars successfully.');

      _errorMessage = null; // Ensure error message is cleared on success
    } catch (e, stackTrace) {
      // Uh oh, something went wrong during loading.
      _errorMessage = 'Failed to load avatars: ${e.toString()}';
      debugPrint('$_errorMessage\nStack trace:\n$stackTrace 😭');
      _avatars.clear(); // Clear avatars on error to avoid inconsistent state
    } finally {
      // Whether loading succeeded or failed, we're no longer loading.
      _isLoading = false;
      notifyListeners(); // Notify UI about the final state (loaded data or error)
    }
  }

  /// Saves the current list of avatars (_avatars) to storage via `StorageService`.
  /// This should be called *after* any modification to the avatars list or their contents.
  Future<void> _saveAvatarsToStorage() async {
    try {
      debugPrint('Saving ${_avatars.length} avatars to storage...');
      await _storageService.saveAvatars(_avatars);
      _errorMessage = null; // Clear any previous save errors
      debugPrint('Avatars saved successfully.');
    } catch (e, stackTrace) {
      // Saving failed! This is more critical than loading usually.
      _errorMessage = 'Failed to save avatars: ${e.toString()}';
      debugPrint('$_errorMessage\nStack trace:\n$stackTrace 💾❌');
      // Notify listeners about the error state, but don't clear local data.
      notifyListeners();
      // Rethrow the error so the calling function knows saving failed.
      rethrow;
    }
  }

  // --- Search & Filtering ---

  /// Returns a list of avatars filtered by the current `_searchQuery`.
  /// If the query is empty, returns all avatars.
  /// Searches within avatar names AND voice names/categories.
  List<Avatar> getFilteredAvatars() {
    // If no search query, return everything!
    if (_searchQuery.isEmpty) {
      return _avatars;
    }

    // Prepare the query for case-insensitive comparison.
    final query = _searchQuery.toLowerCase();

    // Filter the list.
    return _avatars.where((avatar) {
      // Match if the avatar's name contains the query.
      if (avatar.name.toLowerCase().contains(query)) {
        return true;
      }

      // OR match if *any* of the avatar's voices contain the query in their name or category.
      return avatar.voices.any(
        (voice) =>
            voice.name.toLowerCase().contains(query) ||
            voice.category.toLowerCase().contains(query),
      );
    }).toList(); // Convert the result back to a List.
  }

  /// Performs a search specifically across all voices in all avatars.
  /// Returns a list of maps, each containing the matching `Voice` and its parent `Avatar`.
  /// Useful for a global voice search feature.
  List<Map<String, dynamic>> searchVoices(String query) {
    // Don't bother searching if the query is empty.
    if (query.isEmpty) {
      return [];
    }

    final lowercaseQuery = query.toLowerCase();
    List<Map<String, dynamic>> results = [];

    // Iterate through each avatar...
    for (final avatar in _avatars) {
      // ...and through each voice within that avatar.
      for (final voice in avatar.voices) {
        // Check if the voice name or category matches the query.
        if (voice.name.toLowerCase().contains(lowercaseQuery) ||
            voice.category.toLowerCase().contains(lowercaseQuery)) {
          // If it matches, add the voice and its avatar to the results.
          results.add({'avatar': avatar, 'voice': voice});
        }
      }
    }

    debugPrint('Voice search for "$query" found ${results.length} results.');
    return results;
  }

  /// Updates the internal search query state.
  void setSearchQuery(String query) {
    if (_searchQuery == query) return; // No change
    _searchQuery = query;
    debugPrint('Search query set to: "$_searchQuery"');
    notifyListeners(); // Trigger UI update for filtered lists etc.
  }

  /// Clears the search query.
  void clearSearchQuery() {
    setSearchQuery(''); // Just set it to empty
  }

  // --- Avatar Management (Add, Update, Delete) ---

  /// Adds a new avatar to the list and saves the changes.
  Future<Avatar> addAvatar(
    String name, {
    IconData? icon, // Optional icon
    String? color, // Optional color
    String? imagePath, // Optional custom image path
  }) async {
    // Basic validation: Need a name!
    if (name.trim().isEmpty) {
      throw ArgumentError('Avatar name cannot be empty.');
    }

    try {
      debugPrint('Adding new avatar with name: "$name"...');
      _isLoading = true; // Indicate activity
      _errorMessage = null;
      notifyListeners();

      // Create the new Avatar object using the provided details.
      // The Avatar constructor handles default icons/colors if not provided.
      final newAvatar = Avatar(
        name: name.trim(), // Trim whitespace
        icon: icon,
        color: color,
        imagePath: imagePath,
      );

      // Add it to our in-memory list.
      _avatars.add(newAvatar);

      // Persist the changes to storage.
      await _saveAvatarsToStorage();

      debugPrint('Successfully added avatar with ID: ${newAvatar.id}');
      return newAvatar; // Return the newly created avatar
    } catch (e) {
      // Handle potential errors during saving.
      _errorMessage = 'Failed to add avatar: ${e.toString()}';
      debugPrint(_errorMessage);
      // Rethrow the error so the UI can display a message.
      rethrow;
    } finally {
      _isLoading = false; // Done with the add operation
      notifyListeners();
    }
  }

  /// Updates an existing avatar's properties (name, icon, color, imagePath).
  /// Finds the avatar by its ID.
  Future<void> updateAvatar(
    String id, {
    String? name,
    IconData? icon,
    String? color,
    String? imagePath,
    bool clearImagePath = false, // Explicit flag to remove image
  }) async {
    // Find the index of the avatar to update.
    final avatarIndex = _avatars.indexWhere((avatar) => avatar.id == id);

    if (avatarIndex != -1) {
      debugPrint('Updating avatar with ID: $id');
      final originalAvatar = _avatars[avatarIndex];

      // Create the updated avatar using copyWith.
      // Use new values if provided, otherwise keep the originals.
      final updatedAvatar = originalAvatar.copyWith(
        name: name?.trim(), // Trim new name if provided
        icon: icon,
        color: color,
        // Handle image path update/removal:
        imagePath:
            clearImagePath ? null : (imagePath ?? originalAvatar.imagePath),
      );

      // Replace the old avatar with the updated one in the list.
      _avatars[avatarIndex] = updatedAvatar;

      // If the *selected* avatar is the one being edited, update the selection too.
      if (_selectedAvatar?.id == id) {
        _selectedAvatar = updatedAvatar;
        debugPrint('Updated selected avatar as well.');
      }

      // Save the changes.
      try {
        await _saveAvatarsToStorage();
        notifyListeners(); // Notify UI after successful save
        debugPrint('Avatar $id updated successfully.');
      } catch (e) {
        // If saving fails, we should arguably revert the change in memory
        // or at least inform the user more clearly.
        // For now, we've already set the error message in _saveAvatarsToStorage.
        debugPrint('Failed to save update for avatar $id.');
        // We already notified listeners about the error in _saveAvatarsToStorage.
        // Consider if a revert is needed here.
        _avatars[avatarIndex] = originalAvatar; // Revert the change in memory
        if (_selectedAvatar?.id == id) _selectedAvatar = originalAvatar;
        notifyListeners(); // Notify about the revert
        rethrow; // Rethrow the save error
      }
    } else {
      debugPrint('Attempted to update non-existent avatar with ID: $id 🤷‍♂️');
      throw Exception('Avatar with ID $id not found for update.');
    }
  }

  /// Sets the currently selected avatar by its ID.
  /// Pass `null` to deselect any avatar.
  void setSelectedAvatar(String? id) {
    if (_selectedAvatar?.id == id) return; // Already selected or deselected

    if (id == null) {
      _selectedAvatar = null;
      debugPrint('Avatar deselected.');
    } else {
      try {
        // Find the avatar in the list by its ID.
      _selectedAvatar = _avatars.firstWhere((avatar) => avatar.id == id);
        debugPrint('Avatar selected: ${_selectedAvatar?.name} (ID: $id)');
      } catch (e) {
        // This shouldn't happen if the ID comes from the UI list,
        // but handle it just in case.
        _selectedAvatar = null;
        debugPrint('Could not find avatar with ID $id to select.');
      }
    }
    // Notify listeners that the selection has changed.
    notifyListeners();
  }

  /// Removes an avatar and all its associated voice data (including audio files).
  /// This operation is asynchronous to avoid blocking the UI, especially during file deletion.
  Future<void> removeAvatar(String id) async {
    // Prevent concurrent deletions or operations while deleting.
    if (_isDeletingAvatar) {
      debugPrint(
        'Deletion already in progress, skipping removeAvatar for ID: $id',
      );
      return;
    }

    final avatarIndex = _avatars.indexWhere((avatar) => avatar.id == id);
    if (avatarIndex == -1) {
      debugPrint('Attempted to remove non-existent avatar with ID: $id');
      return; // Avatar not found
    }

    try {
      _isDeletingAvatar = true;
      notifyListeners(); // Show loading/disabled state in UI
      debugPrint('Starting removal of avatar ID: $id');

      // Get the avatar object before removing it from the list.
      final avatarToRemove = _avatars[avatarIndex];

      // --- Step 1: Update In-Memory State & Notify UI ---  (Fast Part)
      // Remove the avatar from the main list.
      _avatars.removeAt(avatarIndex);
      // If the removed avatar was the selected one, deselect it.
      if (_selectedAvatar?.id == id) {
        _selectedAvatar = null;
        debugPrint('Deselected avatar $id as it was removed.');
      }

      // Save the updated list (without the removed avatar) *immediately*.
      // This makes the UI update feel quick, even if file deletion takes time.
      try {
        await _saveAvatarsToStorage();
        debugPrint('Saved avatar list after removing $id from memory.');
        // Notify UI *after* successful save of the removal.
        notifyListeners();
      } catch (e) {
        // BIG PROBLEM: Failed to save the removal. The avatar might reappear on next load.
        // We should try to recover or at least log this severely.
        debugPrint(
          'CRITICAL: Failed to save avatar list after removing $id! Re-adding to memory to avoid inconsistency.',
        );
        _avatars.insert(avatarIndex, avatarToRemove); // Put it back in memory
        // We need to re-notify about the failure/revert
        _isDeletingAvatar = false; // Reset flag as operation failed
        notifyListeners();
        rethrow; // Rethrow the critical save error
      }

      // --- Step 2: Delete Associated Audio Files (Slow Part - Background) ---
      debugPrint(
        'Starting background deletion of ${avatarToRemove.voices.length} audio files for avatar $id...',
      );
      int deletedFiles = 0;
      int failedFiles = 0;
      for (final voice in avatarToRemove.voices) {
        try {
          // Don't await each deletion individually if it takes too long.
          // Let them run concurrently, but be careful about resource limits.
          // A safer approach might be Future.wait with error handling,
          // or processing in batches.
          // For simplicity here, we await, but add a small delay.
          bool deleted = await _storageService.deleteAudioFile(voice.audioUrl);
          if (deleted)
            deletedFiles++;
          else
            failedFiles++;
          // Small delay to prevent overwhelming disk I/O, especially with many files.
          await Future.delayed(const Duration(milliseconds: 20));
        } catch (e) {
          failedFiles++;
          // Log deletion errors but continue deleting other files.
          debugPrint('Error deleting audio file ${voice.audioUrl}: $e');
        }
      }
      debugPrint(
        'Finished background audio file deletion for avatar $id. Success: $deletedFiles, Failures: $failedFiles',
      );
    } catch (e) {
      // Catch errors from the overall process (e.g., the initial save failure rethrow).
      _errorMessage = 'Failed to remove avatar: ${e.toString()}';
      debugPrint(_errorMessage);
      // Attempt to reload to ensure consistency, though this might bring back the avatar if save failed.
      await reloadAvatars();
      // Rethrow the error so the caller knows the operation failed.
      rethrow;
    } finally {
      // --- Step 3: Final Cleanup --- (Always Runs)
      _isDeletingAvatar = false;
      // Notify listeners one last time to ensure UI is in the correct final state (e.g., hide loading indicator).
      notifyListeners();
      debugPrint(
        'Avatar removal process finished for ID: $id. Deleting flag reset.',
      );
    }
  }

  // --- Voice Management (Add, Remove, Update, Reorder) ---

  /// Adds a new voice to a specific avatar.
  Future<void> addVoiceToAvatar(String avatarId, Voice voice) async {
    final avatarIndex = _avatars.indexWhere((avatar) => avatar.id == avatarId);
    if (avatarIndex != -1) {
      debugPrint('Adding voice "${voice.name}" to avatar ID: $avatarId');
      final avatar = _avatars[avatarIndex];
      // Create a new list with the existing voices plus the new one.
      final updatedVoices = [...avatar.voices, voice];
      // Create an updated avatar object with the new voices list.
      _avatars[avatarIndex] = avatar.copyWith(voices: updatedVoices);

      // Save the changes.
      await _saveAvatarsToStorage();
      notifyListeners(); // Update UI
      debugPrint('Voice added and avatars saved.');
    } else {
      debugPrint('Avatar $avatarId not found to add voice to.');
      throw Exception('Avatar not found to add voice.');
    }
  }

  /// Removes a specific voice from an avatar and deletes its audio file.
  Future<void> removeVoiceFromAvatar(String avatarId, String voiceId) async {
    final avatarIndex = _avatars.indexWhere((avatar) => avatar.id == avatarId);
    if (avatarIndex != -1) {
      debugPrint('Removing voice ID: $voiceId from avatar ID: $avatarId');
      final avatar = _avatars[avatarIndex];
      String? audioUrlToDelete;

      // Create a new list excluding the voice to be removed.
      final updatedVoices =
          avatar.voices.where((v) {
            if (v.id == voiceId) {
              audioUrlToDelete =
                  v.audioUrl; // Capture the URL before filtering out
              return false; // Exclude this voice
            }
            return true; // Keep this voice
          }).toList();

      // Only proceed if a voice was actually found and removed.
      if (audioUrlToDelete != null) {
        // Update the avatar in the list with the modified voice list.
      _avatars[avatarIndex] = avatar.copyWith(voices: updatedVoices);

        // Save the updated avatar list.
        await _saveAvatarsToStorage();
        notifyListeners(); // Update UI immediately
        debugPrint('Voice removed from avatar in memory and saved.');

        // Now, delete the associated audio file.
        try {
          debugPrint('Deleting audio file: $audioUrlToDelete');
          await _storageService.deleteAudioFile(audioUrlToDelete!);
          debugPrint('Audio file deleted successfully.');
        } catch (e) {
          // Log error but the main removal from the list is already done.
          debugPrint('Error deleting audio file $audioUrlToDelete: $e');
        }
      } else {
        debugPrint('Voice ID $voiceId not found within avatar $avatarId.');
      }
    } else {
      debugPrint('Avatar $avatarId not found to remove voice from.');
      throw Exception('Avatar not found to remove voice.');
    }
  }

  /// Removes ALL voices from a specific avatar and deletes their audio files.
  Future<void> removeAllVoicesFromAvatar(String avatarId) async {
    final avatarIndex = _avatars.indexWhere((avatar) => avatar.id == avatarId);
    if (avatarIndex != -1) {
      debugPrint('Removing ALL voices from avatar ID: $avatarId');
      final avatar = _avatars[avatarIndex];

      // Get the list of audio files to delete *before* clearing the list.
      final List<String> urlsToDelete =
          avatar.voices.map((v) => v.audioUrl).toList();

      // Update the avatar with an empty voice list.
      _avatars[avatarIndex] = avatar.copyWith(voices: []);

      // Save the change (avatar now has no voices).
      await _saveAvatarsToStorage();
      notifyListeners(); // Update UI quickly
      debugPrint('Cleared voices in memory for avatar $avatarId and saved.');

      // Delete all the associated audio files.
      debugPrint(
        'Deleting ${urlsToDelete.length} audio files for avatar $avatarId...',
      );
      int failedDeletions = 0;
      for (final url in urlsToDelete) {
        try {
          await _storageService.deleteAudioFile(url);
          await Future.delayed(const Duration(milliseconds: 20)); // Small delay
        } catch (e) {
          failedDeletions++;
          debugPrint('Error deleting audio file $url: $e');
        }
      }
      debugPrint(
        'Finished deleting audio files for avatar $avatarId. Failures: $failedDeletions',
      );
    } else {
      debugPrint('Avatar $avatarId not found to remove all voices from.');
      throw Exception('Avatar not found to remove all voices.');
    }
  }

  /// Reorders the voices within an avatar based on old and new indices.
  /// Used for drag-and-drop reordering in the UI.
  Future<void> reorderVoices(
    String avatarId,
    int oldIndex,
    int newIndex,
  ) async {
    final avatarIndex = _avatars.indexWhere((avatar) => avatar.id == avatarId);
    if (avatarIndex != -1) {
      final avatar = _avatars[avatarIndex];
      final voices = avatar.voices;

      // Basic bounds check
      if (oldIndex < 0 ||
          oldIndex >= voices.length ||
          newIndex < 0 ||
          newIndex > voices.length) {
        debugPrint(
          'Invalid indices for reordering: old=$oldIndex, new=$newIndex, length=${voices.length}',
        );
        return;
      }

      debugPrint(
        'Reordering voice in avatar $avatarId from index $oldIndex to $newIndex',
      );

      // Create a mutable copy of the list.
      final updatedVoices = List<Voice>.from(voices);

      // Adjust the newIndex if the item is moved downwards.
      // When removing an item, indices above it shift down by one.
      final actualNewIndex = (newIndex > oldIndex) ? newIndex - 1 : newIndex;

      // Remove the voice from its original position.
      final voiceToMove = updatedVoices.removeAt(oldIndex);
      // Insert the voice into the new position.
      updatedVoices.insert(actualNewIndex, voiceToMove);

      // Update the avatar with the reordered list.
      _avatars[avatarIndex] = avatar.copyWith(voices: updatedVoices);

      // Save the changes.
      await _saveAvatarsToStorage();
      notifyListeners(); // Update the UI
      debugPrint('Voice reordered successfully and saved.');
    } else {
      debugPrint('Avatar $avatarId not found for reordering voices.');
      throw Exception('Avatar not found for reordering voices.');
    }
  }

  /// Updates the display color associated with a specific voice.
  Future<void> updateVoiceColor(
    String avatarId,
    String voiceId,
    String? colorName,
  ) async {
    final avatarIndex = _avatars.indexWhere((avatar) => avatar.id == avatarId);
    if (avatarIndex != -1) {
      final avatar = _avatars[avatarIndex];
      final voiceIndex = avatar.voices.indexWhere(
        (voice) => voice.id == voiceId,
      );

      if (voiceIndex != -1) {
        debugPrint(
          'Updating color for voice $voiceId in avatar $avatarId to "$colorName"',
        );
        final voice = avatar.voices[voiceIndex];
        // Create an updated voice object with the new color.
        final updatedVoice = voice.copyWith(
          color: colorName,
        ); // Pass null to clear color

        // Create a new list with the updated voice replaced.
        final updatedVoices = List<Voice>.from(avatar.voices);
        updatedVoices[voiceIndex] = updatedVoice;

        // Update the avatar with the new list.
        _avatars[avatarIndex] = avatar.copyWith(voices: updatedVoices);

        // Save changes.
        await _saveAvatarsToStorage();
      notifyListeners();
        debugPrint('Voice color updated and saved.');
      } else {
        debugPrint(
          'Voice $voiceId not found in avatar $avatarId to update color.',
        );
      }
    } else {
      debugPrint('Avatar $avatarId not found to update voice color.');
      throw Exception('Avatar not found to update voice color.');
    }
  }

  // --- Voice Usage Tracking ---

  /// Increments the play count and updates the last played time for a specific voice.
  /// This usually doesn't need to notify listeners immediately unless the UI
  /// specifically displays play counts or sorts by recent plays dynamically.
  Future<void> trackVoiceUsage(String avatarId, String voiceId) async {
    final avatarIndex = _avatars.indexWhere((avatar) => avatar.id == avatarId);
    if (avatarIndex != -1) {
      final avatar = _avatars[avatarIndex];
      final voiceIndex = avatar.voices.indexWhere(
        (voice) => voice.id == voiceId,
      );

      if (voiceIndex != -1) {
        final voice = avatar.voices[voiceIndex];
        // Use the Voice model's helper method to get an updated instance.
        final updatedVoice = voice.incrementPlayCount();

        // Update the voice in the list.
        final updatedVoices = List<Voice>.from(avatar.voices);
        updatedVoices[voiceIndex] = updatedVoice;
        _avatars[avatarIndex] = avatar.copyWith(voices: updatedVoices);

        // Save the updated data.
        // We might debounce this save later if it causes performance issues.
        await _saveAvatarsToStorage();
        // Optional: Notify listeners if UI needs to react to play count changes.
        // notifyListeners();
        debugPrint(
          'Tracked usage for voice $voiceId. New count: ${updatedVoice.playCount}',
        );
      } else {
        debugPrint('Voice $voiceId not found for usage tracking.');
      }
    } else {
      debugPrint('Avatar $avatarId not found for usage tracking.');
    }
  }

  /// Gets a list of the most frequently played voices across all avatars.
  /// Returns a list of maps, each containing the `Avatar` and the `Voice`.
  List<Map<String, dynamic>> getMostUsedVoices({int limit = 10}) {
    List<Map<String, dynamic>> allVoicesWithPlays = [];

    // Collect all voices that have been played at least once.
    for (final avatar in _avatars) {
      for (final voice in avatar.voices) {
        if (voice.playCount > 0) {
          allVoicesWithPlays.add({'avatar': avatar, 'voice': voice});
        }
      }
    }

    // Sort the list by play count in descending order (most played first).
    allVoicesWithPlays.sort((a, b) {
      final voiceA = a['voice'] as Voice;
      final voiceB = b['voice'] as Voice;
      // Compare B to A for descending order.
      return voiceB.playCount.compareTo(voiceA.playCount);
    });

    // Return only the top `limit` voices.
    return allVoicesWithPlays.take(limit).toList();
  }

  /// Gets a list of the most recently played voices across all avatars.
  /// Returns a list of maps, each containing the `Avatar` and the `Voice`.
  List<Map<String, dynamic>> getRecentlyUsedVoices({int limit = 10}) {
    List<Map<String, dynamic>> recentVoices = [];

    // Collect all voices that have a last played timestamp.
    for (final avatar in _avatars) {
      for (final voice in avatar.voices) {
        if (voice.lastPlayed != null) {
          recentVoices.add({'avatar': avatar, 'voice': voice});
        }
      }
    }

    // Sort by the last played time, most recent first (descending order).
    recentVoices.sort((a, b) {
      final voiceA = a['voice'] as Voice;
      final voiceB = b['voice'] as Voice;
      // Use DateTime(0) as a fallback for safety, although `lastPlayed` should be non-null here.
      // Compare B to A for descending order.
      return (voiceB.lastPlayed ?? DateTime(0)).compareTo(
        voiceA.lastPlayed ?? DateTime(0),
      );
    });

    // Return the top `limit` most recent voices.
    return recentVoices.take(limit).toList();
  }

  // --- Utility & Maintenance ---

  /// Saves a raw audio file (bytes) using the `StorageService` and returns the path.
  /// This is typically used when importing or recording new audio.
  Future<String> saveAudioFile(String fileName, List<int> bytes) async {
    debugPrint('Saving audio file: $fileName');
    try {
      final path = await _storageService.saveAudioFile(fileName, bytes);
      debugPrint('Audio file saved to: $path');
      return path;
    } catch (e) {
      debugPrint('Error saving audio file $fileName: $e');
      rethrow; // Let the caller handle the error (e.g., show message to user)
    }
  }

  /// Forces a reload of avatar data from storage.
  /// Useful if the data might have been changed externally or to recover from errors.
  Future<void> reloadAvatars() async {
    debugPrint('Force reloading avatars from storage...');
    await _loadAvatarsFromStorage();
  }

  /// Deletes ALL avatars, voices, and associated audio files.
  /// USE WITH EXTREME CAUTION! 💣
  Future<void> deleteAllAvatars() async {
    if (_isDeletingAvatar) {
      debugPrint('Deletion already in progress, skipping deleteAllAvatars.');
      return;
    }

    debugPrint('[AvatarProvider] Starting deleteAllAvatars...');
    _isDeletingAvatar = true;
    notifyListeners(); // Indicate global deletion is starting

    try {
      // --- Step 1: Get list of files to delete --- (Before clearing memory)
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

      // --- Step 2: Clear in-memory state --- (Fast UI update)
      _avatars.clear();
      _selectedAvatar = null;
      debugPrint('[AvatarProvider] Cleared in-memory avatar list.');

      // --- Step 3: Save the empty list to storage --- (Persist the clearing)
      debugPrint('[AvatarProvider] Saving empty avatars list to storage...');
      try {
        await _saveAvatarsToStorage();
        debugPrint('[AvatarProvider] Successfully saved empty avatars list');
      } catch (storageError) {
        // Log error, but proceed with file deletion anyway.
        // The data is already gone from memory.
        debugPrint(
          '[AvatarProvider] Error saving empty avatars list: $storageError. Proceeding with file deletion.',
        );
        // We should still notify about the memory clear
        notifyListeners();
      }

      // Notify UI *after* saving the empty list (or attempting to)
      notifyListeners();

      // --- Step 4: Delete audio files --- (Slow part - Background)
      debugPrint(
        '[AvatarProvider] Starting background deletion of audio files...',
      );
      int deletedCount = 0;
      int errorCount = 0;
      for (final audioUrl in audioFilesToDelete) {
        try {
          final result = await _storageService.deleteAudioFile(audioUrl);
          if (result)
            deletedCount++;
          else
            errorCount++;
          // Small delay
          await Future.delayed(const Duration(milliseconds: 20));
        } catch (e) {
          errorCount++;
          debugPrint(
            '[AvatarProvider] Error deleting audio file: $audioUrl, error: $e',
          );
        }
      }
      debugPrint(
        '[AvatarProvider] Deleted $deletedCount audio files with $errorCount errors',
      );

      // --- Step 5: Clear any other related data (optional) ---
      // If StorageService has other related data, clear it too.
      // For now, assume clearAllData is sufficient if needed, but it might be too broad.
      // await _storageService.clearUsageStats(); // Example if stats were separate

      debugPrint('[AvatarProvider] deleteAllAvatars process completed.');
    } catch (e) {
      // Catch any unexpected errors during the overall process.
      _errorMessage =
          'An error occurred while deleting all avatars: ${e.toString()}';
      debugPrint('[AvatarProvider] Error during deleteAllAvatars: $e');
      // Attempt to reload to get back to a known state (likely empty if save worked).
      await reloadAvatars();
      rethrow;
    } finally {
      // --- Step 6: Final Cleanup --- (Always runs)
      _isDeletingAvatar = false;
      notifyListeners(); // Ensure UI reflects the final state
      debugPrint(
        '[AvatarProvider] Reset deleting flag and notified listeners after deleteAllAvatars.',
      );
    }
  }

  /// DEPRECATED? This seems redundant if deleteAllAvatars clears storage.
  /// If needed, it should likely call a specific method in StorageService.
  /// Clears *everything* via the storage service. Might be too aggressive.
  @Deprecated(
    'Use deleteAllAvatars for clearing avatar data. This might clear unrelated prefs.',
  )
  Future<void> clearAllData() async {
    debugPrint(
      'WARNING: Calling clearAllData - this will wipe ALL app preferences and stored files!',
    );
    await _storageService
        .clearAllData(); // This likely clears SharedPreferences too.
    _avatars.clear();
    _selectedAvatar = null;
    _isLoading = false; // Reset loading state
    _errorMessage = null;
    notifyListeners();
    debugPrint('All data cleared via StorageService.clearAllData()');
  }
}
