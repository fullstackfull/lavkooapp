import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syriapharmacy/data/datasource/remote/dio/api_cache_key.dart';
import 'package:syriapharmacy/data/datasource/remote/dio/dio_client.dart';
import 'package:syriapharmacy/data/datasource/remote/dio/logging_interceptor.dart';
import 'package:syriapharmacy/features/storefront/storefront_config.dart';
import 'package:syriapharmacy/utill/app_constants.dart';

const String _cacheWindowPath = '/api/v1/cash';

/// Answers every request from a script and remembers what was asked, so the real client runs over the real Dio without a network.
class _ScriptedAdapter implements HttpClientAdapter {
  _ScriptedAdapter(this._answer);

  final Future<ResponseBody> Function(RequestOptions options) _answer;
  final List<RequestOptions> requests = <RequestOptions>[];

  /// What was asked of the catalogue. The client's one look at the server's cache window, made before its first cached request, is
  /// not what these tests count.
  List<RequestOptions> get catalogueRequests => requests
      .where((RequestOptions options) => options.path != _cacheWindowPath)
      .toList();

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    requests.add(options);
    return _answer(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Object body) => ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );

/// The catalogue as a server with storefronts answers it: the answer names the storefront the request asked for.
Future<ResponseBody> _answerByStorefront(RequestOptions options) async {
  if (options.path == _cacheWindowPath) {
    return _json(300000);
  }

  final Object storefront =
      options.headers[AppConstants.storefrontHeader] ?? 'none';

  return _json(<String, Object>{'storefront': storefront});
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const String uri = '/api/v1/products/latest';
  const Map<String, dynamic> query = <String, dynamic>{
    'limit': 10,
    'offset': 1,
  };
  const String legacyDiskKey =
      'api_cache_/api/v1/products/latest?limit=10&offset=1#en';

  late SharedPreferences preferences;
  late _ScriptedAdapter adapter;

  Future<DioClient> clientWith(
    Map<String, Object> stored, {
    Future<ResponseBody> Function(RequestOptions options) answer =
        _answerByStorefront,
  }) async {
    DioClient.clearMemoryCache();
    SharedPreferences.setMockInitialValues(<String, Object>{
      AppConstants.userLoginToken: 'token',
      AppConstants.analyticsClientId: 'test-client-id',
      AppConstants.languageCode: 'en',
      ...stored,
    });
    preferences = await SharedPreferences.getInstance();
    adapter = _ScriptedAdapter(answer);

    return DioClient(
      'https://shop.test',
      Dio()..httpClientAdapter = adapter,
      loggingInterceptor: LoggingInterceptor(),
      sharedPreferences: preferences,
    );
  }

  Iterable<String> cachedKeys() =>
      preferences.getKeys().where((String key) => key.startsWith('api_cache_'));

  List<Object?> storefrontsAsked() => adapter.catalogueRequests
      .map((RequestOptions options) =>
          options.headers[AppConstants.storefrontHeader])
      .toList();

  /// Lets a request a test holds back finish whatever the test did, and waits for it. The client keeps its in-flight requests in a
  /// static map, so one left hanging by a failed test would make the next test wait for it.
  void releaseAtTearDown(
    Completer<ResponseBody> held,
    List<Future<Response>> started,
  ) {
    addTearDown(() async {
      if (!held.isCompleted) {
        held.complete(_json(<String, Object>{'storefront': 'released'}));
      }
      for (final Future<Response> request in started) {
        await request.then<void>((Response _) {}, onError: (Object _) {});
      }
    });
  }

  group('while storefronts are off', () {
    test(
        'an answer is filed, in memory and on disk, under the key it always had',
        () async {
      final DioClient client = await clientWith(<String, Object>{});

      await client.get(uri, queryParameters: query);

      expect(adapter.catalogueRequests, hasLength(1));
      expect(
        cachedKeys(),
        unorderedEquals(<String>[legacyDiskKey, '${legacyDiskKey}_time']),
      );
      expect(preferences.getString(legacyDiskKey), '{"storefront":"none"}');
    });

    test('the same request is answered from memory, then from disk', () async {
      final DioClient client = await clientWith(<String, Object>{});

      final Response first = await client.get(uri, queryParameters: query);
      final Response fromMemory = await client.get(uri, queryParameters: query);
      DioClient.clearMemoryCache();
      final Response fromDisk = await client.get(uri, queryParameters: query);

      expect(adapter.catalogueRequests, hasLength(1));
      expect(identical(fromMemory, first), isTrue);
      expect(identical(fromDisk, first), isFalse);
      expect(fromDisk.data, first.data);
    });

    test('an answer already on the phone is read as before', () async {
      final DioClient client = await clientWith(<String, Object>{
        legacyDiskKey: '{"storefront":"kept from an earlier release"}',
        '${legacyDiskKey}_time': DateTime.now().millisecondsSinceEpoch,
      });

      final Response response = await client.get(uri, queryParameters: query);

      expect(adapter.catalogueRequests, isEmpty);
      expect(response.data['storefront'], 'kept from an earlier release');
    });

    test('a stored storefront choice is neither sent nor part of the key',
        () async {
      final DioClient client = await clientWith(<String, Object>{
        AppConstants.storefrontCountry: 'AE',
      });

      await client.get(uri, queryParameters: query);
      await preferences.setString(AppConstants.storefrontCountry, 'KW');
      client.updateHeader(null, null);
      await client.get(uri, queryParameters: query);

      expect(adapter.catalogueRequests, hasLength(1));
      expect(
        adapter.catalogueRequests.single.headers,
        isNot(contains(AppConstants.storefrontHeader)),
      );
      expect(
        cachedKeys(),
        unorderedEquals(<String>[legacyDiskKey, '${legacyDiskKey}_time']),
      );
    });

    test('a language switch misses the other language and files its own',
        () async {
      final DioClient client = await clientWith(<String, Object>{});

      await client.get(uri, queryParameters: query);
      await preferences.setString(AppConstants.languageCode, 'ar');
      await client.get(uri, queryParameters: query);

      expect(adapter.catalogueRequests, hasLength(2));
      expect(
        cachedKeys(),
        unorderedEquals(<String>[
          legacyDiskKey,
          '${legacyDiskKey}_time',
          'api_cache_/api/v1/products/latest?limit=10&offset=1#ar',
          'api_cache_/api/v1/products/latest?limit=10&offset=1#ar_time',
        ]),
      );
    });
  }, skip: StorefrontConfig.enabled);

  group('clearing the cache', () {
    test(
        'the disk cache goes by prefix: every storefront\'s answers, nothing else',
        () async {
      final Map<String, Object> cached = <String, Object>{};
      for (final String? storefront in <String?>[null, 'SA', 'AE', 'KW']) {
        final String answerKey = ApiCacheKey.build(
          uri: '/api/v1/categories',
          languageCode: 'en',
          storefrontCode: storefront,
        );
        cached['api_cache_$answerKey'] = '[]';
        cached['api_cache_${answerKey}_time'] =
            DateTime.now().millisecondsSinceEpoch;
      }
      final DioClient client = await clientWith(<String, Object>{
        ...cached,
        AppConstants.storefrontCountry: 'AE',
        'api_cached': 'not a cached answer',
      });
      expect(cachedKeys(), hasLength(8));

      client.clearDiskCache();

      expect(cachedKeys(), isEmpty);
      expect(
        preferences.getKeys(),
        unorderedEquals(<String>[
          AppConstants.userLoginToken,
          AppConstants.analyticsClientId,
          AppConstants.languageCode,
          AppConstants.storefrontCountry,
          'api_cached',
        ]),
      );
    });
  });

  group('requests asked at once', () {
    test('the same request is still folded into one', () async {
      final Completer<ResponseBody> answer = Completer<ResponseBody>();
      final DioClient client = await clientWith(
        <String, Object>{},
        answer: (RequestOptions options) => options.path == _cacheWindowPath
            ? _answerByStorefront(options)
            : answer.future,
      );

      final List<Future<Response>> started = <Future<Response>>[];
      releaseAtTearDown(answer, started);

      final Future<Response> first = client.get(uri, queryParameters: query);
      started.add(first);
      await pumpEventQueue();
      final Future<Response> second = client.get(uri, queryParameters: query);
      started.add(second);
      await pumpEventQueue();

      expect(adapter.catalogueRequests, hasLength(1));

      answer.complete(_json(<String, Object>{'storefront': 'one answer'}));

      expect((await first).data, <String, Object>{'storefront': 'one answer'});
      expect((await second).data, <String, Object>{'storefront': 'one answer'});
    });
  });

  // Runs only in a build made with --dart-define=GCC_STOREFRONTS_ENABLED=true, because the flag is a compile-time constant.
  group('while storefronts are on', () {
    String diskKeyFor(String storefront) => '$legacyDiskKey#$storefront';

    // What the storefront chooser has to do after saving a choice: the headers are built from the choice only when asked to be.
    Future<void> chooseStorefront(DioClient client, String code) async {
      await preferences.setString(AppConstants.storefrontCountry, code);
      client.updateHeader(null, null);
    }

    test('an answer is filed under the storefront the request carried',
        () async {
      final DioClient client = await clientWith(<String, Object>{
        AppConstants.storefrontCountry: 'AE',
      });

      final Response response = await client.get(uri, queryParameters: query);

      expect(storefrontsAsked(), <Object?>['AE']);
      expect(response.data['storefront'], 'AE');
      expect(
        cachedKeys(),
        unorderedEquals(<String>[
          diskKeyFor('AE'),
          '${diskKeyFor('AE')}_time',
        ]),
      );
    });

    test('nothing chosen yet is the Saudi storefront, and is filed as such',
        () async {
      final DioClient client = await clientWith(<String, Object>{});

      await client.get(uri, queryParameters: query);

      expect(storefrontsAsked(), <Object?>['SA']);
      expect(cachedKeys(), contains(diskKeyFor('SA')));
    });

    test('switching storefront misses the other one\'s cache and hits its own',
        () async {
      final DioClient client = await clientWith(<String, Object>{});

      final Response saudi = await client.get(uri, queryParameters: query);
      await chooseStorefront(client, 'AE');
      final Response emirates = await client.get(uri, queryParameters: query);
      await chooseStorefront(client, 'SA');
      final Response saudiAgain = await client.get(uri, queryParameters: query);

      expect(storefrontsAsked(), <Object?>['SA', 'AE']);
      expect(saudi.data['storefront'], 'SA');
      expect(emirates.data['storefront'], 'AE');
      expect(saudiAgain.data['storefront'], 'SA');
      expect(identical(saudiAgain, saudi), isTrue);

      DioClient.clearMemoryCache();
      final Response saudiFromDisk =
          await client.get(uri, queryParameters: query);
      await chooseStorefront(client, 'AE');
      final Response emiratesFromDisk =
          await client.get(uri, queryParameters: query);

      expect(storefrontsAsked(), <Object?>['SA', 'AE']);
      expect(saudiFromDisk.data['storefront'], 'SA');
      expect(emiratesFromDisk.data['storefront'], 'AE');
      expect(
        cachedKeys(),
        unorderedEquals(<String>[
          diskKeyFor('SA'),
          '${diskKeyFor('SA')}_time',
          diskKeyFor('AE'),
          '${diskKeyFor('AE')}_time',
        ]),
      );
    });

    test('an answer cached before storefronts were on is not read by any',
        () async {
      final DioClient client = await clientWith(<String, Object>{
        legacyDiskKey: '{"storefront":"kept from an earlier release"}',
        '${legacyDiskKey}_time': DateTime.now().millisecondsSinceEpoch,
      });

      final Response response = await client.get(uri, queryParameters: query);

      expect(adapter.catalogueRequests, hasLength(1));
      expect(response.data['storefront'], 'SA');
      expect(
        preferences.getString(legacyDiskKey),
        '{"storefront":"kept from an earlier release"}',
      );
    });

    test('a language switch still misses, whatever the storefront', () async {
      final DioClient client = await clientWith(<String, Object>{
        AppConstants.storefrontCountry: 'AE',
      });

      await client.get(uri, queryParameters: query);
      await preferences.setString(AppConstants.languageCode, 'ar');
      await client.get(uri, queryParameters: query);

      expect(adapter.catalogueRequests, hasLength(2));
      expect(
        cachedKeys(),
        containsAll(<String>[
          diskKeyFor('AE'),
          'api_cache_/api/v1/products/latest?limit=10&offset=1#ar#AE',
        ]),
      );
    });

    test(
        'between a choice and the next header rebuild nothing is filed under the new storefront',
        () async {
      final DioClient client = await clientWith(<String, Object>{});

      await preferences.setString(AppConstants.storefrontCountry, 'AE');
      final Response response = await client.get(uri, queryParameters: query);

      expect(storefrontsAsked(), <Object?>['SA']);
      expect(response.data['storefront'], 'SA');
      expect(cachedKeys(), contains(diskKeyFor('SA')));
      expect(cachedKeys(), isNot(contains(diskKeyFor('AE'))));

      client.updateHeader(null, null);
      final Response afterRebuild =
          await client.get(uri, queryParameters: query);

      expect(storefrontsAsked(), <Object?>['SA', 'AE']);
      expect(afterRebuild.data['storefront'], 'AE');
    });

    test('two storefronts asking at once are not folded into one request',
        () async {
      final Completer<ResponseBody> saudiAnswer = Completer<ResponseBody>();
      final DioClient client = await clientWith(
        <String, Object>{},
        answer: (RequestOptions options) {
          if (options.path != _cacheWindowPath &&
              options.headers[AppConstants.storefrontHeader] == 'SA') {
            return saudiAnswer.future;
          }

          return _answerByStorefront(options);
        },
      );

      final List<Future<Response>> started = <Future<Response>>[];
      releaseAtTearDown(saudiAnswer, started);

      final Future<Response> saudi = client.get(uri, queryParameters: query);
      started.add(saudi);
      await pumpEventQueue();
      await chooseStorefront(client, 'AE');
      final Future<Response> emirates = client.get(uri, queryParameters: query);
      started.add(emirates);
      await pumpEventQueue();

      expect(storefrontsAsked(), <Object?>['SA', 'AE']);

      saudiAnswer.complete(_json(<String, Object>{'storefront': 'SA'}));

      expect((await saudi).data['storefront'], 'SA');
      expect((await emirates).data['storefront'], 'AE');
      expect(cachedKeys(), contains(diskKeyFor('SA')));
      expect(cachedKeys(), contains(diskKeyFor('AE')));
    });

    test('clearing the caches clears every storefront\'s answers', () async {
      final DioClient client = await clientWith(<String, Object>{});
      await client.get(uri, queryParameters: query);
      await chooseStorefront(client, 'AE');
      await client.get(uri, queryParameters: query);
      expect(cachedKeys(), hasLength(4));

      client.clearDiskCache();
      DioClient.clearMemoryCache();

      expect(cachedKeys(), isEmpty);
      await client.get(uri, queryParameters: query);
      await chooseStorefront(client, 'SA');
      await client.get(uri, queryParameters: query);
      expect(storefrontsAsked(), <Object?>['SA', 'AE', 'AE', 'SA']);
    });
  }, skip: !StorefrontConfig.enabled);
}
