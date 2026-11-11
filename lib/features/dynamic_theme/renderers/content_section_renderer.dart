import 'package:flutter/material.dart';
import 'package:syriapharmacy/common/basewidget/custom_image_widget.dart';
import 'package:syriapharmacy/features/dynamic_theme/domain/models/theme_schema.dart';
import 'package:syriapharmacy/features/dynamic_theme/engine/section_renderer.dart';
import 'package:syriapharmacy/features/dynamic_theme/engine/theme_action_resolver.dart';
import 'package:syriapharmacy/features/dynamic_theme/engine/theme_style.dart';
import 'package:syriapharmacy/features/dynamic_theme/widgets/theme_section_shell.dart';
import 'package:syriapharmacy/theme/custom_theme_colors.dart';
import 'package:syriapharmacy/utill/dimensions.dart';

/// The sections whose content is entirely in the payload: trust badges, statistics, testimonials,
/// FAQs, interest tiles, price bands, the app-download strip.
///
/// They share a renderer because they share a structure — a list of blocks, each with a little
/// text and maybe an icon or an image — and differ only in how that list is arranged. The
/// arrangement is chosen from the section type, and everything else is the same code, which is why
/// none of these needed a network call or a model of its own.
class ContentSectionRenderer extends SectionRenderer {
  const ContentSectionRenderer();

  static const ThemeActionResolver _actions = ThemeActionResolver();

  @override
  List<String> get types => const [
    'usp_strip',
    'stats_bar',
    'testimonials',
    'faq',
    'interest_tiles',
    'price_tiles',
    'app_download',
  ];

  /// Almost every one of these draws from its blocks — no blocks means the merchant has not
  /// filled the section in yet, and the page skips it. app_download is the exception: it has NO
  /// block type at all (the store links come from the shop's own config), so demanding blocks
  /// meant the section could never render on any phone.
  @override
  bool canRender(ThemeSectionSchema section) =>
      section.type == 'app_download' || section.blocks.isNotEmpty;

  @override
  Widget? build(BuildContext context, ThemeSectionSchema section) {
    // «ثقتكم بالأرقام»: نفس شكل الموقع (لوحة بنفسجية داكنة + أيقونة + رقم + وصف)
    if (section.type == 'stats_bar') {
      return ThemeSectionShell(section: section, child: _StatsPanel(section: section));
    }

    final Widget body = switch (contentLayoutFor(section.type, section.variant)) {
      ContentLayout.faqPanel => _FaqList(section: section),
      ContentLayout.faqColumns => _FaqList(section: section, columns: true),
      ContentLayout.faqCards => _FaqCards(section: section),
      ContentLayout.quoteCards => _TestimonialRail(section: section),
      ContentLayout.quoteCompact =>
          _TestimonialRail(section: section, compact: true),
      ContentLayout.quoteWall => _TestimonialWall(section: section),
      ContentLayout.circleRow => _BubbleRow(section: section),
      ContentLayout.tileRail => _TileGrid(section: section, rail: true),
      ContentLayout.tileGrid => _TileGrid(section: section),
      ContentLayout.iconPlain =>
          _IconRow(section: section, showLabels: true, dress: _Dress.plain),
      ContentLayout.iconDark =>
          _IconRow(section: section, showLabels: true, dress: _Dress.dark),
      ContentLayout.iconBoxed =>
          _IconRow(section: section, showLabels: true, dress: _Dress.boxed),
    };

    return ThemeSectionShell(section: section, child: body);
  }

  static void _tap(BuildContext context, ThemeSettings settings) =>
      _actions.go(context, settings.action);

  static bool _tappable(ThemeSettings settings) =>
      _actions.isNavigable(settings.action);
}

/// Every look this renderer can draw.
///
/// One enum rather than a switch per widget so the mapping below can be read — and tested —
/// against the display styles the builder actually offers. The bug that motivated it: the tile
/// section branched on a style called `bubbles` that the builder never produces, so a merchant
/// choosing "circles" got the grid, silently, forever.
enum ContentLayout {
  iconBoxed,
  iconPlain,
  iconDark,
  tileGrid,
  circleRow,
  tileRail,
  quoteCards,
  quoteWall,
  quoteCompact,
  faqPanel,
  faqColumns,
  faqCards,
}

