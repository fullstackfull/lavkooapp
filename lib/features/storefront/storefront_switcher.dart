import 'dart:async';

import 'package:syriapharmacy/features/storefront/controllers/storefront_controller.dart';
import 'package:syriapharmacy/features/storefront/domain/models/storefront_country.dart';
import 'package:syriapharmacy/features/storefront/storefront_change_notifier.dart';

enum StorefrontSwitch {
  /// The customer is on the storefront they chose, and everything that held the previous one has been told.
  switched,

  /// They chose the storefront they were already on, so nothing was done.
  unchanged,

  /// The choice could not be saved, so nothing was done.
  failed,
}

/// What choosing a storefront does, in the order it has to be done: the choice is saved and the server asked about the new storefront,
/// then the request headers are rebuilt so every request asks for it, then everything that held the old storefront's data is told.
/// The chooser then takes the customer to the home screen, which is its own business.
class StorefrontSwitcher {
  StorefrontSwitcher({
    required this.storefrontController,
    required this.applyHeaders,
    required this.changeNotifier,
  });

  final StorefrontController storefrontController;

  /// Rebuilds the HTTP client's headers, which is what puts the chosen storefront into `X-Storefront`.
  final void Function() applyHeaders;

  final StorefrontChangeNotifier changeNotifier;

  /// The reloads run on in the background: what the customer sees meanwhile is what the controllers dropped to, never the storefront
  /// they left.
  Future<StorefrontSwitch> switchTo(StorefrontCountry storefront) async {
    final StorefrontCountry previous = storefrontController.current;
    if (previous.code == storefront.code) {
      return StorefrontSwitch.unchanged;
    }

    if (!await storefrontController.choose(storefront)) {
      return StorefrontSwitch.failed;
    }

    applyHeaders();
    unawaited(changeNotifier.storefrontChanged(
        previous: previous, current: storefront));

    return StorefrontSwitch.switched;
  }

  /// Asks the server which storefronts it lists, then keeps the customer on one of them. The server answers a country it does not list
  /// as the default storefront, so a customer left on one it dropped would read the default storefront's answers under the dropped one's
  /// name, currency and caches. They are moved to the default storefront the way a choice moves them: saved, headers rebuilt, what held the
  /// dropped storefront told. Nothing is done while storefronts are off, before the server has answered once (there is then nothing to
  /// judge by), or for a customer who is on a storefront the answer lists or on the default one.
  Future<StorefrontSwitch> followTheServersList() async {
    await storefrontController.refresh();

    final StorefrontCountry current = storefrontController.current;
    final List<StorefrontCountry> listed = storefrontController.available;
    final bool stillListed =
        listed.any((StorefrontCountry storefront) => storefront.code == current.code);

    if (listed.isEmpty || stillListed) {
      return StorefrontSwitch.unchanged;
    }

    return switchTo(StorefrontCountry.defaultCountry);
  }
}
