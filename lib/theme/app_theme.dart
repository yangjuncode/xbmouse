/// XBMouse application theme.
/// Dark gaming-inspired theme with Xbox green accents.

import 'package:flutter/material.dart';

class AppTheme {
  // Xbox-inspired color palette
  static const Color xboxGreen = Color(0xFF107C10);
  static const Color xboxLightGreen = Color(0xFF2ECC40);
  static const Color surfaceDark = Color(0xFF1A1A2E);
  static const Color surfaceCard = Color(0xFF16213E);
  static const Color surfaceElevated = Color(0xFF1E2D4A);
  static const Color textPrimary = Color(0xFFE8E8E8);
  static const Color textSecondary = Color(0xFF8B8FA3);
  static const Color accentOrange = Color(0xFFE94560);
  static const Color accentBlue = Color(0xFF0F3460);

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: xboxGreen,
      secondary: xboxLightGreen,
      surface: surfaceDark,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: textPrimary,
      error: accentOrange,
    ),
    scaffoldBackgroundColor: const Color(0xFF0A0A1A),
    appBarTheme: const AppBarTheme(
      backgroundColor: surfaceDark,
      foregroundColor: textPrimary,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: surfaceCard,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return xboxGreen;
        }
        return Colors.grey;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return xboxGreen.withValues(alpha: 0.5);
        }
        return Colors.grey.withValues(alpha: 0.3);
      }),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: xboxGreen,
      thumbColor: xboxLightGreen,
      inactiveTrackColor: Colors.grey.withValues(alpha: 0.3),
      overlayColor: xboxGreen.withValues(alpha: 0.2),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: xboxGreen,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: xboxGreen,
        side: const BorderSide(color: xboxGreen),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceElevated,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: xboxGreen, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    dividerColor: Colors.white.withValues(alpha: 0.1),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: surfaceDark,
      selectedIconTheme: const IconThemeData(color: xboxGreen),
      unselectedIconTheme: IconThemeData(color: textSecondary),
      selectedLabelTextStyle: const TextStyle(color: xboxGreen, fontWeight: FontWeight.w600),
      unselectedLabelTextStyle: TextStyle(color: textSecondary),
    ),
  );
}
