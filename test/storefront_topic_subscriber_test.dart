import 'package:flutter_test/flutter_test.dart';
import 'package:syriapharmacy/features/storefront/domain/models/storefront_country.dart';
import 'package:syriapharmacy/features/storefront/storefront_change_notifier.dart';
import 'package:syriapharmacy/push_notification/storefront_topic_subscriber.dart';
import 'package:syriapharmacy/utill/app_constants.dart';

/// J-11 criteria 1 and 2: the marketing topics are scoped by storefront, and a switch or a sign-out leaves the storefront the device is
/// no longer on while it joins the one it is.
///
/// Every call Firebase would be asked to make is recorded instead, so what is measured is the SET of topics joined and the SET left, not
/// a plugin. The build flag is a parameter of the subscriber, so both answers are measured in one run.
///
/// The test that protects every install that exists today is the first group: with storefronts off the subscription is exactly
/// `{sixvalley}` and NOT ONE unsubscribe call is made, because the app made none before and the backend still publishes every marketing
/// broadcast to that topic (tracker I1-05 is not built).
void main() {
  late List<String> joined;
  late List<String> left;

  setUp(() {
    joined = <String>[];
    left = <String>[];
  });

  StorefrontTopicSubscriber subscriberOn(
    StorefrontCountry storefront, {
    required bool enabled,
    bool marketingAllowed = true,
    List<StorefrontCountry> available = const <StorefrontCountry>[],
  }) =>
      StorefrontTopicSubscriber(
        subscribeToTopic: (String topic) async => joined.add(topic),
        unsubscribeFromTopic: (String topic) async => left.add(topic),
        currentStorefront: () => storefront,
        availableStorefronts: () => available,
        pushMarketingAllowed: (_) => marketingAllowed,
        enabled: enabled,
      );

  StorefrontChange moveFrom(
          StorefrontCountry previous, StorefrontCountry current) =>
      StorefrontChange(previous: previous, current: current, signedIn: true);

  group('with storefronts off: exactly what the app did before', () {
    test('the device token registration subscribes sixvalley and nothing else', () async {
      await subscriberOn(StorefrontCountry.saudiArabia, enabled: false).apply();

      expect(joined, <String>[AppConstants.topic]);
      expect(joined, <String>['sixvalley']);
    });

    test('and unsubscribes from nothing at all', () async {
      await subscriberOn(StorefrontCountry.saudiArabia, enabled: false).apply();

      expect(left, isEmpty);
    });

    test('signing out leaves nothing, as before', () async {
      await subscriberOn(StorefrontCountry.saudiArabia, enabled: false)
          .leaveEverything();

      expect(left, isEmpty);
      expect(joined, isEmpty);
    });

    test('a storefront change tells it nothing new: the set is the global topic whatever market is named', () async {
      await subscriberOn(StorefrontCountry.kuwait, enabled: false)
          .onStorefrontChanged(
              moveFrom(StorefrontCountry.saudiArabia, StorefrontCountry.kuwait));

      expect(joined, <String>[AppConstants.topic]);
      expect(left, isEmpty);
    });

    test('and a person who has refused marketing is still on the global topic, because this build never asked them', () async {
      await subscriberOn(StorefrontCountry.saudiArabia,
              enabled: false, marketingAllowed: false)
          .apply();

      expect(joined, <String>[AppConstants.topic]);
      expect(left, isEmpty);
    });
  });

  group('with storefronts on', () {
    test('the device joins the current storefront\'s topic', () async {
      await subscriberOn(StorefrontCountry.kuwait, enabled: true).apply();

      expect(joined, <String>['sixvalley_kw']);
    });

    test('and leaves the global topic, which is where it was before the update', () async {
      await subscriberOn(StorefrontCountry.kuwait, enabled: true).apply();

      expect(left, contains(AppConstants.topic));
    });

    test('and leaves every other market\'s topic', () async {
      await subscriberOn(StorefrontCountry.kuwait, enabled: true).apply();

      expect(left, contains('sixvalley_sa'));
      expect(left, contains('sixvalley_ae'));
      expect(left, contains('sixvalley_qa'));
      expect(left, contains('sixvalley_bh'));
      expect(left, contains('sixvalley_om'));
      expect(left, isNot(contains('sixvalley_kw')));
    });

    test('a switch leaves the storefront the customer left and joins the one they chose', () async {
      await subscriberOn(StorefrontCountry.kuwait, enabled: true)
          .onStorefrontChanged(
              moveFrom(StorefrontCountry.saudiArabia, StorefrontCountry.kuwait));

      expect(joined, <String>['sixvalley_kw']);
      expect(left, contains('sixvalley_sa'));
      expect(left, isNot(contains('sixvalley_kw')));
    });

    test('the switch is judged by the storefront the change names, not by the one the subscriber would resolve', () async {
      // The subscriber is told it is on Saudi Arabia, and the change says the customer has moved to Qatar. What the change says wins:
      // the notifier runs after the headers are rebuilt, and it is the authority on where the customer now is.
      await subscriberOn(StorefrontCountry.saudiArabia, enabled: true)
          .onStorefrontChanged(
              moveFrom(StorefrontCountry.kuwait, StorefrontCountry.qatar));

      expect(joined, <String>['sixvalley_qa']);
      expect(left, contains('sixvalley_kw'));
      expect(left, contains('sixvalley_sa'));
    });

    test('a market the server has opened since this app was built is left as well', () async {
      await subscriberOn(
        StorefrontCountry.kuwait,
        enabled: true,
        available: <StorefrontCountry>[
          const StorefrontCountry(code: 'EG', path: '/eg', currency: 'EGP'),
        ],
      ).apply();

      expect(left, contains('sixvalley_eg'));
    });

    test('signing out leaves every marketing topic and joins none', () async {
      await subscriberOn(StorefrontCountry.kuwait, enabled: true)
          .leaveEverything();

      expect(joined, isEmpty);
      expect(left, contains('sixvalley_kw'));
      expect(left, contains(AppConstants.topic));
      for (final StorefrontCountry storefront in StorefrontCountry.all) {
        expect(left, contains('sixvalley_${storefront.code.toLowerCase()}'),
            reason: storefront.code);
      }
    });

    test('a person who has not agreed joins nothing, and is taken off everything', () async {
      await subscriberOn(StorefrontCountry.kuwait,
              enabled: true, marketingAllowed: false)
          .apply();

      expect(joined, isEmpty);
      expect(left, contains('sixvalley_kw'));
      expect(left, contains(AppConstants.topic));
    });

    test('THE LEAVING COMES BEFORE THE JOINING, so a device is never on two markets at once', () async {
      // Recorded in one list, in the order the calls were made, so the order itself is what is asserted. A device that joined the new
      // market first would be on both for a moment and could be handed a broadcast meant for the market it left.
      final List<String> calls = <String>[];
      final StorefrontTopicSubscriber subscriber = StorefrontTopicSubscriber(
        subscribeToTopic: (String topic) async => calls.add('join $topic'),
        unsubscribeFromTopic: (String topic) async => calls.add('leave $topic'),
        currentStorefront: () => StorefrontCountry.kuwait,
        availableStorefronts: () => const <StorefrontCountry>[],
        pushMarketingAllowed: (_) => true,
        enabled: true,
      );

      await subscriber.onStorefrontChanged(
          moveFrom(StorefrontCountry.saudiArabia, StorefrontCountry.kuwait));

      expect(calls.last, 'join sixvalley_kw');
      expect(calls.indexOf('leave sixvalley_sa'),
          lessThan(calls.indexOf('join sixvalley_kw')));
      expect(calls.indexOf('leave ${AppConstants.topic}'),
          lessThan(calls.indexOf('join sixvalley_kw')));
    });

    test('a topic call that fails does not stop the rest', () async {
      final StorefrontTopicSubscriber subscriber = StorefrontTopicSubscriber(
        subscribeToTopic: (String topic) async =>
            throw StateError('no network'),
        unsubscribeFromTopic: (String topic) async => left.add(topic),
        currentStorefront: () => StorefrontCountry.kuwait,
        availableStorefronts: () => const <StorefrontCountry>[],
        pushMarketingAllowed: (_) => true,
        enabled: true,
      );

      await subscriber.apply();

      expect(left, contains(AppConstants.topic));
    });
  });

  group('the one place the question is answered', () {
    test('the subscriber\'s wanted set is what StorefrontTopics says, and nothing is decided twice', () async {
      final StorefrontTopicSubscriber off =
          subscriberOn(StorefrontCountry.kuwait, enabled: false);
      final StorefrontTopicSubscriber on =
          subscriberOn(StorefrontCountry.kuwait, enabled: true);

      expect(off.wanted, <String>{AppConstants.topic});
      expect(on.wanted, <String>{'sixvalley_kw'});
    });
  });
}
