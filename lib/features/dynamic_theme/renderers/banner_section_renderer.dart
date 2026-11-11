import 'dart:async';
import 'dart:math' as math;

import 'package:carousel_slider/carousel_slider.dart';

import 'package:flutter/material.dart';
import 'package:syriapharmacy/theme/custom_theme_colors.dart';
import 'package:syriapharmacy/common/basewidget/custom_image_widget.dart';
import 'package:syriapharmacy/data/services/analytics_reporter.dart';
import 'package:syriapharmacy/features/dynamic_theme/domain/models/theme_schema.dart';
import 'package:syriapharmacy/features/dynamic_theme/engine/section_renderer.dart';
import 'package:syriapharmacy/features/dynamic_theme/engine/theme_action_resolver.dart';
import 'package:syriapharmacy/features/dynamic_theme/engine/theme_style.dart';
import 'package:syriapharmacy/features/dynamic_theme/widgets/theme_carousel_dots.dart';
import 'package:syriapharmacy/features/dynamic_theme/widgets/theme_section_shell.dart';
import 'package:syriapharmacy/utill/dimensions.dart';

// ── حجم بانرات الرئيسية (عدّل من هون بس) ───────────────────────────────────────
/// الهامش الجانبي للبانرات (كان 15). أقل = المستطيلات أعرض.
const double _kBannerSidePadding = 6;

/// المسافة بين المستطيلات (كانت 12 أو قيمة السيرفر). أقل = المستطيلات أكبر.
const double _kBannerGap = 6;

/// نسبة العرض/الطول الافتراضية (كانت 16/9 ≈ 1.78). أقل = المستطيل أطول وأكبر.
const double _kBannerRatio = 1.6;

/// عدد المستطيلات الكاملة الظاهرة بالشاشة.
const int _kBannerColumns = 2;

/// كم يظهر من المستطيل التالي (0.33 = تلته تقريباً). صفر = ما بيبين شي منه.
const double _kBannerPeek = 0.30;
// ────────────────────────────────────────────────────────────────────────────────

/// Every banner arrangement the builder offers, drawn from one card list.
///
/// Six section types share this renderer because they are the same content in different geometry:
/// the server has already merged each card with its live Banner Setup row, resolved the image for
/// this breakpoint and turned the merchant's link into a typed action. What is left is layout, and
/// layout is a parameter — which is why adding a seventh arrangement will not need a seventh
/// renderer.
class BannerSectionRenderer extends SectionRenderer {
  const BannerSectionRenderer();

  static const ThemeActionResolver _actions = ThemeActionResolver();

  @override
  List<String> get types => const [
    'hero_banner',
    'promotional_banner',
    'split_banner',
    'banner_mosaic',
    'banner_strip',
    'store_banner',
  ];

  /// A banner section with no card is an empty padded band, which reads on a page as a bug. The
  /// merchant sees why in the builder's readiness panel; the shopper simply never sees the band.
  @override
  bool canRender(ThemeSectionSchema section) =>
      (section.cards?.isNotEmpty ?? false);

  @override
  Widget? build(BuildContext context, ThemeSectionSchema section) {
    final cards = section.cards!;

    final Widget body = switch (bannerLayoutFor(section.type, section.variant,
        display: section.settings.string('display'))) {
      BannerLayout.carousel => _Carousel(section: section, cards: cards),
      BannerLayout.strip => _Strip(section: section, cards: cards),
      BannerLayout.mosaic => _Mosaic(section: section, cards: cards),
      BannerLayout.split =>
          _Grid(section: section, cards: cards, forcedColumns: 2),
      BannerLayout.rail => _Row(section: section, cards: cards),
      BannerLayout.swipe => _Row(section: section, cards: cards, paged: true),
      BannerLayout.overlap =>
          _Row(section: section, cards: cards, stagger: true),
    // كانت شبكة ثابتة؛ صارت صف أفقي: مستطيلين كاملين + جزء من الثالث
      BannerLayout.grid => _Row(section: section, cards: cards),
    };

    return ThemeSectionShell(section: section, child: body);
  }

