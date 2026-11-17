import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:syriapharmacy/data/model/api_response.dart';
import 'package:syriapharmacy/features/dynamic_theme/controllers/dynamic_theme_controller.dart';
import 'package:syriapharmacy/features/dynamic_theme/domain/models/theme_schema.dart';
import 'package:syriapharmacy/features/dynamic_theme/domain/services/dynamic_theme_service_interface.dart';
import 'package:syriapharmacy/features/storefront/domain/models/storefront_country.dart';
import 'package:syriapharmacy/features/storefront/storefront_change_notifier.dart';
import 'package:syriapharmacy/features/storefront/storefront_scope.dart';

const StorefrontChange _toEmirates = StorefrontChange(
  previous: StorefrontCountry.saudiArabia,
  current: StorefrontCountry.unitedArabEmirates,
  signedIn: false,
);

String get _who => StorefrontScope.current ?? 'none';

ThemePayload _page(String label, {String page = 'home'}) =>
    ThemePayload.fromJson(<String, Object>{
      'revision': 5,
      'checksum': label,
      'schema_version': 1,
      'engine_version': 1,
      'page': page,
      'sections': <Object>[
        <String, Object>{
          'uuid': 'u-$label',
          'id': 1,
          'type': 'spacer',
          'settings': <String, Object>{'height': 20},
        },
      ],
    });

/// A theme service that answers, like a server with storefronts, with the page of the storefront it is asked for, so what the controller
/// shows can be told by the checksum of its page.
class _ThemeServer implements DynamicThemeServiceInterface {
  /// The pages the cache holds, by storefront.
  final Map<String, ThemePayload> cached = <String, ThemePayload>{};

  /// While a page is in here, its request waits for it; the answer is still built for the storefront asked for at the time of the request.
  final Map<String, Completer<void>> holdPage = <String, Completer<void>>{};
  Completer<void>? holdSection;
  Completer<void>? holdRevision;
  Completer<void>? holdCached;
  final List<String> homeAskedFor = <String>[];
  final List<String?> checksumsSent = <String?>[];
  int revisionAsked = 0;

  @override
  Future<ThemeRevision> getRevision() async {
    revisionAsked++;
    await holdRevision?.future;
    return const ThemeRevision(
      revision: 5,
      checksum: 'version',
      schemaVersion: 1,
      engineVersion: 1,
    );
  }

  @override
  Future<ApiResponseModel<ThemePayload?>> getPayload({
    String page = 'home',
    String? knownChecksum,
  }) async {
    final String who = _who;
    if (page == 'home') {
      homeAskedFor.add(who);
      checksumsSent.add(knownChecksum);
    }
    await holdPage[page]?.future;

    return ApiResponseModel.withSuccess(_page('$page of $who', page: page));
  }

  @override
  Future<ThemePayload?> getCachedPayload({String page = 'home'}) async {
    final ThemePayload? payload = page == 'home' ? cached[_who] : null;
    await holdCached?.future;

    return payload;
  }

  @override
  Future<ApiResponseModel> getSectionData(SectionSource source) async {
    final String who = _who;
    await holdSection?.future;

    return ApiResponseModel.withSuccess('section of $who');
  }

  @override
  Future<void> dropCachedPayloads() async {}
}

