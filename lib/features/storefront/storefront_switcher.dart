import 'dart:async';

import 'package:syriapharmacy/features/storefront/controllers/storefront_controller.dart';
import 'package:syriapharmacy/features/storefront/domain/models/storefront_country.dart';
import 'package:syriapharmacy/features/storefront/storefront_change_notifier.dart';

enum StorefrontSwitch {
  /// The customer is on another storefront — the one they chose, or the one the server's list moved them to — and everything that held the
  /// previous one has been told.
  switched,

  /// They were already on that storefront, so nothing was done.
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
  Future<StorefrontSwitch> switchTo(StorefrontCountry storefront) =>
      _settleOn(storefront, from: storefrontController.current);

  /// Asks the server which storefronts it lists, then keeps the customer on one of them, under the name, currency and caches of the one
  /// the app is actually asking for.
  ///
  /// The server answers a country it does not list as the default storefront, so a customer left on one it dropped would read the default
  /// storefront's answers under the dropped one's name, currency and caches. They are moved to the storefront the answer names its default,
  /// and to Saudi Arabia while it names none, the way a choice moves them: saved, headers rebuilt, what held the dropped storefront told. A
  /// customer on a storefront the server has stopped in the redirect mode is moved the same way to the storefront it names, when that one is
  /// listed and is not itself redirected (two storefronts that send each other away would move the customer on every start); a storefront in
  /// any other stop mode keeps its customers.
  ///
  /// A customer who has chosen no storefront is on the one the answer names its default, so the answer itself can move them: the storefront
  /// is read before the server is asked and again after, and a move the new answer made is seen through the same headers and caches as a
  /// move a choice makes. Nothing is written for it, so the next answer moves them again.
  ///
  /// Nothing is done while storefronts are off, before the server has answered once (there is then nothing to judge by), or for a customer
  /// whose storefront the answer lists, does not redirect, and has not moved.
  Future<StorefrontSwitch> followTheServersList() async {
    final StorefrontCountry before = storefrontController.current;

    await storefrontController.refresh();

    final List<StorefrontCountry> listed = storefrontController.available;
    if (listed.isEmpty) {
      return StorefrontSwitch.unchanged;
    }

    return _settleOn(_whereTheListLeavesThem(listed), from: before);
  }

  /// The storefront the answer leaves the customer on: the one they are on while it lists them and does not redirect them, the one a
  /// redirected storefront names, and the default of the list while it does not list theirs at all.
  StorefrontCountry _whereTheListLeavesThem(List<StorefrontCountry> listed) {
    final StorefrontCountry current = storefrontController.current;

    final StorefrontCountry? entry = _listedAs(listed, current.code);
    if (entry == null) {
      return StorefrontCountry.fallbackAmong(listed);
    }

    final String? destinationCode = entry.redirectsTo;
    final StorefrontCountry? destination =
        destinationCode == null ? null : _listedAs(listed, destinationCode);

    return destination == null || destination.redirectsTo != null
        ? current
        : destination;
  }

  /// Leaves the customer on [storefront], coming [from] the storefront the app's requests, caches and screens are on now. The two are not
  /// always the storefront the app resolves: a customer who has chosen none is on the default of the server's list, and a newer list moves
  /// them without anything being written.
  ///
  /// The choice is saved only when the app would not resolve [storefront] on its own, so a customer following the server's default keeps
  /// following it rather than being pinned to the one it names today. The rest is what a choice does, in the order it has to be done: the
  /// headers are rebuilt so every request asks for the new storefront, then everything that held the old one is told.
  Future<StorefrontSwitch> _settleOn(StorefrontCountry storefront,
      {required StorefrontCountry from}) async {
    if (storefront.code != storefrontController.current.code &&
        !await storefrontController.choose(storefront)) {
      return StorefrontSwitch.failed;
    }

    if (from.code == storefront.code) {
      return StorefrontSwitch.unchanged;
    }

    applyHeaders();
    unawaited(
        changeNotifier.storefrontChanged(previous: from, current: storefront));

    return StorefrontSwitch.switched;
  }

  static StorefrontCountry? _listedAs(
      List<StorefrontCountry> listed, String code) {
    for (final StorefrontCountry storefront in listed) {
      if (storefront.code == code) {
        return storefront;
      }
    }

    return null;
  }
}
