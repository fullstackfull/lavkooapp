import 'package:flutter/material.dart';
import 'package:syriapharmacy/features/dynamic_theme/domain/models/theme_schema.dart';

/// The merchant's design tokens, resolved for Flutter.
///
/// The same values the storefront writes as CSS custom properties reach the app as data, so a
/// colour changed in Theme Settings moves both clients at once. Where a token is absent or
/// unparseable the app's own theme wins — a half-applied palette is worse than none, and a
/// mistyped colour must never blank a section.
///
/// Provided through an InheritedWidget so a renderer can read tokens without threading them
/// through every constructor, and so a rebuild after a publish repaints everything below it.
class ThemeStyle extends InheritedWidget {
  const ThemeStyle({
    super.key,
    required this.tokens,
    required this.fallback,
    required super.child,
  });

  final ThemeTokens tokens;

  /// The app's own theme, used wherever a token is missing.
  final ThemeData fallback;

  static ThemeStyle of(BuildContext context) {
    final style = context.dependOnInheritedWidgetOfExactType<ThemeStyle>();
    if (style != null) return style;

    // A renderer used outside a themed page still has to draw. Falling back to the ambient theme
    // keeps that legal instead of making the widget unusable in isolation — which is also what
    // makes these renderers testable on their own.
    return ThemeStyle(
      tokens: ThemeTokens.empty,
      fallback: Theme.of(context),
      child: const SizedBox.shrink(),
    );
  }

  Color get primary => color(_token('colors', 'primary')) ?? fallback.primaryColor;

  Color get accent =>
      color(_token('colors', 'accent')) ?? fallback.colorScheme.secondary;

  Color get surface =>
      color(_token('colors', 'surface')) ?? fallback.cardColor;

  Color get textPrimary =>
      color(_token('colors', 'text')) ??
      (fallback.textTheme.bodyMedium?.color ?? fallback.colorScheme.onSurface);

  Color get mutedText => color(_token('colors', 'muted_text')) ?? fallback.hintColor;

  Color get border =>
      color(_token('colors', 'border')) ?? fallback.dividerColor;

  /// The corner radius the merchant chose, clamped to something a card can actually wear.
  double get radius {
    final value = _token('layout', 'border_radius');
    final parsed = value == null ? null : double.tryParse(value);
    return (parsed ?? 8).clamp(0, 40).toDouble();
  }

  /// A colour from a token or a section setting, or null when there isn't one.
  ///
  /// Accepts `#RGB`, `#RRGGBB` and `#AARRGGBB`, with or without the hash — all four reach here
  /// from a builder field that lets a merchant type freely.
  Color? color(String? value) {
    if (value == null) return null;

    var hex = value.trim().replaceAll('#', '').toUpperCase();
    if (hex.isEmpty) return null;

    if (hex.length == 3) {
      hex = hex.split('').map((char) => '$char$char').join();
    }
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    if (hex.length != 8) return null;

    final parsed = int.tryParse(hex, radix: 16);
    return parsed == null ? null : Color(parsed);
  }

  String? _token(String group, String key) {
    final values = switch (group) {
      'colors' => tokens.colors,
      'typography' => tokens.typography,
      'layout' => tokens.layout,
      'branding' => tokens.branding,
      _ => const <String, dynamic>{},
    };

    final value = values[key];
    if (value == null) return null;

    final text = '$value'.trim();
    // `inherit` is the storefront's way of saying "use the theme's own value", and it must not be
    // parsed as a colour or a number.
    return text.isEmpty || text == 'inherit' || text == 'null' ? null : text;
  }

  @override
  bool updateShouldNotify(ThemeStyle oldWidget) =>
      oldWidget.tokens != tokens || oldWidget.fallback != fallback;
}
