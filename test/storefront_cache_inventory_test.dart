import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every place the app keeps what a server told it, found by scanning the source, and what was decided about each: it is storefront-aware,
/// or it is not storefront data, with the reason. A new cache, a new store or a new controller fails here until someone decides, so the
/// day storefronts are turned on no list of products, no cart and no row can still be showing one country's data in another's without
/// somebody having looked at it.
void main() {
  final Map<String, String> sources = <String, String>{
    for (final FileSystemEntity entity
        in Directory('lib').listSync(recursive: true))
      if (entity is File && entity.path.endsWith('.dart'))
        entity.path: entity.readAsStringSync(),
  };

  String? lines(String path) => sources[path];

  group('the local database', () {
    /// Files that read or write a row of the one local table. The rows are filed by `AppDatabase`, which files every one of them by
    /// storefront; the files that keep a row across a network answer also drop an answer for a storefront the customer has left.
    final Map<String, String> files = <String, String>{
      'lib/data/local/cache_response.dart':
          'the table and its one place that files a row by storefront',
      'lib/data/reposotories/data_sync_repo.dart':
          'every answer of the data sync layer (categories, brands, banners, the product lists, sellers, the cart): guarded',
      'lib/helper/db_helper.dart': 'the shared write: guarded',
      'lib/features/dynamic_theme/domain/repositories/dynamic_theme_repository.dart':
          'the theme pages: guarded',
      'lib/features/splash/controllers/splash_controller.dart':
          'the config: guarded',
      'lib/features/order/controllers/order_controller.dart':
          'the delivered orders: guarded',
      'lib/features/shop/controllers/shop_controller.dart':
          'a shop\'s clearance products: guarded',
      'lib/features/deal/controllers/flash_deal_controller.dart':
          'the flash deal and its products: guarded',
      'lib/localization/controllers/localization_controller.dart':
          'a language switch clears the whole table, every storefront\'s rows included, which is what it must do',
      'lib/di_container.dart':
          'gives the storefront change notifier the table\'s one delete for a storefront',
      'lib/main.dart': 'creates the one database',
      'lib/utill/cache_manager.dart':
          'not called by anything; it would file its rows through AppDatabase like the rest',
    };

    const Set<String> guarded = <String>{
      'lib/data/reposotories/data_sync_repo.dart',
      'lib/helper/db_helper.dart',
      'lib/features/dynamic_theme/domain/repositories/dynamic_theme_repository.dart',
      'lib/features/splash/controllers/splash_controller.dart',
      'lib/features/order/controllers/order_controller.dart',
      'lib/features/shop/controllers/shop_controller.dart',
      'lib/features/deal/controllers/flash_deal_controller.dart',
    };

    final RegExp usesTable = RegExp(
        r'getCacheResponseById|insertCacheResponse|updateCacheResponse|deleteCacheResponse|clearCacheResponses|getAllCacheResponses|AppDatabase');

    test('is reached by exactly the files that were looked at', () {
      final Set<String> found = <String>{
        for (final MapEntry<String, String> source in sources.entries)
          if (!source.key.endsWith('.g.dart') &&
              usesTable.hasMatch(source.value))
            source.key,
      };

      expect(found, files.keys.toSet(),
          reason:
              'a file that reads or writes a row has to be looked at: is every answer it keeps filed by storefront, and is an answer for a storefront the customer left dropped?');
    });

    test(
        'is written by the files that wait for a network answer only after asking whether the storefront is still the one',
        () {
      for (final String path in guarded) {
        expect(lines(path), contains('StorefrontScope.isCurrent('),
            reason: path);
      }
    });

    test('is only ever queried by the one class that files its rows', () {
      for (final MapEntry<String, String> source in sources.entries) {
        if (source.key == 'lib/data/local/cache_response.dart' ||
            source.key.endsWith('.g.dart')) {
          continue;
        }

        expect(source.value, isNot(contains('into(cacheResponse)')),
            reason: source.key);
        expect(source.value, isNot(contains('select(cacheResponse)')),
            reason: source.key);
        expect(source.value, isNot(contains('customStatement(')),
            reason: source.key);
      }
    });

    test('files every row through one rule', () {
      final String table = lines('lib/data/local/cache_response.dart')!;
      final List<String> methods = table.split('\n  Future<').skip(1).toList();

      String bodyOf(String name) =>
          methods.singleWhere((String method) => method.contains(' $name('));

      for (final String name in <String>[
        'insertCacheResponse',
        'getCacheResponseById',
        'updateCacheResponse',
        'deleteCacheResponseByEndpoint',
      ]) {
        expect(bodyOf(name), anyOf(contains('_rowKey('), contains('_filed(')),
            reason: name);
      }
      expect(bodyOf('deleteCacheResponsesByPrefix'),
          contains('StorefrontScope.current'));
      expect(table, contains('StorefrontCacheKey.scoped('));
    });
  });

  group('the preferences', () {
    /// Every key written to the preferences, as the code writes it: `<file>::<key expression>`, and what was decided.
    final Map<String, String> keys = <String, String>{
      'lib/data/datasource/remote/dio/dio_client.dart::\'api_cache_\$cacheKey\'':
          'storefront-aware: the HTTP cache\'s answer, under a key that ends with the storefront (ApiCacheKey)',
      'lib/data/datasource/remote/dio/dio_client.dart::\'api_cache_\${cacheKey}_time\'':
          'storefront-aware: the clock of the answer above',
      'lib/data/datasource/remote/dio/dio_client.dart::AppConstants.analyticsClientId':
          'not storefront data: the install\'s own id',
      'lib/data/reposotories/data_sync_repo.dart::uri':
          'storefront-aware: a web build\'s answer, under the key the table would use (never reached on a phone)',
      'lib/data/services/app_health_reporter.dart::AppConstants.pendingCrashCount':
          'not storefront data: a crash counter',
      'lib/features/auth/domain/repositories/auth_repository.dart::AppConstants.appleLoginEmail':
          'not storefront data: the sign-in',
      'lib/features/auth/domain/repositories/auth_repository.dart::AppConstants.guestCartId':
          'not storefront data: the id a guest\'s carts are asked for with; the server keeps the cart per storefront',
      'lib/features/auth/domain/repositories/auth_repository.dart::AppConstants.guestId':
          'not storefront data: a guest\'s id, the same at every storefront',
      'lib/features/auth/domain/repositories/auth_repository.dart::AppConstants.userLogData':
          'not storefront data: the sign-in',
      'lib/features/auth/domain/repositories/auth_repository.dart::AppConstants.userLoginToken':
          'not storefront data: the sign-in',
      'lib/features/search_product/domain/repositories/search_product_repository.dart::AppConstants.searchProductName':
          'not storefront data: what the customer typed in earlier searches',
      'lib/features/splash/controllers/splash_controller.dart::\'isNewPricingMode\'':
          'not storefront data: a display switch the customer toggles',
      'lib/features/splash/domain/repositories/splash_repository.dart::AppConstants.intro':
          'not storefront data: whether the intro was seen',
      'lib/features/splash/domain/repositories/splash_repository.dart::AppConstants.currency':
          'not storefront data: the currency the customer picked, resolved against the config, which is storefront-aware',
      'lib/features/storefront/stored_storefronts.dart::AppConstants.storefrontList':
          'the storefront feature\'s own: the list of storefronts',
      'lib/features/storefront/storefront_choice.dart::AppConstants.storefrontCountry':
          'the storefront feature\'s own: the choice',
      'lib/localization/controllers/localization_controller.dart::AppConstants.languageCode':
          'not storefront data: the language',
      'lib/localization/controllers/localization_controller.dart::AppConstants.countryCode':
          'not storefront data: the language\'s country',
      'lib/theme/controllers/theme_controller.dart::AppConstants.theme':
          'not storefront data: dark mode',
    };

    test('are written under exactly the keys that were looked at', () {
      final RegExp write = RegExp(
          r'\.set(?:String|StringList|Int|Bool|Double)\(\s*([^,]+?)\s*,');
      final Set<String> found = <String>{
        for (final MapEntry<String, String> source in sources.entries)
          if (!source.key.startsWith('lib/features/health/'))
            for (final RegExpMatch match in write.allMatches(source.value))
              '${source.key}::${match.group(1)}',
      };

      expect(found, keys.keys.toSet(),
          reason:
              'a value written to the preferences has to be looked at: does it depend on the storefront the customer is on?');
    });
  });

  group('the other stores', () {
    test(
        'are the health trackers, which hold the customer\'s own readings and nothing a storefront decides',
        () {
      final RegExp opensStore = RegExp(
          r'Hive\.openBox|openDatabase\(|getApplicationDocumentsDirectory|getApplicationSupportDirectory');
      final Set<String> found = <String>{
        for (final MapEntry<String, String> source in sources.entries)
          if (opensStore.hasMatch(source.value)) source.key,
      };

      expect(
          found,
          <String>{
            // Hive boxes and a local database of the health trackers: the customer's own readings.
            'lib/features/health/reminders/medication_reminder_screen.dart',
            'lib/features/health/reminders/water_reminder_screen.dart',
            'lib/features/health/calculators/bmi_calculator_screen.dart',
            'lib/features/health/misc/health_challenges_screen.dart',
            'lib/features/health/trackers/blood_sugar_screen.dart',
            'lib/features/health/trackers/sleep_tracker_screen.dart',
            'lib/features/health/trackers/period_tracker_screen.dart',
            'lib/features/health/data/health_database_helper.dart',
            // Files written to be opened at once, not read before a network answer: a downloaded order PDF, a downloaded digital product, a
            // chat attachment, a notification's picture.
            'lib/data/datasource/remote/dio/dio_client.dart',
            'lib/features/order_details/controllers/order_details_controller.dart',
            'lib/features/product_details/controllers/product_details_controller.dart',
            'lib/features/chat/screens/media_viewer_screen.dart',
            'lib/features/chat/widgets/message_bubble_widget.dart',
            'lib/push_notification/notification_helper.dart',
          },
          reason: 'a new store has to be looked at');
    });
  });

  group('the controllers', () {
    /// Every class that is a ChangeNotifier in the app: it holds what a storefront decides, and is told when the storefront changes, or it
    /// does not, with the reason.
    final Map<String, String?> controllers = <String, String?>{
      // told when the storefront changes
      'lib/features/banner/controllers/banner_controller.dart': null,
      'lib/features/brand/controllers/brand_controller.dart': null,
      'lib/features/cart/controllers/cart_controller.dart': null,
      'lib/features/category/controllers/category_controller.dart': null,
      'lib/features/compare/controllers/compare_controller.dart': null,
      'lib/features/coupon/controllers/coupon_controller.dart': null,
      'lib/features/deal/controllers/featured_deal_controller.dart': null,
      'lib/features/deal/controllers/flash_deal_controller.dart': null,
      'lib/features/dynamic_theme/controllers/dynamic_theme_controller.dart':
          null,
      'lib/features/product/controllers/product_controller.dart': null,
      'lib/features/product/controllers/seller_product_controller.dart': null,
      'lib/features/product_details/controllers/product_details_controller.dart':
          null,
      'lib/features/restock/controllers/restock_controller.dart': null,
      'lib/features/search_product/controllers/search_product_controller.dart':
          null,
      'lib/features/shipping/controllers/shipping_controller.dart': null,
      'lib/features/shop/controllers/shop_controller.dart': null,
      'lib/features/splash/controllers/splash_controller.dart': null,
      'lib/features/wishlist/controllers/wishlist_controller.dart': null,
      // not told, and why
      'lib/features/address/controllers/address_controller.dart':
          'the customer\'s saved addresses; the home reloads them on every refresh',
      'lib/features/auth/controllers/auth_controller.dart':
          'the sign-in, the same at every storefront',
      'lib/features/auth/controllers/facebook_login_controller.dart':
          'the sign-in',
      'lib/features/auth/controllers/google_login_controller.dart':
          'the sign-in',
      'lib/features/chat/controllers/chat_controller.dart':
          'the customer\'s conversations with shops and delivery men',
      'lib/features/checkout/controllers/checkout_controller.dart':
          'what the customer chose for the order in progress; the cart and the shipping it reads are dropped and loaded by their own controllers, and the sale gate reads the storefront when the checkout is drawn',
      'lib/features/contact_us/controllers/contact_us_controller.dart':
          'a form',
      'lib/features/health/domain/models/news_model.dart':
          'the health feature\'s news feed, which is not the shop',
      'lib/features/location/controllers/location_controller.dart':
          'the map and the places searched',
      'lib/features/loyaltyPoint/controllers/loyalty_point_controller.dart':
          'the customer\'s own points ledger, loaded when its screen opens',
      'lib/features/notification/controllers/notification_controller.dart':
          'the customer\'s notifications',
      'lib/features/onboarding/controllers/onboarding_controller.dart':
          'the intro',
      'lib/features/order/controllers/order_controller.dart':
          'the customer\'s own orders, loaded again whenever their screen opens; the row it keeps for the reorder list is filed by storefront',
      'lib/features/order_details/controllers/order_details_controller.dart':
          'one of the customer\'s own orders, loaded when it is opened',
      'lib/features/product/widgets/latest_product/stacked_swiper/transformer_page_view/index_controller.dart':
          'a swiper\'s position, not data',
      'lib/features/profile/controllers/profile_contrroller.dart':
          'the customer\'s profile',
      'lib/features/refund/controllers/refund_controller.dart':
          'the customer\'s own refund requests, loaded when their screen opens',
      'lib/features/reorder/controllers/re_order_controller.dart':
          'a reorder in progress',
      'lib/features/review/controllers/review_controller.dart':
          'the customer\'s own reviews, loaded when their screen opens',
      'lib/features/storefront/controllers/storefront_controller.dart':
          'the storefront itself',
      'lib/features/support/controllers/support_ticket_controller.dart':
          'the customer\'s own tickets',
      'lib/features/wallet/controllers/wallet_controller.dart':
          'the customer\'s own wallet ledger, loaded when its screen opens',
      'lib/localization/controllers/localization_controller.dart':
          'the language',
      'lib/theme/controllers/theme_controller.dart': 'dark mode',
    };

    test('are every ChangeNotifier of the app, and each was looked at', () {
      final RegExp notifier = RegExp(r'(extends|with)\s+ChangeNotifier');
      final Set<String> found = <String>{
        for (final MapEntry<String, String> source in sources.entries)
          if (notifier.hasMatch(source.value)) source.key,
      };

      expect(found, controllers.keys.toSet(),
          reason:
              'a controller that holds data has to be looked at: does what it holds depend on the storefront?');
    });

    test(
        'that hold what a storefront decides join the notifier and say what they do',
        () {
      for (final MapEntry<String, String?> controller in controllers.entries) {
        if (controller.value != null) continue;

        final String source = lines(controller.key)!;
        expect(source, contains('StorefrontChangeAware'),
            reason: controller.key);
        expect(source, contains('followStorefrontChanges('),
            reason: controller.key);
        expect(source, contains('Future<void> onStorefrontChanged('),
            reason: controller.key);
      }
    });

    test('that do not are not told', () {
      for (final MapEntry<String, String?> controller in controllers.entries) {
        if (controller.value == null) continue;

        expect(lines(controller.key), isNot(contains('StorefrontChangeAware')),
            reason: controller.key);
      }
    });

    test(
        'that are told are built with the notifier by the container that builds them',
        () {
      final String container = lines('lib/di_container.dart')!;

      for (final MapEntry<String, String?> controller in controllers.entries) {
        if (controller.value != null) continue;

        final String className = RegExp(r'class (\w+Controller)')
            .firstMatch(lines(controller.key)!)!
            .group(1)!;
        final RegExpMatch? registration =
            RegExp('$className\\(([^;]*?)\\)\\);', dotAll: true)
                .firstMatch(container);

        expect(registration, isNotNull, reason: className);
        expect(
            registration!.group(1),
            contains(
                'storefrontChangeNotifier: sl<StorefrontChangeNotifier>()'),
            reason: className);
      }
    });
  });
}
