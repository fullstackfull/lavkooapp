import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syriapharmacy/common/enums/data_source_enum.dart';
import 'package:syriapharmacy/data/datasource/remote/dio/dio_client.dart';
import 'package:syriapharmacy/data/datasource/remote/dio/logging_interceptor.dart';
import 'package:syriapharmacy/data/local/cache_response.dart';
import 'package:syriapharmacy/data/model/api_response.dart';
import 'package:syriapharmacy/data/reposotories/data_sync_repo.dart';
import 'package:syriapharmacy/features/deal/controllers/flash_deal_controller.dart';
import 'package:syriapharmacy/features/deal/domain/services/flash_deal_service_interface.dart';
import 'package:syriapharmacy/features/dynamic_theme/domain/repositories/dynamic_theme_repository.dart';
import 'package:syriapharmacy/features/order/controllers/order_controller.dart';
import 'package:syriapharmacy/features/order/domain/services/order_service_interface.dart';
import 'package:syriapharmacy/features/storefront/storefront_scope.dart';
import 'package:syriapharmacy/features/shop/controllers/shop_controller.dart';
import 'package:syriapharmacy/features/shop/domain/services/shop_service_interface.dart';
import 'package:syriapharmacy/helper/data_sync_helper.dart';
import 'package:syriapharmacy/helper/db_helper.dart';
import 'package:syriapharmacy/utill/app_constants.dart';

/// Answers every request from a script, one answer at a time, and remembers what was asked.
class _ScriptedAdapter implements HttpClientAdapter {
  _ScriptedAdapter(this.answer);

  Future<ResponseBody> Function(RequestOptions options) answer;
  final List<RequestOptions> requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    requests.add(options);
    return answer(options);
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

Response<dynamic> _ok(Object? body) => Response<dynamic>(
      requestOptions: RequestOptions(path: '/'),
      statusCode: 200,
      data: body,
    );

class _FakeFlashDealService implements FlashDealServiceInterface {
  Future<dynamic> Function() deal = () async => ApiResponseModel.withError('x');
  int dealAsked = 0;

  @override
  Future<dynamic> getFlashDeal() {
    dealAsked++;
    return deal();
  }

  @override
  Future<dynamic> get(String productID) async => ApiResponseModel.withSuccess(
      _ok(<String, Object>{'products': <Object>[]}));
}

class _FakeOrderService implements OrderServiceInterface {
  Future<dynamic> Function() orders =
      () async => ApiResponseModel.withError('x');

  @override
  Future<dynamic> getOrderList(int offset, String status, {String? type}) =>
      orders();

  @override
  Future<dynamic> getTrackingInfo(String orderID) async =>
      ApiResponseModel.withError('x');

  @override
  Future<dynamic> cancelOrder(int? orderId) async =>
      ApiResponseModel.withError('x');
}

class _FakeShopService extends Fake implements ShopServiceInterface {
  Future<dynamic> Function() products =
      () async => ApiResponseModel.withError('x');

  @override
  Future<dynamic> getClearanceShopProductList(
          String type, String offset, String sellerId) =>
      products();
}

/// A database that moves the app to another storefront while a row is being looked up: the race the database helper guards.
class _SwitchingDatabase extends AppDatabase {
  _SwitchingDatabase() : super.forTesting(NativeDatabase.memory());

  String? switchWhileLookingUp;

