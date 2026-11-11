import 'package:flutter/material.dart';
import 'package:syriapharmacy/theme/custom_theme_colors.dart';
import 'package:provider/provider.dart';
import 'package:syriapharmacy/common/basewidget/custom_image_widget.dart';
import 'package:syriapharmacy/features/dynamic_theme/controllers/dynamic_theme_controller.dart';
import 'package:syriapharmacy/features/dynamic_theme/domain/models/theme_schema.dart';
import 'package:syriapharmacy/features/dynamic_theme/engine/section_renderer.dart';
import 'package:syriapharmacy/features/dynamic_theme/engine/theme_action_resolver.dart';
import 'package:syriapharmacy/features/dynamic_theme/engine/theme_style.dart';
import 'package:syriapharmacy/features/dynamic_theme/widgets/theme_section_shell.dart';
import 'package:syriapharmacy/localization/language_constrants.dart';
import 'package:syriapharmacy/utill/custom_themes.dart';
import 'package:syriapharmacy/features/dynamic_theme/widgets/theme_view_all.dart';
import 'package:syriapharmacy/utill/dimensions.dart';

/// Category, brand and vendor rails — the three lists whose entries are all "a picture, a name,
/// and somewhere to go".
///
/// One renderer, and every display style the builder offers for each:
///
///   category_grid   circles · cards · tiles · chips
///   brand_slider    tiles · circles · rail
///   vendor_slider   cards · rail · compact
///
/// The styles share the same entry model and tap handling; only the arrangement changes, which is
/// what lets a merchant flip a category row from round shortcuts to image tiles and see the same
/// change on the phone without a release.
class TaxonomySectionRenderer extends SectionRenderer {
  const TaxonomySectionRenderer();

  @override
  List<String> get types => const ['category_grid', 'brand_slider', 'vendor_slider'];

  @override
  bool canRender(ThemeSectionSchema section) => section.source.isApi;

  @override
  Widget? build(BuildContext context, ThemeSectionSchema section) =>
      _TaxonomySection(section: section, kind: _Kind.of(section.type));
}

/// What distinguishes one taxonomy rail from another.
/// Every look this renderer can draw.
enum TaxonomyLayout {
  circleRail,
  cardRail,
  shopCards,
  vendorStorefront,
  labelledGrid,
  bareGrid,
  chips,
  compactList,
}

/// The layout a taxonomy section's display style asks for.
///
/// Written per section type because the three types offer three different vocabularies for the
/// same shelf: a category grid speaks of circles and chips, a brand slider of marquee and story, a
/// vendor rail of cards and compact. Reading them through one switch is how the brand slider's
/// three styles all ended up drawing the same rail — none of its words appeared in it.
TaxonomyLayout taxonomyLayoutFor(String type, String? variant) {
  return switch (type) {
    'brand_slider' => switch (variant) {
      'grid' => TaxonomyLayout.labelledGrid,
      'story' => TaxonomyLayout.circleRail,
      _ => TaxonomyLayout.cardRail,
    },
    'vendor_slider' => switch (variant) {
      'rail' => TaxonomyLayout.cardRail,
      'compact' => TaxonomyLayout.compactList,
      'logos' => TaxonomyLayout.circleRail,
    // The storefront card: cover, logo, badges, stats and a way in.
      'storefront' => TaxonomyLayout.vendorStorefront,
      _ => TaxonomyLayout.shopCards,
    },
  // category_grid, and anything new that lands here before it has a branch of its own.
    _ => switch (variant) {
      'cards' => TaxonomyLayout.labelledGrid,
      'tiles' => TaxonomyLayout.bareGrid,
      'chips' => TaxonomyLayout.chips,
      _ => TaxonomyLayout.circleRail,
    },
  };
}

enum _Kind {
  category(actionType: 'category'),
  brand(actionType: 'brand'),
  vendor(actionType: 'vendor');

  const _Kind({required this.actionType});

  /// The action type a tap produces — the same vocabulary the server uses for links.
  final String actionType;

  static _Kind of(String sectionType) => switch (sectionType) {
    'brand_slider' => _Kind.brand,
    'vendor_slider' => _Kind.vendor,
    _ => _Kind.category,
  };
}

class _TaxonomySection extends StatefulWidget {
  const _TaxonomySection({required this.section, required this.kind});

