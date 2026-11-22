import 'dart:convert';

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
import 'package:syriapharmacy/features/storefront/storefront_change_notifier.dart';
import 'package:syriapharmacy/features/storefront/storefront_choice.dart';
import 'package:syriapharmacy/features/storefront/storefront_config.dart';
import 'package:syriapharmacy/features/storefront/storefront_scope.dart';
import 'package:syriapharmacy/features/storefront/storefront_switcher.dart';
import 'package:syriapharmacy/features/storefront/stored_storefronts.dart';
import 'package:syriapharmacy/helper/route_healper.dart';
import 'package:syriapharmacy/main.dart' show navigatorKey;
import 'package:syriapharmacy/push_notification/models/notification_body.dart';
import 'package:syriapharmacy/push_notification/notification_helper.dart';
import 'package:syriapharmacy/utill/app_constants.dart';

/// J-11 criterion 3: a push carries its storefront, and THE TAP OPENS THE ORDER, THE WALLET OR THE PRODUCT IN THAT STOREFRONT'S CONTEXT.
///
/// Nothing is stubbed between the tap and the move. The real `NotificationHelper.initialize` is run, the real local-notification tap and
/// the real Firebase opened-app message are driven through it, and the move is made by the real [StorefrontSwitcher] over a real
/// [StorefrontController] and a real [StorefrontChangeNotifier]. What is looked at afterwards is the storefront the app is actually on:
/// the choice that was saved, and the code the request headers publish ([StorefrontScope]), which is what every later request and every
/// cache read will be filed under. The route table is a stand-in, as in order_push_routing_test.dart, because the real order screen needs
/// the providers of the whole app.
///
/// THE CASE A REVIEWER SHOULD COME FOR IS THE LAST GROUP: a push that names no storefront. That is every push the backend sends today
/// and every push in flight when an app is updated, and it has to behave exactly as it always did. It is asserted in BOTH settings of
/// the build flag, because it has to hold in both.
///
///   flutter test test/push_storefront_notification_test.dart
///   flutter test --dart-define=GCC_STOREFRONTS_ENABLED=true test/push_storefront_notification_test.dart
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

/// The three markets the server lists in this test. Kuwait may sell; the Emirates are listed browse-only, so a push about an order there
/// still opens in the Emirates — an order that exists is not a sale.
const List<StorefrontCountry> _listed = <StorefrontCountry>[
  StorefrontCountry.saudiArabia,
  StorefrontCountry(code: 'KW', path: '/kw', currency: 'KWD', sellable: true),
  StorefrontCountry(code: 'AE', path: '/ae', currency: 'AED'),
];

