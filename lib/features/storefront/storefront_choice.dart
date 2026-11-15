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

  /// While storefronts are off every storefront is the Saudi one, which may sell as before. While they are on, a storefront may
  /// sell only when it is marked sellable. A browse-only storefront can still be chosen and browsed.
  bool canSell(StorefrontCountry storefront) => !enabled || storefront.sellable;

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
