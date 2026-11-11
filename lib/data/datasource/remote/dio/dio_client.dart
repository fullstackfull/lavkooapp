import 'dart:io';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:syriapharmacy/data/datasource/remote/dio/logging_interceptor.dart';
import 'package:syriapharmacy/utill/app_constants.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as path;
import 'dart:convert';

class DioClient {
  final String baseUrl;
  final LoggingInterceptor loggingInterceptor;
  final SharedPreferences sharedPreferences;

  Dio? dio;
  String? token;
  String? countryCode;

  DioClient(
    this.baseUrl,
    Dio? dioC, {
    required this.loggingInterceptor,
    required this.sharedPreferences,
  }) {
    token = sharedPreferences.getString(AppConstants.userLoginToken);
    countryCode = sharedPreferences.getString(AppConstants.countryCode) ??
        AppConstants.languages[0].countryCode;

    // A stable per-installation id. Without it a signed-out shopper's analytics identity fell
    // back to a network hash that rotates daily — the same person counted as a new visitor every
    // morning, and experiment bucketing wobbled with them. Minted once, kept for the install's
    // life, carries nothing about the person.
    _clientId = sharedPreferences.getString(AppConstants.analyticsClientId) ?? _mintClientId();
    if (kDebugMode) {
      print("NNNN $token");
    }
    dio = dioC ?? Dio();
    dio
      ?..options.baseUrl = baseUrl
      ..options.connectTimeout = const Duration(seconds: 60)
      ..options.receiveTimeout = const Duration(seconds: 60)
      ..httpClientAdapter
      ..options.headers = _headers();
    dio!.interceptors.add(loggingInterceptor);
  }

  void updateHeader(String? token, String? countryCode) {
    this.token = token ?? this.token;
    this.countryCode = countryCode ?? this.countryCode;
    dio!.options.headers = _headers();
  }

  /// Every request's headers, built in one place.
  ///
  /// Built once rather than written twice because the second copy — the one [updateHeader] wrote
  /// after a login — was missing `Accept`, so the app's headers quietly changed the moment a
  /// customer signed in.
  ///
  /// `X-Platform` and `X-App-Version` are what the shop's Monitoring panels, the Analytics
  /// visitor context and the Developer Portal's deprecation checks all read to tell one release
  /// from another. Without them every request from the app is an anonymous client: the version
  /// table is empty, and "the crashes are all on 2.0.1" is a question nothing can answer.
  Map<String, String> _headers() => {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'X-Platform': Platform.isIOS ? 'ios' : 'android',
        'X-App-Version': AppConstants.appVersion,
        'X-Client-Id': _clientId,
        AppConstants.langKey: _language,
      };

  late final String _clientId;

  String _mintClientId() {
    final random = Random.secure();
    final id = List.generate(32, (_) => random.nextInt(16).toRadixString(16)).join();
    sharedPreferences.setString(AppConstants.analyticsClientId, id);
    return id;
  }

  /// The `lang` header carries the LANGUAGE code — the backend sets its locale from it, and
  /// everything localized keys on `ar`/`en`: DB catalog translations, translate() strings, and
  /// the theme's per-field `_ar` overrides. This used to send the country code (`sa`), which
  /// matched none of them. Read from prefs on every request so a language switch applies
  /// immediately rather than after a restart.
  String get _language =>
      sharedPreferences.getString(AppConstants.languageCode) ??
      AppConstants.languages[0].languageCode ??
      'en';

  // In-memory cache for ultra-fast response of duplicate requests in the same session
  static final Map<String, Response> _memoryCache = {};

  // In-flight deduplication: if two callers ask for the same URL before the first
  // response arrives, the second one waits for the same Future instead of opening
  // a second HTTP connection.
  static final Map<String, Future<Response>> _inFlight = {};

  // Dynamic cache duration in milliseconds (default 5 min = 300000, updated from /api/v1/cash)
  static int _cacheDurationMs = 300000;
  static bool _cacheDurationFetched = false;

  /// Fetch cache duration from backend once per app session.
  Future<void> _ensureCacheDuration() async {
    if (_cacheDurationFetched) return;
    _cacheDurationFetched = true;
    try {
      final response = await dio!.get('/api/v1/cash');
      if (response.statusCode == 200 && response.data != null) {
        final value = int.tryParse(response.data.toString());
        if (value != null && value > 0) {
          _cacheDurationMs = value;
          if (kDebugMode) print("[CACHE] Duration set to ${_cacheDurationMs}ms from server");
        }
      }
    } catch (_) {
      // Keep default on failure
    }
  }

  final List<String> _cacheableEndpoints = [
    '/api/v1/categories',
    '/api/v1/brands',
    '/api/v1/banners',
    '/api/v1/business-pages',
    '/api/v1/theme/version',
    '/api/v1/seller/list/all',
    '/api/v1/products/featured',
    '/api/v1/products/best-sellings',
    '/api/v1/products/latest',
    '/api/v1/deals/featured',
    '/api/v1/flash-deals',
    '/api/v1/dealsoftheday/deal-of-the-day',
    '/api/v1/products/clearance-sale',
    '/api/v1/products/home-categories',
    '/api/v1/products/discounted-product'
  ];

