import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// J-11 criteria 1 and 2, the WIRING: every place in the app that puts a device on a Firebase topic or takes it off one, accounted for,
/// and the three places that ask the one subscriber.
///
/// The behaviour of the subscriber is measured by running it (storefront_topic_subscriber_test.dart). What this file does instead is pin
/// the things a unit test cannot reach: the container's registration needs the whole app to start, and the sign-out needs an HTTP client.
///
/// IT IS A TEXT SCAN, and that is its limit, stated rather than waved away: a call reached indirectly through another helper would pass
/// it. What it does catch is the regression that matters — a controller that starts subscribing a marketing topic of its own again, or a
/// wiring quietly dropped — because the inventory below is asserted to be COMPLETE and would go red on a call site that is not in it.
void main() {
  final Map<String, String> sources = <String, String>{
    for (final FileSystemEntity entity
        in Directory('lib').listSync(recursive: true))
      if (entity is File && entity.path.endsWith('.dart'))
        entity.path: entity.readAsStringSync(),
  };

  /// A source with its comment lines dropped, so a word in prose is never read as code.
  String codeOf(String path) => sources[path]!
      .split('\n')
      .where((String line) => !line.trimLeft().startsWith('//'))
      .join('\n');

  group('every topic this app subscribes or unsubscribes', () {
    /// `<file>`: what it does with a topic, and why it is or is not marketing.
    final Map<String, String> callers = <String, String>{
      'lib/push_notification/storefront_topic_subscriber.dart':
          'THE MARKETING TOPICS, and the only place that touches one: it asks StorefrontTopics which the device belongs on and leaves every other',
      'lib/features/splash/controllers/splash_controller.dart':
          'not marketing: the maintenance and theme-publish beacons, operational pings subscribed before anyone has signed in, which no consent governs and which are global on purpose',
      'lib/features/restock/controllers/restock_controller.dart':
          'not marketing: a topic per restock request for one product, which the customer asked for; a request for a product another storefront sells is refused by the server',
      'lib/features/cart/controllers/cart_controller.dart':
          'not marketing: the topic the server names in its own answer for this cart',
    };

    test('are made from exactly the files that were looked at', () {
      final RegExp call = RegExp(r'(?:un)?subscribeToTopic|unsubscribeFromTopic');
      final Set<String> found = <String>{
        for (final String path in sources.keys)
          if (call.hasMatch(codeOf(path))) path,
      };

      expect(found, callers.keys.toSet(),
          reason:
              'a file that puts a device on a topic has to be looked at: is that topic marketing, and is it scoped to one market?');
    });

    test('and only the subscriber names a marketing topic', () {
      for (final String path in callers.keys) {
        if (path == 'lib/push_notification/storefront_topic_subscriber.dart') {
          continue;
        }

        expect(codeOf(path), isNot(contains('AppConstants.topic')),
            reason: path);
        expect(codeOf(path), isNot(contains('AppConstants.demoTopic')),
            reason: path);
        expect(codeOf(path), isNot(contains('StorefrontTopics')), reason: path);
      }
    });
  });

  group('the three places that ask the subscriber', () {
    test('the container makes it a listener of the storefront change, so a switch tells it', () {
      expect(
        codeOf('lib/di_container.dart'),
        contains(
            'sl<StorefrontChangeNotifier>().register(sl<StorefrontTopicSubscriber>())'),
      );
    });

    test('the device token registration asks it to apply, and no longer subscribes a topic itself', () {
      final String repository =
          codeOf('lib/features/auth/domain/repositories/auth_repository.dart');

      expect(repository,
          contains('StorefrontTopicSubscriber.forDevice(sharedPreferences!)'));
      expect(repository, contains('.apply()'));
      expect(repository, isNot(contains('subscribeToTopic')),
          reason:
              'the two direct subscribe calls this replaced must not come back: they would put the device on the global topic whatever the storefront');
    });

    test('signing out asks it to leave everything', () {
      expect(
        codeOf('lib/features/auth/domain/repositories/auth_repository.dart'),
        contains('.leaveEverything()'),
      );
    });
  });

  group('the routing of a push', () {
    test('settles the storefront before it routes, in both tap paths, and does not suspend when there is nothing to settle', () {
      final String helper =
          codeOf('lib/push_notification/notification_helper.dart');
      final RegExp settleThenRoute = RegExp(
          r'PushStorefrontTarget\.enter\((?:payload|notificationBody), Get\.context\);\s*if \(movingStorefront != null\) \{\s*await movingStorefront;\s*\}');

      expect(settleThenRoute.allMatches(helper).length, 2);
    });

    test('reads the storefront of a message once, for every kind of message', () {
      expect(
        codeOf('lib/push_notification/notification_helper.dart'),
        contains('body.storefront = NotificationBody.storefrontIn(data);'),
      );
    });
  });
}
