import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  // Theme mode key for shared preferences
  static const String _themeKey = 'theme_mode';

  // Default to system theme
  ThemeMode _themeMode = ThemeMode.light;

  // Getter for current theme mode
  ThemeMode get themeMode => _themeMode;

  // Check if dark mode is active
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  // Constructor loads saved theme
  ThemeProvider() {
    _loadThemeFromPrefs();
  }

  // Load theme from shared preferences
  Future<void> _loadThemeFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString(_themeKey);

      if (savedTheme != null) {
        _themeMode = _getThemeModeFromString(savedTheme);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading theme: $e');
    }
  }

  // Save theme to shared preferences
  Future<void> _saveThemeToPrefs(ThemeMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, mode.toString());
    } catch (e) {
      debugPrint('Error saving theme: $e');
    }
  }

  // Convert string to ThemeMode
  ThemeMode _getThemeModeFromString(String themeString) {
    switch (themeString) {
      case 'ThemeMode.dark':
        return ThemeMode.dark;
      case 'ThemeMode.light':
        return ThemeMode.light;
      default:
        return ThemeMode.system;
    }
  }

  // Toggle between light and dark mode
  Future<void> toggleTheme() async {
    _themeMode =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    await _saveThemeToPrefs(_themeMode);
    notifyListeners();
  }

  // Set specific theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;

    _themeMode = mode;
    await _saveThemeToPrefs(mode);
    notifyListeners();
  }
}
