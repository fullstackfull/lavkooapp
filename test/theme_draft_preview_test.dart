import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syriapharmacy/data/datasource/remote/dio/dio_client.dart';
import 'package:syriapharmacy/data/datasource/remote/dio/logging_interceptor.dart';
import 'package:syriapharmacy/data/local/cache_response.dart';
import 'package:syriapharmacy/data/model/api_response.dart';
import 'package:syriapharmacy/features/dynamic_theme/controllers/dynamic_theme_controller.dart';
import 'package:syriapharmacy/features/dynamic_theme/domain/models/theme_schema.dart';
import 'package:syriapharmacy/features/dynamic_theme/domain/repositories/dynamic_theme_repository.dart';
import 'package:syriapharmacy/features/dynamic_theme/domain/services/dynamic_theme_service_interface.dart';
import 'package:syriapharmacy/features/dynamic_theme/theme_preview.dart';
import 'package:syriapharmacy/features/storefront/storefront_scope.dart';
import 'package:syriapharmacy/utill/app_constants.dart';

/// J-V1: a merchant checks an unpublished draft of the home page on a real phone.
///
/// The backend half shipped a while ago and nothing in this app could talk to it: `ThemePreviewToken`
/// signs one version for one hour, `GET /api/v1/theme/home?preview=<token>` answers that version
/// marked `preview: true` with no ETag and `Cache-Control: no-store`, and the app sent no `preview`
/// and read no `preview`. Two things had to be true at once — the app asks for the draft, and the
/// app never KEEPS it, because a draft written to the disk cache opens as the home page of the
/// next cold start, for a shopper, after the merchant decided against it.
///
/// Nothing here reads the storefronts flag, so the file runs once per build and says the same
/// thing. What IS a compile-time constant is whether this build accepts a preview token at all
/// (`--dart-define=GCC_THEME_PREVIEW_ENABLED=true`); the one group that asserts it names which
/// build it is talking about and skips in the other, and every other group drives the switch
/// through the `enabled` parameter so both answers are exercised by one build.
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

/// A page the app can render, as the server sends one. [draft] adds the `preview` mark the preview
/// path puts on its answer and nothing else does.
Map<String, Object?> _page({
  String checksum = 'published-checksum',
  bool draft = false,
}) =>
    <String, Object?>{
      'page': 'home',
      'revision': 1,
      'checksum': checksum,
      'schema_version': 1,
      'engine_version': 1,
      if (draft) 'preview': true,
      'sections': <Object>[
        <String, Object?>{
          'uuid': 'u-1',
          'id': 1,
          'type': 'spacer',
          'settings': <String, Object?>{'height': 20},
        },
      ],
    };

class _FakeThemeService implements DynamicThemeServiceInterface {
  ThemeRevision revision = const ThemeRevision(
      revision: 1, checksum: 'published-checksum', schemaVersion: 1, engineVersion: 1);
  ApiResponseModel<ThemePayload?> payloadResponse =
      ApiResponseModel.withSuccess(null);
  ThemePayload? cached;

