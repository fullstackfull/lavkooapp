import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syriapharmacy/data/datasource/remote/dio/api_cache_key.dart';
import 'package:syriapharmacy/data/datasource/remote/dio/dio_client.dart';
import 'package:syriapharmacy/data/datasource/remote/dio/logging_interceptor.dart';
import 'package:syriapharmacy/features/storefront/storefront_config.dart';
import 'package:syriapharmacy/features/storefront/storefront_scope.dart';
import 'package:syriapharmacy/utill/app_constants.dart';

const String _cacheWindowPath = '/api/v1/cash';

class _ScriptedAdapter implements HttpClientAdapter {
  _ScriptedAdapter(this._answer);

  final Future<ResponseBody> Function(RequestOptions options) _answer;
  final List<RequestOptions> requests = <RequestOptions>[];

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

Future<ResponseBody> _answerByStorefront(RequestOptions options) async {
  if (options.path == _cacheWindowPath) {
    return _json(300000);
  }

  return _json(<String, Object>{
    'storefront': options.headers[AppConstants.storefrontHeader] ?? 'none',
  });
}

/// The HTTP client's part of a storefront change: the namespace a storefront's cached answers live in, and the storefront it tells the rest
/// of the app its requests are for.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const String uri = '/api/v1/products/latest';
  const Map<String, dynamic> query = <String, dynamic>{
    'limit': 10,
    'offset': 1,
  };

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

  Map<String, Object> answersFor(
    String uri,
    Iterable<String?> storefronts, {
    Iterable<String> languages = const <String>['en'],
  }) {
    final Map<String, Object> cached = <String, Object>{};
    for (final String? storefront in storefronts) {
      for (final String language in languages) {
        final String key = ApiCacheKey.build(
          uri: uri,
          languageCode: language,
          storefrontCode: storefront,
        );
        cached['api_cache_$key'] = '[]';
        cached['api_cache_${key}_time'] = DateTime.now().millisecondsSinceEpoch;
      }
    }

    return cached;
  }

  setUp(() => StorefrontScope.publish(null));
  tearDown(() => StorefrontScope.publish(null));

  group('while storefronts are off', () {
    test('the client publishes no storefront, whatever is stored', () async {
      await clientWith(<String, Object>{
        AppConstants.storefrontCountry: 'AE',
      });

      expect(StorefrontScope.current, isNull);
    });

    test('a header rebuild still publishes no storefront', () async {
      final DioClient client = await clientWith(<String, Object>{
        AppConstants.storefrontCountry: 'AE',
      });

      client.updateHeader('another token', 'ar');

      expect(StorefrontScope.current, isNull);
    });
  }, skip: StorefrontConfig.enabled);

  group('clearing one storefront\'s answers', () {
    test('goes through every language of that storefront, on disk', () async {
      final DioClient client = await clientWith(answersFor(
        '/api/v1/categories',
        <String?>['SA', 'AE'],
        languages: <String>['en', 'ar'],
      ));
      expect(cachedKeys(), hasLength(8));

      client.clearStorefrontCache('AE');

      expect(
        cachedKeys(),
        unorderedEquals(<String>[
          for (final String language in <String>['en', 'ar']) ...<String>[
            'api_cache_/api/v1/categories#$language#SA',
            'api_cache_/api/v1/categories#$language#SA_time',
          ],
        ]),
      );
    });

    test('takes the answer and its clock together, or neither', () async {
      final DioClient client = await clientWith(answersFor(
        '/api/v1/categories',
        <String?>['AE'],
      ));

      client.clearStorefrontCache('AE');

      expect(cachedKeys(), isEmpty);
    });

    test('leaves what was cached before storefronts were on', () async {
      final DioClient client = await clientWith(<String, Object>{
        ...answersFor('/api/v1/categories', <String?>[null, 'SA']),
        'api_cache_/api/v1/categories#sa': '[]',
      });

      client.clearStorefrontCache('SA');

      expect(
        cachedKeys(),
        unorderedEquals(<String>[
          'api_cache_/api/v1/categories#en',
          'api_cache_/api/v1/categories#en_time',
          'api_cache_/api/v1/categories#sa',
        ]),
      );
    });

    test('leaves everything that is not a cached answer', () async {
      final DioClient client = await clientWith(<String, Object>{
        ...answersFor('/api/v1/categories', <String?>['AE']),
        AppConstants.storefrontCountry: 'AE',
        'api_cached': 'not a cached answer',
        'AE': 'a key that only ends the same way',
      });

      client.clearStorefrontCache('AE');

      expect(
        preferences.getKeys(),
        unorderedEquals(<String>[
          AppConstants.userLoginToken,
          AppConstants.analyticsClientId,
          AppConstants.languageCode,
          AppConstants.storefrontCountry,
          'api_cached',
          'AE',
        ]),
      );
    });

    test('is a no-op for a storefront with nothing cached', () async {
      final DioClient client = await clientWith(answersFor(
        '/api/v1/categories',
        <String?>['SA'],
      ));

      client.clearStorefrontCache('KW');

      expect(cachedKeys(), hasLength(2));
    });
  });