  @override
  Future<CacheResponseData?> getCacheResponseById(String endPoint) async {
    final CacheResponseData? row = await super.getCacheResponseById(endPoint);
    if (switchWhileLookingUp != null) {
      StorefrontScope.publish(switchWhileLookingUp);
    }

    return row;
  }
}

Map<String, Object?> _productPage(String label) => <String, Object?>{
      'total_size': 1,
      'limit': 10,
      'offset': 1,
      'products': <Object>[
        <String, Object?>{'id': 1, 'name': label},
      ],
    };

Map<String, Object?> _flashDeal(int id) => <String, Object?>{
      'id': id,
      'title': 'deal $id',
      'start_date': '2000-01-01',
      // In the past, so the controller starts no countdown timer.
      'end_date': '2000-01-02',
    };

Map<String, Object?> _orders(int total) => <String, Object?>{
      'total_size': total,
      'limit': '10',
      'offset': '1',
      'orders': <Object>[],
    };

Map<String, Object?> _themePage(String label) => <String, Object?>{
      'revision': 3,
      'checksum': 'checksum of $label',
      'schema_version': 1,
      'engine_version': 1,
      'page': 'home',
      'sections': <Object>[
        <String, Object?>{
          'uuid': 'u-$label',
          'id': 1,
          'type': 'spacer',
          'settings': <String, Object>{'height': 20},
        },
      ],
    };

/// Every cache of the app that keeps an answer in the local database, once for the build with storefronts off, whose rows must be what
/// they always were, and once with them on, whose rows must never be read by another storefront. The storefront is the one the HTTP client
/// publishes, so both settings run in one test run, over a real SQLite database in memory.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const String dataSyncUri = '/api/v1/products/just-for-you?guest_id=1';

  late AppDatabase database;
  late SharedPreferences preferences;
  late _ScriptedAdapter adapter;
  late DioClient client;

  Future<List<String>> storedKeys() async =>
      (await database.getAllCacheResponses())
          .map((CacheResponseData row) => row.endPoint)
          .toList()
        ..sort();

