import 'package:flutter/material.dart';

/// Defines the visual themes for the application (both light and dark mode).
///
/// This class centralizes all the color schemes, typography, and component styling
/// adhering to a clean, modern aesthetic, potentially inspired by Apple's HIG.
class AppTheme {
  // --- Light Theme Definition --- //

  // Defines the core color palette for the light theme.
  // Uses specific hex values for a consistent look, inspired by iOS defaults.
  static final ColorScheme _lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: const Color(
      0xFF007AFF,
    ), // Standard iOS blue - interactive elements
    onPrimary: Colors.white, // Text/icons on top of primary color
    secondary: const Color(
      0xFF5856D6,
    ), // Standard iOS purple - accents, secondary actions
    onSecondary: Colors.white, // Text/icons on top of secondary color
    error: const Color(
      0xFFFF3B30,
    ), // Standard iOS red - errors, destructive actions
    onError: Colors.white, // Text/icons on top of error color
    surface: Colors.white, // Background of cards, sheets, menus
    onSurface:
        Colors
            .black87, // Text/icons on top of surface color (slightly off-black)
    surfaceContainerHighest: const Color(
      0xFFF2F2F7,
    ), // Light gray background (like iOS grouped tables)
    onSurfaceVariant:
        Colors.black54, // Less prominent text/icons (placeholders, subtitles)
    outline: Colors.black12, // Borders, dividers (very subtle)
    shadow: Colors.black.withOpacity(0.1), // Subtle shadow for elevation
    inverseSurface: const Color(
      0xFF1C1C1E,
    ), // Roughly the dark mode surface color (for Snackbars, etc.)
    onInverseSurface: Colors.white, // Text on dark backgrounds (in light theme)
    inversePrimary: const Color(
      0xFF0A84FF,
    ), // Primary color shade used in dark mode
  );

  // --- Dark Theme Definition --- //

  // Defines the core color palette for the dark theme.
  // Aims for a professional, cool look with good contrast.
  static final ColorScheme _darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: const Color(0xFF0A84FF), // Brighter iOS blue for dark mode
    onPrimary: Colors.white,
    secondary: const Color(0xFF5E5CE6), // Brighter iOS purple for dark mode
    onSecondary: Colors.white,
    error: const Color(0xFFFF453A), // Brighter iOS red for dark mode
    onError: Colors.white,
    surface: const Color(
      0xFF1c1c1e,
    ), // Primary dark background (Cards, etc.) - Changed from 2C2C2E for deeper black
    onSurface: Colors.white.withOpacity(
      0.9,
    ), // Primary text/icons on dark background (slightly off-white)
    surfaceContainerHighest: const Color(
      0xFF2c2c2e,
    ), // Secondary dark background (e.g., text fields) - Changed from 3A3A3C
    onSurfaceVariant: Colors.white70, // Less prominent text/icons
    outline: Colors.white24, // Borders, dividers
    shadow: Colors.black.withOpacity(
      0.4,
    ), // More pronounced shadow for dark mode depth
    inverseSurface: Colors.white, // Light backgrounds (in dark theme)
    onInverseSurface: Colors.black,
    inversePrimary: const Color(
      0xFF007AFF,
    ), // Primary color shade used in light mode
  );

  // --- Light ThemeData --- //

  /// The fully configured ThemeData object for the light mode.
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true, // Enable Material 3 features and styling
    colorScheme: _lightColorScheme, // Apply the defined light color scheme
    scaffoldBackgroundColor: const Color(
      0xFFF2F2F7,
    ), // Use the light gray for main background - Changed from surface
    appBarTheme: AppBarTheme(
      backgroundColor:
          Colors.transparent, // Keep AppBar transparent for blending
      foregroundColor: _lightColorScheme.onSurface, // Text/icon color
      elevation: 0, // No shadow for a flatter look
      centerTitle: true, // Center align title
      titleTextStyle: TextStyle(
        fontWeight:
            FontWeight.w600, // Slightly bolder title - Changed from w700
        // letterSpacing: 0.5, // Removed for standard spacing
        fontSize: 17, // Standard iOS title size - Changed from 18
        color: _lightColorScheme.onSurface,
      ),
    ),
    cardTheme: CardTheme(
      color: _lightColorScheme.surface, // White card background
      elevation: 0, // Flat cards, use borders instead - Changed from 1
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          10,
        ), // Slightly less rounded - Changed from 12
        side: BorderSide(
          color: _lightColorScheme.outline,
          width: 0.5,
        ), // Subtle border
      ),
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 6,
      ), // Default card margins
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _lightColorScheme.primary, // Blue background
        foregroundColor: _lightColorScheme.onPrimary, // White text
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ), // Match card rounding
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 14,
        ), // Adjusted padding
        elevation: 1, // Minimal elevation
        textStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: _lightColorScheme.primary, // Blue text
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      // Added FilledButton styling
      style: FilledButton.styleFrom(
        backgroundColor: _lightColorScheme.primary,
        foregroundColor: _lightColorScheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        textStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
        elevation: 1,
      ),
    ),
    iconTheme: IconThemeData(
      color: _lightColorScheme.onSurfaceVariant,
    ), // Slightly muted icons - Changed from onSurface
    textTheme: TextTheme(
      // Define various text styles used throughout the app
      // Using weights and sizes common in iOS
      displayLarge: TextStyle(
        fontWeight: FontWeight.w300,
        fontSize: 34,
        color: _lightColorScheme.onSurface,
      ),
      displayMedium: TextStyle(
        fontWeight: FontWeight.w400,
        fontSize: 28,
        color: _lightColorScheme.onSurface,
      ),
      displaySmall: TextStyle(
        fontWeight: FontWeight.w400,
        fontSize: 22,
        color: _lightColorScheme.onSurface,
      ),
      headlineMedium: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 17,
        color: _lightColorScheme.onSurface,
      ), // Common headline
      headlineSmall: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 15,
        color: _lightColorScheme.onSurface,
      ),
      titleLarge: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 20,
        color: _lightColorScheme.onSurface,
      ), // Larger titles
      titleMedium: TextStyle(
        fontWeight: FontWeight.w500,
        fontSize: 17,
        color: _lightColorScheme.onSurface,
      ), // Default list tile title
      titleSmall: TextStyle(
        fontWeight: FontWeight.w500,
        fontSize: 15,
        color: _lightColorScheme.onSurfaceVariant,
      ), // Slightly smaller/muted title
      bodyLarge: TextStyle(
        fontSize: 17,
        color: _lightColorScheme.onSurface,
        fontWeight: FontWeight.w400,
      ), // Standard body text
      bodyMedium: TextStyle(
        fontSize: 15,
        color: _lightColorScheme.onSurface,
        fontWeight: FontWeight.w400,
      ), // Slightly smaller body
      bodySmall: TextStyle(
        fontSize: 13,
        color: _lightColorScheme.onSurfaceVariant,
      ), // Footnotes, captions
      labelLarge: TextStyle(
        fontSize: 17,
        color: _lightColorScheme.primary,
        fontWeight: FontWeight.w500,
      ), // Button text
    ),
    dividerTheme: DividerThemeData(
      color: _lightColorScheme.outline,
      thickness: 0.5,
    ),
    inputDecorationTheme: InputDecorationTheme(
      fillColor:
          _lightColorScheme
              .surface, // White background for fields - Changed from surfaceContainerHighest
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: _lightColorScheme.outline, width: 0.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: _lightColorScheme.outline, width: 0.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: _lightColorScheme.primary,
          width: 1.5,
        ), // Thicker focus border
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    listTileTheme: ListTileThemeData(
      tileColor:
          Colors.transparent, // Transparent tiles, rely on card background
      selectedTileColor: _lightColorScheme.primary.withOpacity(0.1),
      iconColor: _lightColorScheme.onSurfaceVariant,
      textColor: _lightColorScheme.onSurface,
      selectedColor: _lightColorScheme.primary,
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: _lightColorScheme.surface, // White background
      elevation: 4,
      shadowColor: _lightColorScheme.shadow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: _lightColorScheme.outline, width: 0.5),
      ),
    ),
    dialogTheme: DialogTheme(
      backgroundColor: _lightColorScheme.surface,
      elevation: 8,
      shadowColor: _lightColorScheme.shadow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          14,
        ), // Slightly larger rounding for dialogs
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor:
          _lightColorScheme.surfaceContainerHighest, // Light gray background
      modalBackgroundColor: _lightColorScheme.surfaceContainerHighest,
      elevation: 4,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return _lightColorScheme.onPrimary; // White thumb when on
        }
        return _lightColorScheme.onSurface.withOpacity(
          0.6,
        ); // Grayish thumb when off
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return _lightColorScheme.primary; // Blue track when on
        }
        return _lightColorScheme.outline; // Outline color track when off
      }),
      trackOutlineColor: WidgetStateProperty.all(
        Colors.transparent,
      ), // Remove M3 track outline
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return _lightColorScheme.primary;
        }
        return Colors.transparent; // Transparent background when off
      }),
      checkColor: WidgetStateProperty.all(_lightColorScheme.onPrimary),
      side: BorderSide(color: _lightColorScheme.outline, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return _lightColorScheme.primary;
        }
        return _lightColorScheme.onSurfaceVariant;
      }),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: _lightColorScheme.inverseSurface, // Dark background
      contentTextStyle: TextStyle(
        color: _lightColorScheme.onInverseSurface,
      ), // White text
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      behavior: SnackBarBehavior.floating,
      elevation: 4,
    ),
  );

  // --- Dark ThemeData --- //

  /// The fully configured ThemeData object for the dark mode.
  /// Enhanced with specific overrides for a polished dark appearance.
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: _darkColorScheme, // Apply the defined dark color scheme
    scaffoldBackgroundColor: const Color(
      0xFF000000,
    ), // Pure black background for OLED - Changed from surface
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent, // Keep AppBar transparent
      foregroundColor: _darkColorScheme.onSurface, // White-ish text/icons
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontWeight: FontWeight.w600, // Match light theme boldness
        fontSize: 17, // Match light theme size
        color: _darkColorScheme.onSurface,
      ),
    ),
    cardTheme: CardTheme(
      color: _darkColorScheme.surface, // Dark gray card background
      elevation: 0, // No elevation, use borders
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10), // Match light theme
        side: BorderSide(
          color: _darkColorScheme.outline,
          width: 0.5,
        ), // Subtle border
      ),
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 6,
      ), // Match light theme
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _darkColorScheme.primary, // Bright blue background
        foregroundColor: _darkColorScheme.onPrimary, // White text
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        elevation: 2, // Subtle elevation
        shadowColor: Colors.black.withOpacity(0.3),
        textStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: _darkColorScheme.primary, // Bright blue text
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: _darkColorScheme.primary,
        foregroundColor: _darkColorScheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        textStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
        elevation: 1,
      ),
    ),
    iconTheme: IconThemeData(
      color: _darkColorScheme.onSurfaceVariant,
    ), // Slightly muted icons - Changed from onSurface
    textTheme: TextTheme(
      // Define dark theme text styles, mirroring light theme structure
      displayLarge: TextStyle(
        fontWeight: FontWeight.w300,
        fontSize: 34,
        color: _darkColorScheme.onSurface,
      ),
      displayMedium: TextStyle(
        fontWeight: FontWeight.w400,
        fontSize: 28,
        color: _darkColorScheme.onSurface,
      ),
      displaySmall: TextStyle(
        fontWeight: FontWeight.w400,
        fontSize: 22,
        color: _darkColorScheme.onSurface,
      ),
      headlineMedium: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 17,
        color: _darkColorScheme.onSurface,
      ),
      headlineSmall: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 15,
        color: _darkColorScheme.onSurface,
      ),
      titleLarge: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 20,
        color: _darkColorScheme.onSurface,
      ),
      titleMedium: TextStyle(
        fontWeight: FontWeight.w500,
        fontSize: 17,
        color: _darkColorScheme.onSurface,
      ),
      titleSmall: TextStyle(
        fontWeight: FontWeight.w500,
        fontSize: 15,
        color: _darkColorScheme.onSurfaceVariant,
      ),
      bodyLarge: TextStyle(
        fontSize: 17,
        color: _darkColorScheme.onSurface,
        fontWeight: FontWeight.w400,
      ),
      bodyMedium: TextStyle(
        fontSize: 15,
        color: _darkColorScheme.onSurface,
        fontWeight: FontWeight.w400,
      ),
      bodySmall: TextStyle(
        fontSize: 13,
        color: _darkColorScheme.onSurfaceVariant,
      ),
      labelLarge: TextStyle(
        fontSize: 17,
        color: _darkColorScheme.primary,
        fontWeight: FontWeight.w500,
      ),
    ),
    dividerTheme: DividerThemeData(
      color: _darkColorScheme.outline,
      thickness: 0.5,
    ),
    inputDecorationTheme: InputDecorationTheme(
      fillColor:
          _darkColorScheme.surfaceContainerHighest, // Use secondary dark bg
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none, // No border by default
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none, // No border by default
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: _darkColorScheme.primary,
          width: 1.5,
        ), // Focus border
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    listTileTheme: ListTileThemeData(
      tileColor: Colors.transparent, // Transparent, rely on card background
      selectedTileColor: _darkColorScheme.primary.withOpacity(
        0.2,
      ), // More prominent selection
      iconColor: _darkColorScheme.onSurfaceVariant,
      textColor: _darkColorScheme.onSurface,
      selectedColor: _darkColorScheme.primary,
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: _darkColorScheme.surfaceContainerHighest, // Use secondary dark bg
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: _darkColorScheme.outline, width: 0.5),
      ),
    ),
    dialogTheme: DialogTheme(
      backgroundColor: _darkColorScheme.surface, // Dark gray background
      elevation: 16,
      shadowColor: Colors.black.withOpacity(0.6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14), // Match light theme
        side: BorderSide(color: _darkColorScheme.outline, width: 0.5),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: _darkColorScheme.surface, // Dark gray background
      modalBackgroundColor: _darkColorScheme.surface,
      elevation: 8,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return _darkColorScheme.onPrimary; // White thumb when on
        }
        return _darkColorScheme.onSurface.withOpacity(
          0.6,
        ); // Grayish thumb when off
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return _darkColorScheme.primary; // Blue track when on
        }
        return _darkColorScheme.outline.withOpacity(
          0.5,
        ); // Darker outline track when off
      }),
      trackOutlineColor: WidgetStateProperty.all(
        Colors.transparent,
      ), // Remove M3 track outline
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return _darkColorScheme.primary;
        }
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(_darkColorScheme.onPrimary),
      side: BorderSide(color: _darkColorScheme.onSurfaceVariant, width: 1.5),
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
      backgroundColor:
          _darkColorScheme.surfaceContainerHighest, // Use secondary dark bg
      contentTextStyle: TextStyle(
        color: _darkColorScheme.onSurface,
      ), // White-ish text
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      behavior: SnackBarBehavior.floating,
      elevation: 4,
    ),
  );
}
