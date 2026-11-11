import 'package:flutter/material.dart';
import 'package:syriapharmacy/utill/dimensions.dart';
import 'package:syriapharmacy/utill/custom_themes.dart';
import 'package:syriapharmacy/theme/custom_theme_colors.dart';
import 'package:syriapharmacy/features/dynamic_theme/domain/models/theme_schema.dart';
import 'package:syriapharmacy/features/dynamic_theme/engine/theme_action_resolver.dart';
import 'package:syriapharmacy/localization/language_constrants.dart';

/// The "view all" link beside a section's heading.
///
/// A rail shows the merchant's `limit` and stops; on the web the shopper's way past that is the
/// view-all link, and until now the app simply dropped the setting — a section capped at eight
/// products was a dead end on the phone and a full list on the web from the same published theme.
///
/// The destination is not invented here: it is expressed as a [ThemeAction] and handed to
/// [ThemeActionResolver], the same routing a banner tap goes through, so a section's heading link
/// and its cards can never disagree about where the section leads.
class ThemeViewAll extends StatelessWidget {
  const ThemeViewAll._({required this.action});

  final ThemeAction action;

  static const ThemeActionResolver _actions = ThemeActionResolver();

  /// The affordance for a section, or null when the merchant turned it off or the section leads
  /// nowhere this build can open.
  static Widget? forSection(ThemeSectionSchema section) {
    // Default true to match the builder's own default and the storefront's `?? true`: a payload
    // that predates the setting shows the link on both clients rather than on one.
    if (!section.settings.flag('view_all', true)) return null;

    final action = _destinationOf(section);
    if (action == null || !_actions.isNavigable(action)) return null;

    return ThemeViewAll._(action: action);
  }

  /// Where each section's heading leads.
  ///
  /// The server decides this now, from what the section actually shows — which is the only place
  /// that knows a rail is scoped to one category rather than to the catalogue. What is left here
  /// is the fallback for a payload from a server that predates `view_all`: the same per-type guess
  /// this widget shipped with, kept so an app updated ahead of its backend still draws the link.
  static ThemeAction? _destinationOf(ThemeSectionSchema section) {
    if (!section.viewAll.isNone) return section.viewAll;

    final settings = section.settings;

    return switch (section.type) {
      'product_slider' =>
        const ThemeAction(type: 'collection', collection: 'all'),
      'category_showcase' =>
        _showcase('category', settings.integer('category_id', 0), section.title),
      'brand_showcase' =>
        _showcase('brand', settings.integer('brand_id', 0), section.title),
      'brand_slider' =>
        const ThemeAction(type: 'collection', collection: 'all_brands'),
      'vendor_slider' =>
        const ThemeAction(type: 'collection', collection: 'all_vendors'),
      _ => null,
    };
  }

  /// A showcase leads to the one category or brand it is about. With nothing chosen there is no
  /// destination — the link is dropped rather than pointed at an empty list.
  static ThemeAction? _showcase(String type, int id, String? title) =>
      id > 0 ? ThemeAction(type: type, id: id, slug: title) : null;

  @override
  Widget build(BuildContext context) {
    // The approved header link, identical to the one the native sections draw:
    // plain violet with a chevron, no underline. Two styles on one page read as
    // two different controls, and the underlined one was neither Direction B's
    // nor anything else on the screen.
    return InkWell(
      onTap: () => _actions.go(context, action),
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(
            getTranslated('view_all', context) ?? 'View all',
            style: textBold.copyWith(
              color: BrandColors.primary,
              fontSize: Dimensions.fontSizeSmall,
            ),
          ),
          const SizedBox(width: 3),
          Icon(forwardChevron(context),
              size: Dimensions.fontSizeDefault, color: BrandColors.primary),
        ]),
      ),
    );
  }
}

/// The chevron that means "onwards" in the reading direction of the moment.
///
/// Hard-coding one of them points the wrong way in the other locale, which reads as "back" — on an
/// Arabic storefront that is every rail on the page.
IconData forwardChevron(BuildContext context) =>
    Directionality.of(context) == TextDirection.rtl
        ? Icons.chevron_left
        : Icons.chevron_right;