  final ThemeSectionSchema section;
  final _Kind kind;

  @override
  State<_TaxonomySection> createState() => _TaxonomySectionState();
}

class _TaxonomySectionState extends State<_TaxonomySection> {
  static const ThemeActionResolver _actions = ThemeActionResolver();

  /// Requests this section's data if the controller does not hold it.
  ///
  /// Called from build, not initState, on purpose: Flutter reuses this State when a republish
  /// swaps the section in place (same widget type, same position), so initState never runs again —
  /// and a republish also clears fetched data, which would have left the section on its shimmer
  /// forever. loadSectionData is idempotent, so asking on every build is safe; the post-frame
  /// deferral keeps the notify out of the build.
  void _ensureDataRequested() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<DynamicThemeController>().loadSectionData(widget.section);
    });
  }

  void _open(_Entry entry) => _actions.go(
    context,
    ThemeAction(type: widget.kind.actionType, id: entry.id, slug: entry.slug),
  );

  @override
  Widget build(BuildContext context) {
    final section = widget.section;
    final limit = section.settings.integer('limit', 12).clamp(1, 40);

    return Consumer<DynamicThemeController>(
      builder: (context, controller, _) {
        final response = controller.dataFor(section);
        if (response == null) _ensureDataRequested();
        if (response == null || controller.isSectionLoading(section)) {
          return ThemeSectionShell(
            section: section,
            trailing: ThemeViewAll.forSection(section),
            child: const _Shimmer(),
          );
        }

        final entries = _entriesFrom(response.response?.data).take(limit).toList();
        if (entries.isEmpty) return const SizedBox.shrink();

        // The vendor sections' stats toggle (default on, like the web): rating and how much
        // the shop sells, under its name. Brand and category entries never carry the fields.
        final showStats = widget.kind == _Kind.vendor &&
            section.settings.flag('stats', true);

        final Widget body = switch (
        taxonomyLayoutFor(widget.section.type, section.variant)) {
          TaxonomyLayout.shopCards => _CardRail(
              entries: entries,
              onTap: _open,
              width: 200,
              height: 120,
              showStats: showStats),
          TaxonomyLayout.vendorStorefront => _VendorStorefrontRail(
              entries: entries, onTap: _open, showStats: showStats),
          TaxonomyLayout.compactList =>
              _CompactList(entries: entries, onTap: _open, showStats: showStats),
          TaxonomyLayout.labelledGrid => _ImageGrid(
              section: section, entries: entries, onTap: _open, labelBelow: true),
          TaxonomyLayout.bareGrid => _ImageGrid(
              section: section, entries: entries, onTap: _open, labelBelow: false),
          TaxonomyLayout.chips => _Chips(entries: entries, onTap: _open),
          TaxonomyLayout.circleRail => _CircleRail(
              entries: entries,
              onTap: _open,
              // شعار الماركة يظهر كامل داخل الدائرة بدون قص
              containImages: widget.kind == _Kind.brand,
              size: widget.kind == _Kind.brand ? 70 : 68),
        // العلامات التجارية صارت دوائر (كانت مستطيلات 132×84)
          TaxonomyLayout.cardRail => widget.kind == _Kind.brand
              ? _CircleRail(
              entries: entries,
              onTap: _open,
              containImages: true,
              size: 70)
              : _CardRail(
              entries: entries,
              onTap: _open,
              width: 132,
              height: 70,
              showStats: showStats),
        };

        return ThemeSectionShell(
          section: section,
          trailing: ThemeViewAll.forSection(section),
          child: body,
        );
      },
    );
  }

  /// Entries out of whatever the endpoint returned.
  ///
  /// The three endpoints do not agree on a wrapper — categories and brands answer with a bare
  /// list, sellers with an object — and none of them may be allowed to throw here. Everything
  /// that is not a usable row is dropped rather than raised.
  List<_Entry> _entriesFrom(dynamic data) {
    try {
      final raw = switch (data) {
        List<dynamic> items => items,
        {'data': final List<dynamic> items} => items,
        {'sellers': final List<dynamic> items} => items,
        {'categories': final List<dynamic> items} => items,
        {'brands': final List<dynamic> items} => items,
        _ => const <dynamic>[],
      };

      return raw
          .whereType<Map>()
          .map(_Entry.fromJson)
          .where((entry) => entry.name != null)
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }
}

