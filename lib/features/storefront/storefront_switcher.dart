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
}
