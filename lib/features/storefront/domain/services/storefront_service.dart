import 'package:syriapharmacy/data/model/api_response.dart';
import 'package:syriapharmacy/features/storefront/domain/models/storefront_country.dart';
import 'package:syriapharmacy/features/storefront/domain/repositories/storefront_repository_interface.dart';
import 'package:syriapharmacy/features/storefront/domain/services/storefront_service_interface.dart';
import 'package:syriapharmacy/features/storefront/storefront_config.dart';

class StorefrontService implements StorefrontServiceInterface {
  StorefrontService({
    required this.storefrontRepositoryInterface,
    this.enabled = StorefrontConfig.enabled,
  });

  final StorefrontRepositoryInterface storefrontRepositoryInterface;

  /// While storefronts are off nothing is asked, so a build with them off sends no new request. It defaults to the build flag and is a
  /// parameter so both settings can be tested in one run.
  final bool enabled;

  @override
  Future<bool> refreshStorefronts() async {
    if (!enabled) {
      return false;
    }

    final ApiResponseModel apiResponse =
        await storefrontRepositoryInterface.getStorefronts();
    if (!apiResponse.isSuccess) {
      return false;
    }

    // An answer with no usable entry is not stored: it would wipe what the app last knew and leave every storefront on its default.
    final List<StorefrontCountry> answered =
        StorefrontCountry.parseList(apiResponse.response?.data);
    if (answered.isEmpty) {
      return false;
    }

    return storefrontRepositoryInterface.saveStorefronts(answered);
  }
}
