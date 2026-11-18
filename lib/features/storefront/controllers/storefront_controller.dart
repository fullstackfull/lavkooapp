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
    this.answerWait = const Duration(seconds: 5),
  });

  final StorefrontServiceInterface storefrontServiceInterface;
  final StorefrontChoice storefrontChoice;

  /// How long a choice waits for the server's answer about the new storefront before it lets the customer through. On a bad network the
  /// request can take a minute; the customer is not held in the loader for it. The answer, when it comes, is still stored and the screens are
  /// still told: until then the storefront is judged by the last answer, so a storefront the server has just opened stays browse-only a little longer.
  final Duration answerWait;

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

  /// The storefront the customer is on.
  StorefrontCountry get current => storefrontChoice.current();

  /// The storefronts the shop serves, as the server last said. Empty while storefronts are off.
  List<StorefrontCountry> get available => storefrontChoice.available();

  /// Whether the customer has a storefront to choose: storefronts are on and the server lists more than one. A shop that serves one
  /// storefront, or a build with storefronts off, shows no chooser.
  bool get canChoose => available.length > 1;

  /// Whether a sale may start on [storefront], as the checkout would decide it on that storefront.
  bool canSell(StorefrontCountry storefront) =>
      storefrontChoice.canSell(storefront);

  /// The server's entry for the storefront the customer is on, with how it is stopped, the message for its customers and the end of the stop. Null while
  /// storefronts are off, before the server has answered once, and when its answer does not list the storefront.
  StorefrontCountry? get currentEntry =>
      storefrontChoice.listedEntryOf(current);

  /// Whether the server has put the storefront the customer is on in maintenance: it is not browsed, and what the customer already has is served elsewhere.
  bool get inMaintenance => currentEntry?.isInMaintenance ?? false;

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

  /// Saves the customer's choice and asks for the answer about it, waiting for it for [answerWait] at most. False when the choice was not saved,
  /// which is always the case while storefronts are off.
  Future<bool> choose(StorefrontCountry storefront) async {
    final bool saved = await storefrontChoice.choose(storefront);
    if (saved) {
      notifyListeners();
      await refresh().timeout(answerWait, onTimeout: () {});
    }

    return saved;
  }
}