/// The storefront card: a vendor as a store rather than a logo.
///
/// Everything on it is data the shop already publishes — the merchant's own
/// banner, their logo, how many products they carry, what shoppers rated them,
/// whether they are open. Nothing is inferred: the «متجر رسمي» badge is the
/// platform's own `author_type`, and a rating appears only when reviews exist.
/// Each absent field simply removes its own line, so a bare store still reads
/// as a balanced card.
class _VendorStorefrontRail extends StatelessWidget {
  const _VendorStorefrontRail(
      {required this.entries, required this.onTap, this.showStats = true});

  final List<_Entry> entries;
  final void Function(_Entry) onTap;
  final bool showStats;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 214,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
        itemCount: entries.length,
        separatorBuilder: (_, __) =>
        const SizedBox(width: Dimensions.paddingSizeSmall),
        itemBuilder: (context, index) => _VendorStorefrontCard(
            entry: entries[index],
            showStats: showStats,
            onTap: () => onTap(entries[index])),
      ),
    );
  }
}

class _VendorStorefrontCard extends StatelessWidget {
  const _VendorStorefrontCard(
      {required this.entry, required this.onTap, required this.showStats});

  final _Entry entry;
  final VoidCallback onTap;
  final bool showStats;

  @override
  Widget build(BuildContext context) {
    final style = ThemeStyle.of(context);
    final bool hasRating =
        (entry.reviewCount ?? 0) > 0 && (entry.rating ?? 0) > 0;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        width: 232,
        decoration: BoxDecoration(
          color: style.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: BrandColors.hairline),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Cover, with the logo riding its lower edge.
          SizedBox(
            height: 84,
            child: Stack(clipBehavior: Clip.none, children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(14)),
                  child: entry.cover != null
                      ? CustomImageWidget(image: entry.cover!, fit: BoxFit.cover)
                      : const DecoratedBox(
                      decoration:
                      BoxDecoration(gradient: BrandGradients.primary)),
                ),
              ),
              if (entry.closed)
                PositionedDirectional(
                  top: 8,
                  end: 8,
                  child: Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: BrandColors.ink.withValues(alpha: .72),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      getTranslated('temporarily_closed', context) ?? '',
                      style:
                      textBold.copyWith(fontSize: 9, color: Colors.white),
                    ),
                  ),
                ),
              PositionedDirectional(
                start: 12,
                bottom: -18,
                child: Container(
                  width: 46,
                  height: 46,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: BrandColors.hairline),
                  ),
                  child: entry.image != null
                      ? CustomImageWidget(
                      image: entry.image!, fit: BoxFit.contain)
                      : Icon(Icons.storefront_outlined,
                      size: 22, color: style.primary),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Flexible(
                      child: Text(
                        entry.name ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: robotoBold.copyWith(
                            fontSize: Dimensions.fontSizeDefault,
                            color: style.textPrimary),
                      ),
                    ),
                    if (entry.official) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.verified_rounded,
                          size: 14, color: BrandColors.blue),
                    ],
                  ]),
                  if (entry.official)
                    Text(
                      getTranslated('official_store', context) ?? '',
                      maxLines: 1,
                      style: textRegular.copyWith(
                          fontSize: 9, color: BrandColors.blue),
                    ),
                  if (showStats) ...[
                    const SizedBox(height: 3),
                    Row(children: [
                      if (hasRating) ...[
                        const Icon(Icons.star_rate_rounded,
                            color: BrandColors.star, size: 13),
                        Text(
                          '${entry.rating!.toStringAsFixed(1)} (${entry.reviewCount})',
                          style: textRegular.copyWith(
                              fontSize: 10, color: style.mutedText),
                        ),
                        if ((entry.productCount ?? 0) > 0)
                          Text(' · ',
                              style: textRegular.copyWith(
                                  fontSize: 10, color: style.mutedText)),
                      ],
                      if ((entry.productCount ?? 0) > 0)
                        Flexible(
                          child: Text(
                            '${entry.productCount} ${getTranslated('products', context)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textRegular.copyWith(
                                fontSize: 10, color: style.mutedText),
                          ),
                        ),
                    ]),
                  ],
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    decoration: BoxDecoration(
                      gradient: BrandGradients.primary,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(
                      getTranslated('visit_store', context) ?? '',
                      maxLines: 1,
                      style: robotoBold.copyWith(
                          fontSize: 10.5, color: Colors.white),
                    ),
                  ),
                ]),
          ),
        ]),
      ),
    );
  }
}

