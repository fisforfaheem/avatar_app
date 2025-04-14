import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // For saving the theme choice locally

/// Manages the application's theme (light/dark mode).
///
/// This class handles:
/// 1. Keeping track of the current theme mode (light, dark, or system).
/// 2. Loading the user's preferred theme from device storage when the app starts.
/// 3. Saving the user's theme choice to device storage.
/// 4. Providing a way to toggle or set the theme.
/// 5. Notifying listeners (like the `MaterialApp`) when the theme changes so the UI updates.
///
/// It uses `ChangeNotifier` so that widgets can listen for theme changes and rebuild.
class ThemeProvider with ChangeNotifier {
  // The key we use to store the theme setting in SharedPreferences.
  // Like a label for the saved data.
  static const String _themeKey = 'theme_mode';

  // The internal variable holding the current theme mode.
  // We start with light mode by default, but this gets updated from storage.
  ThemeMode _themeMode = ThemeMode.light;

  // Public getter to access the current theme mode from outside the class.
  // Widgets will use this to know which theme to apply.
  ThemeMode get themeMode => _themeMode;

  // A handy little getter to quickly check if dark mode is currently active.
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  // Constructor: When a ThemeProvider is created, it immediately tries
  // to load the previously saved theme preference.
  ThemeProvider() {
    _loadThemeFromPrefs();
  }

  // --- Theme Persistence (Loading & Saving) ---

  /// Loads the saved theme preference from SharedPreferences.
  /// This runs when the provider is initialized.
  Future<void> _loadThemeFromPrefs() async {
    try {
      // Get the SharedPreferences instance (like opening the storage box).
      final prefs = await SharedPreferences.getInstance();
      // Read the string value associated with our theme key.
      final savedTheme = prefs.getString(_themeKey);

      // If we found a saved theme...
      if (savedTheme != null) {
        // Convert the saved string back into a ThemeMode enum.
        _themeMode = _getThemeModeFromString(savedTheme);
        // Tell everyone who's listening that the theme might have changed!
        notifyListeners();
      }
      // If `savedTheme` is null, we just keep the default `_themeMode`.
    } catch (e) {
      // Oops, something went wrong reading from storage.
      // Log the error for debugging, but don't crash the app.
      debugPrint('Error loading theme from SharedPreferences: $e 🤷‍♀️');
    }
  }

  /// Saves the given theme mode to SharedPreferences.
  /// This is called whenever the theme is changed by the user.
  Future<void> _saveThemeToPrefs(ThemeMode mode) async {
    try {
      // Get the SharedPreferences instance.
      final prefs = await SharedPreferences.getInstance();
      // Save the theme mode as a string (e.g., "ThemeMode.dark").
      await prefs.setString(_themeKey, mode.toString());
    } catch (e) {
      // Uh oh, couldn't save the theme.
      // Log for debugging.
      debugPrint('Error saving theme to SharedPreferences: $e 💾❌');
    }
  }

  /// Helper function to convert the string stored in SharedPreferences
  /// back into a proper `ThemeMode` enum value.
  ThemeMode _getThemeModeFromString(String themeString) {
    switch (themeString) {
      case 'ThemeMode.dark':
        return ThemeMode.dark;
      case 'ThemeMode.light':
        return ThemeMode.light;
      // If the saved string is something unexpected, default to system theme.
      default:
        return ThemeMode.system;
    }
  }

  // --- Public Methods for Changing Theme ---

  /// Toggles the theme between light and dark mode.
  /// If it's light, switch to dark. If it's dark, switch to light.
  Future<void> toggleTheme() async {
    // Determine the new mode.
    _themeMode =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    // Save the new choice.
    await _saveThemeToPrefs(_themeMode);
    // Notify listeners to update the UI.
    notifyListeners();
  }

  /// Allows setting the theme to a specific mode (light, dark, or system).
  Future<void> setThemeMode(ThemeMode mode) async {
    // If the requested mode is already the current mode, do nothing.
    // Avoids unnecessary saves and notifications.
    if (_themeMode == mode) return;

    // Update the internal state.
    _themeMode = mode;
    // Save the new choice.
    await _saveThemeToPrefs(mode);
    // Notify listeners.
    notifyListeners();
  }
}
