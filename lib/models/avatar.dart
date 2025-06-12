import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart'; // Used for generating unique IDs
import 'dart:typed_data'; // Added for Uint8List

// --- Avatar Class --- //

/// Represents a collection of voice recordings, kind of like a character or profile.
/// Think of it as the main folder for a set of sounds! 📁
class Avatar {
  // Unique identifier for this avatar. Generated automatically if not provided.
  final String id;
  // The name you give this avatar (e.g., "Funny Robot", "Serious Narrator").
  final String name;
  // A color string (like 'blue', 'red') used for visual distinction in the UI.
  // Gets a random color if you don't specify one.
  final String color;
  // The list of actual voice recordings associated with this avatar.
  final List<Voice> voices;
  // The icon displayed for this avatar in the UI (e.g., a person icon).
  // Defaults to Icons.person if not set.
  final IconData icon;
  // Optional path to a custom image file to represent the avatar instead of an icon.
  final String? imagePath;

  // Constructor for creating a new Avatar instance.
  Avatar({
    String? id, // You can provide an ID, or we'll make one up.
    required this.name, // An avatar MUST have a name.
    String? color, // Optional color.
    List<Voice>? voices, // Optional list of starting voices.
    IconData? icon, // Optional icon.
    this.imagePath, // Optional custom image path.
  }) : id =
           id ??
           const Uuid().v4(), // If no ID is given, generate a unique v4 UUID.
       color =
           color ??
           _getRandomColor(), // If no color is given, pick a random one.
       voices =
           voices ?? [], // Start with an empty list if no voices are provided.
       icon =
           icon ??
           _getDefaultIcon(); // Use the default icon if none is specified.

  /// Creates a copy of this Avatar but allows you to change specific properties.
  /// Super useful for updating state immutably (without changing the original object).
  Avatar copyWith({
    String? name, // New name?
    String? color, // New color?
    List<Voice>? voices, // New list of voices?
    IconData? icon, // New icon?
    String? imagePath, // New image path?
  }) {
    return Avatar(
      id: id, // Keep the original ID.
      name:
          name ??
          this.name, // Use new name if provided, otherwise keep the old one.
      color: color ?? this.color, // Use new color if provided, etc.
      voices: voices ?? this.voices,
      icon: icon ?? this.icon,
      imagePath: imagePath ?? this.imagePath,
    );
  }

  /// Helper method to pick a random color from our predefined palette.
  /// Keeps things visually interesting! 🎨
  static String _getRandomColor() {
    // A nice selection of color names.
    const colors = [
      // Green Palette
      'green', 'light_green', 'forest_green',
      // Orange/Yellow Palette
      'orange', 'amber', 'warm_orange', 'sand',
      // Blue Palette
      'blue', 'teal', 'cyan', 'sky_blue', 'light_blue',
      // Red/Pink Palette
      'red', 'pink', 'coral', 'rose',
      // Purple/Indigo Palette
      'purple', 'indigo', 'deep_purple',
    ];
    // Pick a color based on the current microsecond - simple randomness!
    return colors[DateTime.now().microsecond % colors.length];
  }

  /// Helper method to get the default icon.
  /// Just a simple person icon for now. 🧑
  static IconData _getDefaultIcon() {
    return Icons.person;
  }
}

// --- Voice Class --- //

/// Represents a single voice recording file and its metadata.
/// This is the actual sound bite! 🔊
class Voice {
  // Unique identifier for this specific voice recording.
  final String id;
  // The name of the voice recording (e.g., "Greeting", "Laugh Track").
  final String name;
  // The path or URL where the audio file is stored.
  final String audioUrl;
  // The raw audio data, primarily used for web uploads before saving.
  final Uint8List? audioBytes;
  // How long the audio recording is.
  final Duration duration;
  // When this voice recording was added/created.
  final DateTime createdAt;
  // A category for organization (e.g., "Greetings", "Sound Effects").
  final String category;
  // How many times this voice has been played. Popularity contest! 🏆
  final int playCount;
  // When this voice was last played (if ever).
  final DateTime? lastPlayed;
  // Optional color specifically for this voice item in the UI.
  final String? color;

  // Constructor for creating a new Voice instance.
  Voice({
    String? id, // Optional ID, will be generated if missing.
    required this.name, // A voice MUST have a name.
    required this.audioUrl, // A voice MUST have an audio source.
    this.audioBytes, // Not required, used for uploads.
    Duration? duration, // Optional duration (defaults to zero).
    DateTime? createdAt, // Optional creation time (defaults to now).
    this.category = 'Uncategorized', // Default category if none provided.
    this.playCount = 0, // Starts with zero plays.
    this.lastPlayed, // Starts as null (never played).
    this.color, // Optional color for this specific voice.
  }) : id = id ?? const Uuid().v4(), // Generate unique ID if needed.
       duration = duration ?? Duration.zero, // Default to zero duration.
       createdAt = createdAt ?? DateTime.now(); // Default to current time.

  /// Creates a copy of this Voice with updated properties.
  /// Again, great for immutable state updates.
  Voice copyWith({
    String? name, // New name?
    String? audioUrl, // New audio source?
    Uint8List? audioBytes, // New audio bytes?
    Duration? duration, // New duration?
    String? category, // New category?
    int? playCount, // New play count?
    DateTime? lastPlayed, // New last played time?
    String? color, // New color?
  }) {
    return Voice(
      id: id, // Keep the original ID.
      name: name ?? this.name, // Use new if provided, else old.
      audioUrl: audioUrl ?? this.audioUrl,
      audioBytes: audioBytes ?? this.audioBytes,
      duration: duration ?? this.duration,
      createdAt: createdAt, // Keep original creation time.
      category: category ?? this.category,
      playCount: playCount ?? this.playCount,
      lastPlayed: lastPlayed ?? this.lastPlayed,
      color: color ?? this.color,
    );
  }

  /// Creates a *new* Voice instance with the play count increased by one
  /// and the `lastPlayed` time updated to now.
  Voice incrementPlayCount() {
    return copyWith(
      playCount: playCount + 1, // Bump the count!
      lastPlayed: DateTime.now(), // Mark it as played right now.
    );
  }
}