  bool _shouldCache(String uri) {
    for (var endpoint in _cacheableEndpoints) {
      if (uri.contains(endpoint)) return true;
    }
    return false;
  }

  String _normalizeCacheKey(String uri, Map<String, dynamic>? queryParameters) {
    try {
      final parsedUri = Uri.parse(uri);
      final queryMap = <String, String>{};

      parsedUri.queryParameters.forEach((key, value) {
        if (value.isNotEmpty) queryMap[key] = value;
      });

      if (queryParameters != null) {
        queryParameters.forEach((key, value) {
          if (value != null) queryMap[key] = value.toString();
        });
      }

      final sortedKeys = queryMap.keys.toList()..sort();
      final sortedParams = sortedKeys.map((k) => '$k=${queryMap[k]}').join('&');

      final baseKey = sortedParams.isEmpty ? parsedUri.path : '${parsedUri.path}?$sortedParams';
      return '$baseKey#$_language';
    } catch (_) {
      return '${uri + (queryParameters?.toString() ?? '')}#$_language';
    }
  }

  Future<Response> get(
    String uri, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    final bool canCache = _shouldCache(uri);
    final String cacheKey = _normalizeCacheKey(uri, queryParameters);

    if (canCache) {
      // Fetch dynamic cache duration once
      await _ensureCacheDuration();

      // 1. Memory cache (instant)
      if (_memoryCache.containsKey(cacheKey)) {
        if (kDebugMode) print("[CACHE HIT - MEMORY] Returning cached response for: $cacheKey");
        return _memoryCache[cacheKey]!;
      }

      // 2. Disk cache (SharedPreferences)
      final String diskCacheKey = 'api_cache_$cacheKey';
      final String? cachedData = sharedPreferences.getString(diskCacheKey);
      final int? cacheTime = sharedPreferences.getInt('${diskCacheKey}_time');

      if (cachedData != null && cacheTime != null) {
        final currentTime = DateTime.now().millisecondsSinceEpoch;
        final difference = currentTime - cacheTime;
        if (difference < _cacheDurationMs) {
          if (kDebugMode) print("[CACHE HIT - DISK] Returning cached response for: $cacheKey");
          final response = Response(
            requestOptions: RequestOptions(path: uri),
            data: jsonDecode(cachedData),
            statusCode: 200,
          );
          _memoryCache[cacheKey] = response;
          return response;
        } else {
          sharedPreferences.remove(diskCacheKey);
          sharedPreferences.remove('${diskCacheKey}_time');
        }
      }

      // 3. In-flight deduplication: if someone else is already fetching this, wait for them
      if (_inFlight.containsKey(cacheKey)) {
        if (kDebugMode) print("[CACHE DEDUP] Waiting for in-flight request: $cacheKey");
        return _inFlight[cacheKey]!;
      }
    }

    Future<Response> doFetch() async {
      var response = await dio!.get(
        uri,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
      );

      if (canCache && response.statusCode == 200) {
        _memoryCache[cacheKey] = response;
        sharedPreferences.setString('api_cache_$cacheKey', jsonEncode(response.data));
        sharedPreferences.setInt('api_cache_${cacheKey}_time', DateTime.now().millisecondsSinceEpoch);
      }

      return response;
    }

    try {
      if (canCache) {
        final future = doFetch();
        _inFlight[cacheKey] = future;
        try {
          return await future;
        } finally {
          _inFlight.remove(cacheKey);
        }
      }
      return await doFetch();
    } on SocketException catch (e) {
      throw SocketException(e.toString());
    } on FormatException catch (_) {
      throw const FormatException("Unable to process the data");
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> getDownload(
    String uri, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
    String? filePath,
  }) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = path.join(directory.path, 'order.pdf');
    try {
      var response = await dio!.download(uri, filePath);
      return response;
    } on SocketException catch (e) {
      throw SocketException(e.toString());
    } on FormatException catch (_) {
      throw const FormatException("Unable to process the data");
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> post(
    String uri, {
    data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      var response = await dio!.post(
        uri,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
      return response;
    } on FormatException catch (_) {
      throw const FormatException("Unable to process the data");
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> put(
    String uri, {
    data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      var response = await dio!.put(
        uri,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
      return response;
    } on FormatException catch (_) {
      throw const FormatException("Unable to process the data");
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> delete(
    String uri, {
    data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      var response = await dio!.delete(
        uri,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response;
    } on FormatException catch (_) {
      throw const FormatException("Unable to process the data");
    } catch (e) {
      rethrow;
    }
  }

  static void clearMemoryCache() {
    _memoryCache.clear();
    if (kDebugMode) print("[CACHE] Memory cache cleared for refresh");
  }

  void clearDiskCache() {
    final keys = sharedPreferences.getKeys();
    for (String key in keys) {
      if (key.startsWith('api_cache_')) {
        sharedPreferences.remove(key);
      }
    }
    if (kDebugMode) print("[CACHE] Disk cache cleared for language switch");
  }
}
