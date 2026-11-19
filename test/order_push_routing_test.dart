import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
// ignore: depend_on_referenced_packages
import 'package:firebase_messaging_platform_interface/firebase_messaging_platform_interface.dart'
    show FirebaseMessagingPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syriapharmacy/features/storefront/controllers/storefront_controller.dart';
import 'package:syriapharmacy/features/storefront/domain/models/storefront_country.dart';
import 'package:syriapharmacy/features/storefront/domain/services/storefront_service_interface.dart';
import 'package:syriapharmacy/features/storefront/storefront_choice.dart';
import 'package:syriapharmacy/features/storefront/storefront_scope.dart';
import 'package:syriapharmacy/features/storefront/stored_storefronts.dart';
import 'package:syriapharmacy/helper/route_healper.dart';
import 'package:syriapharmacy/main.dart' show navigatorKey;
import 'package:syriapharmacy/push_notification/models/notification_body.dart';
import 'package:syriapharmacy/push_notification/notification_helper.dart';
import 'package:syriapharmacy/utill/app_constants.dart';

/// Stands in for the plugin that shows local notifications, to be handed the function the app wants called when the customer taps one.
class _CapturingPlugin implements FlutterLocalNotificationsPlugin {
  DidReceiveNotificationResponseCallback? onTap;

  @override
  Future<bool?> initialize({
    required InitializationSettings settings,
    DidReceiveNotificationResponseCallback? onDidReceiveNotificationResponse,
    DidReceiveBackgroundNotificationResponseCallback?
        onDidReceiveBackgroundNotificationResponse,
  }) async {
    onTap = onDidReceiveNotificationResponse;

    return true;
  }