  static void _tap(BuildContext context, ThemeCard card) {
    // Counted before the navigation: a banner placed by the theme builder is the same banner row
    // the merchant edits in Banner Setup, and its clicks belong in the same report.
    AnalyticsReporter.bannerClicked(card.bannerId);
    _actions.go(context, card.action);
  }

  static bool _tappable(ThemeCard card) => _actions.isNavigable(card.action);
}

/// Every arrangement this renderer can draw.
enum BannerLayout { carousel, strip, mosaic, split, grid, rail, swipe, overlap }

/// The arrangement a banner section's chosen style asks for.
///
/// Three of these types have no choice at all — a hero is a slideshow, a strip is a strip — and two
/// offer six and four. Reading all five through one loose switch is how `swipe` and `overlap`
/// ended up drawing the same grid as `tiles`: the value arrived, matched nothing, and fell through
/// silently while the web honoured it.
BannerLayout bannerLayoutFor(String type, String? variant, {String? display}) {
  return switch (type) {
    'hero_banner' => BannerLayout.carousel,
    'banner_strip' => BannerLayout.strip,
  // The mosaic's one choice lives in `display`, not `style` — the web offers the same
  // tiles as a swipeable row, and the app follows it there.
    'banner_mosaic' =>
    display == 'swipe' ? BannerLayout.swipe : BannerLayout.mosaic,
    'store_banner' => switch (variant) {
      'grid' => BannerLayout.grid,
      'mosaic' => BannerLayout.mosaic,
      'strip' => BannerLayout.strip,
      'split' => BannerLayout.split,
      'swipe' => BannerLayout.swipe,
      _ => BannerLayout.carousel,
    },
    'promotional_banner' => switch (variant) {
      'rail' => BannerLayout.rail,
      'overlap' => BannerLayout.overlap,
      'swipe' => BannerLayout.swipe,
      _ => BannerLayout.grid,
    },
    'split_banner' => BannerLayout.split,
    _ => BannerLayout.grid,
  };
}

/// A row of banners read sideways.
///
/// Three of the builder's styles are this shape and differ in how it moves: a rail scrolls freely,
/// a swipe settles one banner at a time, and an overlap staggers them so the row reads as a
/// composition rather than a table. They are one widget because they are one idea with three
/// physics, and three widgets would drift apart on the next change to a card.
class _Row extends StatelessWidget {
  const _Row({
    required this.section,
    required this.cards,
    this.paged = false,
    this.stagger = false,
  });

  final ThemeSectionSchema section;
  final List<ThemeCard> cards;
  final bool paged;
  final bool stagger;

  @override
  Widget build(BuildContext context) {
    // العرض الحقيقي المتاح للصف (مو عرض الشاشة): إذا الصفحة حاطة هوامش حوالين السكشن،
    // حساب العرض من الشاشة بيطلّع جزء أكبر من المستطيل الثالث.
    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        return _buildRow(context, available);
      },
    );
  }

  Widget _buildRow(BuildContext context, double width) {
    final settings = section.settings;
    final radius = ThemeStyle.of(context).radius;
    final gap = _kBannerGap;
    final overlay = settings.flag('overlay', true);

    // A paged row shows one banner; a free rail shows the next one peeking, which is what tells a
    // shopper it moves at all.
    const columns = _kBannerColumns;
    final cardWidth = paged
        ? width - _kBannerSidePadding * 2
        : (width - _kBannerSidePadding - gap * columns) /
        (columns + _kBannerPeek);
    final ratio = switch (settings.string('ratio')) {
      'square' => 1.0,
      'portrait' => 0.75,
      _ => _kBannerRatio,
    };
    var height = cardWidth / ratio + (stagger ? 18 : 0);
    if (paged) {
      // The merchant's swipe-row height is honoured the way the hero honours its own: as a
      // ceiling, so the web's 240 does not dictate a phone's proportions but a short row stays
      // short on both surfaces.
      height = math.min(
          height, settings.integer('height', 240).clamp(90, 400).toDouble());
    }

    if (paged) {
      // A real PageView: PageScrollPhysics on a ListView snaps by VIEWPORT width while the items
      // are card-wide, so every swipe drifted a little further off the card until banners sat
      // half out of frame. The fraction makes page extent and card extent the same thing.
      final fraction = ((cardWidth + gap) / width).clamp(0.5, 1.0);

      return SizedBox(
        height: height,
        child: PageView.builder(
          controller: PageController(viewportFraction: fraction),
          padEnds: false,
          itemCount: cards.length,
          itemBuilder: (context, index) => Padding(
            padding: EdgeInsets.only(
              left: _kBannerSidePadding,
              right: index == cards.length - 1 ? _kBannerSidePadding : 0,
            ),
            child: _CardTile(
                card: cards[index],
                radius: radius,
                overlayText: overlay,
                rotateMs: section.settings.integer('rotate_ms', 4000)),
          ),
        ),
      );
    }

    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: _kBannerSidePadding),
        itemCount: cards.length,
        separatorBuilder: (_, __) => SizedBox(width: gap),
        itemBuilder: (context, index) => Padding(
          // The stagger: every other card drops, so the row has a rhythm instead of a baseline.
          padding: EdgeInsets.only(top: stagger && index.isOdd ? 18 : 0),
          child: SizedBox(
            width: cardWidth,
            child: _CardTile(
              card: cards[index],
              radius: radius,
              overlayText: overlay,
              rotateMs: section.settings.integer('rotate_ms', 4000),
            ),
          ),
        ),
      ),
    );
  }
}