/// One row of a taxonomy endpoint, reduced to what a tile needs.
class _Entry {
  const _Entry(
      {this.id,
        this.slug,
        this.name,
        this.image,
        this.rating,
        this.productCount,
        this.cover,
        this.reviewCount,
        this.official = false,
        this.closed = false});

  final int? id;
  final String? slug;
  final String? name;
  final String? image;

  /// What a buyer weighs before entering a store — carried only by the sellers endpoint.
  final double? rating;
  final int? productCount;

  /// The shop's own storefront banner, if the merchant uploaded one. Never the
  /// logo stretched wide: with no cover the card draws a brand field instead.
  final String? cover;

  /// How many shoppers actually rated the store. A rating with no reviews behind
  /// it is not shown at all.
  final int? reviewCount;

  /// The platform's own store — an explicit `author_type`, not an inference.
  final bool official;

  /// Closed for a holiday or by the merchant: worth saying before a tap.
  final bool closed;

  factory _Entry.fromJson(Map<dynamic, dynamic> json) {
    // Shops carry their display name under `name` on the shop object, brands and categories
    // directly. Reading both keeps one parser serving all three.
    final shop = json['shop'];
    final source = shop is Map ? shop : json;

    return _Entry(
      id: int.tryParse('${json['id'] ?? source['id'] ?? ''}'),
      rating: double.tryParse('${json['average_rating'] ?? ''}'),
      productCount: int.tryParse('${json['product_count'] ?? ''}'),
      reviewCount: int.tryParse('${json['review_count'] ?? ''}'),
      official: '${source['author_type'] ?? ''}' == 'admin',
      closed: '${json['temporary_close'] ?? source['temporary_close'] ?? ''}' == '1' ||
          '${json['temporary_close'] ?? source['temporary_close'] ?? ''}' == 'true' ||
          '${json['is_vacation_mode_now'] ?? ''}' == 'true' ||
          '${source['vacation_status'] ?? ''}' == 'true',
      cover: _text(
        source['banner_full_url']?['path'] ??
            source['offer_banner_full_url']?['path'] ??
            source['bottom_banner_full_url']?['path'],
      ),
      slug: _text(json['slug'] ?? source['slug']),
      name: _text(source['name'] ?? json['name']),
      // The merchant's phone image first, wherever this row came from — a shop, a brand or a
      // category. The server falls back to the web image inside each `mobile_*` key, so reading
      // them first is not a risk: an entry with no mobile image still arrives with a picture.
      image: _text(
        source['mobile_image_full_url']?['path'] ??
            json['mobile_image_full_url']?['path'] ??
            source['mobile_icon_full_url']?['path'] ??
            json['mobile_icon_full_url']?['path'] ??
            source['image_full_url']?['path'] ??
            json['image_full_url']?['path'] ??
            source['icon_full_url']?['path'] ??
            json['icon_full_url']?['path'] ??
            source['image'] ??
            json['image'],
      ),
    );
  }

  static String? _text(dynamic value) {
    if (value == null) return null;
    final text = '$value'.trim();
    return text.isEmpty || text == 'null' ? null : text;
  }
}

/// Round shortcuts in a scrolling row — the classic category rail.
class _CircleRail extends StatelessWidget {
  const _CircleRail({
    required this.entries,
    required this.onTap,
    this.size = 68,
    this.containImages = false,
  });

  final List<_Entry> entries;
  final void Function(_Entry entry) onTap;

  /// قطر الدائرة.
  final double size;

  /// true = الصورة تظهر كاملة على خلفية بيضاء (للشعارات)، false = تملأ الدائرة.
  final bool containImages;

