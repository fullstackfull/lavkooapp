import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:syriapharmacy/common/enums/data_source_enum.dart';
import 'package:syriapharmacy/data/local/cache_response.dart';
import 'package:syriapharmacy/data/model/api_response.dart';
import 'package:syriapharmacy/features/storefront/storefront_scope.dart';
import 'package:syriapharmacy/helper/api_checker.dart';

class DataSyncHelper {
  /// Generic method to fetch data from local and remote sources
  ///
  /// The answers are for the storefront the customer is on when this is called. If they choose another while an answer is on its way,
  /// the answer is dropped: [onResponse] is never called with the storefront they left, and nothing more is asked for it.
  static Future<void> fetchAndSyncData({
    required Future<ApiResponseModel<CacheResponseData>> Function()
        fetchFromLocal,
    required Future<ApiResponseModel<Response>> Function() fetchFromClient,
    required Function(dynamic, DataSourceEnum source) onResponse,
  }) async {
    final String? storefront = StorefrontScope.current;

    // Step 1: Try to load from the local source
    final localResponse = await fetchFromLocal();
    if (!StorefrontScope.isCurrent(storefront)) return;

    if (localResponse.isSuccess) {
      onResponse(
          jsonDecode(localResponse.response!.response), DataSourceEnum.local);
    }

    // Step 2: Try to load from the client (remote) source and update if successful
    final clientResponse = await fetchFromClient();
    if (!StorefrontScope.isCurrent(storefront)) return;

    if (clientResponse.isSuccess) {
      onResponse(clientResponse.response?.data, DataSourceEnum.client);
    } else {
      ApiChecker.checkApi(clientResponse);
    }
  }
}
