import 'package:flutter/material.dart';

/// The approved brand palette (Direction B — Dynamic Marketplace).
///
/// Single source for the guideline colours so a widget never re-types a hex.
/// Server-published theme tokens (ThemeStyle) still win inside App Builder
/// sections; these are the app-side fallback and the chrome palette.
class BrandColors {
  BrandColors._();

  static const Color primary = Color(0xFF063523);
  static const Color blue = Color(0xFF1F7A55);
  static const Color magenta = Color(0xFF0B5A3A);
  static const Color ink = Color(0xFF04170F);
  static const Color inkSoft = Color(0xFF0F2E22);
  static const Color surface = Color(0xFFF4F8F6);
  static const Color surfaceDeep = Color(0xFFE6F0EB);
  static const Color mutedText = Color(0xFF7A8B83);
  static const Color star = Color(0xFFF5A623);
  static const Color hairline = Color(0x1704170F); // rgba(20,8,46,.09)
}

/// The three approved gradients from the brand guidelines.
class BrandGradients {
  BrandGradients._();

  /// Primary 140°: violet → blue. Headers, primary buttons, «أضف».
  static const LinearGradient primary = LinearGradient(
    begin: Alignment(-0.64, -0.77),
    end: Alignment(0.64, 0.77),
    colors: [BrandColors.primary, BrandColors.blue],
  );

  /// Flash strip: blue → magenta. Flash-deal sections and urgency accents.
  static const LinearGradient flash = LinearGradient(
    begin: AlignmentDirectional.centerStart,
    end: AlignmentDirectional.centerEnd,
    colors: [BrandColors.blue, BrandColors.magenta],
  );

  /// Dark cover 155°: deep violet campaign background.
  static const LinearGradient campaign = LinearGradient(
    begin: Alignment(-0.42, -0.91),
    end: Alignment(0.42, 0.91),
    colors: [Color(0xFF0D5A3C), Color(0xFF0B4A31), Color(0xFF08402B)],
    stops: [0.0, 0.45, 0.85],
  );
}
