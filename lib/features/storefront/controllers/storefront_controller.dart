import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:syriapharmacy/features/storefront/checkout_sale_gate.dart';
import 'package:syriapharmacy/features/storefront/domain/models/storefront_country.dart';
import 'package:syriapharmacy/features/storefront/domain/services/storefront_service_interface.dart';
import 'package:syriapharmacy/features/storefront/storefront_choice.dart';
import 'package:syriapharmacy/features/storefront/storefront_config.dart';

/// What the screens need to know about the storefront the customer is on: whether it may sell yet. The server's answer is asked for
/// at app start, once the shop's config has loaded, and again whenever the customer chooses another storefront, and never while a
/// screen is built. A screen that listens is rebuilt when a newer answer arrives.
///
/// A storefront chooser must call [choose] rather than `StorefrontChoice.choose`, or the answer for the new storefront is not asked for.
///
/// While storefronts are off nothing here asks the server and nothing notifies, so a build with them off behaves as it did.
class StorefrontController extends ChangeNotifier {
  StorefrontController({
    required this.storefrontServiceInterface,
    required this.storefrontChoice,
  });

  final StorefrontServiceInterface storefrontServiceInterface;
  final StorefrontChoice storefrontChoice;

  /// Whether the storefront the customer is on may start a sale, for the controllers that place an order or start a payment and have
  /// no widget to listen from. While storefronts are off it answers yes without looking anything up. With no context to look the
  /// controller up from there is nothing to judge by, so it answers yes and leaves the refusal to the server.
  static bool maySellIn(BuildContext? context) {
    if (!StorefrontConfig.enabled || context == null) {
      return true;
    }

    return Provider.of<StorefrontController>(context, listen: false)
        .saleGate
        .storefrontMaySell;
  }

  CheckoutSaleGate get saleGate => CheckoutSaleGate(
        storefrontMaySell: storefrontChoice.canSell(storefrontChoice.current()),
      );

  /// Asks the server which storefronts may sell yet. It runs in the background and never throws: a refresh that fails leaves the
  /// last stored answer in force.
  Future<void> refresh() async {
    if (!storefrontChoice.enabled) {
      return;
    }

    try {
      final bool refreshed =
          await storefrontServiceInterface.refreshStorefronts();
      if (refreshed) {
        notifyListeners();
      }
    } catch (error) {
      if (kDebugMode) debugPrint('[storefront] refresh failed: $error');
    }
  }

  /// Saves the customer's choice and asks for the answer about it. False when the choice was not saved, which is always the case while
  /// storefronts are off.
  Future<bool> choose(StorefrontCountry storefront) async {
    final bool saved = await storefrontChoice.choose(storefront);
    if (saved) {
      notifyListeners();
      await refresh();
    }

    return saved;
  }
}
