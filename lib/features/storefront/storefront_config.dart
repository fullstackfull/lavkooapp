import 'package:shared_preferences/shared_preferences.dart';
import 'package:syriapharmacy/features/storefront/domain/models/storefront_country.dart';
import 'package:syriapharmacy/features/storefront/stored_storefronts.dart';
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
      return _fallbackFor(sharedPreferences);
    }

    final String normalizedCode = storedCode.trim().toUpperCase();
    return StorefrontCountry.all.firstWhere(
      (storefront) => storefront.code == normalizedCode,
      orElse: () => _fallbackFor(sharedPreferences),
    );
  }

  /// The storefront a customer is on while they have chosen none this app can honour: the one the server's last answer named its
  /// `default_country`, so that moving the default moves them with it, and Saudi Arabia while the server has named none.
  static StorefrontCountry _fallbackFor(SharedPreferences sharedPreferences) =>
      StorefrontCountry.fallbackAmong(
          StoredStorefronts(sharedPreferences).read());
}
