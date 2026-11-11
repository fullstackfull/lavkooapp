import 'dart:convert';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';
import 'package:syriapharmacy/data/datasource/remote/dio/dio_client.dart';
import 'package:syriapharmacy/data/datasource/remote/exception/api_error_handler.dart';
import 'package:syriapharmacy/data/local/cache_response.dart';
import 'package:syriapharmacy/data/model/api_response.dart';
import 'package:syriapharmacy/features/dynamic_theme/domain/models/theme_schema.dart';
import 'package:syriapharmacy/features/dynamic_theme/domain/repositories/dynamic_theme_repository_interface.dart';
import 'package:syriapharmacy/features/dynamic_theme/engine/capability_registry.dart';
import 'package:syriapharmacy/helper/db_helper.dart';
import 'package:syriapharmacy/main.dart';
import 'package:syriapharmacy/utill/app_constants.dart';

/// Talks to the theme endpoints, and keeps the last good page on disk.
///
/// The cache is the existing Drift response store the config and order screens already use —
/// deliberately, because the app has four persistence mechanisms already and a fifth for one
/// feature would be indefensible. The key is the endpoint, which is the convention that store was
/// built around.
class DynamicThemeRepository implements DynamicThemeRepositoryInterface {
  DynamicThemeRepository({required this.dioClient});

  final DioClient dioClient;

  /// The cache key for a page's payload. Namespaced under the endpoint so it cannot collide with
  /// the raw endpoint entry the generic sync layer might write for the same path.
  String _cacheKey(String page) => '${AppConstants.themeHomeUri}::$page';

  /// Forget every cached theme page on disk. Called when the server reports nothing published:
  /// a withdrawn theme kept on disk would come back on every cold start forever.
  @override
  Future<void> dropCachedPayloads() async {
    try {
      await database.deleteCacheResponsesByPrefix('${AppConstants.themeHomeUri}::');
    } catch (_) {
      // Losing the delete costs one more stale cold start, never the sync.
    }
  }

  /// Which breakpoint this device is served: the server collapses `*_tablet` / `*_mobile`
  /// overrides onto their base keys per the value sent here.
  ///
  /// Uses the physical display rather than a BuildContext, because this runs before any widget
  /// exists (the cold-start prefetch). The 600dp shortest-side threshold is the same rule
  /// ResponsiveHelper applies in the UI, so a section sized for tablets in the builder appears on
  /// exactly the devices the rest of the app already treats as tablets.
  static String deviceClass() {
    try {
      final view = ui.PlatformDispatcher.instance.implicitView;
      if (view == null) return 'mobile';

      final shortestSide = view.physicalSize.shortestSide / view.devicePixelRatio;
      return shortestSide >= 600 ? 'tablet' : 'mobile';
    } catch (_) {
      return 'mobile';
    }
  }

  @override
  Future<ThemeRevision> fetchRevision() async {
    try {
      final response = await dioClient.get(
        AppConstants.themeVersionUri,
        options: Options(headers: ThemeCapabilities.headers),
      );

      final data = response.data;
      if (data is Map) {
        return ThemeRevision.fromJson(Map<String, dynamic>.from(data));
      }
    } catch (error) {
      // Offline, or the endpoint does not exist on this backend yet. Either way the answer is
      // "nothing new to fetch", which leaves whatever is cached on screen.
      if (kDebugMode) debugPrint('[theme] revision check failed: $error');
    }

    return ThemeRevision.none;
  }

  @override
  Future<ApiResponseModel<ThemePayload?>> fetchPayload({
    String page = 'home',
    String? knownChecksum,
  }) async {
    try {
      final headers = <String, String>{
        ...ThemeCapabilities.headers,
        if (knownChecksum != null) 'If-None-Match': '"$knownChecksum"',
      };

      final response = await dioClient.get(
        '${AppConstants.themeHomeUri}?page=$page&device=${deviceClass()}',
        options: Options(
          headers: headers,
          // 304 is the success case this request is built around, and 404 is a real ANSWER
          // (the page was removed or disabled) — neither may be thrown into the generic handler.
          validateStatus: (status) => status != null && (status < 400 || status == 404),
        ),
      );

      if (response.statusCode == 304) {
        return ApiResponseModel.withSuccess(null);
      }

      if (response.statusCode == 404) {
        // Typed, so the controller can retire the page instead of offering an endless retry
        // against something the merchant deliberately took away.
        return ApiResponseModel.withError('page_gone');
      }

      final data = response.data;
      if (data is! Map) {
        return ApiResponseModel.withError('theme_payload_was_not_an_object');
      }

      final raw = Map<String, dynamic>.from(data);
      final payload = ThemePayload.fromJson(raw);

      // Only a page that actually rendered is worth keeping. Caching an empty payload would give
      // the next cold start a blank home page to show instantly, which is worse than no cache —
      // and a page the server just emptied must also stop serving its OLD cached self.
      if (payload.isRenderable) {
        await writeCachedPayload(payload, raw);
      } else {
        await database.deleteCacheResponseByEndpoint(_cacheKey(payload.page));
      }

      return ApiResponseModel.withSuccess(payload);
    } catch (error) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(error));
    }
  }

  @override
  Future<ApiResponseModel> fetchSectionData(String path) async {
    try {
      return ApiResponseModel.withSuccess(await dioClient.get(withGuestCredential(path)));
    } catch (error) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(error));
    }
  }

  /// The catalogue routes answer 401 to a caller that is neither a customer nor a named guest.
  /// New payloads carry guest_id in the hint itself; a payload cached before that fix does not,
  /// and this keeps those rails alive until the next sync replaces it. guest_id=1 is the same
  /// guest convention every stock catalogue URI in [AppConstants] hard-codes.
  @visibleForTesting
  static String withGuestCredential(String path) {
    if (path.contains('guest_id=')) return path;
    return path.contains('?') ? '$path&guest_id=1' : '$path?guest_id=1';
  }

  @override
  Future<ThemePayload?> readCachedPayload({String page = 'home'}) async {
    try {
      final cached = await database.getCacheResponseById(_cacheKey(page));
      if (cached == null) return null;

      final decoded = jsonDecode(cached.response);
      if (decoded is! Map) return null;

      final payload = ThemePayload.fromJson(Map<String, dynamic>.from(decoded));
      return payload.isRenderable ? payload : null;
    } catch (error) {
      // A cache written by an older build of this app, or a truncated write. Treat it as absent;
      // it will be replaced by the next successful fetch.
      if (kDebugMode) debugPrint('[theme] cached payload unreadable: $error');
      return null;
    }
  }

  @override
  Future<void> writeCachedPayload(
    ThemePayload payload,
    Map<String, dynamic> raw,
  ) async {
    try {
      await DbHelper.insertOrUpdate(
        id: _cacheKey(payload.page),
        data: CacheResponseCompanion(
          endPoint: Value(_cacheKey(payload.page)),
          header: Value(jsonEncode({'revision': payload.revision})),
          response: Value(jsonEncode(raw)),
          isSuccess: const Value(true),
        ),
      );
    } catch (error) {
      // A cache that cannot be written costs the next cold start its instant render, and nothing
      // else. It is never worth failing the fetch that produced it.
      if (kDebugMode) debugPrint('[theme] cache write failed: $error');
    }
  }
}
