import 'package:shared_preferences/shared_preferences.dart';
import 'package:syriapharmacy/features/storefront/domain/models/storefront_country.dart';
import 'package:syriapharmacy/utill/app_constants.dart';

/// GCC storefronts ship dark: nothing reads the stored choice or sends `X-Storefront` unless the
/// build is made with `--dart-define=GCC_STOREFRONTS_ENABLED=true`.
class StorefrontConfig {
  static const bool enabled =
      bool.fromEnvironment('GCC_STOREFRONTS_ENABLED', defaultValue: false);

  static StorefrontCountry resolve(SharedPreferences sharedPreferences) {
    final Object? storedCode =
        sharedPreferences.get(AppConstants.storefrontCountry);
    if (storedCode is! String) {
      return StorefrontCountry.defaultCountry;
    }

    final String normalizedCode = storedCode.trim().toUpperCase();
    return StorefrontCountry.all.firstWhere(
      (storefront) => storefront.code == normalizedCode,
      orElse: () => StorefrontCountry.defaultCountry,
    );
  }
}