  @override
  T? resolvePlatformSpecificImplementation<
          T extends FlutterLocalNotificationsPlatform>() =>
      null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoServer implements StorefrontServiceInterface {
  @override
  Future<bool> refreshStorefronts() async => false;
}

/// The Emirates, once the server has opened them for sales.
const StorefrontCountry _openedEmirates = StorefrontCountry(
  code: 'AE',
  path: '/ae',
  currency: 'AED',
  sellable: true,
);

/// The storefront the customer chose, and the list the server last answered with.
typedef _Storefront = ({String? chosen, List<StorefrontCountry>? listed});

/// J-11 criterion 3: a push about an order opens the order, by its id, on any storefront, a browse-only one included. The sale gate is asked
/// by what starts a sale and by nothing else, and an order that exists is not a sale.
///
/// The routing is in two functions that `NotificationHelper.initialize` hands to the notification plugin and to the message stream of
/// Firebase: the tap on a notification that the app showed itself (a message that came while it was open), and the tap on one that the system
/// showed (a message that came while it was not). They are reached here the way the app reaches them: the plugin is a stand-in that keeps the
/// function it is given, and the message goes into the stream that Firebase's own code feeds. The route table is a stand-in too: the real one
/// builds the order screen, which needs the providers of the whole app, so what is looked at is the route asked for, by the real
/// `RouterHelper`, with the id. The storefront is set the three ways the app knows it, the choice the customer saved, the list the server last
/// answered with, and the code the HTTP client publishes for the requests (`StorefrontScope`), so a hold-back written on any of them is in
/// the way.
///
/// A push that started the app is routed by the splash screen, which is not driven here (it is the screen of the update gate, and is read and
/// not touched): its two order branches and the absence of a gate in it are pinned by the source.
///
/// A storefront is browse-only only in a build with storefronts on, so the tests that could tell a gate in the way run in that build:
///
///   flutter test test/order_push_routing_test.dart
///   flutter test --dart-define=GCC_STOREFRONTS_ENABLED=true test/order_push_routing_test.dart
void main() {
  late _CapturingPlugin plugin;

  setUpAll(() async {
    plugin = _CapturingPlugin();
    await NotificationHelper.initialize(plugin);
  });

  Future<void> openApp(WidgetTester tester,
      {String? chosen, List<StorefrontCountry>? listed}) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      if (chosen != null) AppConstants.storefrontCountry: chosen,
    });
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    if (listed != null) {
      await StoredStorefronts(preferences).save(listed);
    }
    StorefrontScope.publish(chosen ?? StorefrontCountry.defaultCountry.code);
    addTearDown(() => StorefrontScope.publish(null));

    await tester.pumpWidget(
      ChangeNotifierProvider<StorefrontController>.value(
        value: StorefrontController(
          storefrontServiceInterface: _NoServer(),
          storefrontChoice: StorefrontChoice(preferences, enabled: true),
        ),
        child: MaterialApp.router(
          routerConfig: GoRouter(
            navigatorKey: navigatorKey,
            routes: <RouteBase>[
              GoRoute(
                path: '/',
                builder: (BuildContext context, GoRouterState state) =>
                    const Text('the home screen'),
              ),
              GoRoute(
                path: RouterHelper.orderDetailsScreen,
                builder: (BuildContext context, GoRouterState state) => Text(
                    'order ${state.uri.queryParameters['orderId']}, from a notification: ${state.uri.queryParameters['isNotification']}'),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('the home screen'), findsOneWidget);
  }

  final Map<String, _Storefront> storefronts = <String, _Storefront>{
    'a storefront that may sell': (chosen: null, listed: null),
    'a browse-only storefront': (chosen: 'AE', listed: null),
    'a storefront the server lists as browse-only': (
      chosen: 'AE',
      listed: <StorefrontCountry>[
        StorefrontCountry.saudiArabia,
        const StorefrontCountry(
            code: 'AE', path: '/ae', currency: 'AED', stopMode: 'browse_only'),
      ],
    ),
    'a storefront the server has opened': (
      chosen: 'AE',
      listed: <StorefrontCountry>[
        StorefrontCountry.saudiArabia,
        _openedEmirates,
      ],
    ),
  };

  for (final MapEntry<String, _Storefront> storefront in storefronts.entries) {
    group('on ${storefront.key}', () {
      testWidgets(
          'a tap on the notification of an order that the app showed opens the order by its id',
          (WidgetTester tester) async {
        await openApp(tester,
            chosen: storefront.value.chosen, listed: storefront.value.listed);

        plugin.onTap!(NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotification,
          payload: jsonEncode(
              NotificationBody(type: 'order', orderId: 4217).toJson()),
        ));
        await tester.pumpAndSettle();

        expect(
            find.text('order 4217, from a notification: true'), findsOneWidget);
        expect(find.text('the home screen'), findsNothing);
      });

      testWidgets(
          'a tap on the notification of an order that the system showed opens the order by its id',
          (WidgetTester tester) async {
        await openApp(tester,
            chosen: storefront.value.chosen, listed: storefront.value.listed);

        FirebaseMessagingPlatform.onMessageOpenedApp.add(RemoteMessage(
          data: <String, dynamic>{'type': 'order', 'order_id': '4217'},
          notification: const RemoteNotification(title: 'Your order'),
        ));
        await tester.pumpAndSettle();

        expect(
            find.text('order 4217, from a notification: true'), findsOneWidget);
        expect(find.text('the home screen'), findsNothing);
      });
    });
  }

  test('the id of an order is read from the message as the number it is', () {
    final NotificationBody body = NotificationHelper.convertNotification(
        <String, dynamic>{'type': 'order', 'order_id': '4217'});

    expect(body.type, 'order');
    expect(body.orderId, 4217);
  });

  group('the sources, structural only', () {
    String codeOf(String path) => File(path)
        .readAsLinesSync()
        .where((String line) => !line.trimLeft().startsWith('//'))
        .join('\n');

    final String helper =
        codeOf('lib/push_notification/notification_helper.dart');
    final String splash =
        codeOf('lib/features/splash/screens/splash_screen.dart');
    final String routes = codeOf('lib/helper/route_healper.dart');
    final RegExp gateWords = RegExp(
        r'CheckoutSaleGate|checkout_sale_gate|saleGate|storefrontMaySell|maySellIn|showsBrowseOnlyNotice|BrowseOnlyNotice|browse_only_notice|canSell|sellable');

    test(
        'route an order push to the order by its id, in the tap on a notification of the app and in the tap on one of the system',
        () {
      final RegExp orderBranch = RegExp(
          r"\.type == 'order'\)\s*\{\s*RouterHelper\.getOrderDetailsScreenRoute\(\s*action: RouteAction\.pushReplacement,\s*orderId: (?:payload|notificationBody)\.orderId!,\s*isNotification: true\);");

      expect(orderBranch.allMatches(helper).length, 2);
    });

    test(
        'route an order push that started the app to the order by its id, in the two places the splash screen does it',
        () {
      final RegExp orderBranch = RegExp(
          r"widget\.body!\.type == 'order'\)\s*\{\s*RouterHelper\.getOrderDetailsScreenRoute\(\s*action: RouteAction\.pushReplacement,\s*orderId: widget\.body!\.orderId!,\s*\);");

      expect(orderBranch.allMatches(splash).length, 2);
    });

    test(
        'ask the sale gate nothing: neither the routing of a push, nor the splash screen that routes one that started the app, nor the routes',
        () {
      expect(gateWords.firstMatch(helper)?.group(0), isNull,
          reason: 'the routing of a push');
      expect(gateWords.firstMatch(splash)?.group(0), isNull,
          reason: 'the splash screen');
      expect(gateWords.firstMatch(routes)?.group(0), isNull,
          reason: 'the routes, the order details route among them');
    });
  });
}
