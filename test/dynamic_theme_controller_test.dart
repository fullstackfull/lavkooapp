import 'package:flutter_test/flutter_test.dart';
import 'package:syriapharmacy/data/model/api_response.dart';
import 'package:syriapharmacy/features/dynamic_theme/controllers/dynamic_theme_controller.dart';
import 'package:syriapharmacy/features/dynamic_theme/domain/models/theme_schema.dart';
import 'package:syriapharmacy/features/dynamic_theme/domain/services/dynamic_theme_service_interface.dart';

/// A service double the tests script per scenario. No mocking package: the interface is four
/// methods and a hand-rolled fake keeps the failure output readable.
class _FakeThemeService implements DynamicThemeServiceInterface {
  int droppedCaches = 0;

  ThemeRevision revision = ThemeRevision.none;
  ApiResponseModel<ThemePayload?> payloadResponse =
      ApiResponseModel.withSuccess(null);
  ApiResponseModel<ThemePayload?> headerResponse =
      ApiResponseModel.withSuccess(null);
  ThemePayload? cached;
  ThemePayload? cachedHeader;

  int revisionCalls = 0;
  int payloadCalls = 0;
  int headerCalls = 0;
  String? lastChecksumSent;

  @override
  Future<ThemeRevision> getRevision() async {
    revisionCalls++;
    return revision;
  }

  @override
  Future<ApiResponseModel<ThemePayload?>> getPayload({
    String page = 'home',
    String? knownChecksum,
  }) async {
    if (page == 'header') {
      headerCalls++;
      return headerResponse;
    }
    payloadCalls++;
    lastChecksumSent = knownChecksum;
    return payloadResponse;
  }

  @override
  Future<void> dropCachedPayloads() async {
    droppedCaches++;
  }

  @override
  Future<ThemePayload?> getCachedPayload({String page = 'home'}) async =>
      page == 'header' ? cachedHeader : cached;

  @override
  Future<ApiResponseModel> getSectionData(SectionSource source) async =>
      ApiResponseModel.withError('not_used_in_these_tests');
}

ThemePayload _payload({int revision = 1, String checksum = 'c1'}) =>
    ThemePayload.fromJson({
      'revision': revision,
      'checksum': checksum,
      'schema_version': 1,
      'engine_version': 1,
      'sections': [
        {'uuid': 'u-1', 'id': 1, 'type': 'spacer', 'settings': {'height': 20}},
      ],
    });