  // Run only in a build made with --dart-define=GCC_STOREFRONTS_ENABLED=true, because the flag is a compile-time constant.
  group('while storefronts are on', () {
    Future<void> chooseStorefront(DioClient client, String code) async {
      await preferences.setString(AppConstants.storefrontCountry, code);
      client.updateHeader(null, null);
    }

    test('a new client publishes the storefront its header carries', () async {
      await clientWith(<String, Object>{
        AppConstants.storefrontCountry: 'AE',
      });

      expect(StorefrontScope.current, 'AE');
    });

    test('nothing chosen yet is the Saudi storefront, and is published as such',
        () async {
      await clientWith(<String, Object>{});

      expect(StorefrontScope.current, 'SA');
    });

    test('a choice is published when the headers are rebuilt, not before',
        () async {
      final DioClient client = await clientWith(<String, Object>{});

      await preferences.setString(AppConstants.storefrontCountry, 'AE');
      expect(StorefrontScope.current, 'SA');

      client.updateHeader(null, null);
      expect(StorefrontScope.current, 'AE');
    });

    test('a login keeps the storefront that is published', () async {
      final DioClient client = await clientWith(<String, Object>{
        AppConstants.storefrontCountry: 'KW',
      });

      client.updateHeader('a new token', null);

      expect(StorefrontScope.current, 'KW');
    });

    test('clearing a storefront empties its memory cache and keeps the rest',
        () async {
      final DioClient client = await clientWith(<String, Object>{});

      await client.get(uri, queryParameters: query);
      await chooseStorefront(client, 'AE');
      await client.get(uri, queryParameters: query);
      expect(adapter.catalogueRequests, hasLength(2));

      client.clearStorefrontCache('SA');
      final Response emirates = await client.get(uri, queryParameters: query);
      expect(adapter.catalogueRequests, hasLength(2));
      expect(emirates.data['storefront'], 'AE');

      await chooseStorefront(client, 'SA');
      final Response saudi = await client.get(uri, queryParameters: query);
      expect(adapter.catalogueRequests, hasLength(3));
      expect(saudi.data['storefront'], 'SA');
    });

    test('clearing a storefront empties its disk cache and keeps the rest',
        () async {
      final DioClient client = await clientWith(<String, Object>{});

      await client.get(uri, queryParameters: query);
      await chooseStorefront(client, 'AE');
      await client.get(uri, queryParameters: query);

      client.clearStorefrontCache('SA');
      DioClient.clearMemoryCache();

      final Response emirates = await client.get(uri, queryParameters: query);
      expect(adapter.catalogueRequests, hasLength(2), reason: 'read from disk');
      expect(emirates.data['storefront'], 'AE');
      expect(
        cachedKeys(),
        unorderedEquals(<String>[
          'api_cache_/api/v1/products/latest?limit=10&offset=1#en#AE',
          'api_cache_/api/v1/products/latest?limit=10&offset=1#en#AE_time',
        ]),
      );
    });
  }, skip: !StorefrontConfig.enabled);
}
