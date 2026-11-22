import 'package:flutter_test/flutter_test.dart';
import 'package:syriapharmacy/features/storefront/domain/models/storefront_country.dart';
import 'package:syriapharmacy/push_notification/storefront_topics.dart';
import 'package:syriapharmacy/utill/app_constants.dart';

/// J-11 criterion 1: the marketing topics an install subscribes to are scoped by storefront, so one country's push cannot reach
/// another's audience.
///
/// [StorefrontTopics.forStorefront] takes the build flag as a parameter, so BOTH answers are measured in one run and the file does not
/// depend on how the build was made. What it does not cover is who calls it: that is storefront_topic_subscriber_test.dart.
void main() {
  group('with storefronts off, the set is the one global topic and nothing else', () {
    test('on Saudi Arabia, the storefront the app serves today', () {
      expect(
        StorefrontTopics.forStorefront(StorefrontCountry.saudiArabia,
            enabled: false),
        <String>{'sixvalley'},
      );
    });

    test('and the topic is the constant the app has always subscribed to', () {
      expect(AppConstants.topic, 'sixvalley');
      expect(
        StorefrontTopics.forStorefront(StorefrontCountry.saudiArabia,
            enabled: false),
        <String>{AppConstants.topic},
      );
    });

    test('on any other storefront, still only the global topic: a build with storefronts off has one market', () {
      for (final StorefrontCountry storefront in StorefrontCountry.all) {
        expect(
          StorefrontTopics.forStorefront(storefront, enabled: false),
          <String>{AppConstants.topic},
          reason: storefront.code,
        );
      }
    });

    test('and consent is not consulted: a build with storefronts off never asked for one', () {
      expect(
        StorefrontTopics.forStorefront(StorefrontCountry.kuwait,
            enabled: false, marketingAllowed: false),
        <String>{AppConstants.topic},
      );
    });
  });

  group('with storefronts on, the set is the storefront\'s own topic', () {
    test('Kuwait hears Kuwait', () {
      expect(
        StorefrontTopics.forStorefront(StorefrontCountry.kuwait,
            enabled: true),
        <String>{'sixvalley_kw'},
      );
    });

    test('and the global topic is NOT in it: a global broadcast would reach every market', () {
      final Set<String> kuwait = StorefrontTopics.forStorefront(
          StorefrontCountry.kuwait,
          enabled: true);

      expect(kuwait, isNot(contains(AppConstants.topic)));
      expect(kuwait, hasLength(1));
    });

    test('no two storefronts share a topic, so one country\'s push cannot reach another\'s audience', () {
      final Set<String> topics = <String>{
        for (final StorefrontCountry storefront in StorefrontCountry.all)
          StorefrontTopics.of(storefront),
      };

      expect(topics, hasLength(StorefrontCountry.all.length));
      expect(
        topics,
        <String>{
          'sixvalley_sa',
          'sixvalley_ae',
          'sixvalley_kw',
          'sixvalley_qa',
          'sixvalley_bh',
          'sixvalley_om',
        },
      );
    });

    test('SAUDI ARABIA DOES NOT KEEP THE BARE GLOBAL TOPIC, which is what makes the six markets disjoint', () {
      // The backend's naming item (I1-05) proposes that `sixvalley` stay as Saudi Arabia's topic. Every install that exists, in every
      // market, is already on `sixvalley`: were it read as Saudi Arabia's audience, Saudi marketing would reach all six markets at once.
      // This is the decision, pinned so that changing it is a visible change and not a drift.
      expect(StorefrontTopics.of(StorefrontCountry.saudiArabia),
          'sixvalley_sa');
      expect(StorefrontTopics.of(StorefrontCountry.saudiArabia),
          isNot(AppConstants.topic));
      expect(
        StorefrontTopics.forStorefront(StorefrontCountry.saudiArabia,
            enabled: true),
        isNot(contains(AppConstants.topic)),
      );
    });

    test('a storefront the server lists that this app does not know gets its own topic too', () {
      expect(
        StorefrontTopics.of(const StorefrontCountry(
            code: 'EG', path: '/eg', currency: 'EGP')),
        'sixvalley_eg',
      );
    });

    test('a person who has not agreed to marketing on this channel subscribes to nothing', () {
      expect(
        StorefrontTopics.forStorefront(StorefrontCountry.kuwait,
            enabled: true, marketingAllowed: false),
        isEmpty,
      );
    });
  });

  group('everything this app could have put the device on', () {
    test('holds the global topic, so an update that turns storefronts on can take the device off it', () {
      expect(
        StorefrontTopics.everyTopicThisAppMaySubscribe(),
        contains(AppConstants.topic),
      );
    });

    test('holds the demo topic as well, whatever string it carries', () {
      expect(
        StorefrontTopics.everyTopicThisAppMaySubscribe(),
        contains(AppConstants.demoTopic),
      );
    });

    test('holds every built-in storefront\'s topic', () {
      final Set<String> every =
          StorefrontTopics.everyTopicThisAppMaySubscribe();

      for (final StorefrontCountry storefront in StorefrontCountry.all) {
        expect(every, contains(StorefrontTopics.of(storefront)),
            reason: storefront.code);
      }
    });

    test('holds a market the server has opened since this app was built', () {
      expect(
        StorefrontTopics.everyTopicThisAppMaySubscribe(
          available: <StorefrontCountry>[
            const StorefrontCountry(code: 'EG', path: '/eg', currency: 'EGP'),
          ],
        ),
        contains('sixvalley_eg'),
      );
    });
  });
}
