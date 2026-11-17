import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syriapharmacy/data/model/api_response.dart';
import 'package:syriapharmacy/features/storefront/domain/models/storefront_country.dart';
import 'package:syriapharmacy/features/storefront/domain/repositories/storefront_repository_interface.dart';
import 'package:syriapharmacy/features/storefront/domain/services/storefront_service.dart';

/// A repository double the tests script per scenario. No mocking package: the interface is three methods.
class _FakeStorefrontRepository implements StorefrontRepositoryInterface {
  _FakeStorefrontRepository({ApiResponseModel? answer})
      : answer = answer ?? ApiResponseModel.withError('offline');

  ApiResponseModel answer;
  List<StorefrontCountry> stored = <StorefrontCountry>[];
  int requests = 0;
  int saves = 0;

  @override
  Future<ApiResponseModel> getStorefronts() async {
    requests++;
    return answer;
  }

  @override
  List<StorefrontCountry> readStoredStorefronts() => stored;

  @override
  Future<bool> saveStorefronts(List<StorefrontCountry> storefronts) async {
    saves++;
    stored = storefronts;
    return true;
  }
}

ApiResponseModel _answerWith(Object? body, {int statusCode = 200}) {
  final RequestOptions request = RequestOptions(path: '/api/v1/storefronts');

  return ApiResponseModel.withSuccess(
    Response<Object?>(
      requestOptions: request,
      statusCode: statusCode,
      data: body,
    ),
  );
}

Map<String, Object> _listOf(List<Map<String, Object>> storefronts) =>
    <String, Object>{
      'enabled': true,
      'default_country': 'SA',
      'storefronts': storefronts,
    };

const Map<String, Object> _saudi = <String, Object>{
  'country': 'SA',
  'path': 'sa',
  'currency': 'SAR',
  'is_default': true,
  'sellable': true,
};

const Map<String, Object> _emirates = <String, Object>{
  'country': 'AE',
  'path': 'ae',
  'currency': 'AED',
  'is_default': false,
  'sellable': true,
};

String _describe(StorefrontCountry storefront) =>
    '${storefront.code} ${storefront.sellable ? 'sellable' : 'browse-only'}';

void main() {
  group('while storefronts are off', () {
    test('nothing is asked and nothing is stored', () async {
      final repository =
          _FakeStorefrontRepository(answer: _answerWith(_listOf([_saudi])));
      final service = StorefrontService(
        storefrontRepositoryInterface: repository,
        enabled: false,
      );

      final refreshed = await service.refreshStorefronts();

      expect(refreshed, isFalse);
      expect(repository.requests, 0);
      expect(repository.saves, 0);
    });

    test('is the default of a build made without the flag', () async {
      final repository =
          _FakeStorefrontRepository(answer: _answerWith(_listOf([_saudi])));
      final service =
          StorefrontService(storefrontRepositoryInterface: repository);

      expect(service.enabled, isFalse);
      expect(await service.refreshStorefronts(), isFalse);
      expect(repository.requests, 0);
    });
  });

  group('while storefronts are on', () {
    StorefrontService serviceOver(_FakeStorefrontRepository repository) =>
        StorefrontService(
          storefrontRepositoryInterface: repository,
          enabled: true,
        );

    test('a usable answer is stored and reported', () async {
      final repository = _FakeStorefrontRepository(
          answer: _answerWith(_listOf([_saudi, _emirates])));

      final refreshed = await serviceOver(repository).refreshStorefronts();

      expect(refreshed, isTrue);
      expect(repository.requests, 1);
      expect(repository.saves, 1);
      expect(repository.stored.map(_describe),
          <String>['SA sellable', 'AE sellable']);
    });

    test('a newer answer replaces the stored one', () async {
      final repository = _FakeStorefrontRepository(
          answer: _answerWith(_listOf([_saudi, _emirates])))
        ..stored = <StorefrontCountry>[
          StorefrontCountry.saudiArabia,
          StorefrontCountry.unitedArabEmirates,
        ];

      await serviceOver(repository).refreshStorefronts();

      expect(repository.stored.map(_describe),
          <String>['SA sellable', 'AE sellable']);
    });

    test(
        'an answer that leaves sellable out is stored with the built-in defaults',
        () async {
      final repository = _FakeStorefrontRepository(
        answer: _answerWith(_listOf([
          <String, Object>{
            'country': 'SA',
            'path': 'sa',
            'currency': 'SAR',
            'is_default': true,
          },
        ])),
      );

      await serviceOver(repository).refreshStorefronts();

      expect(repository.stored.map(_describe), <String>['SA sellable']);
    });

    test('a request that fails keeps the stored answer', () async {
      final repository = _FakeStorefrontRepository(
          answer: ApiResponseModel.withError('Connection timeout'))
        ..stored = <StorefrontCountry>[StorefrontCountry.unitedArabEmirates];

      final refreshed = await serviceOver(repository).refreshStorefronts();

      expect(refreshed, isFalse);
      expect(repository.requests, 1);
      expect(repository.saves, 0);
      expect(repository.stored.map(_describe), <String>['AE browse-only']);
    });

    test('an answer of an unknown shape keeps the stored answer', () async {
      for (final Object? body in <Object?>[
        null,
        '<html>maintenance</html>',
        <Object?>[],
        <String, Object>{'message': 'Server Error'},
        <String, Object>{'storefronts': 'AE'},
      ]) {
        final repository = _FakeStorefrontRepository(answer: _answerWith(body))
          ..stored = <StorefrontCountry>[StorefrontCountry.saudiArabia];

        final refreshed = await serviceOver(repository).refreshStorefronts();

        expect(refreshed, isFalse, reason: '$body');
        expect(repository.saves, 0, reason: '$body');
        expect(repository.stored.map(_describe), <String>['SA sellable'],
            reason: '$body');
      }
    });

    test('an empty list keeps the stored answer instead of wiping it',
        () async {
      final repository =
          _FakeStorefrontRepository(answer: _answerWith(_listOf([])))
            ..stored = <StorefrontCountry>[
              StorefrontCountry.saudiArabia,
              StorefrontCountry.unitedArabEmirates,
            ];

      final refreshed = await serviceOver(repository).refreshStorefronts();

      expect(refreshed, isFalse);
      expect(repository.saves, 0);
      expect(repository.stored, hasLength(2));
    });

    test('a list of entries that cannot be read keeps the stored answer',
        () async {
      final repository = _FakeStorefrontRepository(
        answer: _answerWith(_listOf([
          <String, Object>{'path': 'ae'},
          <String, Object>{'country': 'UAE'},
        ])),
      )..stored = <StorefrontCountry>[StorefrontCountry.saudiArabia];

      final refreshed = await serviceOver(repository).refreshStorefronts();

      expect(refreshed, isFalse);
      expect(repository.saves, 0);
    });

    test('asks once per refresh, never more', () async {
      final repository =
          _FakeStorefrontRepository(answer: _answerWith(_listOf([_saudi])));
      final service = serviceOver(repository);

      await service.refreshStorefronts();
      await service.refreshStorefronts();

      expect(repository.requests, 2);
    });
  });
}