  @override
  Widget build(BuildContext context) {
    final style = ThemeStyle.of(context);

    return SizedBox(
      height: size + 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
        itemCount: entries.length,
        separatorBuilder: (_, __) =>
        const SizedBox(width: Dimensions.paddingSizeSmall),
        itemBuilder: (context, index) {
          final entry = entries[index];

          return InkWell(
            onTap: () => onTap(entry),
            borderRadius: BorderRadius.circular(size),
            child: SizedBox(
              width: size + 14,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // A soft tinted ring lifts the circle off any background and gives every
                  // category the same finished edge — logo images on white no longer bleed
                  // into the page.
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: style.primary.withValues(alpha: .07),
                      border: Border.all(
                        color: style.primary.withValues(alpha: .18),
                        width: 1,
                      ),
                    ),
                    child: ClipOval(
                      child: SizedBox(
                        height: size - 6,
                        width: size - 6,
                        child: entry.image == null
                            ? ColoredBox(color: style.surface)
                            : containImages
                            ? ColoredBox(
                          color: Colors.white,
                          child: Padding(
                            padding: EdgeInsets.all(size * 0.16),
                            child: CustomImageWidget(
                                image: entry.image!,
                                fit: BoxFit.contain),
                          ),
                        )
                            : CustomImageWidget(
                            image: entry.image!, fit: BoxFit.cover),
                      ),
                    ),
                  ),
                  const SizedBox(height: 7),
                  _EntryLabel(name: entry.name!),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Rectangular image cards in a scrolling row — brand logos, shop covers.
class _CardRail extends StatelessWidget {
  const _CardRail({
    required this.entries,
    required this.onTap,
    required this.width,
    required this.height,
    this.showStats = false,
    this.containImages = false,
  });

  final List<_Entry> entries;
  final void Function(_Entry entry) onTap;
  final double width;
  final double height;
  final bool showStats;

  /// Logos are contained on a soft surface; covers and photos fill the frame.
  final bool containImages;

  @override
  Widget build(BuildContext context) {
    final style = ThemeStyle.of(context);

    return SizedBox(
      height: height + (showStats ? 64 : 44),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
        itemCount: entries.length,
        separatorBuilder: (_, __) =>
        const SizedBox(width: Dimensions.paddingSizeSmall),
        itemBuilder: (context, index) {
          final entry = entries[index];

          return InkWell(
            borderRadius: BorderRadius.circular(style.radius),
            onTap: () => onTap(entry),
            child: SizedBox(
              width: width,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(style.radius),
                    child: SizedBox(
                      height: height,
                      child: entry.image == null
                          ? ColoredBox(color: style.surface)
                          : containImages
                          ? ColoredBox(
                        color: Theme.of(context).cardColor,
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: CustomImageWidget(
                              image: entry.image!,
                              fit: BoxFit.contain),
                        ),
                      )
                          : CustomImageWidget(
                          image: entry.image!, fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(height: 6),
                  _EntryLabel(name: entry.name!, maxLines: showStats ? 1 : 2),
                  if (showStats) _StatsLine(entry: entry, centred: true),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// A fixed grid of images — "cards" carries the label below, "tiles" overlays it on the image.
class _ImageGrid extends StatelessWidget {
  const _ImageGrid({
    required this.section,
    required this.entries,
    required this.onTap,
    required this.labelBelow,
  });

  final ThemeSectionSchema section;
  final List<_Entry> entries;
  final void Function(_Entry entry) onTap;
  final bool labelBelow;

  @override
  Widget build(BuildContext context) {
    final style = ThemeStyle.of(context);
    final columns = section.settings.integer('columns', 3).clamp(2, 4);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: entries.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          mainAxisSpacing: Dimensions.paddingSizeSmall,
          crossAxisSpacing: Dimensions.paddingSizeSmall,
          childAspectRatio: labelBelow ? 0.78 : 1,
        ),
        itemBuilder: (context, index) {
          final entry = entries[index];

          final image = ClipRRect(
            borderRadius: BorderRadius.circular(style.radius),
            child: entry.image != null
                ? CustomImageWidget(
              image: entry.image!,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            )
                : ColoredBox(color: style.surface),
          );

          return InkWell(
            borderRadius: BorderRadius.circular(style.radius),
            onTap: () => onTap(entry),
            child: labelBelow
                ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: image),
                const SizedBox(height: 6),
                _EntryLabel(name: entry.name!),
              ],
            )
                : Stack(
              fit: StackFit.expand,
              children: [
                image,
                // The scrim keeps a white label readable on whatever photo the
                // merchant chose.
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(style.radius),
                    gradient: const LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.center,
                      colors: [Color(0x8C000000), Color(0x00000000)],
                    ),
                  ),
                ),
                PositionedDirectional(
                  start: 10,
                  end: 8,
                  bottom: 9,
                  child: Row(children: [
                    Expanded(
                      child: Text(
                        entry.name!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Icon(forwardChevron(context),
                        size: 16, color: Colors.white),
                  ]),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Text pills that wrap — the densest arrangement, all names visible at once.
class _Chips extends StatelessWidget {
  const _Chips({required this.entries, required this.onTap});

  final List<_Entry> entries;
  final void Function(_Entry entry) onTap;

  @override
  Widget build(BuildContext context) {
    final style = ThemeStyle.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
      child: Wrap(
        spacing: Dimensions.paddingSizeExtraSmall,
        runSpacing: Dimensions.paddingSizeExtraSmall,
        children: [
          for (final entry in entries)
            ActionChip(
              onPressed: () => onTap(entry),
              label: Text(entry.name!),
              labelStyle: Theme.of(context).textTheme.bodySmall,
              side: BorderSide(color: style.border),
              backgroundColor: style.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(style.radius * 2),
              ),
            ),
        ],
      ),
    );
  }
}

/// Dense rows — the vendor list a shopper reads rather than browses.
class _CompactList extends StatelessWidget {
  const _CompactList(
      {required this.entries, required this.onTap, this.showStats = false});

  final List<_Entry> entries;
  final void Function(_Entry entry) onTap;
  final bool showStats;

  @override
  Widget build(BuildContext context) {
    final style = ThemeStyle.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
      child: Column(
        children: [
          for (final entry in entries)
            InkWell(
              borderRadius: BorderRadius.circular(style.radius),
              onTap: () => onTap(entry),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: Dimensions.paddingSizeExtraSmall),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(style.radius),
                      child: SizedBox(
                        width: 44,
                        height: 44,
                        child: entry.image != null
                            ? CustomImageWidget(image: entry.image!, fit: BoxFit.cover)
                            : ColoredBox(color: style.surface),
                      ),
                    ),
                    const SizedBox(width: Dimensions.paddingSizeSmall),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            entry.name!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          if (showStats) _StatsLine(entry: entry),
                        ],
                      ),
                    ),
                    Icon(forwardChevron(context),
                        size: Dimensions.iconSizeSmall, color: style.mutedText),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EntryLabel extends StatelessWidget {
  const _EntryLabel({required this.name, this.maxLines = 2});

  final String name;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Text(
      name,
      maxLines: maxLines,
      textAlign: TextAlign.center,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        fontWeight: FontWeight.w600,
        height: 1.15,
      ),
    );
  }
}

class _Shimmer extends StatelessWidget {
  const _Shimmer();

  @override
  Widget build(BuildContext context) {
    final style = ThemeStyle.of(context);

    return SizedBox(
      height: 108,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
        itemCount: 5,
        separatorBuilder: (_, __) =>
        const SizedBox(width: Dimensions.paddingSizeSmall),
        itemBuilder: (context, index) => Container(
          height: 68,
          width: 68,
          decoration: BoxDecoration(
            color: style.surface,
            borderRadius: BorderRadius.circular(34),
          ),
        ),
      ),
    );
  }
}


/// The shop's numbers, spoken small: its rating when it has one, and how much it sells.
class _StatsLine extends StatelessWidget {
  const _StatsLine({required this.entry, this.centred = false});

  final _Entry entry;
  final bool centred;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasRating = (entry.rating ?? 0) > 0;
    final count = entry.productCount;
    if (!hasRating && count == null) return const SizedBox.shrink();

    final muted = theme.textTheme.labelSmall?.copyWith(color: theme.hintColor);

    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment:
        centred ? MainAxisAlignment.center : MainAxisAlignment.start,
        children: [
          if (hasRating) ...[
            const Icon(Icons.star_rate_rounded, size: 13, color: Colors.orange),
            const SizedBox(width: 1),
            Text(entry.rating!.toStringAsFixed(1), style: muted),
          ],
          if (hasRating && count != null)
            Text('  ·  ', style: muted),
          if (count != null)
            Flexible(
              child: Text(
                '$count ${getTranslated('products', context) ?? 'products'}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: muted,
              ),
            ),
        ],
      ),
    );
  }
}