  setUp(() async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    database = AppDatabase.forTesting(NativeDatabase.memory());
    SharedPreferences.setMockInitialValues(<String, Object>{
      AppConstants.userLoginToken: 'token',
      AppConstants.analyticsClientId: 'test-client-id',
      AppConstants.languageCode: 'en',
    });
    preferences = await SharedPreferences.getInstance();
    adapter = _ScriptedAdapter((RequestOptions options) async =>
        _json(<String, Object>{'answer': 'default'}));
    client = DioClient(
      'https://shop.test',
      Dio()..httpClientAdapter = adapter,
      loggingInterceptor: LoggingInterceptor(),
      sharedPreferences: preferences,
    );
    StorefrontScope.publish(null);
  });

  tearDown(() async {
    StorefrontScope.publish(null);
    await database.close();
  });

  group('the data sync rows', () {
    late DataSyncRepo repo;

    setUp(() {
      repo = DataSyncRepo(
        dioClient: client,
        sharedPreferences: preferences,
        localDatabase: database,
      );
    });

    Future<ApiResponseModel<Response>> fetchFor(
      String? storefront, {
      String answer = 'default',
    }) {
      StorefrontScope.publish(storefront);
      adapter.answer = (RequestOptions options) async =>
          _json(<String, Object>{'answer': answer});
      return repo.fetchData<Response>(dataSyncUri, DataSourceEnum.client);
    }

    Future<ApiResponseModel<CacheResponseData>> readFor(String? storefront) {
      StorefrontScope.publish(storefront);
      return repo.fetchData<CacheResponseData>(
          dataSyncUri, DataSourceEnum.local);
    }

    String? cachedAnswer(ApiResponseModel<CacheResponseData> read) =>
        (jsonDecode(read.response!.response) as Map)['answer'] as String?;

    group('while storefronts are off', () {
      test('an answer is filed under the key it always had', () async {
        await fetchFor(null);

        expect(await storedKeys(), <String>['$dataSyncUri#en']);
      });

      test('and is read back by it, in the language it was asked for',
          () async {
        await fetchFor(null, answer: 'english');
        final ApiResponseModel<CacheResponseData> read = await readFor(null);

        expect(read.isSuccess, isTrue);
        expect(cachedAnswer(read), 'english');

        await preferences.setString(AppConstants.languageCode, 'ar');
        expect((await readFor(null)).isSuccess, isFalse);
      });

      test('a row an earlier release filed is still found', () async {
        await database.insertCacheResponse(CacheResponseCompanion.insert(
          endPoint: '$dataSyncUri#en',
          header: '{}',
          response: '{"answer":"kept from an earlier release"}',
        ));

        final ApiResponseModel<CacheResponseData> read = await readFor(null);

        expect(cachedAnswer(read), 'kept from an earlier release');
      });
    });

    group('while storefronts are on', () {
      test('an answer is filed under the storefront it was asked for',
          () async {
        await fetchFor('SA');
        await fetchFor('AE');

        expect(await storedKeys(), <String>[
          '$dataSyncUri#en#AE',
          '$dataSyncUri#en#SA',
        ]);
      });

      test('two storefronts never read each other\'s rows', () async {
        await fetchFor('SA', answer: 'saudi');

        expect((await readFor('AE')).isSuccess, isFalse);

        await fetchFor('AE', answer: 'emirates');
        expect(cachedAnswer(await readFor('AE')), 'emirates');
        expect(cachedAnswer(await readFor('SA')), 'saudi');
      });

      test('a row filed before storefronts were on is never read', () async {
        await database.insertCacheResponse(CacheResponseCompanion.insert(
          endPoint: '$dataSyncUri#en',
          header: '{}',
          response: '{"answer":"legacy"}',
        ));

        expect((await readFor('SA')).isSuccess, isFalse);
      });

      test(
          'an answer that arrives after the customer chose another storefront is handed back and filed nowhere',
          () async {
        final Completer<ResponseBody> held = Completer<ResponseBody>();
        addTearDown(() {
          if (!held.isCompleted) held.complete(_json(<String, Object>{}));
        });
        StorefrontScope.publish('SA');
        adapter.answer = (RequestOptions options) => held.future;

        final Future<ApiResponseModel<Response>> asked =
            repo.fetchData<Response>(dataSyncUri, DataSourceEnum.client);
        await pumpEventQueue();
        StorefrontScope.publish('AE');
        held.complete(_json(<String, Object>{'answer': 'saudi'}));
        final ApiResponseModel<Response> answered = await asked;

        expect(answered.isSuccess, isTrue);
        expect(await storedKeys(), isEmpty);
      });
    });
  });

  group('the data sync helper', () {
    Future<ApiResponseModel<CacheResponseData>> localAnswer() async =>
        ApiResponseModel.withSuccess(const CacheResponseData(
          id: 1,
          endPoint: 'x',
          header: '{}',
          response: '{"from":"local"}',
          isSuccess: true,
        ));

    Future<ApiResponseModel<Response>> clientAnswer() async =>
        ApiResponseModel.withSuccess(_ok(<String, Object>{'from': 'client'}));

    test('hands on the local answer, then the client\'s, as it always did',
        () async {
      final List<String> delivered = <String>[];

      await DataSyncHelper.fetchAndSyncData(
        fetchFromLocal: localAnswer,
        fetchFromClient: clientAnswer,
        onResponse: (dynamic data, DataSourceEnum source) =>
            delivered.add('${(data as Map)['from']} ${source.name}'),
      );

      expect(delivered, <String>['local local', 'client client']);
    });

    test('does the same on a storefront that does not change', () async {
      StorefrontScope.publish('SA');
      final List<String> delivered = <String>[];

      await DataSyncHelper.fetchAndSyncData(
        fetchFromLocal: localAnswer,
        fetchFromClient: clientAnswer,
        onResponse: (dynamic data, DataSourceEnum source) =>
            delivered.add('${(data as Map)['from']}'),
      );

      expect(delivered, <String>['local', 'client']);
    });

    test(
        'drops both answers, and asks nothing more, when the storefront changes while the local one is read',
        () async {
      StorefrontScope.publish('SA');
      final List<String> delivered = <String>[];
      int clientAsked = 0;

      await DataSyncHelper.fetchAndSyncData(
        fetchFromLocal: () async {
          StorefrontScope.publish('AE');
          return localAnswer();
        },
        fetchFromClient: () {
          clientAsked++;
          return clientAnswer();
        },
        onResponse: (dynamic data, DataSourceEnum source) =>
            delivered.add('${(data as Map)['from']}'),
      );

      expect(delivered, isEmpty);
      expect(clientAsked, 0);
    });

    test(
        'keeps the local answer and drops the client\'s when the storefront changes while that is on its way',
        () async {
      StorefrontScope.publish('SA');
      final List<String> delivered = <String>[];

      await DataSyncHelper.fetchAndSyncData(
        fetchFromLocal: localAnswer,
        fetchFromClient: () async {
          StorefrontScope.publish('AE');
          return clientAnswer();
        },
        onResponse: (dynamic data, DataSourceEnum source) =>
            delivered.add('${(data as Map)['from']}'),
      );

      expect(delivered, <String>['local']);
    });

    test('keeps an answer for a storefront the customer left and came back to',
        () async {
      StorefrontScope.publish('SA');
      final List<String> delivered = <String>[];

      await DataSyncHelper.fetchAndSyncData(
        fetchFromLocal: localAnswer,
        fetchFromClient: () async {
          StorefrontScope.publish('AE');
          StorefrontScope.publish('SA');
          return clientAnswer();
        },
        onResponse: (dynamic data, DataSourceEnum source) =>
            delivered.add('${(data as Map)['from']}'),
      );

      expect(delivered, <String>['local', 'client']);
    });
  });

  group('the theme payload rows', () {
    late DynamicThemeRepository repository;

    setUp(() {
      repository = DynamicThemeRepository(
        dioClient: client,
        localDatabase: database,
      );
    });

    Future<ApiResponseModel<dynamic>> fetchFor(String? storefront) {
      StorefrontScope.publish(storefront);
      adapter.answer = (RequestOptions options) async =>
          _json(_themePage(storefront ?? 'none'));
      return repository.fetchPayload(page: 'home');
    }

    Future<String?> cachedChecksum(String? storefront) async {
      StorefrontScope.publish(storefront);
      return (await repository.readCachedPayload(page: 'home'))?.checksum;
    }

    group('while storefronts are off', () {
      test('the page is filed under the key it always had', () async {
        await fetchFor(null);

        expect(await storedKeys(), <String>['/api/v1/theme/home::home']);
        expect(await cachedChecksum(null), 'checksum of none');
      });

      test('dropping the pages takes every page', () async {
        await fetchFor(null);
        await database.insertCacheResponse(CacheResponseCompanion.insert(
          endPoint: '/api/v1/theme/home::header',
          header: '{}',
          response: '{}',
        ));

        await repository.dropCachedPayloads();

        expect(await storedKeys(), isEmpty);
      });
    });

    group('while storefronts are on', () {
      test('the page is filed under the storefront it was fetched for',
          () async {
        await fetchFor('SA');
        await fetchFor('AE');

        expect(await storedKeys(), <String>[
          '/api/v1/theme/home::home#AE',
          '/api/v1/theme/home::home#SA',
        ]);
      });

      test('two storefronts never read each other\'s page', () async {
        await fetchFor('SA');

        expect(await cachedChecksum('AE'), isNull);

        await fetchFor('AE');
        expect(await cachedChecksum('AE'), 'checksum of AE');
        expect(await cachedChecksum('SA'), 'checksum of SA');
      });

      test('a page filed before storefronts were on is never read', () async {
        await fetchFor(null);

        expect(await cachedChecksum('SA'), isNull);
      });

      test('dropping the pages takes the storefront\'s own and no other\'s',
          () async {
        await fetchFor('SA');
        await fetchFor('AE');

        StorefrontScope.publish('AE');
        await repository.dropCachedPayloads();

        expect(await storedKeys(), <String>['/api/v1/theme/home::home#SA']);
      });

      test(
          'a page that arrives after the customer chose another storefront is neither cached nor handed on',
          () async {
        final Completer<ResponseBody> held = Completer<ResponseBody>();
        addTearDown(() {
          if (!held.isCompleted) held.complete(_json(<String, Object>{}));
        });
        StorefrontScope.publish('SA');
        adapter.answer = (RequestOptions options) => held.future;

        final Future<ApiResponseModel<dynamic>> asked =
            repository.fetchPayload(page: 'home');
        await pumpEventQueue();
        StorefrontScope.publish('AE');
        held.complete(_json(_themePage('SA')));
        final ApiResponseModel<dynamic> answered = await asked;

        expect(answered.isSuccess, isFalse);
        expect(await storedKeys(), isEmpty);
      });
    });
  });

  group('the flash deal rows', () {
    late _FakeFlashDealService service;
    late FlashDealController controller;

    setUp(() {
      service = _FakeFlashDealService();
      controller = FlashDealController(
        flashDealServiceInterface: service,
        localDatabase: database,
      );
    });

    Future<void> loadFor(String? storefront, int dealId) {
      StorefrontScope.publish(storefront);
      service.deal =
          () async => ApiResponseModel.withSuccess(_ok(_flashDeal(dealId)));
      return controller.getFlashDealList(true, true);
    }

    /// What a fresh controller shows before the network answers, which is what is in the table for the storefront.
    Future<int?> shownFromTable(String? storefront) async {
      StorefrontScope.publish(storefront);
      final Completer<dynamic> neverAnswered = Completer<dynamic>();
      final _FakeFlashDealService silent = _FakeFlashDealService()
        ..deal = () => neverAnswered.future;
      final FlashDealController fresh = FlashDealController(
        flashDealServiceInterface: silent,
        localDatabase: database,
      );
      unawaited(fresh.getFlashDealList(true, true));
      await pumpEventQueue();

      return fresh.flashDeal?.id;
    }

    group('while storefronts are off', () {
      test('the deal and its products are filed under the keys they always had',
          () async {
        await loadFor(null, 1);

        expect(
            await storedKeys(),
            <String>[
              AppConstants.flashDealUri,
              AppConstants.flashDealProductUri,
            ]..sort());
        expect(await shownFromTable(null), 1);
      });
    });

    group('while storefronts are on', () {
      test('they are filed under the storefront they were fetched for',
          () async {
        await loadFor('SA', 1);
        await loadFor('AE', 2);

        expect(
            await storedKeys(),
            <String>[
              '${AppConstants.flashDealUri}#AE',
              '${AppConstants.flashDealUri}#SA',
              '${AppConstants.flashDealProductUri}#AE',
              '${AppConstants.flashDealProductUri}#SA',
            ]..sort());
      });

      test('two storefronts never show each other\'s deal', () async {
        await loadFor('SA', 1);

        expect(await shownFromTable('AE'), isNull);

        await loadFor('AE', 2);
        expect(await shownFromTable('AE'), 2);
        expect(await shownFromTable('SA'), 1);
      });

      test('a deal filed before storefronts were on is never shown', () async {
        await loadFor(null, 1);

        expect(await shownFromTable('SA'), isNull);
      });

      test(
          'a deal that arrives after the customer chose another storefront is neither shown nor filed',
          () async {
        final Completer<dynamic> held = Completer<dynamic>();
        addTearDown(() {
          if (!held.isCompleted) held.complete(ApiResponseModel.withError('x'));
        });
        StorefrontScope.publish('SA');
        service.deal = () => held.future;

        final Future<void> loading = controller.getFlashDealList(true, true);
        await pumpEventQueue();
        StorefrontScope.publish('AE');
        held.complete(ApiResponseModel.withSuccess(_ok(_flashDeal(1))));
        await loading;

        expect(controller.flashDeal, isNull);
        expect(await storedKeys(), isEmpty);
      });
    });
  });

  group('the delivered orders row', () {
    late _FakeOrderService service;
    late OrderController controller;

    setUp(() {
      service = _FakeOrderService();
      controller = OrderController(
        orderServiceInterface: service,
        localDatabase: database,
      );
    });

    Future<void> loadFor(String? storefront, int total) {
      StorefrontScope.publish(storefront);
      service.orders =
          () async => ApiResponseModel.withSuccess(_ok(_orders(total)));
      return controller.getOrderList(1, 'delivered', type: 'reorder');
    }

    /// What the reorder list shows before the network answers.
    Future<int?> shownFromTable(String? storefront) async {
      StorefrontScope.publish(storefront);
      final Completer<dynamic> neverAnswered = Completer<dynamic>();
      final _FakeOrderService silent = _FakeOrderService()
        ..orders = () => neverAnswered.future;
      final OrderController fresh = OrderController(
        orderServiceInterface: silent,
        localDatabase: database,
      );
      unawaited(fresh.getOrderList(1, 'delivered', type: 'reorder'));
      await pumpEventQueue();

      return fresh.deliveredOrderModel?.totalSize;
    }

    test('while storefronts are off it is filed under the key it always had',
        () async {
      await loadFor(null, 11);

      expect(await storedKeys(), <String>[AppConstants.orderUri]);
      expect(await shownFromTable(null), 11);
    });

    test('while storefronts are on, two storefronts never show each other\'s',
        () async {
      await loadFor('SA', 11);

      expect(await storedKeys(), <String>['${AppConstants.orderUri}#SA']);
      expect(await shownFromTable('AE'), isNull);

      await loadFor('AE', 22);
      expect(await shownFromTable('AE'), 22);
      expect(await shownFromTable('SA'), 11);
    });

    test('a row filed before storefronts were on is never shown', () async {
      await loadFor(null, 11);

      expect(await shownFromTable('SA'), isNull);
    });

    test(
        'orders that arrive after the customer chose another storefront are neither shown nor filed',
        () async {
      final Completer<dynamic> held = Completer<dynamic>();
      addTearDown(() {
        if (!held.isCompleted) held.complete(ApiResponseModel.withError('x'));
      });
      StorefrontScope.publish('SA');
      service.orders = () => held.future;

      final Future<void> loading =
          controller.getOrderList(1, 'delivered', type: 'reorder');
      await pumpEventQueue();
      StorefrontScope.publish('AE');
      held.complete(ApiResponseModel.withSuccess(_ok(_orders(11))));
      await loading;

      expect(controller.deliveredOrderModel, isNull);
      expect(await storedKeys(), isEmpty);
    });
  });

  group('every other row, which the app files by the key it builds', () {
    // The config, a shop's clearance products and the rest reach the table through the same methods as the rows above, so the table's
    // rule files them too. The key each of them builds, as the app builds it.
    final Map<String, String> keys = <String, String>{
      'the shop config': AppConstants.configUri,
      'a shop\'s clearance products':
          '${AppConstants.clearanceShopProductUri}a-shop/products?guest_id=1&limit=10&offset=1&offer_type=clearance_sale',
      'the header page of the theme': '${AppConstants.themeHomeUri}::header',
      'an answer of the data sync layer': '${AppConstants.brandUri}#ar',
    };

    for (final MapEntry<String, String> entry in keys.entries) {
      test('${entry.key}: filed under its own key while storefronts are off',
          () async {
        await database.insertCacheResponse(CacheResponseCompanion.insert(
          endPoint: entry.value,
          header: '{}',
          response: '{}',
        ));

        expect(await storedKeys(), <String>[entry.value]);
        expect(await database.getCacheResponseById(entry.value), isNotNull);
      });

      test('${entry.key}: never read by another storefront while they are on',
          () async {
        StorefrontScope.publish('SA');
        await database.insertCacheResponse(CacheResponseCompanion.insert(
          endPoint: entry.value,
          header: '{}',
          response: '{"for":"SA"}',
        ));

        StorefrontScope.publish('AE');
        expect(await database.getCacheResponseById(entry.value), isNull);

        StorefrontScope.publish('SA');
        expect(
          (await database.getCacheResponseById(entry.value))?.response,
          '{"for":"SA"}',
        );
        expect(await storedKeys(), <String>['${entry.value}#SA']);
      });
    }
  });

  group('the clearance products of a shop', () {
    const String slug = 'a-shop';
    final String rowKey =
        '${AppConstants.clearanceShopProductUri}$slug/products?guest_id=1&limit=10&offset=1&offer_type=clearance_sale';
    late _FakeShopService service;
    late ShopController controller;

    setUp(() {
      service = _FakeShopService();
      controller = ShopController(
        shopServiceInterface: service,
        localDatabase: database,
      );
    });

    Future<void> loadFor(String? storefront, String label) {
      StorefrontScope.publish(storefront);
      service.products =
          () async => ApiResponseModel.withSuccess(_ok(_productPage(label)));
      return controller.getClearanceShopProductList(
          'clearance_sale', '1', slug);
    }

    /// What a fresh controller shows before the network answers.
    Future<String?> shownFromTable(String? storefront) async {
      StorefrontScope.publish(storefront);
      final Completer<dynamic> neverAnswered = Completer<dynamic>();
      final _FakeShopService silent = _FakeShopService()
        ..products = () => neverAnswered.future;
      final ShopController fresh = ShopController(
        shopServiceInterface: silent,
        localDatabase: database,
      );
      unawaited(fresh.getClearanceShopProductList('clearance_sale', '1', slug));
      await pumpEventQueue();

      return fresh.clearanceProductModel?.products?.single.name;
    }

    test(
        'while storefronts are off they are filed under the key they always had',
        () async {
      await loadFor(null, 'products');

      expect(await storedKeys(), <String>[rowKey]);
      expect(await shownFromTable(null), 'products');
    });

    test('while storefronts are on, two storefronts never show each other\'s',
        () async {
      await loadFor('SA', 'saudi products');

      expect(await storedKeys(), <String>['$rowKey#SA']);
      expect(await shownFromTable('AE'), isNull);

      await loadFor('AE', 'emirates products');
      expect(await shownFromTable('AE'), 'emirates products');
      expect(await shownFromTable('SA'), 'saudi products');
    });

    test(
        'products that arrive after the customer chose another storefront are neither shown nor filed',
        () async {
      final Completer<dynamic> held = Completer<dynamic>();
      addTearDown(() {
        if (!held.isCompleted) held.complete(ApiResponseModel.withError('x'));
      });
      StorefrontScope.publish('SA');
      service.products = () => held.future;

      final Future<void> loading =
          controller.getClearanceShopProductList('clearance_sale', '1', slug);
      await pumpEventQueue();
      StorefrontScope.publish('AE');
      held.complete(ApiResponseModel.withSuccess(_ok(_productPage('saudi'))));
      await loading;

      expect(controller.clearanceProductModel, isNull);
      expect(await storedKeys(), isEmpty);
    });
  });

  group('the database helper', () {
    CacheResponseCompanion row() => CacheResponseCompanion.insert(
          endPoint: 'a-key',
          header: '{}',
          response: '{}',
        );

    test('writes a row for the storefront it looked the row up for', () async {
      StorefrontScope.publish('SA');

      await DbHelper.insertOrUpdate(
          id: 'a-key', data: row(), localDatabase: database);

      expect(await storedKeys(), <String>['a-key#SA']);
    });

    test('writes nothing when the customer moved on while it looked', () async {
      final _SwitchingDatabase switching = _SwitchingDatabase()
        ..switchWhileLookingUp = 'AE';
      addTearDown(switching.close);
      StorefrontScope.publish('SA');

      await DbHelper.insertOrUpdate(
          id: 'a-key', data: row(), localDatabase: switching);

      StorefrontScope.publish('AE');
      expect(await switching.getAllCacheResponses(), isEmpty);
      StorefrontScope.publish('SA');
      expect(await switching.getAllCacheResponses(), isEmpty);
    });
  });
}