/// The layout a section type and display style ask for.
///
/// Every branch here matches a value in `SectionRegistry`'s options for that type. A style this
/// build has never heard of falls to the type's default rather than to nothing, so a section
/// composed on a newer server still draws.
ContentLayout contentLayoutFor(String type, String? variant) {
  return switch (type) {
    'faq' => switch (variant) {
      'two_column' => ContentLayout.faqColumns,
      'cards' => ContentLayout.faqCards,
      _ => ContentLayout.faqPanel,
    },
    'testimonials' => switch (variant) {
      'wall' => ContentLayout.quoteWall,
      'compact' => ContentLayout.quoteCompact,
      _ => ContentLayout.quoteCards,
    },
    'interest_tiles' => switch (variant) {
      'circles' => ContentLayout.circleRow,
      'rail' => ContentLayout.tileRail,
      _ => ContentLayout.tileGrid,
    },
    'price_tiles' => ContentLayout.tileGrid,
  // usp_strip, stats_bar and the app-download strip are one row in three dresses.
    _ => switch (variant) {
      'plain' => ContentLayout.iconPlain,
      'dark' => ContentLayout.iconDark,
      _ => ContentLayout.iconBoxed,
    },
  };
}

/// A row of small items — a trust badge, a statistic, a store link. Scrollable rather than
/// squeezed, because four of these across a phone leaves each one unreadable.
/// How an icon row dresses: a bordered card, bare text, or an inverted dark band — the
/// boxed / plain / dark options the builder offers on trust strips and stat bars.
enum _Dress { boxed, plain, dark }

class _IconRow extends StatelessWidget {
  const _IconRow({
    required this.section,
    required this.showLabels,
    this.dress = _Dress.boxed,
  });

  final ThemeSectionSchema section;
  final bool showLabels;
  final _Dress dress;

  @override
  Widget build(BuildContext context) {
    final style = ThemeStyle.of(context);
    final theme = Theme.of(context);

    final Color tileColor = switch (dress) {
      _Dress.dark => const Color(0xFF1D2430),
      _Dress.plain => Colors.transparent,
      _Dress.boxed => style.surface,
    };
    final Color titleColor = dress == _Dress.dark
        ? Colors.white
        : (theme.textTheme.bodyMedium?.color ?? style.textPrimary);
    final Color subtitleColor =
    dress == _Dress.dark ? Colors.white70 : style.mutedText;
    final Border? border =
    dress == _Dress.boxed ? Border.all(color: style.border) : null;

    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
        itemCount: section.blocks.length,
        separatorBuilder: (_, __) => const SizedBox(width: Dimensions.paddingSizeSmall),
        itemBuilder: (context, index) {
          final settings = section.blocks[index].settings;
          final title = settings.string('title') ?? settings.string('value');
          final subtitle = settings.string('subtitle') ?? settings.string('label');
          final image = settings.string('image');

          final tile = Container(
            width: 150,
            padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
            decoration: BoxDecoration(
              color: tileColor,
              borderRadius: BorderRadius.circular(style.radius),
              border: border,
            ),
            child: Row(
              children: [
                if (image != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: CustomImageWidget(image: image, height: 34, width: 34),
                  ),
                if (image != null) const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (title != null)
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700, color: titleColor),
                        ),
                      if (showLabels && subtitle != null)
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: subtitleColor),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );

          if (!ContentSectionRenderer._tappable(settings)) return tile;

          return InkWell(
            borderRadius: BorderRadius.circular(style.radius),
            onTap: () => ContentSectionRenderer._tap(context, settings),
            child: tile,
          );
        },
      ),
    );
  }
}

/// Interest and price tiles: a picture with a label, two or three across.
class _TileGrid extends StatelessWidget {
  const _TileGrid({required this.section, this.rail = false});

  final ThemeSectionSchema section;

  /// The builder's "rail" style: the same tiles, scrolled sideways instead of wrapped. A grid of
  /// nine on a phone is three rows of thumbnails; a rail says "there is more" and costs one line.
  final bool rail;

