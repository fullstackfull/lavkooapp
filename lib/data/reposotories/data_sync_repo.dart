import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:syriapharmacy/common/enums/data_source_enum.dart';
import 'package:syriapharmacy/common/enums/local_caches_type_enum.dart';
import 'package:syriapharmacy/data/datasource/remote/dio/dio_client.dart';
import 'package:syriapharmacy/data/datasource/remote/exception/api_error_handler.dart';
import 'package:syriapharmacy/data/local/cache_response.dart';
import 'package:syriapharmacy/data/model/api_response.dart';
import 'package:syriapharmacy/data/reposotories/data_sync_repo_interface.dart';
import 'package:syriapharmacy/features/storefront/storefront_cache_key.dart';
import 'package:syriapharmacy/features/storefront/storefront_scope.dart';
import 'package:syriapharmacy/helper/db_helper.dart';
import 'package:syriapharmacy/main.dart';
import 'package:syriapharmacy/utill/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DataSyncRepo implements DataSyncRepoInterface {
  final DioClient dioClient;
  final SharedPreferences? sharedPreferences;

  /// The database the answers are kept in: the app's one, unless a test hands in another.
  final AppDatabase? localDatabase;

  DataSyncRepo(
      {required this.dioClient,
      required this.sharedPreferences,
      this.localDatabase});

  AppDatabase get _database => localDatabase ?? database;

  @override
  Future<ApiResponseModel<T>> fetchData<T>(
      String uri, DataSourceEnum source) async {
    try {
      return source == DataSourceEnum.client || _isACachesDisable()
          ? await _fetchFromClient<T>(uri)
          : await _fetchFromLocalCache<T>(uri);
    } catch (e) {
      debugPrint('DataSyncRepo: ===> $source $e ($uri)');

      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }

  String _getLangAwareUri(String uri) {
    final lang = sharedPreferences?.getString(AppConstants.languageCode) ?? 'en';
    return '$uri#$lang';
  }

  /// The key a web build files an answer under in the preferences, which have no table to file it for the storefront: the language-aware
  /// key, followed by the storefront while they are on. The database files its rows itself, by the same rule.
  String _webKey(String cacheKey, String? storefront) =>
      StorefrontCacheKey.scoped(cacheKey, storefrontCode: storefront);

  Future<ApiResponseModel<T>> _fetchFromClient<T>(String uri) async {
    final String? storefront = StorefrontScope.current;
    final response = await dioClient.get(uri);
    final cacheKey = _getLangAwareUri(uri);

    // Prepare the cache data
    final cacheData = CacheResponseCompanion(
      endPoint: Value(cacheKey),
      header: Value(jsonEncode(dioClient.dio?.options.headers)),
      response: Value(jsonEncode(response.data)),
      isSuccess: Value(response.statusCode == 200),
    );

    // An answer for a storefront the customer has left on the way is handed back and filed nowhere: kept, it would be read as the answer
    // of the storefront they are on.
    if (StorefrontScope.isCurrent(storefront)) {
      // Cache the data based on the platform
      if (kIsWeb && _isWebCachesActive()) {
        _cacheResponseWeb(_webKey(cacheKey, storefront), cacheData);
      }

      if (!kIsWeb && _isAppCachesActive()) {
        await DbHelper.insertOrUpdate(
            id: cacheKey, data: cacheData, localDatabase: _database);
      }
    }

    return ApiResponseModel.withSuccess(response as T);
  }

  bool _isWebCachesActive() =>
      (AppConstants.cachesType == LocalCachesTypeEnum.all ||
          AppConstants.cachesType == LocalCachesTypeEnum.web);
  bool _isAppCachesActive() =>
      (AppConstants.cachesType == LocalCachesTypeEnum.all ||
          AppConstants.cachesType == LocalCachesTypeEnum.app);
  bool _isACachesDisable() =>
      AppConstants.cachesType == LocalCachesTypeEnum.none;

  void _cacheResponseWeb(String uri, CacheResponseCompanion cacheData) {
    final cacheJson = CacheResponseData(
      id: 0,
      endPoint: cacheData.endPoint.value,
      header: cacheData.header.value,
      response: cacheData.response.value,
      isSuccess: true,
    ).toJson();
    sharedPreferences?.setString(uri, jsonEncode(cacheJson));
  }

  Future<ApiResponseModel<T>> _fetchFromLocalCache<T>(String uri) async {
    CacheResponseData? cacheData;
    final cacheKey = _getLangAwareUri(uri);

    if (kIsWeb) {
      final cachedJson = sharedPreferences
          ?.getString(_webKey(cacheKey, StorefrontScope.current));
      if (cachedJson != null) {
        cacheData = CacheResponseData.fromJson(jsonDecode(cachedJson));
      }
    } else {
      cacheData = await _database.getCacheResponseById(cacheKey);
    }

    if (cacheData != null && cacheData.isSuccess) {
      return ApiResponseModel.withSuccess(cacheData as T);
    } else {
      return ApiResponseModel.withError("No local data found for $cacheKey");
    }
  }

  @override
  Future add(value) {
    // TODO: implement add
    throw UnimplementedError();
  }

  @override
  Future delete(int id) {
    // TODO: implement delete
    throw UnimplementedError();
  }

  @override
  Future get(String id) {
    // TODO: implement get
    throw UnimplementedError();
  }

  @override
  Future getList({int? offset = 1}) {
    // TODO: implement getList
    throw UnimplementedError();
  }

  @override
  Future update(Map<String, dynamic> body, int id) {
    // TODO: implement update
    throw UnimplementedError();
  }
}
