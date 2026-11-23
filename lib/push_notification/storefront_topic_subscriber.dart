import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syriapharmacy/features/marketing_consent/marketing_consent.dart';
import 'package:syriapharmacy/features/marketing_consent/marketing_consent_store.dart';
import 'package:syriapharmacy/features/storefront/domain/models/storefront_country.dart';
import 'package:syriapharmacy/features/storefront/storefront_choice.dart';
import 'package:syriapharmacy/features/storefront/storefront_change_notifier.dart';
import 'package:syriapharmacy/features/storefront/storefront_config.dart';
import 'package:syriapharmacy/push_notification/storefront_topics.dart';

/// Puts this device on the topics [StorefrontTopics] says it belongs on, and TAKES IT OFF the ones it does not.
///
/// It is told three times: when the device token is registered (at login and at every start), when the customer moves to another
/// storefront, and when they sign out. The second and third are the ones that did not exist before — the app had no unsubscribe at all,
/// so a device that had once been on a market's audience stayed on it for ever.
///
/// While storefronts are off it only subscribes, to the one global topic, and leaves nothing: that is exactly what the app did before,
/// and a build that ships with the flag off must not start making calls it never made. Signing out of such a build unsubscribes nothing,
/// as before.
///
/// A topic call that fails is logged and the rest still run. The alternative is worse: a refused topic would otherwise fail the login
/// that registered the token, or stop the storefront switch half-done with the device on two markets' audiences at once. The next
/// [apply] puts it right, and [apply] runs at every start.
class StorefrontTopicSubscriber implements StorefrontChangeListener {
  StorefrontTopicSubscriber({
    required this.subscribeToTopic,
    required this.unsubscribeFromTopic,
    required this.currentStorefront,
    required this.availableStorefronts,
    required this.pushMarketingAllowed,
    this.enabled = StorefrontConfig.enabled,
  });

  /// The one this app uses: Firebase for the topics, the saved choice for the storefront, the server's last list for the markets the shop
  /// has, and this device's own record for whether the person agreed to marketing on the push channel.
  ///
  /// `FirebaseMessaging.instance` is reached only when a call is actually made, so a test builds the subscriber with the main
  /// constructor and no Firebase app has to exist.
  factory StorefrontTopicSubscriber.forDevice(
    SharedPreferences preferences, {
    bool enabled = StorefrontConfig.enabled,
  }) {
    final StorefrontChoice choice =
        StorefrontChoice(preferences, enabled: enabled);
    final MarketingConsentStore consents = MarketingConsentStore(preferences);

    return StorefrontTopicSubscriber(
      subscribeToTopic: (String topic) =>
          FirebaseMessaging.instance.subscribeToTopic(topic),
      unsubscribeFromTopic: (String topic) =>
          FirebaseMessaging.instance.unsubscribeFromTopic(topic),
      currentStorefront: choice.current,
      availableStorefronts: choice.available,
      pushMarketingAllowed: (StorefrontCountry storefront) => consents.allows(
        market: storefront.code,
        channel: MarketingConsent.channelPush,
        purpose: MarketingConsent.purposeBroadcast,
      ),
      enabled: enabled,
    );
  }

  final Future<void> Function(String topic) subscribeToTopic;
  final Future<void> Function(String topic) unsubscribeFromTopic;

  final StorefrontCountry Function() currentStorefront;

  /// The storefronts the server last listed, so a market the shop opened after this app was built is one this device can also be taken
  /// off. Empty is fine: the six built-in ones are always covered.
  final List<StorefrontCountry> Function() availableStorefronts;

  /// Whether the person has agreed to marketing on the push channel for a storefront. Not consulted while storefronts are off.
  final bool Function(StorefrontCountry storefront) pushMarketingAllowed;

  /// The storefronts build flag, a parameter so one run can test both answers.
  final bool enabled;

  /// The topics this device should be on now, for the storefront it is on.
  Set<String> get wanted => StorefrontTopics.forStorefront(
        currentStorefront(),
        enabled: enabled,
        marketingAllowed: pushMarketingAllowed(currentStorefront()),
      );

  /// Subscribes what the current storefront wants and leaves everything else. Called when the device token is registered.
  Future<void> apply() => _settle(wanted);

  /// A customer who has moved to another storefront: the storefront they left is no longer wanted, so its topics are left and the new
  /// one's are joined. [StorefrontChangeNotifier] calls this only while storefronts are on.
  @override
  Future<void> onStorefrontChanged(StorefrontChange change) =>
      _settle(StorefrontTopics.forStorefront(
        change.current,
        enabled: enabled,
        marketingAllowed: pushMarketingAllowed(change.current),
      ));

  /// A customer who has signed out: the device leaves every marketing topic, so it stops receiving the market's marketing once nobody is
  /// signed in on it. A build with storefronts off leaves nothing, as before.
  Future<void> leaveEverything() => _settle(const <String>{});

  /// Leaves every topic this app could have put the device on except [target], and then joins [target].
  ///
  /// THE LEAVING COMES FIRST. A device that joined the new market before leaving the old one would be on both for a moment and could be
  /// handed one broadcast meant for the market it left, which is the very thing this feature exists to stop; leaving first can only cost
  /// a broadcast that was not seen. Missing one is better than one market's offer reaching another market's customer.
  ///
  /// With storefronts off nothing is unsubscribed: the app made no such call before and must not start. That is what leaves the build
  /// that ships today with exactly the one subscribe call it has always made.
  Future<void> _settle(Set<String> target) async {
    if (enabled) {
      final Set<String> toLeave =
          StorefrontTopics.everyTopicThisAppMaySubscribe(
        available: availableStorefronts(),
      )..removeAll(target);

      for (final String topic in toLeave) {
        await _call(unsubscribeFromTopic, topic, 'unsubscribe');
      }
    }

    for (final String topic in target) {
      await _call(subscribeToTopic, topic, 'subscribe');
    }
  }

  Future<void> _call(
    Future<void> Function(String topic) call,
    String topic,
    String what,
  ) async {
    try {
      await call(topic);
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[push] $what $topic failed: ${error.runtimeType}');
      }
    }
  }
}
