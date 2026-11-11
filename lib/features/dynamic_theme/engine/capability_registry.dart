/// What this build can actually draw.
///
/// The server decides what to send by asking this question, not by comparing version numbers. A
/// version comparison is a guess about what a binary contains, and it is wrong the first time
/// someone staggers a rollout, side-loads a build, or ships a hotfix that adds a renderer without
/// moving the marketing version. The list below is the truth, because it is derived from the
/// renderers that are actually registered.
///
/// Two numbers travel with it:
///   [engineVersion]  the renderer generation — bumped when the engine gains a new primitive that
///                    older builds cannot draw at all.
///   [schemaVersion]  the payload shape this build understands — bumped when the contract changes
///                    meaning, not when a field is added.
///
/// Both are sent as headers so a CDN can vary on them and two different builds never share a
/// cached page.
library;

class ThemeCapabilities {
  const ThemeCapabilities._();

  /// The payload contract this build parses. Must match the server's `schema_version`; a server
  /// that reports a HIGHER one is not an error — the parser ignores what it does not know.
  static const int schemaVersion = 1;

  /// The renderer generation compiled into this build.
  static const int engineVersion = 1;

  /// Header names the server reads to negotiate. Values are computed from the live registry, so
  /// deleting a renderer automatically stops the server sending its sections.
  static const String componentsHeader = 'X-UI-Components';
  static const String engineHeader = 'X-UI-Engine';
  static const String schemaHeader = 'X-UI-Schema';

  /// Section types this build renders, in a stable order.
  ///
  /// Kept as a const list rather than read from the registry at call time so it can be asserted
  /// against the registry in a test: a renderer registered but not declared would never be sent,
  /// and a type declared but not registered would arrive with nothing to draw it.
  static const List<String> components = [
    // Banner family — one renderer, several arrangements, all fed by `cards`.
    'hero_banner',
    'promotional_banner',
    'split_banner',
    'banner_mosaic',
    'banner_strip',
    'store_banner',

    // Product family — one renderer, fed by the section's `source`.
    'product_slider',
    'featured_deal',
    'clearance_sale',
    'deal_of_the_day',
    'flash_deal',
    'category_showcase',
    'brand_showcase',
    'bundle',
    'product_tabs',
    'vendor_showcase',

    // Taxonomy rails.
    'category_grid',
    'brand_slider',
    'vendor_slider',

    // Content and chrome — everything they need is inline in the payload.
    'announcement_bar',
    'usp_strip',
    'stats_bar',
    'testimonials',
    'faq',
    'interest_tiles',
    'price_tiles',
    'app_download',

    // Utility — storytelling, countdowns, coupons, merchant HTML.
    'stories',
    'branches',
    'before_after',
    'shipping_cutoff',
    'coupon_strip',
    'custom_html',

    // Layout primitives.
    'spacer',
  ];

  /// The headers a theme request carries.
  static Map<String, String> get headers => {
        componentsHeader: components.join(','),
        engineHeader: '$engineVersion',
        schemaHeader: '$schemaVersion',
      };

  static bool supports(String type) => components.contains(type);
}
