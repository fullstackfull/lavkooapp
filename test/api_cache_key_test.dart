import 'package:flutter_test/flutter_test.dart';
import 'package:syriapharmacy/data/datasource/remote/dio/api_cache_key.dart';
import 'package:syriapharmacy/features/storefront/domain/models/storefront_country.dart';

typedef _PinnedKey = ({
  String what,
  String uri,
  Map<String, dynamic>? query,
  String language,
  String key,
});

/// Without a storefront code the key must be exactly what this app built before storefronts existed, because every answer already
/// cached on a phone sits under it. With a code it must tell the storefronts apart and still hold everything it held.
void main() {
  group('without a storefront code', () {
    // Every expected key was produced by the key function as it was before storefronts existed, not by the one under test.
    const List<_PinnedKey> pinned = <_PinnedKey>[
      (
        what: 'a path alone',
        uri: '/api/v1/categories',
        query: null,
        language: 'en',
        key: '/api/v1/categories#en',
      ),
      (
        what: 'the language of the lang header',
        uri: '/api/v1/categories',
        query: null,
        language: 'ar',
        key: '/api/v1/categories#ar',
      ),
      (
        what: 'a language the app does not ship is kept as it is',
        uri: '/api/v1/products/latest?limit=10&offset=1',
        query: null,
        language: 'fr',
        key: '/api/v1/products/latest?limit=10&offset=1#fr',
      ),
      (
        what: 'parameters written into the address',
        uri: '/api/v1/products/latest?limit=10&offset=1',
        query: null,
        language: 'en',
        key: '/api/v1/products/latest?limit=10&offset=1#en',
      ),
      (
        what: 'parameters passed as a map are sorted by name',
        uri: '/api/v1/products/latest',
        query: <String, dynamic>{'offset': 1, 'limit': 10},
        language: 'en',
        key: '/api/v1/products/latest?limit=10&offset=1#en',
      ),
      (
        what: 'the same parameters passed in the other order',
        uri: '/api/v1/products/latest',
        query: <String, dynamic>{'limit': 10, 'offset': 1},
        language: 'en',
        key: '/api/v1/products/latest?limit=10&offset=1#en',
      ),
      (
        what: 'parameters of the address are sorted too',
        uri: '/api/v1/products/featured?offset=1&limit=10&guest_id=1',
        query: null,
        language: 'ar',
        key: '/api/v1/products/featured?guest_id=1&limit=10&offset=1#ar',
      ),
      (
        what: 'the host is not part of the key',
        uri: 'https://shop.test/api/v1/banners?banner_type=main',
        query: null,
        language: 'en',
        key: '/api/v1/banners?banner_type=main#en',
      ),
      (
        what:
            'the map wins over the address, an empty value of the address and a null of the map are left out, a bool is written as text',
        uri: '/api/v1/products/latest?limit=5&empty=',
        query: <String, dynamic>{'limit': 10, 'skipped': null, 'flag': true},
        language: 'en',
        key: '/api/v1/products/latest?flag=true&limit=10#en',
      ),
      (
        what:
            'an address that cannot be read falls back to the raw address and the map as text',
        uri: '/api/v1/products/latest?x=%E0%A4%A',
        query: <String, dynamic>{'a': 1},
        language: 'en',
        key: '/api/v1/products/latest?x=%E0%A4%A{a: 1}#en',
      ),
      (
        what:
            'an address that cannot be parsed at all falls back to the raw address',
        uri: 'http://[bad',
        query: null,
        language: 'ar',
        key: 'http://[bad#ar',
      ),
    ];

    for (final _PinnedKey pin in pinned) {
      test('keeps its key for ${pin.what}', () {
        expect(
          ApiCacheKey.build(
            uri: pin.uri,
            queryParameters: pin.query,
            languageCode: pin.language,
          ),
          pin.key,
        );
      });
    }

    test('a null storefront code is the same as leaving it out', () {
      expect(
        ApiCacheKey.build(
          uri: '/api/v1/banners',
          languageCode: 'en',
          storefrontCode: null,
        ),
        ApiCacheKey.build(uri: '/api/v1/banners', languageCode: 'en'),
      );
    });
  });

  group('with a storefront code', () {
    const String address = '/api/v1/products/latest?limit=10&offset=1';

    String keyFor(String? storefront, {String language = 'en'}) =>
        ApiCacheKey.build(
          uri: address,
          languageCode: language,
          storefrontCode: storefront,
        );

    test('the key is the key without a code, followed by the code', () {
      expect(keyFor('AE'), '/api/v1/products/latest?limit=10&offset=1#en#AE');
      expect(keyFor('AE'), '${keyFor(null)}#AE');
    });

    test('two storefronts never share a key', () {
      expect(keyFor('SA'), isNot(keyFor('AE')));
    });

    test('every GCC storefront has a key of its own and none is the legacy key',
        () {
      final Set<String> keys = <String>{
        for (final StorefrontCountry storefront in StorefrontCountry.all)
          keyFor(storefront.code),
      };

      expect(keys, hasLength(StorefrontCountry.all.length));
      expect(keys, isNot(contains(keyFor(null))));
    });

    test('the same storefront asking twice gets the same key', () {
      expect(keyFor('KW'), keyFor('KW'));
    });

    test('the language is still part of the key', () {
      expect(keyFor('AE', language: 'ar'),
          '/api/v1/products/latest?limit=10&offset=1#ar#AE');
      expect(keyFor('AE', language: 'ar'), isNot(keyFor('AE', language: 'en')));
    });

    test('the order of the parameters does not change the key', () {
      final String inAddressOrder = ApiCacheKey.build(
        uri: '/api/v1/products/latest',
        queryParameters: <String, dynamic>{'limit': 10, 'offset': 1},
        languageCode: 'en',
        storefrontCode: 'QA',
      );
      final String inOtherOrder = ApiCacheKey.build(
        uri: '/api/v1/products/latest',
        queryParameters: <String, dynamic>{'offset': 1, 'limit': 10},
        languageCode: 'en',
        storefrontCode: 'QA',
      );

      expect(inAddressOrder, inOtherOrder);
      expect(inAddressOrder, '/api/v1/products/latest?limit=10&offset=1#en#QA');
    });

    test('an address that cannot be read still carries the storefront', () {
      expect(
        ApiCacheKey.build(
          uri: '/api/v1/products/latest?x=%E0%A4%A',
          queryParameters: <String, dynamic>{'a': 1},
          languageCode: 'en',
          storefrontCode: 'BH',
        ),
        '/api/v1/products/latest?x=%E0%A4%A{a: 1}#en#BH',
      );
    });
  });
}
