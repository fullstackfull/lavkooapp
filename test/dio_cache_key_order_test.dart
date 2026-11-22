import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syriapharmacy/data/datasource/remote/dio/dio_client.dart';
import 'package:syriapharmacy/data/datasource/remote/dio/logging_interceptor.dart';
import 'package:syriapharmacy/features/storefront/storefront_config.dart';
import 'package:syriapharmacy/utill/app_constants.dart';

class _ScriptedAdapter implements HttpClientAdapter {
  _ScriptedAdapter(this._answer);

  final Future<ResponseBody> Function(RequestOptions options) _answer;
  final List<RequestOptions> requests = <RequestOptions>[];

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

/// What the client does before it sends a cached request, in the order it does it: it looks at the server's cache window first, and only
/// then makes the key the answer is filed under. The client looks at the cache window once in the life of the app, on its first cached
/// request, and keeps that in a static, so this is the only test of this file and the first request of its run: a second test could not
/// make the client wait.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
      'an answer is filed under what the request asked for, when language or storefront change while the cache window is awaited',
      () async {
    final Completer<ResponseBody> window = Completer<ResponseBody>();
    DioClient.clearMemoryCache();
    SharedPreferences.setMockInitialValues(<String, Object>{
      AppConstants.userLoginToken: 'token',
      AppConstants.analyticsClientId: 'test-client-id',
      AppConstants.languageCode: 'en',
    });
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final _ScriptedAdapter adapter = _ScriptedAdapter(
      (RequestOptions options) => options.path == '/api/v1/cash'
          ? window.future
          : Future<ResponseBody>.value(_json(<String, Object>{
              'storefront':
                  options.headers[AppConstants.storefrontHeader] ?? 'none',
            })),
    );
    final DioClient client = DioClient(
      'https://shop.test',
      Dio()..httpClientAdapter = adapter,
      loggingInterceptor: LoggingInterceptor(),
      sharedPreferences: preferences,
    );
    addTearDown(() {
      if (!window.isCompleted) window.complete(_json(300000));
    });

    final Future<Response> asked = client.get(
      '/api/v1/products/latest',
      queryParameters: <String, dynamic>{'limit': 10, 'offset': 1},
    );
    await pumpEventQueue();
    expect(adapter.requests.map((RequestOptions options) => options.path),
        <String>['/api/v1/cash'],
        reason: 'the request waits for the cache window');

    await preferences.setString(AppConstants.languageCode, 'ar');
    await preferences.setString(AppConstants.storefrontCountry, 'AE');
    client.updateHeader(null, 'ar');
    window.complete(_json(300000));
    await asked;

    final RequestOptions sent = adapter.requests.last;
    final String storefront = StorefrontConfig.enabled ? 'AE' : 'none';
    final String key =
        'api_cache_/api/v1/products/latest?limit=10&offset=1#ar${StorefrontConfig.enabled ? '#AE' : ''}';

    expect(sent.headers[AppConstants.langKey], 'ar');
    expect(sent.headers[AppConstants.storefrontHeader],
        StorefrontConfig.enabled ? 'AE' : isNull);
    expect(preferences.getString(key), '{"storefront":"$storefront"}');
    expect(
      preferences.getKeys().where((String key) => key.startsWith('api_cache_')),
      unorderedEquals(<String>[key, '${key}_time']),
    );
  });
}
