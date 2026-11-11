import 'dart:async';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:syriapharmacy/theme/custom_theme_colors.dart';
import 'package:provider/provider.dart';
import 'package:syriapharmacy/common/basewidget/product_shimmer_item_widget.dart';
import 'package:syriapharmacy/common/basewidget/product_widget.dart';
import 'package:syriapharmacy/features/dynamic_theme/controllers/dynamic_theme_controller.dart';
import 'package:syriapharmacy/features/dynamic_theme/domain/models/theme_schema.dart';
import 'package:syriapharmacy/features/dynamic_theme/engine/theme_style.dart';
import 'package:syriapharmacy/localization/language_constrants.dart';
import 'package:syriapharmacy/features/dynamic_theme/engine/section_renderer.dart';
import 'package:syriapharmacy/features/dynamic_theme/widgets/theme_carousel_dots.dart';
import 'package:syriapharmacy/features/dynamic_theme/widgets/theme_section_shell.dart';
import 'package:syriapharmacy/features/dynamic_theme/widgets/theme_shop_header.dart';
import 'package:syriapharmacy/features/dynamic_theme/widgets/theme_view_all.dart';
import 'package:syriapharmacy/features/product/domain/models/product_model.dart';
import 'package:syriapharmacy/utill/dimensions.dart';

/// Every product rail, whatever feeds it.
///
/// Five section types share this renderer because the difference between "featured products" and
/// "this category's products" is a URL the server already worked out — the section carries a
/// `source`, the renderer fetches it, and the layout comes from the merchant's `style` setting.
/// That is what makes a second product rail on the home page a builder action rather than a release.
///
/// The rail owns three states and draws all of them: loading (a shimmer the width of the real
/// cards), empty (nothing at all — never an empty titled band), and loaded.
class ProductSectionRenderer extends SectionRenderer {
  const ProductSectionRenderer();

  @override
  List<String> get types => const [
        'product_slider',
        'featured_deal',
        'clearance_sale',
        'deal_of_the_day',
        'flash_deal',
        // One picked scope's products — the server points their source at the right endpoint.
        'category_showcase',
        'brand_showcase',
        'bundle',
        // One shop and what it is selling: the same rail, introduced by the
        // shop it belongs to.
        'vendor_showcase',
      ];

  /// A rail whose source names no endpoint has nothing to fetch and nothing inline to show.
  @override
  bool canRender(ThemeSectionSchema section) => section.source.isApi;

  @override
  Widget? build(BuildContext context, ThemeSectionSchema section) =>
      _ProductSection(section: section);
}

class _ProductSection extends StatefulWidget {
  const _ProductSection({required this.section});

  final ThemeSectionSchema section;

  @override
  State<_ProductSection> createState() => _ProductSectionState();
}

class _ProductSectionState extends State<_ProductSection> {
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

  @override
  Widget build(BuildContext context) {
    final section = widget.section;
    final limit = section.settings.integer('limit', 10).clamp(1, 40);

    // Any deal section whose source carries an end draws the clock — the flash deal ticks to
    // its own end, the deal of the day to midnight — exactly where the storefront draws one.
    final endsAt = section.source.endsAt;
    final showClock = section.settings.flag('countdown', true) &&
        endsAt != null &&
        endsAt.isAfter(DateTime.now());

    // The flash deal's "show the deal's products" toggle: off means the countdown strip alone,
    // as the web renders it — and nothing at all once there is nothing to count to.
    if (!section.settings.flag('products', true)) {
      if (!showClock) return const SizedBox.shrink();
      return ThemeSectionShell(
        section: section,
        trailing: ThemeViewAll.forSection(section),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: Dimensions.paddingSizeDefault),
          child: _DealCountdown(endsAt: endsAt),
        ),
      );
    }

    return Consumer<DynamicThemeController>(
      builder: (context, controller, _) {
        final response = controller.dataFor(section);
        if (response == null) _ensureDataRequested();

        if (response == null || controller.isSectionLoading(section)) {
          return ThemeSectionShell(
            section: section,
            trailing: ThemeViewAll.forSection(section),
            child: const _RailShimmer(),
          );
        }

        final products = _productsFrom(response.response?.data).take(limit).toList();

        // A rail that resolved to nothing disappears entirely. The merchant sees why in the
        // builder's readiness panel; a shopper should never meet a titled band with no contents.
        if (products.isEmpty) return const SizedBox.shrink();

        final Widget content = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (section.type == 'vendor_showcase')
              ThemeShopHeader(section: section),
            if (showClock)
              Padding(
                padding: const EdgeInsets.only(
                  left: Dimensions.paddingSizeDefault,
                  right: Dimensions.paddingSizeDefault,
                  bottom: Dimensions.paddingSizeSmall,
                ),
                child:
                    _DealCountdown(endsAt: endsAt, onGradient: showClock),
              ),
            _layout(section, products),
          ],
        );

        return ThemeSectionShell(
          section: section,
          trailing: ThemeViewAll.forSection(section),
          // A deal with a live clock is the approved flash band: one
          // blue→magenta field carrying the countdown and the white cards.
          child: showClock
              ? Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: Dimensions.paddingSizeSmall),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: BrandGradients.flash,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(
                        vertical: Dimensions.paddingSizeSmall),
                    child: content,
                  ),
                )
              : content,
        );
      },
    );
  }

  Widget _layout(ThemeSectionSchema section, List<Product> products) {
    final showCart = section.settings.flag('add_to_cart', true);
    // A best-selling source is a trending band: its first three cards wear the
    // approved ink «#1/#2/#3» rank pills.
    final bool trending =
        (section.source.endpoint ?? '').contains('best-selling') ||
            (section.source.endpoint ?? '').contains('best_selling');
    return switch (productLayoutFor(section.type, section.variant)) {
      ProductLayout.grid =>
        _Grid(section: section, products: products, trending: trending),
      ProductLayout.list => _List(products: products, showCart: showCart),
      ProductLayout.carousel => _Carousel(section: section, products: products),
      ProductLayout.spotlight =>
        _Spotlight(products: products, showCart: showCart),
      ProductLayout.rail =>
        _Rail(products: products, showCart: showCart, trending: trending),
    };
  }

  /// Products out of whatever shape the endpoint returned.
  ///
  /// The catalogue endpoints are consistent today — `{total_size, products: [...]}` — but this
  /// renderer follows a URL the server chose, and one endpoint returning a bare list must cost
  /// that rail and nothing more. Every branch that cannot produce products produces none.
  List<Product> _productsFrom(dynamic data) {
    try {
      final raw = switch (data) {
        {'products': final List<dynamic> items} => items,
        List<dynamic> items => items,
        {'data': final List<dynamic> items} => items,
        // Deal-of-the-day answers with ONE formatted product, not a wrapper —
        // a bare object with an id is that product.
        Map<String, dynamic> single when single.containsKey('id') => [single],
        _ => const <dynamic>[],
      };

      return raw
          .whereType<Map<String, dynamic>>()
          .map(Product.fromJson)
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }
}

