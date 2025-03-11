import 'package:flutter/material.dart';

class AppTheme {
  // Light theme colors
  static final ColorScheme _lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: const Color(0xFF007AFF), // iOS blue
    onPrimary: Colors.white,
    secondary: const Color(0xFF5856D6), // iOS purple
    onSecondary: Colors.white,
    error: const Color(0xFFFF3B30), // iOS red
    onError: Colors.white,
    surface: Colors.white,
    onSurface: Colors.black87,
    surfaceContainerHighest: const Color(
      0xFFF2F2F7,
    ), // iOS light gray background
    onSurfaceVariant: Colors.black54,
    outline: Colors.black12,
    shadow: Colors.black.withOpacity(0.1),
    inverseSurface: const Color(0xFF1C1C1E), // iOS dark gray
    onInverseSurface: Colors.white,
    inversePrimary: const Color(0xFF0A84FF), // iOS blue (dark mode)
  );

  // Dark theme colors - enhanced for a more professional and cool look
  static final ColorScheme _darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: const Color(0xFF0A84FF), // iOS blue (dark mode)
    onPrimary: Colors.white,
    secondary: const Color(0xFF5E5CE6), // iOS purple (dark mode)
    onSecondary: Colors.white,
    error: const Color(0xFFFF453A), // iOS red (dark mode)
    onError: Colors.white,
    surface: const Color(0xFF2C2C2E), // iOS dark surface
    onSurface: Colors.white,
    surfaceContainerHighest: const Color(
      0xFF3A3A3C,
    ), // iOS dark gray (secondary)
    onSurfaceVariant: Colors.white70,
    outline: Colors.white24,
    shadow: Colors.black.withOpacity(0.3),
    inverseSurface: Colors.white,
    onInverseSurface: Colors.black,
    inversePrimary: const Color(0xFF007AFF), // iOS blue (light mode)
  );

  // Light theme
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: _lightColorScheme,
    scaffoldBackgroundColor: _lightColorScheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: _lightColorScheme.onSurface,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        fontSize: 18,
        color: _lightColorScheme.onSurface,
      ),
    ),
    cardTheme: CardTheme(
      color: _lightColorScheme.surface,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _lightColorScheme.primary,
        foregroundColor: _lightColorScheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: _lightColorScheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    iconTheme: IconThemeData(color: _lightColorScheme.onSurface),
    textTheme: TextTheme(
      titleLarge: TextStyle(
        fontWeight: FontWeight.w300,
        fontSize: 28,
        color: _lightColorScheme.onSurface,
      ),
      titleMedium: TextStyle(
        fontWeight: FontWeight.w500,
        fontSize: 22,
        color: _lightColorScheme.onSurface,
      ),
      titleSmall: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 16,
        color: _lightColorScheme.onSurface,
      ),
      bodyLarge: TextStyle(fontSize: 16, color: _lightColorScheme.onSurface),
      bodyMedium: TextStyle(fontSize: 14, color: _lightColorScheme.onSurface),
      bodySmall: TextStyle(
        fontSize: 12,
        color: _lightColorScheme.onSurface.withOpacity(0.7),
      ),
    ),
  );

  // Dark theme - enhanced for a more professional and cool look
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: _darkColorScheme,
    scaffoldBackgroundColor: _darkColorScheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: _darkColorScheme.onSurface,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        fontSize: 18,
        color: _darkColorScheme.onSurface,
      ),
    ),
    cardTheme: CardTheme(
      color: _darkColorScheme.surface,
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: _darkColorScheme.outline, width: 0.5),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _darkColorScheme.primary,
        foregroundColor: _darkColorScheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        elevation: 4,
        shadowColor: _darkColorScheme.primary.withOpacity(0.5),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: _darkColorScheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: _darkColorScheme.primary,
        foregroundColor: _darkColorScheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        elevation: 2,
      ),
    ),
    iconTheme: IconThemeData(color: _darkColorScheme.onSurface),
    textTheme: TextTheme(
      titleLarge: TextStyle(
        fontWeight: FontWeight.w300,
        fontSize: 28,
        color: _darkColorScheme.onSurface,
      ),
      titleMedium: TextStyle(
        fontWeight: FontWeight.w500,
        fontSize: 22,
        color: _darkColorScheme.onSurface,
      ),
      titleSmall: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 16,
        color: _darkColorScheme.onSurface,
      ),
      bodyLarge: TextStyle(fontSize: 16, color: _darkColorScheme.onSurface),
      bodyMedium: TextStyle(fontSize: 14, color: _darkColorScheme.onSurface),
      bodySmall: TextStyle(
        fontSize: 12,
        color: _darkColorScheme.onSurface.withOpacity(0.7),
      ),
    ),
    // Dark mode specific overrides
    popupMenuTheme: PopupMenuThemeData(
      color: _darkColorScheme.surfaceContainerHighest,
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: _darkColorScheme.outline, width: 0.5),
      ),
    ),
    dialogTheme: DialogTheme(
      backgroundColor: _darkColorScheme.surface,
      elevation: 16,
      shadowColor: Colors.black.withOpacity(0.6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: _darkColorScheme.outline, width: 0.5),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: _darkColorScheme.surface,
      modalBackgroundColor: _darkColorScheme.surface,
      elevation: 16,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: _darkColorScheme.outline,
      thickness: 0.5,
    ),
    inputDecorationTheme: InputDecorationTheme(
      fillColor: _darkColorScheme.surfaceContainerHighest,
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _darkColorScheme.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _darkColorScheme.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _darkColorScheme.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    listTileTheme: ListTileThemeData(
      tileColor: _darkColorScheme.surface,
      selectedTileColor: _darkColorScheme.surfaceContainerHighest,
      iconColor: _darkColorScheme.primary,
      textColor: _darkColorScheme.onSurface,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return _darkColorScheme.primary;
        }
        return _darkColorScheme.onSurfaceVariant;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return _darkColorScheme.primary.withOpacity(0.5);
        }
        return _darkColorScheme.surfaceContainerHighest;
      }),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return _darkColorScheme.primary;
        }
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(_darkColorScheme.onPrimary),
      side: BorderSide(color: _darkColorScheme.onSurfaceVariant),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return _darkColorScheme.primary;
        }
        return _darkColorScheme.onSurfaceVariant;
      }),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: _darkColorScheme.inverseSurface,
      contentTextStyle: TextStyle(color: _darkColorScheme.onInverseSurface),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
