import 'package:flutter/material.dart';
import 'package:syriapharmacy/core/animations/app_animations.dart';
import 'package:syriapharmacy/theme/custom_theme_colors.dart';

// Direction B (approved design): brand violet/blue replace the legacy blue pair.
Color _primaryColor = BrandColors.primary;
Color _secondaryColor = BrandColors.blue;
Color _tertiaryColor = const Color(0xFFBFE3D1);

ThemeData dark({Color? primaryColor, Color? secondaryColor}) => ThemeData(
  fontFamily: 'IBM_Plex_Sans_Arabic',
  primaryColor: _primaryColor,
  brightness: Brightness.dark,
  // Direction B dark: the night surfaces keep the brand ink's violet cast
  // instead of neutral grey.
  highlightColor: const Color(0xFF0E2A20),
  hintColor: const Color(0xFFA9BDB4),
  cardColor: const Color(0xFF0A1F17),
  scaffoldBackgroundColor: BrandColors.ink,
  splashColor: Colors.transparent,
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Color(0xFFE9EEF4)), // Text color primary
    bodyMedium: TextStyle(color: Color(0xFFE9EEF4)), // Text color Secondary
    bodySmall: TextStyle(color: Color(0xFFE9EEF4)), // Text color Light grey
  ),
  colorScheme: ColorScheme.dark(
    primary: _primaryColor, // Primary Color
    secondary: _secondaryColor, // Secondary Color
    tertiary: _tertiaryColor, // Warning Color
    tertiaryContainer: const Color(0xFF6C7A8E),
    surface: const Color(0xFF0F2B21),
    onPrimary: const Color(0xFFCFE6DA),
    onTertiaryContainer: const Color(0xFF04BB7B), // Success Color
    primaryContainer: const Color(0xFF208458),
    onSecondaryContainer: const Color(0x912A2A2A),
    outline: BrandColors.blue, // Info Color
    onTertiary: const Color(0xFF545252),
    secondaryContainer: const Color(0xFFE9EEF4),
    onSecondary: BrandColors.magenta,
    surfaceContainer: const Color(0xFFFB6C4C),
    error: const Color(0xFFFF4040), // Danger Color
    shadow: const Color(0xFFF4F7FC),
  ),
  pageTransitionsTheme: const PageTransitionsTheme(builders: {
    TargetPlatform.android: PremiumPageTransitionsBuilder(),
    TargetPlatform.iOS: PremiumPageTransitionsBuilder(),
    TargetPlatform.fuchsia: PremiumPageTransitionsBuilder(),
    TargetPlatform.macOS: PremiumPageTransitionsBuilder(),
    TargetPlatform.windows: PremiumPageTransitionsBuilder(),
    TargetPlatform.linux: PremiumPageTransitionsBuilder(),
  }),
);