  @override
  Widget build(BuildContext context) {
    final columns = section.settings.integer('columns', 3).clamp(2, 4);

    if (rail) {
      // Sized so the next tile peeks: a rail that ends flush at the screen edge reads as a grid
      // that happens to be one row, and nobody swipes it.
      final width = MediaQuery.sizeOf(context).width / (columns + 0.35);

      return SizedBox(
        height: width / 0.85 + 24,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
          itemCount: section.blocks.length,
          separatorBuilder: (_, __) => const SizedBox(width: Dimensions.paddingSizeSmall),
          itemBuilder: (context, index) =>
              SizedBox(width: width, child: _tile(context, index)),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: section.blocks.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          mainAxisSpacing: Dimensions.paddingSizeSmall,
          crossAxisSpacing: Dimensions.paddingSizeSmall,
          childAspectRatio: 0.85,
        ),
        itemBuilder: _tile,
      ),
    );
  }

  Widget _tile(BuildContext context, int index) {
    final style = ThemeStyle.of(context);
    final settings = section.blocks[index].settings;
    final image = settings.string('image');
    final title = settings.string('title') ?? settings.string('label');

    final tile = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(style.radius),
            child: image != null
                ? CustomImageWidget(image: image, fit: BoxFit.cover, width: double.infinity)
                : ColoredBox(color: style.surface),
          ),
        ),
        if (title != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              title,
              maxLines: 1,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
      ],
    );

    if (!ContentSectionRenderer._tappable(settings)) return tile;

    return InkWell(
      borderRadius: BorderRadius.circular(style.radius),
      onTap: () => ContentSectionRenderer._tap(context, settings),
      child: tile,
    );
  }
}

/// Interest tiles as round bubbles — the builder's "bubbles" style, the same circular grammar
/// shoppers already know from the category rail.
class _BubbleRow extends StatelessWidget {
  const _BubbleRow({required this.section});

  final ThemeSectionSchema section;

  @override
  Widget build(BuildContext context) {
    final style = ThemeStyle.of(context);
    const size = 74.0;

    return SizedBox(
      height: size + 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
        itemCount: section.blocks.length,
        separatorBuilder: (_, __) =>
        const SizedBox(width: Dimensions.paddingSizeSmall),
        itemBuilder: (context, index) {
          final settings = section.blocks[index].settings;
          final image = settings.string('image');
          final title = settings.string('title') ?? settings.string('label');

          final bubble = SizedBox(
            width: size + 12,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipOval(
                  child: SizedBox(
                    height: size,
                    width: size,
                    child: image != null
                        ? CustomImageWidget(image: image, fit: BoxFit.cover)
                        : ColoredBox(color: style.surface),
                  ),
                ),
                if (title != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      title,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
              ],
            ),
          );

          if (!ContentSectionRenderer._tappable(settings)) return bubble;

          return InkWell(
            customBorder: const CircleBorder(),
            onTap: () => ContentSectionRenderer._tap(context, settings),
            child: bubble,
          );
        },
      ),
    );
  }
}

/// Customer quotes, one card at a time.
class _TestimonialRail extends StatelessWidget {
  const _TestimonialRail({required this.section, this.compact = false});

  final ThemeSectionSchema section;

  /// The builder's "compact" style: tighter cards for a page where the quotes are seasoning,
  /// not the dish. ("wall" renders as cards too — a masonry wall has no phone-width reading.)
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final style = ThemeStyle.of(context);
    final theme = Theme.of(context);