  int revisionCalls = 0;
  int payloadCalls = 0;
  int cacheReads = 0;

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
      return ApiResponseModel.withSuccess(null);
    }
    payloadCalls++;
    return payloadResponse;
  }

  @override
  Future<void> dropCachedPayloads() async {}

  @override
  Future<ThemePayload?> getCachedPayload({String page = 'home'}) async {
    if (page == 'header') {
      return null;
    }
    cacheReads++;
    return cached;
  }

  @override
  Future<ApiResponseModel> getSectionData(SectionSource source) async =>
      ApiResponseModel.withError('not_used_in_these_tests');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(ThemePreview.stop);

  group('the token a link carries', () {
    test('is the key the builder already mints its link with', () {
      expect(
          ThemePreview.tokenIn(Uri.parse('https://shop.test/?theme_preview=t-1')),
          't-1');
      expect(ThemePreview.linkKey, 'theme_preview');
      expect(ThemePreview.requestKey, 'preview');
    });

    test('and a link with none, or an empty one, carries none', () {
      expect(ThemePreview.tokenIn(Uri.parse('https://shop.test/')), isNull);
      expect(
          ThemePreview.tokenIn(Uri.parse('https://shop.test/?theme_preview=')),
          isNull);
      expect(
          ThemePreview.tokenIn(
              Uri.parse('https://shop.test/?theme_preview=%20%20')),
          isNull);
      expect(ThemePreview.tokenIn(Uri.parse('https://shop.test/product/x')),
          isNull);
    });
  });

  group('a build that accepts no preview token (the default build)', () {
    test('holds nothing, whatever link it is handed', () {
      expect(ThemePreview.enabledInThisBuild, isFalse);
      expect(ThemePreview.show('t-1'), isFalse);
      expect(ThemePreview.token, isNull);
      expect(ThemePreview.isAskingForADraft, isFalse);
    }, skip: ThemePreview.enabledInThisBuild);
  });

  group('a build that does accept one', () {
    test('holds the token until it is told to stop', () {
      expect(ThemePreview.show('t-1', enabled: true), isTrue);
      expect(ThemePreview.token, 't-1');
      expect(ThemePreview.isAskingForADraft, isTrue);

      ThemePreview.stop();

      expect(ThemePreview.token, isNull);
      expect(ThemePreview.isAskingForADraft, isFalse);
    });

    test('and holds nothing when there is no token to hold', () {
      expect(ThemePreview.show(null, enabled: true), isFalse);
      expect(ThemePreview.show('   ', enabled: true), isFalse);
      expect(ThemePreview.token, isNull);
    });
  });

  group('the page the server answers', () {
    test('is a draft only when the server marked it one', () {
      expect(ThemePayload.fromJson(_page(draft: true)).isDraft, isTrue);
      expect(ThemePayload.fromJson(_page()).isDraft, isFalse);
      expect(ThemePayload.none.isDraft, isFalse);
    });

    test('and a mark that is not the server\'s own boolean is not a draft', () {
      for (final Object? sent in <Object?>[null, false, 'true', 1, <Object>[]]) {
        expect(
            ThemePayload.fromJson(<String, Object?>{..._page(), 'preview': sent})
                .isDraft,
            isFalse,
            reason: 'preview sent as $sent');
      }
    });
  });

  group('the request the app makes', () {
    late AppDatabase database;
    late _ScriptedAdapter adapter;
    late DynamicThemeRepository repository;

    setUp(() async {
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      database = AppDatabase.forTesting(NativeDatabase.memory());
      SharedPreferences.setMockInitialValues(<String, Object>{
        AppConstants.userLoginToken: 'token',
        AppConstants.languageCode: 'en',
      });
      adapter =
          _ScriptedAdapter((RequestOptions options) async => _json(_page()));
      repository = DynamicThemeRepository(
        dioClient: DioClient(
          'https://shop.test',
          Dio()..httpClientAdapter = adapter,
          loggingInterceptor: LoggingInterceptor(),
          sharedPreferences: await SharedPreferences.getInstance(),
        ),
        localDatabase: database,
      );
      StorefrontScope.publish(null);
    });

    tearDown(() async {
      await database.close();
    });

    test('carries no preview and the checksum it holds while no draft was asked for',
        () async {
      await repository.fetchPayload(page: 'home', knownChecksum: 'c-1');

      expect(adapter.requests.single.path, isNot(contains('preview=')));
      expect(adapter.requests.single.headers['If-None-Match'], '"c-1"');
    });

    test('carries the token, and no checksum, once a draft was asked for',
        () async {
      ThemePreview.show('t-1 /&=', enabled: true);
      adapter.answer =
          (RequestOptions options) async => _json(_page(draft: true));

      await repository.fetchPayload(page: 'home', knownChecksum: 'c-1');

      // Encoded, so a token can never smuggle a second query parameter into the request.
      expect(adapter.requests.single.path,
          contains('&preview=${Uri.encodeQueryComponent('t-1 /&=')}'));
      expect(adapter.requests.single.path, contains('page=home'));
      expect(adapter.requests.single.headers.containsKey('If-None-Match'),
          isFalse,
          reason:
              'a draft is answered with no ETag and never with a 304, and the checksum held is the published page\'s');
    });

    test('and the draft it is answered is read as a draft', () async {
      ThemePreview.show('t-1', enabled: true);
      adapter.answer =
          (RequestOptions options) async => _json(_page(draft: true));

      final ApiResponseModel<ThemePayload?> answer =
          await repository.fetchPayload(page: 'home');

      expect(answer.isSuccess, isTrue);
      expect(answer.response?.isDraft, isTrue);
      expect(answer.response?.isRenderable, isTrue);
    });
  });

  group('a draft is never kept on disk', () {
    late AppDatabase database;
    late _ScriptedAdapter adapter;
    late DynamicThemeRepository repository;

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
        AppConstants.languageCode: 'en',
      });
      adapter =
          _ScriptedAdapter((RequestOptions options) async => _json(_page()));
      repository = DynamicThemeRepository(
        dioClient: DioClient(
          'https://shop.test',
          Dio()..httpClientAdapter = adapter,
          loggingInterceptor: LoggingInterceptor(),
          sharedPreferences: await SharedPreferences.getInstance(),
        ),
        localDatabase: database,
      );
      StorefrontScope.publish(null);
    });

    tearDown(() async {
      await database.close();
    });

    test('the published page still is', () async {
      await repository.fetchPayload(page: 'home');

      expect(await storedKeys(), <String>['/api/v1/theme/home::home']);
      expect((await repository.readCachedPayload(page: 'home'))?.checksum,
          'published-checksum');
    });

    test('a draft is not written, and does not evict the page a shopper would see',
        () async {
      await repository.fetchPayload(page: 'home');

      ThemePreview.show('t-1', enabled: true);
      adapter.answer = (RequestOptions options) async =>
          _json(_page(checksum: 'draft-checksum', draft: true));

      await repository.fetchPayload(page: 'home');

      expect(await storedKeys(), <String>['/api/v1/theme/home::home']);
      expect((await repository.readCachedPayload(page: 'home'))?.checksum,
          'published-checksum',
          reason:
              'the draft must neither be kept nor take the published page away from the next cold start');
    });

    test('and a draft that arrives without being asked for is not kept either',
        () async {
      adapter.answer = (RequestOptions options) async =>
          _json(_page(checksum: 'draft-checksum', draft: true));

      await repository.fetchPayload(page: 'home');

      expect(await storedKeys(), isEmpty,
          reason:
              'the ANSWER\'s own mark decides whether a page may be kept, not what the request asked for');
    });
  });

  group('the controller', () {
    test('is not shown a draft, and asks for none, in a build that accepts no token',
        () async {
      final _FakeThemeService service = _FakeThemeService()
        ..payloadResponse =
            ApiResponseModel.withSuccess(ThemePayload.fromJson(_page()));
      final DynamicThemeController controller =
          DynamicThemeController(dynamicThemeServiceInterface: service);

      expect(await controller.showDraft('t-1', enabled: false), isFalse);
      expect(ThemePreview.isAskingForADraft, isFalse);
      expect(service.payloadCalls, 0,
          reason: 'a refused token must not cost a request');
      expect(controller.isShowingADraft, isFalse);
    });

    test('drops the published page and fetches the draft by force', () async {
      final _FakeThemeService service = _FakeThemeService()
        ..cached = ThemePayload.fromJson(_page())
        ..payloadResponse = ApiResponseModel.withSuccess(
            ThemePayload.fromJson(_page(checksum: 'draft-checksum', draft: true)));
      final DynamicThemeController controller =
          DynamicThemeController(dynamicThemeServiceInterface: service);

      expect(await controller.showDraft('t-1', enabled: true), isTrue);

      expect(controller.isShowingADraft, isTrue);
      expect(controller.payload.checksum, 'draft-checksum');
      expect(service.payloadCalls, 1);
      expect(service.revisionCalls, 0,
          reason:
              'the version endpoint answers the PUBLISHED revision, so a check would say nothing moved and the draft would never be fetched');
      expect(service.cacheReads, 0,
          reason:
              'the cache only ever holds published pages, so seeding from it would put the shop under a notice saying it was a draft');
    });

    test('says it is showing a draft only when the server answered one', () async {
      final _FakeThemeService service = _FakeThemeService()
        ..payloadResponse =
            ApiResponseModel.withSuccess(ThemePayload.fromJson(_page()));
      final DynamicThemeController controller =
          DynamicThemeController(dynamicThemeServiceInterface: service);

      expect(await controller.showDraft('refused-by-the-server', enabled: true),
          isTrue);

      expect(controller.payload.isRenderable, isTrue);
      expect(controller.isShowingADraft, isFalse,
          reason:
              'a token the server refused is answered with the published page, and a notice over the real shop would be a lie');
    });

    test('and putting the shop back stops asking for the draft and refetches',
        () async {
      final _FakeThemeService service = _FakeThemeService()
        ..payloadResponse = ApiResponseModel.withSuccess(
            ThemePayload.fromJson(_page(checksum: 'draft-checksum', draft: true)));
      final DynamicThemeController controller =
          DynamicThemeController(dynamicThemeServiceInterface: service);

      await controller.showDraft('t-1', enabled: true);
      expect(controller.isShowingADraft, isTrue);

      service.payloadResponse =
          ApiResponseModel.withSuccess(ThemePayload.fromJson(_page()));
      await controller.stopShowingADraft();

      expect(ThemePreview.isAskingForADraft, isFalse);
      expect(controller.isShowingADraft, isFalse);
      expect(controller.payload.checksum, 'published-checksum');
      expect(service.payloadCalls, 2);
    });

    test('and is left alone when it was showing no draft', () async {
      final _FakeThemeService service = _FakeThemeService();
      final DynamicThemeController controller =
          DynamicThemeController(dynamicThemeServiceInterface: service);

      await controller.stopShowingADraft();

      expect(service.payloadCalls, 0);
      expect(service.revisionCalls, 0);
    });
  });
}
