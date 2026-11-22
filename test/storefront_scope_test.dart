import 'package:flutter_test/flutter_test.dart';
import 'package:syriapharmacy/features/storefront/storefront_cache_key.dart';
import 'package:syriapharmacy/features/storefront/storefront_scope.dart';

void main() {
  setUp(() => StorefrontScope.publish(null));
  tearDown(() => StorefrontScope.publish(null));

  group('the storefront the requests are made for', () {
    test('is nobody\'s until the HTTP client says so', () {
      expect(StorefrontScope.current, isNull);
    });

    test('is what the client last published', () {
      StorefrontScope.publish('AE');
      expect(StorefrontScope.current, 'AE');

      StorefrontScope.publish('KW');
      expect(StorefrontScope.current, 'KW');

      StorefrontScope.publish(null);
      expect(StorefrontScope.current, isNull);
    });

    test('while storefronts are off every answer is for the current one', () {
      final String? captured = StorefrontScope.current;

      expect(StorefrontScope.isCurrent(captured), isTrue);
      expect(StorefrontScope.isCurrent(null), isTrue);
    });

    test('an answer asked for before a change is not for the current one', () {
      StorefrontScope.publish('SA');
      final String? captured = StorefrontScope.current;

      StorefrontScope.publish('AE');

      expect(StorefrontScope.isCurrent(captured), isFalse);
      expect(StorefrontScope.isCurrent('AE'), isTrue);
    });

    test('an answer asked for before a change and back is for the current one',
        () {
      StorefrontScope.publish('SA');
      final String? captured = StorefrontScope.current;

      StorefrontScope.publish('AE');
      StorefrontScope.publish('SA');

      expect(StorefrontScope.isCurrent(captured), isTrue);
    });

    test('an answer asked for with no storefront is stale once one is on', () {
      final String? captured = StorefrontScope.current;

      StorefrontScope.publish('SA');

      expect(StorefrontScope.isCurrent(captured), isFalse);
    });
  });

  group('the key a row is filed under', () {
    test('is the key itself while storefronts are off', () {
      for (final String key in <String>[
        '/api/v1/categories#en',
        '/api/v1/config',
        '/api/v1/customer/order/list?limit=10&offset=',
        '/api/v1/theme/home::home',
      ]) {
        expect(StorefrontCacheKey.scoped(key, storefrontCode: null), key);
      }
    });

    test('ends with the storefront when one is on', () {
      expect(
        StorefrontCacheKey.scoped('/api/v1/categories#en',
            storefrontCode: 'AE'),
        '/api/v1/categories#en#AE',
      );
      expect(
        StorefrontCacheKey.scoped('/api/v1/config', storefrontCode: 'SA'),
        '/api/v1/config#SA',
      );
    });

    test('differs between two storefronts, so neither reads the other\'s row',
        () {
      expect(
        StorefrontCacheKey.scoped('/api/v1/banners#ar', storefrontCode: 'SA'),
        isNot(StorefrontCacheKey.scoped('/api/v1/banners#ar',
            storefrontCode: 'AE')),
      );
    });

    test('is never the key a row filed without a storefront has', () {
      const String legacy = '/api/v1/banners#ar';

      expect(
        StorefrontCacheKey.scoped(legacy, storefrontCode: 'SA'),
        isNot(legacy),
      );
    });

    test('is recognised as the storefront\'s own, and nobody else\'s', () {
      final String saudi =
          StorefrontCacheKey.scoped('/api/v1/banners#ar', storefrontCode: 'SA');

      expect(
          StorefrontCacheKey.isScopedTo(saudi, storefrontCode: 'SA'), isTrue);
      expect(
          StorefrontCacheKey.isScopedTo(saudi, storefrontCode: 'AE'), isFalse);
      expect(
        StorefrontCacheKey.isScopedTo('/api/v1/banners#ar',
            storefrontCode: 'SA'),
        isFalse,
      );
      expect(
        StorefrontCacheKey.isScopedTo('/api/v1/banners#sa',
            storefrontCode: 'SA'),
        isFalse,
        reason: 'a language ending in the same letters is not a storefront',
      );
    });
  });
}