/// The server-driven home when the shopper moves to another storefront. The version check on a build's revision knows nothing about a
/// storefront, so everything the controller holds is dropped and fetched again, and what was on its way when they moved is not kept.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _ThemeServer server;
  late DynamicThemeController controller;

  setUp(() async {
    StorefrontScope.publish('SA');
    server = _ThemeServer();
    controller = DynamicThemeController(dynamicThemeServiceInterface: server);
    await controller.sync();
  });

  tearDown(() {
    controller.dispose();
    StorefrontScope.publish(null);
  });

  test('the home page and its header are the first storefront\'s to begin with',
      () {
    expect(controller.payload.checksum, 'home of SA');
    expect(controller.headerSections, isNotEmpty);
  });

  test(
      'everything held is dropped at once, so the other storefront\'s home is never on screen',
      () async {
    await controller.loadPage('offers');
    await controller.loadSectionData(const ThemeSectionSchemaStub().section);
    expect(controller.page('offers')?.checksum, 'offers of SA');

    StorefrontScope.publish('AE');
    final Future<void> told = controller.onStorefrontChanged(_toEmirates);

    expect(controller.payload.checksum, isNot('home of SA'));
    expect(controller.hasPublishedTheme, isFalse);
    expect(controller.headerSections, isEmpty);
    expect(controller.page('offers'), isNull);
    expect(controller.pageFailed('offers'), isFalse);
    expect(controller.keyedData('u-section'), isNull);

    await told;
  });

  test(
      'and the new storefront\'s home is fetched by force, with no checksum of the old one',
      () async {
    server.checksumsSent.clear();
    server.revisionAsked = 0;

    StorefrontScope.publish('AE');
    await controller.onStorefrontChanged(_toEmirates);

    expect(controller.payload.checksum, 'home of AE');
    expect(server.homeAskedFor.last, 'AE');
    expect(server.checksumsSent, <String?>[null]);
    expect(server.revisionAsked, 0,
        reason: 'a forced fetch skips the version check');
  });

  test(
      'the new storefront\'s cached home is on screen before the download ends',
      () async {
    final Completer<void> hold = Completer<void>();
    server.cached['AE'] = _page('cached home of AE');
    server.holdPage['home'] = hold;
    addTearDown(() {
      if (!hold.isCompleted) hold.complete();
    });

    StorefrontScope.publish('AE');
    final Future<void> told = controller.onStorefrontChanged(_toEmirates);
    await pumpEventQueue();

    expect(controller.payload.checksum, 'cached home of AE');

    hold.complete();
    await told;
    expect(controller.payload.checksum, 'home of AE');
  });

  test(
      'a page the shopper opened on the other storefront is fetched again when it is opened again',
      () async {
    await controller.loadPage('offers');

    StorefrontScope.publish('AE');
    await controller.onStorefrontChanged(_toEmirates);
    await controller.loadPage('offers');

    expect(controller.page('offers')?.checksum, 'offers of AE');
  });

  test('a page on its way when the shopper moved on is not kept', () async {
    final Completer<void> hold = Completer<void>();
    server.holdPage['offers'] = hold;
    addTearDown(() {
      if (!hold.isCompleted) hold.complete();
    });

    final Future<void> loading = controller.loadPage('offers');
    await pumpEventQueue();
    StorefrontScope.publish('AE');
    final Future<void> told = controller.onStorefrontChanged(_toEmirates);
    hold.complete();
    await loading;
    await told;

    expect(controller.page('offers'), isNull);
    expect(controller.pageFailed('offers'), isFalse);
  });

  test(
      'a sync on its way when the shopper moved on is not kept, and the new storefront\'s is fetched when it ends',
      () async {
    final Completer<void> hold = Completer<void>();
    server.holdPage['home'] = hold;
    addTearDown(() {
      if (!hold.isCompleted) hold.complete();
    });
    server.homeAskedFor.clear();

    final Future<void> syncing = controller.sync(force: true);
    await pumpEventQueue();
    expect(server.homeAskedFor, <String>['SA']);

    StorefrontScope.publish('AE');
    await controller.onStorefrontChanged(_toEmirates);
    expect(controller.hasPublishedTheme, isFalse,
        reason: 'the refresh waits for the sync that is still running');

    server.holdPage.remove('home');
    hold.complete();
    await syncing;

    expect(server.homeAskedFor, <String>['SA', 'AE']);
    expect(controller.payload.checksum, 'home of AE');
  });

  test('a version check on its way when the shopper moved on is not acted on',
      () async {
    final Completer<void> hold = Completer<void>();
    server.holdRevision = hold;
    addTearDown(() {
      if (!hold.isCompleted) hold.complete();
    });
    server.homeAskedFor.clear();

    final Future<void> syncing = controller.sync();
    await pumpEventQueue();
    StorefrontScope.publish('AE');
    await controller.onStorefrontChanged(_toEmirates);
    server.holdRevision = null;
    hold.complete();
    await syncing;

    expect(server.homeAskedFor, <String>['AE'],
        reason: 'only the refresh the change asked for fetches the page');
    expect(controller.payload.checksum, 'home of AE');
  });

  test('a header on its way when the shopper moved on is not kept', () async {
    final Completer<void> header = Completer<void>();
    final Completer<void> home = Completer<void>();
    server.holdPage['header'] = header;
    addTearDown(() {
      if (!header.isCompleted) header.complete();
      if (!home.isCompleted) home.complete();
    });

    final Future<void> syncing = controller.sync(force: true);
    await pumpEventQueue();
    StorefrontScope.publish('AE');
    await controller.onStorefrontChanged(_toEmirates);
    server.holdPage
      ..remove('header')
      ..['home'] = home;
    header.complete();
    await pumpEventQueue();

    expect(controller.headerSections, isEmpty,
        reason: 'the header of the other storefront is not shown');
    expect(controller.hasPublishedTheme, isFalse);

    home.complete();
    await syncing;
    expect(controller.payload.checksum, 'home of AE');
  });

  test('a cached home on its way when the shopper moved on is not shown',
      () async {
    final DynamicThemeController fresh =
        DynamicThemeController(dynamicThemeServiceInterface: server);
    addTearDown(fresh.dispose);
    final Completer<void> cache = Completer<void>();
    final Completer<void> home = Completer<void>();
    server
      ..cached['SA'] = _page('cached home of SA')
      ..holdCached = cache;
    addTearDown(() {
      if (!cache.isCompleted) cache.complete();
      if (!home.isCompleted) home.complete();
    });

    final Future<void> syncing = fresh.sync();
    await pumpEventQueue();
    StorefrontScope.publish('AE');
    await fresh.onStorefrontChanged(_toEmirates);
    server
      ..holdCached = null
      ..holdPage['home'] = home;
    cache.complete();
    await pumpEventQueue();

    expect(fresh.payload.checksum, isNot('cached home of SA'));
    expect(fresh.hasPublishedTheme, isFalse);

    home.complete();
    await syncing;
    expect(fresh.payload.checksum, 'home of AE');
  });

  test('data a section fetched is dropped, and data on its way is not kept',
      () async {
    final ThemeSectionSchemaStub stub = const ThemeSectionSchemaStub();
    await controller.loadKeyedData(stub.key, stub.source);
    expect(controller.keyedData(stub.key)?.response, 'section of SA');

    final Completer<void> hold = Completer<void>();
    server.holdSection = hold;
    addTearDown(() {
      if (!hold.isCompleted) hold.complete();
    });

    StorefrontScope.publish('AE');
    await controller.onStorefrontChanged(_toEmirates);
    expect(controller.keyedData(stub.key), isNull);

    final Future<void> loading =
        controller.loadKeyedData(stub.key, stub.source);
    await pumpEventQueue();
    StorefrontScope.publish('KW');
    hold.complete();
    await loading;

    expect(controller.keyedData(stub.key), isNull);
  });

  test('a language switch behaves as it did', () async {
    server.homeAskedFor.clear();

    await controller.onLanguageChanged();

    expect(server.homeAskedFor, <String>['SA']);
    expect(controller.payload.checksum, 'home of SA');
  });
}

/// One API-backed section, to give the controller something to fetch.
class ThemeSectionSchemaStub {
  const ThemeSectionSchemaStub();

  String get key => 'u-section';

  SectionSource get source =>
      const SectionSource(kind: 'api', endpoint: '/api/v1/products/latest');

  ThemeSectionSchema get section =>
      ThemeSectionSchema.fromJson(<String, Object>{
        'uuid': key,
        'id': 9,
        'type': 'spacer',
        'settings': <String, Object>{'height': 20},
        'source': <String, Object>{
          'kind': 'api',
          'endpoint': '/api/v1/products/latest',
        },
      });
}
