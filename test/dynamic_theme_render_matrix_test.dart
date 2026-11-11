import 'package:flutter/material.dart';
import 'package:syriapharmacy/theme/custom_theme_colors.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syriapharmacy/data/model/api_response.dart';
import 'package:syriapharmacy/features/dynamic_theme/controllers/dynamic_theme_controller.dart';
import 'package:syriapharmacy/features/dynamic_theme/domain/models/theme_schema.dart';
import 'package:syriapharmacy/features/dynamic_theme/domain/services/dynamic_theme_service_interface.dart';
import 'package:syriapharmacy/features/dynamic_theme/engine/section_renderer_registry.dart';
import 'package:syriapharmacy/features/dynamic_theme/engine/theme_engine.dart';
import 'package:syriapharmacy/features/auth/controllers/auth_controller.dart';
import 'package:syriapharmacy/features/auth/domain/services/auth_service_interface.dart';
import 'package:syriapharmacy/features/cart/controllers/cart_controller.dart';
import 'package:syriapharmacy/features/product_details/controllers/product_details_controller.dart';
import 'package:syriapharmacy/features/product_details/domain/services/product_details_service_interface.dart';
import 'package:syriapharmacy/features/search_product/controllers/search_product_controller.dart';
import 'package:syriapharmacy/features/search_product/domain/services/search_product_service_interface.dart';
import 'package:syriapharmacy/features/splash/controllers/splash_controller.dart';
import 'package:syriapharmacy/features/wishlist/controllers/wishlist_controller.dart';
import 'package:syriapharmacy/localization/controllers/localization_controller.dart';
import 'package:syriapharmacy/theme/controllers/theme_controller.dart';

/// Every app-safe section type × every display style the builder offers for it, rendered at a
/// phone width, in RTL — the way this store's shoppers actually hold it.
///
/// The assertion is deliberate: `tester.takeException()` — a RenderFlex overflow, a failed layout
/// or anything a renderer throws surfaces as an exception in the test binding, so "renders
/// cleanly" is provable here without an emulator. Where a style has visible proof (a title, a
/// chip, a product name) the test looks for it too.
class _FakeThemeService implements DynamicThemeServiceInterface {
  @override
  Future<void> dropCachedPayloads() async {}

  @override
  Future<ThemeRevision> getRevision() async => ThemeRevision.none;

  @override
  Future<ApiResponseModel<ThemePayload?>> getPayload({
    String page = 'home',
    String? knownChecksum,
  }) async =>
      ApiResponseModel.withSuccess(null);

  @override
  Future<ThemePayload?> getCachedPayload({String page = 'home'}) async => null;

  /// Answers each section's data source with the shape the real endpoint uses.
  @override
  Future<ApiResponseModel> getSectionData(SectionSource source) async {
    final endpoint = source.endpoint ?? '';

    if (endpoint.contains('deal-of-the-day')) {
      // The real endpoint answers with ONE formatted product, not a wrapper.
      return ApiResponseModel.withSuccess(_FakeResponse(_product(1, 'Deal of the day')));
    }
    if (endpoint.contains('/products') || endpoint.contains('deals') || endpoint.contains('flash')) {
      return ApiResponseModel.withSuccess(_FakeResponse({
        'total_size': 4,
        'products': [for (var i = 1; i <= 4; i++) _product(i, 'Product $i')],
      }));
    }
    if (endpoint.contains('categories')) {
      return ApiResponseModel.withSuccess(_FakeResponse([
        for (var i = 1; i <= 6; i++) {'id': i, 'name': 'فئة $i', 'slug': 'cat-$i'},
      ]));
    }
    if (endpoint.contains('brands')) {
      return ApiResponseModel.withSuccess(_FakeResponse([
        for (var i = 1; i <= 5; i++) {'id': i, 'name': 'Brand $i', 'slug': 'brand-$i'},
      ]));
    }
    if (endpoint.contains('coupon')) {
      return ApiResponseModel.withSuccess(_FakeResponse({
        'coupons': [
          {'code': 'SAVE10', 'discount': 10, 'discount_type': 'percentage', 'title': 'خصم ١٠٪'},
          {'code': 'FREE5K', 'discount': 5000, 'discount_type': 'amount', 'title': ''},
        ],
      }));
    }
    if (endpoint.contains('seller')) {
      return ApiResponseModel.withSuccess(_FakeResponse({
        'sellers': [
          for (var i = 1; i <= 4; i++)
            {'id': i, 'shop': {'id': i, 'name': 'متجر $i', 'slug': 'shop-$i'}},
        ],
      }));
    }
    return ApiResponseModel.withError('no_fixture_for_$endpoint');
  }

