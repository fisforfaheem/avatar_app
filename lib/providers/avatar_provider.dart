import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/avatar.dart';

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

  List<Avatar> get avatars => List.unmodifiable(_avatars);
  Avatar? get selectedAvatar => _selectedAvatar;

  // Get the list of predefined avatar icons
  List<IconData> get predefinedIcons => predefinedAvatarIcons;

  // Get the list of predefined avatar colors
  List<String> get predefinedColors => predefinedAvatarColors;

  void addAvatar(String name, {IconData? icon, String? color}) {
    final avatar = Avatar(
      name: name,
      icon: icon,
      color: color,
    );
    _avatars.add(avatar);
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
      notifyListeners();
    }
  }

  void removeVoiceFromAvatar(String avatarId, String voiceId) {
    final avatarIndex = _avatars.indexWhere((avatar) => avatar.id == avatarId);
    if (avatarIndex != -1) {
      final avatar = _avatars[avatarIndex];
      final updatedVoices =
          avatar.voices.where((voice) => voice.id != voiceId).toList();
      _avatars[avatarIndex] = avatar.copyWith(voices: updatedVoices);
      notifyListeners();
    }
  }

  void removeAvatar(String id) {
    _avatars.removeWhere((avatar) => avatar.id == id);
    if (_selectedAvatar?.id == id) {
      _selectedAvatar = null;
    }
    notifyListeners();
  }
}