/// Every shape a row of products can take.
enum ProductLayout { rail, grid, list, carousel, spotlight }

/// The shape a product section's display style asks for.
///
/// Most of these types share one vocabulary — rail, grid, list, carousel, spotlight — and two do
/// not. A flash deal speaks of strips and banners; a deal of the day, which is usually ONE product,
/// speaks of splits and cards. Both were read through the shared switch, which meant every style
/// they offer except `grid` fell through to the same rail while the website drew three different
/// things.
ProductLayout productLayoutFor(String type, String? variant) {
  return switch (type) {
    // A bundle is a set bought together; it is shown together, whatever else is set.
    'bundle' => ProductLayout.grid,
    'vendor_showcase' => variant == 'grid' ? ProductLayout.grid : ProductLayout.rail,
    'flash_deal' => switch (variant) {
        'grid' => ProductLayout.grid,
        'banner' => ProductLayout.spotlight,
        _ => ProductLayout.rail,
      },
    'deal_of_the_day' => switch (variant) {
        'card' => ProductLayout.grid,
        'banner' => ProductLayout.carousel,
        _ => ProductLayout.spotlight,
      },
    _ => switch (variant) {
        'grid' => ProductLayout.grid,
        'list' => ProductLayout.list,
        'carousel' => ProductLayout.carousel,
        'spotlight' => ProductLayout.spotlight,
        _ => ProductLayout.rail,
      },
  };
}

/// A placeholder shaped like the rail it replaces.
///
/// The app's grid shimmer is the wrong shape here — dropped into a rail's height it overflows,
/// which turns a loading state into a visible layout error. Matching the real cards' geometry is
/// also what stops the page jumping when the products arrive.
class _RailShimmer extends StatelessWidget {
  const _RailShimmer();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 310,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
        itemCount: 4,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(right: Dimensions.paddingSizeSmall),
          child: const SizedBox(width: 160, child: ProductShimmerItemWidget()),
        ),
      ),
    );
  }
}

/// The default: a horizontally scrolling row of cards.
class _Rail extends StatelessWidget {
  const _Rail({required this.products, this.showCart = true, this.trending = false});

  final bool trending;

  final List<Product> products;
  final bool showCart;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 310,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
        itemCount: products.length,
        itemBuilder: (context, index) => SizedBox(
          width: 160,
          child: ProductWidget(
              productModel: products[index],
              showCartButton: showCart,
              rank: trending && index < 3 ? index + 1 : null),
        ),
      ),
    );
  }
}

/// A fixed grid. The merchant's column count is capped at three — four product cards across a
/// phone leaves no room for a price and a name.
class _Grid extends StatelessWidget {
  const _Grid({required this.section, required this.products, this.trending = false});

  final bool trending;

  final ThemeSectionSchema section;
  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    final columns = section.settings.integer('columns', 2).clamp(1, 3);
    final showCart = section.settings.flag('add_to_cart', true);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
      itemCount: products.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        childAspectRatio: 0.52,
        mainAxisSpacing: Dimensions.paddingSizeSmall,
        crossAxisSpacing: Dimensions.paddingSizeSmall,
      ),
      itemBuilder: (context, index) => ProductWidget(
          productModel: products[index],
          showCartButton: showCart,
          rank: trending && index < 3 ? index + 1 : null),
    );
  }
}