  static Map<String, dynamic> _product(int id, String name) => {
        'id': id,
        'name': name,
        'slug': 'product-$id',
        'unit_price': 1500,
        'discount': 0,
        'discount_type': 'flat',
        'current_stock': 10,
        'min_qty': 1,
        'reviews_count': 3,
        'rating': const [],
      };
}

/// Loose fakes for the service interfaces the product card's providers require.
///
/// `noSuchMethod` answers null for anything not overridden: the card's BUILD path only touches a
/// handful of members, and a test that had to implement forty unrelated methods per interface
/// would drown the thing it verifies. A member the build actually calls gets a real override —
/// discovered by the test failing, which is exactly the coverage wanted.
class _LooseAuthService implements AuthServiceInterface {
  @override
  bool isLoggedIn() => false;

  @override
  Future<dynamic> getGuestId() async => '1';

  @override
  String? getGuestIdToken() => '1';

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _LooseProductDetailsService implements ProductDetailsServiceInterface {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _LooseSearchService implements SearchProductServiceInterface {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

/// The smallest object the repository layer's Response contract needs here.
class _FakeResponse {
  _FakeResponse(this.data);
  final dynamic data;
  final int? statusCode = 200;
}

ThemeSectionSchema _section(
  String type, {
  Map<String, dynamic> settings = const {},
  List<Map<String, dynamic>> blocks = const [],
  List<Map<String, dynamic>>? cards,
  Map<String, dynamic>? source,
}) =>
    ThemeSectionSchema.fromJson({
      'uuid': 'u-$type-${settings['style'] ?? settings['layout'] ?? 'default'}',
      'id': 1,
      'type': type,
      'settings': {'title': 'عنوان القسم', ...settings},
      'blocks': [
        for (var i = 0; i < blocks.length; i++)
          {'id': i + 1, 'type': blocks[i]['type'] ?? 'usp', 'settings': blocks[i]},
      ],
      if (cards != null) 'cards': cards,
      'source': source,
    });

List<Map<String, dynamic>> _cards(int count) => [
      for (var i = 1; i <= count; i++)
        {'title': 'بانر $i', 'subtitle': 'وصف قصير', 'action': null},
    ];

const _productsSource = {
  'kind': 'api',
  'endpoint': '/api/v1/products/featured',
  'params': {'limit': 4, 'offset': 1},
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  late SectionRendererRegistry registry;
  late DynamicThemeController controller;

  setUp(() {
    registry = ThemeEngine.buildRegistry();
    controller =
        DynamicThemeController(dynamicThemeServiceInterface: _FakeThemeService());
  });

  Future<void> pumpSection(
    WidgetTester tester,
    ThemeSectionSchema section, {
    TextDirection direction = TextDirection.rtl,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider<DynamicThemeController>.value(value: controller),
        Provider<SectionRendererRegistry>.value(value: registry),
        ChangeNotifierProvider(
            create: (_) =>
                LocalizationController(sharedPreferences: prefs, dioClient: null)),
        ChangeNotifierProvider(
            create: (_) => ThemeController(sharedPreferences: prefs)),
        ChangeNotifierProvider(
            create: (_) => SplashController(splashServiceInterface: null)),
        ChangeNotifierProvider(
            create: (_) => AuthController(authServiceInterface: _LooseAuthService())),
        ChangeNotifierProvider(
            create: (_) => WishListController(wishlistServiceInterface: null)),
        ChangeNotifierProvider(
            create: (_) => CartController(cartServiceInterface: null)),
        ChangeNotifierProvider(
            create: (_) => ProductDetailsController(
                productDetailsServiceInterface: _LooseProductDetailsService())),
        ChangeNotifierProvider(
            create: (_) => SearchProductController(
                searchProductServiceInterface: _LooseSearchService())),
      ],
      child: MaterialApp(
        home: Directionality(
          textDirection: direction,
          child: Scaffold(
            body: SingleChildScrollView(
              child: Builder(
                builder: (context) =>
                    registry.render(context, section) ?? const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      ),
    ));

    // Fixed pumps, never pumpAndSettle: shimmer and carousel animations are infinite by design
    // and would hang a settle. Two frames deliver the post-frame data fetch and its rebuild.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 400));
  }

  group('render matrix — every type × every builder style, phone width, RTL', () {
    testWidgets('product sections: rail, grid, list, carousel, spotlight', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      for (final style in ['rail', 'grid', 'list', 'carousel', 'spotlight']) {
        await pumpSection(
          tester,
          _section('product_slider',
              settings: {'style': style, 'limit': 4}, source: _productsSource),
        );

        expect(tester.takeException(), isNull, reason: 'product_slider/$style threw');
        expect(find.text('Product 1'), findsWidgets,
            reason: 'product_slider/$style rendered no product');
      }
    });

    testWidgets('deal of the day parses its single-product answer', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await pumpSection(
        tester,
        _section('deal_of_the_day', source: const {
          'kind': 'api',
          'endpoint': '/api/v1/dealsoftheday/deal-of-the-day',
          'params': {},
        }),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Deal of the day'), findsWidgets,
          reason: 'the single-product response must render, not vanish');
    });

    testWidgets('category styles: circles, cards, tiles, chips', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      for (final style in ['circles', 'cards', 'tiles', 'chips']) {
        await pumpSection(
          tester,
          _section('category_grid', settings: {
            'style': style,
            'columns': 3,
          }, source: const {
            'kind': 'api',
            'endpoint': '/api/v1/categories',
            'params': {},
          }),
        );

        expect(tester.takeException(), isNull, reason: 'category_grid/$style threw');
        expect(find.text('فئة 1'), findsWidgets,
            reason: 'category_grid/$style rendered no category');
      }
    });

    testWidgets('brand styles: rail, circles, tiles — vendor styles: cards, rail, compact',
        (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      for (final style in ['rail', 'circles', 'tiles']) {
        await pumpSection(
          tester,
          _section('brand_slider', settings: {'style': style}, source: const {
            'kind': 'api',
            'endpoint': '/api/v1/brands',
            'params': {},
          }),
        );
        expect(tester.takeException(), isNull, reason: 'brand_slider/$style threw');
        expect(find.text('Brand 1'), findsWidgets);
      }

      for (final style in ['cards', 'rail', 'compact']) {
        await pumpSection(
          tester,
          _section('vendor_slider', settings: {'style': style}, source: const {
            'kind': 'api',
            'endpoint': '/api/v1/seller/list/all',
            'params': {},
          }),
        );
        expect(tester.takeException(), isNull, reason: 'vendor_slider/$style threw');
        expect(find.text('متجر 1'), findsWidgets);
      }
    });

    testWidgets('banner arrangements: hero, strip, mosaic, grids, splits, store layouts',
        (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      final cases = <(String, Map<String, dynamic>)>[
        ('hero_banner', {'autoplay': false}),
        // A merchant-set height BELOW the phone floor: clamp throws when its bounds cross, and
        // height 100 in the builder was taking the whole home page down with an ArgumentError.
        ('hero_banner', {'autoplay': false, 'height': 100}),
        ('hero_banner', {'autoplay': false, 'height': 90}),
        ('banner_strip', {}),
        ('banner_mosaic', {}),
        ('split_banner', {}),
        ('promotional_banner', {'style': 'tiles', 'ratio': 'wide', 'columns': 2}),
        ('promotional_banner', {'style': 'tiles', 'ratio': 'square', 'columns': 3}),
        ('promotional_banner', {'style': 'rail'}),
        ('promotional_banner', {'style': 'overlap'}),
        for (final layout in ['carousel', 'grid', 'mosaic', 'strip', 'split'])
          ('store_banner', {'layout': layout, 'autoplay': false}),
      ];

      for (final (type, settings) in cases) {
        await pumpSection(tester, _section(type, settings: settings, cards: _cards(3)));

        expect(tester.takeException(), isNull,
            reason: '$type/${settings['style'] ?? settings['layout'] ?? 'default'} threw');
        expect(find.textContaining('بانر'), findsWidgets,
            reason: '$type rendered no card');
      }

      // A mosaic with a single card must not divide by its missing neighbours.
      await pumpSection(tester, _section('banner_mosaic', cards: _cards(1)));
      expect(tester.takeException(), isNull);
    });

    testWidgets('content sections: every dress and arrangement', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      final uspBlocks = [
        for (var i = 1; i <= 4; i++)
          {'type': 'usp', 'title': 'ميزة $i', 'subtitle': 'تفصيل الميزة'},
      ];

      final cases = <(String, Map<String, dynamic>, List<Map<String, dynamic>>)>[
        for (final style in ['boxed', 'plain', 'dark'])
          ('usp_strip', {'style': style}, uspBlocks),
        for (final style in ['boxed', 'dark'])
          ('stats_bar', {'style': style}, [
            for (var i = 1; i <= 3; i++)
              {'type': 'stat', 'value': '${i * 100}+', 'label': 'إحصائية $i'},
          ]),
        for (final style in ['cards', 'compact', 'wall'])
          ('testimonials', {'style': style}, [
            for (var i = 1; i <= 3; i++)
              {'type': 'comparison', 'title': 'عميل $i', 'body': 'رأي جميل في المتجر رقم $i'},
          ]),
        ('faq', {}, [
          for (var i = 1; i <= 3; i++)
            {'type': 'qa', 'title': 'سؤال $i؟', 'body': 'الجواب رقم $i'},
        ]),
        for (final style in ['cards', 'bubbles'])
          ('interest_tiles', {'style': style, 'columns': 3}, [
            for (var i = 1; i <= 3; i++) {'type': 'interest', 'title': 'اهتمام $i'},
          ]),
        ('price_tiles', {'columns': 2}, [
          for (var i = 1; i <= 2; i++)
            {'type': 'price_band', 'title': 'أقل من ${i * 5000}'},
        ]),
        ('app_download', {}, [
          {'type': 'apps', 'title': 'حمّل التطبيق', 'subtitle': 'App Store'},
        ]),
      ];

      for (final (type, settings, blocks) in cases) {
        await pumpSection(tester, _section(type, settings: settings, blocks: blocks));
        expect(tester.takeException(), isNull,
            reason: '$type/${settings['style'] ?? 'default'} threw');
      }
    });

    testWidgets('parity newcomers: showcases, bundle, tabs, stories, branches, before/after, cutoff, coupons, html',
        (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      // The product-scoped trio rides the product renderer with a server-pointed source.
      for (final type in ['category_showcase', 'brand_showcase', 'bundle']) {
        await pumpSection(tester, _section(type, settings: {'limit': 4}, source: _productsSource));
        expect(tester.takeException(), isNull, reason: '$type threw');
        expect(find.text('Product 1'), findsWidgets, reason: '$type rendered no product');
      }

      // Tabs: two sources, first tab fetches on build.
      await pumpSection(
        tester,
        ThemeSectionSchema.fromJson({
          'uuid': 'u-tabs',
          'id': 1,
          'type': 'product_tabs',
          'settings': {'title': 'تبويبات', 'limit': 4},
          'blocks': [
            {'id': 1, 'type': 'tab', 'settings': {'title': 'الأحدث'}},
            {'id': 2, 'type': 'tab', 'settings': {'title': 'الأفضل'}},
          ],
          'source': {
            'kind': 'api',
            'tabs': [_productsSource, _productsSource],
          },
        }),
      );
      expect(tester.takeException(), isNull, reason: 'product_tabs threw');
      expect(find.text('الأحدث'), findsOneWidget);
      expect(find.text('Product 1'), findsWidgets, reason: 'active tab rendered no product');

      for (final style in ['bubbles', 'cards']) {
        await pumpSection(tester, _section('stories', settings: {'style': style}, blocks: [
          for (var i = 1; i <= 3; i++)
            {'type': 'story', 'title': 'قصة $i', 'image': 'https://x.test/s$i.png'},
        ]));
        expect(tester.takeException(), isNull, reason: 'stories/$style threw');
        expect(find.text('قصة 1'), findsOneWidget);
      }

      await pumpSection(tester, _section('branches', blocks: [
        {'type': 'branch', 'title': 'فرع دمشق', 'address': 'شارع الثورة', 'hours': '9-22', 'phone': '011223344'},
        {'type': 'branch', 'title': 'فرع حلب', 'address': 'العزيزية'},
      ]));
      expect(tester.takeException(), isNull, reason: 'branches threw');
      expect(find.text('فرع دمشق'), findsOneWidget);
      expect(find.text('011223344'), findsOneWidget);

      await pumpSection(tester, _section('before_after', blocks: [
        {'type': 'comparison', 'title': 'نتيجة العلاج', 'image': 'https://x.test/b.png', 'after': 'https://x.test/a.png'},
      ]));
      expect(tester.takeException(), isNull, reason: 'before_after threw');
      expect(find.text('نتيجة العلاج'), findsOneWidget);

      for (final style in ['strip', 'card']) {
        await pumpSection(tester,
            _section('shipping_cutoff', settings: {'cutoff': '16:00', 'style': style, 'subtitle': 'اطلب الآن'}));
        expect(tester.takeException(), isNull, reason: 'shipping_cutoff/$style threw');
        expect(find.text('اطلب الآن'), findsWidgets);
      }

      await pumpSection(tester, _section('coupon_strip', source: const {
        'kind': 'api',
        'endpoint': '/api/v1/coupon/list',
        'params': {'limit': 100, 'offset': 1},
      }));
      expect(tester.takeException(), isNull, reason: 'coupon_strip threw');
      expect(find.text('SAVE10'), findsOneWidget);

      await pumpSection(tester, _section('custom_html', settings: {
        'content': '<p>نص <b>مهم</b> من التاجر</p><script>alert(1)</script>',
      }));
      expect(tester.takeException(), isNull, reason: 'custom_html threw');
      expect(find.textContaining('من التاجر', findRichText: true), findsWidgets,
          reason: 'the markup must render as text, the script must be inert');
    });

    testWidgets('chrome: announcement bar and spacer, RTL and LTR', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      for (final direction in [TextDirection.rtl, TextDirection.ltr]) {
        await pumpSection(
          tester,
          _section('announcement_bar', settings: {'text': 'توصيل مجاني فوق ٥٠ ألف'}),
          direction: direction,
        );
        expect(tester.takeException(), isNull);
        expect(find.text('توصيل مجاني فوق ٥٠ ألف'), findsOneWidget);

        await pumpSection(
          tester,
          _section('spacer', settings: {'height': 40}),
          direction: direction,
        );
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('the shared shell: heading, eyebrow, centre alignment, clamped padding',
        (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await pumpSection(
        tester,
        _section('usp_strip', settings: {
          'eyebrow': 'مختارات',
          'subtitle': 'وصف تحت العنوان',
          'alignment': 'center',
          // A mistyped 4000 must clamp, not push the page off screen.
          'padding_top': 4000,
        }, blocks: [
          {'type': 'usp', 'title': 'شحن سريع'},
        ]),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('عنوان القسم'), findsOneWidget);
      expect(find.text('مختارات'), findsOneWidget);
      expect(find.text('وصف تحت العنوان'), findsOneWidget);
    });

    testWidgets('view all: shown where the storefront shows it, honouring the setting',
        (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      // getTranslated falls back to the key when no localisation is loaded.
      final viewAll = find.text('view_all');

      await pumpSection(
        tester,
        _section('product_slider',
            settings: {'style': 'rail', 'limit': 4}, source: _productsSource),
      );
      expect(viewAll, findsOneWidget,
          reason: 'a capped rail must offer a way past the merchant\'s limit');
      // One header link across the whole app: the approved Direction B style is
      // plain violet with a chevron. An underline here was a second control
      // sitting beside the native sections' link and reading differently.
      final viewAllText = tester.widget<Text>(viewAll);
      expect(viewAllText.style?.decoration, isNot(TextDecoration.underline),
          reason: 'the approved header link is not underlined');
      expect(viewAllText.style?.color, BrandColors.primary,
          reason: 'the header link carries the brand violet');
      expect(
          find.descendant(
              of: find.ancestor(
                  of: viewAll, matching: find.byType(InkWell)).first,
              matching: find.byType(Icon)),
          findsOneWidget,
          reason: 'the link ends in a chevron pointing the reading direction');

      await pumpSection(
        tester,
        _section('product_slider', settings: {
          'style': 'rail',
          'limit': 4,
          'view_all': false,
        }, source: _productsSource),
      );
      expect(viewAll, findsNothing, reason: 'the merchant turned it off');

      // A showcase leads to its own subject, so with no subject chosen there is nowhere to go.
      await pumpSection(
        tester,
        _section('brand_showcase', settings: {'limit': 4}, source: _productsSource),
      );
      expect(viewAll, findsNothing,
          reason: 'a showcase with no brand id must not offer a dead link');

      await pumpSection(
        tester,
        _section('brand_showcase',
            settings: {'limit': 4, 'brand_id': 7}, source: _productsSource),
      );
      expect(viewAll, findsOneWidget);

      // Taxonomy rails: the storefront links brands and vendors onwards, and the app follows.
      await pumpSection(
        tester,
        _section('vendor_slider', settings: {'style': 'rail'}, source: const {
          'kind': 'api',
          'endpoint': '/api/v1/seller/list/all',
          'params': {},
        }),
      );
      expect(viewAll, findsOneWidget);

      // A category rail is not one of them — parity means not inventing links either.
      await pumpSection(
        tester,
        _section('category_grid', settings: {'style': 'circles'}, source: const {
          'kind': 'api',
          'endpoint': '/api/v1/categories',
          'params': {},
        }),
      );
      expect(viewAll, findsNothing);

      expect(tester.takeException(), isNull);
    });
  });
}
