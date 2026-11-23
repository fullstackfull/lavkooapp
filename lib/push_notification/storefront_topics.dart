import 'package:syriapharmacy/features/storefront/domain/models/storefront_country.dart';
import 'package:syriapharmacy/features/storefront/storefront_config.dart';
import 'package:syriapharmacy/utill/app_constants.dart';

/// WHICH MARKETING TOPICS THIS INSTALL SUBSCRIBES TO. One question, answered in one place, so the four controllers that subscribe a topic
/// cannot drift apart.
///
/// While storefronts are off the answer is exactly `{sixvalley}`: the one global topic the app has always subscribed to, which is the
/// topic the backend publishes every marketing broadcast to today. Nothing else is in the set, the per-market topics do not exist, and
/// consent is not consulted — the build behaves exactly as it always did.
///
/// While storefronts are on the answer is the current storefront's own topic, and the global one is NOT in it: a device on the Kuwaiti
/// storefront hears Kuwait's broadcasts and no other market's, which is the whole point. Marketing needs the person's permission for the
/// push channel, so a device whose owner has not agreed subscribes to nothing at all.
///
/// THE BACKEND MUST PUBLISH PER-MARKET BEFORE THE FLAG MAY BE TURNED ON. Its broadcast still goes to the one global topic (tracker
/// I1-05, not built), so a build with storefronts on would leave that topic and hear nothing. That is why
/// [StorefrontConfig.enabled] defaults to false and why both answers are tested.
///
/// The maintenance and theme topics are not here. They are operational — a shop in maintenance, a theme republished — not marketing,
/// they are subscribed before anyone has logged in, and no consent decision governs them.
class StorefrontTopics {
  const StorefrontTopics._();

  /// `sixvalley_kw`: the global topic's own name, then the storefront's ISO code in lower case. The prefix is the existing topic rather
  /// than a new word, so a backend reading the app's topics sees the same family it already publishes to.
  ///
  /// EVERY MARKET GETS A SUFFIX, SAUDI ARABIA INCLUDED, and that is a decision the backend has to agree to. The backend's own tracker
  /// item for the naming (I1-05, IN PROGRESS, nothing built) proposes instead that bare `sixvalley` stay as Saudi Arabia's topic. It
  /// cannot: every install that exists, in every market, is already subscribed to `sixvalley`, so the day the backend began treating that
  /// topic as Saudi Arabia's audience, Saudi marketing would go to every device in all six markets — the exact leak this feature exists
  /// to stop. Keeping `sixvalley` as the legacy global topic, which this app LEAVES when storefronts are on, and giving Saudi Arabia
  /// `sixvalley_sa` like everyone else, is what makes the markets disjoint.
  ///
  /// It is one line, in one place, so the other decision costs one line if the owner takes it.
  static String of(StorefrontCountry storefront) =>
      '${AppConstants.topic}_${storefront.code.trim().toLowerCase()}';

  /// The topics a device on [storefront] should be subscribed to, and the complete set: anything not in it is unsubscribed.
  ///
  /// [enabled] is the storefronts build flag, taken as a parameter so one run can test both answers. [marketingAllowed] is whether the
  /// person has agreed to marketing on the push channel for this market; it is not consulted while storefronts are off, because a build
  /// with them off has no consent screen and must keep the subscription it has always had.
  static Set<String> forStorefront(
    StorefrontCountry storefront, {
    bool enabled = StorefrontConfig.enabled,
    bool marketingAllowed = true,
  }) {
    if (!enabled) {
      return <String>{AppConstants.topic};
    }

    return marketingAllowed ? <String>{of(storefront)} : const <String>{};
  }

  /// Every marketing topic this app could have put this device on, so that what is no longer wanted can be left.
  ///
  /// It holds the global topic as well as the per-market ones, which is what a device carries after an update that turns storefronts on:
  /// it was subscribed to `sixvalley` by the build before, and nothing but this list would ever take it off again.
  ///
  /// [available] is the storefront list the server last answered with, so a market the shop has opened since this app was built is
  /// covered too. Its own six are always included.
  static Set<String> everyTopicThisAppMaySubscribe({
    List<StorefrontCountry> available = const <StorefrontCountry>[],
  }) {
    // Both global constants are listed although they hold the same string today, so a build that gave them different values would still
    // take the device off both. They are added rather than written as a set literal because the analyzer rejects a literal whose two
    // entries it can see are equal, and the point here is not to depend on their being equal.
    final Set<String> topics = <String>{}
      ..add(AppConstants.topic)
      ..add(AppConstants.demoTopic);

    for (final StorefrontCountry storefront in StorefrontCountry.all) {
      topics.add(of(storefront));
    }
    for (final StorefrontCountry storefront in available) {
      topics.add(of(storefront));
    }

    return topics;
  }
}
