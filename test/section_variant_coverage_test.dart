import 'package:flutter_test/flutter_test.dart';
import 'package:syriapharmacy/features/dynamic_theme/renderers/banner_section_renderer.dart';
import 'package:syriapharmacy/features/dynamic_theme/renderers/content_section_renderer.dart';
import 'package:syriapharmacy/features/dynamic_theme/renderers/product_section_renderer.dart';
import 'package:syriapharmacy/features/dynamic_theme/renderers/taxonomy_section_renderer.dart';
import 'package:syriapharmacy/features/dynamic_theme/renderers/utility_section_renderer.dart';

/// Every display style the builder offers has to draw something different.
///
/// The bug this exists for: the tile section branched on a style called `bubbles`, and the builder
/// has never offered that word — its options are tiles, circles and rail. So a merchant choosing
/// "circles" got the grid, and would have kept getting the grid forever, because nothing on either
/// side could notice. The web honoured the choice; the phone silently did not.
///
/// The lists below are copied from `SectionRegistry`'s options for each type. They are the contract
/// between the two codebases, and a copy is honest here: the app ships independently of the server
/// and has to state what it believes the server offers, so that a change on either side shows up as
/// a failing test rather than as a style that quietly stops working.
void main() {
  group('content section display styles', () {
    // type -> the display styles SectionRegistry offers for it, first one being its default.
    const offered = <String, List<String>>{
      'faq': ['panel', 'two_column', 'cards'],
      'testimonials': ['cards', 'wall', 'compact'],
      'interest_tiles': ['tiles', 'circles', 'rail'],
      'usp_strip': ['boxed', 'plain', 'dark'],
      'stats_bar': ['boxed', 'dark'],
    };

    test('each style maps to a layout of its own', () {
      offered.forEach((type, styles) {
        final layouts = styles.map((style) => contentLayoutFor(type, style)).toList();

        expect(
          layouts.toSet(),
          hasLength(styles.length),
          reason: '$type offers ${styles.length} styles ($styles) but draws '
              '${layouts.toSet().length} layouts — one of them does nothing',
        );
      });
    });

    test('the default style is what an unset one falls back to', () {
      // A section composed before a style existed, or by an import that dropped it, must render
      // the way the builder says that type renders by default — not into some other branch.
      offered.forEach((type, styles) {
        expect(contentLayoutFor(type, null), contentLayoutFor(type, styles.first),
            reason: type);
      });
    });

    test('a style from a newer server falls back rather than drawing nothing', () {
      for (final type in offered.keys) {
        expect(() => contentLayoutFor(type, 'holographic'), returnsNormally, reason: type);
        expect(contentLayoutFor(type, 'holographic'), contentLayoutFor(type, offered[type]!.first),
            reason: type);
      }
    });

    test('a type this renderer does not know still resolves', () {
      // The registry decides which types reach this renderer; a new one must not throw here
      // before anybody has written its branch.
      expect(contentLayoutFor('some_new_type', null), ContentLayout.iconBoxed);
    });
  });

  group('taxonomy section display styles', () {
    // Three types, three vocabularies for the same shelf — which is how the brand slider's three
    // styles all drew the same rail: not one of its words appeared in the switch that read them.
    const offered = <String, List<String>>{
      'category_grid': ['circles', 'cards', 'tiles', 'chips'],
      'brand_slider': ['marquee', 'grid', 'story'],
      'vendor_slider': ['cards', 'rail', 'compact'],
    };

    test('each style maps to a layout of its own', () {
      offered.forEach((type, styles) {
        final layouts = styles.map((style) => taxonomyLayoutFor(type, style)).toList();

        expect(
          layouts.toSet(),
          hasLength(styles.length),
          reason: '$type offers ${styles.length} styles ($styles) but draws '
              '${layouts.toSet().length} layouts — one of them does nothing',
        );
      });
    });

    test('the default style is what an unset one falls back to', () {
      offered.forEach((type, styles) {
        expect(taxonomyLayoutFor(type, null), taxonomyLayoutFor(type, styles.first),
            reason: type);
      });
    });

    test('a category grid is the fallback for a type with no branch of its own', () {
      expect(taxonomyLayoutFor('some_new_taxonomy', null), TaxonomyLayout.circleRail);
    });
  });

  group('product row display styles', () {
    const offered = <String, List<String>>{
      'product_slider': ['rail', 'grid', 'carousel', 'spotlight', 'list'],
      'category_showcase': ['rail', 'grid'],
      'brand_showcase': ['rail', 'grid'],
      'featured_deal': ['rail', 'grid'],
      'clearance_sale': ['rail', 'grid'],
      'flash_deal': ['strip', 'banner', 'grid'],
      'deal_of_the_day': ['split', 'banner', 'card'],
    };

    test('each style maps to a shape of its own', () {
      offered.forEach((type, styles) {
        final layouts = styles.map((style) => productLayoutFor(type, style)).toList();

        expect(layouts.toSet(), hasLength(styles.length),
            reason: '$type offers $styles but draws ${layouts.toSet().length} shapes');
      });
    });

    test('the default style is what an unset one falls back to', () {
      offered.forEach((type, styles) {
        expect(productLayoutFor(type, null), productLayoutFor(type, styles.first), reason: type);
      });
    });

    test('a bundle is shown together whatever else is set', () {
      // The products in a bundle are bought as a set; a rail that hides half of them behind a
      // swipe is the one shape that misrepresents what the section is.
      for (final style in [null, 'rail', 'list', 'carousel']) {
        expect(productLayoutFor('bundle', style), ProductLayout.grid);
      }
    });
  });

  group('utility section display styles', () {
    const offered = <String, List<String>>{
      'branches': ['cards', 'list'],
      'shipping_cutoff': ['strip', 'card'],
      'coupon_strip': ['tickets', 'cards', 'strip'],
    };

    test('each style maps to a layout of its own', () {
      offered.forEach((type, styles) {
        final layouts = styles.map((style) => utilityLayoutFor(type, style)).toList();

        expect(layouts.toSet(), hasLength(styles.length),
            reason: '$type offers $styles but draws ${layouts.toSet().length} layouts');
      });
    });

    test('the default style is what an unset one falls back to', () {
      offered.forEach((type, styles) {
        expect(utilityLayoutFor(type, null), utilityLayoutFor(type, styles.first), reason: type);
      });
    });

    test('the types with one look here ignore whatever style arrives', () {
      // Stories takes its own two styles inside its widget; tabs and before/after have one look.
      for (final style in [null, 'cards', 'nonsense']) {
        expect(utilityLayoutFor('stories', style), UtilityLayout.stories);
        expect(utilityLayoutFor('before_after', style), UtilityLayout.beforeAfter);
        expect(utilityLayoutFor('product_tabs', style), UtilityLayout.tabs);
      }
    });
  });

  group('banner section arrangements', () {
    const offered = <String, List<String>>{
      'store_banner': ['carousel', 'grid', 'mosaic', 'strip', 'split', 'swipe'],
      'promotional_banner': ['tiles', 'rail', 'overlap', 'swipe'],
    };

    test('each arrangement is its own', () {
      offered.forEach((type, styles) {
        final layouts = styles.map((style) => bannerLayoutFor(type, style)).toList();

        expect(
          layouts.toSet(),
          hasLength(styles.length),
          reason: '$type offers ${styles.length} arrangements ($styles) but draws '
              '${layouts.toSet().length} — one of them does nothing',
        );
      });
    });

    test('the types with one look ignore whatever style arrives', () {
      // A hero is a slideshow and a strip is a strip. A stray style on one of them must not be
      // able to turn it into something else.
      for (final style in [null, 'grid', 'mosaic', 'nonsense']) {
        expect(bannerLayoutFor('hero_banner', style), BannerLayout.carousel);
        expect(bannerLayoutFor('banner_strip', style), BannerLayout.strip);
        expect(bannerLayoutFor('banner_mosaic', style), BannerLayout.mosaic);
        expect(bannerLayoutFor('banner_mosaic', style, display: 'swipe'),
            BannerLayout.swipe,
            reason: 'the mosaic\'s display=swipe follows the web to a row');
      }
    });

    test('the default arrangement is what an unset one falls back to', () {
      offered.forEach((type, styles) {
        expect(bannerLayoutFor(type, null), bannerLayoutFor(type, styles.first), reason: type);
      });
    });
  });
}
