import 'package:flutter/material.dart';
import 'package:syriapharmacy/features/dynamic_theme/domain/models/theme_schema.dart';
import 'package:syriapharmacy/features/dynamic_theme/engine/theme_style.dart';
import 'package:syriapharmacy/utill/dimensions.dart';

/// The frame every section shares: background, spacing, and an optional heading.
///
/// Written once because these are the settings the builder puts on EVERY section — a merchant who
/// sets `padding_top` on a product rail expects it to behave exactly as it does on a banner row.
/// A renderer that drew its own padding would be the reason two sections with identical settings
/// look different, and that is the kind of inconsistency a builder makes very visible.
class ThemeSectionShell extends StatelessWidget {
  const ThemeSectionShell({
    super.key,
    required this.section,
    required this.child,
    this.trailing,
  });

  final ThemeSectionSchema section;
  final Widget child;

  /// A "view all" affordance or similar, aligned with the heading.
  final Widget? trailing;

  /// A web-scale spacing value, spoken in phone. 0.35 keeps proportions (a merchant who doubles
  /// the web spacing still gets double here) while landing the storefront default of 40 on a
  /// calm 14.
  static double _phoneSpacing(int webPixels) =>
      (webPixels * 0.35).roundToDouble().clamp(0, 48);

  @override
  Widget build(BuildContext context) {
    final settings = section.settings;
    final style = ThemeStyle.of(context);

    // The flash deal reads as a MOMENT, not another white band: with no merchant background it
    // sits on a soft brand wash — the one deliberate interruption in the page's rhythm.
    final background = style.color(settings.string('background')) ??
        (section.type == 'flash_deal'
            ? style.primary.withValues(alpha: .05)
            : null);
    final title = section.title;
    final eyebrow = section.eyebrow;
    final subtitle = section.subtitle;
    // A section can carry its "view all" link without a title — the storefront draws that head row
    // too, and dropping it here would leave the app's rail with no way past the merchant's limit.
    final hasHeading =
        title != null || eyebrow != null || subtitle != null || trailing != null;

    return Container(
      width: double.infinity,
      color: background,
      padding: EdgeInsets.only(
        // The stored value is WEB pixels — the builder's canvas is a desktop page, and its
        // default of 40 read as an 80px chasm between every two phone sections. The number is
        // kept as the merchant's INTENT and mapped to a phone rhythm: proportional, so more
        // spacing on the web is still more on the phone, but at the scale a phone breathes in.
        // Zero stays zero, and the clamp still swallows a mistyped 4000.
        top: _phoneSpacing(settings.integer('padding_top', 24)),
        bottom: _phoneSpacing(settings.integer('padding_bottom', 24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hasHeading)
            Padding(
              padding: const EdgeInsets.only(
                left: Dimensions.paddingSizeDefault,
                right: Dimensions.paddingSizeDefault,
                bottom: 12,
              ),
              child: _Heading(
                eyebrow: eyebrow,
                title: title,
                subtitle: subtitle,
                alignment: settings.string('alignment') ?? 'start',
                headingStyle: settings.string('heading_style') ?? 'standard',
                trailing: trailing,
              ),
            ),
          child,
        ],
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.alignment,
    required this.headingStyle,
    required this.trailing,
  });

  final String? eyebrow;
  final String? title;
  final String? subtitle;
  final String alignment;

  /// The merchant's heading voice: `standard` is the working head every rail wears, `editorial`
  /// is the big centred statement for a moment that deserves one, `compact` is a quiet one-liner
  /// for supporting content. Same fields, three registers — not three layouts to maintain.
  final String headingStyle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final editorial = headingStyle == 'editorial';
    final compact = headingStyle == 'compact';
    final centred = editorial || alignment == 'center';

    final titleStyle = editorial
        ? theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800, height: 1.15, letterSpacing: -.3)
        : compact
            ? theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700, height: 1.15)
            : theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800, height: 1.15, letterSpacing: -.2);

    final text = Column(
      crossAxisAlignment:
          centred ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        if (eyebrow != null && !compact)
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              eyebrow!.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
                letterSpacing: 1.1,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        if (title != null)
          Text(
            title!,
            textAlign: centred ? TextAlign.center : TextAlign.start,
            style: titleStyle,
          ),
        if (title != null && !compact)
          // The storefront's signature carried over: the short accent rule that marks a section
          // heading as a heading. Small enough to be a detail, present enough to be an identity.
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(
              width: editorial ? 40 : 28,
              height: 3,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: .85),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        if (subtitle != null && !compact)
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text(
              subtitle!,
              textAlign: centred ? TextAlign.center : TextAlign.start,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.hintColor,
                height: 1.3,
              ),
            ),
          ),
      ],
    );

    if (trailing == null) {
      return centred ? Center(child: text) : text;
    }

    // The editorial head is a centred statement; its link sits beneath it rather than
    // fighting the big title for the same row.
    if (editorial) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [text, const SizedBox(height: 4), trailing!],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: text),
        trailing!,
      ],
    );
  }
}
