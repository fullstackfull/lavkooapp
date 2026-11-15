import 'package:shared_preferences/shared_preferences.dart';
import 'package:syriapharmacy/features/storefront/domain/models/storefront_country.dart';
import 'package:syriapharmacy/features/storefront/storefront_config.dart';
import 'package:syriapharmacy/utill/app_constants.dart';

/// Reads and saves the storefront a customer picked. While storefronts ship dark, nothing is written and every
/// read answers Saudi Arabia, the storefront the app serves today.
class StorefrontChoice {
  const StorefrontChoice(
    this._preferences, {
    this.enabled = StorefrontConfig.enabled,
  });

  final SharedPreferences _preferences;
  final bool enabled;

  StorefrontCountry current() {
    if (!enabled) {
      return StorefrontCountry.defaultCountry;
    }

    return StorefrontConfig.resolve(_preferences);
  }

  Future<bool> choose(StorefrontCountry storefront) {
    if (!enabled) {
      return Future<bool>.value(false);
    }

    return _preferences.setString(
      AppConstants.storefrontCountry,
      storefront.code,
    );
  }
}
