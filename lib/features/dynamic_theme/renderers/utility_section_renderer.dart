import 'dart:math' as math;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:provider/provider.dart';
import 'package:syriapharmacy/common/basewidget/custom_image_widget.dart';
import 'package:syriapharmacy/common/basewidget/product_shimmer_item_widget.dart';
import 'package:syriapharmacy/common/basewidget/product_widget.dart';
import 'package:syriapharmacy/common/basewidget/show_custom_snakbar_widget.dart';
import 'package:syriapharmacy/features/dynamic_theme/controllers/dynamic_theme_controller.dart';
import 'package:syriapharmacy/features/dynamic_theme/domain/models/theme_schema.dart';
import 'package:syriapharmacy/features/dynamic_theme/engine/section_renderer.dart';
import 'package:syriapharmacy/features/dynamic_theme/engine/theme_action_resolver.dart';
import 'package:syriapharmacy/features/dynamic_theme/engine/theme_style.dart';
import 'package:syriapharmacy/features/dynamic_theme/widgets/theme_section_shell.dart';
import 'package:syriapharmacy/features/product/domain/models/product_model.dart';
import 'package:syriapharmacy/localization/language_constrants.dart';
import 'package:syriapharmacy/utill/dimensions.dart';

import '../../../theme/custom_theme_colors.dart';

/// The section types that closed the web/app parity gap: tabs, stories, branches, before/after,
/// the ship-today countdown, live coupons, and merchant HTML.
///
/// Grouped in one file because each is small and none shares enough with the banner/product/
/// taxonomy families to live there. Every renderer keeps the engine's two promises: it renders
/// entirely from the payload (plus, for tabs and coupons, the source the payload names), and it
/// declines rather than draws an empty band.
class UtilitySectionRenderer extends SectionRenderer {
  const UtilitySectionRenderer();

  @override
  List<String> get types => const [
        'product_tabs',
        'stories',
        'branches',
        'before_after',
        'shipping_cutoff',
        'coupon_strip',
        'custom_html',
      ];

  @override
  bool canRender(ThemeSectionSchema section) => switch (section.type) {
        'product_tabs' => section.source.tabs.any((tab) => tab.isApi),
        'stories' || 'branches' || 'before_after' => section.blocks.isNotEmpty,
        'shipping_cutoff' => section.settings.string('cutoff') != null,
        'coupon_strip' => section.source.isApi,
        'custom_html' => section.settings.string('content') != null,
        _ => false,
      };

  @override
  Widget? build(BuildContext context, ThemeSectionSchema section) {
    final Widget body = switch (utilityLayoutFor(section.type, section.variant)) {
      UtilityLayout.tabs => _ProductTabs(section: section),
      UtilityLayout.stories => _StoriesRail(section: section),
      UtilityLayout.branchCards => _BranchList(section: section),
      UtilityLayout.branchList => _BranchList(section: section, plain: true),
      UtilityLayout.beforeAfter => _BeforeAfterGrid(section: section),
      UtilityLayout.cutoffStrip => _ShippingCutoff(section: section),
      UtilityLayout.cutoffCard => _ShippingCutoff(section: section, card: true),
      UtilityLayout.couponTickets => _CouponStrip(section: section),
      UtilityLayout.couponCards => _CouponStrip(section: section, stacked: true),
      UtilityLayout.couponLine => _CouponStrip(section: section, line: true),
      UtilityLayout.html => _MerchantHtml(section: section),
    };

    return ThemeSectionShell(section: section, child: body);
  }
}

/// Every look this renderer can draw.
enum UtilityLayout {
  tabs,
  stories,
  branchCards,
  branchList,
  beforeAfter,
  cutoffStrip,
  cutoffCard,
  couponTickets,
  couponCards,
  couponLine,
  html,
}

