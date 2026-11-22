import 'package:syriapharmacy/data/model/api_response.dart';
import 'package:syriapharmacy/features/storefront/domain/models/storefront_country.dart';

abstract class StorefrontRepositoryInterface {
  /// `GET /api/v1/storefronts`: the storefronts the shop serves and whether each may sell yet.
  Future<ApiResponseModel> getStorefronts();

  /// The last list that was saved, or an empty list when none was.
  List<StorefrontCountry> readStoredStorefronts();

  /// Keeps [storefronts] as the last answer. False when the device refused the write.
  Future<bool> saveStorefronts(List<StorefrontCountry> storefronts);
}
