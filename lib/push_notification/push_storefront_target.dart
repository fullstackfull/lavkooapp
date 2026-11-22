import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:syriapharmacy/features/storefront/controllers/storefront_controller.dart';
import 'package:syriapharmacy/features/storefront/domain/models/storefront_country.dart';
import 'package:syriapharmacy/features/storefront/storefront_config.dart';
import 'package:syriapharmacy/features/storefront/storefront_switcher.dart';
import 'package:syriapharmacy/push_notification/models/notification_body.dart';

/// THE STOREFRONT A TAP ON A PUSH OPENS IN.
///
/// A push that names a storefront is about that market's order, wallet or product, so the screen it opens has to be read under that
/// market's headers, currency and caches. The customer is moved there first and the routing then happens as it always did: the order by
/// its id, the wallet, the product.
///
/// A PUSH THAT NAMES NO STOREFRONT IS LEFT ALONE, and that is the case for every push the backend sends today — no sender writes the key.
/// [of] answers null for it, [enter] does nothing, and not one provider is even looked up, so the routing is bit for bit what it was.
/// The same is true of a build with storefronts off, of a storefront the server does not list, and of a push about the market the
/// customer is already on.
class PushStorefrontTarget {
  const PushStorefrontTarget._();

  /// The storefront the customer has to be moved to before the tap is routed, or null when there is nothing to move.
  ///
  /// Null when storefronts are off, when the message names no storefront, when it names the one the customer is on, and when it names
  /// one the server does not list. The last is the one worth saying out loud: moving a customer to a market the shop has not listed
  /// would leave them reading that market's name and currency over answers the server will not give, so an unknown market is treated as
  /// a push that named nothing.
  static StorefrontCountry? of(
    NotificationBody body, {
    required StorefrontCountry current,
    required List<StorefrontCountry> available,
    bool enabled = StorefrontConfig.enabled,
  }) {
    final String? named = body.storefront;
    if (!enabled || named == null || named == current.code) {
      return null;
    }

    for (final StorefrontCountry storefront in available) {
      if (storefront.code == named) {
        return storefront;
      }
    }

    return null;
  }

  /// The move the tap has to wait for before it routes, or NULL when there is nothing to move.
  ///
  /// The move is the one the storefront chooser makes — the choice saved, the headers rebuilt, everything holding the market they left
  /// told to drop it — so the screen the tap opens next is built under the storefront the push was about.
  ///
  /// It is deliberately NOT an `async` function. Returning null rather than a completed future means a caller that writes
  /// `if (move != null) await move;` does not suspend at all for a push with no storefront to move to, so the routing of every push the
  /// backend sends today is reached in the same turn of the event loop it always was. An earlier draft of this returned
  /// `Future<void>` and awaited it unconditionally; that alone broke an existing test of the order push routing, which is how plainly
  /// the extra hop was observable.
  ///
  /// Null for a build with storefronts off, for a push that names no storefront, for one that names the storefront the customer is on or
  /// one the server does not list, and when the providers that make the move are not mounted. The first two tests come before any lookup.
  static Future<void>? enter(NotificationBody body, BuildContext? context) {
    if (!StorefrontConfig.enabled || body.storefront == null) {
      return null;
    }

    final StorefrontController? controller =
        _read<StorefrontController>(context);
    final StorefrontSwitcher? switcher = _read<StorefrontSwitcher>(context);
    if (controller == null || switcher == null) {
      return null;
    }

    final StorefrontCountry? target = of(
      body,
      current: controller.current,
      available: controller.available,
    );

    return target == null ? null : _move(switcher, target);
  }

  /// A move that fails must not cost the customer the screen they tapped for.
  ///
  /// Both tap paths in the notification helper route inside a `try`/`catch` that swallows everything, so an exception escaping from here
  /// would skip the routing altogether and the tap would do NOTHING — a regression on a path that has always opened a screen. A failure
  /// is logged instead, and the tap goes on to route on the storefront the app is already on, which is exactly what it did before this
  /// existed.
  static Future<void> _move(
      StorefrontSwitcher switcher, StorefrontCountry target) async {
    try {
      await switcher.switchTo(target);
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[push] the storefront did not move: ${error.runtimeType}');
      }
    }
  }

  /// A push can be tapped before the app has built the tree that provides these, and a notification must never be swallowed because of
  /// it: a missing provider means the move cannot be made, and the tap is routed on the storefront the app is on.
  static T? _read<T extends Object>(BuildContext? context) {
    if (context == null) {
      return null;
    }

    try {
      return Provider.of<T>(context, listen: false);
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[push] no $T to move the storefront with: ${error.runtimeType}');
      }

      return null;
    }
  }
}