/// The layout a utility section's display style asks for.
///
/// Same shape as the other renderers, for the same reason: these types offer styles the builder
/// writes into every published theme, and a style with no branch is a choice that does nothing on
/// the phone while the website honours it.
///
/// `stories` takes its two styles inside its own widget, which is why one entry covers both.
UtilityLayout utilityLayoutFor(String type, String? variant) {
  return switch (type) {
    'product_tabs' => UtilityLayout.tabs,
    'stories' => UtilityLayout.stories,
    'before_after' => UtilityLayout.beforeAfter,
    'branches' => variant == 'list' ? UtilityLayout.branchList : UtilityLayout.branchCards,
    'shipping_cutoff' =>
      variant == 'card' ? UtilityLayout.cutoffCard : UtilityLayout.cutoffStrip,
    'coupon_strip' => switch (variant) {
        'cards' => UtilityLayout.couponCards,
        'strip' => UtilityLayout.couponLine,
        _ => UtilityLayout.couponTickets,
      },
    _ => UtilityLayout.html,
  };
}

/// One product row, several sources, switched by chips — each tab fetched on first open only.
class _ProductTabs extends StatefulWidget {
  const _ProductTabs({required this.section});

  final ThemeSectionSchema section;

  @override
  State<_ProductTabs> createState() => _ProductTabsState();
}

class _ProductTabsState extends State<_ProductTabs> {
  int _active = 0;

  String _keyFor(int index) => '${widget.section.uuid}#$index';

  @override
  Widget build(BuildContext context) {
    final tabs = widget.section.source.tabs;
    final labels = [
      // The tab block's merchant-typed name travels as `label` (its registry title key);
      // reading `title` here left every chip numbered while the web showed the real names.
      for (var i = 0; i < tabs.length; i++)
        widget.section.blocks.length > i
            ? (widget.section.blocks[i].settings.string('label') ??
                widget.section.blocks[i].settings.string('title') ??
                '${i + 1}')
            : '${i + 1}',
    ];

    return Consumer<DynamicThemeController>(
      builder: (context, controller, _) {
        final key = _keyFor(_active);
        final activeIsApi = _active < tabs.length && tabs[_active].isApi;
        final held = controller.keyedData(key);
        if (activeIsApi && (held == null || !held.isSuccess)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) controller.loadKeyedData(key, tabs[_active]);
          });
        }