/// The full-width slideshow. Autoplay and interval come from the section's settings, so a merchant
/// can slow a busy hero down without a release.
class _Carousel extends StatefulWidget {
  const _Carousel({required this.section, required this.cards});

  final ThemeSectionSchema section;
  final List<ThemeCard> cards;

  @override
  State<_Carousel> createState() => _CarouselState();
}

class _CarouselState extends State<_Carousel> {
  int _slide = 0;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final calculatedHeight = (screenWidth * 0.5); // غير 0.5 إلى 0.71 إذا كنت لا تزال تريد النسبة القديمة
    // debugPrint('📏 مقاس الكونتينر الفعلي: العرض = $screenWidth | الارتفاع = $calculatedHeight');
    final settings = widget.section.settings;
    final cards = widget.cards;

    // The builder stores the web's pixel height; a phone is much narrower, so it is treated as a
    // ceiling rather than a target and the real height comes from the screen width. Half the width
    // is the 2:1 shape Banner Setup asks merchants to upload their phone image in. The floor
    // yields when the merchant's ceiling sits below it — clamp THROWS when its bounds cross, and
    // a height of 100 in the builder was taking the whole home page down with an ArgumentError.
    final maxHeight = settings.integer('height', 420).clamp(90, 420).toDouble();
    final minHeight = math.min(120.0, maxHeight);
    // final height = (MediaQuery.sizeOf(context).width * 0.5).clamp(minHeight, maxHeight);
// 0.71 تتطابق مع نسبة صورتك (554  781 ≈ 0.71)
    final height = (MediaQuery.sizeOf(context).width * 0.71).clamp(minHeight, maxHeight);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.bottomCenter,
          children: [
            CarouselSlider.builder(
              itemCount: cards.length,
              itemBuilder: (context, index, _) => _CardTile(
                card: cards[index],
                radius: ThemeStyle.of(context).radius,
                overlayText: true,
                rotateMs: widget.section.settings.integer('rotate_ms', 4000),
              ),
              options: CarouselOptions(
                height: height,
                // Edge to edge, like the storefront's hero. Peeking at the next slide cost every
                // slide about 8% of the screen and made the main banner look inset on a phone.
                viewportFraction: 1,
                autoPlay: settings.flag('autoplay', true) && cards.length > 1,
                autoPlayInterval: Duration(
                  milliseconds: settings.integer('interval', 5000).clamp(2000, 20000),
                ),
                enableInfiniteScroll: cards.length > 1,
                onPageChanged: (index, _) => setState(() => _slide = index),
              ),
            ),
            // ON the image, where every marketplace hero puts them: the page keeps its rhythm
            // (no extra band under the banner) and the dots inherit the scrim's legibility.
            if (cards.length > 1)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ThemeCarouselDots(
                  count: cards.length,
                  activeIndex: _slide,
                  onImage: true,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// A horizontally scrolling row — used where the web shows a wide strip that would squash on a
/// phone. Scrolling keeps every card legible instead of shrinking all of them.
class _Strip extends StatelessWidget {
  const _Strip({required this.section, required this.cards});

  final ThemeSectionSchema section;
  final List<ThemeCard> cards;

  @override
  Widget build(BuildContext context) {
    final radius = ThemeStyle.of(context).radius;
    final width = MediaQuery.sizeOf(context).width * 0.75;

    return SizedBox(
      height: width * 0.42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
        itemCount: cards.length,
        separatorBuilder: (_, __) =>
            SizedBox(width: Dimensions.paddingSizeSmall),
        itemBuilder: (context, index) => SizedBox(
          width: width,
          child: _CardTile(
              card: cards[index],
              radius: radius,
              overlayText: true,
              rotateMs: section.settings.integer('rotate_ms', 4000)),
        ),
      ),
    );
  }
}

/// The mosaic: one lead tile and a column of smaller ones. On a phone the web's arbitrary spans
/// collapse to this fixed pairing, because anything denser stops being tappable.
class _Mosaic extends StatelessWidget {
  const _Mosaic({required this.section, required this.cards});

  final ThemeSectionSchema section;
  final List<ThemeCard> cards;

  @override
  Widget build(BuildContext context) {
    final radius = ThemeStyle.of(context).radius;
    final gap = section.settings.integer('gap', 12).clamp(0, 32).toDouble();

    if (cards.length == 1) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: _CardTile(
              card: cards.first,
              radius: radius,
              overlayText: true,
              rotateMs: section.settings.integer('rotate_ms', 4000)),
        ),
      );
    }

