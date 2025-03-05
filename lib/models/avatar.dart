import 'package:uuid/uuid.dart';

/// Represents a voice avatar with its associated voices and properties
class Avatar {
  final String id;
  final String name;
  final String color;
  final List<Voice> voices;

  Avatar({
    String? id,
    required this.name,
    String? color,
    List<Voice>? voices,
  })  : id = id ?? const Uuid().v4(),
        color = color ?? _getRandomColor(),
        voices = voices ?? [];

  /// Creates a copy of this Avatar with the given fields replaced with the new values
  Avatar copyWith({
    String? name,
    String? color,
    List<Voice>? voices,
  }) {
    return Avatar(
      id: id,
      name: name ?? this.name,
      color: color ?? this.color,
      voices: voices ?? this.voices,
    );
  }

  /// Generate a random color from a predefined set of colors
  static String _getRandomColor() {
    const colors = [
      'blue',
      'purple',
      'pink',
      'orange',
      'green',
      'teal',
    ];
    return colors[DateTime.now().microsecond % colors.length];
  }
}

/// Represents a voice recording associated with an avatar
class Voice {
  final String id;
  final String name;
  final String audioUrl;
  final Duration duration;
  final DateTime createdAt;

  Voice({
    String? id,
    required this.name,
    required this.audioUrl,
    Duration? duration,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        duration = duration ?? Duration.zero,
        createdAt = createdAt ?? DateTime.now();

  Voice copyWith({
    String? name,
    String? audioUrl,
    Duration? duration,
  }) {
    return Voice(
      id: id,
      name: name ?? this.name,
      audioUrl: audioUrl ?? this.audioUrl,
      duration: duration ?? this.duration,
      createdAt: createdAt,
    );
  }
}