/// One large card at a time, swiping — the builder's "carousel" style. Autoplay, interval and the
/// pagination dots come from the same settings the web honours.
class _Carousel extends StatefulWidget {
  const _Carousel({required this.section, required this.products});

  final ThemeSectionSchema section;
  final List<Product> products;

  @override
  State<_Carousel> createState() => _CarouselState();
}

class _CarouselState extends State<_Carousel> {
  int _slide = 0;

  @override
  Widget build(BuildContext context) {
    final settings = widget.section.settings;
    final products = widget.products;
    final showDots = settings.flag('pagination', false) && products.length > 1;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CarouselSlider.builder(
          itemCount: products.length,
          itemBuilder: (context, index, _) => Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: Dimensions.paddingSizeExtraSmall),
            child: ProductWidget(
                productModel: products[index],
                showCartButton: settings.flag('add_to_cart', true),
                style: ProductCardStyle.large),
          ),
          options: CarouselOptions(
            height: 360,
            viewportFraction: 0.62,
            enlargeCenterPage: true,
            enlargeFactor: 0.18,
            autoPlay: settings.flag('autoplay', false) && products.length > 1,
            autoPlayInterval: Duration(
              milliseconds: settings.integer('interval', 4000).clamp(2000, 20000),
            ),
            enableInfiniteScroll: products.length > 2,
            onPageChanged:
                showDots ? (index, _) => setState(() => _slide = index) : null,
          ),
        ),
        if (showDots) ...[
          const SizedBox(height: Dimensions.paddingSizeSmall),
          ThemeCarouselDots(count: products.length, activeIndex: _slide),
        ],
      ],
    );
  }
}

/// The first product large, the rest in a rail below — the builder's "spotlight" style, for a
/// section whose first pick is the point (a deal of the day, a hero product).
class _Spotlight extends StatelessWidget {
  const _Spotlight({required this.products, this.showCart = true});

  final List<Product> products;
  final bool showCart;

  @override
  Widget build(BuildContext context) {
    final rest = products.skip(1).toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
          child: SizedBox(
            height: 360,
            child: ProductWidget(
                productModel: products.first,
                productNameLine: 2,
                showCartButton: showCart,
                style: ProductCardStyle.large),
          ),
        ),
        if (rest.isNotEmpty) ...[
          const SizedBox(height: Dimensions.paddingSizeSmall),
          _Rail(products: rest, showCart: showCart),
        ],
      ],
    );
  }
}

/// A vertical list, for a rail the merchant wants read rather than scanned.
class _List extends StatelessWidget {
  const _List({required this.products, this.showCart = true});

  final List<Product> products;
  final bool showCart;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
      itemCount: products.length,
      itemBuilder: (context, index) => ProductWidget(
          productModel: products[index],
          showCartButton: showCart,
          style: ProductCardStyle.horizontal),
    );
  }
}


/// The clock that makes a flash deal a flash deal.
///
/// The web draws one; the app was showing the same section as an ordinary product rail — the one
/// piece of information that creates the urgency was the piece missing. Ticks itself, kills its
/// own timer, and quietly disappears the second the deal is over.
class _DealCountdown extends StatefulWidget {
  const _DealCountdown({required this.endsAt, this.onGradient = false});

  final DateTime endsAt;

  /// True when the strip already sits on the flash-gradient field — it goes
  /// transparent instead of stacking a second gradient.
  final bool onGradient;

  @override
  State<_DealCountdown> createState() => _DealCountdownState();
}

class _DealCountdownState extends State<_DealCountdown> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final left = widget.endsAt.difference(DateTime.now());
    if (left.isNegative) return const SizedBox.shrink();

    final style = ThemeStyle.of(context);
    final days = left.inDays;
    final units = <String>[
      if (days > 0) days.toString().padLeft(2, '0'),
      (left.inHours % 24).toString().padLeft(2, '0'),
      (left.inMinutes % 60).toString().padLeft(2, '0'),
      (left.inSeconds % 60).toString().padLeft(2, '0'),
    ];

    // The urgency band the big marketplaces taught every shopper to read: a saturated strip,
    // a bolt, "ends in", and white tabular digits in dark cells. Quiet chips do not say HURRY.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: widget.onGradient
          ? null
          : BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  style.primary,
                  Color.lerp(style.primary, Colors.black, .25)!
                ],
                begin: AlignmentDirectional.centerStart,
                end: AlignmentDirectional.centerEnd,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: .22),
            ),
            child: const Icon(Icons.bolt_rounded, size: 17, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              getTranslated('ends_in', context) ?? 'Ends in',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
                letterSpacing: .2,
              ),
            ),
          ),
          for (var index = 0; index < units.length; index++) ...[
            if (index > 0)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 2),
                child: Text(':',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13)),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: .28),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                units[index],
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