        final response = controller.keyedData(key);
        final products = response == null
            ? const <Product>[]
            : _productsFrom(response.response?.data)
                .take(widget.section.settings.integer('limit', 8).clamp(1, 40))
                .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                itemCount: labels.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                itemBuilder: (context, index) {
                  final selected = index == _active;
                  final style = ThemeStyle.of(context);

                  // Filled pill for the active tab, hairline ghost for the rest — reads as one
                  // segmented control instead of a row of chips with checkmarks.
                  return ChoiceChip(
                    label: Text(labels[index]),
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : null,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 13,
                    ),
                    selected: selected,
                    showCheckmark: false,
                    selectedColor: style.primary,
                    backgroundColor: Theme.of(context).cardColor,
                    side: BorderSide(
                      color: selected
                          ? Colors.transparent
                          : Theme.of(context).dividerColor.withValues(alpha: .6),
                    ),
                    shape: const StadiumBorder(),
                    visualDensity: VisualDensity.compact,
                    onSelected: (_) => setState(() => _active = index),
                  );
                },
              ),
            ),
            const SizedBox(height: Dimensions.paddingSizeSmall),
            if (activeIsApi && (response == null || controller.isKeyLoading(key)))
              SizedBox(
                height: 250,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
                  itemCount: 4,
                  itemBuilder: (context, index) => const Padding(
                    padding: EdgeInsets.only(right: Dimensions.paddingSizeSmall),
                    child: SizedBox(width: 160, child: ProductShimmerItemWidget()),
                  ),
                ),
              )
            else if (products.isEmpty)
              const SizedBox.shrink()
            else if (widget.section.variant == 'grid' ||
                widget.section.settings.string('style') == 'grid')
              // The builder's "grid" display, honored: the web draws a grid for it, and the app
              // silently rendering a rail made the same section disagree between clients.
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisExtent: 250,
                  crossAxisSpacing: Dimensions.paddingSizeSmall,
                  mainAxisSpacing: Dimensions.paddingSizeSmall,
                ),
                itemCount: products.length,
                itemBuilder: (context, index) =>
                    ProductWidget(productModel: products[index]),
              )
            else
              SizedBox(
                height: 250,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
                  itemCount: products.length,
                  itemBuilder: (context, index) => SizedBox(
                    width: 160,
                    child: ProductWidget(productModel: products[index]),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  List<Product> _productsFrom(dynamic data) {
    try {
      final raw = switch (data) {
        {'products': final List<dynamic> items} => items,
        List<dynamic> items => items,
        _ => const <dynamic>[],
      };
      return raw.whereType<Map<String, dynamic>>().map(Product.fromJson).toList();
    } catch (_) {
      return const [];
    }
  }
}

/// Tall story cards that lead somewhere — the block's own link, resolved as a typed action.
class _StoriesRail extends StatelessWidget {
  const _StoriesRail({required this.section});

  final ThemeSectionSchema section;

  static const ThemeActionResolver _actions = ThemeActionResolver();

  @override
  Widget build(BuildContext context) {
    final style = ThemeStyle.of(context);
    final bubbles = (section.variant ?? 'bubbles') == 'bubbles';
    final width = bubbles ? 96.0 : 150.0;
    final height = bubbles ? 96.0 : 210.0;

    final cards = section.blocks
        .where((block) => block.settings.string('image') != null)
        .toList(growable: false);
    if (cards.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: height + 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
        itemCount: cards.length,
        separatorBuilder: (_, __) => const SizedBox(width: Dimensions.paddingSizeSmall),
        itemBuilder: (context, index) {
          final block = cards[index];
          final action = block.settings.action;

          final card = SizedBox(
            width: width,
            child: Column(
              children: [
                Container(
                  height: height,
                  width: width,
                  decoration: BoxDecoration(
                    shape: bubbles ? BoxShape.circle : BoxShape.rectangle,
                    borderRadius:
                        bubbles ? null : BorderRadius.circular(style.radius),
                    border: Border.all(color: style.primary, width: 2),
                  ),
                  padding: const EdgeInsets.all(2),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(
                        // Clamped: a theme corner radius under 2 made this negative, which
                        // BorderRadius rejects with an assert.
                        bubbles ? width : math.max(0, style.radius - 2)),
                    child: CustomImageWidget(
                      image: block.settings.string('image')!,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                if (block.settings.string('title') != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      block.settings.string('title')!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
              ],
            ),
          );

          if (!_actions.isNavigable(action)) return card;
          return InkWell(
              onTap: () => _actions.go(context, action), child: card);
        },
      ),
    );
  }
}

/// Branch cards: name, address, hours, a phone that dials and a map link that opens.
class _BranchList extends StatelessWidget {
  const _BranchList({required this.section, this.plain = false});

  final ThemeSectionSchema section;

  /// The builder's "list" style: the same branches with the card chrome taken off. A shop with two
  /// branches wants them to look considered; a shop with nine wants to read them.
  final bool plain;

  static const ThemeActionResolver _actions = ThemeActionResolver();

  @override
  Widget build(BuildContext context) {
    final style = ThemeStyle.of(context);
    final theme = Theme.of(context);

    final branches = section.blocks
        .where((block) => block.settings.string('title') != null)
        .toList(growable: false);
    if (branches.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
      child: Column(
        children: [
          for (final block in branches)
            Container(
              width: double.infinity,
              margin: EdgeInsets.only(bottom: plain ? 0 : Dimensions.paddingSizeSmall),
              padding: plain
                  ? const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall)
                  : const EdgeInsets.all(Dimensions.paddingSizeDefault),
              decoration: plain
                  ? BoxDecoration(
                      border: Border(bottom: BorderSide(color: style.border)))
                  : BoxDecoration(
                      color: style.surface,
                      borderRadius: BorderRadius.circular(style.radius),
                      border: Border.all(color: style.border),
                    ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(block.settings.string('title')!,
                      style: theme.textTheme.bodyLarge
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  if (block.settings.string('address') != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(block.settings.string('address')!,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: style.mutedText)),
                    ),
                  if (block.settings.string('hours') != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Row(children: [
                        Icon(Icons.schedule, size: 14, color: style.mutedText),
                        const SizedBox(width: 4),
                        Text(block.settings.string('hours')!,
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: style.mutedText)),
                      ]),
                    ),
                  Row(children: [
                    if (block.settings.string('phone') != null)
                      TextButton.icon(
                        onPressed: () => _actions.go(
                            context,
                            ThemeAction(
                                type: 'url',
                                url: 'tel:${block.settings.string('phone')}')),
                        icon: const Icon(Icons.call, size: 16),
                        label: Text(block.settings.string('phone')!),
                      ),
                    if (_actions.isNavigable(block.settings.action))
                      TextButton.icon(
                        onPressed: () =>
                            _actions.go(context, block.settings.action),
                        icon: const Icon(Icons.map_outlined, size: 16),
                        label: Text(getTranslated('map', context) ?? 'Map'),
                      ),
                  ]),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Before/after pairs, side by side with labels — the web's drag slider reduced to what a
/// scrolling page can hold without stealing the gesture.
class _BeforeAfterGrid extends StatelessWidget {
  const _BeforeAfterGrid({required this.section});

  final ThemeSectionSchema section;

  @override
  Widget build(BuildContext context) {
    final style = ThemeStyle.of(context);
    final theme = Theme.of(context);

    final pairs = section.blocks
        .where((block) =>
            block.settings.string('image') != null &&
            block.settings.string('after') != null)
        .toList(growable: false);
    if (pairs.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
      child: Column(
        children: [
          for (final block in pairs)
            Padding(
              padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    for (final (image, label) in [
                      (block.settings.string('image')!, getTranslated('before', context) ?? 'Before'),
                      (block.settings.string('after')!, getTranslated('after', context) ?? 'After'),
                    ])
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsetsDirectional.only(end: 6),
                          child: Column(children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(style.radius),
                              child: AspectRatio(
                                aspectRatio: 3 / 4,
                                child: CustomImageWidget(image: image, fit: BoxFit.cover),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(label,
                                style: theme.textTheme.labelSmall
                                    ?.copyWith(color: style.mutedText)),
                          ]),
                        ),
                      ),
                  ]),
                  if (block.settings.string('title') != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(block.settings.string('title')!,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600)),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// "Order within … to have it shipped today" — a live countdown to the merchant's cut-off hour.
///
/// The clock here decides a DISPLAY, never visibility: past the cut-off the strip says tomorrow's
/// window rather than lying with a negative timer, and section scheduling stays server-side.
// class _ShippingCutoff extends StatefulWidget {
//   const _ShippingCutoff({required this.section, this.card = false});
//
//   final ThemeSectionSchema section;
//
//   /// The builder's "card" style: the countdown as a block with the clock given its own line,
//   /// rather than a line of text with the numbers at the end of it.
//   final bool card;
//
//   @override
//   State<_ShippingCutoff> createState() => _ShippingCutoffState();
// }
//
// class _ShippingCutoffState extends State<_ShippingCutoff> {
//   Timer? _tick;
//
//   @override
//   void initState() {
//     super.initState();
//     _tick = Timer.periodic(const Duration(seconds: 1), (_) {
//       if (mounted) setState(() {});
//     });
//   }
//
//   @override
//   void dispose() {
//     _tick?.cancel();
//     super.dispose();
//   }
//
//   Duration? _remaining() {
//     final raw = widget.section.settings.string('cutoff');
//     if (raw == null) return null;
//
//     final parts = raw.split(':');
//     final hour = int.tryParse(parts.first);
//     final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
//     if (hour == null || hour < 0 || hour > 23) return null;
//
//     final now = DateTime.now();
//     var cutoff = DateTime(now.year, now.month, now.day, hour, minute);
//     if (!cutoff.isAfter(now)) cutoff = cutoff.add(const Duration(days: 1));
//     return cutoff.difference(now);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final style = ThemeStyle.of(context);
//     final remaining = _remaining();
//     if (remaining == null) return const SizedBox.shrink();
//
//     String two(int value) => value.toString().padLeft(2, '0');
//     final clock =
//         '${two(remaining.inHours)}:${two(remaining.inMinutes % 60)}:${two(remaining.inSeconds % 60)}';
//     final label = widget.section.settings.string('subtitle') ??
//         widget.section.settings.string('title') ??
//         (getTranslated('order_within', context) ?? 'Order within');
//
//     return Container(
//       margin: EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
//       padding: const EdgeInsets.symmetric(
//           horizontal: Dimensions.paddingSizeDefault,
//           vertical: Dimensions.paddingSizeSmall),
//       decoration: BoxDecoration(
//         color: style.primary.withValues(alpha: .08),
//         borderRadius: BorderRadius.circular(style.radius),
//         border: Border.all(color: style.primary.withValues(alpha: .25)),
//       ),
//       child: widget.card
//           ? Column(children: [
//               Icon(Icons.local_shipping_outlined, color: style.primary, size: 28),
//               const SizedBox(height: 6),
//               Text(label, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
//               const SizedBox(height: 4),
//               Text(
//                 clock,
//                 style: Theme.of(context).textTheme.headlineSmall?.copyWith(
//                     color: style.primary,
//                     fontWeight: FontWeight.w800,
//                     fontFeatures: const [FontFeature.tabularFigures()]),
//               ),
//             ])
//           : Row(children: [
//               Icon(Icons.local_shipping_outlined, color: style.primary),
//               const SizedBox(width: Dimensions.paddingSizeSmall),
//               Expanded(
//                 child: Text(label,
//                     maxLines: 2,
//                     overflow: TextOverflow.ellipsis,
//                     style: Theme.of(context).textTheme.bodySmall),
//               ),
//               Text(
//                 clock,
//                 style: Theme.of(context).textTheme.titleMedium?.copyWith(
//                     color: style.primary,
//                     fontWeight: FontWeight.w700,
//                     fontFeatures: const [FontFeature.tabularFigures()]),
//               ),
//             ]),
//     );
//   }
// }
class _ShippingCutoff extends StatefulWidget {
  const _ShippingCutoff({required this.section, this.card = false});

  final ThemeSectionSchema section;
  final bool card;

  @override
  State<_ShippingCutoff> createState() => _ShippingCutoffState();
}

class _ShippingCutoffState extends State<_ShippingCutoff> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  Duration? _remaining() {
    final raw = widget.section.settings.string('cutoff');
    if (raw == null) return null;

    final parts = raw.split(':');
    final hour = int.tryParse(parts.first);
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    if (hour == null || hour < 0 || hour > 23) return null;

    final now = DateTime.now();
    var cutoff = DateTime(now.year, now.month, now.day, hour, minute);
    if (!cutoff.isAfter(now)) cutoff = cutoff.add(const Duration(days: 1));
    return cutoff.difference(now);
  }

  @override
  Widget build(BuildContext context) {
    final style = ThemeStyle.of(context);
    final remaining = _remaining();
    if (remaining == null) return const SizedBox.shrink();

    String two(int value) => value.toString().padLeft(2, '0');
    final clock = '${two(remaining.inHours)}:${two(remaining.inMinutes % 60)}:${two(remaining.inSeconds % 60)}';

    final label = widget.section.settings.string('subtitle') ??
        widget.section.settings.string('title') ??
        (getTranslated('order_within', context) ?? 'Order within');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
      padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: BrandGradients.campaign,
      ),
      child: Row(
        children: [
          // أيقونة الشاحنة بلون الموقع الأساسي
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.local_shipping_outlined,
              color: Colors.amber,
              size: 28,
            ),
          ),
          const SizedBox(width: Dimensions.paddingSizeDefault),

          // النصوص والعداد
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      '$label ',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // العداد الزمني بلون الموقع الأساسي
                    Text(
                      clock,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.amber,                        fontWeight: FontWeight.w800,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  getTranslated('to_have_it_shipped_today', context) ??
                      'To have it shipped today',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Live coupons as tap-to-copy tickets. The list endpoint requires a customer; guests simply do
/// not get the strip — the same rule the web applies.
class _CouponStrip extends StatelessWidget {
  const _CouponStrip({required this.section, this.stacked = false, this.line = false});

  final ThemeSectionSchema section;

  /// The builder's "cards" style: full-width coupons down the page instead of a swiped row. Worth
  /// the height when the coupons ARE the offer rather than a reminder that some exist.
  final bool stacked;

  /// The builder's "strip" style: one line of codes, for a shop that keeps a standing discount and
  /// wants it mentioned rather than presented.
  final bool line;

  @override
  Widget build(BuildContext context) {
    return Consumer<DynamicThemeController>(
      builder: (context, controller, _) {
        final held = controller.keyedData(section.uuid);
        if (held == null || !held.isSuccess) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            controller.loadKeyedData(section.uuid, section.source);
          });
        }

        final response = controller.keyedData(section.uuid);
        // An error here is almost always 401 — a guest. Nothing to show, nothing to say.
        if (response == null || !response.isSuccess) return const SizedBox.shrink();

        final coupons = _couponsFrom(response.response?.data)
            .take(section.settings.integer('limit', 4).clamp(1, 20))
            .toList();
        if (coupons.isEmpty) return const SizedBox.shrink();

        final style = ThemeStyle.of(context);
        final theme = Theme.of(context);

        if (line) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
            child: Wrap(
              spacing: Dimensions.paddingSizeSmall,
              runSpacing: 6,
              children: [
                for (final coupon in coupons)
                  InkWell(
                    borderRadius: BorderRadius.circular(style.radius),
                    onTap: () => _copy(context, coupon),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: style.primary.withValues(alpha: .06),
                        borderRadius: BorderRadius.circular(style.radius),
                        border: Border.all(color: style.primary.withValues(alpha: .3)),
                      ),
                      child: Text(
                        coupon.code,
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: style.primary,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }

        if (stacked) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
            child: Column(
              children: [
                for (final coupon in coupons)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(style.radius),
                      onTap: () => _copy(context, coupon),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                        decoration: BoxDecoration(
                          color: style.primary.withValues(alpha: .06),
                          borderRadius: BorderRadius.circular(style.radius),
                          border: Border.all(color: style.primary.withValues(alpha: .3)),
                        ),
                        child: Row(children: [
                          Expanded(
                            child: Text(coupon.label,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall),
                          ),
                          Text(coupon.code,
                              style: theme.textTheme.titleSmall?.copyWith(
                                  color: style.primary,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1)),
                          const SizedBox(width: 6),
                          Icon(Icons.copy, size: 14, color: style.primary),
                        ]),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }

        return SizedBox(
          height: 92,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
            itemCount: coupons.length,
            separatorBuilder: (_, __) =>
                const SizedBox(width: Dimensions.paddingSizeSmall),
            itemBuilder: (context, index) {
              final coupon = coupons[index];

              return InkWell(
                borderRadius: BorderRadius.circular(style.radius),
                onTap: () => _copy(context, coupon),
                child: ClipPath(
                  clipper: _TicketClipper(radius: style.radius, notchCenter: 56),
                  child: Container(
                  width: 216,
                  padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                  decoration: BoxDecoration(
                    color: style.primary.withValues(alpha: .07),
                    borderRadius: BorderRadius.circular(style.radius),
                  ),
                  child: Row(children: [
                    // The badge is what makes a ticket read as an OFFER at rail speed — a
                    // bordered box of text reads as a form field.
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: style.primary.withValues(alpha: .12),
                      ),
                      child: Icon(Icons.percent, size: 18, color: style.primary),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(coupon.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(height: 1.1)),
                          const SizedBox(height: 3),
                          Row(children: [
                            Expanded(
                              child: Text(coupon.code,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                      color: style.primary,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1)),
                            ),
                            Icon(Icons.copy, size: 14, color: style.primary),
                          ]),
                        ],
                      ),
                    ),
                  ]),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  /// Copying IS the interaction — a coupon a shopper has to retype is a coupon they abandon.
  void _copy(BuildContext context, _Coupon coupon) {
    Clipboard.setData(ClipboardData(text: coupon.code));
    showCustomSnackBarWidget(
      '${getTranslated('coupon_code_copied', context) ?? 'Copied'}: ${coupon.code}',
      context,
    );
  }

  List<_Coupon> _couponsFrom(dynamic data) {
    try {
      final raw = switch (data) {
        List<dynamic> items => items,
        {'coupons': final List<dynamic> items} => items,
        {'data': final List<dynamic> items} => items,
        _ => const <dynamic>[],
      };

      return raw
          .whereType<Map>()
          .map((json) {
            final code = '${json['code'] ?? ''}'.trim();
            final discount = '${json['discount'] ?? ''}'.trim();
            final type = '${json['discount_type'] ?? ''}'.trim();
            final title = '${json['title'] ?? ''}'.trim();
            return _Coupon(
              code: code,
              label: title.isNotEmpty && title != 'null'
                  ? title
                  : (type == 'percentage' ? '$discount%' : discount),
            );
          })
          .where((coupon) => coupon.code.isNotEmpty && coupon.code != 'null')
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }
}

class _Coupon {
  const _Coupon({required this.code, required this.label});
  final String code;
  final String label;
}

/// The merchant's own markup, drawn by the script-free native HTML builder the app already ships
/// for product descriptions — no WebView, no JavaScript, stricter than the web that executes the
/// same markup raw.
class _MerchantHtml extends StatelessWidget {
  const _MerchantHtml({required this.section});

  final ThemeSectionSchema section;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
      child: HtmlWidget(
        section.settings.string('content')!,
        textStyle: Theme.of(context).textTheme.bodyMedium,
        // A markup mistake in an admin field must cost this section, never the page.
        onErrorBuilder: (context, element, error) => const SizedBox.shrink(),
      ),
    );
  }
}


/// The coupon silhouette every marketplace taught shoppers: rounded card with two half-circle
/// notches where a paper ticket would tear. The notch line separates the badge from the offer.
class _TicketClipper extends CustomClipper<Path> {
  const _TicketClipper({required this.radius, required this.notchCenter});

  final double radius;

  /// Distance from the leading edge to the tear line.
  final double notchCenter;

  @override
  Path getClip(Size size) {
    const notch = 5.0;
    final card = Path()
      ..addRRect(RRect.fromRectAndRadius(
          Offset.zero & size, Radius.circular(radius)));

    final holes = Path()
      ..addOval(Rect.fromCircle(center: Offset(notchCenter, 0), radius: notch))
      ..addOval(Rect.fromCircle(center: Offset(notchCenter, size.height), radius: notch));

    return Path.combine(PathOperation.difference, card, holes);
  }

  @override
  bool shouldReclip(_TicketClipper oldClipper) =>
      oldClipper.radius != radius || oldClipper.notchCenter != notchCenter;
}