void main() {
  group('DynamicThemeController.sync', () {
    test('no published theme -> fallback home, no page download', () async {
      final service = _FakeThemeService()..revision = ThemeRevision.none;
      final controller =
          DynamicThemeController(dynamicThemeServiceInterface: service);

      await controller.sync();

      expect(controller.hasPublishedTheme, isFalse);
      expect(service.revisionCalls, 1);
      expect(service.payloadCalls, 0,
          reason: 'revision 0 must never cost a page download');
    });

    test('a server that SAYS nothing is published purges the cache', () async {
      final service = _FakeThemeService()
        ..cached = _payload()
        // schemaVersion travels with a real server answer; zero everything is offline.
        ..revision = const ThemeRevision(
            revision: 0, checksum: null, schemaVersion: 1, engineVersion: 1);

      final controller =
          DynamicThemeController(dynamicThemeServiceInterface: service);

      await controller.sync();

      expect(controller.hasPublishedTheme, isFalse,
          reason: 'the merchant unpublished; a withdrawn theme must not linger');
      expect(service.droppedCaches, 1,
          reason: 'and the disk copy must go too, or every cold start resurrects it');
    });

    test('cached page renders even when the network fails', () async {
      final service = _FakeThemeService()
        ..cached = _payload()
        ..revision = ThemeRevision.none; // the version check "failed" / offline

      final controller =
          DynamicThemeController(dynamicThemeServiceInterface: service);

      await controller.sync();

      expect(controller.hasPublishedTheme, isTrue,
          reason: 'stale-while-revalidate: the cache is the first render');
      expect(controller.sections.single.type, 'spacer');
    });

    test('a newer revision downloads the page once', () async {
      final service = _FakeThemeService()
        ..revision = const ThemeRevision(
            revision: 2, checksum: 'c2', schemaVersion: 1, engineVersion: 1)
        ..payloadResponse = ApiResponseModel.withSuccess(
            _payload(revision: 2, checksum: 'c2'));

      final controller =
          DynamicThemeController(dynamicThemeServiceInterface: service);

      await controller.sync();

      expect(controller.payload.revision, 2);
      expect(service.payloadCalls, 1);
    });

    test('an unchanged revision downloads nothing', () async {
      final service = _FakeThemeService()
        ..cached = _payload()
        ..revision = const ThemeRevision(
            revision: 1, checksum: 'c1', schemaVersion: 1, engineVersion: 1);

      final controller =
          DynamicThemeController(dynamicThemeServiceInterface: service);

      await controller.sync();

      expect(service.payloadCalls, 0);
      expect(controller.payload.checksum, 'c1');
    });

    test('a failed download keeps the page already held', () async {
      final service = _FakeThemeService()
        ..cached = _payload()
        ..revision = const ThemeRevision(
            revision: 2, checksum: 'c2', schemaVersion: 1, engineVersion: 1)
        ..payloadResponse = ApiResponseModel.withError('boom');

      final controller =
          DynamicThemeController(dynamicThemeServiceInterface: service);

      await controller.sync();

      expect(controller.hasPublishedTheme, isTrue,
          reason: 'a network failure must never blank the home page');
      expect(controller.payload.revision, 1);
      expect(controller.lastError, isNotNull);
    });

    test('a 304 keeps the page already held', () async {
      final service = _FakeThemeService()
        ..cached = _payload()
        ..revision = const ThemeRevision(
            revision: 1, checksum: 'other', schemaVersion: 1, engineVersion: 1)
        ..payloadResponse = ApiResponseModel.withSuccess(null);

      final controller =
          DynamicThemeController(dynamicThemeServiceInterface: service);

      await controller.sync();

      expect(controller.payload.revision, 1);
      expect(service.lastChecksumSent, 'c1',
          reason: 'the held checksum rides as If-None-Match');
    });

    test('an unpublished theme drops the held page', () async {
      final service = _FakeThemeService()
        ..cached = _payload()
        ..revision = const ThemeRevision(
            revision: 2, checksum: 'c2', schemaVersion: 1, engineVersion: 1)
        ..payloadResponse =
            ApiResponseModel.withSuccess(ThemePayload.none);

      final controller =
          DynamicThemeController(dynamicThemeServiceInterface: service);

      await controller.sync();

      expect(controller.hasPublishedTheme, isFalse,
          reason: 'the merchant unpublished on purpose; the built-in home '
              'must come back');
    });

    test('the header page rides the home fetch', () async {
      final service = _FakeThemeService()
        ..revision = const ThemeRevision(
            revision: 2, checksum: 'c2', schemaVersion: 1, engineVersion: 1)
        ..payloadResponse = ApiResponseModel.withSuccess(
            _payload(revision: 2, checksum: 'c2'))
        ..headerResponse = ApiResponseModel.withSuccess(ThemePayload.fromJson({
          'page': 'header',
          'revision': 2,
          'checksum': 'h2',
          'sections': [
            {
              'uuid': 'bar-1',
              'id': 9,
              'type': 'announcement_bar',
              'settings': {'text': 'Sale'},
            },
          ],
        }));

      final controller =
          DynamicThemeController(dynamicThemeServiceInterface: service);

      await controller.sync();

      expect(service.headerCalls, 1);
      expect(controller.headerSections.single.type, 'announcement_bar',
          reason: 'the announcement bar lives on the header page — the app '
              'must fetch it or it never appears');
    });

    test('an unchanged revision fetches neither page', () async {
      final service = _FakeThemeService()
        ..cached = _payload()
        ..revision = const ThemeRevision(
            revision: 1, checksum: 'c1', schemaVersion: 1, engineVersion: 1);

      final controller =
          DynamicThemeController(dynamicThemeServiceInterface: service);

      await controller.sync();

      expect(service.payloadCalls, 0);
      expect(service.headerCalls, 0);
    });

    test('a failed header fetch never costs the home page', () async {
      final service = _FakeThemeService()
        ..revision = const ThemeRevision(
            revision: 2, checksum: 'c2', schemaVersion: 1, engineVersion: 1)
        ..payloadResponse = ApiResponseModel.withSuccess(
            _payload(revision: 2, checksum: 'c2'))
        ..headerResponse = ApiResponseModel.withError('boom');

      final controller =
          DynamicThemeController(dynamicThemeServiceInterface: service);

      await controller.sync();

      expect(controller.hasPublishedTheme, isTrue);
      expect(controller.headerSections, isEmpty);
    });

    test('force refresh skips the version check', () async {
      final service = _FakeThemeService()
        ..payloadResponse = ApiResponseModel.withSuccess(_payload());

      final controller =
          DynamicThemeController(dynamicThemeServiceInterface: service);

      await controller.refresh();

      expect(service.revisionCalls, 0);
      expect(service.payloadCalls, 1);
    });
  });

  group('DynamicThemeController.loadPage', () {
    test('fetches a composed page once and keeps it', () async {
      final service = _FakeThemeService()
        ..payloadResponse = ApiResponseModel.withSuccess(_payload());
      final controller =
          DynamicThemeController(dynamicThemeServiceInterface: service);

      await controller.loadPage('offers');

      expect(controller.page('offers'), isNotNull);
      expect(controller.page('offers')!.sections.single.type, 'spacer');
      expect(service.payloadCalls, 1);

      await controller.loadPage('offers');
      expect(service.payloadCalls, 1,
          reason: 'reopening the screen must not refetch a page already held');
    });

    test('a failed fetch leaves the page absent, so reopening retries', () async {
      final service = _FakeThemeService()
        ..payloadResponse = ApiResponseModel.withError('offline');
      final controller =
          DynamicThemeController(dynamicThemeServiceInterface: service);

      await controller.loadPage('offers');

      expect(controller.page('offers'), isNull,
          reason: 'an empty page would tell the shopper the shop has nothing '
              'here, when the truth is the network dropped');
      expect(controller.isPageLoading('offers'), isFalse);

      service.payloadResponse = ApiResponseModel.withSuccess(_payload());
      await controller.loadPage('offers');

      expect(controller.page('offers'), isNotNull,
          reason: 'a failure must not be remembered as a page');
    });

    test('a republish drops held pages with the rest of the stale state', () async {
      final service = _FakeThemeService()
        ..revision = const ThemeRevision(
            revision: 1, checksum: 'c1', schemaVersion: 1, engineVersion: 1)
        ..payloadResponse = ApiResponseModel.withSuccess(_payload());
      final controller =
          DynamicThemeController(dynamicThemeServiceInterface: service);

      await controller.sync();
      await controller.loadPage('offers');
      expect(controller.page('offers'), isNotNull);

      service
        ..revision = const ThemeRevision(
            revision: 2, checksum: 'c2', schemaVersion: 1, engineVersion: 1)
        ..payloadResponse = ApiResponseModel.withSuccess(
            _payload(revision: 2, checksum: 'c2'));
      await controller.sync();

      expect(controller.page('offers'), isNull,
          reason: 'every page rides the same publish; a held copy of one '
              'would be the only stale thing in an otherwise fresh app');
    });

    test('a page fetched under the old language never sneaks back in', () async {
      final service = _FakeThemeService()
        ..payloadResponse = ApiResponseModel.withSuccess(_payload());
      final controller =
          DynamicThemeController(dynamicThemeServiceInterface: service);

      // The fetch is in flight when the shopper switches language.
      final inFlight = controller.loadPage('offers');
      await controller.onLanguageChanged();
      await inFlight;

      expect(controller.page('offers'), isNull,
          reason: 'the payload it carries is spelled in the language the '
              'shopper just left');
    });

    test('a failed page is marked failed and retryPage clears it', () async {
      final service = _FakeThemeService()
        ..payloadResponse = ApiResponseModel.withError('404');
      final controller =
          DynamicThemeController(dynamicThemeServiceInterface: service);

      await controller.loadPage('offers');

      expect(controller.pageFailed('offers'), isTrue,
          reason: 'a spinner over a dead request spins forever');

      service.payloadResponse = ApiResponseModel.withSuccess(_payload());
      await controller.retryPage('offers');

      expect(controller.pageFailed('offers'), isFalse);
      expect(controller.page('offers'), isNotNull);
    });

    test('a language switch during a running sync is deferred, not dropped', () async {
      final service = _FakeThemeService()
        ..revision = const ThemeRevision(
            revision: 1, checksum: 'c1', schemaVersion: 1, engineVersion: 1)
        ..payloadResponse = ApiResponseModel.withSuccess(_payload());
      final controller =
          DynamicThemeController(dynamicThemeServiceInterface: service);

      final running = controller.sync();
      await controller.onLanguageChanged(); // lands while sync is in flight
      await running;
      // The deferred refresh fires in sync's finally; give it a turn to run.
      await Future<void>.delayed(Duration.zero);

      expect(service.payloadCalls, greaterThan(1),
          reason: 'the switch must refetch once the running sync ends — '
              'silently dropping it keeps the old language on screen');
    });

    test('a language switch drops held pages and refetches by force', () async {
      final service = _FakeThemeService()
        ..payloadResponse = ApiResponseModel.withSuccess(_payload());
      final controller =
          DynamicThemeController(dynamicThemeServiceInterface: service);

      await controller.loadPage('offers');
      expect(controller.page('offers'), isNotNull);

      await controller.onLanguageChanged();

      expect(controller.page('offers'), isNull,
          reason: 'a page fetched under the old lang header reopens in the '
              'old language unless it is dropped');
      expect(service.revisionCalls, 0,
          reason: 'the revision did not change — asking would truthfully say '
              'nothing moved, and nothing would refetch');
      expect(service.payloadCalls, greaterThan(1),
          reason: 'the home page must be refetched by force');
    });
  });
}