    return SizedBox(
      height: compact ? 104 : 148,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
        itemCount: section.blocks.length,
        separatorBuilder: (_, __) => const SizedBox(width: Dimensions.paddingSizeSmall),
        itemBuilder: (context, index) {
          final settings = section.blocks[index].settings;
          final quote = settings.string('body') ?? settings.string('subtitle');
          final author = settings.string('title') ?? settings.string('name');

          return Container(
            width: MediaQuery.sizeOf(context).width * (compact ? 0.55 : 0.72),
            padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
            decoration: BoxDecoration(
              color: style.surface,
              borderRadius: BorderRadius.circular(style.radius),
              border: Border.all(color: style.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (quote != null)
                  Expanded(
                    child: Text(
                      quote,
                      maxLines: compact ? 2 : 4,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                if (author != null)
                  Text(
                    author,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: style.primary,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Questions and answers, collapsed until asked for.
class _FaqList extends StatelessWidget {
  const _FaqList({required this.section, this.columns = false});

  final ThemeSectionSchema section;

  /// The builder's "two column" style. Honoured where there is width for it and ignored on a
  /// phone, because two columns of collapsible questions across 390 logical pixels is one column
  /// of unreadable ones — the option means "use the room if you have it", not "halve the text".
  final bool columns;

  @override
  Widget build(BuildContext context) {
    if (columns && MediaQuery.sizeOf(context).width >= 600) {
      final half = (section.blocks.length / 2).ceil();

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _column(context, section.blocks.take(half))),
            const SizedBox(width: Dimensions.paddingSizeDefault),
            Expanded(child: _column(context, section.blocks.skip(half))),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
      child: _column(context, section.blocks),
    );
  }

  Widget _column(BuildContext context, Iterable<ThemeBlock> blocks) {
    final style = ThemeStyle.of(context);

    return Column(
      children: [
        for (final block in blocks)
          if (block.settings.string('title') != null)
            Theme(
              // ExpansionTile draws its own dividers over the card border, which reads as a
              // double line on every row. Removing them here rather than restyling every row.
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: 8),
                title: Text(
                  block.settings.string('title')!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                children: [
                  if (block.settings.string('body') != null)
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        block.settings.string('body')!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: style.mutedText,
                        ),
                      ),
                    ),
                ],
              ),
            ),
      ],
    );
  }
}

/// Questions and answers as open cards — the builder's "cards" style.
///
/// The difference from the panel list is not decoration: an expander hides every answer behind a
/// tap, which is right for twenty shipping questions and wrong for the three a shop wants read.
class _FaqCards extends StatelessWidget {
  const _FaqCards({required this.section});

  final ThemeSectionSchema section;

  @override
  Widget build(BuildContext context) {
    final style = ThemeStyle.of(context);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
      child: Column(
        children: [
          for (final block in section.blocks)
            if (block.settings.string('title') != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
                padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                decoration: BoxDecoration(
                  color: style.surface,
                  borderRadius: BorderRadius.circular(style.radius),
                  border: Border.all(color: style.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      block.settings.string('title')!,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    if (block.settings.string('body') != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          block.settings.string('body')!,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: style.mutedText),
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

/// Quotes stacked down the page rather than scrolled sideways — the builder's "wall" style.
///
/// A rail shows one quote at a time and asks to be swiped; a wall is read. Which is right depends
/// on whether the reviews are the point of the section or the seasoning on it, and that is the
/// merchant's call, not the renderer's.
class _TestimonialWall extends StatelessWidget {
  const _TestimonialWall({required this.section});

  final ThemeSectionSchema section;

  @override
  Widget build(BuildContext context) {
    final style = ThemeStyle.of(context);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
      child: Column(
        children: [
          for (final block in section.blocks)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
              padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
              decoration: BoxDecoration(
                color: style.surface,
                borderRadius: BorderRadius.circular(style.radius),
                border: Border.all(color: style.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (block.settings.string('body') != null ||
                      block.settings.string('subtitle') != null)
                    Text(
                      block.settings.string('body') ??
                          block.settings.string('subtitle')!,
                      style: theme.textTheme.bodySmall,
                    ),
                  if (block.settings.string('title') != null ||
                      block.settings.string('name') != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        block.settings.string('title') ??
                            block.settings.string('name')!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: style.primary,
                        ),
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

/// «ثقتكم بالأرقام» بنفس شكل الموقع: تم إزالة الكونتينر الخارجي، وأصبح السكرول يمتد لعرض الشاشة
class _StatsPanel extends StatelessWidget {
  const _StatsPanel({required this.section});

  final ThemeSectionSchema section;

  static const Color _tile = Color(0xFF211642);

  /// حجم البطاقة الواحدة بالصف الأفقي.
  static const double _tileWidth = 130;
  static const double _tileHeight = 140;

  /// أسماء الحقول المحتملة من السيرفر (أول واحد موجود يُستعمل).
  static const _valueKeys = ['value', 'number', 'count', 'stat', 'counter', 'total', 'amount'];
  static const _labelKeys = ['label', 'subtitle', 'title', 'name', 'text', 'description'];

  static String? _first(ThemeSettings s, List<String> keys) {
    for (final key in keys) {
      final v = s.string(key);
      if (v != null) return v;
    }
    return null;
  }

  static IconData _iconFor(String? iconName, String? label, int index) {
    // أسماء الأيقونات القادمة من الداشبورد (نفس أيقونات الموقع: سماعة، قفل، شاحنة)
    final byName = switch ((iconName ?? '').trim().toLowerCase()) {
      'support' || 'headset' || 'headphones' => Icons.headphones_outlined,
      'secure' || 'lock' || 'shield' => Icons.lock_outline_rounded,
      'shipping' || 'truck' || 'delivery' => Icons.local_shipping_outlined,
      'star' => Icons.star_outline_rounded,
      'heart' => Icons.favorite_border_rounded,
      _ => null,
    };
    if (byName != null) return byName;

    final hint = '${iconName ?? ''} ${label ?? ''}'.toLowerCase();
    bool has(List<String> words) => words.any(hint.contains);

    if (has(['headset', 'headphone', 'support', 'customer', 'user', 'people', 'عملاء', 'عميل'])) {
      return Icons.headset_mic_rounded;
    }
    if (has(['truck', 'ship', 'deliver', 'order', 'طلب', 'توصيل'])) {
      return Icons.local_shipping_rounded;
    }
    if (has(['brand', 'award', 'medal', 'علامات', 'ماركة'])) {
      return Icons.workspace_premium_rounded;
    }
    if (has(['bag', 'product', 'box', 'package', 'shop', 'store', 'منتج'])) {
      return Icons.shopping_bag_rounded;
    }
    if (has(['star', 'rating', 'review'])) return Icons.star_rounded;
    if (has(['heart', 'like'])) return Icons.favorite_rounded;
    if (has(['shield', 'secure', 'lock', 'safe'])) return Icons.verified_user_rounded;

    const fallback = [
      Icons.headset_mic_rounded,
      Icons.shopping_bag_rounded,
      Icons.workspace_premium_rounded,
      Icons.local_shipping_rounded,
    ];
    return fallback[index % fallback.length];
  }

  @override
  Widget build(BuildContext context) {
    final blocks = section.blocks;

    // تم إزالة الـ Container الخارجي الذي كان يلف القائمة
    // وأصبح الـ ListView يمتد مباشرة مع إضافة الـ padding له لضمان هوامش مناسبة عند بداية ونهاية السكرول
    return SizedBox(
      height: _tileHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
        itemCount: blocks.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) => SizedBox(
          width: _tileWidth,
          child: _StatTile(settings: blocks[i].settings, index: i),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.settings, required this.index});

  final ThemeSettings settings;
  final int index;

  @override
  Widget build(BuildContext context) {
    // اطبع الحقول الجاية من السيرفر لتعرف أسماءها إذا الرقم ما ظهر.
    debugPrint('STAT block settings: ${settings.raw}');

    var value = _StatsPanel._first(settings, _StatsPanel._valueKeys);
    final label = _StatsPanel._first(
      settings,
      _StatsPanel._labelKeys.where((k) => settings.string(k) != value).toList(),
    );
    if (value != null) {
      final prefix = settings.string('prefix') ?? '';
      final suffix = settings.string('suffix') ?? '';
      if (prefix.isNotEmpty && !value.startsWith(prefix)) value = '$prefix$value';
      if (suffix.isNotEmpty && !value.endsWith(suffix)) value = '$value$suffix';
    }

    final image = settings.string('image');
    final icon = _StatsPanel._iconFor(settings.string('icon'), label, index);

    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: _StatsPanel._tile,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: .10)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: BrandGradients.primary,
              borderRadius: BorderRadius.circular(13),
            ),
            child: image != null
                ? Padding(
              padding: const EdgeInsets.all(10),
              child: CustomImageWidget(image: image, fit: BoxFit.contain),
            )
                : Icon(icon, color: Colors.white, size: 25),
          ),
          if (value != null) ...[
            const SizedBox(height: 12),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),
          ],
          if (label != null) ...[
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: .65),
                fontSize: 12.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}