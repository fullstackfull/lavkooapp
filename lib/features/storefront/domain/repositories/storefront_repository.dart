import 'package:shared_preferences/shared_preferences.dart';
import 'package:syriapharmacy/data/datasource/remote/dio/dio_client.dart';
import 'package:syriapharmacy/data/model/api_response.dart';
import 'package:syriapharmacy/features/storefront/domain/models/storefront_country.dart';
import 'package:syriapharmacy/features/storefront/domain/repositories/storefront_repository_interface.dart';
import 'package:syriapharmacy/features/storefront/stored_storefronts.dart';
import 'package:syriapharmacy/utill/app_constants.dart';

class StorefrontRepository implements StorefrontRepositoryInterface {
  StorefrontRepository({
    required this.dioClient,
    required this.sharedPreferences,
  });

  final DioClient dioClient;
  final SharedPreferences sharedPreferences;

  /// A list that cannot be fetched is an error the caller ignores: the last stored answer stays in force. The message is therefore
  /// never shown, and `ApiErrorHandler` is not used on purpose, because its 401 branch signs the customer out and a background refresh
  /// of a public list must never do that.
  @override
  Future<ApiResponseModel> getStorefronts() async {
    try {
      final response = await dioClient.get(AppConstants.storefrontsUri);
      return ApiResponseModel.withSuccess(response);
    } catch (error) {
      return ApiResponseModel.withError(error.toString());
    }
  }

  @override
  List<StorefrontCountry> readStoredStorefronts() {
    return StoredStorefronts(sharedPreferences).read();
  }

  @override
  Future<bool> saveStorefronts(List<StorefrontCountry> storefronts) {
    return StoredStorefronts(sharedPreferences).save(storefronts);
  }
}
