import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syriapharmacy/data/datasource/remote/dio/dio_client.dart';
import 'package:syriapharmacy/data/datasource/remote/dio/logging_interceptor.dart';
import 'package:syriapharmacy/features/storefront/domain/models/storefront_country.dart';
import 'package:syriapharmacy/features/storefront/domain/repositories/storefront_repository.dart';
import 'package:syriapharmacy/features/storefront/domain/services/storefront_service.dart';
import 'package:syriapharmacy/utill/app_constants.dart';

/// Answers every request from a script and remembers what was asked, so the repository and the service run over the real Dio client
/// without a network.
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

ResponseBody _json(Object body, {int statusCode = 200}) =>
    ResponseBody.fromString(
      jsonEncode(body),
      statusCode,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences preferences;

  Future<({StorefrontRepository repository, _ScriptedAdapter adapter})>
      repositoryAnswering(
    Future<ResponseBody> Function(RequestOptions options) answer,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      AppConstants.userLoginToken: 'token',
      AppConstants.analyticsClientId: 'test-client-id',
      AppConstants.languageCode: 'en',
    });
    preferences = await SharedPreferences.getInstance();

    final adapter = _ScriptedAdapter(answer);
    final dio = Dio()..httpClientAdapter = adapter;
    final dioClient = DioClient(
      'https://shop.test',
      dio,
      loggingInterceptor: LoggingInterceptor(),
      sharedPreferences: preferences,
    );

    return (
      repository: StorefrontRepository(
        dioClient: dioClient,
        sharedPreferences: preferences,
      ),
      adapter: adapter,
    );
  }

  final Map<String, Object> serverAnswer = <String, Object>{
    'enabled': true,
    'default_country': 'SA',
    'storefronts': <Object>[
      <String, Object>{
        'country': 'SA',
        'path': 'sa',
        'currency': 'SAR',
        'is_default': true,
        'sellable': true,
      },
      <String, Object>{
        'country': 'AE',
        'path': 'ae',
        'currency': 'AED',
        'is_default': false,
        'sellable': false,
      },
    ],
  };

  group('the request', () {
    test('is a GET of the public list, with the URI the backend serves',
        () async {
      final scripted =
          await repositoryAnswering((_) async => _json(serverAnswer));

      await scripted.repository.getStorefronts();

      expect(AppConstants.storefrontsUri, '/api/v1/storefronts');
      expect(scripted.adapter.requests, hasLength(1));
      expect(scripted.adapter.requests.single.method, 'GET');
      expect(scripted.adapter.requests.single.uri.toString(),
          'https://shop.test/api/v1/storefronts');
    });

    test('is read into the storefronts the server listed', () async {
      final scripted =
          await repositoryAnswering((_) async => _json(serverAnswer));

      final response = await scripted.repository.getStorefronts();

      expect(response.isSuccess, isTrue);
      final storefronts = StorefrontCountry.parseList(response.response.data);
      expect(
          storefronts
              .map((storefront) => '${storefront.code} ${storefront.sellable}'),
          <String>['SA true', 'AE false']);
    });
  });

  group('a request that fails', () {
    test('is an error answer, not a throw, for a server error', () async {
      final scripted = await repositoryAnswering((_) async =>
          _json(<String, Object>{'message': 'Server Error'}, statusCode: 500));

      final response = await scripted.repository.getStorefronts();

      expect(response.isSuccess, isFalse);
      expect(response.error, isA<String>());
    });

    test('is an error answer, not a throw, for a dropped connection', () async {
      final scripted = await repositoryAnswering((RequestOptions options) {
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
          error: 'offline',
        );
      });

      final response = await scripted.repository.getStorefronts();

      expect(response.isSuccess, isFalse);
    });

    test(
        'is an error answer for a 401 too, and the app\'s sign-out handling never sees it',
        () async {
      final scripted = await repositoryAnswering((_) async => _json(
          <String, Object>{'message': 'Unauthenticated.'},
          statusCode: 401));

      final response = await scripted.repository.getStorefronts();

      expect(response.isSuccess, isFalse);
      expect(preferences.getString(AppConstants.userLoginToken), 'token');
    });
  });

  group('the service over the real client', () {
    test('stores what the server answered and reads it back after a restart',
        () async {
      final scripted =
          await repositoryAnswering((_) async => _json(serverAnswer));
      final service = StorefrontService(
        storefrontRepositoryInterface: scripted.repository,
        enabled: true,
      );

      final refreshed = await service.refreshStorefronts();

      expect(refreshed, isTrue);
      final afterRestart = StorefrontRepository(
        dioClient: DioClient(
          'https://shop.test',
          Dio(),
          loggingInterceptor: LoggingInterceptor(),
          sharedPreferences: preferences,
        ),
        sharedPreferences: preferences,
      );
      expect(
        afterRestart
            .readStoredStorefronts()
            .map((storefront) => '${storefront.code} ${storefront.sellable}'),
        <String>['SA true', 'AE false'],
      );
    });

    test('keeps the stored answer when the server cannot be reached', () async {
      final scripted = await repositoryAnswering((RequestOptions options) {
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
          error: 'offline',
        );
      });
      await scripted.repository.saveStorefronts(<StorefrontCountry>[
        StorefrontCountry.saudiArabia,
        const StorefrontCountry(
          code: 'AE',
          path: '/ae',
          currency: 'AED',
          sellable: true,
        ),
      ]);
      final service = StorefrontService(
        storefrontRepositoryInterface: scripted.repository,
        enabled: true,
      );

      final refreshed = await service.refreshStorefronts();

      expect(refreshed, isFalse);
      expect(
        scripted.repository
            .readStoredStorefronts()
            .map((storefront) => '${storefront.code} ${storefront.sellable}'),
        <String>['SA true', 'AE true'],
      );
    });

    test('sends no request at all while storefronts are off', () async {
      final scripted =
          await repositoryAnswering((_) async => _json(serverAnswer));
      final service = StorefrontService(
        storefrontRepositoryInterface: scripted.repository,
        enabled: false,
      );

      await service.refreshStorefronts();

      expect(scripted.adapter.requests, isEmpty);
      expect(preferences.containsKey(AppConstants.storefrontList), isFalse);
    });
  });
}
