import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

/// Represents a voice avatar with its associated voices and properties
class Avatar {
  final String id;
  final String name;
  final String color;
  final List<Voice> voices;
  final IconData icon;

  Avatar({
    String? id,
    required this.name,
    String? color,
    List<Voice>? voices,
    IconData? icon,
  }) : id = id ?? const Uuid().v4(),
       color = color ?? _getRandomColor(),
       voices = voices ?? [],
       icon = icon ?? _getDefaultIcon();

  /// Creates a copy of this Avatar with the given fields replaced with the new values
  Avatar copyWith({
    String? name,
    String? color,
    List<Voice>? voices,
    IconData? icon,
  }) {
    return Avatar(
      id: id,
      name: name ?? this.name,
      color: color ?? this.color,
      voices: voices ?? this.voices,
      icon: icon ?? this.icon,
    );
  }

  /// Generate a random color from a predefined set of colors
  static String _getRandomColor() {
    const colors = [
      // Green Palette
      'green',
      'light_green',
      'forest_green',

      // Orange/Yellow Palette
      'orange',
      'amber',
      'warm_orange',
      'sand',

      // Blue Palette
      'blue',
      'teal',
      'cyan',
      'sky_blue',
      'light_blue',

      // Red/Pink Palette
      'red',
      'pink',
      'coral',
      'rose',

      // Purple/Indigo Palette
      'purple',
      'indigo',
      'deep_purple',
    ];
    return colors[DateTime.now().microsecond % colors.length];
  }

  /// Get a default icon for the avatar
  static IconData _getDefaultIcon() {
    return Icons.person;
  }
}

/// Represents a voice recording associated with an avatar
class Voice {
  final String id;
  final String name;
  final String audioUrl;
  final Duration duration;
  final DateTime createdAt;
  final String category;
  final int playCount;
  final DateTime? lastPlayed;
  final String? color; // Color of the voice item

  Voice({
    String? id,
    required this.name,
    required this.audioUrl,
    Duration? duration,
    DateTime? createdAt,
    this.category = 'Uncategorized',
    this.playCount = 0,
    this.lastPlayed,
    this.color,
  }) : id = id ?? const Uuid().v4(),
       duration = duration ?? Duration.zero,
       createdAt = createdAt ?? DateTime.now();

  Voice copyWith({
    String? name,
    String? audioUrl,
    Duration? duration,
    String? category,
    int? playCount,
    DateTime? lastPlayed,
    String? color,
  }) {
    return Voice(
      id: id,
      name: name ?? this.name,
      audioUrl: audioUrl ?? this.audioUrl,
      duration: duration ?? this.duration,
      createdAt: createdAt,
      category: category ?? this.category,
      playCount: playCount ?? this.playCount,
      lastPlayed: lastPlayed ?? this.lastPlayed,
      color: color ?? this.color,
    );
  }

  Voice incrementPlayCount() {
    return copyWith(playCount: playCount + 1, lastPlayed: DateTime.now());
  }
}
