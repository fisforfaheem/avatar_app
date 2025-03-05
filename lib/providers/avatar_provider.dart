import 'package:flutter/foundation.dart';
import '../models/avatar.dart';

class AvatarProvider with ChangeNotifier {
  final List<Avatar> _avatars = [];
  Avatar? _selectedAvatar;

  List<Avatar> get avatars => List.unmodifiable(_avatars);
  Avatar? get selectedAvatar => _selectedAvatar;

  void addAvatar(String name) {
    final avatar = Avatar(name: name);
    _avatars.add(avatar);
    notifyListeners();
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