    final lead = cards.first;
    final rest = cards.skip(1).take(2).toList(growable: false);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).width * 0.62,
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: _CardTile(
                  card: lead,
                  radius: radius,
                  overlayText: true,
                  rotateMs: section.settings.integer('rotate_ms', 4000)),
            ),
            SizedBox(width: gap),
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  for (var index = 0; index < rest.length; index++) ...[
                    if (index > 0) SizedBox(height: gap),
                    Expanded(
                      child: _CardTile(
                        card: rest[index],
                        radius: radius,
                        overlayText: true,
                        rotateMs: section.settings.integer('rotate_ms', 4000),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Equal tiles in a grid. The merchant's column count is honoured but capped: three tiles across a
/// phone is already the point where a banner's text stops being readable.
class _Grid extends StatelessWidget {
  const _Grid({required this.section, required this.cards, this.forcedColumns});

  final ThemeSectionSchema section;
  final List<ThemeCard> cards;

  /// Set by arrangements whose geometry IS the column count — a split is two halves by
  /// definition, whatever the section's own columns setting says.
  final int? forcedColumns;

  @override
  Widget build(BuildContext context) {
    final settings = section.settings;
    final radius = ThemeStyle.of(context).radius;
    final gap = _kBannerGap;
    final columns = forcedColumns ?? settings.integer('columns', 2).clamp(1, 3);

    final ratio = switch (settings.string('ratio')) {
      'square' => 1.0,
      'portrait' => 0.75,
      _ => _kBannerRatio,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _kBannerSidePadding),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: cards.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          mainAxisSpacing: gap,
          crossAxisSpacing: gap,
          childAspectRatio: ratio,
        ),
        itemBuilder: (context, index) => _CardTile(
          card: cards[index],
          radius: radius,
          overlayText: settings.flag('overlay', true),
          rotateMs: section.settings.integer('rotate_ms', 4000),
        ),
      ),
    );
  }
}

/// One banner: its image, its optional text overlay, and its tap.
class _CardTile extends StatelessWidget {
  const _CardTile({
    required this.card,
    required this.radius,
    required this.overlayText,
    this.rotateMs = 4000,
  });

  final ThemeCard card;
  final double radius;
  final bool overlayText;

  /// The section's image_rotate_interval_ms — only felt by a card carrying extra frames.
  final int rotateMs;

