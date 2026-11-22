import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syriapharmacy/data/local/cache_response.dart';
import 'package:syriapharmacy/features/storefront/storefront_scope.dart';

CacheResponseCompanion _row(String endPoint, String answer) =>
    CacheResponseCompanion(
      endPoint: Value(endPoint),
      header: const Value('{}'),
      response: Value(answer),
    );

/// The one local table the app shows answers from before the network answers: how it files a row while storefronts are off and while they
/// are on. The storefront comes from [StorefrontScope], which the HTTP client publishes, so both settings run in one test run here, over
/// a real SQLite database in memory.
void main() {
  late AppDatabase database;

  setUp(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    database = AppDatabase.forTesting(NativeDatabase.memory());
    StorefrontScope.publish(null);
  });

  tearDown(() async {
    StorefrontScope.publish(null);
    await database.close();
  });

  Future<List<String>> storedKeys() async =>
      (await database.getAllCacheResponses())
          .map((CacheResponseData row) => row.endPoint)
          .toList()
        ..sort();

  group('while storefronts are off', () {
    test('a row is filed under exactly the key it is given', () async {
      await database.insertCacheResponse(_row('/api/v1/config', 'config'));
      await database.insertCacheResponse(_row('/api/v1/banners#ar', 'banners'));

      expect(await storedKeys(), <String>[
        '/api/v1/banners#ar',
        '/api/v1/config',
      ]);
    });

    test('a row is read, updated and deleted by the key it was filed under',
        () async {
      await database.insertCacheResponse(_row('/api/v1/config', 'first'));

      expect((await database.getCacheResponseById('/api/v1/config'))?.response,
          'first');

      await database.updateCacheResponse(
          '/api/v1/config', _row('/api/v1/config', 'second'));
      expect((await database.getCacheResponseById('/api/v1/config'))?.response,
          'second');
      expect(await storedKeys(), <String>['/api/v1/config']);

      expect(await database.deleteCacheResponseByEndpoint('/api/v1/config'), 1);
      expect(await database.getCacheResponseById('/api/v1/config'), isNull);
    });

    test('a prefix deletes every row that starts with it', () async {
      await database
          .insertCacheResponse(_row('/api/v1/theme/home::home', 'home'));
      await database
          .insertCacheResponse(_row('/api/v1/theme/home::header', 'header'));
      await database.insertCacheResponse(_row('/api/v1/config', 'config'));

      expect(
        await database.deleteCacheResponsesByPrefix('/api/v1/theme/home::'),
        2,
      );
      expect(await storedKeys(), <String>['/api/v1/config']);
    });

    test('a row filed in another release is still found', () async {
      await database.insertCacheResponse(
          _row('/api/v1/customer/order/list?limit=10&offset=', 'orders'));

      expect(
        (await database.getCacheResponseById(
                '/api/v1/customer/order/list?limit=10&offset='))
            ?.response,
        'orders',
      );
    });

    test('the whole table is cleared as before', () async {
      await database.insertCacheResponse(_row('/api/v1/config', 'config'));
      await database.insertCacheResponse(_row('/api/v1/banners#ar', 'banners'));

      expect(await database.clearCacheResponses(), 2);
      expect(await storedKeys(), isEmpty);
    });
  });

  group('while storefronts are on', () {
    test('a row is filed under the storefront the requests are made for',
        () async {
      StorefrontScope.publish('SA');
      await database.insertCacheResponse(_row('/api/v1/config', 'config'));

      StorefrontScope.publish('AE');
      await database.insertCacheResponse(_row('/api/v1/banners#ar', 'banners'));

      expect(await storedKeys(), <String>[
        '/api/v1/banners#ar#AE',
        '/api/v1/config#SA',
      ]);
    });

    test('two storefronts never read each other\'s row', () async {
      StorefrontScope.publish('SA');
      await database.insertCacheResponse(_row('/api/v1/config', 'saudi'));

      StorefrontScope.publish('AE');
      expect(await database.getCacheResponseById('/api/v1/config'), isNull);
      await database.insertCacheResponse(_row('/api/v1/config', 'emirates'));
      expect((await database.getCacheResponseById('/api/v1/config'))?.response,
          'emirates');

      StorefrontScope.publish('SA');
      expect((await database.getCacheResponseById('/api/v1/config'))?.response,
          'saudi');
      expect(await storedKeys(), <String>[
        '/api/v1/config#AE',
        '/api/v1/config#SA',
      ]);
    });

    test('a row filed before storefronts were on is never read', () async {
      await database.insertCacheResponse(_row('/api/v1/config', 'legacy'));

      StorefrontScope.publish('SA');

      expect(await database.getCacheResponseById('/api/v1/config'), isNull);
    });

    test('and a row filed for a storefront is not read once they are off again',
        () async {
      StorefrontScope.publish('SA');
      await database.insertCacheResponse(_row('/api/v1/config', 'saudi'));

      StorefrontScope.publish(null);

      expect(await database.getCacheResponseById('/api/v1/config'), isNull);
    });

    test('an update changes the storefront\'s own row and no other', () async {
      StorefrontScope.publish('SA');
      await database.insertCacheResponse(_row('/api/v1/config', 'saudi'));
      StorefrontScope.publish('AE');
      await database.insertCacheResponse(_row('/api/v1/config', 'emirates'));

      expect(
        await database.updateCacheResponse(
            '/api/v1/config', _row('/api/v1/config', 'emirates, newer')),
        1,
      );

      StorefrontScope.publish('SA');
      expect((await database.getCacheResponseById('/api/v1/config'))?.response,
          'saudi');
      StorefrontScope.publish('AE');
      expect((await database.getCacheResponseById('/api/v1/config'))?.response,
          'emirates, newer');
      expect(await storedKeys(), <String>[
        '/api/v1/config#AE',
        '/api/v1/config#SA',
      ]);
    });

    test('an update of a row the storefront has not filed changes nothing',
        () async {
      StorefrontScope.publish('SA');
      await database.insertCacheResponse(_row('/api/v1/config', 'saudi'));

      StorefrontScope.publish('AE');
      expect(
        await database.updateCacheResponse(
            '/api/v1/config', _row('/api/v1/config', 'emirates')),
        0,
      );

      StorefrontScope.publish('SA');
      expect((await database.getCacheResponseById('/api/v1/config'))?.response,
          'saudi');
    });

    test('a delete by key takes the storefront\'s own row and no other',
        () async {
      StorefrontScope.publish('SA');
      await database.insertCacheResponse(_row('/api/v1/config', 'saudi'));
      StorefrontScope.publish('AE');
      await database.insertCacheResponse(_row('/api/v1/config', 'emirates'));

      expect(await database.deleteCacheResponseByEndpoint('/api/v1/config'), 1);

      expect(await storedKeys(), <String>['/api/v1/config#SA']);
    });

    test('a prefix deletes the storefront\'s rows and no other\'s', () async {
      for (final String storefront in <String>['SA', 'AE']) {
        StorefrontScope.publish(storefront);
        await database
            .insertCacheResponse(_row('/api/v1/theme/home::home', 'home'));
        await database
            .insertCacheResponse(_row('/api/v1/theme/home::header', 'header'));
        await database.insertCacheResponse(_row('/api/v1/config', 'config'));
      }

      StorefrontScope.publish('AE');
      expect(
        await database.deleteCacheResponsesByPrefix('/api/v1/theme/home::'),
        2,
      );

      expect(await storedKeys(), <String>[
        '/api/v1/config#AE',
        '/api/v1/config#SA',
        '/api/v1/theme/home::header#SA',
        '/api/v1/theme/home::home#SA',
      ]);
    });

    test('a storefront\'s rows go together, in every language, and only theirs',
        () async {
      for (final String storefront in <String>['SA', 'AE']) {
        StorefrontScope.publish(storefront);
        for (final String language in <String>['en', 'ar']) {
          await database.insertCacheResponse(
              _row('/api/v1/categories#$language', 'categories'));
        }
        await database.insertCacheResponse(_row('/api/v1/config', 'config'));
      }
      StorefrontScope.publish(null);
      await database.insertCacheResponse(_row('/api/v1/config', 'legacy'));
      await database
          .insertCacheResponse(_row('/api/v1/categories#sa', 'language sa'));

      expect(await database.deleteCacheResponsesOfStorefront('SA'), 3);

      expect(await storedKeys(), <String>[
        '/api/v1/categories#ar#AE',
        '/api/v1/categories#en#AE',
        '/api/v1/categories#sa',
        '/api/v1/config',
        '/api/v1/config#AE',
      ]);
    });

    test('clearing a storefront with no rows deletes nothing', () async {
      StorefrontScope.publish('SA');
      await database.insertCacheResponse(_row('/api/v1/config', 'saudi'));

      expect(await database.deleteCacheResponsesOfStorefront('KW'), 0);
      expect(await storedKeys(), <String>['/api/v1/config#SA']);
    });

    test('the whole table is still cleared at once, as a language switch does',
        () async {
      for (final String storefront in <String>['SA', 'AE']) {
        StorefrontScope.publish(storefront);
        await database.insertCacheResponse(_row('/api/v1/config', 'config'));
      }

      expect(await database.clearCacheResponses(), 2);
    });
  });
}
