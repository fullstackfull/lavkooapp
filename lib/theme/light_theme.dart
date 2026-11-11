import 'package:flutter/material.dart';
import 'package:syriapharmacy/core/animations/app_animations.dart';
import 'package:syriapharmacy/theme/custom_theme_colors.dart';

// Direction B (approved design): the light theme commits to the brand palette,
// so the guideline colours hold even when the server config carries the legacy blue.
ThemeData light({Color? primaryColor, Color? secondaryColor}) => ThemeData(
      fontFamily: 'IBM_Plex_Sans_Arabic',
      primaryColor: BrandColors.primary,
      brightness: Brightness.light,
      highlightColor: Colors.white,
      hintColor: BrandColors.mutedText, //Border Color
      splashColor: Colors.transparent,
      cardColor: Colors.white,

      scaffoldBackgroundColor: Colors.white,

      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: BrandColors.ink), // Text color primary
        bodyMedium: TextStyle(color: BrandColors.primary), // Text color Secondary
        bodySmall: TextStyle(color: BrandColors.mutedText), // Text color Light grey

        titleMedium: TextStyle(color: BrandColors.inkSoft),
      ),

      colorScheme: const ColorScheme.light(
        primary: BrandColors.primary, // Primary Color
        secondary: BrandColors.blue, // Secondary Color
        tertiary: BrandColors.surfaceDeep, // Warning Color
        tertiaryContainer: Color(0xFFD6E3FF),
        onTertiaryContainer: Color(0xFF04BB7B), // Success Color
        onPrimary: Color(0xFFEDF1FF),
        surface: BrandColors.surface,
        onSecondary: BrandColors.magenta,
        error: Color(0xFFFF4040), // Danger Color
        onSecondaryContainer: BrandColors.surface,
        outline: BrandColors.blue, // Info Color
        onTertiary: BrandColors.surfaceDeep,
        shadow: Color(0xFF66717C),

        primaryContainer: Color(0xFF9AECC6),
        secondaryContainer: Color(0xFFE9EEF4),
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
