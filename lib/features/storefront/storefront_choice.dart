import 'package:shared_preferences/shared_preferences.dart';
import 'package:syriapharmacy/features/storefront/domain/models/storefront_country.dart';
import 'package:syriapharmacy/features/storefront/storefront_config.dart';
import 'package:syriapharmacy/features/storefront/stored_storefronts.dart';
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

  /// The storefronts the server last said the shop serves, in the order it gave them. Empty while storefronts are off, and before the
  /// server has answered once: there is then nothing to choose from.
  List<StorefrontCountry> available() {
    if (!enabled) {
      return const <StorefrontCountry>[];
    }

    return StoredStorefronts(_preferences).read();
  }

  /// While storefronts are off every storefront is the Saudi one, which may sell as before. While they are on, the server's last stored
  /// answer decides: a storefront it marks sellable may sell and every other one it lists is browse-only. A storefront the answer does not
  /// list, or no answer yet, keeps the storefront's own default, so only Saudi Arabia may sell. A browse-only storefront can still be
  /// chosen and browsed.
  bool canSell(StorefrontCountry storefront) {
    if (!enabled) {
      return true;
    }

    final StorefrontCountry? answered =
        StoredStorefronts(_preferences).find(storefront.code);

    return answered?.sellable ?? storefront.sellable;
  }

  /// What the server's last answer says about [storefront]: its entry, with how it is stopped, the message for its customers and the end of the stop. Null while
  /// storefronts are off, before the server has answered once, and when the answer does not list it.
  StorefrontCountry? listedEntryOf(StorefrontCountry storefront) {
    if (!enabled) {
      return null;
    }

    return StoredStorefronts(_preferences).find(storefront.code);
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