void main() {
  late _CapturingPlugin plugin;
  late StorefrontController controller;

  setUpAll(() async {
    plugin = _CapturingPlugin();
    await NotificationHelper.initialize(plugin);
  });

  /// Opens the app on [on], with [_listed] as the server's last answer, and with everything a storefront move needs in the tree.
  Future<void> openApp(WidgetTester tester, {String on = 'SA'}) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      AppConstants.storefrontCountry: on,
    });
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await StoredStorefronts(preferences).save(_listed);

    StorefrontScope.publish(on);
    addTearDown(() => StorefrontScope.publish(null));

    controller = StorefrontController(
      storefrontServiceInterface: _NoServer(),
      storefrontChoice: StorefrontChoice(preferences, enabled: true),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<StorefrontController>.value(value: controller),
          Provider<StorefrontSwitcher>(
            create: (BuildContext context) => StorefrontSwitcher(
              storefrontController: controller,
              // What the HTTP client does when it rebuilds its headers: it publishes the storefront every request from now on asks for.
              applyHeaders: () =>
                  StorefrontScope.publish(controller.current.code),
              changeNotifier: StorefrontChangeNotifier(
                clearHttpCache: (String _) {},
                clearLocalCache: (String _) async {},
                isSignedIn: () => true,
                enabled: true,
              ),
            ),
          ),
        ],
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
              GoRoute(
                path: RouterHelper.walletScreen,
                builder: (BuildContext context, GoRouterState state) =>
                    const Text('the wallet'),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('the home screen'), findsOneWidget);
    expect(controller.current.code, on);
  }

  /// Lets the app finish what the tap started. The listener settles the storefront before it routes, and the move is a real chain of
  /// awaits — the choice saved, the server asked, the headers rebuilt — so the REAL queue is let run before the frames are pumped.
  Future<void> settle(WidgetTester tester) async {
    await tester
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();
  }

  /// A tap on a notification the app showed itself.
  Future<void> tapOne(WidgetTester tester, NotificationBody body) async {
    plugin.onTap!(NotificationResponse(
      notificationResponseType: NotificationResponseType.selectedNotification,
      payload: jsonEncode(body.toJson()),
    ));
    await settle(tester);
  }

  /// A tap on a notification the system showed, which Firebase delivers as an opened-app message.
  Future<void> openFromSystem(
      WidgetTester tester, Map<String, dynamic> data) async {
    FirebaseMessagingPlatform.onMessageOpenedApp.add(RemoteMessage(
      data: data,
      notification: const RemoteNotification(title: 'Your order'),
    ));
    await settle(tester);
  }

  group('a push that names its storefront opens in that storefront', () {
    testWidgets('an order push about Kuwait moves the app to Kuwait and opens the order',
        (WidgetTester tester) async {
      await openApp(tester);

      await tapOne(tester,
          NotificationBody(type: 'order', orderId: 4217, storefront: 'KW'));

      expect(controller.current.code, 'KW');
      expect(StorefrontScope.current, 'KW',
          reason: 'every request the order screen makes must ask for Kuwait');
      expect(find.text('order 4217, from a notification: true'), findsOneWidget);
    });

    testWidgets('the same from a notification the system showed',
        (WidgetTester tester) async {
      await openApp(tester);

      await openFromSystem(tester, <String, dynamic>{
        'type': 'order',
        'order_id': '4217',
        'storefront': 'KW',
      });

      expect(controller.current.code, 'KW');
      expect(StorefrontScope.current, 'KW');
      expect(find.text('order 4217, from a notification: true'), findsOneWidget);
    });

    testWidgets('a wallet push about Kuwait opens the wallet in Kuwait',
        (WidgetTester tester) async {
      await openApp(tester);

      await openFromSystem(tester, <String, dynamic>{
        'type': 'wallet',
        'storefront': 'KW',
      });

      expect(controller.current.code, 'KW');
      expect(StorefrontScope.current, 'KW');
      expect(find.text('the wallet'), findsOneWidget);
    });

    testWidgets('a push about a market the server lists browse-only still opens there: an order that exists is not a sale',
        (WidgetTester tester) async {
      await openApp(tester);

      await openFromSystem(tester, <String, dynamic>{
        'type': 'order',
        'order_id': '4217',
        'storefront': 'AE',
      });

      expect(controller.current.code, 'AE');
      expect(StorefrontScope.current, 'AE');
      expect(find.text('order 4217, from a notification: true'), findsOneWidget);
    });

    testWidgets('the storefront the app moves to carries the market\'s own currency',
        (WidgetTester tester) async {
      await openApp(tester);

      await openFromSystem(tester, <String, dynamic>{
        'type': 'order',
        'order_id': '4217',
        'storefront': 'KW',
      });

      expect(controller.current.currency, 'KWD');
    });

    testWidgets('a push about a market the server does not list opens where the customer already is',
        (WidgetTester tester) async {
      await openApp(tester);

      await openFromSystem(tester, <String, dynamic>{
        'type': 'order',
        'order_id': '4217',
        'storefront': 'QA',
      });

      expect(controller.current.code, 'SA');
      expect(StorefrontScope.current, 'SA');
      expect(find.text('order 4217, from a notification: true'), findsOneWidget);
    });

    testWidgets('a push about the market the customer is already on moves nothing and still opens the order',
        (WidgetTester tester) async {
      await openApp(tester, on: 'KW');

      await openFromSystem(tester, <String, dynamic>{
        'type': 'order',
        'order_id': '4217',
        'storefront': 'KW',
      });

      expect(controller.current.code, 'KW');
      expect(find.text('order 4217, from a notification: true'), findsOneWidget);
    });
  }, skip: !StorefrontConfig.enabled);

  group('with storefronts off, a push that names a storefront is routed as it always was', () {
    testWidgets('the app does not move, and the order still opens',
        (WidgetTester tester) async {
      await openApp(tester);

      await openFromSystem(tester, <String, dynamic>{
        'type': 'order',
        'order_id': '4217',
        'storefront': 'KW',
      });

      expect(StorefrontScope.current, 'SA');
      expect(find.text('order 4217, from a notification: true'), findsOneWidget);
    });
  }, skip: StorefrontConfig.enabled);

  group('A PUSH THAT NAMES NO STOREFRONT BEHAVES EXACTLY AS IT DID: both settings of the build flag', () {
    testWidgets('an order push is routed to the order by its id and moves nothing',
        (WidgetTester tester) async {
      await openApp(tester);

      await openFromSystem(tester, <String, dynamic>{
        'type': 'order',
        'order_id': '4217',
      });

      expect(controller.current.code, 'SA');
      expect(StorefrontScope.current, 'SA');
      expect(find.text('order 4217, from a notification: true'), findsOneWidget);
    });

    testWidgets('a tap on one the app showed itself is routed the same way',
        (WidgetTester tester) async {
      await openApp(tester);

      await tapOne(tester, NotificationBody(type: 'order', orderId: 4217));

      expect(controller.current.code, 'SA');
      expect(StorefrontScope.current, 'SA');
      expect(find.text('order 4217, from a notification: true'), findsOneWidget);
    });

    testWidgets('a wallet push opens the wallet and moves nothing',
        (WidgetTester tester) async {
      await openApp(tester);

      await openFromSystem(tester, <String, dynamic>{'type': 'wallet'});

      expect(controller.current.code, 'SA');
      expect(find.text('the wallet'), findsOneWidget);
    });

    testWidgets('a storefront written as the empty string, which is how the backend writes a value it has none of, moves nothing',
        (WidgetTester tester) async {
      await openApp(tester);

      await openFromSystem(tester, <String, dynamic>{
        'type': 'order',
        'order_id': '4217',
        'storefront': '',
      });

      expect(controller.current.code, 'SA');
      expect(StorefrontScope.current, 'SA');
      expect(find.text('order 4217, from a notification: true'), findsOneWidget);
    });
  });
}