  @override
  Widget build(BuildContext context) {
    final style = ThemeStyle.of(context);
    final image = card.mobileImage;
    final frames = card.frames;
    final hasText = card.title != null || card.subtitle != null;

    final content = Container(
      // A soft ambient shadow separates the banner from the page the way the storefront's card
      // shadows do — depth instead of a flat rectangle, quiet enough to disappear on busy images.
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .10),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (frames.length > 1)
            // The web crossfades a card's extra frames; the same campaign card cycles here.
              _FrameCycler(images: frames, rotateMs: rotateMs.clamp(1500, 20000))
            else if (image != null)
              CustomImageWidget(image: image, fit: BoxFit.cover)
            else if (style.color(card.background) != null)
                ColoredBox(color: style.color(card.background)!)
              else
              // No image and no merchant colour: the approved dark campaign
              // cover (155° violet ramp with a blue glow) instead of a blank.
                const DecoratedBox(
                  decoration: BoxDecoration(gradient: BrandGradients.campaign),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment(0.9, -0.9),
                        radius: 1.1,
                        colors: [Color(0x661F7A55), Color(0x001F7A55)],
                      ),
                    ),
                  ),
                ),

            if (overlayText && hasText) ...[
              // The scrim exists so white overlay text stays legible on a photograph the merchant
              // chose without knowing what would sit on top of it. Taller and softer than before:
              // it fades from readable to invisible instead of cutting a hard band mid-image.
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    stops: [0.0, 0.55, 1.0],
                    colors: [Color(0xB3000000), Color(0x26000000), Color(0x00000000)],
                  ),
                ),
              ),
              Positioned(
                left: 14,
                right: 14,
                bottom: 14,
                child: _CardText(card: card),
              ),
            ],
          ],
        ),
      ),
    );

    if (!BannerSectionRenderer._tappable(card)) return content;

    final tile = InkWell(
      borderRadius: BorderRadius.circular(radius),
      onTap: () => BannerSectionRenderer._tap(context, card),
      child: content,
    );

    // A banner is usually a picture with its words baked into it, so a screen reader finds a
    // tappable rectangle and nothing to call it. The merchant's own title is that name; where the
    // text is drawn on top it is already readable, and labelling twice would repeat it.
    final label = overlayText && hasText
        ? null
        : card.title ?? card.subtitle ?? card.buttonText;

    if (label == null) return tile;

    return Semantics(button: true, label: label, child: tile);
  }
}

class _CardText extends StatelessWidget {
  const _CardText({required this.card});

  final ThemeCard card;

  @override
  Widget build(BuildContext context) {
    final style = ThemeStyle.of(context);
    final colour = style.color(card.textColor) ?? Colors.white;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (card.eyebrow != null)
          Text(
            card.eyebrow!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colour.withValues(alpha: .85),
              fontSize: Dimensions.fontSizeExtraSmall,
              fontWeight: FontWeight.w600,
            ),
          ),
        if (card.title != null)
          Text(
            card.title!,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colour,
              fontSize: Dimensions.fontSizeLarge,
              fontWeight: FontWeight.w700,
            ),
          ),
        if (card.subtitle != null)
          Text(
            card.subtitle!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colour.withValues(alpha: .9),
              fontSize: Dimensions.fontSizeSmall,
            ),
          ),
        if (card.buttonText != null)
        // The merchant's call to action as a real pill — a hero that says "Shop now"
        // instead of hoping the whole rectangle reads as tappable.
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .94),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              card.buttonText!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}


/// A card's extra frames, crossfaded on the section's rotate interval.
///
/// Exists only when there is more than one frame — a single-image card never pays for a timer.
class _FrameCycler extends StatefulWidget {
  const _FrameCycler({required this.images, required this.rotateMs});

  final List<String> images;
  final int rotateMs;

  @override
  State<_FrameCycler> createState() => _FrameCyclerState();
}

class _FrameCyclerState extends State<_FrameCycler> {
  Timer? _timer;
  int _frame = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(Duration(milliseconds: widget.rotateMs), (_) {
      if (mounted) {
        setState(() => _frame = (_frame + 1) % widget.images.length);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 600),
      child: CustomImageWidget(
        key: ValueKey(_frame),
        image: widget.images[_frame % widget.images.length],
        fit: BoxFit.cover,
      ),
    );
  }
}