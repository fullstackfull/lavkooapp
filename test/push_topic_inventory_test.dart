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
///
/// A GAP THIS INVENTORY RECORDS RATHER THAN CLOSES. The two restock call sites join a topic the server names and the app never notes
/// down, so a switch and a sign-out cannot leave them: a customer who asked to hear about a product in one market keeps hearing about it
/// in another, and after a sign-out the next person on the device hears about the previous person's products. It predates this branch,
/// it is not marketing and no consent governs it, and leaving it needs the app to remember what it joined — which is work of its own, not
/// a line in this feature. An earlier version of this file justified the exclusion by asserting that the server refuses a restock request
/// for a product another storefront sells. THE BACKEND SOURCE DOES NOT SHOW THAT: its restock endpoint keys the request by product and
/// customer and asks nothing about a market. An unverified claim about the other repository is not a reason, so it is gone.
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
          'not marketing: a topic the SERVER names per restock request, restock_<requestId>_product_restock_<productId>_topic (backend app/Utils/product.php getRestockProductFCMTopic), asked for by the customer one product at a time. It carries no market and no marketing name, so it is in no storefront set — and the app keeps no record of which of them it joined, so it cannot leave them either: see the gap recorded below',
      'lib/features/cart/controllers/cart_controller.dart':
          'not marketing: the same server-named restock topic, returned by the cart answer to a restock request (backend RestAPI/v1/CartController) — the same shape and the same gap',
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

    /// A PUSH THAT STARTED THE APP is not routed by the notification helper at all. `main` reads it with
    /// `FirebaseMessaging.instance.getInitialMessage()`, and the splash screen routes it in TWO places of its own. Neither settled the
    /// storefront, so either of them would open an order under whatever storefront the app resolved at launch.
    ///
    /// NEITHER IS REACHED TODAY, and this pin does not pretend otherwise. `main.dart` hands the message to `MyApp(body:)` and nothing
    /// reads it again, and all three constructions of SplashScreen pass no body, so `widget.body` is always null and both blocks are
    /// unreachable. That a cold-start push is routed NOWHERE is a gap this feature did not make and does not close; the tracker records it
    /// against J-11.3. What this pin is for is the day the body is wired through: both branches settle before they route, so the hole does
    /// not reopen silently in the one place a reviewer would not think to look.
    test('settles the storefront in the two places the splash screen routes a push that started the app', () {
      final String splash =
          codeOf('lib/features/splash/screens/splash_screen.dart');
      final RegExp settleThenRoute = RegExp(
          r'PushStorefrontTarget\.enter\(widget\.body!, Get\.context\);\s*if \(movingStorefront != null\) \{\s*await movingStorefront;\s*\}');

      expect(settleThenRoute.allMatches(splash).length, 2,
          reason:
              'main hands a cold-start push to the splash screen, which routes it in two branches; a branch that did not settle first would open the order under the wrong market');
    });
  });
}
