import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:syriapharmacy/features/storefront/controllers/storefront_controller.dart';
import 'package:syriapharmacy/features/storefront/domain/models/storefront_country.dart';
import 'package:syriapharmacy/features/storefront/storefront_config.dart';
import 'package:syriapharmacy/features/storefront/storefront_switcher.dart';

/// What the app does with a link that names a market other than the one the customer is on (J-10).
///
/// The owner's decision between the three is OPEN, so all three are built and the choice is a build
/// flag rather than a code change. The shipped value is [stay], which is exactly what the app did
/// before a link could name a market at all, and it honours the plan's own rule that a manual
/// choice is never overridden by something inferred (plan line 189).
enum DeepLinkStorefrontRule {
  /// Open the link in the market the customer chose. Nothing moves.
  stay,

  /// Ask the customer, naming both markets, and move only if they say so.
  ask,

  /// Move to the market the link names, then open it there.
  follow,
}

/// The rule this build follows, from `--dart-define=GCC_DEEP_LINK_MARKET_RULE=ask|follow|stay`.
///
/// Anything else, including a typo and a blank value, is [DeepLinkStorefrontRule.stay]: a rule that
/// MOVES a customer between markets must be asked for on purpose and never arrived at by accident.
class DeepLinkStorefrontRuleConfig {
  static const String _configured =
      String.fromEnvironment('GCC_DEEP_LINK_MARKET_RULE', defaultValue: 'stay');

  static DeepLinkStorefrontRule get rule => parse(_configured);

  static DeepLinkStorefrontRule parse(String value) {
    return switch (value.trim().toLowerCase()) {
      'ask' => DeepLinkStorefrontRule.ask,
      'follow' || 'switch' => DeepLinkStorefrontRule.follow,
      _ => DeepLinkStorefrontRule.stay,
    };
  }
}

/// What the gateway has to do before it opens a link.
enum DeepLinkStorefrontStep {
  /// Open it where the customer is, which is the whole of what this app did before.
  openHere,

  /// Ask the customer first.
  askFirst,

  /// Move to the market the link names, then open it.
  moveThenOpen,
}

/// The market a link names, and what to do about it.
///
/// This is the deep-link half of what `PushStorefrontTarget` does for a tapped notification, and it
/// is deliberately the same shape: the market is honoured only when the server LISTS it, only when
/// it differs from the one the customer is on, and never while storefronts are off. The two are
/// kept apart because their decisions are different — a push that names a market is the market's own
/// message and moves the customer (A1-17, decided), while a link is something a person was handed
/// and the owner has not yet said what it should do (J-10, open).
class DeepLinkStorefrontTarget {
  /// The market to open the link in, or null when there is nothing to move to.
  ///
  /// Null while storefronts are off, for a link that names no market, for one that names the market
  /// the customer is already on, and for one that names a market the server does not list — a link
  /// can never put a customer in a market the shop does not serve.
  static StorefrontCountry? of({
    required String? named,
    required StorefrontCountry current,
    required List<StorefrontCountry> available,
    bool storefronts = StorefrontConfig.enabled,
  }) {
    if (!storefronts || named == null) {
      return null;
    }

    final String code = named.trim().toUpperCase();
    if (code.isEmpty || code == current.code) {
      return null;
    }

    for (final StorefrontCountry storefront in available) {
      if (storefront.code == code) {
        return storefront;
      }
    }

    return null;
  }

  /// What to do, given the market the link named and the rule this build follows. Nothing to move to
  /// is always [DeepLinkStorefrontStep.openHere], whatever the rule says.
  static DeepLinkStorefrontStep step({
    required StorefrontCountry? target,
    DeepLinkStorefrontRule? rule,
  }) {
    if (target == null) {
      return DeepLinkStorefrontStep.openHere;
    }

    return switch (rule ?? DeepLinkStorefrontRuleConfig.rule) {
      DeepLinkStorefrontRule.stay => DeepLinkStorefrontStep.openHere,
      DeepLinkStorefrontRule.ask => DeepLinkStorefrontStep.askFirst,
      DeepLinkStorefrontRule.follow => DeepLinkStorefrontStep.moveThenOpen,
    };
  }

  /// The move itself: the one the storefront chooser makes, so the screen the link opens next is
  /// built under the market it named.
  ///
  /// A move that fails must not cost the customer the screen they tapped for, exactly as on the push
  /// path: the failure is logged and the link opens in the market they are on, which is what it did
  /// before any of this existed.
  static Future<void> move(StorefrontSwitcher switcher, StorefrontCountry target) async {
    try {
      await switcher.switchTo(target);
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[deep link] the storefront did not move: ${error.runtimeType}');
      }
    }
  }

  /// A provider the gateway needs, or null when the tree does not offer it — a link can be opened
  /// before the app has built it, and a link must never be swallowed because of that.
  static T? read<T extends Object>(BuildContext? context) {
    if (context == null) {
      return null;
    }

    try {
      return Provider.of<T>(context, listen: false);
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[deep link] no ${T.toString()} in this tree: ${error.runtimeType}');
      }

      return null;
    }
  }

  /// The market a link names and what to do about it, read from the tree. [DeepLinkStorefrontStep.openHere]
  /// with no target whenever the controllers that would make the move are not there.
  static ({StorefrontCountry? target, DeepLinkStorefrontStep step}) decide({
    required String? named,
    required BuildContext? context,
    DeepLinkStorefrontRule? rule,
  }) {
    final StorefrontController? controller = read<StorefrontController>(context);

    if (controller == null || read<StorefrontSwitcher>(context) == null) {
      return (target: null, step: DeepLinkStorefrontStep.openHere);
    }

    final StorefrontCountry? target = of(
      named: named,
      current: controller.current,
      available: controller.available,
    );

    return (target: target, step: step(target: target, rule: rule));
  }
}
